defmodule SupportCopilotWeb.CoreComponents do
  @moduledoc false
  use Phoenix.Component

  attr :rest, :global
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button {@rest} style="padding: 0.5rem 1rem; border-radius: 0.375rem; border: 1px solid #ccc; background: #f8fafc; cursor: pointer;">
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
