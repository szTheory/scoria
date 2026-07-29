defmodule Scoria.Connectors.InvocationTest do
  use ExUnit.Case, async: false
  import Ecto.Query

  alias Scoria.Connectors.Invocation
  alias Scoria.MCP.Classification
  alias Scoria.Repo
  alias Scoria.SRE.AuditOutboxEvent
  alias Scoria.Workflows

  defmodule ReplayTool do
    @behaviour Scoria.MCP.Tool

    @impl true
    def name, do: "replay_tool"

    @impl true
    def description, do: "Replay invocation test tool"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(args, context) do
      send(context.test_pid, {:tool_executed, args, context})
      {:ok, %{result: "live"}}
    end
  end

  defmodule ClassifiedReplayTool do
    use Scoria.MCP.Tool, action_class: "write", can_exfiltrate: true

    @impl true
    def name, do: "classified_replay_tool"

    @impl true
    def description,
      do: "Declares a classification for site-4 connector-invocation seam tests (plan 56-03)"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(args, context) do
      send(context.test_pid, {:tool_executed, args, context})
      {:ok, %{result: "live"}}
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        execution_mode: "replay",
        replay_overrides: %{"live_tool_allowlist" => ["allowed.tool"]}
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "tool",
        role_id: "executor",
        status: "queued"
      })

    %{run: Workflows.get_run!(run.id), step: step}
  end

  test "replay read seam with exact evidence returns a historical stub and never executes the tool",
       %{run: run, step: step} do
    assert {:ok, result} =
             Invocation.invoke(
               ReplayTool,
               %{"action" => "read"},
               %{
                 run: run,
                 run_id: run.id,
                 step_id: step.id,
                 test_pid: self(),
                 tool_id: "repo.read",
                 local_classification: :read,
                 action_class: "read",
                 risk_level: "low",
                 args_fingerprint: "same",
                 subject_ref: "repo:acme/scoria",
                 required_scopes: ["repo:read"],
                 grant_state: "active",
                 policy_key: "repo.read",
                 source_evidence: %{
                   source_run_id: run.source_run_id || run.id,
                   source_checkpoint_id: run.source_checkpoint_id || Ecto.UUID.generate(),
                   source_step_id: step.id,
                   source_audit_outbox_event_id: Ecto.UUID.generate(),
                   tool_id: "repo.read",
                   args_fingerprint: "same",
                   subject_ref: "repo:acme/scoria",
                   required_scopes: ["repo:read"],
                   grant_state: "active",
                   policy_key: "repo.read",
                   result: %{"cached" => true}
                 }
               }
             )

    assert result.status == :historical_stub
    assert result.result == %{"cached" => true}
    refute_receive {:tool_executed, _, _}
  end

  test "remote safety hints cannot override local unsafe classification and missing evidence blocks",
       %{run: run, step: step} do
    assert {:error, envelope} =
             Invocation.invoke(
               ReplayTool,
               %{"action" => "write"},
               %{
                 run: run,
                 run_id: run.id,
                 step_id: step.id,
                 test_pid: self(),
                 tool_id: "mail.send",
                 local_classification: :write,
                 action_class: "write",
                 risk_level: "high",
                 approval_sensitive: true,
                 remote_hint: %{replay_safe: true},
                 args_fingerprint: "changed",
                 subject_ref: "mailbox:ops",
                 required_scopes: ["mail:send"],
                 policy_key: "mail.send"
               }
             )

    assert envelope.status == :replay_blocked
    assert envelope.replay_reason_code == "missing_source_evidence"
    refute_receive {:tool_executed, _, _}
  end

  test "approval-sensitive seams require exact effect matches to historical stub", %{
    run: run,
    step: step
  } do
    assert {:error, envelope} =
             Invocation.invoke(
               ReplayTool,
               %{"action" => "write"},
               %{
                 run: run,
                 run_id: run.id,
                 step_id: step.id,
                 test_pid: self(),
                 tool_id: "deploy.prod",
                 local_classification: :write,
                 action_class: "write",
                 risk_level: "high",
                 approval_sensitive: true,
                 args_fingerprint: "current",
                 subject_ref: "env:prod",
                 required_scopes: ["deploy:write"],
                 grant_state: "active",
                 policy_key: "deploy.prod",
                 source_evidence: %{
                   source_run_id: run.id,
                   source_checkpoint_id: Ecto.UUID.generate(),
                   source_step_id: step.id,
                   source_audit_outbox_event_id: Ecto.UUID.generate(),
                   tool_id: "deploy.prod",
                   args_fingerprint: "original",
                   subject_ref: "env:prod",
                   required_scopes: ["deploy:write"],
                   grant_state: "active",
                   policy_key: "deploy.prod"
                 }
               }
             )

    assert envelope.replay_reason_code == "missing_source_evidence"
  end

  test "scope escalation and re-auth seams stay blocked in the default lane", %{
    run: run,
    step: step
  } do
    assert {:error, envelope} =
             Invocation.invoke(
               ReplayTool,
               %{},
               %{
                 run: run,
                 run_id: run.id,
                 step_id: step.id,
                 test_pid: self(),
                 tool_id: "admin.grant",
                 local_classification: :authority_expanding,
                 action_class: "admin",
                 risk_level: "high",
                 authority_expanding: "scope escalation",
                 grant_state: "reauth_required",
                 required_scopes: ["admin:write"],
                 policy_key: "admin.grant"
               }
             )

    assert envelope.status == :replay_blocked
    assert envelope.replay_reason_code == "authority_expanding_change"
    refute_receive {:tool_executed, _, _}
  end

  test "allowlisted live tools require current policy and fresh replay approval before executing",
       %{run: run, step: step} do
    blocked_context = %{
      run: run,
      run_id: run.id,
      step_id: step.id,
      test_pid: self(),
      tool_id: "allowed.tool",
      local_classification: :write,
      action_class: "write",
      risk_level: "high",
      approval_sensitive: true,
      args_fingerprint: "same",
      subject_ref: "env:prod",
      required_scopes: ["deploy:write"],
      grant_state: "active",
      policy_key: "allowed.tool",
      approval_context: %{current_policy_ok?: false, replay_approved?: false}
    }

    assert {:error, blocked} =
             Invocation.invoke(ReplayTool, %{"action" => "live"}, blocked_context)

    assert blocked.replay_reason_code == "live_override_requires_policy_and_replay_approval"
    refute_receive {:tool_executed, _, _}

    live_context =
      Map.put(blocked_context, :approval_context, %{
        current_policy_ok?: true,
        replay_approved?: true
      })

    assert {:ok, live} = Invocation.invoke(ReplayTool, %{"action" => "live"}, live_context)
    assert live.status == :execute_live
    assert_receive {:tool_executed, %{"action" => "live"}, tool_context}
    assert is_binary(tool_context.replay_idempotency_key)
  end

  test "replay-live retries reuse the same replay_idempotency_key and dedupe audit writes", %{
    run: run,
    step: step
  } do
    context = %{
      run: run,
      run_id: run.id,
      step_id: step.id,
      trace_id: "replay-live",
      tenant_id: "tenant-1",
      actor_id: "actor-1",
      tool_id: "allowed.tool",
      tool_target: "deploy_prod",
      local_classification: :write,
      action_class: "write",
      risk_level: "high",
      approval_sensitive: true,
      policy_sensitive: true,
      args_fingerprint: "same",
      subject_ref: "env:prod",
      required_scopes: ["deploy:write"],
      grant_state: "active",
      policy_key: "allowed.tool",
      approval_context: %{current_policy_ok?: true, replay_approved?: true},
      test_pid: self()
    }

    assert {:ok, first} = Invocation.invoke(ReplayTool, %{"action" => "live"}, context)
    assert_receive {:tool_executed, _, first_ctx}
    assert {:ok, second} = Invocation.invoke(ReplayTool, %{"action" => "live"}, context)
    assert_receive {:tool_executed, _, second_ctx}

    assert first.replay_idempotency_key == second.replay_idempotency_key
    assert first_ctx.replay_idempotency_key == second_ctx.replay_idempotency_key

    assert Repo.aggregate(
             from(a in AuditOutboxEvent,
               where: a.trace_id == "replay-live" and a.event_type == "tool.invocation"
             ),
             :count
           ) == 1
  end

  describe "Site 4 (D-05, plan 56-03): classification resolved before Invocation's own replay decision" do
    setup %{run: run, step: step} do
      live_context = %{
        run: run,
        run_id: run.id,
        step_id: step.id,
        test_pid: self(),
        tool_id: "allowed.tool",
        local_classification: :write,
        action_class: "write",
        risk_level: "high",
        approval_sensitive: true,
        args_fingerprint: "same",
        subject_ref: "env:prod",
        required_scopes: ["deploy:write"],
        grant_state: "active",
        policy_key: "allowed.tool",
        tenant_id: "tenant-1",
        approval_context: %{current_policy_ok?: true, replay_approved?: true}
      }

      %{live_context: live_context}
    end

    test "undeclared tool: an unclassified event fires at each resolution site, and the tool's context carries :tool_classification",
         %{live_context: live_context} do
      parent = self()
      ref = make_ref()
      handler_id = "invocation-classification-undeclared-#{System.unique_integer()}"

      :telemetry.attach(
        handler_id,
        [:scoria, :class, :unclassified],
        fn event_name, measurements, metadata, _config ->
          send(parent, {:telemetry_event, ref, event_name, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      assert {:ok, %{status: :execute_live}} =
               Invocation.invoke(ReplayTool, %{"action" => "live"}, live_context)

      assert_receive {:tool_executed, _args, tool_context}

      assert %Classification{source: :unclassified_default} =
               Map.get(tool_context, :tool_classification)

      # Phase 57 plan 05 (D-35): `MCP.Executor.resolve_classification/2`'s
      # idempotence clause is now gated on `source` -- a pre-resolved
      # `unclassified_default` classification (exactly what
      # `resolve_tool_classification/2` above injects) no longer
      # short-circuits it, so the executor genuinely RE-resolves and emits
      # its own `[:scoria, :class, :unclassified]` event too. This is the
      # fix, not a regression: before it, an undeclared tool routed
      # through the connector silently bypassed
      # `require_tool_classification` at the executor. One event now
      # fires per genuine resolution site (`:connector_invocation` here,
      # `:mcp_executor` from the executor), never a third.
      assert_receive {:telemetry_event, ^ref, [:scoria, :class, :unclassified], _measurements,
                      connector_metadata}

      assert connector_metadata.site == :connector_invocation

      assert_receive {:telemetry_event, ^ref, [:scoria, :class, :unclassified], _measurements,
                      executor_metadata}

      assert executor_metadata.site == :mcp_executor

      refute_receive {:telemetry_event, ^ref, [:scoria, :class, :unclassified], _measurements,
                      _metadata3}
    end

    test "a declaring tool: no unclassified event fires, and the tool's received context carries its declaration",
         %{live_context: live_context} do
      create_budget_policy!("tenant-1", "tool_calls")

      parent = self()
      ref = make_ref()
      handler_id = "invocation-classification-declaring-#{System.unique_integer()}"

      :telemetry.attach(
        handler_id,
        [:scoria, :class, :unclassified],
        fn event_name, measurements, metadata, _config ->
          send(parent, {:telemetry_event, ref, event_name, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      assert {:ok, %{status: :execute_live}} =
               Invocation.invoke(ClassifiedReplayTool, %{"action" => "live"}, live_context)

      assert_receive {:tool_executed, _args, tool_context}

      assert %Classification{source: :tool_declared, action_class: "write", can_exfiltrate: true} =
               Map.get(tool_context, :tool_classification)

      refute_receive {:telemetry_event, ^ref, [:scoria, :class, :unclassified], _measurements,
                      _metadata}
    end
  end

  defp create_budget_policy!(tenant_id, resource_kind) do
    {:ok, _policy} =
      Scoria.SRE.create_budget_policy(%{
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
  end
end
