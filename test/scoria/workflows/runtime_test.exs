defmodule Scoria.Workflows.RuntimeTest do
  use Scoria.IntegrationCase

  alias Scoria.Repo
  alias Scoria.SRE.AuditOutboxEvent
  alias Scoria.SRE.BudgetReservation
  alias Scoria.Workflows
  alias Scoria.Workflows.{Reconciler, Resume, Runtime}
  alias Scoria.SRE

  defmodule Handlers do
    def succeed(step, _run), do: {:ok, %{"step_id" => step.id, "status" => "ok"}}

    def succeed_and_notify(step, _run, pid),
      do:
        send(pid, {:side_effect_ran, step.id}) && {:ok, %{"step_id" => step.id, "status" => "ok"}}

    def wait_for_approval(_step, run) do
      {:waiting_for_approval,
       %{
         tool_name: "approve_publish",
         arguments: %{"target" => "prod"},
         reason: "Requires approval",
         actor_id: "operator-runtime",
         tenant_id: "tenant-runtime",
         trace_id: "trace-#{run.id}"
       }}
    end

    def handoff(_step, _run),
      do:
        {:handoff,
         %{
           "delegated_role_id" => "critic",
           "delegated_kind" => "review",
           "handoff_input" => %{"brief" => "review"},
           "projected_context" => %{"task" => "review"}
         }}

    def fail(_step, _run), do: {:error, :bad_tool}
    def timeout(_step, _run), do: Process.sleep(50)
    def raise_error(_step, _run), do: raise("boom")
  end

  setup do
    Application.put_env(:scoria, :workflow_runtime_handlers, %{})
    :fuse.remove("provider:runtime-test")
    :fuse.remove("workflow:local-runtime-test")

    if :ets.whereis(:scoria_breaker_registry) != :undefined,
      do: :ets.delete(:scoria_breaker_registry, "provider:runtime-test")

    :ok
  end

  describe "workflow runtime supervision" do
    test "workflow runtime executes bounded step work under a named Task.Supervisor" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "success",
          role_id: "executor",
          status: "queued"
        })

      assert {:ok, _step} = Runtime.execute_step(step.id, handler: {Handlers, :succeed})

      completed = Workflows.get_step!(step.id)
      assert completed.status == "completed"
      assert Process.whereis(Scoria.Workflow.TaskSupervisor)
    end

    test "timeout or crash paths emit durable failure transitions" do
      {:ok, timeout_run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, timeout_step} =
        Workflows.create_step(timeout_run.id, %{
          sequence: 1,
          kind: "timeout",
          role_id: "executor",
          status: "queued"
        })

      assert {:ok, failed_step} =
               Runtime.execute_step(timeout_step.id, handler: {Handlers, :timeout}, timeout: 10)

      assert failed_step.status == "failed"
      assert Workflows.get_run!(timeout_run.id).status == "failed"

      {:ok, crash_run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, crash_step} =
        Workflows.create_step(crash_run.id, %{
          sequence: 1,
          kind: "crash",
          role_id: "executor",
          status: "queued"
        })

      assert {:ok, crash_failed_step} =
               Runtime.execute_step(crash_step.id, handler: {Handlers, :raise_error})

      assert crash_failed_step.status == "failed"
      assert Workflows.get_run!(crash_run.id).status == "failed"
    end

    test "application boot and post-transition reconciliation scan persisted runnable steps and dispatch them safely" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, _step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "success",
          role_id: "executor",
          status: "queued"
        })

      assert {:ok, 1} =
               Reconciler.dispatch_runnable_steps(handlers: %{"success" => {Handlers, :succeed}})

      [step] = Workflows.list_run_steps(run.id)
      assert step.status == "completed"
    end

    test "budget trips fail the step before any side effect runs" do
      {:ok, _policy} =
        SRE.create_budget_policy(%{
          tenant_id: "tenant-budget-trip",
          policy_key: "tenant:default:cost_usd",
          scope_key: "tenant:tenant-budget-trip",
          scope_kind: "tenant",
          resource_kind: "cost_usd",
          status: "active",
          warn_threshold: Decimal.new("8.0"),
          trip_threshold: Decimal.new("10.0"),
          max_workflow_steps: 25,
          max_repeated_tool_calls: 3,
          max_consecutive_failures: 2,
          metadata: %{}
        })

      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "budgeted",
          role_id: "executor",
          status: "queued"
        })

      step_id = step.id

      assert {:ok, failed_step} =
               Runtime.execute_step(
                 step.id,
                 handler: {Handlers, :succeed_and_notify, [self()]},
                 budget_context: %{
                   tenant_id: "tenant-budget-trip",
                   actor_id: "actor-1",
                   trace_id: "trace-runtime-trip",
                   estimated_cost_usd: Decimal.new("15.0"),
                   integration_kind: "provider"
                 }
               )

      assert failed_step.status == "failed"
      assert failed_step.error_envelope["reason_code"] == "trip_threshold_exceeded"
      refute_receive {:side_effect_ran, ^step_id}
    end

    test "external-effect handlers trip an integration-scoped breaker before the side effect reruns" do
      {:ok, _policy} =
        SRE.create_budget_policy(%{
          tenant_id: "tenant-breaker-open",
          policy_key: "tenant:default:cost_usd",
          scope_key: "tenant:tenant-breaker-open",
          scope_kind: "tenant",
          resource_kind: "cost_usd",
          status: "active",
          warn_threshold: Decimal.new("8.0"),
          trip_threshold: Decimal.new("10.0"),
          max_workflow_steps: 25,
          max_repeated_tool_calls: 3,
          max_consecutive_failures: 2,
          metadata: %{}
        })

      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, first_step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "external",
          role_id: "executor",
          status: "queued"
        })

      assert {:ok, failed_step} =
               Runtime.execute_step(
                 first_step.id,
                 handler: {Handlers, :raise_error},
                 breaker_context: %{integration_kind: "provider", provider_ref: "runtime-test"}
               )

      assert failed_step.status == "failed"
      assert failed_step.error_envelope["reason"] =~ "boom"

      {:ok, second_step} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "external",
          role_id: "executor",
          status: "queued"
        })

      second_step_id = second_step.id
      trace_id = "trace-runtime-breaker-open"

      assert {:ok, blocked_step} =
               Runtime.execute_step(
                 second_step.id,
                 handler: {Handlers, :succeed_and_notify, [self()]},
                 breaker_context: %{integration_kind: "provider", provider_ref: "runtime-test"},
                 budget_context: %{
                   tenant_id: "tenant-breaker-open",
                   actor_id: "actor-1",
                   trace_id: trace_id,
                   estimated_cost_usd: Decimal.new("5.0"),
                   integration_kind: "provider",
                   provider_ref: "runtime-test"
                 }
               )

      reservation = Repo.get_by!(BudgetReservation, trace_id: trace_id)

      assert blocked_step.status == "failed"
      assert blocked_step.error_envelope["reason_code"] == "breaker_open"
      assert blocked_step.error_envelope["breaker_key"] == "provider:runtime-test"
      assert blocked_step.error_envelope["budget_reservation_id"] == reservation.id
      refute_receive {:side_effect_ran, ^second_step_id}
      assert reservation.status == "reconciled"
      assert Decimal.equal?(reservation.actual_units, Decimal.new("0"))
      assert reservation.metadata["outcome"] == "breaker_open"
    end

    test "local workflow handlers are not breaker-wrapped by default" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, first_step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "local",
          role_id: "executor",
          status: "queued"
        })

      assert {:ok, failed_step} =
               Runtime.execute_step(first_step.id, handler: {Handlers, :raise_error})

      assert failed_step.status == "failed"

      {:ok, second_step} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "local",
          role_id: "executor",
          status: "queued"
        })

      second_step_id = second_step.id

      assert {:ok, completed_step} =
               Runtime.execute_step(second_step.id,
                 handler: {Handlers, :succeed_and_notify, [self()]}
               )

      assert completed_step.status == "completed"
      assert_receive {:side_effect_ran, ^second_step_id}
    end
  end

  describe "durable approval waits and handoffs" do
    test "entering approval wait persists waiting_for_approval before any projection step" do
      {:ok, run} =
        Workflows.create_run(%{
          root_role_id: "executor",
          actor_id: "run-actor",
          tenant_id: "run-tenant",
          session_id: "run-session"
        })

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "approval",
          role_id: "executor",
          status: "queued"
        })

      assert {:ok, approval} =
               Runtime.execute_step(step.id, handler: {Handlers, :wait_for_approval})

      assert approval.workflow_run_id == run.id
      assert approval.actor_id == "run-actor"
      assert approval.tenant_id == "run-tenant"
      assert approval.session_id == "run-session"
      assert Workflows.get_run!(run.id).status == "waiting_for_approval"
      assert Workflows.get_step!(step.id).status == "waiting_for_approval"
    end

    test "approval expiration keeps workflow truth paused while writing durable audit evidence" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "approval",
          role_id: "executor",
          status: "queued"
        })

      assert {:ok, approval} =
               Runtime.execute_step(step.id, handler: {Handlers, :wait_for_approval})

      assert {:ok, expired} = Workflows.approve(approval.id, "expired")

      expired_event =
        Repo.get_by!(AuditOutboxEvent,
          workflow_run_id: run.id,
          event_type: "approval.expired",
          trace_id: "trace-#{run.id}"
        )

      assert expired.status == "expired"
      assert Workflows.get_run!(run.id).status == "waiting_for_approval"
      assert Workflows.get_step!(step.id).status == "waiting_for_approval"
      assert expired_event.actor_ref == "operator-runtime"
      assert expired_event.redacted_refs["approval_id"] == approval.id
      assert expired_event.redacted_refs["decision"] == "expired"
    end

    test "handoff execution passes projected context slices only and preserves root ownership" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "researcher"})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "handoff",
          role_id: "researcher",
          status: "queued"
        })

      assert {:ok, completed_step} = Runtime.execute_step(step.id, handler: {Handlers, :handoff})

      [handoff] = Workflows.get_run_tree!(run.id).handoffs
      child_steps = Workflows.list_run_steps(run.id)
      assert completed_step.status == "completed"
      assert handoff.delegated_kind == "review"
      assert handoff.handoff_input == %{"brief" => "review"}
      assert Enum.any?(child_steps, &(&1.parent_step_id == step.id and &1.role_id == "critic"))
      assert Enum.any?(child_steps, &(&1.parent_step_id == step.id and &1.kind == "review"))

      assert Enum.all?(child_steps, fn workflow_step ->
               workflow_step.projected_context == %{} or
                 Map.keys(workflow_step.projected_context) == ["task"]
             end)
    end

    test "handoff execution keeps bounded projected context failures explicit at the workflow seam" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "researcher"})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "handoff",
          role_id: "researcher",
          status: "queued"
        })

      handler = fn _step, _run ->
        {:handoff,
         %{
           "delegated_role_id" => "critic",
           "delegated_kind" => "review",
           "handoff_input" => %{"brief" => "review"},
           "projected_context" => %{"safe" => %{"provider_session" => %{"token" => "secret"}}}
         }}
      end

      assert {:ok, failed_step} = Runtime.execute_step(step.id, handler: handler)
      assert failed_step.status == "failed"
      assert failed_step.error_envelope["reason"] == "unsafe_projected_context"
      assert failed_step.error_envelope["contract"] == "bounded_handoff_projected_context"
      assert failed_step.error_envelope["message"] =~ "projected_context"
    end

    test "handoff execution rejects non-map projected context at the workflow seam" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "researcher"})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "handoff",
          role_id: "researcher",
          status: "queued"
        })

      handler = fn _step, _run ->
        {:handoff,
         %{
           "delegated_role_id" => "critic",
           "delegated_kind" => "review",
           "handoff_input" => %{"brief" => "review"},
           "projected_context" => ["not", "a", "map"]
         }}
      end

      assert {:ok, failed_step} = Runtime.execute_step(step.id, handler: handler)
      assert failed_step.status == "failed"
      assert failed_step.error_envelope["reason"] == "invalid_projected_context"
      assert failed_step.error_envelope["contract"] == "bounded_handoff_projected_context"
    end
  end

  describe "exact resume and retry failed step" do
    test "resume reads the latest durable checkpoint and chooses the correct next action" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "approval",
          role_id: "executor",
          status: "queued"
        })

      {:ok, approval} = Runtime.execute_step(step.id, handler: {Handlers, :wait_for_approval})

      assert {:ok, _approval} = Workflows.approve(approval.id, "approved")

      assert {:ok, _resumed_run} =
               Resume.resume_run(run.id, handlers: %{"approval" => {Handlers, :succeed}})

      eventually(fn ->
        status = Workflows.get_run!(run.id).status
        status == "completed" or status == "running"
      end)

      assert Workflows.get_step!(step.id).status == "completed"
    end

    test "retry failed step creates the expected retry state without replaying completed durable boundaries" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "failing",
          role_id: "executor",
          status: "queued"
        })

      {:ok, failed_step} = Runtime.execute_step(step.id, handler: {Handlers, :fail})
      assert failed_step.status == "failed"

      assert {:ok, _run} =
               Resume.retry_failed_step(run.id, handlers: %{"failing" => {Handlers, :succeed}})

      eventually(fn -> Workflows.get_step!(step.id).status == "completed" end)

      retried_step = Workflows.get_step!(step.id)
      checkpoints = Workflows.list_run_checkpoints(run.id)
      assert retried_step.attempt == 2
      assert retried_step.status == "completed"
      assert Enum.count(Enum.filter(checkpoints, &(&1.transition == "step_completed"))) == 1
    end
  end

  describe "async workflow dispatch (production parity)" do
    test "dispatch_run reaches completed status under async dispatch" do
      previous = Application.get_env(:scoria, :workflow_dispatch)
      Application.put_env(:scoria, :workflow_dispatch, :async)

      on_exit(fn ->
        Application.put_env(:scoria, :workflow_dispatch, previous)
      end)

      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, _step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "success",
          role_id: "executor",
          status: "queued"
        })

      assert {:ok, 1} =
               Reconciler.dispatch_run(run.id, handlers: %{"success" => {Handlers, :succeed}})

      eventually(fn ->
        [step] = Workflows.list_run_steps(run.id)
        step.status == "completed"
      end)
    end
  end
end
