defmodule ScoriaWeb.WorkflowDetailPanelComponent do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import ScoriaWeb.UI, only: [evidence_rows: 1, panel: 1]

  alias ScoriaWeb.ReplayTraceNotebookComponent
  alias ScoriaWeb.SemanticCacheTraceNotebookComponent

  attr(:step, :map, default: nil)
  attr(:checkpoint, :map, default: nil)
  attr(:comparison, :map, default: nil)
  attr(:semantic_evidence, :map, default: %{})
  attr(:selected_source_variant, :string, default: "original")
  attr(:selected_comparison_entry, :map, default: nil)
  attr(:promotion_context, :map, default: nil)

  def workflow_detail_panel(assigns) do
    ~H"""
    <.panel id="workflow-detail-panel">
      <%= if @step do %>
        <div class="flex items-start justify-between gap-4">
          <div>
            <p class="scoria-eyebrow">Step detail</p>
            <h2>Replay trace</h2>
            <.evidence_rows rows={[{"Role", @step.role_id}, {"kind", @step.kind}]} />
          </div>

          <button
            type="button"
            phx-click={JS.push_focus() |> JS.push("open_promote_modal")}
            phx-value-step-id={@step.id}
            disabled={promotion_disabled?(@promotion_context)}
            class={[
              "scoria-button scoria-button--sm",
              if(promotion_disabled?(@promotion_context),
                do: "scoria-button--ghost",
                else: "scoria-button--primary"
              )
            ]}
          >
            Promote Trace to Draft Dataset
          </button>
        </div>

        <p class="mt-3">
          <%= promotion_helper_copy(@selected_source_variant, @promotion_context) %>
        </p>

        <ReplayTraceNotebookComponent.render
          step={@step}
          checkpoint={@checkpoint}
          comparison={@comparison}
          selected_source_variant={@selected_source_variant}
          selected_comparison_entry={@selected_comparison_entry}
        />

        <SemanticCacheTraceNotebookComponent.render semantic_evidence={@semantic_evidence} />
      <% else %>
        <p>Select a step to inspect checkpoint metadata and failure reasons.</p>
        <SemanticCacheTraceNotebookComponent.render semantic_evidence={@semantic_evidence} />
      <% end %>
    </.panel>
    """
  end

  defp promotion_disabled?(nil), do: true

  defp promotion_disabled?(promotion_context) do
    promotion_context
    |> read_value(:promotion_snapshot)
    |> case do
      value when is_map(value) -> map_size(value) == 0
      _other -> true
    end
  end

  defp promotion_helper_copy(source_variant, promotion_context) do
    case promotion_disabled?(promotion_context) do
      true ->
        "#{variant_label(source_variant)} cannot be promoted until Scoria resolves a frozen promotion snapshot for the selected trace."

      false ->
        "#{variant_label(source_variant)} is active for this draft-dataset promotion."
    end
  end

  defp variant_label("replay"), do: "Replay trace"
  defp variant_label(_variant), do: "Original trace"

  defp read_value(context, key) when is_map(context),
    do: Map.get(context, key, Map.get(context, to_string(key)))

  defp read_value(_context, _key), do: nil
end
