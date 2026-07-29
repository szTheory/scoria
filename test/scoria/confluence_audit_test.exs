defmodule Scoria.ConfluenceAuditTest do
  @moduledoc """
  Plan 57-07: every confluence escalation and every confluence block leaves
  a durable, distinct, back-linked audit outbox row; an allow leaves none
  (D-37, D-38, D-40, D-41, D-42, D-46).
  """
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Scoria.MCP.Executor
  alias Scoria.Observe.Approval
  alias Scoria.Repo
  alias Scoria.SRE
  alias Scoria.SRE.AuditOutboxEvent
  alias Scoria.Workflows

  # A single tool declaring all three trifecta legs -- reaches
  # `"exfiltration_path"` on its own call, no per-run accumulator needed
  # (D-11).
  defmodule ThreeLegTool do
    use Scoria.MCP.Tool,
      reads_private_data: true,
      sees_untrusted_content: true,
      can_exfiltrate: true

    @impl true
    def name, do: "confluence_audit_three_leg_tool"

    @impl true
    def description, do: "Declares all three trifecta legs for confluence audit tests"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, context) do
      send(context.test_pid, {:tool_body_executed, self()})
      {:ok, %{result: "leaked"}}
    end
  end

  # Declares only the exfil leg -- never reaches `"exfiltration_path"`, so
  # the gate always resolves `"allow"` for it.
  defmodule ExfilOnlyTool do
    use Scoria.MCP.Tool, can_exfiltrate: true

    @impl true
    def name, do: "confluence_audit_exfil_only_tool"

    @impl true
    def description, do: "Declares only the exfil leg -- never reaches exfiltration_path"

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

  defp new_run! do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})
    run
  end

  defp new_step!(run, sequence) do
    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: sequence,
        kind: "work",
        role_id: "executor",
        status: "running"
      })

    step
  end

  defp exfil_context(run, step, args_fingerprint \\ nil) do
    %{
      actor_id: "user-1",
      tenant_id: "tenant-1",
      run_id: run.id,
      step_id: step.id,
      args_fingerprint: args_fingerprint,
      test_pid: self()
    }
  end

  # Mirrors `Scoria.Workflows.Runtime.execute_handler/6`'s own
  # `Task.Supervisor.async_nolink/2` + `Task.yield/Task.shutdown` shape, so
  # this proves the identical signal path production code observes.
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

  defp confluence_audit_events(run_id) do
    from(e in AuditOutboxEvent,
      where: e.workflow_run_id == ^run_id,
      where: e.event_type == "tool.confluence.escalated"
    )
    |> Repo.all()
  end

  describe "confluence audit row on escalate, block, allow (D-37, D-38, D-42)" do
    test "an escalation writes exactly one audit outbox row with the confluence event type, policy class and actor reference" do
      run = new_run!()
      step = new_step!(run, 1)
      context = exfil_context(run, step, "fp-escalate-1")

      result =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, _attrs}}} = result

      assert [event] = confluence_audit_events(run.id)
      assert event.event_type == "tool.confluence.escalated"
      assert event.policy_class == "confluence_gate"
      assert event.actor_ref == "system:scoria.confluence"
    end

    test "the created approval's blocker_audit_outbox_event_id equals the audit row's id, and its blocker_kind is confluence" do
      run = new_run!()
      step = new_step!(run, 1)
      context = exfil_context(run, step, "fp-escalate-2")

      result =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, _attrs}}} = result

      assert [event] = confluence_audit_events(run.id)

      approval =
        Repo.get_by!(Approval, workflow_run_id: run.id, blocker_kind: "confluence")

      assert approval.blocker_audit_outbox_event_id == event.id
      assert approval.blocker_kind == "confluence"
    end

    test "when the audit write succeeds but the pause transition subsequently fails, the audit row remains an orphan" do
      run = new_run!()
      step = new_step!(run, 1)
      context = exfil_context(run, step, "fp-orphan-1")

      # Delete the step out from under the escalation, between the audit
      # write and `mark_waiting_for_approval/3` -- easiest reachable way
      # to make the pause transition fail without touching the escalation
      # code path itself. `mark_waiting_for_approval/3` calls `repo.get!`
      # on the step id and raises `Ecto.NoResultsError`.
      Repo.delete!(step)

      result =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
        end)

      assert {:exit, {%Ecto.NoResultsError{}, _stacktrace}} = result

      assert [event] = confluence_audit_events(run.id)
      assert event.event_type == "tool.confluence.escalated"
    end

    test "a block via a rejected-approval deny writes an audit row carrying the deny reason code" do
      run = new_run!()
      step = new_step!(run, 1)

      %Approval{
        tool_name: ThreeLegTool.name(),
        status: "rejected",
        blocker_kind: "confluence",
        workflow_run_id: run.id,
        run_id: run.id,
        args_fingerprint: "fp-block-1"
      }
      |> Repo.insert!()

      context = exfil_context(run, step, "fp-block-1")

      assert {:error, %{status: :confluence_denied, reason_code: "confluence_rejected"}} =
               Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)

      assert [event] = confluence_audit_events(run.id)
      assert event.event_type == "tool.confluence.escalated"
      assert event.metadata["reason_code"] == "confluence_rejected"
    end

    test "an unattributed deny under a strict configuration writes an audit row carrying the deny reason code" do
      previous = Application.get_env(:scoria, Scoria.Confluence, [])

      Application.put_env(
        :scoria,
        Scoria.Confluence,
        Keyword.put(previous, :unattributed, :block)
      )

      on_exit(fn -> Application.put_env(:scoria, Scoria.Confluence, previous) end)

      context = %{actor_id: "user-1", tenant_id: "tenant-audit-unattributed", test_pid: self()}

      assert {:error, %{status: :confluence_denied, reason_code: "unattributed"}} =
               Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)

      events =
        from(e in AuditOutboxEvent,
          where: e.tenant_id == "tenant-audit-unattributed",
          where: e.event_type == "tool.confluence.escalated",
          where: is_nil(e.workflow_run_id)
        )
        |> Repo.all()

      assert [event] = events
      assert event.metadata["reason_code"] == "unknown"
    end

    test "an allow writes zero confluence audit outbox rows" do
      :ok = create_budget_policy!("tenant-1", "tool_calls")
      run = new_run!()
      step = new_step!(run, 1)
      context = exfil_context(run, step)

      assert {:ok, _result} = Executor.execute(ExfilOnlyTool, %{}, context)

      assert confluence_audit_events(run.id) == []
    end

    test "two genuine escalations in one run write two distinct rows with two distinct dedupe keys, and both approvals carry a blocker_audit_outbox_event_id" do
      run = new_run!()
      step1 = new_step!(run, 1)
      step2 = new_step!(run, 2)

      context1 = exfil_context(run, step1, "fp-multi-1")
      context2 = exfil_context(run, step2, "fp-multi-2")

      result1 =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context1)
        end)

      result2 =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context2)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, _}}} = result1
      assert {:exit, {:shutdown, {:scoria_confluence_escalation, _}}} = result2

      events = confluence_audit_events(run.id)
      assert length(events) == 2

      dedupe_keys = Enum.map(events, & &1.dedupe_key)
      assert length(Enum.uniq(dedupe_keys)) == 2

      approvals =
        Repo.all(
          from(a in Approval,
            where: a.workflow_run_id == ^run.id,
            where: a.blocker_kind == "confluence"
          )
        )

      assert length(approvals) == 2
      assert Enum.all?(approvals, & &1.blocker_audit_outbox_event_id)

      audit_event_ids = MapSet.new(events, & &1.id)
      approval_blocker_ids = MapSet.new(approvals, & &1.blocker_audit_outbox_event_id)
      assert audit_event_ids == approval_blocker_ids
    end

    test "the escalation attrs map passed to mark_waiting_for_approval/3 carries no dedupe key (D-41)" do
      source =
        File.read!(Path.join([File.cwd!(), "lib", "scoria", "mcp", "executor.ex"]))

      # Isolate the LITERAL `attrs = %{...}` map immediately preceding
      # `Workflows.mark_waiting_for_approval/3`'s call in the escalation
      # (`true ->`) arm -- not the surrounding comments, which legitimately
      # discuss `dedupe_key` in prose.
      [_before, after_marker] =
        String.split(source, "attrs = %{\n          tool_name: tool_module.name(),", parts: 2)

      [attrs_literal, _rest] = String.split(after_marker, "\n        }", parts: 2)

      refute attrs_literal =~ "dedupe_key"
      assert after_marker =~ "Workflows.mark_waiting_for_approval(run_id, step_id, attrs)"
    end
  end
end
