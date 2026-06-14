defmodule ScoriaWeb.ApprovalInboxComponent do
  use Phoenix.Component

  import ScoriaWeb.UI

  attr(:approvals, :list, required: true)
  attr(:highlight_approval_id, :string, default: nil)
  attr(:density, :atom, default: :compact)
  attr(:on_density_change, :string, default: nil)
  attr(:select_event, :string, default: nil)

  def render(assigns) do
    ~H"""
    <.panel class="scoria-panel--flush">
      <:eyebrow>approvals</:eyebrow>
      <:title>Approval inbox</:title>

      <.table
        id="approvals"
        rows={@approvals}
        density={@density}
        on_density_change={@on_density_change}
      >
        <:col :let={approval} label="Approval">
          <span data-highlight={approval_field(approval, :id) == @highlight_approval_id && "true"}>
            <span class="font-semibold"><%= approval_field(approval, :tool_name) %></span>
            <.badge
              :if={approval_field(approval, :id) == @highlight_approval_id}
              tone={:warn}
              label="New"
              dot={false}
              class="ml-2"
            />
          </span>
        </:col>
        <:col :let={approval} label="Workflow">
          <span class="font-mono"><%= short_id(approval_field(approval, :workflow_run_id)) %></span>
        </:col>
        <:col :let={approval} label="Requested by">
          <%= approval_field(approval, :actor_id) || approval_field(approval, :session_id) || "operator" %>
        </:col>
        <:col :let={_approval} label="Consequence">
          Approval resumes when possible; rejection keeps the workflow paused.
        </:col>
        <:col :let={approval} label="Requested">
          <%= format_requested(approval_field(approval, :inserted_at)) %>
        </:col>
        <:col :let={approval} label="Status">
          <.badge tone={tone(approval_field(approval, :status))} label={status_label(approval_field(approval, :status))} />
        </:col>
        <:action :let={approval}>
          <button
            type="button"
            phx-click={@select_event}
            phx-value-id={@select_event && approval_field(approval, :id)}
            class="scoria-button scoria-button--ghost scoria-button--sm"
          >
            Inspect approval
          </button>
        </:action>
        <:empty>
          <.empty_state title="No approvals waiting">
            The first workflow-owned approval request will appear here with its consequence and status.
          </.empty_state>
        </:empty>
      </.table>
    </.panel>
    """
  end

  defp approval_field(approval, field) do
    Map.get(approval, field) || Map.get(approval, Atom.to_string(field))
  end

  defp short_id(nil), do: "Not recorded"
  defp short_id(id), do: id |> to_string() |> String.slice(0, 8)

  defp format_requested(nil), do: "Not recorded"
  defp format_requested(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  defp format_requested(other), do: to_string(other)
end
