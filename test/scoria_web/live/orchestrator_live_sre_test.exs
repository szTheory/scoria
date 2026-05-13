defmodule ScoriaWeb.OrchestratorLiveSRETest.Router do
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

defmodule ScoriaWeb.OrchestratorLiveSRETest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_scoria_sre_key",
    signing_salt: "scoria_sre_salt"
  )

  plug(ScoriaWeb.OrchestratorLiveSRETest.Router)
end

defmodule ScoriaWeb.OrchestratorLiveSRETest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Decimal, as: D
  alias Scoria.Repo

  alias Scoria.SRE.{
    AlertEvent,
    AuditOutboxEvent,
    BreakerTrip,
    BudgetPolicy,
    BudgetReservation,
    Incident,
    IncidentEvent,
    NotificationDelivery
  }

  alias Scoria.Workflows

  @endpoint ScoriaWeb.OrchestratorLiveSRETest.Endpoint

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.OrchestratorLiveSRETest.Endpoint,
      secret_key_base: "JcQF3J7M1pW1B3vA8L9tX2mE0sQ7nF4uP5kR6yH8zN1cD4bV9mT2wL6aS8qP3eY",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "998877665"],
      debug_errors: true
    )

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    original_audit_sink = Application.get_env(:scoria, :sre_audit_sink)

    Application.delete_env(:scoria, :sre_audit_sink)

    on_exit(fn ->
      case original_audit_sink do
        nil -> Application.delete_env(:scoria, :sre_audit_sink)
        value -> Application.put_env(:scoria, :sre_audit_sink, value)
      end
    end)

    start_supervised!(@endpoint)
    :ok
  end

  test "incident evidence renders workflow-owned approval, incident, and delivery lineage from the real path" do
    trace_id = "trace-sre-real"
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "approval_gate",
        role_id: "critic",
        status: "running"
      })

    {:ok, approval} =
      Workflows.mark_waiting_for_approval(run.id, step.id, %{
        tool_name: "publish",
        arguments: %{"env" => "prod"},
        reason: "Need operator approval",
        actor_id: "operator-sre",
        tenant_id: "tenant-sre",
        trace_id: trace_id
      })

    seed_budget_and_breaker!(trace_id, run.id)

    assert {:ok, %{notification_deliveries: [review_delivery]}} =
             Scoria.SRE.record_alert_event(%{
               tenant_id: "tenant-sre",
               subject_kind: "workflow",
               policy_key: "tenant:default:quality",
               reason_code: "ci_baseline_dip",
               summary: "Review incident",
               measured_value: D.new("0.61"),
               threshold_value: D.new("0.75"),
               scorer_version: "scorer-v4",
               baseline_version: "baseline-2026-05-11",
               trace_id: trace_id,
               workflow_run_id: run.id,
               window_bucket: "2026-05-11T18",
               routing_class: "review",
               approval_id: approval.id
             })

    assert {:ok, %{notification_deliveries: [page_delivery]}} =
             Scoria.SRE.record_alert_event(%{
               tenant_id: "tenant-sre",
               subject_kind: "workflow",
               policy_key: "tenant:default:cost_usd",
               reason_code: "budget_fast_burn",
               summary: "Page incident",
               measured_value: D.new("103.0"),
               threshold_value: D.new("100.0"),
               severity: "critical",
               routing_class: "page",
               fast_burn: true,
               trace_id: trace_id,
               workflow_run_id: run.id,
               window_bucket: "2026-05-11T18",
               approval_id: approval.id
             })

    assert :ok = Scoria.SRE.Relay.drain_once()

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, @endpoint)

    {:ok, view, _html} = live(conn, "/scoria")

    send(
      view.pid,
      {:new_trace,
       %{
         id: trace_id,
         workflow_run_id: run.id,
         spans: [%{id: "span-sre-1", name: "score_run", depth: 0}]
       }}
    )

    render_click(view, "load_incident_evidence", %{"id" => trace_id, "run_id" => run.id})
    render_async(view)

    html = render(view)

    assert html =~ "Composite health rollup"
    assert html =~ "scorer-v4"
    assert html =~ "baseline-2026-05-11"
    assert html =~ approval.id
    assert html =~ trace_id
    assert html =~ run.id
    assert html =~ "Review incident"
    assert html =~ "Page incident"
    assert html =~ "chimeway"
    assert html =~ "mailglass"
    assert html =~ "approval.requested"
    assert html =~ "outcome"
    assert html =~ "unconfigured"

    audit_event =
      Repo.get_by!(AuditOutboxEvent,
        workflow_run_id: run.id,
        event_type: "approval.requested",
        trace_id: trace_id
      )

    assert audit_event.redacted_refs["approval_id"] == approval.id

    review_delivery = Repo.get!(NotificationDelivery, review_delivery.id)
    page_delivery = Repo.get!(NotificationDelivery, page_delivery.id)

    assert review_delivery.trace_id == trace_id
    assert review_delivery.workflow_run_id == run.id
    assert page_delivery.trace_id == trace_id
    assert page_delivery.workflow_run_id == run.id
    assert review_delivery.metadata["delivery_outcome"] == "unconfigured"
    assert page_delivery.metadata["delivery_outcome"] == "unconfigured"
  end

  test "lazy budget and incident loads promote compact trace badges without replacing the trace-first controls" do
    run_id = Ecto.UUID.generate()
    seed_incident_evidence!("trace-sre-2", run_id)

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, @endpoint)

    {:ok, view, _html} = live(conn, "/scoria")

    send(
      view.pid,
      {:new_trace,
       %{
         id: "trace-sre-2",
         workflow_run_id: run_id,
         spans: [%{id: "span-sre-2", name: "budget_guard", depth: 0}]
       }}
    )

    html = render(view)
    refute html =~ "Budget warn"
    refute html =~ "breaker open"

    render_click(view, "load_budget_state", %{"id" => "trace-sre-2", "run_id" => run_id})
    render_click(view, "load_incident_evidence", %{"id" => "trace-sre-2", "run_id" => run_id})
    render_async(view)

    html = render(view)

    assert html =~ ~r/id="traces-trace-sre-2".*Budget warn.*Load Incident Evidence/s
    assert html =~ ~r/id="traces-trace-sre-2".*breaker open.*Load Incident Evidence/s
    assert html =~ ~r/id="traces-trace-sre-2".*review incident.*Load Incident Evidence/s
    assert html =~ ~r/id="traces-trace-sre-2".*page incident.*Load Incident Evidence/s
    assert html =~ "Load Retrieval Evidence"
    assert html =~ "budget_guard"
  end

  defp seed_budget_and_breaker!(trace_id, run_id) do
    {:ok, policy} =
      %BudgetPolicy{}
      |> BudgetPolicy.changeset(%{
        tenant_id: "tenant-sre",
        policy_key: "tenant:default:cost_usd",
        scope_key: "tenant:tenant-sre",
        scope_kind: "tenant",
        resource_kind: "cost_usd",
        status: "active",
        warn_threshold: D.new("80.0"),
        trip_threshold: D.new("100.0"),
        max_workflow_steps: 25,
        max_repeated_tool_calls: 3,
        max_consecutive_failures: 2,
        metadata: %{"source" => "sre-live-test"}
      })
      |> Repo.insert()

    {:ok, _reservation} =
      %BudgetReservation{}
      |> BudgetReservation.changeset(%{
        tenant_id: "tenant-sre",
        policy_id: policy.id,
        policy_key: policy.policy_key,
        scope_key: policy.scope_key,
        status: "reserved",
        reconciliation_status: "pending",
        resource_kind: "cost_usd",
        estimated_units: D.new("92.4"),
        actual_units: D.new("92.4"),
        reason_code: "budget_warn",
        provider_ref: "openai:gpt-5",
        tool_ref: "mcp.search",
        workflow_run_id: run_id,
        trace_id: trace_id,
        policy_snapshot: %{"warn_threshold" => "80.0", "trip_threshold" => "100.0"},
        metadata: %{"reservation_actuals" => "92.4 / 100.0"}
      })
      |> Repo.insert()

    {:ok, _breaker_trip} =
      %BreakerTrip{}
      |> BreakerTrip.changeset(%{
        tenant_id: "tenant-sre",
        breaker_key: "remote_mcp:https://mcp.example.test",
        integration_kind: "remote_mcp",
        reason_code: "breaker_open",
        transition: "closed_to_open",
        state: "open",
        workflow_run_id: run_id,
        trace_id: trace_id,
        evidence_refs: %{"trace_id" => trace_id, "workflow_run_id" => run_id},
        metadata: %{"relay_status" => "degraded"}
      })
      |> Repo.insert()
  end

  defp seed_incident_evidence!(trace_id, run_id) do
    seed_budget_and_breaker!(trace_id, run_id)

    {:ok, review_incident} =
      %Incident{}
      |> Incident.changeset(%{
        tenant_id: "tenant-sre",
        incident_key:
          "tenant-sre:workflow:tenant:default:quality:ci_baseline_dip:ci:2026-05-11T18",
        severity: "warning",
        status: "open",
        summary: "CI baseline dip on helpfulness",
        routing_class: "review",
        dedupe_key: "tenant-sre:review:ci_baseline_dip",
        first_seen_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
        last_seen_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
        workflow_run_id: run_id,
        trace_id: trace_id,
        evidence_summary: %{
          "policy_key" => "tenant:default:quality",
          "trace_id" => trace_id,
          "workflow_run_id" => run_id,
          "scorer_version" => "scorer-v4",
          "baseline_version" => "baseline-2026-05-11"
        },
        metadata: %{"reason_code" => "ci_baseline_dip"}
      })
      |> Repo.insert()

    {:ok, page_incident} =
      %Incident{}
      |> Incident.changeset(%{
        tenant_id: "tenant-sre",
        incident_key:
          "tenant-sre:workflow:tenant:default:cost_usd:budget_fast_burn:2026-05-11T18",
        severity: "critical",
        status: "open",
        summary: "Fast burn budget incident",
        routing_class: "page",
        dedupe_key: "tenant-sre:page:budget_fast_burn",
        first_seen_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
        last_seen_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
        workflow_run_id: run_id,
        trace_id: trace_id,
        evidence_summary: %{
          "policy_key" => "tenant:default:cost_usd",
          "trace_id" => trace_id,
          "workflow_run_id" => run_id
        },
        metadata: %{"reason_code" => "budget_fast_burn"}
      })
      |> Repo.insert()

    {:ok, review_alert} =
      %AlertEvent{}
      |> AlertEvent.changeset(%{
        tenant_id: "tenant-sre",
        incident_id: review_incident.id,
        incident_key: review_incident.incident_key,
        reason_code: "ci_baseline_dip",
        severity: "warning",
        status: "new",
        measured_value: D.new("0.61"),
        threshold_value: D.new("0.75"),
        scorer_version_ref: "scorer-v4",
        baseline_version_ref: "baseline-2026-05-11",
        workflow_run_id: run_id,
        trace_id: trace_id,
        evidence_refs: %{"approval_id" => "approval-123"},
        metadata: %{"note" => "Review before routing changes"}
      })
      |> Repo.insert()

    {:ok, page_alert} =
      %AlertEvent{}
      |> AlertEvent.changeset(%{
        tenant_id: "tenant-sre",
        incident_id: page_incident.id,
        incident_key: page_incident.incident_key,
        reason_code: "budget_fast_burn",
        severity: "critical",
        status: "deduped",
        measured_value: D.new("103.0"),
        threshold_value: D.new("100.0"),
        workflow_run_id: run_id,
        trace_id: trace_id,
        evidence_refs: %{"approval_id" => "approval-123"},
        metadata: %{"note" => "Paged on fast burn"}
      })
      |> Repo.insert()

    {:ok, _incident_event} =
      %IncidentEvent{}
      |> IncidentEvent.changeset(%{
        tenant_id: "tenant-sre",
        incident_id: review_incident.id,
        alert_event_id: review_alert.id,
        incident_key: review_incident.incident_key,
        event_type: "alert_linked",
        reason_code: "ci_baseline_dip",
        actor_ref: "operator:sre",
        workflow_run_id: run_id,
        trace_id: trace_id,
        evidence_refs: %{
          "trace_id" => trace_id,
          "workflow_run_id" => run_id,
          "approval_id" => "approval-123"
        },
        metadata: %{"scorer_version" => "scorer-v4", "baseline_version" => "baseline-2026-05-11"}
      })
      |> Repo.insert()

    {:ok, _page_incident_event} =
      %IncidentEvent{}
      |> IncidentEvent.changeset(%{
        tenant_id: "tenant-sre",
        incident_id: page_incident.id,
        alert_event_id: page_alert.id,
        incident_key: page_incident.incident_key,
        event_type: "alert_linked",
        reason_code: "budget_fast_burn",
        actor_ref: "operator:sre",
        workflow_run_id: run_id,
        trace_id: trace_id,
        evidence_refs: %{
          "trace_id" => trace_id,
          "workflow_run_id" => run_id,
          "approval_id" => "approval-123"
        },
        metadata: %{"delivery_status" => "pending"}
      })
      |> Repo.insert()

    {:ok, _delivery} =
      %NotificationDelivery{}
      |> NotificationDelivery.changeset(%{
        tenant_id: "tenant-sre",
        incident_id: page_incident.id,
        alert_event_id: page_alert.id,
        sink_kind: "mailglass",
        routing_key: "sre@scoria.test",
        delivery_status: "failed",
        pending_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
        last_attempt_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
        attempt_count: 2,
        payload_hash: "sha256:delivery-123",
        last_error: "smtp timeout",
        workflow_run_id: run_id,
        trace_id: trace_id,
        metadata: %{"incident_key" => page_incident.incident_key}
      })
      |> Repo.insert()

    {:ok, _audit_event} =
      %AuditOutboxEvent{}
      |> AuditOutboxEvent.changeset(%{
        tenant_id: "tenant-sre",
        event_type: "approval.requested",
        policy_class: "policy_sensitive",
        sink_status: "pending",
        dedupe_key: "tenant-sre:approval-123",
        payload_hash: "sha256:audit-123",
        pending_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
        attempt_count: 1,
        actor_ref: "operator:sre",
        workflow_run_id: run_id,
        trace_id: trace_id,
        redacted_refs: %{"approval_id" => "approval-123"},
        metadata: %{"incident_key" => page_incident.incident_key}
      })
      |> Repo.insert()
  end

end
