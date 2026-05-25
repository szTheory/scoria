defmodule ScoriaWeb.SemanticEvidenceNotebookComponent do
  use Phoenix.Component

  attr :semantic_evidence, :map, default: %{}

  def render(assigns) do
    ~H"""
    <section
      :if={present?(@semantic_evidence)}
      class="mt-4 rounded-xl border border-stone-200 bg-stone-50 p-4 shadow-sm"
    >
      <div class="mb-4">
        <p class="text-xs uppercase tracking-[0.24em] text-stone-500">semantic evidence notebook</p>
        <h3 class="text-lg font-semibold text-stone-900">Semantic fast-path inspection</h3>
        <p class="mt-1 text-sm text-stone-600">
          Workflow evidence keeps semantic verdict, compatibility, provenance, lifecycle, and append-only events on one page.
        </p>
      </div>

      <div class="grid gap-4 xl:grid-cols-[1.1fr,0.9fr]">
        <div class="space-y-4">
          <.group_card title="Summary" group={read_group(@semantic_evidence, :summary)} />
          <.group_card title="Compatibility" group={read_group(@semantic_evidence, :compatibility)} />
          <.group_card title="Provenance" group={read_group(@semantic_evidence, :provenance)} />
        </div>

        <div class="space-y-4">
          <.group_card title="Lifecycle" group={read_group(@semantic_evidence, :lifecycle)} />
          <.group_card title="Candidate" group={read_group(@semantic_evidence, :candidate)} />
          <.events_card events={read_events(@semantic_evidence)} />
        </div>
      </div>

      <details class="mt-4 rounded-lg border border-stone-200 bg-white p-4">
        <summary class="cursor-pointer text-sm font-semibold text-stone-900">Advanced raw evidence</summary>
        <pre class="mt-3 overflow-x-auto whitespace-pre-wrap rounded-md bg-stone-50 p-3 text-xs text-stone-700"><%= Jason.encode_to_iodata!(normalize_for_json(@semantic_evidence), pretty: true) %></pre>
      </details>
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
          <p class="mt-1 text-xs text-stone-500">Curated semantic evidence from runtime metadata and durable cache truth.</p>
        </div>
        <span class={badge_class(card_status(@group))}><%= card_status(@group) %></span>
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

  attr :events, :list, default: []

  defp events_card(assigns) do
    ~H"""
    <div class="rounded-lg border border-stone-200 bg-white p-4">
      <div class="flex items-start justify-between gap-3">
        <div>
          <h4 class="text-sm font-semibold text-stone-900">Append-only events</h4>
          <p class="mt-1 text-xs text-stone-500">Semantic entry events stay inspectable instead of collapsing into a generic miss.</p>
        </div>
        <span class={badge_class(if(@events == [], do: "empty", else: "recorded"))}>
          <%= if @events == [], do: "empty", else: "recorded" %>
        </span>
      </div>

      <div :if={@events == []} class="mt-3 rounded-md bg-stone-50 p-3 text-sm text-stone-600">
        No semantic entry events recorded.
      </div>

      <ol :if={@events != []} class="mt-3 space-y-3">
        <li :for={event <- @events} class="rounded-md bg-stone-50 p-3 text-sm text-stone-700">
          <p class="font-medium text-stone-900">
            <%= map_value(event, :event_kind) %>
            <span class="ml-2 rounded-full border border-stone-200 bg-white px-2 py-0.5 text-[11px] font-semibold uppercase tracking-[0.18em] text-stone-700">
              <%= map_value(event, :entry_role) %>
            </span>
          </p>
          <p :if={map_value(event, :reason_code)} class="mt-1 text-xs text-stone-600">
            reason_code: <span class="font-mono"><%= map_value(event, :reason_code) %></span>
          </p>
        </li>
      </ol>
    </div>
    """
  end

  defp present?(semantic_evidence) when is_map(semantic_evidence), do: map_size(semantic_evidence) > 0
  defp present?(_semantic_evidence), do: false

  defp read_group(entry, key) when is_map(entry), do: Map.get(entry, key, %{})
  defp read_group(_entry, _key), do: %{}

  defp read_events(entry) when is_map(entry), do: Map.get(entry, :events, [])
  defp read_events(_entry), do: []

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

  defp render_value("semantic_reuse"), do: "Semantic fast path reused a cached answer."
  defp render_value("live_execution_admitted"), do: "Normal runtime path executed and admitted fresh semantic evidence."
  defp render_value("live_execution_writeback_rejected"), do: "Normal runtime path executed and writeback_rejected semantic evidence."
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

  defp badge_class("empty"),
    do: "rounded-full border border-amber-200 bg-amber-50 px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-amber-800"

  defp badge_class(_value),
    do: "rounded-full border border-emerald-200 bg-emerald-50 px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-emerald-800"

  defp map_value(map, key) when is_map(map), do: Map.get(map, key)
  defp map_value(_map, _key), do: nil
end
