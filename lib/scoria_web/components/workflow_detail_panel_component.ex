defmodule ScoriaWeb.WorkflowDetailPanelComponent do
  use Phoenix.Component

  alias ScoriaWeb.ReplayEvidenceNotebookComponent

  attr :step, :map, default: nil
  attr :checkpoint, :map, default: nil
  attr :comparison, :map, default: nil
  attr :selected_source_variant, :string, default: "original"
  attr :selected_comparison_entry, :map, default: nil
  attr :promotion_context, :map, default: nil

  def workflow_detail_panel(assigns) do
    ~H"""
    <aside id="workflow-detail-panel" class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
      <%= if @step do %>
        <div class="flex items-start justify-between gap-4">
          <div>
            <p class="text-xs uppercase tracking-[0.22em] text-stone-500">Step detail</p>
            <h2 class="mt-1 text-lg font-semibold">Replay evidence</h2>
            <p class="mt-1 text-sm text-stone-600">
              Role <span class="font-medium text-stone-900"><%= @step.role_id %></span>
              · kind <span class="font-medium text-stone-900"><%= @step.kind %></span>
            </p>
          </div>

          <button
            type="button"
            phx-click="open_promote_modal"
            phx-value-step-id={@step.id}
            disabled={promotion_disabled?(@promotion_context)}
            class={[
              "rounded-md px-3 py-1.5 text-sm font-medium",
              if(promotion_disabled?(@promotion_context),
                do: "cursor-not-allowed border border-stone-200 bg-stone-100 text-stone-400",
                else: "bg-blue-600 text-white hover:bg-blue-700"
              )
            ]}
          >
            Promote Trace to Draft Dataset
          </button>
        </div>

        <p class="mt-3 text-sm text-stone-600">
          <%= promotion_helper_copy(@selected_source_variant, @promotion_context) %>
        </p>

        <ReplayEvidenceNotebookComponent.render
          step={@step}
          checkpoint={@checkpoint}
          comparison={@comparison}
          selected_source_variant={@selected_source_variant}
          selected_comparison_entry={@selected_comparison_entry}
        />
      <% else %>
        <p class="text-sm text-stone-500">Select a step to inspect checkpoint metadata and failure reasons.</p>
      <% end %>
    </aside>
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
        "#{variant_label(source_variant)} cannot be promoted until Scoria resolves a frozen promotion snapshot for the selected evidence."

      false ->
        "#{variant_label(source_variant)} is active for this draft-dataset promotion."
    end
  end

  defp variant_label("replay"), do: "Replay trace"
  defp variant_label(_variant), do: "Original trace"

  defp read_value(context, key) when is_map(context), do: Map.get(context, key, Map.get(context, to_string(key)))
  defp read_value(_context, _key), do: nil
end
