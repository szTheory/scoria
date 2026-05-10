defmodule ScoriaWeb.TraceTreeComponent do
  use Phoenix.LiveComponent

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <div id={@id} class="trace-tree">
      <%= for span <- @spans do %>
        <div 
          class="trace-row pl-[calc(var(--indent-level)*1.5rem)] flex items-center py-1 border-b"
          style={"--indent-level: #{Map.get(span, :depth, 0)}"}
        >
          <div class="trace-span-name font-mono text-sm">
            <%= span.name %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
