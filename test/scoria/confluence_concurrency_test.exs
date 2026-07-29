defmodule Scoria.ConfluenceConcurrencyTest do
  @moduledoc """
  The multi-sibling-step and concurrent-escalation interaction class
  `.planning/phases/57-confluence-escalation-gate/57-RESEARCH.md`'s
  Pitfalls 3, 4 and 5 name as the single highest-risk untested class in
  the phase -- invisible to any single-step-per-run fixture, which is
  exactly the shape every other confluence test file uses for its own
  narrower unit of behavior. This is the load-bearing suite RESEARCH.md's
  sampling-rate section requires the phase gate to exercise before
  verification. Select it on its own via
  `mix test test/scoria/confluence_concurrency_test.exs`.

  Every fixture below creates AT LEAST two steps on one run.

  ## D-25 (locked, `d25-step-scoped`, verbatim in 57-01-SUMMARY.md)

  The escalation pause is STEP-scoped, not run-scoped.
  `Scoria.Workflows.complete_step/3`'s run-status computation is
  untouched by this phase -- a sibling completing while another step is
  escalated flips the run status back to `"running"`, and any remaining
  QUEUED sibling becomes dispatchable again via
  `Scoria.Workflows.list_runnable_steps/0`, even though the escalated
  step itself remains genuinely paused (`"waiting_for_approval"`) until a
  human decides it. This is the accepted, documented limitation 57-08's
  own regression test pins from the `mark_waiting_for_approval/3` angle;
  the tests below pin it again driven through the real gate
  (`Scoria.MCP.Executor.execute/3`) from concurrent processes, which is
  the shape a real multi-step agent run actually produces.
  """

  use ExUnit.Case, async: false
  @moduletag :confluence

  import Ecto.Query

  alias Scoria.MCP.Executor
  alias Scoria.Observe.Approval
  alias Scoria.Repo
  alias Scoria.SRE
  alias Scoria.Workflows
  alias Scoria.Workflows.Run
  alias Scoria.Workflows.Step

  # Two DISTINCT three-leg tools -- distinct names so two genuinely
  # independent, concurrently-escalating steps in ONE run can be driven
  # without either escalation's args-fingerprint/consume-CAS lookup
  # interacting with the other's.
  defmodule TrifectaToolA do
    use Scoria.MCP.Tool,
      reads_private_data: true,
      sees_untrusted_content: true,
      can_exfiltrate: true

    @impl true
    def name, do: "concurrency_trifecta_tool_a"

    @impl true
    def description, do: "Declares all three legs -- concurrency fixture A"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, context) do
      send(context.test_pid, {:tool_body_executed, :a, self()})
      {:ok, %{result: "leaked_a"}}
    end
  end

  defmodule TrifectaToolB do
    use Scoria.MCP.Tool,
      reads_private_data: true,
      sees_untrusted_content: true,
      can_exfiltrate: true

    @impl true
    def name, do: "concurrency_trifecta_tool_b"

    @impl true
    def description, do: "Declares all three legs -- concurrency fixture B"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, context) do
      send(context.test_pid, {:tool_body_executed, :b, self()})
      {:ok, %{result: "leaked_b"}}
    end
  end

  defmodule PrivateDataOnlyTool do
    use Scoria.MCP.Tool, reads_private_data: true

    @impl true
    def name, do: "concurrency_private_data_only_tool"

    @impl true
    def description, do: "Declares only the private-data leg"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, _context), do: {:ok, %{result: "ok"}}
  end

  defmodule UntrustedContentOnlyTool do
    use Scoria.MCP.Tool, sees_untrusted_content: true

    @impl true
    def name, do: "concurrency_untrusted_content_only_tool"

    @impl true
    def description, do: "Declares only the untrusted-content leg"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, _context), do: {:ok, %{result: "ok"}}
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  # -- Genuinely multi-step fixture helpers --------------------------------

  defp two_step_run! do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, step_a} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "work",
        role_id: "executor",
        status: "running"
      })

    {:ok, step_b} =
      Workflows.create_step(run.id, %{
        sequence: 2,
        kind: "work",
        role_id: "executor",
        status: "running"
      })

    {run, step_a, step_b}
  end

  defp context_for(run, step) do
    %{
      actor_id: "user-1",
      tenant_id: "tenant-1",
      run_id: run.id,
      step_id: step.id,
      test_pid: self()
    }
  end

  # Mirrors `Scoria.Workflows.Runtime.execute_handler/6`'s own
  # `Task.Supervisor.async_nolink/2` + `Task.yield`/`Task.shutdown` shape
  # -- the same supervisor name, the same yield idiom -- so this suite
  # observes the identical signal path production code observes, not a
  # synthetic substitute.
  defp run_in_supervised_task(fun) do
    task = Task.Supervisor.async_nolink(Scoria.Workflow.TaskSupervisor, fun)
    Task.yield(task, 5_000) || Task.shutdown(task, :brutal_kill)
  end

  defp create_budget_policy!(tenant_id, resource_kind) do
    {:ok, _policy} =
      SRE.create_budget_policy(%{
        tenant_id: tenant_id,
        policy_key: "tenant:default:#{resource_kind}",
        scope_key: "tenant:#{tenant_id}",
        scope_kind: "tenant",
        resource_kind: resource_kind,
        status: "active",
        warn_threshold: Decimal.new("80.0"),
        trip_threshold: Decimal.new("100.0"),
        max_workflow_steps: 25,
        max_repeated_tool_calls: 3,
        max_consecutive_failures: 2,
        metadata: %{}
      })

    :ok
  end

  defp count_confluence_approvals(run_id) do
    Repo.aggregate(
      from(a in Approval, where: a.workflow_run_id == ^run_id and a.blocker_kind == "confluence"),
      :count
    )
  end

  defp count_pending_confluence_approvals(run_id) do
    Repo.aggregate(
      from(a in Approval,
        where:
          a.workflow_run_id == ^run_id and a.blocker_kind == "confluence" and
            a.status == "pending"
      ),
      :count
    )
  end

  defp rail_envelope(run, step) do
    %{
      "status" => "run_halted",
      "reason_code" => "max_steps_exceeded",
      "rail" => "max_steps",
      "limit" => 1,
      "observed" => 1,
      "attempted" => 2,
      "run_id" => run.id,
      "step_id" => step.id,
      "halted_at" => DateTime.to_iso8601(DateTime.utc_now()),
      "site" => "workflow_runtime_step"
    }
  end

  # -- Behavior 1: two concurrent escalations in one run -------------------

  describe "two concurrent escalations in one multi-step run (D-26, D-28)" do
    test "both approvals exist with distinct ids, are independently approvable in either order, and both steps resume to completion" do
      for approve_order <- [:a_then_b, :b_then_a] do
        {run, step_a, step_b} = two_step_run!()

        tasks = [
          Task.async(fn ->
            run_in_supervised_task(fn ->
              Executor.execute(TrifectaToolA, %{}, context_for(run, step_a))
            end)
          end),
          Task.async(fn ->
            run_in_supervised_task(fn ->
              Executor.execute(TrifectaToolB, %{}, context_for(run, step_b))
            end)
          end)
        ]

        [result_a, result_b] = Task.await_many(tasks, 5_000)

        assert {:exit, {:shutdown, {:scoria_confluence_escalation, attrs_a}}} = result_a
        assert {:exit, {:shutdown, {:scoria_confluence_escalation, attrs_b}}} = result_b
        assert attrs_a.tool_name == "concurrency_trifecta_tool_a"
        assert attrs_b.tool_name == "concurrency_trifecta_tool_b"

        approval_a =
          Repo.get_by!(Approval, workflow_run_id: run.id, tool_name: "concurrency_trifecta_tool_a")

        approval_b =
          Repo.get_by!(Approval, workflow_run_id: run.id, tool_name: "concurrency_trifecta_tool_b")

        refute approval_a.id == approval_b.id
        assert approval_a.status == "pending"
        assert approval_b.status == "pending"

        case approve_order do
          :a_then_b ->
            assert {:ok, _} = Workflows.approve(approval_a.id, "approved", %{})
            assert {:ok, resumed_a} = Workflows.resume_run(run.id)
            assert resumed_a.id == step_a.id
            assert {:ok, _} = Workflows.complete_step(step_a.id, %{"result" => "ok"})

            assert {:ok, _} = Workflows.approve(approval_b.id, "approved", %{})
            assert {:ok, resumed_b} = Workflows.resume_run(run.id)
            assert resumed_b.id == step_b.id
            assert {:ok, _} = Workflows.complete_step(step_b.id, %{"result" => "ok"})

          :b_then_a ->
            assert {:ok, _} = Workflows.approve(approval_b.id, "approved", %{})
            assert {:ok, resumed_b} = Workflows.resume_run(run.id)
            assert resumed_b.id == step_b.id
            assert {:ok, _} = Workflows.complete_step(step_b.id, %{"result" => "ok"})

            assert {:ok, _} = Workflows.approve(approval_a.id, "approved", %{})
            assert {:ok, resumed_a} = Workflows.resume_run(run.id)
            assert resumed_a.id == step_a.id
            assert {:ok, _} = Workflows.complete_step(step_a.id, %{"result" => "ok"})
        end

        assert Repo.get!(Run, run.id).status == "completed"
      end
    end
  end

  # -- Behavior 2: a sibling completes mid-escalation -----------------------

  describe "a sibling step completes while an escalation is in flight (D-25, D-28)" do
    test "the escalating task does not crash and its own step is never left running" do
      {run, escalating_step, sibling_step} = two_step_run!()

      tasks = [
        Task.async(fn ->
          run_in_supervised_task(fn ->
            Executor.execute(TrifectaToolA, %{}, context_for(run, escalating_step))
          end)
        end),
        Task.async(fn -> Workflows.complete_step(sibling_step.id, %{"result" => "ok"}) end)
      ]

      [escalation_result, sibling_result] = Task.await_many(tasks, 5_000)

      # Task.await_many/2 itself would have raised had either task died
      # with an uncaught exception -- so simply reaching this line already
      # proves the escalating task never crashed the calling process.
      # Either branch below is a legitimate outcome under D-28's
      # normalize-fail-closed rescue.
      assert match?({:exit, {:shutdown, {:scoria_confluence_escalation, _attrs}}}, escalation_result) or
               match?(
                 {:ok, {:error, %{status: :confluence_denied, reason_code: "confluence_concurrent_run_mutation"}}},
                 escalation_result
               )

      assert {:ok, %Step{status: "completed"}} = sibling_result

      reloaded_escalating_step = Repo.get!(Step, escalating_step.id)
      refute reloaded_escalating_step.status == "running"
    end
  end

  # -- Behavior 3: a sibling completing AFTER the escalation reopens
  # sibling dispatch, and the escalation itself is still resumable -------

  describe "a sibling completing after an escalation reopens dispatch (D-25 accepted limitation)" do
    test "run status flips back to running, a queued sibling becomes dispatchable via list_runnable_steps/0, and the escalation is still resumable" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, escalating_step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "running"
        })

      {:ok, in_flight_sibling} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "work",
          role_id: "executor",
          status: "running"
        })

      {:ok, queued_sibling} =
        Workflows.create_step(run.id, %{
          sequence: 3,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      result =
        run_in_supervised_task(fn ->
          Executor.execute(TrifectaToolA, %{}, context_for(run, escalating_step))
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, _attrs}}} = result
      assert Repo.get!(Run, run.id).status == "waiting_for_approval"

      # Not yet dispatchable: `list_runnable_steps/0` requires run.status
      # in ["running", "retrying"], and the run is "waiting_for_approval".
      refute queued_sibling.id in Enum.map(Workflows.list_runnable_steps(), & &1.id)

      # The IN-FLIGHT sibling completing rewrites the run status back to
      # "running" (`complete_step/3`'s own run-status computation, D-25,
      # untouched by this phase) -- `queued_sibling` is still neither
      # completed nor cancelled, so pending_count > 0 and the computed
      # status is "running", not "completed".
      assert {:ok, _completed} = Workflows.complete_step(in_flight_sibling.id, %{"result" => "ok"})
      assert Repo.get!(Run, run.id).status == "running"

      # This is the documented, intended D-25 behavior, not a bug: the
      # queued sibling becomes dispatchable again even though
      # `escalating_step` itself remains genuinely paused.
      assert queued_sibling.id in Enum.map(Workflows.list_runnable_steps(), & &1.id)
      refute escalating_step.id in Enum.map(Workflows.list_runnable_steps(), & &1.id)

      approval = Repo.get_by!(Approval, workflow_run_id: run.id, blocker_kind: "confluence")
      assert {:ok, _approved} = Workflows.approve(approval.id, "approved", %{})

      assert {:ok, resumed_step} = Workflows.resume_run(run.id)
      assert resumed_step.id == escalating_step.id
    end
  end

  # -- Behavior 4: resume, then the identical call passes through once ----

  describe "resume then replay: the identical tool call passes through on the consumed approval exactly once (D-26)" do
    test "no second approval is created, and the sibling step is untouched by the consume path" do
      :ok = create_budget_policy!("tenant-1", "tool_calls")
      {run, escalating_step, sibling_step} = two_step_run!()

      context =
        context_for(run, escalating_step) |> Map.put(:args_fingerprint, "fp-concurrency-resume")

      result = run_in_supervised_task(fn -> Executor.execute(TrifectaToolA, %{}, context) end)
      assert {:exit, {:shutdown, {:scoria_confluence_escalation, _attrs}}} = result

      approval = Repo.get_by!(Approval, workflow_run_id: run.id, blocker_kind: "confluence")
      assert {:ok, _approved} = Workflows.approve(approval.id, "approved", %{})

      assert {:ok, resumed_step} = Workflows.resume_run(run.id)
      assert resumed_step.id == escalating_step.id

      assert {:ok, %{result: "leaked_a"}} = Executor.execute(TrifectaToolA, %{}, context)
      assert_receive {:tool_body_executed, :a, _pid}

      reloaded_approval = Repo.get!(Approval, approval.id)
      refute is_nil(reloaded_approval.consumed_at)
      assert count_confluence_approvals(run.id) == 1

      # The sibling step, untouched by any of this, remains exactly where
      # it started -- proving the consume path composes correctly
      # alongside a genuinely multi-step run rather than only a
      # single-step fixture.
      assert Repo.get!(Step, sibling_step.id).status == "running"
    end
  end

  # -- Behavior 5: accumulator concurrency, strongest witness per leg -----

  describe "concurrent accumulator fold: different legs, strongest witness per leg (D-15, D-17)" do
    test "two concurrent calls, each lighting a different leg, produce an accumulator containing both legs with their own witness source" do
      {run, step_a, step_b} = two_step_run!()

      tasks = [
        Task.async(fn -> Executor.execute(PrivateDataOnlyTool, %{}, context_for(run, step_a)) end),
        Task.async(fn ->
          Executor.execute(UntrustedContentOnlyTool, %{}, context_for(run, step_b))
        end)
      ]

      results = Task.await_many(tasks, 5_000)
      assert Enum.all?(results, &match?({:ok, _}, &1))

      stored = Repo.get!(Run, run.id).confluence_legs
      assert stored["private_data"]["source"] == "declared"
      assert stored["untrusted_content"]["source"] == "declared"
    end

    test "the same leg lit concurrently by a weaker and a stronger witness resolves to the stronger one, regardless of which task wins the race" do
      {run, step_a, step_b} = two_step_run!()

      weaker = %{private_data: %{source: :default_tier}, untrusted_content: nil, exfil: nil}
      stronger = %{private_data: %{source: :declared}, untrusted_content: nil, exfil: nil}

      tasks = [
        Task.async(fn -> Executor.fold_confluence_legs_for_test(run.id, step_a.id, weaker) end),
        Task.async(fn -> Executor.fold_confluence_legs_for_test(run.id, step_b.id, stronger) end)
      ]

      results = Task.await_many(tasks, 5_000)
      assert Enum.all?(results, &match?({:ok, _}, &1))

      # Strongest-wins is a property of the single-statement CAS itself
      # (D-15), not of arrival order -- this must hold no matter which of
      # the two concurrent folds the database serializes last.
      stored = Repo.get!(Run, run.id).confluence_legs
      assert stored["private_data"]["source"] == "declared"
    end
  end

  # -- Behavior 6: a rail halt with a pending escalation --------------------

  describe "a rail halt with a pending escalation leaves no approval in the pending state (D-52)" do
    test "a run that halts on a rail limit while an escalation is pending resolves that approval to a terminal status" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", rail_max_steps: 1})

      {:ok, halting_step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      {:ok, escalated_step} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "approval_gate",
          role_id: "critic",
          status: "running"
        })

      {:ok, approval} =
        Workflows.mark_waiting_for_approval(run.id, escalated_step.id, %{
          tool_name: "publish",
          blocker_kind: "confluence"
        })

      assert approval.status == "pending"
      assert count_pending_confluence_approvals(run.id) == 1

      {:ok, _claimed} = Workflows.claim_step(halting_step.id)

      assert {:ok, %Run{status: "halted"}} =
               Workflows.halt_run(run.id, halting_step.id, rail_envelope(run, halting_step))

      assert count_pending_confluence_approvals(run.id) == 0
      assert Repo.get!(Approval, approval.id).status == "expired"
    end
  end

  # -- Behavior 7: a retry against an escalated step is refused ------------

  describe "retry_step/1 against an escalated step in a multi-step run (D-27)" do
    test "the retry is refused and the step, approval, and run are all left unchanged" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

      {:ok, escalated_step} =
        Workflows.create_step(run.id, %{
          sequence: 1,
          kind: "work",
          role_id: "executor",
          status: "running",
          result_envelope: %{"prior" => "evidence"}
        })

      {:ok, sibling_step} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "work",
          role_id: "executor",
          status: "running"
        })

      {:ok, approval} =
        Workflows.mark_waiting_for_approval(run.id, escalated_step.id, %{
          tool_name: "publish",
          blocker_kind: "confluence"
        })

      run_before = Repo.get!(Run, run.id)
      step_before = Repo.get!(Step, escalated_step.id)

      assert {:error, :step_not_retryable} = Workflows.retry_step(escalated_step.id)

      assert Repo.get!(Step, escalated_step.id).status == step_before.status
      assert Repo.get!(Step, escalated_step.id).result_envelope == step_before.result_envelope
      assert Repo.get!(Approval, approval.id).status == "pending"
      assert Repo.get!(Run, run.id).status == run_before.status
      assert Repo.get!(Step, sibling_step.id).status == "running"
    end
  end
end
