defmodule ScoriaWeb.WorkflowLiveTest.Router do
  use Phoenix.Router
  import ScoriaWeb.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
  end

  scope "/" do
    pipe_through :browser
    scoria_dashboard("/scoria")
  end
end

defmodule ScoriaWeb.WorkflowLiveTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug Plug.Session,
    store: :cookie,
    key: "_workflow_key",
    signing_salt: "workflow_salt"

  plug ScoriaWeb.WorkflowLiveTest.Router
end

defmodule ScoriaWeb.WorkflowLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Workflows

  @endpoint ScoriaWeb.WorkflowLiveTest.Endpoint

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.WorkflowLiveTest.Endpoint,
      secret_key_base: "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1M",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "87654321"],
      debug_errors: true
    )

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    start_supervised!(ScoriaWeb.WorkflowLiveTest.Endpoint)
    :ok
  end

  test "LiveView mounts from persisted workflow records and subscribes for projection updates" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})
    {:ok, step} = Workflows.create_step(run.id, %{sequence: 1, kind: "tool", role_id: "executor", status: "running"})
    {:ok, _checkpoint} = Workflows.append_checkpoint(run.id, step.id, %{transition: "tool_started", status: "running", snapshot: %{"tool" => "fetch"}})

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, _view, html} = live(conn, "/scoria/workflows/#{run.id}")

    assert html =~ "Workflow Run"
    assert html =~ run.id
    assert html =~ "running"
    assert html =~ "tool"
  end

  test "run page renders lifecycle badges and responds to run and step updates without owning truth" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})
    {:ok, step} = Workflows.create_step(run.id, %{sequence: 1, kind: "tool", role_id: "executor", status: "running"})

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.WorkflowLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria/workflows/#{run.id}")

    assert render(view) =~ "running"

    {:ok, _step} = Workflows.complete_step(step.id, %{"ok" => true})

    assert render(view) =~ "completed"
    assert render(view) =~ "step_completed"
  end
end
