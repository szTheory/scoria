defmodule ScoriaWeb.TraceTreeComponent do
  use Phoenix.LiveComponent

  attr(:spans, :list, required: true)
  attr(:token_previews, :map, default: %{})

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
          class={[
            "trace-row scoria-span flex flex-col",
            "scoria-span--#{span_kind(span)}"
          ]}
          style={"--indent-level: #{Map.get(span, :depth, 0)}"}
        >
          <span class="scoria-span__rail"></span>
          <div
            class="trace-span-name font-mono text-sm cursor-pointer"
            phx-click="load_metadata"
            phx-value-span_id={span_id(span)}
            phx-target={@myself}
          >
            <%= Map.get(span, :name) || Map.get(span, "name") %>
          </div>
          <%= if llm_token_preview?(assigns, span) do %>
            <div class="token-preview scoria-raw-evidence__pre font-mono whitespace-pre-wrap break-all">
              <%= Map.get(@token_previews, span_id(span)) %>
            </div>
          <% end %>
          <%= if @active_span_id == to_string(span_id(span)) do %>
            <div class="scoria-raw-evidence__pre font-mono">
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
    span_id = span_id(span)

    span_kind(span) == "llm" and
      is_nil(Map.get(span, :end_time)) and
      Map.get(assigns, :token_previews, %{})
      |> Map.get(span_id, "") != ""
  end

  defp span_id(span) do
    Map.get(span, :id) || Map.get(span, "id") || Map.get(span, :name) || Map.get(span, "name")
  end

  defp span_kind(span) do
    span
    |> Map.get(:span_kind, Map.get(span, "span_kind", "agent"))
    |> to_string()
    |> String.downcase()
    |> case do
      kind when kind in ~w(agent llm prompt tool mcp retriever guardrail eval error) -> kind
      _ -> "agent"
    end
  end
end
