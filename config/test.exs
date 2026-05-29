import Config

config :scoria, Scoria.Repo,
  username: System.get_env("SCORIA_DB_USERNAME", "postgres"),
  password: System.get_env("SCORIA_DB_PASSWORD", "postgres"),
  hostname: System.get_env("SCORIA_DB_HOST", "localhost"),
  port: String.to_integer(System.get_env("SCORIA_DB_PORT", "5432")),
  database:
    System.get_env("SCORIA_DB_NAME") ||
      "scoria_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 20,
  show_sensitive_data_on_connection_error: true

config :scoria, Oban, testing: :manual

config :scoria, :workflow_dispatch, :inline
