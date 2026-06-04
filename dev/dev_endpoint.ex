defmodule ScoriaWeb.DevEndpoint do
  @moduledoc """
  Dev-only Phoenix endpoint for local development of the Scoria dashboard.

  Compiled ONLY in `:dev` (see `elixirc_paths/1` in mix.exs) and never shipped
  to Hex. Started via the `:dev_children` application hook (see
  `Scoria.Application` and `config/dev.exs`) so that `mix phx.server` serves the
  dashboard at `http://localhost:4000/scoria` for the screenshot/critique
  harness (`mix scoria.ui.shots`) and manual iteration.

  Assets are inlined into the root layout at compile time by `ScoriaWeb.Assets`
  (the LiveDashboard/Oban-Web self-contained model), so no `Plug.Static` is
  required here — the page is fully styled and interactive on its own.

  The endpoint process always starts (it backs LiveView/PubSub), but only binds
  the HTTP listener when running under `mix phx.server`. Plain `mix` tasks that
  call `app.start` (e.g. the `--critique` pass) therefore do NOT try to bind the
  port, avoiding "address already in use" when a server is already running.
  """
  use Phoenix.Endpoint, otp_app: :scoria

  @session_options [
    store: :cookie,
    key: "_scoria_dev_key",
    signing_salt: "scoria_dev_salt",
    same_site: "Lax"
  ]

  # LiveView socket — the dashboard JS (assets/js/scoria.js) connects here and
  # sets data-scoria-ready="true" once connected, which the harness waits on.
  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]]
  )

  # Live reload for fast local iteration. Only active when phoenix_live_reload
  # is loaded (dev-only dep) and configured with patterns in config/dev.exs.
  if Code.ensure_loaded?(Phoenix.LiveReloader) do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.Session, @session_options)
  plug(ScoriaWeb.DevRouter)
end
