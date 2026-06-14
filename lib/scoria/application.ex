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
      ] ++ maybe_reconciler() ++ dev_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Scoria.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp maybe_reconciler do
    if Mix.env() == :test, do: [], else: [Scoria.Workflows.Reconciler]
  end

  # Runtime-safe dev harness hook. In `:dev`, config/dev.exs sets
  # `:dev_children` to `[ScoriaWeb.DevEndpoint]` so `mix phx.server` can serve
  # the dashboard locally. Reads config (not `Mix.env/0`) so this is safe in
  # adopter releases where Mix is unavailable and the dev modules don't exist —
  # there the key is unset and this is an empty list.
  defp dev_children do
    Application.get_env(:scoria, :dev_children, [])
  end
end
