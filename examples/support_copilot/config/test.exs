import Config

config :support_copilot, SupportCopilotWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4011],
  secret_key_base: "support_copilot_test_secret_key_base_for_gallery_tests_only_must_be_64_bytes_long_!!",
  server: false

config :logger, level: :warning

config :scoria, Scoria.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 2,
  database: "support_copilot_test#{System.get_env("MIX_TEST_PARTITION")}"

config :scoria, Oban, testing: :manual
