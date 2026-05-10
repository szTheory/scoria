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
      |> assign(:active_approval, nil)
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

  def handle_info({:hitl_request, approval}, socket) do
    {:noreply, assign(socket, :active_approval, approval)}
  end

  def handle_event("approve", _, socket) do
    if approval = socket.assigns.active_approval do
      Scoria.Repo.update(Scoria.Observe.Approval.changeset(approval, %{status: "approved"}))
    end
    {:noreply, assign(socket, :active_approval, nil)}
  end

  def handle_event("reject", _, socket) do
    if approval = socket.assigns.active_approval do
      Scoria.Repo.update(Scoria.Observe.Approval.changeset(approval, %{status: "rejected"}))
    end
    {:noreply, assign(socket, :active_approval, nil)}
  end

  def render(assigns) do
    ~H"""
    <div class="scoria-dashboard bg-gray-50 min-h-screen p-8 text-gray-900 font-sans relative">
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

      <%= if @active_approval do %>
        <div id="approval-modal" class="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50">
          <div class="bg-white p-6 rounded shadow-lg max-w-md w-full">
            <h2 class="text-xl font-bold mb-4">Approval Required</h2>
            <p class="mb-2"><strong>Tool:</strong> <%= @active_approval.tool_name %></p>
            <div class="flex justify-end space-x-4 mt-6">
              <button phx-click="reject" class="px-4 py-2 bg-red-500 text-white rounded">Reject</button>
              <button phx-click="approve" class="px-4 py-2 bg-blue-500 text-white rounded">Approve</button>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
