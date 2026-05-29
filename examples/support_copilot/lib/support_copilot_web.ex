defmodule SupportCopilotWeb do
  @moduledoc false

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html]
      import Plug.Conn
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {SupportCopilotWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent
      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component
      import SupportCopilotWeb.CoreComponents
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      import Phoenix.HTML
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
