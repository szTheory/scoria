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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="scoria-dashboard relative">
      <div class="scoria-pagehead">
        <h1>Connectors</h1>
        <p class="text-stone-600 mt-1">
          External runtime presence and connector health for this tenant. Open a row for its detail drawer.
        </p>
      </div>

      <div class="grid gap-6 lg:grid-cols-2">
        <section class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
          <p class="text-xs uppercase tracking-[0.24em] text-stone-500">external runtimes</p>
          <h2 class="text-lg font-semibold text-stone-900">Runtime posture</h2>

          <.empty_state :if={@runtimes == []} title="No runtimes connected" class="mt-4">
            MCP runtimes register here once a host session connects for this tenant.
          </.empty_state>

          <div :if={@runtimes != []} class="mt-4 space-y-3">
            <article :for={runtime <- @runtimes} class="rounded-xl border border-stone-200 bg-stone-50 p-3 flex justify-between items-start">
              <div>
                <p class="text-sm font-semibold text-stone-900 truncate max-w-[12rem]"><%= runtime.id %></p>
                <p class="text-xs text-stone-500 mt-1">
                  <span class={"inline-block w-2 h-2 rounded-full mr-1 #{if runtime.status == "online", do: "bg-emerald-500", else: "bg-stone-300"}"}></span>
                  <%= runtime.status %>
                </p>
              </div>
              <button phx-click="open_runtime_drawer" phx-value-id={runtime.id} class="text-xs font-medium text-blue-700 underline">
                Details
              </button>
            </article>
          </div>
        </section>

        <section class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
          <p class="text-xs uppercase tracking-[0.24em] text-stone-500">connector fleet</p>
          <h2 class="text-lg font-semibold text-stone-900">Connector posture</h2>

          <.empty_state :if={@connector_fleet == []} title="No connectors registered" class="mt-4">
            Register a connector for this tenant to track its auth provenance and refresh health.
          </.empty_state>

          <div :if={@connector_fleet != []} class="mt-4 space-y-3">
            <article :for={connector <- @connector_fleet} class="rounded-xl border border-stone-200 bg-stone-50 p-3">
              <div class="flex items-start justify-between gap-3">
                <div>
                  <p class="text-sm font-semibold text-stone-900"><%= connector.connector_label %></p>
                  <p class="mt-1 text-xs text-stone-600">
                    <%= connector.health_state %> · refresh <%= connector.last_refresh_status %>
                  </p>
                </div>
                <button phx-click="open_connector_drawer" phx-value-id={connector.connector_id} class="text-xs font-medium text-blue-700 underline">
                  Open drawer
                </button>
              </div>

              <div class="mt-3 flex flex-wrap gap-3 text-xs text-stone-600">
                <span>approvals <%= connector.pending_approval_count %></span>
                <span>pending tools <%= connector.pending_local_tool_count %></span>
                <span>auth <%= connector.auth_provenance.status %></span>
              </div>
            </article>
          </div>
        </section>
      </div>

      <RuntimeDetailDrawerComponent.render drawer={@runtime_drawer} />
      <ConnectorDetailDrawerComponent.render drawer={@connector_drawer} />
    </div>
    """
  end

  defp load_fleet(socket) do
    tenant_id = socket.assigns.tenant_id

    socket
    |> assign(:runtimes, OperatorSurface.load_runtimes(tenant_id))
    |> assign(:connector_fleet, OperatorSurface.connector_fleet(tenant_id))
  end
end
