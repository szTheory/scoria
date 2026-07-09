defmodule ScoriaWeb.ReplayTraceNotebookComponent do
  @moduledoc """
  Reviewer-facing replay trace notebook component.
  """

  use Phoenix.Component
  import ScoriaWeb.UI

  attr(:step, :map, default: nil)
  attr(:checkpoint, :map, default: nil)
  attr(:comparison, :map, default: nil)
  attr(:selected_source_variant, :string, default: "original")
  attr(:selected_comparison_entry, :map, default: nil)

  def render(assigns) do
    ~H"""
    <.notebook
      id="replay-trace-notebook"
      title="Replay trace notebook"
      eyebrow="replay trace notebook"
      selected_tab="comparison"
    >
      <:tab key="comparison" label="Comparison">
        <div class="space-y-4">
          <.evidence_section
            title="Trace comparison"
            description="Grouped replay trace details stay structured by provenance, overrides, outcome, safety, and promotion readiness."
          >
            <:actions>
              <div :if={toggle_visible?(@comparison)} class="flex flex-wrap gap-2">
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
            </:actions>

            <%= if comparison_ready?(@selected_comparison_entry) do %>
              <div class="scoria-evidence-split">
                <div class="space-y-4">
                  <.group_section title="Provenance" group={read_group(@selected_comparison_entry, :provenance)} />
                  <.group_section title="Overrides" group={read_group(@selected_comparison_entry, :overrides)} />
                  <.group_section
                    title="Checkpoint / Output"
                    group={read_group(@selected_comparison_entry, :checkpoint_output)}
                  />
                </div>

                <div class="space-y-4">
                  <.group_section title="Safety Evidence" group={read_group(@selected_comparison_entry, :safety)} />
                  <.group_section
                    title="Promotion Snapshot Summary"
                    group={read_group(@selected_comparison_entry, :promotion_snapshot)}
                  />
                </div>
              </div>

              <.raw_evidence label="Advanced raw trace">
                <%= Jason.encode_to_iodata!(normalize_for_json(@selected_comparison_entry), pretty: true) %>
              </.raw_evidence>
            <% else %>
              <.evidence_empty title="No Replay Comparison Available">
                Select a workflow step with durable checkpoint evidence to compare the original run against its replay branch. Promotion stays disabled until Scoria can freeze an evidence snapshot for the selected trace.
              </.evidence_empty>
            <% end %>
          </.evidence_section>
        </div>
      </:tab>
    </.notebook>
    """
  end

  attr(:title, :string, required: true)
  attr(:group, :map, default: %{})

  defp group_section(assigns) do
    ~H"""
    <.evidence_section
      title={@title}
      description="Structured trace details projected from durable runtime DTOs."
      badge={card_status(@group)}
      tone={status_tone(card_status(@group))}
    >
      <.evidence_rows rows={field_rows(@group)} />
    </.evidence_section>
    """
  end

  defp toggle_visible?(comparison) when is_map(comparison) do
    map_size(comparison) > 0 and Map.has_key?(comparison, :original) and
      Map.has_key?(comparison, :replay)
  end

  defp toggle_visible?(_comparison), do: false

  defp comparison_ready?(selected_comparison_entry) when is_map(selected_comparison_entry),
    do: map_size(selected_comparison_entry) > 0

  defp comparison_ready?(_selected_comparison_entry), do: false

  defp toggle_class(true), do: "scoria-button scoria-button--primary scoria-button--sm"
  defp toggle_class(false), do: "scoria-button scoria-button--ghost scoria-button--sm"

  defp read_group(entry, key) when is_map(entry), do: Map.get(entry, key, %{})
  defp read_group(_entry, _key), do: %{}

  defp field_rows(group) do
    group
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.map(fn {key, value} -> {field_label(key), render_value(value)} end)
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

  defp status_tone("empty"), do: :warn
  defp status_tone("recorded"), do: :pass
  defp status_tone(_value), do: :neutral
end
