defmodule Scoria.Workflows.ReplayDispositionTest do
  use ExUnit.Case, async: true

  alias Scoria.Workflows.ReplayDisposition

  describe "resolve/5" do
    test "replay run plus pure local seam resolves to execute_live" do
      run = %{id: "replay-run-1", execution_mode: "replay"}

      seam = %{
        local_classification: :pure,
        tool_id: "workflow.local.render",
        action_class: "read",
        risk_level: "low",
        approval_sensitive: false
      }

      assert {:execute_live, evidence} =
               ReplayDisposition.resolve(run, seam, %{}, %{}, %{})

      assert evidence == %{
               replay_disposition: :execute_live,
               replay_reason_code: "local_safe_to_rerun",
               source_run_id: nil,
               source_checkpoint_id: nil,
               source_step_id: nil,
               source_approval_id: nil,
               source_audit_outbox_event_id: nil,
               args_fingerprint: nil,
               subject_ref: nil,
               required_scopes: [],
               policy_key: nil,
               executed_live: true,
               replay_idempotency_key: nil
             }
    end

    test "replay run plus effectful seam with exact source evidence resolves to historical_stub" do
      run = %{id: "replay-run-2", execution_mode: "replay"}

      seam = %{
        local_classification: :write,
        tool_id: "github.issue.update",
        action_class: "write",
        risk_level: "high",
        approval_sensitive: true,
        subject_ref: "repo:acme/scoria#42",
        required_scopes: ["repo:write"],
        grant_state: "active",
        policy_key: "connector:github:issue:update",
        args_fingerprint: "args-sha-1"
      }

      source_evidence = %{
        source_run_id: "source-run",
        source_checkpoint_id: "source-checkpoint",
        source_step_id: "source-step",
        source_approval_id: "source-approval",
        source_audit_outbox_event_id: "source-audit",
        tool_id: "github.issue.update",
        args_fingerprint: "args-sha-1",
        subject_ref: "repo:acme/scoria#42",
        required_scopes: ["repo:write"],
        grant_state: "active",
        policy_key: "connector:github:issue:update"
      }

      assert {:historical_stub, evidence} =
               ReplayDisposition.resolve(run, seam, source_evidence, %{}, %{})

      assert evidence == %{
               replay_disposition: :historical_stub,
               replay_reason_code: "exact_source_match",
               source_run_id: "source-run",
               source_checkpoint_id: "source-checkpoint",
               source_step_id: "source-step",
               source_approval_id: "source-approval",
               source_audit_outbox_event_id: "source-audit",
               args_fingerprint: "args-sha-1",
               subject_ref: "repo:acme/scoria#42",
               required_scopes: ["repo:write"],
               policy_key: "connector:github:issue:update",
               executed_live: false,
               replay_idempotency_key: nil
             }
    end

    test "local classification outranks remote safety hints and missing evidence blocks" do
      run = %{id: "replay-run-3", execution_mode: "replay"}

      seam = %{
        local_classification: :write,
        tool_id: "remote.mail.send",
        action_class: "write",
        risk_level: "high",
        approval_sensitive: true,
        subject_ref: "mailbox:ops",
        required_scopes: ["mail:send"],
        grant_state: "active",
        policy_key: "connector:mail:send",
        args_fingerprint: "args-sha-2",
        remote_hint: %{replay_safe: true, disposition: :execute_live}
      }

      assert {:blocked, evidence} =
               ReplayDisposition.resolve(run, seam, %{}, %{}, %{})

      assert evidence == %{
               replay_disposition: :blocked,
               replay_reason_code: "missing_source_evidence",
               source_run_id: nil,
               source_checkpoint_id: nil,
               source_step_id: nil,
               source_approval_id: nil,
               source_audit_outbox_event_id: nil,
               args_fingerprint: "args-sha-2",
               subject_ref: "mailbox:ops",
               required_scopes: ["mail:send"],
               policy_key: "connector:mail:send",
               executed_live: false,
               replay_idempotency_key: nil
             }
    end

    test "authority-expanding seams such as scope escalation or re-auth stay blocked" do
      run = %{id: "replay-run-4", execution_mode: "replay"}

      seam = %{
        local_classification: :read,
        tool_id: "github.repo.fetch",
        action_class: "read",
        risk_level: "low",
        approval_sensitive: false,
        subject_ref: "repo:acme/scoria",
        required_scopes: ["repo:read", "repo:admin"],
        grant_state: "reauth_required",
        policy_key: "connector:github:repo:fetch",
        args_fingerprint: "args-sha-3",
        authority_expanding: "scope escalation"
      }

      assert {:blocked, evidence} =
               ReplayDisposition.resolve(run, seam, %{}, %{}, %{})

      assert evidence.replay_disposition == :blocked
      assert evidence.replay_reason_code == "authority_expanding_change"
      assert evidence.required_scopes == ["repo:read", "repo:admin"]
      assert evidence.executed_live == false
    end

    test "allowlisted live tool stays blocked without current policy and replay approval inputs" do
      run = %{id: "replay-run-5", execution_mode: "replay"}

      seam = %{
        local_classification: :write,
        tool_id: "slack.message.post",
        action_class: "write",
        risk_level: "high",
        approval_sensitive: true,
        subject_ref: "channel:ops",
        required_scopes: ["chat:write"],
        grant_state: "active",
        policy_key: "connector:slack:post",
        args_fingerprint: "args-sha-4"
      }

      override_context = %{"live_tool_allowlist" => ["slack.message.post"]}

      approval_context = %{
        current_policy_ok?: false,
        replay_approved?: false
      }

      assert {:blocked, evidence} =
               ReplayDisposition.resolve(run, seam, %{}, approval_context, override_context)

      assert evidence.replay_disposition == :blocked
      assert evidence.replay_reason_code == "live_override_requires_policy_and_replay_approval"
      assert evidence.executed_live == false
    end
  end

  describe "action_class enum ownership (D-02)" do
    test "Scoria.MCP.Classification.action_classes/0 preserves the load-bearing order" do
      # `replay_disposition.ex:93`'s `effectful_or_remote?/1` reads
      # `Enum.drop(@effectful_classes, 1)` -- this pins `"read"` at index 0
      # as the sole non-effectful member. `@effectful_classes` is now
      # derived from `Scoria.MCP.Classification.action_classes/0` rather
      # than a duplicated literal (this test is that consumer's own order
      # assertion, not a re-assertion of ownership).
      assert Scoria.MCP.Classification.action_classes() == ["read", "write", "exec", "admin"]

      assert Enum.drop(Scoria.MCP.Classification.action_classes(), 1) == ["write", "exec", "admin"]
    end
  end

  describe "site-5 non-bricking regression: the bare default seam still resolves execute_live" do
    test "the bare %{local_classification: :pure} default seam is unaffected by this phase" do
      run = %{id: "replay-run-6", execution_mode: "replay"}
      seam = %{local_classification: :pure}

      assert {:execute_live, evidence} = ReplayDisposition.resolve(run, seam, %{}, %{}, %{})
      assert evidence.replay_reason_code == "local_safe_to_rerun"
    end

    test "the same default seam with :tool_classification added still resolves identically" do
      run = %{id: "replay-run-7", execution_mode: "replay"}

      seam = %{
        local_classification: :pure,
        tool_classification: Scoria.MCP.Classification.unclassified_default()
      }

      assert {:execute_live, evidence} = ReplayDisposition.resolve(run, seam, %{}, %{}, %{})
      assert evidence.replay_reason_code == "local_safe_to_rerun"
    end
  end

  describe "site-5 named default seam shape (plan 56-03, Workflows.Runtime.default_replay_seam/2)" do
    test "resolves execute_live/local_safe_to_rerun with :pure intact and a real unclassified_default classification" do
      run = %{id: "replay-run-8", execution_mode: "replay"}

      # Hand-built to match Runtime.default_replay_seam/2's literal output --
      # kept as a pure-map assertion per this plan's own instruction, not a
      # DB-backed Runtime integration test.
      seam = %{
        local_classification: :pure,
        tool_classification: Scoria.MCP.Classification.unclassified_default()
      }

      assert {:execute_live, evidence} = ReplayDisposition.resolve(run, seam, %{}, %{}, %{})
      assert evidence.replay_reason_code == "local_safe_to_rerun"

      assert seam.local_classification == :pure
      assert %Scoria.MCP.Classification{source: :unclassified_default} = seam.tool_classification
    end
  end
end
