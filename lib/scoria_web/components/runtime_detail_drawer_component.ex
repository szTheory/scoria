defmodule ScoriaWeb.RuntimeDetailDrawerComponent do
  use Phoenix.Component

  import ScoriaWeb.UI,
    only: [evidence_action_row: 1, evidence_rows: 1, evidence_section: 1, tone: 1]

  attr(:drawer, :map, default: nil)

  def render(assigns) do
    ~H"""
    <%= if @drawer do %>
      <.evidence_section title="Runtime identity" badge={@drawer.status} tone={tone(@drawer.status)}>
        <.evidence_rows rows={[
          {"Runtime", @drawer.id},
          {"Host session", @drawer.host_session_id},
          {"Transport", @drawer.transport_kind},
          {"Last seen", Map.get(@drawer, :last_seen_at)}
        ]} />
      </.evidence_section>

      <%= if @drawer.status == "offline" && @drawer.terminal_offline_reason do %>
        <.evidence_section title="Terminal offline reason" badge="Offline" tone={:fail}>
          <p><%= @drawer.terminal_offline_reason %></p>
        </.evidence_section>
      <% end %>

      <%= if @drawer.current_run_id do %>
        <.evidence_section title="Active workflow">
          <.evidence_action_row>
            <.link navigate={"/workflows/#{@drawer.current_run_id}"} class="scoria-button scoria-button--ghost scoria-button--sm">
              View run <%= @drawer.current_run_id %>
            </.link>
          </.evidence_action_row>
        </.evidence_section>
      <% end %>

      <%= if semantic_present?(@drawer.semantic) do %>
        <.evidence_section
          title="Semantic summary"
          description={fallback_copy(@drawer.semantic)}
          badge={@drawer.semantic.lookup_status}
          tone={tone(@drawer.semantic.lookup_status)}
        >
          <.evidence_rows rows={[
            {"lookup_status", @drawer.semantic.lookup_status},
            {"scope_kind", @drawer.semantic.scope_kind},
            {"lane_key", @drawer.semantic.lane_key},
            {"scope_reason", @drawer.semantic.scope_reason},
            {"reason_code", @drawer.semantic.reason_code}
          ]} />

          <p :if={@drawer.semantic.scope_kind == "actor_scoped" and present?(@drawer.semantic.actor_id)}>
            Actor scope: <span class="font-medium"><%= @drawer.semantic.actor_id %></span>
          </p>

          <.evidence_action_row>
            <.link navigate={@drawer.semantic.workflow_href} class="scoria-button scoria-button--ghost scoria-button--sm">
              View workflow evidence
            </.link>

            <.link
              :if={present?(@drawer.semantic.origin_run_href)}
              navigate={@drawer.semantic.origin_run_href}
              class="scoria-button scoria-button--ghost scoria-button--sm"
            >
              View origin run
            </.link>
          </.evidence_action_row>
        </.evidence_section>
      <% end %>
    <% end %>
    """
  end

  defp semantic_present?(semantic) when is_map(semantic), do: map_size(semantic) > 0
  defp semantic_present?(_semantic), do: false

  defp fallback_copy(%{fallback_outcome: "semantic_reuse"}),
    do: "Semantic fast path reused a cached answer."

  defp fallback_copy(%{fallback_outcome: "live_execution_admitted"}),
    do: "Normal runtime path executed and admitted fresh semantic evidence."

  defp fallback_copy(%{fallback_outcome: "live_execution_writeback_rejected"}),
    do: "Normal runtime path executed and writeback_rejected semantic evidence."

  defp fallback_copy(%{fallback_outcome: outcome})
       when outcome in ["normal_runtime_path_executed", nil],
       do: "Normal runtime path executed."

  defp fallback_copy(_semantic), do: "Normal runtime path executed."

  defp present?(value) when is_binary(value), do: value != ""
  defp present?(value), do: not is_nil(value)
end
