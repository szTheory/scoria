defmodule Scoria.SupportJourney.Handlers do
  @moduledoc false

  alias Scoria.SupportJourney

  def lookup_support_ticket(_step, _run) do
    ticket = SupportJourney.ticket_fixture()

    {:ok,
     %{
       "tool" => SupportJourney.ticket_lookup_tool(),
       "ticket_id" => ticket["id"],
       "subject" => ticket["subject"],
       "customer" => ticket["customer"],
       "plan" => ticket["plan"]
     }}
  end

  def wait_for_approval(_step, run) do
    {:waiting_for_approval,
     %{
       tool_name: SupportJourney.refund_approval_tool(),
       arguments: %{"ticket_id" => SupportJourney.ticket_fixture()["id"]},
       reason: "Refund requires operator approval",
       actor_id: SupportJourney.operator_identity().actor_id,
       tenant_id: SupportJourney.tenant_id(),
       trace_id: "trace-#{run.id}"
     }}
  end

  def faq_answer(_step, _run) do
    ticket = SupportJourney.ticket_fixture()

    {:ok,
     %{
       "output" => %{
         "answer" =>
           "Pro plan refunds for duplicate charges like #{ticket["id"]} are reviewed within 2 business days."
       },
       "evidence_refs" => %{"docs" => ["refund-policy"]},
       "semantic_lane" => SupportJourney.semantic_lane_module()
     }}
  end

  def knowledge_answer(_step, _run) do
    ticket = SupportJourney.ticket_fixture()

    {:ok,
     %{
       "output" => %{
         "answer" => "Grounded refund guidance for #{ticket["id"]} from knowledge corpus."
       },
       "evidence_refs" => %{"source" => SupportJourney.knowledge_source_title()},
       "retrieval" => %{"grounded" => true}
     }}
  end

  def connector_lookup(_step, _run) do
    {:ok,
     %{
       "connector_key" => SupportJourney.connector_key(),
       "connector_label" => SupportJourney.connector_label(),
       "tool" => "billing_connector"
     }}
  end

  def succeed(step, _run), do: {:ok, %{"step_id" => step.id, "status" => "ok"}}
end
