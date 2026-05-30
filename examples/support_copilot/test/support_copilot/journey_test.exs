defmodule SupportCopilot.JourneyTest do
  use SupportCopilotWeb.ConnCase, async: false

  alias Scoria.Connectors
  alias Scoria.SupportJourney
  alias Scoria.SupportJourney.Handlers
  alias Scoria.Workflows

  test "gallery home shows support journey ticket and persona", %{conn: conn} do
    {:ok, view, html} = live(conn, "/")

    assert html =~ SupportJourney.ticket_fixture()["id"]
    assert html =~ SupportJourney.ticket_fixture()["subject"]
    assert html =~ SupportJourney.persona_fixture()["persona"]
    assert html =~ "Support Ops Console"
    assert has_element?(view, "button", "Start refund review run")
    assert has_element?(view, "button", "Lookup ticket")
    assert has_element?(view, "button", "Run semantic FAQ lane")
    assert has_element?(view, "button", "Run knowledge lane")
    assert has_element?(view, "button", "Run connector lane")
  end

  test "lookup ticket journey exercises lookup_support_ticket tool", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    render_click(view, "lookup_ticket")

    html = render(view)
    assert html =~ SupportJourney.ticket_fixture()["id"]
    assert html =~ SupportJourney.ticket_lookup_tool()
  end

  test "default lane starts approval run and surfaces operator evidence", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    render_click(view, "start_refund_review")

    html = render(view)
    assert html =~ SupportJourney.waiting_status()

    run_id = extract_run_id(html)
    assert run_id

    operator_conn =
      conn
      |> Plug.Test.init_test_session(%{
        "actor_id" => SupportJourney.operator_identity().actor_id,
        "tenant_id" => SupportJourney.tenant_id()
      })

    {:ok, operator_view, operator_html} = live(operator_conn, SupportJourney.operator_route(run_id))

    assert operator_html =~ run_id
    assert operator_html =~ SupportJourney.waiting_status()

    run = Workflows.get_run_tree!(run_id)
    [approval | _] = Enum.reverse(run.approvals)
    {:ok, _approval} = Workflows.approve(approval.id, "approved")

    assert {:ok, _resumed} =
             Scoria.resume_run(run_id, handlers: %{"approval" => {Handlers, :succeed}})

    eventually(fn ->
      case Scoria.get_run(run_id) do
        {:ok, summary} -> summary.status == SupportJourney.completed_status()
        _ -> false
      end
    end)

    assert render(operator_view) =~ SupportJourney.completed_status()
  end

  test "handoff lane escalates to billing specialist with delegated evidence", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    render_click(view, "escalate_billing")

    html = render(view)
    assert html =~ "delegated"

    run_id = extract_run_id(html)
    assert {:ok, detail} = Scoria.get_run_detail(run_id)
    assert Enum.any?(detail.delegated_handoffs, &(&1.delegated_role_id == SupportJourney.handoff_role_id()))

    operator_conn =
      conn
      |> Plug.Test.init_test_session(%{
        "actor_id" => SupportJourney.operator_identity().actor_id,
        "tenant_id" => SupportJourney.tenant_id()
      })

    {:ok, operator_view, operator_html} =
      live(operator_conn, SupportJourney.operator_route(run_id))

    assert operator_html =~ SupportJourney.handoff_role_id()
    assert operator_html =~ SupportJourney.ticket_fixture()["id"]
    assert render(operator_view) =~ run_id
  end

  test "semantic FAQ lane starts a read-only semantic journey", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    render_click(view, "run_semantic_faq")

    html = render(view)
    assert html =~ "semantic"
    assert html =~ "Semantic FAQ lane"

    run_id = extract_run_id(html)
    assert {:ok, summary} = Scoria.get_run(run_id)
    assert summary.run_id == run_id
  end

  test "knowledge lane seeds refund policy and surfaces grounded journey", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    render_click(view, "run_knowledge_lane")

    html = render(view)
    assert html =~ "knowledge"
    assert html =~ SupportJourney.knowledge_source_title()
  end

  test "connector lane registers billing connector and surfaces connector journey", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    render_click(view, "run_connector_lane")

    html = render(view)
    assert html =~ "connector"
    assert html =~ SupportJourney.connector_label()

    fleet = Connectors.list_connector_fleet(%{tenant_id: SupportJourney.tenant_id()})
    assert Enum.any?(fleet, &(&1.connector_key == SupportJourney.connector_key()))
  end

  defp extract_run_id(html) do
    case Regex.run(~r/<code>([^<]+)<\/code>/, html) do
      [_, run_id] -> run_id
      _ -> nil
    end
  end

  defp eventually(fun, attempts \\ 40)

  defp eventually(fun, attempts) when attempts > 0 do
    if fun.() do
      :ok
    else
      Process.sleep(25)
      eventually(fun, attempts - 1)
    end
  end

  defp eventually(_fun, 0), do: flunk("condition not met before timeout")
end
