defmodule Scoria.MCP.ExecutorConfluenceTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Scoria.MCP.Classification
  alias Scoria.MCP.Executor
  alias Scoria.Observe.Approval
  alias Scoria.Repo
  alias Scoria.SRE
  alias Scoria.Workflows
  alias Scoria.Workflows.Run
  alias Scoria.Workflows.Step

  # Declares all three trifecta legs true (D-11: a single tool declaring
  # all three legs escalates on itself, no per-run accumulator needed).
  # `execute/2`'s side effect (the message send) is the load-bearing
  # tracer proof: it must NEVER fire, because the gate refuses the call
  # before the tool's execution Task starts (D-14).
  defmodule ThreeLegTool do
    use Scoria.MCP.Tool,
      reads_private_data: true,
      sees_untrusted_content: true,
      can_exfiltrate: true

    @impl true
    def name, do: "three_leg_tool"

    @impl true
    def description, do: "Declares all three trifecta legs for the confluence gate tracer proof"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, context) do
      send(context.test_pid, {:tool_body_executed, self()})
      {:ok, %{result: "leaked"}}
    end
  end

  # A second, DISTINCT three-leg tool -- used only to prove a run-scoped
  # (`confluence_scope: "run_tool"`) grant does NOT match across tools
  # (D-44).
  defmodule OtherThreeLegTool do
    use Scoria.MCP.Tool,
      reads_private_data: true,
      sees_untrusted_content: true,
      can_exfiltrate: true

    @impl true
    def name, do: "other_three_leg_tool"

    @impl true
    def description, do: "A second declared three-leg tool, distinct from ThreeLegTool"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, context) do
      send(context.test_pid, {:tool_body_executed, self()})
      {:ok, %{result: "leaked"}}
    end
  end

  # Declares exactly ONE leg (`can_exfiltrate`) -- never reaches
  # `"exfiltration_path"`, so the gate always resolves `"allow"` for it.
  # Used only to exercise the always-on `"allow"` telemetry disposition
  # (D-36).
  defmodule ExfilOnlyTool do
    use Scoria.MCP.Tool, can_exfiltrate: true

    @impl true
    def name, do: "exfil_only_tool"

    @impl true
    def description, do: "Declares only the exfil leg -- never reaches exfiltration_path"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, _context), do: {:ok, %{result: "ok"}}
  end

  # No `classification/0` declaration at all -- resolves to
  # `Classification.unclassified_default/0` (D-35 fixture).
  defmodule UndeclaredTool do
    @behaviour Scoria.MCP.Tool

    @impl true
    def name, do: "undeclared_tool"

    @impl true
    def description, do: "No classification declared"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, _context), do: {:ok, %{result: "ok"}}
  end

  # -- Plan 57-06 accumulator fixtures: single-leg tools used to prove the
  # per-run leg fold in isolation from a single call's own three-leg
  # declaration.

  defmodule PrivateDataOnlyTool do
    use Scoria.MCP.Tool, reads_private_data: true

    @impl true
    def name, do: "private_data_only_tool"

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
    def name, do: "untrusted_content_only_tool"

    @impl true
    def description, do: "Declares only the untrusted-content leg"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, _context), do: {:ok, %{result: "ok"}}
  end

  # A genuine declaration of NOTHING sensitive (`source: :tool_declared`,
  # all three legs false) -- distinct from `UndeclaredTool`'s
  # `:unclassified_default`, which produces no witnesses at all regardless
  # of the accumulator. This is the honest "pure harmless read" fixture:
  # its own call never lights anything, but it still folds through (and
  # reads back) the accumulator exactly like any other evaluated call.
  defmodule PureReadTool do
    use Scoria.MCP.Tool

    @impl true
    def name, do: "pure_read_tool"

    @impl true
    def description, do: "Declares no trifecta legs at all"

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

  defp new_run_and_step! do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "work",
        role_id: "executor",
        status: "running"
      })

    {run, step}
  end

  defp exfil_context(run, step) do
    %{
      actor_id: "user-1",
      tenant_id: "tenant-1",
      run_id: run.id,
      step_id: step.id,
      test_pid: self()
    }
  end

  # Mirrors `Scoria.Workflows.Runtime.execute_handler/6`'s own
  # `Task.Supervisor.async_nolink/2` + `Task.yield/Task.shutdown` shape --
  # the same supervisor name, the same yield idiom -- so this test proves
  # the identical signal path production code observes, not a synthetic
  # substitute.
  defp run_in_supervised_task(fun) do
    task = Task.Supervisor.async_nolink(Scoria.Workflow.TaskSupervisor, fun)
    Task.yield(task, 5_000) || Task.shutdown(task, :brutal_kill)
  end

  # `consumed_at`/`consumed_by_step_id`/`confluence_scope` are deliberately
  # absent from `Approval.changeset/2`'s `cast/3` (D-26, D-50) -- fixtures
  # insert a struct literal directly, bypassing the changeset entirely,
  # exactly the way the CAS itself is the only sanctioned writer in
  # production.
  defp insert_confluence_approval!(run, attrs) do
    %Approval{
      tool_name: Keyword.fetch!(attrs, :tool_name),
      status: Keyword.fetch!(attrs, :status),
      blocker_kind: "confluence",
      workflow_run_id: run.id,
      run_id: run.id,
      args_fingerprint: Keyword.get(attrs, :args_fingerprint),
      confluence_scope: Keyword.get(attrs, :confluence_scope)
    }
    |> Repo.insert!()
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

  defp attach_confluence_telemetry(events) do
    ref = make_ref()
    test_pid = self()
    handler_id = "confluence-test-#{inspect(ref)}"

    :telemetry.attach_many(
      handler_id,
      events,
      fn event, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, ref, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    ref
  end

  describe "confluence gate end-to-end (D-14, D-19, D-20, D-23, D-24, D-46)" do
    test "a declared three-leg tool is refused before its execute/2 body runs, and the run/step pause resumably at waiting_for_approval" do
      {run, step} = new_run_and_step!()
      context = exfil_context(run, step)

      result =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}} = result
      assert attrs.tool_name == "three_leg_tool"
      assert attrs.blocker_kind == "confluence"

      # The load-bearing assertion: the tool's execute/2 side effect
      # never occurred.
      refute_receive {:tool_body_executed, _pid}, 200

      reloaded_run = Repo.get!(Run, run.id)
      reloaded_step = Repo.get!(Step, step.id)

      assert reloaded_run.status == "waiting_for_approval"
      assert reloaded_step.status == "waiting_for_approval"

      approval = Repo.get_by!(Approval, workflow_run_id: run.id, blocker_kind: "confluence")

      assert approval.status == "pending"
      assert approval.tool_name == "three_leg_tool"
    end

    test "the pause still lands, and the tool body still never runs, when an adopter handler wraps the call in try/rescue _ -> :ok (D-20)" do
      {run, step} = new_run_and_step!()
      context = exfil_context(run, step)

      result =
        run_in_supervised_task(fn ->
          try do
            Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
          rescue
            _ -> :ok
          end
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}} = result
      assert attrs.blocker_kind == "confluence"

      refute_receive {:tool_body_executed, _pid}, 200

      reloaded_run = Repo.get!(Run, run.id)
      assert reloaded_run.status == "waiting_for_approval"

      approval = Repo.get_by!(Approval, workflow_run_id: run.id, blocker_kind: "confluence")
      assert approval.status == "pending"
    end

    test "a halted run is denied without creating an approval row, and never escalates (D-24)" do
      {run, step} = new_run_and_step!()
      {:ok, _updated_run} = Workflows.halt_run(run.id, step.id, %{"reason" => "test halt"})

      context = exfil_context(run, step)

      assert {:error, %{status: :confluence_denied, reason_code: "run_halted"}} =
               Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)

      refute_receive {:tool_body_executed, _pid}, 200
      refute Repo.get_by(Approval, workflow_run_id: run.id, blocker_kind: "confluence")

      assert Repo.get!(Run, run.id).status == "halted"
    end

    test "a run that halts via a sibling rail trip AFTER this step was claimed still denies the escalation without creating an approval row (D-24)" do
      {run, step} = new_run_and_step!()

      {:ok, sibling_step} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "work",
          role_id: "executor",
          status: "queued"
        })

      # The halt lands on a DIFFERENT step than the one about to escalate --
      # proving the halted-run check is necessary even given a per-step
      # claim-time guard, because a sibling rail can trip after this step
      # was already claimed/dispatched.
      {:ok, _halted_run} =
        Workflows.halt_run(run.id, sibling_step.id, %{"reason" => "sibling rail tripped"})

      context = exfil_context(run, step)

      assert {:error, %{status: :confluence_denied, reason_code: "run_halted"}} =
               Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)

      refute_receive {:tool_body_executed, _pid}, 200
      refute Repo.get_by(Approval, workflow_run_id: run.id, blocker_kind: "confluence")
      assert Repo.get!(Run, run.id).status == "halted"
    end
  end

  describe "resumed confluence escalation re-execution (D-26, plan 57-08 Task 1)" do
    test "a resumed confluence escalation re-reaching the identical tool call passes through on the consumed approval instead of escalating again" do
      :ok = create_budget_policy!("tenant-1", "tool_calls")
      {run, step} = new_run_and_step!()
      context = exfil_context(run, step) |> Map.put(:args_fingerprint, "fp-resume-passthrough")

      result = run_in_supervised_task(fn -> Executor.execute(ThreeLegTool, %{"action" => "leak"}, context) end)
      assert {:exit, {:shutdown, {:scoria_confluence_escalation, _attrs}}} = result

      approval = Repo.get_by!(Approval, workflow_run_id: run.id, blocker_kind: "confluence")
      assert {:ok, _approved} = Workflows.approve(approval.id, "approved", %{})

      assert {:ok, resumed_step} = Workflows.resume_run(run.id)
      assert resumed_step.id == step.id
      assert Repo.get!(Step, step.id).status == "queued"

      # The identical tool call, on the identical args fingerprint, now
      # passes through and consumes the approval instead of escalating
      # again -- proving resume_run/1's widening composes correctly with
      # the pre-existing (57-05) approval-consume CAS.
      assert {:ok, %{result: "leaked"}} =
               Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)

      assert_receive {:tool_body_executed, _pid}

      reloaded_approval = Repo.get!(Approval, approval.id)
      refute is_nil(reloaded_approval.consumed_at)
      assert count_confluence_approvals(run.id) == 1
    end
  end

  describe "concurrency and attrs shape (D-28, plan 57-08 Task 3)" do
    test "a sibling step completing concurrently with an in-flight escalation does not crash the escalating task, and the escalating step is never left running" do
      {run, step_a} = new_run_and_step!()

      {:ok, step_b} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "work",
          role_id: "executor",
          status: "running"
        })

      context = exfil_context(run, step_a)

      tasks = [
        Task.async(fn ->
          run_in_supervised_task(fn -> Executor.execute(ThreeLegTool, %{"action" => "leak"}, context) end)
        end),
        Task.async(fn -> Workflows.complete_step(step_b.id, %{"result" => "ok"}) end)
      ]

      [escalation_result, sibling_result] = Task.await_many(tasks, 5_000)

      # The escalating task never crashed the calling process -- either
      # branch below is a legitimate outcome under D-28's normalize-
      # fail-closed rescue; `Task.await_many/2` itself would have raised
      # had either task died with an uncaught exception.
      assert match?({:exit, {:shutdown, {:scoria_confluence_escalation, _attrs}}}, escalation_result) or
               match?(
                 {:ok, {:error, %{status: :confluence_denied, reason_code: "confluence_concurrent_run_mutation"}}},
                 escalation_result
               )

      assert {:ok, %Step{status: "completed"}} = sibling_result

      reloaded_step_a = Repo.get!(Step, step_a.id)
      refute reloaded_step_a.status == "running"
    end

    test "escalation attrs handed to mark_waiting_for_approval/3 are atom-keyed and always carry a non-nil tool name (D-28)" do
      {run, step} = new_run_and_step!()
      context = exfil_context(run, step)

      result = run_in_supervised_task(fn -> Executor.execute(ThreeLegTool, %{"action" => "leak"}, context) end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}} = result
      assert Enum.all?(Map.keys(attrs), &is_atom/1)
      refute is_nil(attrs.tool_name)
      assert attrs.tool_name == "three_leg_tool"
    end
  end

  describe "approval consume (D-26)" do
    test "a pending call with no matching approved approval evaluates normally and may escalate" do
      {run, step} = new_run_and_step!()
      context = exfil_context(run, step) |> Map.put(:args_fingerprint, "fp-no-match")

      result =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, _attrs}}} = result
    end

    test "an approved, unconsumed confluence approval matching this call's args fingerprint passes through, and after the call that approval's consumed_at/consumed_by_step_id are set" do
      :ok = create_budget_policy!("tenant-1", "tool_calls")
      {run, step} = new_run_and_step!()

      approval =
        insert_confluence_approval!(run,
          tool_name: "three_leg_tool",
          status: "approved",
          args_fingerprint: "fp-consume-1"
        )

      context = exfil_context(run, step) |> Map.put(:args_fingerprint, "fp-consume-1")

      assert {:ok, %{result: "leaked"}} =
               Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)

      assert_receive {:tool_body_executed, _pid}

      reloaded_approval = Repo.get!(Approval, approval.id)
      refute is_nil(reloaded_approval.consumed_at)
      assert reloaded_approval.consumed_by_step_id == step.id

      # No NEW approval was minted for this pass-through call.
      assert count_confluence_approvals(run.id) == 1
      refute Repo.get!(Run, run.id).status == "waiting_for_approval"
    end

    test "the same approval consumed once cannot be consumed a second time -- a repeat of the identical call escalates again rather than passing through" do
      :ok = create_budget_policy!("tenant-1", "tool_calls")
      {run, step} = new_run_and_step!()

      insert_confluence_approval!(run,
        tool_name: "three_leg_tool",
        status: "approved",
        args_fingerprint: "fp-consume-once"
      )

      context = exfil_context(run, step) |> Map.put(:args_fingerprint, "fp-consume-once")

      assert {:ok, _result} = Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
      assert_receive {:tool_body_executed, _pid}

      # Repeating the IDENTICAL call now finds the approval already
      # consumed -- it must escalate again, not pass through a second time.
      result =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}} = result
      assert attrs.tool_name == "three_leg_tool"
      refute_receive {:tool_body_executed, _pid}, 200
    end

    test "a call whose args fingerprint is nil is evaluated (and escalates under a three-leg declared classification) rather than passing through" do
      {run, step} = new_run_and_step!()

      # An approved approval exists, but this call's own context carries no
      # `:args_fingerprint` at all -- `nil` must fail CLOSED, never match.
      insert_confluence_approval!(run,
        tool_name: "three_leg_tool",
        status: "approved",
        args_fingerprint: nil
      )

      context = exfil_context(run, step)
      refute Map.has_key?(context, :args_fingerprint)

      result =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, _attrs}}} = result
      refute_receive {:tool_body_executed, _pid}, 200
    end

    test "a rejected matching approval produces a refusal envelope carrying the confluence-rejected reason code and produces no new approval row" do
      {run, step} = new_run_and_step!()

      insert_confluence_approval!(run,
        tool_name: "three_leg_tool",
        status: "rejected",
        args_fingerprint: "fp-rejected-1"
      )

      context = exfil_context(run, step) |> Map.put(:args_fingerprint, "fp-rejected-1")

      assert {:error, %{status: :confluence_denied, reason_code: "confluence_rejected"}} =
               Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)

      refute_receive {:tool_body_executed, _pid}, 200
      assert count_confluence_approvals(run.id) == 1
      refute Repo.get!(Run, run.id).status == "waiting_for_approval"
    end
  end

  describe "run-scoped grant (confluence_scope: \"run_tool\", D-44/D-50)" do
    test "matches a second call of the same tool in the same run without being consumed" do
      :ok = create_budget_policy!("tenant-1", "tool_calls")
      {run, step} = new_run_and_step!()

      insert_confluence_approval!(run,
        tool_name: "three_leg_tool",
        status: "approved",
        confluence_scope: "run_tool"
      )

      context = exfil_context(run, step)

      assert {:ok, _result} = Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
      assert_receive {:tool_body_executed, _pid}

      # The grant is NOT consumed -- exactly one row remains, still
      # approved, and no new pending approval was minted.
      assert count_confluence_approvals(run.id) == 1
      refute Repo.get!(Run, run.id).status == "waiting_for_approval"
    end

    test "does not match a different tool" do
      {run, step} = new_run_and_step!()

      insert_confluence_approval!(run,
        tool_name: "three_leg_tool",
        status: "approved",
        confluence_scope: "run_tool"
      )

      context = exfil_context(run, step)

      result =
        run_in_supervised_task(fn ->
          Executor.execute(OtherThreeLegTool, %{"action" => "leak"}, context)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}} = result
      assert attrs.tool_name == "other_three_leg_tool"
    end

    test "does not match a different run" do
      :ok = create_budget_policy!("tenant-1", "tool_calls")
      {run, step} = new_run_and_step!()
      {other_run, _other_step} = new_run_and_step!()

      insert_confluence_approval!(other_run,
        tool_name: "three_leg_tool",
        status: "approved",
        confluence_scope: "run_tool"
      )

      context = exfil_context(run, step)

      result =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}} = result
      assert attrs.tool_name == "three_leg_tool"
    end

    test "the match is structurally bound to the \"declared\" grade (D-44) -- a differently-graded escalation of the same tool can never be matched" do
      # `confluence_input/2`'s `leg_witness/1` only ever constructs
      # `source: :declared` witnesses through the current executor
      # wiring (declared-only leg sourcing, D-13), so a live
      # "run_tool"-scoped call at any OTHER grade is not reachable via
      # `Executor.execute/4` in this plan's scope -- the bound is
      # asserted structurally instead: `run_tool_scope_granted?/3`'s
      # match arm is guarded by an explicit `"declared"` head, with a
      # catch-all fallback (`_other_grade`) that returns `false` for
      # every other grade, so a future leg source (e.g. `:scanner_infra`)
      # cannot silently widen the bound without editing this clause.
      source = File.read!(Path.join([File.cwd!(), "lib", "scoria", "mcp", "executor.ex"]))

      assert source =~ ~r/defp run_tool_scope_granted\?\(run_id, tool_module, "declared"\)/

      assert source =~
               ~r/defp run_tool_scope_granted\?\(_run_id, _tool_module, _other_grade\), do: false/
    end
  end

  describe "attribution and containment (D-21, D-22)" do
    test "a tool call carrying :run_id and :step_id in its context is attributable and can be paused" do
      {run, step} = new_run_and_step!()
      context = exfil_context(run, step)

      result =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, _attrs}}} = result
    end

    test "a tool call carrying :workflow_run_id instead of :run_id is attributable, because canonical_context/1 aliases the two" do
      {run, step} = new_run_and_step!()

      context =
        %{
          actor_id: "user-1",
          tenant_id: "tenant-1",
          workflow_run_id: run.id,
          step_id: step.id,
          test_pid: self()
        }

      result =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, _attrs}}} = result
    end

    test "a tool call with no step attribution resolves to the unattributed disposition, defaults to allow, emits the skipped telemetry event, and creates no approval row" do
      :ok = create_budget_policy!("tenant-1", "tool_calls")
      ref = attach_confluence_telemetry([[:scoria, :gate, :confluence, :skipped]])

      context = %{actor_id: "user-1", tenant_id: "tenant-1", test_pid: self()}

      assert {:ok, _result} = Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
      assert_receive {:tool_body_executed, _pid}

      assert_receive {:telemetry_event, ^ref, [:scoria, :gate, :confluence, :skipped],
                      measurements, metadata}

      assert measurements == %{}
      assert metadata.reason == :unattributed

      refute Repo.get_by(Approval, blocker_kind: "confluence", tool_name: "three_leg_tool")
    end

    test "a raw spawn with no $callers chain resolves as uncontained: the call proceeds without pausing, and the skipped telemetry event fires" do
      {run, step} = new_run_and_step!()
      context = exfil_context(run, step)
      ref = attach_confluence_telemetry([[:scoria, :gate, :confluence, :skipped]])

      spawn(fn ->
        Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
      end)

      assert_receive {:telemetry_event, ^ref, [:scoria, :gate, :confluence, :skipped],
                      measurements, metadata},
                     1_000

      assert measurements == %{}
      assert metadata.reason == :uncontained

      refute Repo.get_by(Approval, workflow_run_id: run.id, blocker_kind: "confluence")

      # Give the async spawn a moment to settle, then confirm the run was
      # never paused.
      Process.sleep(100)
      refute Repo.get!(Run, run.id).status == "waiting_for_approval"
    end

    test "the gate driven from inside a Task.async is treated as contained" do
      {run, step} = new_run_and_step!()
      context = exfil_context(run, step)

      result =
        run_in_supervised_task(fn ->
          task =
            Task.async(fn -> Executor.execute(ThreeLegTool, %{"action" => "leak"}, context) end)

          Task.await(task)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}} = result
      assert attrs.tool_name == "three_leg_tool"
    end

    test "the gate driven from inside a Task.async_stream is treated as contained" do
      {run, step} = new_run_and_step!()
      context = exfil_context(run, step)

      result =
        run_in_supervised_task(fn ->
          [context]
          |> Task.async_stream(
            fn ctx -> Executor.execute(ThreeLegTool, %{"action" => "leak"}, ctx) end,
            timeout: 5_000
          )
          |> Enum.to_list()
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}} = result
      assert attrs.tool_name == "three_leg_tool"
    end
  end

  describe "resolve_classification/2 idempotence clause gated on source (D-35)" do
    setup do
      previous = Application.get_env(:scoria, :require_tool_classification, false)
      Application.put_env(:scoria, :require_tool_classification, true)

      on_exit(fn ->
        Application.put_env(:scoria, :require_tool_classification, previous)
      end)

      :ok
    end

    test "a context carrying an unclassified-default classification no longer bypasses the refusal check" do
      {run, step} = new_run_and_step!()

      context =
        exfil_context(run, step)
        |> Map.put(:tool_classification, Classification.unclassified_default())

      assert {:error, %{status: :unclassified_tool}} =
               Executor.execute(UndeclaredTool, %{}, context)
    end

    test "a context carrying a declared-source classification still short-circuits the resolution" do
      {run, step} = new_run_and_step!()

      declared = %Classification{
        source: :host_tightened,
        reads_private_data: false,
        sees_untrusted_content: false,
        can_exfiltrate: false,
        action_class: "read"
      }

      context = exfil_context(run, step) |> Map.put(:tool_classification, declared)

      assert {:ok, %{result: "ok"}} = Executor.execute(UndeclaredTool, %{}, context)
    end
  end

  describe "one always-on gate telemetry event (D-36)" do
    test "the event fires once for an allow, once for an escalate and once for a block, with three distinct decision values, empty measurements, and the grade/combination/action_class/leg sources in metadata" do
      :ok = create_budget_policy!("tenant-1", "tool_calls")
      ref = attach_confluence_telemetry([[:scoria, :gate, :confluence, :observed]])

      # -- allow: a tool that never reaches exfiltration_path -----------
      {allow_run, allow_step} = new_run_and_step!()
      allow_context = exfil_context(allow_run, allow_step)
      assert {:ok, _} = Executor.execute(ExfilOnlyTool, %{}, allow_context)

      assert_receive {:telemetry_event, ^ref, [:scoria, :gate, :confluence, :observed],
                      allow_measurements, allow_metadata}

      assert allow_measurements == %{}
      assert allow_metadata["scoria.confluence.decision"] == "allow"

      # -- escalate: the declared three-leg tool -------------------------
      {escalate_run, escalate_step} = new_run_and_step!()
      escalate_context = exfil_context(escalate_run, escalate_step)

      escalate_result =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, escalate_context)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, _}}} = escalate_result

      assert_receive {:telemetry_event, ^ref, [:scoria, :gate, :confluence, :observed],
                      escalate_measurements, escalate_metadata}

      assert escalate_measurements == %{}
      assert escalate_metadata["scoria.confluence.decision"] == "escalate"
      assert escalate_metadata["scoria.confluence.combination"] == "exfiltration_path"
      assert escalate_metadata["scoria.confluence.grade"] == "declared"
      assert escalate_metadata.action_class != nil
      assert escalate_metadata.private_data_source == :declared
      assert escalate_metadata.untrusted_content_source == :declared
      assert escalate_metadata.exfil_source == :declared

      # -- block: a rejected-approval-consume denial ---------------------
      {block_run, block_step} = new_run_and_step!()

      insert_confluence_approval!(block_run,
        tool_name: "three_leg_tool",
        status: "rejected",
        args_fingerprint: "fp-block-1"
      )

      block_context =
        exfil_context(block_run, block_step) |> Map.put(:args_fingerprint, "fp-block-1")

      assert {:error, %{status: :confluence_denied, reason_code: "confluence_rejected"}} =
               Executor.execute(ThreeLegTool, %{"action" => "leak"}, block_context)

      assert_receive {:telemetry_event, ^ref, [:scoria, :gate, :confluence, :observed],
                      block_measurements, block_metadata}

      assert block_measurements == %{}
      assert block_metadata["scoria.confluence.decision"] == "block"

      decisions =
        [allow_metadata, escalate_metadata, block_metadata]
        |> Enum.map(&Map.get(&1, "scoria.confluence.decision"))
        |> Enum.uniq()

      assert length(decisions) == 3
    end

    test "a raising telemetry handler does not propagate an error out of the tool call" do
      handler_id = "confluence-raising-handler-#{inspect(make_ref())}"

      :telemetry.attach(
        handler_id,
        [:scoria, :gate, :confluence, :observed],
        fn _event, _measurements, _metadata, _config -> raise "boom" end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      {run, step} = new_run_and_step!()
      context = exfil_context(run, step)

      result =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, _attrs}}} = result
    end
  end

  describe "confluence leg accumulator (D-15, D-16, D-17)" do
    test "the private-data leg is first lit by a default-tier witness and later by a declared witness, and the stored source becomes the declared one" do
      {run, step} = new_run_and_step!()

      default_tier_witness = %{private_data: %{source: :default_tier}, untrusted_content: nil, exfil: nil}
      declared_witness = %{private_data: %{source: :declared}, untrusted_content: nil, exfil: nil}

      {:ok, first_legs} =
        Executor.fold_confluence_legs_for_test(run.id, step.id, default_tier_witness)

      assert first_legs.private_data.source == :default_tier

      {:ok, second_legs} = Executor.fold_confluence_legs_for_test(run.id, step.id, declared_witness)

      assert second_legs.private_data.source == :declared

      stored = Repo.get!(Run, run.id).confluence_legs
      assert stored["private_data"]["source"] == "declared"
      assert stored["private_data"]["lit"] == true
    end

    test "reversing the arrival order of a default-tier witness and a declared witness produces the identical final accumulator state" do
      {run_a, _step_a} = new_run_and_step!()
      {run_b, _step_b} = new_run_and_step!()

      # A shared literal step id (not tied to either run's own steps) so the
      # two runs' final `first_step_id` values are directly comparable --
      # the property under test is ordering-independence of the SOURCE
      # resolution, not the (trivially always-equal-to-itself) step
      # identity of whichever call happens to run first in each run.
      shared_step_id = Ecto.UUID.generate()

      default_tier_witness = %{private_data: %{source: :default_tier}, untrusted_content: nil, exfil: nil}
      declared_witness = %{private_data: %{source: :declared}, untrusted_content: nil, exfil: nil}

      {:ok, _} = Executor.fold_confluence_legs_for_test(run_a.id, shared_step_id, default_tier_witness)
      {:ok, _} = Executor.fold_confluence_legs_for_test(run_a.id, shared_step_id, declared_witness)

      {:ok, _} = Executor.fold_confluence_legs_for_test(run_b.id, shared_step_id, declared_witness)
      {:ok, _} = Executor.fold_confluence_legs_for_test(run_b.id, shared_step_id, default_tier_witness)

      stored_a = Repo.get!(Run, run_a.id).confluence_legs
      stored_b = Repo.get!(Run, run_b.id).confluence_legs

      assert stored_a == stored_b
      assert stored_a["private_data"]["source"] == "declared"
    end

    test "a call whose classification marks a leg false writes nothing for that leg -- the key remains absent" do
      {run, step} = new_run_and_step!()

      assert {:ok, _result} = Executor.execute(PureReadTool, %{}, exfil_context(run, step))

      stored = Repo.get!(Run, run.id).confluence_legs
      refute Map.has_key?(stored, "private_data")
      refute Map.has_key?(stored, "untrusted_content")
    end

    test "after a call that lights one leg, the accumulator contains exactly that one key" do
      {run, step} = new_run_and_step!()

      assert {:ok, _result} =
               Executor.execute(PrivateDataOnlyTool, %{}, exfil_context(run, step))

      stored = Repo.get!(Run, run.id).confluence_legs
      assert Map.keys(stored) == ["private_data"]
    end

    test "the merge is a single Repo.update_all reading confluence_legs back via the query's own select:, with no separate accumulator read preceding it" do
      # `Ecto.Repo.update_all/3` has no `:returning` opt (unlike
      # `insert_all/3`) -- the second `{count, results}` element is
      # populated only when the update QUERY itself carries a `select:`,
      # mirroring `consume_call_scope/3`'s and `Rails.admit_tool_call/2`'s
      # own shape. Assert the fold's query selects `confluence_legs` and
      # is read back through the SAME `Repo.update_all` call, never a
      # separate `Repo.one`/`Repo.get` read immediately before it.
      source = File.read!(Path.join([File.cwd!(), "lib", "scoria", "mcp", "executor.ex"]))

      assert source =~ ~r/select: r\.confluence_legs/
      assert source =~ ~r/Repo\.update_all\(query, \[\]\)/
    end

    test "two concurrent tool calls against one run, each lighting a different leg, produce an accumulator containing both legs" do
      {run, step} = new_run_and_step!()
      context = exfil_context(run, step)

      tasks = [
        Task.async(fn -> Executor.execute(PrivateDataOnlyTool, %{}, context) end),
        Task.async(fn -> Executor.execute(UntrustedContentOnlyTool, %{}, context) end)
      ]

      results = Task.await_many(tasks, 5_000)
      assert Enum.all?(results, &match?({:ok, _}, &1))

      stored = Repo.get!(Run, run.id).confluence_legs
      assert Map.has_key?(stored, "private_data")
      assert Map.has_key?(stored, "untrusted_content")
    end

    test "a failed accumulator write (a run id matching no row) emits the fallback telemetry event and the tool call does not crash" do
      ref = attach_confluence_telemetry([[:scoria, :gate, :confluence, :fallback]])

      {_run, step} = new_run_and_step!()
      bogus_run_id = Ecto.UUID.generate()

      context = %{
        actor_id: "user-1",
        tenant_id: "tenant-1",
        run_id: bogus_run_id,
        step_id: step.id,
        test_pid: self()
      }

      assert {:ok, _result} = Executor.execute(PrivateDataOnlyTool, %{}, context)

      assert_receive {:telemetry_event, ^ref, [:scoria, :gate, :confluence, :fallback],
                      measurements, metadata}

      assert measurements == %{}
      assert metadata.run_id == bogus_run_id
    end
  end

  describe "confluence gate wiring: exposure legs accumulate, exfil stays per-call (D-11, D-12)" do
    test "a run where step one declares private data, step two declares untrusted content, and step three declares exfil escalates on step three" do
      {run, step1} = new_run_and_step!()

      assert {:ok, _} = Executor.execute(PrivateDataOnlyTool, %{}, exfil_context(run, step1))

      {:ok, step2} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "work",
          role_id: "executor",
          status: "running"
        })

      assert {:ok, _} = Executor.execute(UntrustedContentOnlyTool, %{}, exfil_context(run, step2))

      {:ok, step3} =
        Workflows.create_step(run.id, %{
          sequence: 3,
          kind: "work",
          role_id: "executor",
          status: "running"
        })

      result =
        run_in_supervised_task(fn ->
          Executor.execute(ExfilOnlyTool, %{}, exfil_context(run, step3))
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}} = result
      assert attrs.tool_name == "exfil_only_tool"

      approval = Repo.get_by!(Approval, workflow_run_id: run.id, blocker_kind: "confluence")
      assert approval.tool_name == "exfil_only_tool"
    end

    test "reordering the two exposure legs still escalates on whichever step carries the exfil leg" do
      {run, step1} = new_run_and_step!()

      assert {:ok, _} = Executor.execute(UntrustedContentOnlyTool, %{}, exfil_context(run, step1))

      {:ok, step2} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "work",
          role_id: "executor",
          status: "running"
        })

      assert {:ok, _} = Executor.execute(PrivateDataOnlyTool, %{}, exfil_context(run, step2))

      {:ok, step3} =
        Workflows.create_step(run.id, %{
          sequence: 3,
          kind: "work",
          role_id: "executor",
          status: "running"
        })

      result =
        run_in_supervised_task(fn ->
          Executor.execute(ExfilOnlyTool, %{}, exfil_context(run, step3))
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}} = result
      assert attrs.tool_name == "exfil_only_tool"
    end

    test "an exfil-capable tool that ran earlier does not poison a later pure read" do
      :ok = create_budget_policy!("tenant-1", "tool_calls")
      {run, step1} = new_run_and_step!()

      assert {:ok, _} = Executor.execute(ExfilOnlyTool, %{}, exfil_context(run, step1))

      {:ok, step2} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "work",
          role_id: "executor",
          status: "running"
        })

      assert {:ok, _} = Executor.execute(PureReadTool, %{}, exfil_context(run, step2))

      refute Repo.get!(Run, run.id).status == "waiting_for_approval"
      refute Repo.get_by(Approval, workflow_run_id: run.id, blocker_kind: "confluence")
    end

    test "a single tool declaring all three legs still escalates on itself, because its own legs fold in before evaluation" do
      {run, step} = new_run_and_step!()
      context = exfil_context(run, step)

      result =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}} = result
      assert attrs.tool_name == "three_leg_tool"
    end

    test "a later call declaring a previously-lit leg false leaves the accumulator's entry for that leg unchanged" do
      {run, step1} = new_run_and_step!()

      assert {:ok, _} = Executor.execute(PrivateDataOnlyTool, %{}, exfil_context(run, step1))
      before_legs = Repo.get!(Run, run.id).confluence_legs

      {:ok, step2} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "work",
          role_id: "executor",
          status: "running"
        })

      assert {:ok, _} = Executor.execute(PureReadTool, %{}, exfil_context(run, step2))
      after_legs = Repo.get!(Run, run.id).confluence_legs

      assert after_legs == before_legs
    end

    test "after an approval is consumed and the tool runs, confluence_legs still contains every leg lit before the approval" do
      :ok = create_budget_policy!("tenant-1", "tool_calls")
      {run, step1} = new_run_and_step!()

      # Light BOTH exposure legs before the approved call -- the D-26
      # consume-CAS path passes an approved call through UNEVALUATED (it
      # never calls `evaluate_confluence/5`, so it never folds its OWN
      # legs), which is exactly why this test proves the accumulator is
      # untouched by consumption rather than proving the consumed call's
      # own declaration gets folded.
      assert {:ok, _} = Executor.execute(PrivateDataOnlyTool, %{}, exfil_context(run, step1))

      {:ok, step2} =
        Workflows.create_step(run.id, %{
          sequence: 2,
          kind: "work",
          role_id: "executor",
          status: "running"
        })

      assert {:ok, _} = Executor.execute(UntrustedContentOnlyTool, %{}, exfil_context(run, step2))

      before_legs = Repo.get!(Run, run.id).confluence_legs
      assert Map.has_key?(before_legs, "private_data")
      assert Map.has_key?(before_legs, "untrusted_content")

      {:ok, step3} =
        Workflows.create_step(run.id, %{
          sequence: 3,
          kind: "work",
          role_id: "executor",
          status: "running"
        })

      insert_confluence_approval!(run,
        tool_name: "three_leg_tool",
        status: "approved",
        args_fingerprint: "fp-retain-legs"
      )

      context3 = exfil_context(run, step3) |> Map.put(:args_fingerprint, "fp-retain-legs")

      assert {:ok, %{result: "leaked"}} =
               Executor.execute(ThreeLegTool, %{"action" => "leak"}, context3)

      final_legs = Repo.get!(Run, run.id).confluence_legs
      assert Map.has_key?(final_legs, "private_data")
      assert Map.has_key?(final_legs, "untrusted_content")
      assert final_legs == before_legs
    end

    test "no function in the executor clears, resets, or downgrades confluence_legs (D-12)" do
      source = File.read!(Path.join([File.cwd!(), "lib", "scoria", "mcp", "executor.ex"]))

      refute source =~ ~r/defp?\s+\w*(clear|reset|downgrade|untaint)\w*confluence_leg/i
      refute source =~ ~r/defp?\s+\w*confluence_leg\w*(clear|reset|downgrade|untaint)/i
    end
  end

  defp count_confluence_approvals(run_id) do
    Repo.aggregate(
      from(a in Approval, where: a.workflow_run_id == ^run_id and a.blocker_kind == "confluence"),
      :count
    )
  end
end
