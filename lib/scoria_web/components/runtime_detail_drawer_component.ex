defmodule ScoriaWeb.RuntimeDetailDrawerComponent do
  use Phoenix.Component

  attr(:drawer, :map, default: nil)

  def render(assigns) do
    ~H"""
    <%= if @drawer do %>
      <section id="runtime-detail-drawer" class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm mt-6">
        <div class="flex items-start justify-between gap-4">
          <div>
            <p class="text-xs uppercase tracking-[0.24em] text-stone-500">runtime detail</p>
            <h2 class="text-lg font-semibold text-stone-900"><%= @drawer.id %></h2>
            <div class="mt-2 flex gap-2">
              <span class={"rounded-full px-2 py-0.5 text-xs font-semibold #{status_color(@drawer.status)}"}>
                <%= @drawer.status %>
              </span>
            </div>
          </div>
          <button phx-click="close_runtime_drawer" class="text-xs font-medium text-stone-600 underline">Close</button>
        </div>

        <div class="mt-4 grid gap-3 md:grid-cols-2">
          <div class="rounded-xl bg-stone-50 p-3">
            <p class="text-xs uppercase tracking-[0.18em] text-stone-500">Host session</p>
            <p class="mt-2 text-sm font-medium text-stone-900"><%= @drawer.host_session_id %></p>
          </div>

          <div class="rounded-xl bg-stone-50 p-3">
            <p class="text-xs uppercase tracking-[0.18em] text-stone-500">Transport</p>
            <p class="mt-2 text-sm font-medium text-stone-900"><%= @drawer.transport_kind %></p>
          </div>
        </div>

        <%= if @drawer.status == "offline" && @drawer.terminal_offline_reason do %>
          <div class="mt-4 rounded-xl border border-rose-200 bg-rose-50 p-3">
            <p class="text-xs uppercase tracking-[0.18em] text-rose-500">Terminal offline reason</p>
            <p class="mt-2 text-sm text-rose-900"><%= @drawer.terminal_offline_reason %></p>
          </div>
        <% end %>

        <%= if @drawer.current_run_id do %>
          <div class="mt-4">
            <p class="text-xs uppercase tracking-[0.18em] text-stone-500">Active workflow</p>
            <div class="mt-2">
              <.link navigate={"/workflows/#{@drawer.current_run_id}"} class="text-sm font-medium text-blue-700 underline">
                View run <%= @drawer.current_run_id %>
              </.link>
            </div>
          </div>
        <% end %>
      </section>
    <% end %>
    """
  end

  defp status_color("online"), do: "bg-emerald-100 text-emerald-800"
  defp status_color("offline"), do: "bg-rose-100 text-rose-800"
  defp status_color(_), do: "bg-stone-100 text-stone-800"
end