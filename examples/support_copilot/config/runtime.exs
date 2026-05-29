import Config

if config_env() == :prod do
  raise "support_copilot gallery is a local demo only"
end

# scoria:runtime:start
config :scoria,
  ecto_repos: [Scoria.Repo]

config :scoria, Scoria.Repo,
  username: System.get_env("SCORIA_DB_USERNAME", "postgres"),
  password: System.get_env("SCORIA_DB_PASSWORD", "postgres"),
  hostname: System.get_env("SCORIA_DB_HOST", "localhost"),
  port: String.to_integer(System.get_env("SCORIA_DB_PORT", "5432")),
  database: "support_copilot_#{config_env()}",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  types: Scoria.PostgrexTypes

config :scoria, Scoria.Runtime,
  defaults: [
    provider: "openai",
    model: "gpt-5-mini",
    prompt_policy: [policy_key: "default"]
  ]

config :scoria, Oban,
  engine: Oban.Engines.Basic,
  repo: Scoria.Repo,
  queues: false,
  plugins: false

config :scoria, Scoria.Vault,
  json_library: Jason,
  ciphers: [
    default: {
      Cloak.Ciphers.AES.GCM,
      tag: "AES.GCM.V1",
      key: Base.decode64!("PwIcoX8/Jhn4gsgZeJueZnyaisQDuCtEvLneO+pDkSk=")
    }
  ]
# scoria:runtime:end
