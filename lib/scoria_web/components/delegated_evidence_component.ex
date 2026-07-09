defmodule ScoriaWeb.DelegatedEvidenceComponent do
  @moduledoc """
  Legacy 0.1.x compatibility wrapper for `ScoriaWeb.DelegatedTraceComponent`.
  """

  use Phoenix.Component

  attr(:delegated_handoffs, :list, required: true)

  def render(assigns) do
    ~H"""
    <ScoriaWeb.DelegatedTraceComponent.render delegated_handoffs={@delegated_handoffs} />
    """
  end
end
