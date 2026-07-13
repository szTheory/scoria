import Config

config :scoria,
  ecto_repos: [Scoria.Repo],
  live_token_coalesce_ms: 75,
  orchestrator_hydrate_trace_limit: 25,
  # Defaults open for adopters without evals; set true to require a completed passing eval verdict.
  require_eval_verdict: false

config :scoria, Scoria.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  types: Scoria.PostgrexTypes

# SEC-01 write-time bound (plan 53-04). No disable switch -- limits tune
# upward only; raising a byte cap never relaxes key admission.
config :scoria, Scoria.Observe.Bounds,
  max_attribute_bytes: 256,
  max_attribute_count: 128,
  max_depth: 5,
  max_list_length: 100,
  max_total_bytes: 16_384,
  max_delta_chunk_bytes: 2_048,
  allowed_key_prefixes: [],
  capture_error_messages: false

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
