defmodule SupportCopilot.RuntimeHandlers do
  @moduledoc false

  defdelegate lookup_support_ticket(step, run), to: Scoria.SupportJourney.Handlers
  defdelegate wait_for_approval(step, run), to: Scoria.SupportJourney.Handlers
  defdelegate faq_answer(step, run), to: Scoria.SupportJourney.Handlers
  defdelegate knowledge_answer(step, run), to: Scoria.SupportJourney.Handlers
  defdelegate connector_lookup(step, run), to: Scoria.SupportJourney.Handlers
  defdelegate succeed(step, run), to: Scoria.SupportJourney.Handlers
end
