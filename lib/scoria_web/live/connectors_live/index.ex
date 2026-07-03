defmodule ScoriaWeb.ConnectorsLive.Index do
  @moduledoc """
  Fleet posture — external runtime presence and connector health, with detail
  drawers. Extracted from the Live Ops god-page so the operator's "are my
  integrations healthy?" job has a focused, linkable surface.
  """
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}

  import ScoriaWeb.UI

  alias ScoriaWeb.ConnectorCopy
  alias ScoriaWeb.ConnectorDetailDrawerComponent
  alias ScoriaWeb.OperatorSurface
  alias ScoriaWeb.RuntimeDetailDrawerComponent

  @impl true
  def mount(params, session, socket) do
    tenant_id = params["tenant"] || session["tenant_id"] || "default"

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Scoria.PubSub, "mcp:runtimes:#{tenant_id}")
    end

    socket =
      socket
      |> assign(:page_title, "Connectors")
      |> assign(:tenant_id, tenant_id)
      |> assign(:runtime_drawer, nil)
      |> assign(:connector_drawer, nil)
      |> load_fleet()

    {:ok, socket}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, load_fleet(socket)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @impl true
  def handle_event("open_runtime_drawer", %{"id" => id}, socket) do
    runtime = Enum.find(socket.assigns.runtimes, &(&1.id == id))
    {:noreply, assign(socket, :runtime_drawer, runtime)}
  end

  def handle_event("close_runtime_drawer", _, socket) do
    {:noreply, assign(socket, :runtime_drawer, nil)}
  end

  def handle_event("open_connector_drawer", %{"id" => connector_id}, socket) do
    {:noreply, assign(socket, :connector_drawer, OperatorSurface.connector_drawer(connector_id))}
  end

  def handle_event("close_connector_drawer", _, socket) do
    {:noreply, assign(socket, :connector_drawer, nil)}
  end

  def handle_event("retry_load", _, socket) do
    {:noreply, load_fleet(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="scoria-dashboard relative">
      <.page_header title="Connectors">
        <:summary>
          External runtime presence and connector health for this tenant. Open a row for its detail drawer.
        </:summary>
      </.page_header>

      <div :if={@load_error} class="mt-6">
        <div class="scoria-flash scoria-flash--fail" role="alert">
          Connector and runtime data could not be loaded right now.
        </div>
        <div class="mt-4">
          <.button type="button" phx-click="retry_load" variant={:ghost} size={:sm}>Retry</.button>
        </div>
      </div>

      <div :if={!@load_error} class="grid gap-6 lg:grid-cols-2">
        <.panel flush={true}>
          <:eyebrow>external runtimes</:eyebrow>
          <:title>Runtime posture</:title>
          <.table id="runtime-presence" rows={@runtimes}>
            <:col :let={runtime} label="Runtime">
              <span class="font-mono"><%= short_id(runtime.id) %></span>
            </:col>
            <:col :let={runtime} label="Status">
              <.badge tone={tone(runtime.status)} label={ConnectorCopy.runtime_status_label(runtime.status)} />
            </:col>
            <:col :let={runtime} label="Active runs">
              <%= if runtime.current_run_id do %>
                <.id value={runtime.current_run_id} id={"run-id-#{runtime.id}"} title="Active run ID" />
              <% else %>
                <span>None</span>
              <% end %>
            </:col>
            <:col :let={runtime} label="Presence or Queue">
              <%= if runtime.host_session_id do %>
                <.id value={runtime.host_session_id} id={"host-session-#{runtime.id}"} title="Host session ID" />
              <% else %>
                <span>No host session</span>
              <% end %>
            </:col>
            <:col :let={runtime} label="Last seen">
              <%= format_ts(runtime[:last_seen_at]) %>
            </:col>
            <:action :let={runtime}>
              <button
                type="button"
                phx-click="open_runtime_drawer"
                phx-value-id={runtime.id}
                class="scoria-button scoria-button--ghost scoria-button--sm"
              >
                Inspect runtime
              </button>
            </:action>
            <:empty>
              <.empty_state title="No runtimes connected">
                Runtime activity appears here once a host session connects for this tenant.
              </.empty_state>
            </:empty>
          </.table>
        </.panel>

        <.panel flush={true}>
          <:eyebrow>connector fleet</:eyebrow>
          <:title>Connector posture</:title>
          <.table id="connector-fleet" rows={@connector_fleet}>
            <:col :let={connector} label="Connector">
              <span class="font-semibold"><%= connector.connector_label %></span>
            </:col>
            <:col :let={connector} label="Health">
              <.badge tone={tone(connector.health_state)} label={ConnectorCopy.health_label(connector.health_state)} />
            </:col>
            <:col :let={connector} label="Auth or Provenance">
              <%= connector.auth_provenance.status %>
            </:col>
            <:col :let={connector} label="Refresh state">
              <.badge tone={tone(connector.last_refresh_status)} label={status_label(connector.last_refresh_status)} />
            </:col>
            <:col :let={connector} label="Last checked">
              pending tools <%= connector.pending_local_tool_count %>, approvals <%= connector.pending_approval_count %>
            </:col>
            <:action :let={connector}>
              <button
                type="button"
                phx-click="open_connector_drawer"
                phx-value-id={connector.connector_id}
                class="scoria-button scoria-button--ghost scoria-button--sm"
              >
                Inspect connector
              </button>
            </:action>
            <:mobile_summary :let={connector}>
              <div class="scoria-mobile-summary">
                <div class="scoria-mobile-summary__label">
                  <span class="font-semibold">{connector.connector_label}</span>
                </div>
                <div class="scoria-mobile-summary__status">
                  <.badge tone={tone(connector.health_state)} label={ConnectorCopy.health_label(connector.health_state)} />
                </div>
                <div class="scoria-mobile-summary__meta">
                  {connector.auth_provenance.status}
                </div>
                <div class="scoria-mobile-summary__action">
                  <button
                    type="button"
                    phx-click="open_connector_drawer"
                    phx-value-id={connector.connector_id}
                    class="scoria-button scoria-button--ghost scoria-button--sm"
                  >
                    Inspect connector
                  </button>
                </div>
              </div>
            </:mobile_summary>
            <:empty>
              <.empty_state title="No connectors match this view">
                Adjust your filters or check back when data is available.
              </.empty_state>
            </:empty>
          </.table>
        </.panel>
      </div>

      <.drawer :if={@runtime_drawer} id="runtime-detail-drawer" show={true} on_dismiss="close_runtime_drawer">
        <:eyebrow>Runtime detail</:eyebrow>
        <:title_slot><%= @runtime_drawer.id %></:title_slot>
        <RuntimeDetailDrawerComponent.render drawer={@runtime_drawer} />
      </.drawer>

      <.drawer :if={@connector_drawer} id="connector-detail-drawer" show={true} on_dismiss="close_connector_drawer">
        <:eyebrow>Connector detail</:eyebrow>
        <:title_slot><%= @connector_drawer.connector_label %></:title_slot>
        <ConnectorDetailDrawerComponent.render drawer={@connector_drawer} />
      </.drawer>
    </div>
    """
  end

  defp load_fleet(socket) do
    tenant_id = socket.assigns.tenant_id

    case fetch_fleet(tenant_id) do
      {:ok, runtimes, connector_fleet} ->
        socket
        |> assign(:load_error, false)
        |> assign(:runtimes, runtimes)
        |> assign(:connector_fleet, connector_fleet)

      :error ->
        socket
        |> assign(:load_error, true)
        |> assign(:runtimes, [])
        |> assign(:connector_fleet, [])
    end
  end

  # D-08: distinguish a genuine fleet-query failure (renders inline scoria-flash--fail +
  # retry) from a legitimately empty fleet (renders empty_state/1 via each table's :empty
  # slot) instead of letting an unrescued query crash the LiveView.
  defp fetch_fleet(tenant_id) do
    {:ok, OperatorSurface.load_runtimes(tenant_id), OperatorSurface.connector_fleet(tenant_id)}
  rescue
    _ -> :error
  end

  defp short_id(nil), do: "Not recorded"
  defp short_id(id), do: id |> to_string() |> String.slice(0, 8)

  defp format_ts(nil), do: "Not recorded"
  defp format_ts(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  defp format_ts(other), do: to_string(other)
end
