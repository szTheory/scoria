import Config

config :scoria,
  ecto_repos: [Scoria.Repo]

config :scoria, Scoria.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  types: Scoria.PostgrexTypes

config :scoria, Oban,
  engine: Oban.Engines.Basic,
  queues: [connector_sync: 10],
  repo: Scoria.Repo

config :scoria, Scoria.Vault,
  json_library: Jason,
  ciphers: [
    default: {
      Cloak.Ciphers.AES.GCM,
      tag: "AES.GCM.V1", key: Base.decode64!("PwIcoX8/Jhn4gsgZeJueZnyaisQDuCtEvLneO+pDkSk=")
    }
  ]

import_config "#{config_env()}.exs"
