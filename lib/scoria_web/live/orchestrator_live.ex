defmodule ScoriaWeb.OrchestratorLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Scoria.PubSub, "scoria:runs:all")
    end

    socket =
      socket
      |> assign(:page_title, "Scoria Dashboard")
      |> assign(:token_buffer, [])
      |> assign(:timer_ref, nil)
      |> assign(:token_text, "")
      |> stream(:traces, [])

    {:ok, socket}
  end

  def handle_info({:new_trace, trace}, socket) do
    {:noreply, stream_insert(socket, :traces, trace)}
  end

  def handle_info({:token, token}, socket) do
    new_buffer = [token | socket.assigns.token_buffer]
    
    socket = 
      if is_nil(socket.assigns.timer_ref) do
        ref = Process.send_after(self(), :flush_tokens, 75)
        assign(socket, timer_ref: ref)
      else
        socket
      end

    {:noreply, assign(socket, token_buffer: new_buffer)}
  end

  def handle_info(:flush_tokens, socket) do
    new_chunk = socket.assigns.token_buffer |> Enum.reverse() |> Enum.join("")
    
    socket = 
      socket 
      |> assign(token_text: socket.assigns.token_text <> new_chunk)
      |> assign(token_buffer: [])
      |> assign(timer_ref: nil)
      
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="scoria-dashboard bg-gray-50 min-h-screen p-8 text-gray-900 font-sans">
      <div class="max-w-7xl mx-auto">
        <h1 class="text-3xl font-bold mb-6">Scoria Orchestrator</h1>
        <p class="text-gray-600 mb-8">A Phoenix-native AI Application Quality Layer.</p>

        <div id="token-stream" class="mb-4 whitespace-pre-wrap"><%= @token_text %></div>

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
