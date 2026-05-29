defmodule HostHandoffSmokeTest do
  use ScoriaHostProofWeb.ConnCase, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias Scoria.SupportJourney

  import Phoenix.LiveViewTest

  setup do
    :ok = Sandbox.checkout(Scoria.Repo)
    Sandbox.mode(Scoria.Repo, {:shared, self()})
    start_supervised!(Scoria.Workflows.Reconciler)
    :ok
  end

  test "host proves bounded handoff delegated evidence for billing escalation", %{conn: conn} do
    identity = SupportJourney.runtime_identity()

    assert {:ok, started} = Scoria.start_run(identity, root_role_id: "support_agent")

    assert {:ok, handoff_run} =
             Scoria.start_handoff_run(identity, SupportJourney.handoff_role_id(),
               root_role_id: "support_agent",
               delegated_kind: SupportJourney.delegated_kind(),
               handoff_input: SupportJourney.handoff_input(),
               projected_context: SupportJourney.projected_context()
             )

    assert started.session_id == handoff_run.session_id
    assert started.run_id != handoff_run.run_id

    assert {:ok, detail} = Scoria.get_run_detail(handoff_run.run_id)

    assert [
             %{
               delegated_role_id: role,
               delegated_kind: kind
             }
           ] = detail.delegated_handoffs

    assert role == SupportJourney.handoff_role_id()
    assert kind == SupportJourney.delegated_kind()

    operator_conn =
      Plug.Test.init_test_session(conn, %{
        "actor_id" => SupportJourney.operator_identity().actor_id,
        "tenant_id" => SupportJourney.tenant_id()
      })

    {:ok, view, _html} = live(operator_conn, SupportJourney.operator_route(handoff_run.run_id))

    assert render(view) =~ handoff_run.run_id
    assert render(view) =~ SupportJourney.handoff_role_id()
  end
end
