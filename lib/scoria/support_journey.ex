defmodule Scoria.SupportJourney do
  @moduledoc """
  Shared support-copilot adoption journey fixtures.

  Single source of truth for generated-host overlay proof, the `examples/support_copilot`
  gallery, and adopter documentation contract tests.
  """

  @fixture_root Path.join([:code.priv_dir(:scoria), "fixtures", "support_journey"])

  @ticket_lookup_tool "lookup_support_ticket"
  @refund_approval_tool "issue_refund"

  def runtime_identity do
    %{
      actor_id: "support-agent-1",
      tenant_id: tenant_id(),
      session_id: session_id()
    }
  end

  def operator_identity do
    %{
      actor_id: "ops-lead-7",
      tenant_id: tenant_id()
    }
  end

  def tenant_id, do: "acme-corp"
  def session_id, do: "support-session-42"
  def handoff_role_id, do: "billing_specialist"
  def delegated_kind, do: "billing_review"
  def waiting_status, do: "waiting_for_approval"
  def completed_status, do: "completed"
  def ticket_lookup_tool, do: @ticket_lookup_tool
  def refund_approval_tool, do: @refund_approval_tool

  def operator_route(run_id), do: "/scoria/workflows/#{run_id}"
  def operator_route_pattern, do: "/scoria/workflows/:run_id"
  def gallery_path, do: "examples/support_copilot"
  def advisory_lane_command, do: "mix scoria.test.support_copilot"

  def ticket_fixture do
    @fixture_root
    |> Path.join("ticket.json")
    |> File.read!()
    |> Jason.decode!()
  end

  def persona_fixture do
    @fixture_root
    |> Path.join("persona.json")
    |> File.read!()
    |> Jason.decode!()
  end

  def handoff_input do
    %{
      "brief" => "Review refund eligibility for #{ticket_fixture()["id"]}",
      "ticket_id" => ticket_fixture()["id"],
      "amount_cents" => ticket_fixture()["amount_cents"]
    }
  end

  def projected_context do
    %{
      "ticket_summary" => ticket_fixture()["subject"],
      "customer_plan" => ticket_fixture()["plan"]
    }
  end

  def doc_fragments do
    [
      gallery_path(),
      advisory_lane_command(),
      tenant_id(),
      session_id(),
      handoff_role_id(),
      delegated_kind(),
      ticket_lookup_tool(),
      refund_approval_tool(),
      ticket_fixture()["id"],
      ticket_fixture()["subject"],
      persona_fixture()["persona"],
      "Scoria.start_run/2",
      "Scoria.resume_run/2",
      "Scoria.start_handoff_run/3",
      "Scoria.get_run_detail/1",
      operator_route_pattern(),
      waiting_status(),
      completed_status(),
      "support-copilot gallery",
      "Support Ops Lead"
    ]
  end
end
