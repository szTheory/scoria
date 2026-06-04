defmodule ScoriaWeb.DevRouter do
  @moduledoc """
  Dev-only router that mounts the Scoria dashboard for local development.

  This file lives under `dev/` and is compiled ONLY in `:dev` (see
  `elixirc_paths/1` in mix.exs). It is never included in the Hex package
  (`package.files` lists `lib` explicitly, not `dev`), so adopters never
  receive it — it exists purely so `mix phx.server` can serve the dashboard
  for the screenshot/critique harness and manual iteration.

  It mirrors the per-test inline routers used in `test/scoria_web/live/*`:
  a minimal `:browser` pipeline plus the public `scoria_dashboard/2` macro.
  """
  use Phoenix.Router

  import Phoenix.Controller
  import ScoriaWeb.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    # Required for the real LiveView WebSocket join: protect_from_forgery stores
    # the CSRF token in the session so the socket can verify _csrf_token on
    # connect. Without it, every join is rejected as "session misconfigured /
    # stale", causing an infinite redirect loop (the dashboard never settles, so
    # the data-scoria-ready sentinel never fires). The per-test inline routers
    # omit this because LiveViewTest bypasses the real socket CSRF check.
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/" do
    pipe_through(:browser)

    scoria_dashboard("/scoria")
  end
end
