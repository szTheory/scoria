defmodule SupportCopilot.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children =
      case Mix.env() do
        :test ->
          [
            {Phoenix.PubSub, name: SupportCopilot.PubSub},
            SupportCopilotWeb.Endpoint
          ]

        _ ->
          [
            {Phoenix.PubSub, name: SupportCopilot.PubSub},
            SupportCopilotWeb.Endpoint,
            Scoria.Workflows.Reconciler
          ]
      end

    opts = [strategy: :one_for_one, name: SupportCopilot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    SupportCopilotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
