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

  import ScoriaWeb.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
  end

  scope "/" do
    pipe_through(:browser)

    scoria_dashboard("/scoria")
  end
end
