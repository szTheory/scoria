defmodule Scoria.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        Scoria.Repo,
        Scoria.Vault,
        {Oban, Application.fetch_env!(:scoria, Oban)},
        {Phoenix.PubSub, name: Scoria.PubSub},
        ScoriaWeb.Presence,
        {Registry, keys: :unique, name: Scoria.MCP.SessionRegistry},
        {Task.Supervisor, name: Scoria.MCP.TaskSupervisor},
        {Task.Supervisor, name: Scoria.Workflow.TaskSupervisor},
        Scoria.SRE.Relay
      ] ++ maybe_reconciler()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Scoria.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp maybe_reconciler do
    if Mix.env() == :test, do: [], else: [Scoria.Workflows.Reconciler]
  end
end
