defmodule ScoriaWeb.SemanticEvidenceNotebookComponent do
  @moduledoc """
  Legacy 0.1.x compatibility wrapper for `ScoriaWeb.SemanticCacheTraceNotebookComponent`.
  """

  use Phoenix.Component

  attr(:semantic_evidence, :map, default: %{})

  def render(assigns) do
    ~H"""
    <ScoriaWeb.SemanticCacheTraceNotebookComponent.render semantic_evidence={@semantic_evidence} />
    """
  end
end
