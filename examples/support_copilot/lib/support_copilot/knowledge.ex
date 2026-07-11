defmodule SupportCopilot.Knowledge do
  @moduledoc false

  alias Scoria.Knowledge
  alias Scoria.SupportJourney

  def ensure_refund_policy_source! do
    case Knowledge.ingest_source(%{
           tenant_id: SupportJourney.tenant_id(),
           kind: "doc",
           title: SupportJourney.knowledge_source_title(),
           uri: "file:///support-copilot/refund-policy.md",
           body: refund_policy_body()
         }) do
      {:ok, source} -> source
      {:error, _} = error -> raise "failed to seed refund policy: #{inspect(error)}"
    end
  end

  defp refund_policy_body do
    ticket = SupportJourney.ticket_fixture()

    """
    Acme Corp refund policy for #{ticket["plan"]} plans.
    Duplicate charges such as #{ticket["id"]} require operator approval before issue_refund.
    """
  end
end
