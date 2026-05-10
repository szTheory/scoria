import Config

config :scoria,
  ecto_repos: [Scoria.Repo]

config :scoria, Scoria.Repo, pool: Ecto.Adapters.SQL.Sandbox

import_config "#{config_env()}.exs"
