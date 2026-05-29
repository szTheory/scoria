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

  alias Scoria.Repo
  alias Scoria.Repo.Trace
  alias Scoria.Eval.OnlineScoreCandidate
  alias Scoria.Runtime.Instance
  alias Scoria.SRE.AuditOutboxEvent
  alias Scoria.Workflows
  alias Scoria.Workflows.Runtime
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
      secret_key_base: "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1M",
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
  end

  test "tokens are buffered and flushed properly" do
    conn =
      build_conn()
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

  test "runtime drawer loads semantic summary for runtimes with a current run and stays stable without one" do
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "assistant",
        tenant_id: "tenant-live",
        session_id: "session-runtime",
        status: "completed",
        execution_mode: "live",
        metadata: %{
          "runtime" => %{
            "semantic_cache" => %{
              "lookup_status" => "bypass",
              "eligibility_status" => "bypass",
              "eligibility_reason_code" => "approval_required",
              "lane_key" => "account_faq",
              "scope_kind" => "tenant_shared",
              "scope_reason" => "lane_default"
            }
          }
        }
      })

    active_instance =
      Repo.insert!(%Instance{
      tenant_id: "tenant-live",
      host_session_id: "session-runtime",
      current_run_id: run.id,
      first_seen_at: DateTime.utc_now() |> DateTime.truncate(:second),
      last_seen_at: DateTime.utc_now() |> DateTime.truncate(:second),
      transport_kind: "websocket"
      })

    offline_instance =
      Repo.insert!(%Instance{
        tenant_id: "tenant-live",
        host_session_id: "session-empty-runtime",
        current_run_id: nil,
        first_seen_at: DateTime.utc_now() |> DateTime.truncate(:second),
        last_seen_at: DateTime.utc_now() |> DateTime.truncate(:second),
        transport_kind: "sse",
        terminal_offline_reason: "Terminal exited"
      })

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{"tenant_id" => "tenant-live"})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria")

    html =
      view
      |> element("button[phx-click='open_runtime_drawer'][phx-value-id='#{offline_instance.id}']")
      |> render_click()

    assert html =~ "Terminal exited"
    refute html =~ "lookup_status"

    html =
      view
      |> element("button[phx-click='open_runtime_drawer'][phx-value-id='#{active_instance.id}']")
      |> render_click()

    assert html =~ "lookup_status"
    assert html =~ "bypass"
    assert html =~ "approval_required"
    assert html =~ "lane_key"
    assert html =~ "scope_kind"
    assert html =~ "View workflow evidence"
  end

  test "HITL approval request renders modal and handles approve" do
    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{
        "actor_id" => "operator-live",
        "tenant_id" => "tenant-live"
      })
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria")

    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "approval",
        role_id: "executor",
        status: "queued"
      })

    {:ok, approval} =
      Runtime.execute_step(step.id, handler: {ApprovalHandlers, :wait_for_approval})

    send(view.pid, {:hitl_request, approval})

    html = render(view)
    assert html =~ "Approval Required"
    assert html =~ "test_tool"
    assert html =~ "Approve Decision"
    assert html =~ "Reject Decision"
    assert html =~ "durably"

    render_click(view, "approve", %{})

    eventually(fn -> render(view) !~ "Approval Required" end)

    updated_approval = Repo.get!(Scoria.Observe.Approval, approval.id)
    assert updated_approval.status == "approved"
    assert Workflows.get_run!(run.id).status == "completed"
    assert Workflows.get_step!(step.id).status == "completed"

    approved_event =
      Repo.get_by!(AuditOutboxEvent,
        workflow_run_id: run.id,
        event_type: "approval.approved",
        trace_id: "trace-#{run.id}"
      )

    assert approved_event.actor_ref == "operator-live"
    assert approved_event.redacted_refs["approval_id"] == approval.id
  end

  test "HITL approval request handles reject" do
    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{
        "actor_id" => "operator-live",
        "tenant_id" => "tenant-live"
      })
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.OrchestratorLiveTest.Endpoint)

    {:ok, view, _html} = live(conn, "/scoria")

    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "approval",
        role_id: "executor",
        status: "queued"
      })

    {:ok, approval} =
      Runtime.execute_step(step.id, handler: {ApprovalHandlers, :wait_for_approval})

    send(view.pid, {:hitl_request, approval})

    render_click(view, "reject", %{})

    eventually(fn -> Repo.get!(Scoria.Observe.Approval, approval.id).status == "rejected" end)
    assert Workflows.get_run!(run.id).status == "waiting_for_approval"
    assert Workflows.get_step!(step.id).status == "waiting_for_approval"

    rejected_event =
      Repo.get_by!(AuditOutboxEvent,
        workflow_run_id: run.id,
        event_type: "approval.rejected",
        trace_id: "trace-#{run.id}"
      )

    assert rejected_event.actor_ref == "operator-live"
    assert rejected_event.redacted_refs["approval_id"] == approval.id
  end

  defp review_candidate_fixture do
    {:ok, trace} =
      %Trace{}
      |> Trace.changeset(%{
        session_id: "session-review",
        attributes: %{"env" => "prod"}
      })
      |> Repo.insert()

    {:ok, run} =
      %Run{}
      |> Run.changeset(%{
        root_role_id: "assistant",
        tenant_id: "tenant-review",
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
        tenant_id: "tenant-review",
        trace_id: trace.id,
        workflow_run_id: run.id,
        workflow_step_id: step.id,
        dedupe_key: "tenant-review:#{trace.id}:orchestrator",
        status: "needs_review",
        review_status: "pending",
        score_status: "failed",
        score_explanation: "Queue evidence on the runtime landing surface",
        scorer_kind: "deterministic_rule",
        scorer_version: "policy-rules@2026.05.23",
        sampling_metadata: %{"sample_reason" => "policy_trigger"}
      })
    )
  end

end
