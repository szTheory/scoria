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
  # `live`/`live_session` are otherwise only available inside the
  # `scoria_dashboard/2` macro's own quote block (that macro imports
  # Phoenix.LiveView.Router locally). This module-scope import is required
  # so the NEW `/scoria/_lab` scope below can call `live/3`/`live_session/3`
  # directly — without it, `mix compile` fails with `live/3 is undefined`.
  import Phoenix.LiveView.Router, only: [live: 3, live_session: 3]
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
    plug(:put_demo_tenant)
  end

  scope "/" do
    pipe_through(:browser)

    scoria_dashboard("/scoria")
  end

  # Dev-only Component Lab (Phase 37, D-01/D-02/D-03): a maintainer-only
  # inspection surface mounted ONLY here, entirely outside the public
  # scoria_dashboard/2 macro above. It must never be reachable via
  # lib/scoria_web/router.ex (proved by
  # test/scoria_web/dev_lab_boundary_test.exs) and never gains a public
  # macro option (no `scoria_dashboard lab: true`).
  scope "/scoria/_lab" do
    pipe_through(:browser)

    live_session :scoria_lab, root_layout: {ScoriaWeb.Layouts, :root} do
      live("/", DevLab.LabLive, :index)
      live("/:section", DevLab.LabLive, :index)
      live("/:section/:item", DevLab.LabLive, :index)
    end
  end

  # Dev-only: default the session tenant to the demo tenant that
  # `priv/repo/dev_seed.exs` populates (Scoria.SupportJourney.tenant_id/0,
  # "acme-corp"). Every dashboard LiveView resolves
  # `params["tenant"] || session["tenant_id"] || "default"`, so without this the
  # bare /scoria URL lands on the empty "default" tenant and the click-around
  # demo looks empty even though seed data exists. Only sets the default when
  # absent, so an explicit `?tenant=` still wins (LiveViews check params first).
  # This lives in the dev-only router (never shipped to Hex), so host apps and
  # production tenant resolution are untouched.
  defp put_demo_tenant(conn, _opts) do
    if Plug.Conn.get_session(conn, "tenant_id") do
      conn
    else
      Plug.Conn.put_session(conn, "tenant_id", Scoria.SupportJourney.tenant_id())
    end
  end
end
