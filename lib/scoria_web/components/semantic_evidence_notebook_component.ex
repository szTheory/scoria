defmodule ScoriaWeb.SemanticEvidenceNotebookComponent do
  use Phoenix.Component
  import ScoriaWeb.UI

  attr(:semantic_evidence, :map, default: %{})

  def render(assigns) do
    ~H"""
    <.notebook
      :if={present?(@semantic_evidence)}
      id="semantic-evidence-notebook"
      title="Semantic fast-path inspection"
      eyebrow="semantic evidence notebook"
      selected_tab="semantic"
    >
      <:tab key="semantic" label="Semantic">
        <div class="space-y-4">
          <.evidence_section
            title="Semantic evidence groups"
            description="Workflow evidence keeps semantic verdict, compatibility, provenance, lifecycle, and append-only events on one page."
          >
            <div class="grid gap-4 xl:grid-cols-[1.1fr,0.9fr]">
              <div class="space-y-4">
                <.group_section title="Summary" group={read_group(@semantic_evidence, :summary)} />
                <.group_section title="Compatibility" group={read_group(@semantic_evidence, :compatibility)} />
                <.group_section title="Provenance" group={read_group(@semantic_evidence, :provenance)} />
              </div>

              <div class="space-y-4">
                <.group_section title="Lifecycle" group={read_group(@semantic_evidence, :lifecycle)} />
                <.group_section title="Candidate" group={read_group(@semantic_evidence, :candidate)} />
                <.events_section events={read_events(@semantic_evidence)} />
              </div>
            </div>

            <.raw_evidence label="Advanced raw evidence">
              <%= Jason.encode_to_iodata!(normalize_for_json(@semantic_evidence), pretty: true) %>
            </.raw_evidence>
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
      description="Curated semantic evidence from runtime metadata and durable cache truth."
      badge={card_status(@group)}
      tone={notebook_tone(card_status(@group))}
    >
      <.evidence_rows rows={field_rows(@group)} />
    </.evidence_section>
    """
  end

  attr(:events, :list, default: [])

  defp events_section(assigns) do
    ~H"""
    <.evidence_section
      title="Append-only events"
      description="Semantic entry events stay inspectable instead of collapsing into a generic miss."
      badge={if(@events == [], do: "empty", else: "recorded")}
      tone={notebook_tone(if(@events == [], do: "empty", else: "recorded"))}
    >
      <%= if @events == [] do %>
        <.evidence_empty title="No semantic entry events recorded.">
          No semantic entry events recorded.
        </.evidence_empty>
      <% else %>
        <div class="space-y-3">
          <.evidence_section :for={event <- @events} title={map_value(event, :event_kind, "event")}>
            <:actions>
              <.badge
                tone={:neutral}
                label={to_string(map_value(event, :entry_role, "unknown"))}
                dot={false}
              />
            </:actions>

            <.evidence_rows
              rows={[
                {"entry role", map_value(event, :entry_role, "unknown")},
                {"reason_code", map_value(event, :reason_code, nil)}
              ]}
            />
          </.evidence_section>
        </div>
      <% end %>
    </.evidence_section>
    """
  end

  defp present?(semantic_evidence) when is_map(semantic_evidence),
    do: map_size(semantic_evidence) > 0

  defp present?(_semantic_evidence), do: false

  defp read_group(entry, key) when is_map(entry), do: Map.get(entry, key, %{})
  defp read_group(_entry, _key), do: %{}

  defp read_events(entry) when is_map(entry), do: Map.get(entry, :events, [])
  defp read_events(_entry), do: []

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

  defp render_value("semantic_reuse"), do: "Semantic fast path reused a cached answer."

  defp render_value("live_execution_admitted"),
    do: "Normal runtime path executed and admitted fresh semantic evidence."

  defp render_value("live_execution_writeback_rejected"),
    do: "Normal runtime path executed and writeback_rejected semantic evidence."

  defp render_value("normal_runtime_path_executed"), do: "Normal runtime path executed."
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

  defp normalize_for_json(%_{} = value) do
    cond do
      String.Chars.impl_for(value) != nil -> to_string(value)
      true -> inspect(value)
    end
  end

  defp normalize_for_json(value) when is_map(value) do
    Map.new(value, fn {key, map_value} -> {to_string(key), normalize_for_json(map_value)} end)
  end

  defp normalize_for_json(value) when is_list(value), do: Enum.map(value, &normalize_for_json/1)
  defp normalize_for_json(value), do: value

  defp notebook_tone("empty"), do: :warn
  defp notebook_tone(_value), do: :pass

  defp map_value(map, key, default) when is_map(map) do
    cond do
      Map.has_key?(map, key) -> Map.get(map, key)
      Map.has_key?(map, to_string(key)) -> Map.get(map, to_string(key))
      true -> default
    end
  end

  defp map_value(_map, _key, default), do: default
end
