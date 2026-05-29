import Config

config :support_copilot, SupportCopilotWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4010],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "support_copilot_dev_secret_key_base_not_for_production_use_only_demo"

config :support_copilot, dev_routes: true

config :logger, level: :info
