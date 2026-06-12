defmodule ScoriaWeb.OrchestratorLiveTest.Router do
  use Phoenix.Router
  import ScoriaWeb.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
  end

  scope "/" do
    pipe_through(:browser)
    scoria_dashboard("/scoria")
  end
end

defmodule ScoriaWeb.OrchestratorLiveTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_scoria_key",
    signing_salt: "scoria_salt"
  )

  plug(ScoriaWeb.OrchestratorLiveTest.Router)
end

defmodule ScoriaWeb.OrchestratorLiveTest do
  use Scoria.IntegrationCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Scoria.Connectors.Connector
  alias Scoria.Observe.Approval
  alias Scoria.Repo
  alias Scoria.Repo.Trace
  alias Scoria.Eval.OnlineScoreCandidate
  alias Scoria.SRE.Incident
  alias Scoria.Workflows.{Run, Step}

  @endpoint ScoriaWeb.OrchestratorLiveTest.Endpoint

  defmodule ApprovalHandlers do
    def wait_for_approval(_step, run) do
      {:waiting_for_approval,
       %{
         tool_name: "test_tool",
         arguments: %{"env" => "prod"},
         reason: "Requires approval",
         actor_id: "operator-live",
         tenant_id: "tenant-live",
         trace_id: "trace-#{run.id}"
       }}
    end

    def succeed(step, _run), do: {:ok, %{"step_id" => step.id, "status" => "approved"}}
  end

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.OrchestratorLiveTest.Endpoint,
      secret_key_base: "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1MpAdExtraKeyMaterial0123456789",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "112345678"],
      debug_errors: true
    )

    :ok
  end

  setup do
    Application.put_env(:scoria, :workflow_runtime_handlers, %{
      "approval" => {ApprovalHandlers, :succeed}
    })

    start_supervised!(ScoriaWeb.OrchestratorLiveTest.Endpoint)
    :ok
  end

  test "OrchestratorLive mounts successfully and renders dummy wrapper" do
    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, _view, html} = live(conn, "/scoria")
    assert html =~ "scoria-dashboard"
  end

  test "Status Home renders exact orientation copy and day-zero stream empty state" do
    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria?tenant=tenant-status-empty")

    html = render_async(view)

    assert html =~ "Home"

    assert html =~
             "Every AI run in this app, traced. Approve tools, triage incidents, and gate prompt releases from here."

    assert html =~ "Nothing needs attention. 0 approvals pending, 0 open incidents."
    assert html =~ "No traces yet. Run your first chat response or MCP request to see the run tree."
    assert html =~ ~s(id="traces-list")

    refute html =~ "Review approvals"
    refute html =~ "Open incidents"
    refute html =~ "View connector health"
    refute html =~ "Review flagged runs"
  end

  test "Status Home renders nonzero attention cards from read-model counts" do
    tenant_id = "tenant-status-attention"
    status_home_fixture(tenant_id)

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria?tenant=#{tenant_id}")

    html = render_async(view)

    assert html =~ "Review approvals"
    assert html =~ "Open incidents"
    assert html =~ "View connector health"
    assert html =~ "Review flagged runs"
    refute html =~ "Nothing needs attention. 0 approvals pending, 0 open incidents."
  end

  test "OrchestratorLive subscribes to PubSub and renders streaming traces" do
    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria")

    # Send a dummy trace message simulating PubSub broadcast
    trace = %{id: "trace-123", spans: [%{id: "span-1", name: "llm_call", depth: 0}]}
    send(view.pid, {:new_trace, trace})

    # Render again to see if it streamed the trace using the component
    assert render(view) =~ "llm_call"
    assert render(view) =~ "trace-tree"
    assert render(view) =~ ~s(id="traces-list")
  end

  test "trace_opened and trace_span sequence renders span name incrementally" do
    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria")
    trace_id = "trace-incr-1"

    send(view.pid, {:trace_opened, %{id: trace_id, tenant_id: "default"}})

    refute render(view) =~ "agent_turn"

    send(view.pid, {:trace_span, trace_id, %{id: "span-1", name: "agent_turn", span_kind: "LLM"}})

    assert render(view) =~ "agent_turn"
  end

  test "duplicate trace_opened is ignored idempotently" do
    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria")
    trace_id = "trace-dup-1"
    header = %{id: trace_id, tenant_id: "default"}

    send(view.pid, {:trace_opened, header})
    send(view.pid, {:trace_span, trace_id, %{id: "span-1", name: "first_span"}})
    send(view.pid, {:trace_opened, header})

    html = render(view)
    assert html =~ "first_span"
    assert html =~ ~s(id="trace-dup-1")
  end

  test "trace_span upsert replaces span with same id" do
    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria")
    trace_id = "trace-upsert-1"
    span_id = "span-same"

    send(view.pid, {:trace_opened, %{id: trace_id}})
    send(view.pid, {:trace_span, trace_id, %{id: span_id, name: "draft"}})
    send(view.pid, {:trace_span, trace_id, %{id: span_id, name: "final"}})

    html = render(view)
    assert html =~ "final"
    refute html =~ "draft"
  end

  test "trace_delta coalesces preview on LLM span row without global token strip" do
    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, view, html} = live(conn, "/scoria")

    refute html =~ "token-stream"

    trace_id = "trace-token-1"
    span_id = "span-llm-1"

    send(view.pid, {:trace_opened, %{id: trace_id}})
    send(view.pid, {:trace_span, trace_id, %{id: span_id, name: "llm_call", span_kind: "LLM"}})
    send(view.pid, {:trace_delta, %{trace_id: trace_id, span_id: span_id, chunk: "Hello"}})
    send(view.pid, {:trace_delta, %{trace_id: trace_id, span_id: span_id, chunk: " world"}})
    send(view.pid, {:flush_tokens, span_id})

    html = render(view)
    assert html =~ "Hello world"
    assert html =~ "token-preview"
    refute html =~ "token-stream"
  end

  test "retrieval evidence loads lazily and renders citation freshness details" do
    conn =
      build_conn()
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
    conn =
      build_conn()
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
    conn =
      build_conn()
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

  test "review candidate deep links preserve queue evidence on the runtime landing surface" do
    candidate = review_candidate_fixture()

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, _view, html} =
      live(conn, "/scoria?runtime=session-review&review_candidate_id=#{candidate.id}")

    assert html =~ "Review candidate context"
    assert html =~ candidate.score_explanation
    assert html =~ candidate.trace_id
  end

  defp status_home_fixture(tenant_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    Repo.insert!(
      Approval.changeset(%Approval{}, %{
        tool_name: "deploy_prompt",
        status: "pending",
        tenant_id: tenant_id,
        reason: "Prompt release gate"
      })
    )

    Repo.insert!(
      Incident.changeset(%Incident{}, %{
        tenant_id: tenant_id,
        incident_key: "#{tenant_id}:critical-budget",
        severity: "critical",
        status: "open",
        summary: "Budget breaker opened",
        routing_class: "page",
        dedupe_key: "#{tenant_id}:critical-budget",
        first_seen_at: now,
        last_seen_at: now
      })
    )

    Repo.insert!(
      Connector.changeset(%Connector{}, %{
        tenant_id: tenant_id,
        key: "#{tenant_id}-mcp",
        label: "Tenant MCP",
        endpoint_url: "https://example.com/mcp",
        transport_kind: "sse",
        auth_mode: "none",
        status: "degraded",
        health_state: "degraded",
        last_refresh_status: "error"
      })
    )

    review_candidate_fixture(%{
      tenant_id: tenant_id,
      session_id: "#{tenant_id}-session",
      score_explanation: "Flagged run requires operator review",
      dedupe_suffix: "status-home"
    })
  end

  defp review_candidate_fixture(attrs \\ %{}) do
    tenant_id = Map.get(attrs, :tenant_id, "tenant-review")
    session_id = Map.get(attrs, :session_id, "session-review")
    score_explanation = Map.get(attrs, :score_explanation, "Queue evidence on the runtime landing surface")
    dedupe_suffix = Map.get(attrs, :dedupe_suffix, "orchestrator")

    {:ok, trace} =
      %Trace{}
      |> Trace.changeset(%{
        session_id: session_id,
        attributes: %{"env" => "prod"}
      })
      |> Repo.insert()

    {:ok, run} =
      %Run{}
      |> Run.changeset(%{
        root_role_id: "assistant",
        tenant_id: tenant_id,
        session_id: trace.session_id,
        status: "running",
        execution_mode: "live"
      })
      |> Repo.insert()

    {:ok, step} =
      %Step{}
      |> Step.changeset(%{
        run_id: run.id,
        sequence: 1,
        kind: "llm_call",
        role_id: "assistant",
        status: "completed"
      })
      |> Repo.insert()

    Repo.insert!(
      OnlineScoreCandidate.changeset(%OnlineScoreCandidate{}, %{
        tenant_id: tenant_id,
        trace_id: trace.id,
        workflow_run_id: run.id,
        workflow_step_id: step.id,
        dedupe_key: "#{tenant_id}:#{trace.id}:#{dedupe_suffix}",
        status: "needs_review",
        review_status: "pending",
        score_status: "failed",
        score_explanation: score_explanation,
        scorer_kind: "deterministic_rule",
        scorer_version: "policy-rules@2026.05.23",
        sampling_metadata: %{"sample_reason" => "policy_trigger"}
      })
    )
  end
end
