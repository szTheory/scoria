defmodule ScoriaWeb.OperatorSurface do
  @moduledoc """
  Read model shared by the operator dashboard pages (Live Ops, Approvals,
  Connectors, Incidents).

  Extracted from `ScoriaWeb.OrchestratorLive` so the slimmed Live Ops page and
  the routed `/connectors` / `/incidents` pages query the same projections
  instead of duplicating the fleet and SRE read logic. Functions are pure reads:
  they take a tenant/trace/run scope and return plain maps ready for rendering.
  """
  import Ecto.Query, warn: false

  alias Decimal, as: D
  alias Scoria.Connectors
  alias Scoria.Connectors.Connector
  alias Scoria.Eval
  alias Scoria.Eval.OnlineScoreCandidate
  alias Scoria.Repo
  alias Scoria.Runtime
  alias Scoria.SRE
  alias Scoria.Workflows
  alias Scoria.Workflows.Run

  alias Scoria.SRE.{
    AlertEvent,
    AuditOutboxEvent,
    BreakerTrip,
    BudgetReservation,
    Incident,
    IncidentEvent,
    NotificationDelivery
  }

  # ── Fleet (runtimes + connectors) ──────────────────────────────────────────

  @doc "Runtime posture rows for a tenant, annotated with live presence status."
  def load_runtimes(tenant_id) do
    presence_topic = "mcp:runtimes:#{tenant_id}"
    presence_ids = ScoriaWeb.Presence.list(presence_topic) |> Map.keys()

    instances =
      Runtime.Instance
      |> where(tenant_id: ^tenant_id)
      |> order_by(desc: :last_seen_at)
      |> limit(10)
      |> Repo.all()

    Enum.map(instances, fn inst ->
      status = if inst.id in presence_ids, do: "online", else: "offline"

      %{
        id: inst.id,
        status: status,
        host_session_id: inst.host_session_id,
        transport_kind: inst.transport_kind,
        terminal_offline_reason: inst.terminal_offline_reason,
        current_run_id: inst.current_run_id,
        last_seen_at: inst.last_seen_at,
        semantic: runtime_drawer_semantic(inst.current_run_id)
      }
    end)
  end

  def runtime_drawer_semantic(nil), do: nil

  def runtime_drawer_semantic(run_id) do
    detail = Runtime.get_run_detail!(run_id)
    summary = detail.semantic_evidence[:summary] || %{}
    provenance = detail.semantic_evidence[:provenance] || %{}

    if map_size(summary) == 0 do
      nil
    else
      %{
        lookup_status: summary[:lookup_status],
        fallback_outcome: summary[:fallback_outcome],
        lane_key: summary[:lane_key],
        scope_kind: summary[:scope_kind],
        scope_reason: summary[:scope_reason],
        reason_code: summary[:lookup_reason_code] || summary[:eligibility_reason_code],
        actor_id: provenance[:actor_id],
        workflow_href: "/workflows/#{run_id}",
        origin_run_href: provenance[:origin_run_href]
      }
    end
  rescue
    _error -> nil
  end

  def connector_fleet(tenant_id) do
    if function_exported?(Connectors, :list_connector_fleet, 1) do
      Connectors.list_connector_fleet(%{tenant_id: tenant_id})
    else
      []
    end
  end

  def connector_drawer(connector_id) do
    if function_exported?(Connectors, :get_connector_drawer, 1) do
      Connectors.get_connector_drawer(connector_id)
    else
      nil
    end
  end

  # ── Summary counts (Live Ops at-a-glance strips) ───────────────────────────

  def pending_approval_count(tenant_id) do
    Workflows.list_pending_remote_approvals(%{tenant_id: tenant_id}) |> length()
  rescue
    _error -> 0
  end

  def status_home_summary(tenant_id) do
    connectors = connector_health_summary(tenant_id)
    incidents = incidents_summary(tenant_id)

    %{
      approvals: %{pending: pending_approval_count(tenant_id)},
      incidents: incidents,
      connectors: connectors,
      reviews: %{pending: pending_review_count(tenant_id)}
    }
  rescue
    _error -> empty_status_home_summary()
  end

  def empty_status_home_summary do
    %{
      approvals: %{pending: 0},
      incidents: %{open: 0, review: 0, page: 0},
      connectors: %{total: 0, degraded: 0},
      reviews: %{pending: 0}
    }
  end

  defp connector_health_summary(tenant_id) do
    base_query = where(Connector, [connector], connector.tenant_id == ^tenant_id)

    degraded_query =
      where(
        base_query,
        [connector],
        connector.health_state not in ["healthy", "ok", "unknown"] or
          connector.status in ["degraded", "error"]
      )

    %{
      total: Repo.aggregate(base_query, :count),
      degraded: Repo.aggregate(degraded_query, :count)
    }
  rescue
    _error -> %{total: 0, degraded: 0}
  end

  def fleet_summary(tenant_id) do
    runtimes = load_runtimes(tenant_id)
    connectors = connector_fleet(tenant_id)

    %{
      runtimes_total: length(runtimes),
      runtimes_online: Enum.count(runtimes, &(&1.status == "online")),
      connectors_total: length(connectors),
      connectors_degraded:
        Enum.count(connectors, &(Map.get(&1, :health_state) not in ["healthy", "ok", nil]))
    }
  rescue
    _error ->
      %{runtimes_total: 0, runtimes_online: 0, connectors_total: 0, connectors_degraded: 0}
  end

  def incidents_summary(tenant_id) do
    incidents = list_tenant_incidents(tenant_id)

    %{
      open: Enum.count(incidents, &(&1.status == "open")),
      review: Enum.count(incidents, &(&1.routing_class == "review" and &1.status == "open")),
      page: Enum.count(incidents, &(&1.routing_class == "page" and &1.status == "open"))
    }
  rescue
    _error -> %{open: 0, review: 0, page: 0}
  end

  defp pending_review_count(tenant_id) do
    OnlineScoreCandidate
    |> where([candidate], candidate.tenant_id == ^tenant_id)
    |> where([candidate], candidate.review_status == "pending")
    |> Repo.aggregate(:count)
  rescue
    _error -> 0
  end

  # ── Workflows (tenant rollup + routed detail) ──────────────────────────────

  @doc "Recent workflow runs for a tenant, newest first — the /workflows list."
  def list_tenant_runs(tenant_id) when is_binary(tenant_id) and tenant_id != "" do
    Run
    |> where([run], run.tenant_id == ^tenant_id)
    |> order_by([run], desc: run.inserted_at)
    |> limit(50)
    |> Repo.all()
  rescue
    _error -> []
  end

  def list_tenant_runs(_tenant_id), do: []

  @doc "Tenant-scoped workflow detail lookup for routed workflow pages."
  def fetch_tenant_run_detail(tenant_id, run_id)
      when is_binary(tenant_id) and tenant_id != "" and is_binary(run_id) do
    with {:ok, id} <- Ecto.UUID.cast(run_id),
         %Run{} <- fetch_visible_run(tenant_id, id) do
      %{
        run: Workflows.get_run_tree!(id),
        detail: Runtime.get_run_detail!(id),
        linked_incident: find_tenant_incident_for_run(tenant_id, id),
        remote_invocation_evidence: SRE.remote_invocation_evidence(id)
      }
    else
      _ -> nil
    end
  rescue
    _error -> nil
  end

  def fetch_tenant_run_detail(_tenant_id, _run_id), do: nil

  @doc "Tenant-scoped review candidate projection for workflow detail deep links."
  def fetch_tenant_review_candidate(tenant_id, %{id: run_id}, candidate_id)
      when is_binary(tenant_id) and tenant_id != "" and is_binary(run_id) and
             is_binary(candidate_id) do
    with {:ok, id} <- Ecto.UUID.cast(candidate_id),
         true <- tenant_review_candidate?(tenant_id, run_id, id) do
      Eval.get_review_candidate(id)
    else
      _ -> nil
    end
  rescue
    _error -> nil
  end

  def fetch_tenant_review_candidate(_tenant_id, _run, _candidate_id), do: nil

  defp fetch_visible_run(tenant_id, run_id) do
    Run
    |> where([run], run.tenant_id == ^tenant_id and run.id == ^run_id)
    |> Repo.one()
  end

  defp tenant_review_candidate?(tenant_id, run_id, candidate_id) do
    Repo.exists?(
      from(candidate in OnlineScoreCandidate,
        where:
          candidate.id == ^candidate_id and candidate.tenant_id == ^tenant_id and
            candidate.workflow_run_id == ^run_id
      )
    )
  end

  # ── Incidents (tenant rollup) ──────────────────────────────────────────────

  @doc "All incidents for a tenant, newest first — the /incidents triage list."
  def list_tenant_incidents(tenant_id) do
    Incident
    |> where(tenant_id: ^tenant_id)
    |> order_by([incident], desc: incident.last_seen_at)
    |> limit(50)
    |> Repo.all()
  rescue
    _error -> []
  end

  @doc "Tenant-scoped incident lookup for routed incident detail pages."
  def fetch_tenant_incident(tenant_id, incident_id) when is_binary(incident_id) do
    case Ecto.UUID.cast(incident_id) do
      {:ok, id} ->
        Incident
        |> where([incident], incident.tenant_id == ^tenant_id and incident.id == ^id)
        |> Repo.one()

      :error ->
        nil
    end
  rescue
    _error -> nil
  end

  def fetch_tenant_incident(_tenant_id, _incident_id), do: nil

  @doc "Newest tenant incident linked to a workflow run, used for legacy ?from=run links."
  def find_tenant_incident_for_run(tenant_id, run_id) when is_binary(run_id) do
    case Ecto.UUID.cast(run_id) do
      {:ok, id} ->
        Incident
        |> where([incident], incident.tenant_id == ^tenant_id and incident.workflow_run_id == ^id)
        |> order_by([incident], desc: incident.last_seen_at)
        |> limit(1)
        |> Repo.one()

      :error ->
        nil
    end
  rescue
    _error -> nil
  end

  def find_tenant_incident_for_run(_tenant_id, _run_id), do: nil

  # ── Per-trace incident/budget projections ──────────────────────────────────

  def load_budget_projection(trace_id, run_id) do
    incidents = list_incidents(trace_id, run_id)
    budget = latest_budget(trace_id, run_id)
    breaker = latest_breaker(trace_id, run_id)

    %{
      trace_id: trace_id,
      run_id: run_id,
      status_label: budget_status_label(budget),
      actuals: budget_actuals(budget),
      breaker_open?: breaker && breaker.state == "open",
      review_open?: Enum.any?(incidents, &(&1.routing_class == "review")),
      page_open?: Enum.any?(incidents, &(&1.routing_class == "page"))
    }
  rescue
    _error ->
      %{
        trace_id: trace_id,
        run_id: run_id,
        status_label: "budget state unavailable",
        actuals: "No reservation evidence available yet.",
        breaker_open?: false,
        review_open?: false,
        page_open?: false
      }
  end

  def load_incident_projection(trace_id, run_id) do
    incidents = list_incidents(trace_id, run_id)
    alert_events = list_alert_events(incidents)
    incident_events = list_incident_events(incidents)
    deliveries = list_deliveries(trace_id, run_id)
    audit_rows = list_audit_rows(trace_id, run_id)
    budget = latest_budget(trace_id, run_id)
    breaker = latest_breaker(trace_id, run_id)

    %{
      trace_id: trace_id,
      run_id: run_id,
      health_rollup: %{
        budget_signal: budget_signal(budget),
        budget_detail: budget_actuals(budget),
        breaker_signal: breaker_signal(breaker),
        breaker_detail: breaker_detail(breaker),
        review_count:
          Enum.count(incidents, &(&1.routing_class == "review" and &1.status == "open")),
        page_count: Enum.count(incidents, &(&1.routing_class == "page" and &1.status == "open")),
        relay_signal: relay_signal(audit_rows, deliveries),
        relay_detail: relay_detail(audit_rows, deliveries)
      },
      budget: %{
        status: budget_status(budget),
        status_label: budget_signal(budget),
        actuals: budget_actuals(budget),
        reason_code: if(budget, do: budget.reason_code, else: "budget evidence unavailable"),
        policy_key: if(budget, do: budget.policy_key, else: "n/a"),
        provider_ref:
          if(budget && budget.provider_ref, do: budget.provider_ref, else: "provider n/a"),
        tool_ref: if(budget && budget.tool_ref, do: budget.tool_ref, else: "tool n/a")
      },
      breaker: %{
        breaker_key: if(breaker, do: breaker.breaker_key, else: "breaker evidence unavailable"),
        state: if(breaker, do: breaker.state, else: "closed"),
        state_label: if(breaker, do: breaker.state, else: "closed"),
        reason_code: if(breaker, do: breaker.reason_code, else: "no breaker trip recorded"),
        integration_kind: if(breaker, do: breaker.integration_kind, else: "local")
      },
      incidents: build_incident_rows(incidents, alert_events, incident_events),
      audit_rows: build_audit_rows(audit_rows),
      deliveries: build_delivery_rows(deliveries)
    }
  rescue
    _error ->
      empty_incident_projection(trace_id, run_id)
  end

  def empty_incident_projection(trace_id, run_id) do
    %{
      trace_id: trace_id,
      run_id: run_id,
      health_rollup: %{
        budget_signal: "No budget evidence",
        budget_detail: "Reservation actuals will appear after a run records them.",
        breaker_signal: "Breaker clear",
        breaker_detail: "No breaker trips recorded for this trace.",
        review_count: 0,
        page_count: 0,
        relay_signal: "Relay quiet",
        relay_detail: "No audit or delivery rows recorded for this trace yet."
      },
      budget: %{
        status: "ok",
        status_label: "No budget evidence",
        actuals: "Reservation actuals unavailable.",
        reason_code: "budget evidence unavailable",
        policy_key: "n/a",
        provider_ref: "provider n/a",
        tool_ref: "tool n/a"
      },
      breaker: %{
        breaker_key: "breaker evidence unavailable",
        state: "closed",
        state_label: "closed",
        reason_code: "no breaker trip recorded",
        integration_kind: "local"
      },
      incidents: [],
      audit_rows: [],
      deliveries: []
    }
  end

  @doc "Compact badge assigns merged onto a trace row when evidence is loaded."
  def compact_trace_badges(trace_id, run_id) do
    incidents = list_incidents(trace_id, run_id)
    budget = latest_budget(trace_id, run_id)
    breaker = latest_breaker(trace_id, run_id)

    %{
      budget_state: budget_signal(budget),
      breaker_state: breaker && breaker.state,
      review_incident:
        Enum.any?(incidents, &(&1.routing_class == "review" and &1.status == "open")),
      page_incident: Enum.any?(incidents, &(&1.routing_class == "page" and &1.status == "open"))
    }
  end

  # ── Queries ────────────────────────────────────────────────────────────────

  def list_incidents(trace_id, run_id) do
    Incident
    |> where(^evidence_filter(trace_id, run_id))
    |> order_by([incident], asc: incident.inserted_at)
    |> Repo.all()
  end

  def list_alert_events([]), do: []

  def list_alert_events(incidents) do
    incident_ids = Enum.map(incidents, & &1.id)

    AlertEvent
    |> where([event], event.incident_id in ^incident_ids)
    |> order_by([event], asc: event.inserted_at)
    |> Repo.all()
  end

  def list_incident_events([]), do: []

  def list_incident_events(incidents) do
    incident_ids = Enum.map(incidents, & &1.id)

    IncidentEvent
    |> where([event], event.incident_id in ^incident_ids)
    |> order_by([event], asc: event.inserted_at)
    |> Repo.all()
  end

  def list_deliveries(trace_id, run_id) do
    NotificationDelivery
    |> where(^evidence_filter(trace_id, run_id))
    |> order_by([delivery], asc: delivery.inserted_at)
    |> Repo.all()
  end

  def list_audit_rows(trace_id, run_id) do
    AuditOutboxEvent
    |> where(^evidence_filter(trace_id, run_id))
    |> order_by([audit], asc: audit.inserted_at)
    |> Repo.all()
  end

  def latest_budget(trace_id, run_id) do
    BudgetReservation
    |> where(^evidence_filter(trace_id, run_id))
    |> order_by([reservation], desc: reservation.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  def latest_breaker(trace_id, run_id) do
    BreakerTrip
    |> where(^evidence_filter(trace_id, run_id))
    |> order_by([trip], desc: trip.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  defp evidence_filter(trace_id, run_id) do
    if is_binary(run_id) and run_id != "" do
      dynamic([row], row.trace_id == ^trace_id or field(row, :workflow_run_id) == ^run_id)
    else
      dynamic([row], row.trace_id == ^trace_id)
    end
  end

  # ── Row builders / formatting ──────────────────────────────────────────────

  def build_incident_rows(incidents, alert_events, incident_events) do
    Enum.map(incidents, fn incident ->
      alert_event = Enum.find(alert_events, &(&1.incident_id == incident.id))
      incident_event = Enum.find(incident_events, &(&1.incident_id == incident.id))

      approval_id =
        first_present([
          alert_event && get_in(alert_event.evidence_refs || %{}, ["approval_id"]),
          incident_event && get_in(incident_event.evidence_refs || %{}, ["approval_id"]),
          incident_event && get_in(incident_event.metadata || %{}, ["approval_id"])
        ])

      %{
        incident_key: incident.incident_key,
        summary: incident.summary,
        reason_code:
          get_in(incident.metadata || %{}, ["reason_code"]) ||
            (alert_event && alert_event.reason_code) || "incident",
        routing_class: incident.routing_class,
        routing_label: routing_label(incident.routing_class),
        severity: incident.severity,
        severity_label: severity_label(incident.severity),
        trace_id: incident.trace_id,
        run_id: incident.workflow_run_id,
        approval_id: approval_id,
        scorer_version:
          first_present([
            alert_event && alert_event.scorer_version_ref,
            get_in(incident.evidence_summary || %{}, ["scorer_version"]),
            get_in((incident_event && incident_event.metadata) || %{}, ["scorer_version"])
          ]) || "n/a",
        baseline_version:
          first_present([
            alert_event && alert_event.baseline_version_ref,
            get_in(incident.evidence_summary || %{}, ["baseline_version"]),
            get_in((incident_event && incident_event.metadata) || %{}, ["baseline_version"])
          ]) || "n/a"
      }
    end)
  end

  def build_audit_rows(audit_rows) do
    Enum.map(audit_rows, fn audit ->
      %{
        event_type: audit.event_type,
        sink_status: audit.sink_status,
        actor_ref: audit.actor_ref || "system",
        approval_id: get_in(audit.redacted_refs || %{}, ["approval_id"]) || "n/a"
      }
    end)
  end

  def build_delivery_rows(deliveries) do
    Enum.map(deliveries, fn delivery ->
      %{
        sink_kind: delivery.sink_kind,
        delivery_status: delivery.delivery_status,
        routing_key: delivery.routing_key,
        attempt_count: delivery.attempt_count,
        last_error: delivery.last_error,
        delivery_outcome: delivery_outcome(delivery),
        transport_mode: get_in(delivery.metadata || %{}, ["transport_mode"]),
        transport_sink: get_in(delivery.metadata || %{}, ["transport_sink"])
      }
    end)
  end

  def delivery_outcome(delivery) do
    get_in(delivery.metadata || %{}, ["delivery_outcome"]) ||
      if(delivery.delivery_status == "failed", do: "failed", else: "delivered")
  end

  def budget_status(nil), do: "ok"

  def budget_status(budget) do
    cond do
      budget.reason_code in ["budget_trip", "trip_threshold_exceeded"] -> "trip"
      budget.reason_code in ["budget_warn", "warn_threshold_exceeded"] -> "warn"
      true -> "ok"
    end
  end

  def budget_signal(budget) do
    case budget_status(budget) do
      "trip" -> "Budget trip"
      "warn" -> "Budget warn"
      _ -> "Budget steady"
    end
  end

  def budget_status_label(budget), do: budget_signal(budget)

  def budget_actuals(nil), do: "Reservation actuals unavailable."

  def budget_actuals(budget) do
    estimated = decimal_to_string(budget.estimated_units)
    actual = decimal_to_string(budget.actual_units)
    "#{actual} actual / #{estimated} reserved"
  end

  def breaker_signal(nil), do: "Breaker clear"
  def breaker_signal(%{state: "open"}), do: "Breaker open"
  def breaker_signal(%{state: "half_open"}), do: "Breaker probing"
  def breaker_signal(_breaker), do: "Breaker clear"

  def breaker_detail(nil), do: "No breaker trips recorded for this trace."
  def breaker_detail(breaker), do: "#{breaker.reason_code} on #{breaker.integration_kind}"

  def relay_signal(audit_rows, deliveries) do
    cond do
      Enum.any?(deliveries, &(&1.delivery_status == "failed")) -> "Relay degraded"
      Enum.any?(audit_rows, &(&1.sink_status == "pending")) -> "Relay pending"
      audit_rows != [] or deliveries != [] -> "Relay healthy"
      true -> "Relay quiet"
    end
  end

  def relay_detail(audit_rows, deliveries) do
    "#{length(audit_rows)} audit row(s), #{length(deliveries)} delivery outcome(s)"
  end

  def routing_label("page"), do: "Page incident"
  def routing_label(_value), do: "Review incident"

  def severity_label("critical"), do: "Critical severity"
  def severity_label("warning"), do: "Warning severity"
  def severity_label(_value), do: "Info severity"

  def first_present(values), do: Enum.find(values, &(&1 not in [nil, ""]))

  def decimal_to_string(nil), do: "0"
  def decimal_to_string(%D{} = value), do: D.to_string(value, :normal)
  def decimal_to_string(value), do: to_string(value)
end
