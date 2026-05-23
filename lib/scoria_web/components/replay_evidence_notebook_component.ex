defmodule ScoriaWeb.ReplayEvidenceNotebookComponent do
  use Phoenix.Component

  attr :step, :map, default: nil
  attr :checkpoint, :map, default: nil
  attr :comparison, :map, default: nil
  attr :selected_source_variant, :string, default: "original"
  attr :selected_comparison_entry, :map, default: nil

  def render(assigns) do
    ~H"""
    <section class="mt-4 rounded-xl border border-stone-200 bg-stone-50 p-4 shadow-sm">
      <div class="mb-4 flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <p class="text-xs uppercase tracking-[0.24em] text-stone-500">replay evidence notebook</p>
          <h3 class="text-lg font-semibold text-stone-900">Original-versus-replay comparison</h3>
          <p class="mt-1 text-sm text-stone-600">
            Grouped operator evidence stays structured by provenance, overrides, outcome, safety, and promotion readiness.
          </p>
        </div>

        <div :if={toggle_visible?(@comparison)} class="inline-flex rounded-full border border-stone-200 bg-white p-1">
          <button
            type="button"
            phx-click="select_comparison_source"
            phx-value-source="original"
            class={toggle_class(@selected_source_variant == "original")}
          >
            Original trace
          </button>
          <button
            type="button"
            phx-click="select_comparison_source"
            phx-value-source="replay"
            class={toggle_class(@selected_source_variant == "replay")}
          >
            Replay trace
          </button>
        </div>
      </div>

      <%= if comparison_ready?(@selected_comparison_entry) do %>
        <div class="mt-4 grid gap-4 xl:grid-cols-[1.25fr,0.9fr]">
          <div class="space-y-4">
            <.group_card title="Provenance" group={read_group(@selected_comparison_entry, :provenance)} />
            <.group_card title="Overrides" group={read_group(@selected_comparison_entry, :overrides)} />
            <.group_card
              title="Checkpoint / Output"
              group={read_group(@selected_comparison_entry, :checkpoint_output)}
            />
          </div>

          <div class="space-y-4">
            <.group_card title="Safety Evidence" group={read_group(@selected_comparison_entry, :safety)} />
            <.group_card
              title="Promotion Snapshot Summary"
              group={read_group(@selected_comparison_entry, :promotion_snapshot)}
            />
          </div>
        </div>

        <details class="mt-4 rounded-lg border border-stone-200 bg-white p-4">
          <summary class="cursor-pointer text-sm font-semibold text-stone-900">Advanced raw evidence</summary>
          <pre class="mt-3 overflow-x-auto whitespace-pre-wrap rounded-md bg-stone-50 p-3 text-xs text-stone-700"><%= Jason.encode_to_iodata!(normalize_for_json(@selected_comparison_entry), pretty: true) %></pre>
        </details>
      <% else %>
        <div class="rounded-xl border border-stone-200 bg-white p-5">
          <p class="text-xs uppercase tracking-[0.22em] text-stone-500">comparison unavailable</p>
          <h4 class="mt-2 text-lg font-semibold text-stone-900">No Replay Comparison Available</h4>
          <p class="mt-2 text-sm text-stone-600">
            Select a workflow step with durable checkpoint evidence to compare the original run against its replay branch. Promotion stays disabled until Scoria can freeze an evidence snapshot for the selected trace.
          </p>
        </div>
      <% end %>
    </section>
    """
  end

  attr :title, :string, required: true
  attr :group, :map, default: %{}

  defp group_card(assigns) do
    ~H"""
    <div class="rounded-lg border border-stone-200 bg-white p-4">
      <div class="flex items-start justify-between gap-3">
        <div>
          <h4 class="text-sm font-semibold text-stone-900"><%= @title %></h4>
          <p class="mt-1 text-xs text-stone-500">Structured evidence projected from durable runtime DTOs.</p>
        </div>
        <span class={badge_class(card_status(@group), :status)}><%= card_status(@group) %></span>
      </div>

      <dl class="mt-3 space-y-3 text-sm text-stone-700">
        <div :for={{label, value} <- field_rows(@group)} class="rounded-md bg-stone-50 p-3">
          <dt class="text-xs uppercase tracking-[0.18em] text-stone-500"><%= label %></dt>
          <dd class="mt-2 font-medium text-stone-900"><%= render_value(value) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  defp toggle_visible?(comparison) when is_map(comparison) do
    map_size(comparison) > 0 and Map.has_key?(comparison, :original) and Map.has_key?(comparison, :replay)
  end

  defp toggle_visible?(_comparison), do: false

  defp comparison_ready?(selected_comparison_entry) when is_map(selected_comparison_entry),
    do: map_size(selected_comparison_entry) > 0

  defp comparison_ready?(_selected_comparison_entry), do: false

  defp toggle_class(true) do
    "rounded-full bg-blue-600 px-3 py-1.5 text-sm font-medium text-white"
  end

  defp toggle_class(false) do
    "rounded-full px-3 py-1.5 text-sm font-medium text-stone-600 hover:bg-stone-100"
  end

  defp read_group(entry, key) when is_map(entry), do: Map.get(entry, key, %{})
  defp read_group(_entry, _key), do: %{}

  defp field_rows(group) do
    group
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.map(fn {key, value} -> {field_label(key), value} end)
  end

  defp field_label(key) do
    key
    |> to_string()
    |> String.replace("_", " ")
  end

  defp render_value(value) when is_binary(value), do: value
  defp render_value(value) when is_boolean(value), do: if(value, do: "true", else: "false")
  defp render_value(value) when is_number(value), do: to_string(value)
  defp render_value(value) when is_list(value), do: Enum.join(Enum.map(value, &to_string/1), ", ")

  defp render_value(value) when is_map(value) do
    if map_size(value) == 0 do
      "No structured values recorded"
    else
      Jason.encode_to_iodata!(normalize_for_json(value), pretty: true)
    end
  end

  defp render_value(value), do: inspect(value)

  defp card_status(group) when is_map(group) and map_size(group) > 0, do: "recorded"
  defp card_status(_group), do: "empty"

  defp normalize_for_json(value) when is_map(value) do
    Map.new(value, fn {key, map_value} -> {to_string(key), normalize_for_json(map_value)} end)
  end

  defp normalize_for_json(value) when is_list(value), do: Enum.map(value, &normalize_for_json/1)
  defp normalize_for_json(value), do: value

  defp badge_class(value, kind) do
    base = "rounded-full px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.18em]"

    tone =
      case {kind, value} do
        {:status, "empty"} -> "border border-amber-200 bg-amber-50 text-amber-800"
        {:status, "recorded"} -> "border border-emerald-200 bg-emerald-50 text-emerald-800"
        _ -> "border border-stone-200 bg-stone-100 text-stone-700"
      end

    [base, tone]
  end
end
