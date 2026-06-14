import Config

config :scoria, Scoria.Repo,
  username: System.get_env("SCORIA_DB_USERNAME", "postgres"),
  password: System.get_env("SCORIA_DB_PASSWORD", "postgres"),
  hostname: System.get_env("SCORIA_DB_HOST", "localhost"),
  port: String.to_integer(System.get_env("SCORIA_DB_PORT", "5432")),
  database: System.get_env("SCORIA_DB_NAME", "scoria_dev"),
  show_sensitive_data_on_connection_error: true,
  # config/config.exs sets `pool: Ecto.Adapters.SQL.Sandbox` at the base level for
  # the test sandbox; dev is a real running server and must NOT inherit it.
  # On the ownership pool the dev dashboard + background pollers (SRE.Relay,
  # Workflows.Reconciler, audit-outbox) contend for the default 10 connections and
  # the boot burst starves the pool (DBConnection ownership_timeout → page 500s
  # for ~20s after boot). Use the standard pool with headroom.
  pool: DBConnection.ConnectionPool,
  pool_size: String.to_integer(System.get_env("SCORIA_DB_POOL_SIZE", "20")),
  queue_target: 200,
  queue_interval: 2_000

# --- Dev host harness ---------------------------------------------------------
# Serves the Scoria dashboard at http://localhost:4000/scoria via `mix phx.server`
# for the screenshot/critique harness and manual iteration. The endpoint module
# (ScoriaWeb.DevEndpoint) lives under dev/ and is dev-only — never shipped to Hex.
#
# Binds 0.0.0.0 so the dockerized Playwright harness can reach it by compose
# service name (http://web:4000/scoria). secret_key_base is a throwaway dev value
# (≥64 bytes — short keys make LiveView pages 500). check_origin is disabled for
# local dev (the proxy/host vary: localhost, scoria.localhost, web:4000).
config :scoria, ScoriaWeb.DevEndpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: System.get_env("PHX_HOST", "localhost"), path: "/"],
  http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT", "4000"))],
  secret_key_base:
    "mIDxZZ/zxiqpdS9PzkM5XkSuaPo0rqxBTIauSemoUACCZAS9c1D8joGTXknXIMDjoC/2jbEE+Dzu6x5mG+yXGw==",
  live_view: [signing_salt: "scoria_dev_lv_salt_v1"],
  pubsub_server: Scoria.PubSub,
  debug_errors: true,
  check_origin: false,
  code_reloader: true,
  live_reload: [
    patterns: [
      # Recompile-trigger: rebuilt asset bundles (ScoriaWeb.Assets inlines these
      # at compile time, so a CSS/JS change must recompile that module).
      ~r"priv/static/scoria/.*(js|css)$",
      ~r"lib/scoria_web/.*(ex|heex)$"
    ]
  ]

# Started by Scoria.Application via the runtime-safe :dev_children hook.
# DevAssetWatcher rebuilds priv/static/scoria/app.{css,js} when assets/ changes,
# so style edits hot-reload without a manual `mix scoria.assets.build`.
config :scoria, dev_children: [ScoriaWeb.DevEndpoint, ScoriaWeb.DevAssetWatcher]

# macOS Docker Desktop does not propagate host fs events into the Linux VM, so
# the native file watcher never fires. Polling works everywhere. Gated on an env
# var so native (host) dev keeps the faster fsevents/inotify backend.
if System.get_env("FILE_SYSTEM_BACKEND") == "fs_poll" do
  config :phoenix_live_reload, backend: :fs_poll, backend_opts: [interval: 500]
end
