import Config

config :scoria, Scoria.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "scoria_dev",
  show_sensitive_data_on_connection_error: true
