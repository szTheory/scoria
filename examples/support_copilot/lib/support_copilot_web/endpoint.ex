defmodule SupportCopilotWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :support_copilot

  socket("/live", Phoenix.LiveView.Socket, websocket: true, longpoll: false)

  @session_options [
    store: :cookie,
    key: "_support_copilot_key",
    signing_salt: "support_copilot_signing",
    same_site: "Lax"
  ]

  plug(Plug.Static,
    at: "/",
    from: :support_copilot,
    gzip: false,
    only: SupportCopilotWeb.static_paths()
  )

  if code_reloading? do
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])
  plug(Plug.Parsers, parsers: [:urlencoded, :multipart, :json], json_decoder: Phoenix.json_library())
  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(SupportCopilotWeb.Router)
end
