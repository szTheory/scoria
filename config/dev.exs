import Config

config :scoria, Scoria.Repo,
  username: System.get_env("SCORIA_DB_USERNAME", "postgres"),
  password: System.get_env("SCORIA_DB_PASSWORD", "postgres"),
  hostname: System.get_env("SCORIA_DB_HOST", "localhost"),
  port: String.to_integer(System.get_env("SCORIA_DB_PORT", "5432")),
  database: System.get_env("SCORIA_DB_NAME", "scoria_dev"),
  show_sensitive_data_on_connection_error: true
