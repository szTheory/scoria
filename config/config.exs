import Config

config :scoria,
  ecto_repos: [Scoria.Repo],
  live_token_coalesce_ms: 75,
  orchestrator_hydrate_trace_limit: 25

config :scoria, Scoria.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  types: Scoria.PostgrexTypes

config :scoria, Oban,
  engine: Oban.Engines.Basic,
  queues: [connector_sync: 10, compaction: 10, system: 10, inference: 20, evals: 50],
  repo: Scoria.Repo

config :scoria, Scoria.Vault,
  json_library: Jason,
  ciphers: [
    default: {
      Cloak.Ciphers.AES.GCM,
      tag: "AES.GCM.V1", key: Base.decode64!("PwIcoX8/Jhn4gsgZeJueZnyaisQDuCtEvLneO+pDkSk=")
    }
  ]

config :scoria,
  fallback_chains: %{
    "openai:gpt-4o" => ["openai:gpt-4-turbo", "openai:gpt-3.5-turbo"],
    "anthropic:claude-3-opus" => ["anthropic:claude-3-sonnet"]
  }

import_config "#{config_env()}.exs"
