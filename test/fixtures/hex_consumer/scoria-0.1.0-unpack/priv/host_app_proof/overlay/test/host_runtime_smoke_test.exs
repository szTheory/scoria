defmodule HostRuntimeSmokeTest do
  use ScoriaHostProofWeb.ConnCase, async: false

  alias Ecto.Adapters.SQL.Sandbox

  import Phoenix.LiveViewTest

  defmodule Handlers do
    def wait_for_approval(_step, run) do
      {:waiting_for_approval,
       %{
         tool_name: "publish",
         arguments: %{"env" => "prod"},
         reason: "Need approval",
         actor_id: "operator-host-proof",
         tenant_id: "tenant-host-proof",
         trace_id: "trace-#{run.id}"
       }}
    end
  end

  setup do
    :ok = Sandbox.checkout(Scoria.Repo)
    Sandbox.mode(Scoria.Repo, {:shared, self()})
    Application.put_env(:scoria, :workflow_runtime_handlers, %{"approval" => {Handlers, :wait_for_approval}})
    start_supervised!(Scoria.Workflows.Reconciler)
    :ok
  end

  test "host proves one durable run, readback, and operator evidence", %{conn: conn} do
    identity = %{actor_id: "host-actor", tenant_id: "host-tenant", session_id: "host-session"}

    {:ok, started} =
      Scoria.start_run(identity,
        root_role_id: "executor",
        initial_step: %{sequence: 1, kind: "approval", role_id: "executor", status: "queued"},
        handlers: %{"approval" => {Handlers, :wait_for_approval}}
      )

    wait_for(fn ->
      case Scoria.get_run(started.run_id) do
        {:ok, summary} -> summary.status == "waiting_for_approval"
        _ -> false
      end
    end)

    {:ok, summary} = Scoria.get_run(started.run_id)
    grouped = Scoria.list_runs_for_session(identity.session_id)

    operator_conn =
      Plug.Test.init_test_session(conn, %{
        "actor_id" => "operator-host-proof",
        "tenant_id" => "tenant-host-proof"
      })

    {:ok, view, _html} = live(operator_conn, "/scoria/workflows/#{started.run_id}")

    assert summary.run_id == started.run_id
    assert summary.session_id == identity.session_id
    assert Enum.any?(grouped, &(&1.run_id == started.run_id))
    assert render(view) =~ started.run_id
    assert render(view) =~ "waiting_for_approval"
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
