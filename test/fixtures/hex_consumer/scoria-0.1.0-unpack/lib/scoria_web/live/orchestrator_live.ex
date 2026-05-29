defmodule ScoriaWeb.OrchestratorLive do
  use Phoenix.LiveView
  import Ecto.Query, warn: false

  alias Decimal, as: D
  alias Scoria.Eval
  alias Scoria.Repo
  alias Scoria.Runtime

  alias Scoria.Connectors

  alias Scoria.SRE.{
    AlertEvent,
    AuditOutboxEvent,
    BreakerTrip,
    BudgetReservation,
    Incident,
    IncidentEvent,
    NotificationDelivery
  }

  alias Scoria.Workflows
  alias Scoria.Workflows.Resume

  alias ScoriaWeb.{
    ApprovalInboxComponent,
    CitationEvidenceComponent,
    ConnectorDetailDrawerComponent,
    IncidentEvidenceComponent,
    RuntimeDetailDrawerComponent
  }

  def mount(params, session, socket) do
    tenant_id = session["tenant_id"] || "default"

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Scoria.PubSub, "scoria:runs:#{tenant_id}")
      Phoenix.PubSub.subscribe(Scoria.PubSub, "mcp:runtimes:#{tenant_id}")
    end

    socket =
      socket
      |> assign(:page_title, "Scoria Dashboard")
      |> assign(:token_buffer, [])
      |> assign(:timer_ref, nil)
      |> assign(:token_text, "")
      |> assign(:active_approval, nil)
      |> assign(:approval_inbox, [])
      |> assign(:connector_fleet, [])
      |> assign(:connector_drawer, nil)
      |> assign(:runtimes, [])
      |> assign(:runtime_drawer, nil)
      |> assign(
        :actor_id,
        session["actor_id"] || session["user_id"] || session["session_id"] || "operator"
      )
      |> assign(:budget_state, nil)
      |> assign(:incident_evidence, nil)
      |> assign(:trace_records, %{})
      |> assign(:replay_notice, nil)
      |> assign(:promote_notice, nil)
      |> assign(:runtime_query, Map.get(params, "runtime"))
      |> assign(:review_candidate, load_review_candidate(Map.get(params, "review_candidate_id")))
      |> assign(:tenant_id, tenant_id)
      |> stream(:traces, [])

    {:ok, load_operator_surface(socket)}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, load_operator_surface(socket)}
  end

  def handle_info({:new_trace, trace}, socket) do
    socket =
      socket
      |> assign(:trace_records, Map.put(socket.assigns.trace_records, trace.id, trace))
      |> stream_insert(:traces, trace)

    {:noreply, socket}
  end

  def handle_info({:token, token}, socket) do
    new_buffer = [token | socket.assigns.token_buffer]

    socket =
      if is_nil(socket.assigns.timer_ref) do
        ref = Process.send_after(self(), :flush_tokens, 75)
        assign(socket, timer_ref: ref)
      else
        socket
      end

    {:noreply, assign(socket, token_buffer: new_buffer)}
  end

  def handle_info(:flush_tokens, socket) do
    new_chunk = socket.assigns.token_buffer |> Enum.reverse() |> Enum.join("")

    socket =
      socket
      |> assign(token_text: socket.assigns.token_text <> new_chunk)
      |> assign(token_buffer: [])
      |> assign(timer_ref: nil)

    {:noreply, socket}
  end

  def handle_info({:hitl_request, approval}, socket) do
    {:noreply,
     socket
     |> assign(:active_approval, approval)
     |> load_operator_surface()}
  end

  def handle_event("approve", _, socket) do
    {:noreply, record_approval_decision(socket, "approved")}
  end

  def handle_event("reject", _, socket) do
    {:noreply, record_approval_decision(socket, "rejected")}
  end

  def handle_event("load_metadata", %{"id" => trace_id}, socket) do
    {:noreply,
     assign_async(socket, :trace_metadata, fn ->
       # Fetch deep trace metadata (simulated here)
       {:ok, %{trace_metadata: %{id: trace_id, deep_data: "loaded lazily"}}}
     end)}
  end

  def handle_event("open_connector_drawer", %{"id" => connector_id}, socket) do
    {:noreply, assign(socket, :connector_drawer, connector_drawer(connector_id))}
  end

  def handle_event("close_connector_drawer", _, socket) do
    {:noreply, assign(socket, :connector_drawer, nil)}
  end

  def handle_event("open_runtime_drawer", %{"id" => id}, socket) do
    runtime = Enum.find(socket.assigns.runtimes, &(&1.id == id))
    {:noreply, assign(socket, :runtime_drawer, runtime)}
  end

  def handle_event("close_runtime_drawer", _, socket) do
    {:noreply, assign(socket, :runtime_drawer, nil)}
  end

  def handle_event("load_retrieval_evidence", %{"id" => trace_id}, socket) do
    {:noreply,
     assign_async(socket, :retrieval_evidence, fn ->
       {:ok, %{retrieval_evidence: sample_evidence(trace_id)}}
     end)}
  end

  def handle_event("load_budget_state", params, socket) do
    trace_id = Map.get(params, "id")
    run_id = Map.get(params, "run_id")

    {:noreply,
     socket
     |> refresh_trace_badges(trace_id, run_id)
     |> assign_async(:budget_state, fn ->
       {:ok, %{budget_state: load_budget_projection(trace_id, run_id)}}
     end)}
  end

  def handle_event("load_incident_evidence", params, socket) do
    trace_id = Map.get(params, "id")
    run_id = Map.get(params, "run_id")

    {:noreply,
     socket
     |> refresh_trace_badges(trace_id, run_id)
     |> assign_async(:incident_evidence, fn ->
       {:ok, %{incident_evidence: load_incident_projection(trace_id, run_id)}}
     end)}
  end

  def handle_event("replay_retrieval", %{"id" => trace_id}, socket) do
    {:noreply, assign(socket, :replay_notice, "replay_retrieval queued for #{trace_id}")}
  end

  def handle_event("promote_retrieval", %{"id" => trace_id}, socket) do
    {:noreply, assign(socket, :promote_notice, "promote_retrieval queued for #{trace_id}")}
  end

  def render(assigns) do
    ~H"""
    <div class="scoria-dashboard bg-gray-50 min-h-screen p-8 text-gray-900 font-sans relative">
      <div class="max-w-7xl mx-auto">
        <h1 class="text-3xl font-bold mb-6">Scoria Orchestrator</h1>
        <p class="text-gray-600 mb-8">A Phoenix-native AI Application Quality Layer.</p>

        <section
          :if={@review_candidate}
          class="mb-6 rounded-2xl border border-blue-200 bg-blue-50 p-4 text-sm text-blue-950 shadow-sm"
        >
          <p class="text-xs font-semibold uppercase tracking-[0.18em] text-blue-700">Review candidate context</p>
          <p class="mt-2 font-semibold text-stone-900"><%= @review_candidate.rationale %></p>
          <p class="mt-2 text-stone-700">
            Queue-selected evidence stays visible while inspecting runtime
            <span :if={@runtime_query} class="font-mono"><%= @runtime_query %></span>.
          </p>
          <div class="mt-3 flex flex-wrap gap-2 text-xs text-stone-700">
            <span class="rounded-full border border-blue-200 bg-white px-3 py-1"><%= @review_candidate.severity %></span>
            <span class="rounded-full border border-blue-200 bg-white px-3 py-1">trace <span class="font-mono"><%= @review_candidate.trace_id %></span></span>
            <span class="rounded-full border border-blue-200 bg-white px-3 py-1">workflow <span class="font-mono"><%= @review_candidate.workflow_run_id %></span></span>
          </div>
        </section>

        <div id="token-stream" class="mb-4 whitespace-pre-wrap"><%= @token_text %></div>

        <div class="mb-6 grid gap-6 xl:grid-cols-[minmax(0,1.1fr)_minmax(18rem,0.9fr)]">
          <%= if approval_inbox_component?() do %>
            <ApprovalInboxComponent.render approvals={@approval_inbox} />
          <% else %>
            <section class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
              <p class="text-xs uppercase tracking-[0.24em] text-stone-500">approvals</p>
              <h2 class="text-lg font-semibold text-stone-900">Approval inbox</h2>
            </section>
          <% end %>

          <div class="space-y-6">
            <section class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
              <div class="flex items-center justify-between gap-4">
                <div>
                  <p class="text-xs uppercase tracking-[0.24em] text-stone-500">external runtimes</p>
                  <h2 class="text-lg font-semibold text-stone-900">Runtime posture</h2>
                </div>
              </div>

              <div class="mt-4 space-y-3">
                <article :for={runtime <- @runtimes} class="rounded-xl border border-stone-200 bg-stone-50 p-3 flex justify-between items-start">
                  <div>
                    <p class="text-sm font-semibold text-stone-900 truncate max-w-[12rem]"><%= runtime.id %></p>
                    <p class="text-xs text-stone-500 mt-1">
                      <span class={"inline-block w-2 h-2 rounded-full mr-1 #{if runtime.status == "online", do: "bg-emerald-500", else: "bg-stone-300"}"}></span>
                      <%= runtime.status %>
                    </p>
                  </div>
                  <button phx-click="open_runtime_drawer" phx-value-id={runtime.id} class="text-xs font-medium text-blue-700 underline">
                    Details
                  </button>
                </article>
              </div>
            </section>

            <section class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
              <div class="flex items-center justify-between gap-4">
                <div>
                  <p class="text-xs uppercase tracking-[0.24em] text-stone-500">connector fleet</p>
                  <h2 class="text-lg font-semibold text-stone-900">Connector posture</h2>
                </div>
              </div>

              <div class="mt-4 space-y-3">
                <article :for={connector <- @connector_fleet} class="rounded-xl border border-stone-200 bg-stone-50 p-3">
                  <div class="flex items-start justify-between gap-3">
                    <div>
                      <p class="text-sm font-semibold text-stone-900"><%= connector.connector_label %></p>
                      <p class="mt-1 text-xs text-stone-600">
                        <%= connector.health_state %> · refresh <%= connector.last_refresh_status %>
                      </p>
                    </div>
                    <button phx-click="open_connector_drawer" phx-value-id={connector.connector_id} class="text-xs font-medium text-blue-700 underline">
                      Open drawer
                    </button>
                  </div>

                  <div class="mt-3 flex flex-wrap gap-3 text-xs text-stone-600">
                    <span>approvals <%= connector.pending_approval_count %></span>
                    <span>pending tools <%= connector.pending_local_tool_count %></span>
                    <span>auth <%= connector.auth_provenance.status %></span>
                  </div>
                </article>
              </div>
            </section>
          </div>
        </div>

        <%= if runtime_drawer_component?() do %>
          <RuntimeDetailDrawerComponent.render drawer={@runtime_drawer} />
        <% end %>
        <%= if connector_drawer_component?() do %>
          <ConnectorDetailDrawerComponent.render drawer={@connector_drawer} />
        <% end %>

        <div id="traces-list" phx-update="stream" class="space-y-4">
          <div :for={{id, trace} <- @streams.traces} id={id} class="bg-white p-4 rounded shadow">
            <.live_component module={ScoriaWeb.TraceTreeComponent} id={"tree-#{id}"} spans={trace.spans} />
            <div class="mt-3 flex flex-wrap gap-2 text-[11px]">
              <span :for={badge <- trace_badges(trace)} class={trace_badge_class(badge.tone)}>
                <%= badge.label %>
              </span>
            </div>
            <div class="mt-3 flex flex-wrap gap-3 text-xs">
              <button phx-click="load_metadata" phx-value-id={trace.id} class="text-blue-500 underline">Load Deep Metadata</button>
              <button phx-click="load_retrieval_evidence" phx-value-id={trace.id} class="text-emerald-700 underline">Load Retrieval Evidence</button>
              <button phx-click="load_budget_state" phx-value-id={trace.id} phx-value-run_id={trace[:workflow_run_id]} class="text-amber-700 underline">Load Budget State</button>
              <button phx-click="load_incident_evidence" phx-value-id={trace.id} phx-value-run_id={trace[:workflow_run_id]} class="text-rose-700 underline">Load Incident Evidence</button>
              <button phx-click="replay_retrieval" phx-value-id={trace.id} class="text-stone-700 underline">Replay Retrieval</button>
              <button phx-click="promote_retrieval" phx-value-id={trace.id} class="text-stone-700 underline">Promote Retrieval</button>
            </div>
          </div>
        </div>

        <%= if assigns[:trace_metadata] do %>
          <div class="mt-4 p-4 bg-gray-100 rounded text-sm">
            <.async_result :let={metadata} assign={@trace_metadata}>
              <:loading>Loading metadata...</:loading>
              <:failed :let={_failure}>Failed to load metadata</:failed>
              <pre><%= inspect(metadata) %></pre>
            </.async_result>
          </div>
        <% end %>

        <%= if assigns[:retrieval_evidence] do %>
          <div id="retrieval-evidence" class="mt-6">
            <.async_result :let={evidence} assign={@retrieval_evidence}>
              <:loading>Loading retrieval evidence...</:loading>
              <:failed :let={_failure}>Failed to load retrieval evidence</:failed>
              <CitationEvidenceComponent.render evidence={evidence} />
            </.async_result>
          </div>
        <% end %>

        <%= if assigns[:budget_state] do %>
          <div id="budget-state" class="mt-6">
            <.async_result :let={budget_state} assign={@budget_state}>
              <:loading>Loading budget state...</:loading>
              <:failed :let={_failure}>Failed to load budget state</:failed>
              <div class="rounded-xl border border-stone-200 bg-white p-4 shadow-sm">
                <p class="text-xs uppercase tracking-[0.24em] text-stone-500">Budget state</p>
                <div class="mt-3 flex flex-wrap gap-2 text-xs">
                  <span class={trace_badge_class("amber")}><%= budget_state.status_label %></span>
                  <span class={trace_badge_class("rose")} :if={budget_state.breaker_open?}>breaker open</span>
                  <span class={trace_badge_class("sky")} :if={budget_state.review_open?}>review incident</span>
                  <span class={trace_badge_class("rose")} :if={budget_state.page_open?}>page incident</span>
                </div>
                <p class="mt-3 text-sm text-stone-700"><%= budget_state.actuals %></p>
              </div>
            </.async_result>
          </div>
        <% end %>

        <%= if assigns[:incident_evidence] do %>
          <div id="incident-evidence" class="mt-6">
            <.async_result :let={evidence} assign={@incident_evidence}>
              <:loading>Loading incident evidence...</:loading>
              <:failed :let={_failure}>Failed to load incident evidence</:failed>
              <IncidentEvidenceComponent.render evidence={evidence} />
            </.async_result>
          </div>
        <% end %>

        <%= if @replay_notice do %>
          <div class="mt-4 rounded border border-emerald-200 bg-emerald-50 p-3 text-sm text-emerald-900">
            <%= @replay_notice %>
          </div>
        <% end %>

        <%= if @promote_notice do %>
          <div class="mt-4 rounded border border-blue-200 bg-blue-50 p-3 text-sm text-blue-900">
            <%= @promote_notice %>
          </div>
        <% end %>
      </div>

      <%= if @active_approval do %>
        <div id="approval-modal" class="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50">
          <div class="bg-white p-6 rounded shadow-lg max-w-md w-full">
            <h2 class="text-xl font-bold mb-4">Approval Required</h2>
            <p class="mb-2"><strong>Tool:</strong> <%= @active_approval.tool_name %></p>
            <p class="text-sm text-stone-600">
              Record a workflow-owned decision. The approval state and audit evidence are written durably before any resume attempt.
            </p>
            <div class="flex justify-end space-x-4 mt-6">
              <button phx-click="reject" class="px-4 py-2 bg-red-500 text-white rounded">Reject Decision</button>
              <button phx-click="approve" class="px-4 py-2 bg-blue-500 text-white rounded">Approve Decision</button>
            </div>
            <p class="mt-4 text-xs text-stone-500">
              Reject Decision keeps the workflow paused until a new operator action is recorded.
            </p>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp sample_evidence(trace_id) do
    %{
      id: trace_id,
      query_text: "citation-backed retrieval for trace #{trace_id}",
      freshness: "freshness: current corpus snapshot",
      citations: [
        %{label: "[1]", title: "Trace-first design", locator: "file:///docs/trace-first.md"},
        %{label: "[2]", title: "Grounding rules", locator: "file:///docs/grounding.md"}
      ],
      ranked_chunks: [
        %{
          rank: 1,
          score: "0.98",
          body: "citation evidence is shown side-by-side for operator review."
        },
        %{rank: 2, score: "0.91", body: "unsupported claims are surfaced before promotion."}
      ],
      unsupported_claims: ["none"],
      grounding_scores: [%{kind: "deterministic", score: "1.0"}]
    }
  end

  defp load_budget_projection(trace_id, run_id) do
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

  defp load_incident_projection(trace_id, run_id) do
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

  defp empty_incident_projection(trace_id, run_id) do
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

  defp list_incidents(trace_id, run_id) do
    Incident
    |> where(^evidence_filter(trace_id, run_id))
    |> order_by([incident], asc: incident.inserted_at)
    |> Repo.all()
  end

  defp list_alert_events([]), do: []

  defp list_alert_events(incidents) do
    incident_ids = Enum.map(incidents, & &1.id)

    AlertEvent
    |> where([event], event.incident_id in ^incident_ids)
    |> order_by([event], asc: event.inserted_at)
    |> Repo.all()
  end

  defp list_incident_events([]), do: []

  defp list_incident_events(incidents) do
    incident_ids = Enum.map(incidents, & &1.id)

    IncidentEvent
    |> where([event], event.incident_id in ^incident_ids)
    |> order_by([event], asc: event.inserted_at)
    |> Repo.all()
  end

  defp list_deliveries(trace_id, run_id) do
    NotificationDelivery
    |> where(^evidence_filter(trace_id, run_id))
    |> order_by([delivery], asc: delivery.inserted_at)
    |> Repo.all()
  end

  defp list_audit_rows(trace_id, run_id) do
    AuditOutboxEvent
    |> where(^evidence_filter(trace_id, run_id))
    |> order_by([audit], asc: audit.inserted_at)
    |> Repo.all()
  end

  defp latest_budget(trace_id, run_id) do
    BudgetReservation
    |> where(^evidence_filter(trace_id, run_id))
    |> order_by([reservation], desc: reservation.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  defp latest_breaker(trace_id, run_id) do
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

  defp build_incident_rows(incidents, alert_events, incident_events) do
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

  defp build_audit_rows(audit_rows) do
    Enum.map(audit_rows, fn audit ->
      %{
        event_type: audit.event_type,
        sink_status: audit.sink_status,
        actor_ref: audit.actor_ref || "system",
        approval_id: get_in(audit.redacted_refs || %{}, ["approval_id"]) || "n/a"
      }
    end)
  end

  defp build_delivery_rows(deliveries) do
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

  defp delivery_outcome(delivery) do
    get_in(delivery.metadata || %{}, ["delivery_outcome"]) ||
      if(delivery.delivery_status == "failed", do: "failed", else: "delivered")
  end

  defp budget_status(nil), do: "ok"

  defp budget_status(budget) do
    cond do
      budget.reason_code in ["budget_trip", "trip_threshold_exceeded"] -> "trip"
      budget.reason_code in ["budget_warn", "warn_threshold_exceeded"] -> "warn"
      true -> "ok"
    end
  end

  defp budget_signal(budget) do
    case budget_status(budget) do
      "trip" -> "Budget trip"
      "warn" -> "Budget warn"
      _ -> "Budget steady"
    end
  end

  defp budget_status_label(budget), do: budget_signal(budget)

  defp budget_actuals(nil), do: "Reservation actuals unavailable."

  defp budget_actuals(budget) do
    estimated = decimal_to_string(budget.estimated_units)
    actual = decimal_to_string(budget.actual_units)
    "#{actual} actual / #{estimated} reserved"
  end

  defp breaker_signal(nil), do: "Breaker clear"
  defp breaker_signal(%{state: "open"}), do: "Breaker open"
  defp breaker_signal(%{state: "half_open"}), do: "Breaker probing"
  defp breaker_signal(_breaker), do: "Breaker clear"

  defp breaker_detail(nil), do: "No breaker trips recorded for this trace."
  defp breaker_detail(breaker), do: "#{breaker.reason_code} on #{breaker.integration_kind}"

  defp relay_signal(audit_rows, deliveries) do
    cond do
      Enum.any?(deliveries, &(&1.delivery_status == "failed")) -> "Relay degraded"
      Enum.any?(audit_rows, &(&1.sink_status == "pending")) -> "Relay pending"
      audit_rows != [] or deliveries != [] -> "Relay healthy"
      true -> "Relay quiet"
    end
  end

  defp relay_detail(audit_rows, deliveries) do
    "#{length(audit_rows)} audit row(s), #{length(deliveries)} delivery outcome(s)"
  end

  defp trace_badges(trace) do
    Enum.concat([
      if(trace[:budget_state], do: [%{label: trace[:budget_state], tone: "amber"}], else: []),
      if(trace[:breaker_state] == "open", do: [%{label: "breaker open", tone: "rose"}], else: []),
      if(trace[:review_incident], do: [%{label: "review incident", tone: "sky"}], else: []),
      if(trace[:page_incident], do: [%{label: "page incident", tone: "rose"}], else: [])
    ])
  end

  defp trace_badge_class(tone) do
    base = "rounded-full px-2.5 py-1 font-semibold uppercase tracking-[0.18em]"

    color =
      case tone do
        "rose" -> "border border-rose-200 bg-rose-50 text-rose-800"
        "sky" -> "border border-sky-200 bg-sky-50 text-sky-800"
        "amber" -> "border border-amber-200 bg-amber-50 text-amber-800"
        _ -> "border border-emerald-200 bg-emerald-50 text-emerald-800"
      end

    [base, color]
  end

  defp routing_label("page"), do: "Page incident"
  defp routing_label(_value), do: "Review incident"

  defp severity_label("critical"), do: "Critical severity"
  defp severity_label("warning"), do: "Warning severity"
  defp severity_label(_value), do: "Info severity"

  defp first_present(values), do: Enum.find(values, &(&1 not in [nil, ""]))

  defp decimal_to_string(nil), do: "0"
  defp decimal_to_string(%D{} = value), do: D.to_string(value, :normal)
  defp decimal_to_string(value), do: to_string(value)

  defp refresh_trace_badges(socket, trace_id, run_id) do
    case Map.get(socket.assigns.trace_records, trace_id) do
      nil ->
        socket

      trace ->
        badge_assigns = compact_trace_badges(trace_id, run_id)
        updated_trace = Map.merge(trace, badge_assigns)

        socket
        |> assign(:trace_records, Map.put(socket.assigns.trace_records, trace_id, updated_trace))
        |> stream_insert(:traces, updated_trace)
    end
  rescue
    _error ->
      socket
  end

  defp compact_trace_badges(trace_id, run_id) do
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

  defp record_approval_decision(socket, status) do
    case socket.assigns.active_approval do
      nil ->
        socket

      approval ->
        attrs = approval_decision_attrs(socket, approval)

        with {:ok, updated_approval} <- Workflows.approve(approval.id, status, attrs),
             {:ok, updated_socket} <- maybe_resume_approval(socket, updated_approval, status) do
          updated_socket
          |> assign(:active_approval, nil)
          |> load_operator_surface()
        else
          {:error, reason} ->
            put_flash(socket, :error, approval_error_message(status, reason))
        end
    end
  end

  defp maybe_resume_approval(socket, _approval, status) when status != "approved",
    do: {:ok, socket}

  defp maybe_resume_approval(socket, approval, "approved") do
    case approval.workflow_run_id do
      nil -> {:ok, socket}
      run_id -> Resume.resume_run(run_id)
    end
    |> case do
      {:ok, _run} -> {:ok, socket}
      {:error, reason} -> {:error, reason}
    end
  end

  defp approval_decision_attrs(socket, approval) do
    request_event = approval_request_event(approval)

    %{
      actor_id: socket.assigns.actor_id || approval.session_id || "operator",
      tenant_id:
        socket.assigns.tenant_id || (request_event && request_event.tenant_id) || "default",
      trace_id: request_event && request_event.trace_id
    }
  end

  defp approval_request_event(approval) do
    AuditOutboxEvent
    |> where(
      [event],
      event.workflow_run_id == ^approval.workflow_run_id and
        event.event_type == "approval.requested"
    )
    |> where([event], fragment("?->>? = ?", event.redacted_refs, "approval_id", ^approval.id))
    |> order_by([event], desc: event.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  defp approval_error_message(status, reason) do
    "Could not #{status} approval through workflow-owned state: #{inspect(reason)}"
  end

  defp load_review_candidate(nil), do: nil
  defp load_review_candidate(candidate_id), do: Eval.get_review_candidate(candidate_id)

  defp connector_drawer(connector_id) do
    if function_exported?(Connectors, :get_connector_drawer, 1) do
      Connectors.get_connector_drawer(connector_id)
    else
      nil
    end
  end

  defp approval_inbox_component? do
    Code.ensure_loaded?(ApprovalInboxComponent) and
      function_exported?(ApprovalInboxComponent, :render, 1)
  end

  defp runtime_drawer_component? do
    Code.ensure_loaded?(RuntimeDetailDrawerComponent) and
      function_exported?(RuntimeDetailDrawerComponent, :render, 1)
  end

  defp connector_drawer_component? do
    Code.ensure_loaded?(ConnectorDetailDrawerComponent) and
      function_exported?(ConnectorDetailDrawerComponent, :render, 1)
  end

  defp load_operator_surface(socket) do
    tenant_id = socket.assigns.tenant_id

    presence_topic = "mcp:runtimes:#{tenant_id}"
    presence_ids = ScoriaWeb.Presence.list(presence_topic) |> Map.keys()

    instances =
      Scoria.Runtime.Instance
      |> where(tenant_id: ^tenant_id)
      |> order_by(desc: :last_seen_at)
      |> limit(10)
      |> Repo.all()

    runtimes =
      Enum.map(instances, fn inst ->
        status = if inst.id in presence_ids, do: "online", else: "offline"
        semantic = runtime_drawer_semantic(inst.current_run_id)

        %{
          id: inst.id,
          status: status,
          host_session_id: inst.host_session_id,
          transport_kind: inst.transport_kind,
          terminal_offline_reason: inst.terminal_offline_reason,
          current_run_id: inst.current_run_id,
          semantic: semantic
        }
      end)

    socket
    |> assign(:approval_inbox, Workflows.list_pending_remote_approvals(%{tenant_id: tenant_id}))
    |> assign(:connector_fleet, connector_fleet(tenant_id))
    |> assign(:runtimes, runtimes)
  end

  defp runtime_drawer_semantic(nil), do: nil

  defp runtime_drawer_semantic(run_id) do
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

  defp connector_fleet(tenant_id) do
    if function_exported?(Connectors, :list_connector_fleet, 1) do
      Connectors.list_connector_fleet(%{tenant_id: tenant_id})
    else
      []
    end
  end
end
