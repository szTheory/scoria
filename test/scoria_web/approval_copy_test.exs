defmodule ScoriaWeb.ApprovalCopyTest do
  use ExUnit.Case, async: true

  alias ScoriaWeb.ApprovalCopy

  test "formats refund approvals around the human action and target" do
    approval = %{
      tool_name: "issue_refund",
      reason: "Enterprise refund exceeds the self-serve support threshold.",
      actor_id: "billing-specialist",
      session_id: "billing-dispute-1047",
      connector_label: "Billing MCP",
      policy_key: "refunds.enterprise_threshold",
      arguments_preview: %{
        "amount_cents" => 12900,
        "customer" => "Morgan Patel",
        "ticket_id" => "TKT-1047",
        "seed_kind" => "approval_inbox_demo"
      }
    }

    assert ApprovalCopy.title(approval) == "Issue $129.00 refund"
    assert ApprovalCopy.target(approval) == "Morgan Patel - TKT-1047"
    assert ApprovalCopy.approve_label(approval) == "Approve refund"
    assert ApprovalCopy.requested_by(approval) == "billing-specialist"
    assert ApprovalCopy.context_detail(approval) == "Billing MCP - session billing-dispute-1047"
    assert ApprovalCopy.impact(approval) =~ "Denying leaves the run waiting for approval."
    refute ApprovalCopy.raw_arguments(approval) =~ "seed_kind"
  end

  test "formats baseline approvals with dataset context" do
    approval = %{
      tool_name: "dataset_baseline_promotion",
      baseline_target: %{
        dataset_name: "Refund Response Quality",
        dataset_version: "4"
      },
      arguments_preview: %{
        "dataset_name" => "Refund Response Quality",
        "dataset_version" => "4"
      }
    }

    assert ApprovalCopy.title(approval) == "Promote Refund Response Quality v4"
    assert ApprovalCopy.target(approval) == "Refund Response Quality - v4"
    assert ApprovalCopy.approve_label(approval) == "Approve baseline"
  end

  test "uses the delivery channel in customer-message approval actions" do
    approval = %{
      tool_name: "send_customer_update",
      arguments_preview: %{
        "ticket_id" => "TKT-1051",
        "channel" => "email"
      }
    }

    assert ApprovalCopy.title(approval) == "Send email update for TKT-1051"
    assert ApprovalCopy.approve_label(approval) == "Send email"
  end

  test "keeps unknown tool names exact while using generic request copy" do
    approval = %{tool_name: "test_tool", arguments_preview: %{"env" => "prod"}}

    assert ApprovalCopy.title(approval) == "test_tool"
    assert ApprovalCopy.approve_label(approval) == "Approve request"
    assert ApprovalCopy.reject_label(approval) == "Deny request"

    assert ApprovalCopy.impact(approval) ==
             "Approving lets the run continue. Denying leaves the run waiting for approval."
  end

  describe "status_line/1" do
    test "renders one canonical string per decision status" do
      assert ApprovalCopy.status_line(%{status: "pending"}) == "Decision pending"
      assert ApprovalCopy.status_line(%{status: "approved"}) == "Approved"
      assert ApprovalCopy.status_line(%{status: "rejected"}) == "Denied"
      assert ApprovalCopy.status_line(%{status: "expired"}) == "Expired"
      assert ApprovalCopy.status_line(nil) == "Decision pending"
    end
  end

  describe "eyebrow/1" do
    test "returns tool context instead of the generic label" do
      assert ApprovalCopy.eyebrow(%{tool_name: "issue_refund"}) == "Refund approval"
      assert ApprovalCopy.eyebrow(%{tool_name: "dataset_baseline_promotion"}) == "Baseline approval"
      assert ApprovalCopy.eyebrow(%{tool_name: "grant_connector_scope"}) == "Connector approval"

      assert ApprovalCopy.eyebrow(%{tool_name: "send_customer_update"}) ==
               "Customer message approval"
    end

    test "falls back to the generic label only when nil or tool-less" do
      assert ApprovalCopy.eyebrow(nil) == "Approval request"
      assert ApprovalCopy.eyebrow(%{tool_name: nil}) == "Approval request"
      assert ApprovalCopy.eyebrow(%{tool_name: "custom_tool"}) == "custom_tool approval"
    end
  end

  describe "decision_outcome/1 (D-24d single home for \"Denied\")" do
    test "returns Denied for a rejected approval" do
      assert ApprovalCopy.decision_outcome(%{status: "rejected"}) == "Denied"
    end

    test "returns the terminal-status word for approved and expired" do
      assert ApprovalCopy.decision_outcome(%{status: "approved"}) == "Approved"
      assert ApprovalCopy.decision_outcome(%{status: "expired"}) == "Expired"
    end

    test "fails safe to a pending label for non-terminal/unknown status" do
      assert ApprovalCopy.decision_outcome(%{status: "pending"}) == "Decision pending"
      assert ApprovalCopy.decision_outcome(nil) == "Decision pending"
    end
  end

  describe "impact_lead/1" do
    test "returns the concrete irreversible-effect lead clause for a refund" do
      approval = %{
        tool_name: "issue_refund",
        arguments_preview: %{"amount_cents" => 1_000_000, "customer" => "cust_889"}
      }

      assert ApprovalCopy.impact_lead(approval) == "This issues a $10000.00 refund to cust_889."
    end

    test "returns a generic lead clause for the default tool bucket" do
      assert ApprovalCopy.impact_lead(%{tool_name: "test_tool"}) == "This lets the run continue."
    end

    test "returns nil for a nil approval" do
      assert ApprovalCopy.impact_lead(nil) == nil
    end
  end

  describe "decision_receipt/3 (D-27 honest receipt)" do
    test "renders past-tense agentful copy when decider and decided-at are supplied" do
      assert ApprovalCopy.decision_receipt("approved", "ops-lead-1", "2026-07-01 10:00") ==
               "Approved by ops-lead-1 · 2026-07-01 10:00"

      assert ApprovalCopy.decision_receipt("rejected", "ops-lead-1", "2026-07-01 10:00") ==
               "Denied by ops-lead-1 · 2026-07-01 10:00"
    end

    test "never fabricates a decider or time for expired when no real audit event exists" do
      assert ApprovalCopy.decision_receipt("expired", nil, nil) == "Expired"
    end

    test "expired may show a real audit-event time but never a fabricated actor" do
      assert ApprovalCopy.decision_receipt("expired", nil, "2026-07-01 10:00") ==
               "Expired · 2026-07-01 10:00"
    end

    test "falls back to the plain outcome word when decider/decided-at are absent" do
      assert ApprovalCopy.decision_receipt("approved", nil, nil) == "Approved"
      assert ApprovalCopy.decision_receipt("rejected", nil, nil) == "Denied"
    end

    test "never asserts side-effect or run-continuation success" do
      receipt = ApprovalCopy.decision_receipt("approved", "ops-lead-1", "2026-07-01 10:00")
      refute receipt =~ "run"
      refute receipt =~ "continu"
      refute receipt =~ "succeed"
    end

    test "renders decision pending for a non-terminal status" do
      assert ApprovalCopy.decision_receipt("pending", nil, nil) == "Decision pending"
    end
  end

  describe "evidence_rows/1 (D-16/D-23 dedup)" do
    test "no longer includes a raw status-atom evidence row" do
      approval = %{
        actor_id: "billing-specialist",
        connector_label: "Billing MCP",
        policy_key: "refunds.enterprise_threshold",
        session_id: "billing-dispute-1047",
        status: "approved"
      }

      rows = ApprovalCopy.evidence_rows(approval)

      refute Enum.any?(rows, fn {label, _value} -> label == "Status" end)
      assert rows != []
    end
  end
end
