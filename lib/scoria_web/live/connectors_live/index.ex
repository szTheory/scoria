defmodule ScoriaWeb.ConnectorsLive.Index do
  @moduledoc """
  Fleet posture — external runtime presence and connector health, with detail
  drawers. Extracted from the Live Ops god-page so the operator's "are my
  integrations healthy?" job has a focused, linkable surface.
  """
  use Phoenix.LiveView, layout: {ScoriaWeb.Layouts, :app}

  import ScoriaWeb.UI

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
      |> assign(:connector_table_density, :compact)
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

  def handle_event("set_density", %{"density" => density}, socket) do
    density =
      case density do
        "compact" -> :compact
        "comfortable" -> :comfortable
        _ -> :default
      end

    {:noreply, assign(socket, :connector_table_density, density)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="scoria-dashboard relative">
      <div class="scoria-pagehead">
        <h1>Connectors</h1>
        <p>
          External runtime presence and connector health for this tenant. Open a row for its detail drawer.
        </p>
      </div>

      <div class="grid gap-6 lg:grid-cols-2">
        <.panel class="scoria-panel--flush">
          <:eyebrow>external runtimes</:eyebrow>
          <:title>Runtime posture</:title>
          <.table
            id="runtime-presence"
            rows={@runtimes}
            density={@connector_table_density}
            on_density_change="set_density"
          >
            <:col :let={runtime} label="Runtime">
              <span class="font-mono"><%= short_id(runtime.id) %></span>
            </:col>
            <:col :let={runtime} label="Status">
              <.badge tone={tone(runtime.status)} label={runtime.status} />
            </:col>
            <:col :let={runtime} label="Active runs">
              <span class="font-mono"><%= runtime.current_run_id || "None" %></span>
            </:col>
            <:col :let={runtime} label="Presence or Queue">
              <%= runtime.host_session_id || "No host session" %>
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

        <.panel class="scoria-panel--flush">
          <:eyebrow>connector fleet</:eyebrow>
          <:title>Connector posture</:title>
          <.table
            id="connector-fleet"
            rows={@connector_fleet}
            density={@connector_table_density}
            on_density_change="set_density"
          >
            <:col :let={connector} label="Connector">
              <span class="font-semibold"><%= connector.connector_label %></span>
            </:col>
            <:col :let={connector} label="Health">
              <.badge tone={tone(connector.health_state)} label={connector.health_state} />
            </:col>
            <:col :let={connector} label="Auth or Provenance">
              <%= connector.auth_provenance.status %>
            </:col>
            <:col :let={connector} label="Refresh state">
              <.badge tone={tone(connector.last_refresh_status)} label={connector.last_refresh_status} />
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
            <:empty>
              <.empty_state title="No connectors registered">
                Connector activity appears here after a tenant registers a connector.
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

    socket
    |> assign(:runtimes, OperatorSurface.load_runtimes(tenant_id))
    |> assign(:connector_fleet, OperatorSurface.connector_fleet(tenant_id))
  end

  defp short_id(nil), do: "Not recorded"
  defp short_id(id), do: id |> to_string() |> String.slice(0, 8)

  defp format_ts(nil), do: "Not recorded"
  defp format_ts(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  defp format_ts(other), do: to_string(other)
end
