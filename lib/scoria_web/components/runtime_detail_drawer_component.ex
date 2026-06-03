defmodule ScoriaWeb.RuntimeDetailDrawerComponent do
  use Phoenix.Component
  import ScoriaWeb.UI, only: [badge: 1, tone: 1]

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
              <.badge tone={tone(@drawer.status)} label={@drawer.status} dot={false} />
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

        <%= if semantic_present?(@drawer.semantic) do %>
          <section class="mt-4 rounded-xl border border-stone-200 bg-stone-50 p-4">
            <div class="flex items-start justify-between gap-3">
              <div>
                <p class="text-xs uppercase tracking-[0.18em] text-stone-500">semantic fast path</p>
                <h3 class="mt-1 text-sm font-semibold text-stone-900">Semantic summary</h3>
              </div>
              <span class="rounded-full bg-blue-100 px-2 py-0.5 text-xs font-semibold text-blue-800">
                <%= @drawer.semantic.lookup_status %>
              </span>
            </div>

            <dl class="mt-3 grid gap-3 md:grid-cols-2">
              <div class="rounded-lg bg-white p-3">
                <dt class="text-xs uppercase tracking-[0.18em] text-stone-500">lookup_status</dt>
                <dd class="mt-2 text-sm font-medium text-stone-900"><%= @drawer.semantic.lookup_status %></dd>
              </div>
              <div class="rounded-lg bg-white p-3">
                <dt class="text-xs uppercase tracking-[0.18em] text-stone-500">scope_kind</dt>
                <dd class="mt-2 text-sm font-medium text-stone-900"><%= @drawer.semantic.scope_kind %></dd>
              </div>
              <div class="rounded-lg bg-white p-3">
                <dt class="text-xs uppercase tracking-[0.18em] text-stone-500">lane_key</dt>
                <dd class="mt-2 text-sm font-medium text-stone-900"><%= @drawer.semantic.lane_key %></dd>
              </div>
              <div class="rounded-lg bg-white p-3">
                <dt class="text-xs uppercase tracking-[0.18em] text-stone-500">scope_reason</dt>
                <dd class="mt-2 text-sm font-medium text-stone-900"><%= @drawer.semantic.scope_reason %></dd>
              </div>
            </dl>

            <%= if @drawer.semantic.reason_code do %>
              <div class="mt-3">
                <span class="rounded-full border border-amber-200 bg-amber-50 px-2.5 py-1 text-xs font-semibold text-amber-800">
                  <%= @drawer.semantic.reason_code %>
                </span>
              </div>
            <% end %>

            <p class="mt-3 text-sm text-stone-700"><%= fallback_copy(@drawer.semantic) %></p>

            <%= if @drawer.semantic.scope_kind == "actor_scoped" and present?(@drawer.semantic.actor_id) do %>
              <p class="mt-2 text-sm text-stone-700">
                Actor scope: <span class="font-medium text-stone-900"><%= @drawer.semantic.actor_id %></span>
              </p>
            <% end %>

            <div class="mt-3 flex flex-wrap gap-3 text-sm">
              <.link navigate={@drawer.semantic.workflow_href} class="font-medium text-blue-700 underline">
                View workflow evidence
              </.link>

              <.link
                :if={present?(@drawer.semantic.origin_run_href)}
                navigate={@drawer.semantic.origin_run_href}
                class="font-medium text-blue-700 underline"
              >
                View origin run
              </.link>
            </div>
          </section>
        <% end %>
      </section>
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
