defmodule Scoria.ConfluenceAuditTest do
  @moduledoc """
  Plan 57-07: every confluence escalation and every confluence block leaves
  a durable, distinct, back-linked audit outbox row; an allow leaves none
  (D-37, D-38, D-40, D-41, D-42, D-46).
  """
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Scoria.Confluence
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

    test "a persisted audit row's metadata key set equals Confluence.audit_metadata/1's output key set for equivalent evidence (D-39 integration)" do
      run = new_run!()
      step = new_step!(run, 1)
      context = exfil_context(run, step, "fp-metadata-keyset-1")

      result =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, _attrs}}} = result

      assert [event] = confluence_audit_events(run.id)

      # An escalate's evidence has every leg declared and a nil
      # `reason_code` -- reconstruct the SAME-SHAPE `%Confluence.Evidence{}`
      # (the exact field VALUES do not matter for a key-set comparison) and
      # prove the persisted row's metadata key set is EXACTLY
      # `Confluence.audit_metadata/1`'s output key set for it -- not a
      # superset, not a subset (D-39).
      equivalent_evidence = %Confluence.Evidence{
        combination: "exfiltration_path",
        grade: "declared",
        decision: "escalate",
        private_data_source: :declared,
        untrusted_content_source: :declared,
        exfil_source: :declared,
        action_class: "read",
        confluence_idempotency_key: "irrelevant-for-key-set-comparison",
        tool_ref: "irrelevant-for-key-set-comparison"
      }

      expected_key_set =
        equivalent_evidence |> Confluence.audit_metadata() |> Map.keys() |> MapSet.new()

      actual_key_set = event.metadata |> Map.keys() |> MapSet.new()

      assert actual_key_set == expected_key_set
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

  describe "replay contract pinned negatively -- Phase 57 adds nothing to ReplayDisposition (D-43, D-44)" do
    test "ReplayDisposition's disposition enum -- the set of atoms resolve/5 can return -- equals its pre-phase value" do
      source =
        File.read!(
          Path.join([File.cwd!(), "lib", "scoria", "workflows", "replay_disposition.ex"])
        )

      dispositions =
        ~r/\{:(\w+),\s*evidence\(/
        |> Regex.scan(source)
        |> Enum.map(fn [_, atom] -> atom end)
        |> Enum.uniq()
        |> Enum.sort()

      assert dispositions == ["blocked", "execute_live", "historical_stub"]
    end

    test "ReplayDisposition's replay_reason_code enum -- the set of literal reason code strings resolve/5 can emit -- equals its pre-phase value" do
      source =
        File.read!(
          Path.join([File.cwd!(), "lib", "scoria", "workflows", "replay_disposition.ex"])
        )

      reason_codes =
        ~r/evidence\(\s*:\w+,\s*"([a-z_]+)"/
        |> Regex.scan(source)
        |> Enum.map(fn [_, code] -> code end)
        |> Enum.uniq()
        |> Enum.sort()

      expected =
        ~w(
          authority_expanding_change
          exact_source_match
          live_override_approved
          live_override_requires_policy_and_replay_approval
          local_safe_to_rerun
          missing_source_evidence
          run_not_in_replay_mode
        )
        |> Enum.sort()

      assert reason_codes == expected
    end

    test "the replay_scope value space (Workflows.mark_waiting_for_approval/3's default) equals its pre-phase value" do
      source = File.read!(Path.join([File.cwd!(), "lib", "scoria", "workflows.ex"]))

      replay_scope_literals =
        ~r/replay_scope[^\n]*"([a-z_]+)"/
        |> Regex.scan(source)
        |> Enum.map(fn [_, value] -> value end)
        |> Enum.uniq()

      assert replay_scope_literals == ["replay_live"]
    end

    test "a replayed call resolving to a historical stub never fires the confluence gate -- no telemetry event, no audit row, no approval row" do
      {:ok, run} =
        Workflows.create_run(%{
          root_role_id: "executor",
          execution_mode: "replay",
          source_run_id: Ecto.UUID.generate(),
          source_checkpoint_id: Ecto.UUID.generate()
        })

      step = new_step!(run, 1)

      ref = make_ref()
      test_pid = self()
      handler_id = "confluence-replay-stub-#{inspect(ref)}"

      :telemetry.attach_many(
        handler_id,
        [
          [:scoria, :gate, :confluence, :observed],
          [:scoria, :gate, :confluence, :skipped]
        ],
        fn event, _measurements, _metadata, _config ->
          send(test_pid, {:confluence_telemetry, ref, event})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      context = %{
        actor_id: "user-1",
        tenant_id: "tenant-1",
        run: run,
        run_id: run.id,
        step_id: step.id,
        test_pid: self(),
        tool_id: "confluence_audit_three_leg_tool",
        local_classification: :read,
        action_class: "read",
        risk_level: "low",
        args_fingerprint: "same",
        subject_ref: "subj-1",
        required_scopes: [],
        grant_state: "active",
        policy_key: "confluence_audit_three_leg_tool",
        source_evidence: %{
          source_run_id: run.source_run_id,
          source_checkpoint_id: run.source_checkpoint_id,
          source_step_id: step.id,
          source_audit_outbox_event_id: Ecto.UUID.generate(),
          tool_id: "confluence_audit_three_leg_tool",
          args_fingerprint: "same",
          subject_ref: "subj-1",
          required_scopes: [],
          grant_state: "active",
          policy_key: "confluence_audit_three_leg_tool",
          result: %{"cached" => true}
        }
      }

      assert {:ok, result} = Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
      assert result.status == :historical_stub

      # The load-bearing proof: the tool's execute/2 side effect never
      # fired -- a historical stub never executes the tool at all, so
      # there is no exfil for the gate to guard against.
      refute_receive {:tool_body_executed, _pid}, 200
      refute_receive {:confluence_telemetry, ^ref, _event}, 200

      assert confluence_audit_events(run.id) == []
      refute Repo.get_by(Approval, workflow_run_id: run.id, blocker_kind: "confluence")
    end

    test "a replayed call resolving to live execution through the override path fires the confluence gate" do
      {:ok, run} = Workflows.create_run(%{root_role_id: "executor", execution_mode: "replay"})
      step = new_step!(run, 1)

      context = %{
        actor_id: "user-1",
        tenant_id: "tenant-1",
        run: run,
        run_id: run.id,
        step_id: step.id,
        test_pid: self(),
        args_fingerprint: "fp-live-override-1",
        approval_context: %{current_policy_ok?: true},
        override_context: %{"live_tool_allowlist" => [inspect(ThreeLegTool)]}
      }

      result =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}} = result
      assert attrs.tool_name == "confluence_audit_three_leg_tool"
      refute_receive {:tool_body_executed, _pid}, 200

      assert [_event] = confluence_audit_events(run.id)
    end

    test "an approved escalation is not a reusable replay grant -- a replay of an approved run re-evaluates rather than passing through" do
      run_a = new_run!()
      step_a1 = new_step!(run_a, 1)

      context_a = exfil_context(run_a, step_a1, "fp-replay-reuse-1")

      result_a =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context_a)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, _}}} = result_a

      approval_a =
        Repo.get_by!(Approval, workflow_run_id: run_a.id, blocker_kind: "confluence")

      approval_a
      |> Approval.changeset(%{status: "approved"})
      |> Repo.update!()

      # A replay of run_a reaching the IDENTICAL tool call (same
      # args_fingerprint) under a DIFFERENT run id -- `local_classification:
      # :pure` forces ReplayDisposition to resolve :execute_live without
      # needing exact-source-match evidence, isolating this test to the
      # gate's own re-evaluation behavior.
      {:ok, run_b} =
        Workflows.create_run(%{
          root_role_id: "executor",
          execution_mode: "replay",
          source_run_id: run_a.id
        })

      step_b1 = new_step!(run_b, 1)

      context_b =
        exfil_context(run_b, step_b1, "fp-replay-reuse-1")
        |> Map.merge(%{run: run_b, local_classification: :pure})

      result_b =
        run_in_supervised_task(fn ->
          Executor.execute(ThreeLegTool, %{"action" => "leak"}, context_b)
        end)

      # A pass-through on run_a's approval would have returned
      # {:ok, %{result: "leaked"}} here -- the gate instead evaluates
      # AFRESH and escalates run_b independently, because
      # consume_call_scope/3 is scoped to a.workflow_run_id == ^run_id and
      # run_a's approved approval can never match run_b's id.
      assert {:exit, {:shutdown, {:scoria_confluence_escalation, _}}} = result_b
      refute_receive {:tool_body_executed, _pid}, 200

      approval_b =
        Repo.get_by!(Approval, workflow_run_id: run_b.id, blocker_kind: "confluence")

      assert approval_b.id != approval_a.id
      assert approval_b.status == "pending"
    end

    test "a tool routed through the connector invocation path is gated identically -- the connector seam needs no separate hook" do
      :ok = create_budget_policy!("tenant-1", "tool_calls")
      run = new_run!()
      step = new_step!(run, 1)

      context = %{
        actor_id: "user-1",
        tenant_id: "tenant-1",
        run_id: run.id,
        step_id: step.id,
        args_fingerprint: "fp-connector-1",
        test_pid: self()
      }

      result =
        run_in_supervised_task(fn ->
          Scoria.Connectors.Invocation.invoke(ThreeLegTool, %{"action" => "leak"}, context)
        end)

      assert {:exit, {:shutdown, {:scoria_confluence_escalation, attrs}}} = result
      assert attrs.tool_name == "confluence_audit_three_leg_tool"
      refute_receive {:tool_body_executed, _pid}, 200
    end
  end
end
