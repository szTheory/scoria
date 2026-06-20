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
end
