defmodule SupportCopilot.JourneyTest do
  use SupportCopilotWeb.ConnCase, async: false

  alias Scoria.SupportJourney
  alias Scoria.Workflows

  test "gallery home shows support journey ticket and persona", %{conn: conn} do
    {:ok, view, html} = live(conn, "/")

    assert html =~ SupportJourney.ticket_fixture()["id"]
    assert html =~ SupportJourney.ticket_fixture()["subject"]
    assert html =~ SupportJourney.persona_fixture()["persona"]
    assert html =~ "Support Ops Console"
    assert has_element?(view, "button", "Start refund review run")
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
             Scoria.resume_run(run_id,
               handlers: %{"approval" => {SupportCopilot.RuntimeHandlers, :succeed}}
             )

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
