defmodule ScoriaWeb.ConnectorDetailDrawerComponent do
  use Phoenix.Component

  attr :drawer, :map, default: nil

  def render(assigns) do
    ~H"""
    <aside :if={@drawer} class="mt-6 rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
      <p class="text-xs uppercase tracking-[0.24em] text-stone-500">Connector detail</p>
      <h2 class="mt-1 text-lg font-semibold text-stone-900"><%= @drawer.connector_label %></h2>
      <dl class="mt-4 grid gap-3 text-sm text-stone-700 md:grid-cols-2">
        <div>
          <dt class="text-xs uppercase tracking-[0.18em] text-stone-500">Status</dt>
          <dd class="mt-1"><%= @drawer.status %> · <%= @drawer.health_state %></dd>
        </div>
        <div>
          <dt class="text-xs uppercase tracking-[0.18em] text-stone-500">Refresh</dt>
          <dd class="mt-1"><%= @drawer.last_refresh_status %></dd>
        </div>
        <div>
          <dt class="text-xs uppercase tracking-[0.18em] text-stone-500">Transport</dt>
          <dd class="mt-1"><%= @drawer.transport_kind %></dd>
        </div>
        <div>
          <dt class="text-xs uppercase tracking-[0.18em] text-stone-500">Auth mode</dt>
          <dd class="mt-1"><%= @drawer.auth_mode %></dd>
        </div>
      </dl>
      <p class="mt-4 text-xs text-stone-500"><%= @drawer.endpoint_url %></p>
    </aside>
    """
  end
end
