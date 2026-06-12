defmodule ScoriaWeb.RouterTest do
  use ExUnit.Case, async: true

  # We define a dummy router to test the macro
  defmodule DummyRouter do
    use Phoenix.Router
    import ScoriaWeb.Router

    pipeline :browser do
      plug :accepts, ["html"]
    end

    scope "/" do
      pipe_through :browser
      scoria_dashboard("/scoria")
    end
  end

  test "scoria_dashboard macro mounts orchestrator live view" do
    assert Phoenix.Router.route_info(DummyRouter, "GET", "/scoria", nil).plug == Phoenix.LiveView.Plug
  end

  test "scoria_dashboard macro mounts workflow run live view" do
    assert Phoenix.Router.route_info(DummyRouter, "GET", "/scoria/workflows/123", nil).plug == Phoenix.LiveView.Plug
  end

  test "scoria_dashboard macro mounts coming-soon live view" do
    assert %{plug: Phoenix.LiveView.Plug} =
             Phoenix.Router.route_info(DummyRouter, "GET", "/scoria/coming/cost-ledger", nil)
  end
end
