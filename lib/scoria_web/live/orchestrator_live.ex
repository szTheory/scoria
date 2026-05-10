defmodule ScoriaWeb.OrchestratorLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Scoria.PubSub, "scoria:runs:all")
    end

    socket =
      socket
      |> assign(:page_title, "Scoria Dashboard")
      |> stream(:traces, [])

    {:ok, socket}
  end

  def handle_info({:new_trace, trace}, socket) do
    {:noreply, stream_insert(socket, :traces, trace)}
  end

  def render(assigns) do
    ~H"""
    <div class="scoria-dashboard bg-gray-50 min-h-screen p-8 text-gray-900 font-sans">
      <div class="max-w-7xl mx-auto">
        <h1 class="text-3xl font-bold mb-6">Scoria Orchestrator</h1>
        <p class="text-gray-600 mb-8">A Phoenix-native AI Application Quality Layer.</p>

        <div id="traces-list" phx-update="stream" class="space-y-4">
          <div :for={{id, trace} <- @streams.traces} id={id} class="bg-white p-4 rounded shadow">
            <.live_component module={ScoriaWeb.TraceTreeComponent} id={"tree-#{id}"} spans={trace.spans} />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
