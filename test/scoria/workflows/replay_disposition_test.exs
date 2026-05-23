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
end
