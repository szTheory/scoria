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
      ] ++ maybe_observe_buffer() ++ maybe_reconciler() ++ dev_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Scoria.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp maybe_reconciler do
    if Mix.env() == :test, do: [], else: [Scoria.Workflows.Reconciler]
  end

  # Turns the span pipeline on by default (D-00a, Phase 53 SC#2). Reads
  # config, NOT Mix.env() -- unlike maybe_reconciler/0, this must boot in
  # :prod too, or every span emitted by a real host app fires into a void.
  # An absent :enabled key means ON; only `enabled: false` opts out.
  defp maybe_observe_buffer do
    observe_children()
  end

  @doc false
  def observe_children do
    if Application.get_env(:scoria, Scoria.Observe, [])[:enabled] != false do
      safe_attach_observe_telemetry()
      [Scoria.Observe.Buffer]
    else
      []
    end
  end

  # :telemetry.attach_many/4 returns {:error, :already_exists} when the
  # handler id is already registered (e.g. an adopter or a test attached it
  # first). Match-and-ignore both outcomes -- never let this raise or halt
  # start/2, since a boot crash takes the entire host app down (T-53-08).
  defp safe_attach_observe_telemetry do
    case Scoria.Observe.Telemetry.attach() do
      :ok -> :ok
      {:error, :already_exists} -> :ok
    end
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
