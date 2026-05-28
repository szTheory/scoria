defmodule HostRouteSmokeTest do
  use ExUnit.Case, async: false

  test "installed scoria routes resolve through Phoenix router metadata" do
    assert Phoenix.Router.route_info(ScoriaHostProofWeb.Router, "GET", "/scoria", nil).plug ==
             Phoenix.LiveView.Plug

    assert Phoenix.Router.route_info(
             ScoriaHostProofWeb.Router,
             "GET",
             "/scoria/workflows/123",
             nil
           ).plug == Phoenix.LiveView.Plug
  end
end
