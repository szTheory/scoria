defmodule SupportCopilotWeb.OrchestratorSmokeTest do
  use SupportCopilotWeb.ConnCase, async: false

  alias Scoria.SupportJourney

  test "GET /scoria orchestrator dashboard mounts with session contract", %{conn: conn} do
    conn =
      conn
      |> Plug.Test.init_test_session(%{
        "tenant_id" => SupportJourney.tenant_id(),
        "actor_id" => SupportJourney.operator_identity().actor_id
      })

    {:ok, _view, html} = live(conn, "/scoria")

    assert html =~ "Scoria Orchestrator"
    assert html =~ "Approval inbox"
  end
end
