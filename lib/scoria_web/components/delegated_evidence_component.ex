defmodule ScoriaWeb.DelegatedEvidenceComponent do
  use Phoenix.Component
  import ScoriaWeb.UI

  attr(:delegated_handoffs, :list, required: true)

  def render(assigns) do
    ~H"""
    <.notebook
      id="delegated-evidence"
      title="Delegated handoff inspection"
      eyebrow="Delegated Evidence"
      selected_tab="delegated"
      empty={@delegated_handoffs == []}
    >
      <:empty_slot>
        <.evidence_empty title="No Delegated Handoffs Recorded">
          This run stayed on the default runtime lane. No bounded handoff is required for first adoption; use Scoria.start_handoff_run/3 only when a same-run delegation needs narrow projected context.
        </.evidence_empty>
      </:empty_slot>

      <:tab key="delegated" label="Delegated">
        <div class="space-y-4">
          <.evidence_section
            title="Delegated handoffs"
            description="Review bounded delegated lineage from the curated runtime detail instead of reconstructing it from raw workflow rows."
          >
            <:actions>
              <a href="#delegated-evidence" class="scoria-button scoria-button--ghost scoria-button--sm">
                Inspect Delegated Evidence
              </a>
            </:actions>

            <div class="space-y-4">
              <.handoff_section :for={delegated <- @delegated_handoffs} delegated={delegated} />
            </div>
          </.evidence_section>
        </div>
      </:tab>
    </.notebook>
    """
  end

  attr(:delegated, :map, required: true)

  defp handoff_section(assigns) do
    ~H"""
    <.evidence_section
      title={"#{map_value(@delegated, :parent_role_id, "unknown")} to #{map_value(@delegated, :delegated_role_id, "unknown")}"}
      description="Same durable run"
      badge={delegated_status_label(map_value(@delegated, :status, nil))}
      tone={tone(map_value(@delegated, :status, nil))}
    >
      <.evidence_rows
        rows={[
          {"parent role", map_value(@delegated, :parent_role_id, "unknown")},
          {"delegated role", map_value(@delegated, :delegated_role_id, "unknown")},
          {"delegated kind", map_value(@delegated, :delegated_kind, "unknown")},
          {"parent step", map_value(@delegated, :parent_step_id, "unknown")},
          {"child step", map_value(@delegated, :child_step_id, "pending")},
          {"child status", delegated_status_label(map_value(@delegated, :child_status, nil))}
        ]}
      />

      <p :if={map_value(@delegated, :child_status, nil) == "child_step_pending"} class="mt-3">
        The handoff is recorded, but delegated execution has not produced a child-step readback yet.
      </p>

      <div class="mt-3 grid gap-3 lg:grid-cols-2">
        <.evidence_section title="Projected Context Preview">
          <%= if preview_context(@delegated) == [] do %>
            <.evidence_empty title="No projected context recorded yet.">
              No projected context recorded yet.
            </.evidence_empty>
          <% else %>
            <.evidence_rows rows={preview_context(@delegated)} />
          <% end %>
        </.evidence_section>

        <.evidence_section
          :if={map_value(@delegated, :capability_tags, []) != []}
          title="Capability metadata"
          badge={"#{length(map_value(@delegated, :capability_tags, []))} tags"}
          tone={:info}
        >
          <.evidence_rows rows={[{"Capability tags", Enum.join(map_value(@delegated, :capability_tags, []), ", ")}]} />
        </.evidence_section>
      </div>

      <.raw_evidence label="View full context">
    handoff input
    <%= inspect(map_value(@delegated, :handoff_input, %{}), pretty: true) %>

    projected context
    <%= inspect(map_value(@delegated, :projected_context, %{}), pretty: true) %>
      </.raw_evidence>
    </.evidence_section>
    """
  end

  defp preview_context(delegated) do
    delegated
    |> map_value(:projected_context, %{})
    |> sorted_pairs()
    |> Enum.take(3)
    |> Enum.map(fn {key, value} -> {key, preview_value(value)} end)
  end

  defp sorted_pairs(map) when is_map(map),
    do: Enum.sort_by(map, fn {key, _value} -> to_string(key) end)

  defp sorted_pairs(_), do: []

  defp preview_value(value) when is_binary(value) and byte_size(value) > 80 do
    binary_part(value, 0, 77) <> "..."
  end

  defp preview_value(value) when is_binary(value), do: value
  defp preview_value(value), do: inspect(value, pretty: true, limit: 3)

  defp map_value(map, key, default) when is_map(map) do
    cond do
      Map.has_key?(map, key) -> Map.get(map, key)
      Map.has_key?(map, to_string(key)) -> Map.get(map, to_string(key))
      true -> default
    end
  end

  defp map_value(_map, _key, default), do: default

  defp delegated_status_label("child_step_pending"), do: "child step pending"
  defp delegated_status_label(value) when is_binary(value), do: value
  defp delegated_status_label(_value), do: "unknown"
end
