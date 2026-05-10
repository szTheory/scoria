import Config

config :scoria, Scoria.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "scoria_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  show_sensitive_data_on_connection_error: true
