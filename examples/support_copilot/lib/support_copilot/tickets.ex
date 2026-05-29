defmodule SupportCopilot.Tickets do
  @moduledoc """
  Support-copilot domain reads backed by `Scoria.SupportJourney` fixtures.
  """

  def current_ticket, do: Scoria.SupportJourney.ticket_fixture()

  def persona, do: Scoria.SupportJourney.persona_fixture()
end
