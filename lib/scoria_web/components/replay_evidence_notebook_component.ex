defmodule ScoriaWeb.ReplayEvidenceNotebookComponent do
  @moduledoc """
  Legacy 0.1.x compatibility wrapper for `ScoriaWeb.ReplayTraceNotebookComponent`.
  """

  use Phoenix.Component

  attr(:step, :map, default: nil)
  attr(:checkpoint, :map, default: nil)
  attr(:comparison, :map, default: nil)
  attr(:selected_source_variant, :string, default: "original")
  attr(:selected_comparison_entry, :map, default: nil)

  def render(assigns) do
    ~H"""
    <ScoriaWeb.ReplayTraceNotebookComponent.render
      step={@step}
      checkpoint={@checkpoint}
      comparison={@comparison}
      selected_source_variant={@selected_source_variant}
      selected_comparison_entry={@selected_comparison_entry}
    />
    """
  end
end
