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
        {Task.Supervisor, name: Scoria.Trust.TaskSupervisor},
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
      safe_attach_observe_mcp()
      safe_attach_observe_req_llm()
      safe_attach_observe_jido()
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

  # Phase 53 Plan 05: gives the MCP tool leg (SC#1) a live production
  # producer. Uses a distinct handler id ("scoria-observe-mcp") from
  # "scoria-observe-telemetry" so the two attach/detach lifecycles never
  # collide, and the same match-and-ignore discipline as
  # safe_attach_observe_telemetry/0 above (T-53-08).
  defp safe_attach_observe_mcp do
    case Scoria.Observe.Adapters.MCP.attach() do
      :ok -> :ok
      {:error, :already_exists} -> :ok
    end
  end

  # Phase 54.1 (D-01): gives the ReqLLM LLM-span leg a live production
  # producer via observe_children/0's boot seam. Uses a distinct handler id
  # ("scoria-observe-reqllm") from the other observe handlers, and the same
  # match-and-ignore discipline as safe_attach_observe_mcp/0 above
  # (T-53-08) -- a duplicate attach (adopter/test attached first) is not an
  # error, it never raises or halts start/2.
  defp safe_attach_observe_req_llm do
    case Scoria.Observe.Adapters.ReqLLM.attach() do
      :ok -> :ok
      {:error, :already_exists} -> :ok
    end
  end

  # Phase 54.1 (D-01, D-02): gives the Jido TOOL-span leg a live production
  # producer via observe_children/0's boot seam. Uses a distinct handler id
  # ("scoria-observe-jido") from the other observe handlers, and the same
  # match-and-ignore discipline as safe_attach_observe_mcp/0 above
  # (T-53-08). Attaches UNCONDITIONALLY -- no module-presence guard --
  # because Scoria.Observe.Adapters.Jido references zero Jido.* modules; a
  # presence guard would guard nothing and mislead. `jido` is deliberately
  # NOT added to mix.exs deps (telemetry-coupled, not a dependency).
  defp safe_attach_observe_jido do
    case Scoria.Observe.Adapters.Jido.attach() do
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
