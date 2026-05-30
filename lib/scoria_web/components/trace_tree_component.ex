defmodule ScoriaWeb.TraceTreeComponent do
  use Phoenix.LiveComponent

  attr :spans, :list, required: true
  attr :token_previews, :map, default: %{}

  def mount(socket) do
    {:ok, assign(socket, active_span_id: nil)}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("load_metadata", %{"span_id" => span_id}, socket) do
    socket =
      socket
      |> assign(:active_span_id, span_id)
      |> assign_async(:active_metadata, fn ->
        Process.sleep(100)
        {:ok, %{active_metadata: "Deep trace metadata loaded lazily for span #{span_id}."}}
      end)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div id={@id} class="trace-tree">
      <%= for span <- @spans do %>
        <div 
          class="trace-row pl-[calc(var(--indent-level)*1.5rem)] flex flex-col py-1 border-b"
          style={"--indent-level: #{Map.get(span, :depth, 0)}"}
        >
          <div 
            class="trace-span-name font-mono text-sm cursor-pointer hover:bg-gray-100 p-1"
            phx-click="load_metadata" 
            phx-value-span_id={Map.get(span, :id) || Map.get(span, "id") || Map.get(span, :name) || Map.get(span, "name")}
            phx-target={@myself}
          >
            <%= Map.get(span, :name) || Map.get(span, "name") %>
          </div>
          <%= if llm_token_preview?(assigns, span) do %>
            <div class="token-preview pl-4 text-xs text-emerald-700 font-mono whitespace-pre-wrap break-all bg-emerald-50 border border-emerald-100 p-2 mt-1">
              <%= Map.get(@token_previews, Map.get(span, :id) || Map.get(span, "id")) %>
            </div>
          <% end %>
          <%= if @active_span_id == to_string(Map.get(span, :id) || Map.get(span, "id") || Map.get(span, :name)) do %>
            <div class="pl-4 text-xs text-gray-500 mt-1 bg-gray-50 p-2 border border-gray-200">
              <%= if Map.get(assigns, :active_metadata) do %>
                <%= if @active_metadata.ok? do %>
                  <%= @active_metadata.result %>
                <% else %>
                  <%= if @active_metadata.loading do %>
                    Loading deep metadata...
                  <% else %>
                    Failed to load metadata.
                  <% end %>
                <% end %>
              <% end %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp llm_token_preview?(assigns, span) do
    span_id = Map.get(span, :id) || Map.get(span, "id")

    Map.get(span, :span_kind) == "LLM" and
      is_nil(Map.get(span, :end_time)) and
      Map.get(assigns, :token_previews, %{})
      |> Map.get(span_id, "") != ""
  end
end
