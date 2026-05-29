import Config

config :support_copilot,
  generators: [timestamp_type: :utc_datetime]

config :support_copilot, SupportCopilotWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: SupportCopilotWeb.ErrorHTML],
    layout: false
  ],
  pubsub_server: SupportCopilot.PubSub,
  live_view: [signing_salt: "support_copilot_live"]

config :logger, :console, format: "$time $metadata[$level] $message\n"

import_config "runtime.exs"
import_config "#{config_env()}.exs"
