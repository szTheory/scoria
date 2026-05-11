defmodule ScoriaWeb.OrchestratorLiveSRETest.Router do
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

defmodule ScoriaWeb.OrchestratorLiveSRETest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug Plug.Session,
    store: :cookie,
    key: "_scoria_sre_key",
    signing_salt: "scoria_sre_salt"

  plug ScoriaWeb.OrchestratorLiveSRETest.Router
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
    ensure_sre_tables!()
    start_supervised!(@endpoint)
    :ok
  end

  test "incident evidence renders deep links, version evidence, and distinct review vs page severity" do
    run_id = Ecto.UUID.generate()
    seed_incident_evidence!("trace-sre-1", run_id)

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, @endpoint)

    {:ok, view, _html} = live(conn, "/scoria")

    send(view.pid, {:new_trace,
      %{
        id: "trace-sre-1",
        workflow_run_id: run_id,
        spans: [%{id: "span-sre-1", name: "score_run", depth: 0}]
      }})

    render_click(view, "load_incident_evidence", %{"id" => "trace-sre-1", "run_id" => run_id})
    render_async(view)

    html = render(view)

    assert html =~ "Composite health rollup"
    assert html =~ "scorer-v4"
    assert html =~ "baseline-2026-05-11"
    assert html =~ "approval-123"
    assert html =~ "trace-sre-1"
    assert html =~ run_id
    assert html =~ "Review incident"
    assert html =~ "Page incident"
    assert html =~ "mailglass"
    assert html =~ "approval.requested"
  end

  defp seed_incident_evidence!(trace_id, run_id) do
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

    {:ok, review_incident} =
      %Incident{}
      |> Incident.changeset(%{
        tenant_id: "tenant-sre",
        incident_key: "tenant-sre:workflow:tenant:default:quality:ci_baseline_dip:ci:2026-05-11T18",
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
        incident_key: "tenant-sre:workflow:tenant:default:cost_usd:budget_fast_burn:2026-05-11T18",
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

  defp ensure_sre_tables! do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS ai_budget_policies (
      id uuid PRIMARY KEY,
      tenant_id varchar NOT NULL,
      policy_key varchar NOT NULL,
      scope_key varchar NOT NULL,
      scope_kind varchar NOT NULL,
      resource_kind varchar NOT NULL,
      status varchar NOT NULL,
      warn_threshold numeric(18,6) NOT NULL,
      trip_threshold numeric(18,6) NOT NULL,
      max_workflow_steps integer NULL,
      max_repeated_tool_calls integer NULL,
      max_consecutive_failures integer NULL,
      lock_version integer NOT NULL DEFAULT 1,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) without time zone NOT NULL,
      updated_at timestamp(6) without time zone NOT NULL
    )
    """)

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS ai_budget_reservations (
      id uuid PRIMARY KEY,
      tenant_id varchar NOT NULL,
      policy_id uuid NULL,
      policy_key varchar NOT NULL,
      scope_key varchar NOT NULL,
      status varchar NOT NULL,
      reconciliation_status varchar NOT NULL,
      resource_kind varchar NOT NULL,
      estimated_units numeric(18,6) NOT NULL,
      actual_units numeric(18,6) NULL,
      reason_code varchar NOT NULL,
      provider_ref varchar NULL,
      tool_ref varchar NULL,
      workflow_run_id uuid NULL,
      trace_id varchar NULL,
      release_reason varchar NULL,
      policy_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) without time zone NOT NULL,
      updated_at timestamp(6) without time zone NOT NULL
    )
    """)

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS ai_breaker_trips (
      id uuid PRIMARY KEY,
      tenant_id varchar NOT NULL,
      breaker_key varchar NOT NULL,
      integration_kind varchar NOT NULL,
      reason_code varchar NOT NULL,
      transition varchar NOT NULL,
      state varchar NOT NULL,
      workflow_run_id uuid NULL,
      trace_id varchar NULL,
      evidence_refs jsonb NOT NULL DEFAULT '{}'::jsonb,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) without time zone NOT NULL,
      updated_at timestamp(6) without time zone NOT NULL
    )
    """)

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS ai_incidents (
      id uuid PRIMARY KEY,
      tenant_id varchar NOT NULL,
      incident_key varchar NOT NULL,
      severity varchar NOT NULL,
      status varchar NOT NULL DEFAULT 'open',
      summary text NOT NULL,
      routing_class varchar NOT NULL,
      dedupe_key varchar NOT NULL,
      first_seen_at timestamp(6) without time zone NOT NULL,
      last_seen_at timestamp(6) without time zone NOT NULL,
      workflow_run_id uuid NULL,
      trace_id varchar NULL,
      evidence_summary jsonb NOT NULL DEFAULT '{}'::jsonb,
      lock_version integer NOT NULL DEFAULT 1,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) without time zone NOT NULL,
      updated_at timestamp(6) without time zone NOT NULL
    )
    """)

    Repo.query!("CREATE UNIQUE INDEX IF NOT EXISTS ai_incidents_tenant_incident_key_idx ON ai_incidents (tenant_id, incident_key)")

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS ai_alert_events (
      id uuid PRIMARY KEY,
      tenant_id varchar NOT NULL,
      alert_policy_id uuid NULL,
      incident_id uuid NULL,
      incident_key varchar NOT NULL,
      reason_code varchar NOT NULL,
      severity varchar NOT NULL,
      status varchar NOT NULL DEFAULT 'new',
      measured_value numeric(18,6) NOT NULL,
      threshold_value numeric(18,6) NOT NULL,
      scorer_version_ref varchar NULL,
      baseline_version_ref varchar NULL,
      workflow_run_id uuid NULL,
      trace_id varchar NULL,
      evidence_refs jsonb NOT NULL DEFAULT '{}'::jsonb,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) without time zone NOT NULL,
      updated_at timestamp(6) without time zone NOT NULL
    )
    """)

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS ai_incident_events (
      id uuid PRIMARY KEY,
      tenant_id varchar NOT NULL,
      incident_id uuid NOT NULL,
      alert_event_id uuid NULL,
      incident_key varchar NOT NULL,
      event_type varchar NOT NULL,
      reason_code varchar NOT NULL,
      actor_ref varchar NULL,
      workflow_run_id uuid NULL,
      trace_id varchar NULL,
      evidence_refs jsonb NOT NULL DEFAULT '{}'::jsonb,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) without time zone NOT NULL,
      updated_at timestamp(6) without time zone NOT NULL
    )
    """)

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS ai_notification_deliveries (
      id uuid PRIMARY KEY,
      tenant_id varchar NOT NULL,
      incident_id uuid NULL,
      alert_event_id uuid NULL,
      sink_kind varchar NOT NULL,
      routing_key varchar NOT NULL,
      delivery_status varchar NOT NULL,
      pending_at timestamp(6) without time zone NOT NULL,
      last_attempt_at timestamp(6) without time zone NULL,
      delivered_at timestamp(6) without time zone NULL,
      attempt_count integer NOT NULL DEFAULT 0,
      payload_hash varchar NOT NULL,
      last_error text NULL,
      workflow_run_id uuid NULL,
      trace_id varchar NULL,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) without time zone NOT NULL,
      updated_at timestamp(6) without time zone NOT NULL
    )
    """)

    Repo.query!("""
    CREATE TABLE IF NOT EXISTS ai_audit_outbox_events (
      id uuid PRIMARY KEY,
      tenant_id varchar NOT NULL,
      event_type varchar NOT NULL,
      policy_class varchar NOT NULL,
      sink_status varchar NOT NULL DEFAULT 'pending',
      dedupe_key varchar NOT NULL,
      payload_hash varchar NOT NULL,
      pending_at timestamp(6) without time zone NOT NULL,
      sent_at timestamp(6) without time zone NULL,
      attempt_count integer NOT NULL DEFAULT 0,
      actor_ref varchar NULL,
      workflow_run_id uuid NULL,
      step_id uuid NULL,
      trace_id varchar NULL,
      redacted_refs jsonb NOT NULL DEFAULT '{}'::jsonb,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) without time zone NOT NULL,
      updated_at timestamp(6) without time zone NOT NULL
    )
    """)

    Repo.query!(
      "CREATE UNIQUE INDEX IF NOT EXISTS ai_audit_outbox_events_tenant_dedupe_key_idx ON ai_audit_outbox_events (tenant_id, dedupe_key)"
    )
  end
end
