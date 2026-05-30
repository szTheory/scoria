defmodule HostRuntimeSmokeTest do
  use ScoriaHostProofWeb.ConnCase, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias Scoria.SupportJourney
  alias Scoria.SupportJourney.Handlers
  alias Scoria.Workflows

  import Phoenix.LiveViewTest

  setup do
    :ok = Sandbox.checkout(Scoria.Repo)
    Sandbox.mode(Scoria.Repo, {:shared, self()})
    Application.put_env(:scoria, :workflow_runtime_handlers, %{"approval" => {Handlers, :wait_for_approval}})
    start_supervised!(Scoria.Workflows.Reconciler)
    :ok
  end

  test "host proves support journey run, approval, resume, and operator evidence", %{conn: conn} do
    identity = SupportJourney.runtime_identity()

    {:ok, started} =
      Scoria.start_run(identity,
        root_role_id: "support_agent",
        initial_step: %{sequence: 1, kind: "approval", role_id: "support_agent", status: "queued"},
        handlers: %{"approval" => {Handlers, :wait_for_approval}}
      )

    wait_for(fn ->
      case Scoria.get_run(started.run_id) do
        {:ok, summary} -> summary.status == SupportJourney.waiting_status()
        _ -> false
      end
    end)

    {:ok, summary} = Scoria.get_run(started.run_id)
    grouped = Scoria.list_runs_for_session(identity.session_id)

    operator_conn =
      Plug.Test.init_test_session(conn, %{
        "actor_id" => SupportJourney.operator_identity().actor_id,
        "tenant_id" => SupportJourney.tenant_id()
      })

    {:ok, view, _html} = live(operator_conn, SupportJourney.operator_route(started.run_id))

    assert summary.run_id == started.run_id
    assert summary.session_id == identity.session_id
    assert Enum.any?(grouped, &(&1.run_id == started.run_id))
    assert render(view) =~ started.run_id
    assert render(view) =~ SupportJourney.waiting_status()

    run = Workflows.get_run_tree!(started.run_id)
    [approval | _] = Enum.reverse(run.approvals)
    {:ok, _approval} = Workflows.approve(approval.id, "approved", %{actor_id: SupportJourney.operator_identity().actor_id})

    assert {:ok, resumed} =
             Scoria.resume_run(started.run_id, handlers: %{"approval" => {Handlers, :succeed}})

    assert resumed.run_id == started.run_id

    wait_for(fn ->
      case Scoria.get_run(started.run_id) do
        {:ok, summary} -> summary.status == SupportJourney.completed_status()
        _ -> false
      end
    end)

    assert render(view) =~ SupportJourney.completed_status()
  end

  defp wait_for(fun, attempts \\ 40)

  defp wait_for(fun, attempts) when attempts > 0 do
    if fun.() do
      :ok
    else
      Process.sleep(25)
      wait_for(fun, attempts - 1)
    end
  end

  defp wait_for(_fun, 0), do: flunk("condition not met before timeout")
end
