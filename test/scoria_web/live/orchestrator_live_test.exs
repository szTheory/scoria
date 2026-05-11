defmodule ScoriaWeb.OrchestratorLiveTest.Router do
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

defmodule ScoriaWeb.OrchestratorLiveTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria
  plug Plug.Session,
    store: :cookie,
    key: "_scoria_key",
    signing_salt: "scoria_salt"
  plug ScoriaWeb.OrchestratorLiveTest.Router
end

defmodule ScoriaWeb.OrchestratorLiveTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint ScoriaWeb.OrchestratorLiveTest.Endpoint

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.OrchestratorLiveTest.Endpoint,
      secret_key_base: "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1M",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "112345678"],
      debug_errors: true
    )

    :ok
  end

  setup do
    start_supervised!(ScoriaWeb.OrchestratorLiveTest.Endpoint)
    :ok
  end

  test "OrchestratorLive mounts successfully and renders dummy wrapper" do
    conn = build_conn()
           |> Plug.Test.init_test_session(%{})
           |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, _view, html} = live(conn, "/scoria")
    assert html =~ "scoria-dashboard"
  end

  test "OrchestratorLive subscribes to PubSub and renders streaming traces" do
    conn = build_conn()
           |> Plug.Test.init_test_session(%{})
           |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria")
    
    # Send a dummy trace message simulating PubSub broadcast
    trace = %{id: "trace-123", spans: [%{id: "span-1", name: "llm_call", depth: 0}]}
    send(view.pid, {:new_trace, trace})

    # Render again to see if it streamed the trace using the component
    assert render(view) =~ "llm_call"
    assert render(view) =~ "trace-tree"
  end

  test "tokens are buffered and flushed properly" do
    conn = build_conn()
           |> Plug.Test.init_test_session(%{})
           |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria")
    
    # Send tokens
    send(view.pid, {:token, "Hello"})
    send(view.pid, {:token, " World"})

    # Ensure they are not in the DOM immediately (buffered)
    refute render(view) =~ "Hello World"
    
    # Send flush event explicitly (or wait for timer)
    send(view.pid, :flush_tokens)

    # Now they should be in the DOM
    assert render(view) =~ "Hello World"
  end

  test "retrieval evidence loads lazily and renders citation freshness details" do
    conn = build_conn()
           |> Plug.Test.init_test_session(%{})
           |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria")

    trace = %{id: "trace-evidence", spans: [%{id: "span-1", name: "retrieve", depth: 0}]}
    send(view.pid, {:new_trace, trace})

    render_click(view, "load_retrieval_evidence", %{"id" => "trace-evidence"})

    assert render(view) =~ "citation"
    assert render(view) =~ "freshness"
    assert render(view) =~ "side-by-side"
  end

  test "retrieval evidence remains available alongside the SRE incident panel" do
    conn = build_conn()
           |> Plug.Test.init_test_session(%{})
           |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria")

    trace = %{id: "trace-combined", spans: [%{id: "span-1", name: "retrieve", depth: 0}]}
    send(view.pid, {:new_trace, trace})

    refute render(view) =~ "Composite health rollup"

    render_click(view, "load_retrieval_evidence", %{"id" => "trace-combined"})
    render_click(view, "load_incident_evidence", %{"id" => "trace-combined"})
    render_async(view)

    html = render(view)
    assert html =~ "side-by-side"
    assert html =~ "Composite health rollup"
    assert html =~ "Load Retrieval Evidence"
  end

  test "replay and promote retrieval actions surface trace-first notices" do
    conn = build_conn()
           |> Plug.Test.init_test_session(%{})
           |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria")

    trace = %{id: "trace-actions", spans: [%{id: "span-1", name: "retrieve", depth: 0}]}
    send(view.pid, {:new_trace, trace})

    render_click(view, "replay_retrieval", %{"id" => "trace-actions"})
    render_click(view, "promote_retrieval", %{"id" => "trace-actions"})

    html = render(view)
    assert html =~ "replay_retrieval"
    assert html =~ "promote_retrieval"
  end

  test "HITL approval request renders modal and handles approve" do
    Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    conn = build_conn()
           |> Plug.Test.init_test_session(%{})
           |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria")
    
    # Create an approval
    {:ok, approval} = Scoria.Repo.insert(
      %Scoria.Observe.Approval{
        tool_name: "test_tool",
        status: "pending",
        session_id: "sess_1",
        run_id: "run_1"
      }
    )

    # Trigger HITL
    send(view.pid, {:hitl_request, approval})

    # Render view and assert modal exists
    html = render(view)
    assert html =~ "Approval Required"
    assert html =~ "test_tool"

    # Click approve
    render_click(view, "approve", %{})

    # Modal should be gone
    refute render(view) =~ "Approval Required"

    # DB should be updated
    updated_approval = Scoria.Repo.get!(Scoria.Observe.Approval, approval.id)
    assert updated_approval.status == "approved"
  end

  test "HITL approval request handles reject" do
    Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    conn = build_conn()
           |> Plug.Test.init_test_session(%{})
           |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria")
    
    {:ok, approval} = Scoria.Repo.insert(
      %Scoria.Observe.Approval{
        tool_name: "dangerous_tool",
        status: "pending",
        session_id: "sess_2",
        run_id: "run_2"
      }
    )

    send(view.pid, {:hitl_request, approval})

    render_click(view, "reject", %{})

    updated_approval = Scoria.Repo.get!(Scoria.Observe.Approval, approval.id)
    assert updated_approval.status == "rejected"
  end
end
