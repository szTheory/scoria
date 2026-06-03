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
          # Scoria.Workflows.Reconciler is owned by Scoria.Application's own supervision tree
          # (the :scoria OTP app starts it in non-test); the host must not start a second one.
          [
            {Phoenix.PubSub, name: SupportCopilot.PubSub},
            SupportCopilotWeb.Endpoint
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
