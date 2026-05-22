# Phase 21: Remote Approval Flow and Operator Evidence UX - Pattern Map

**Mapped:** 2026-05-18
**Files analyzed:** 11 likely targets
**Analogs found:** 11 / 11
**Project guidance:** No project-local `CLAUDE.md`, `.claude/skills`, or `.agents/skills` files were present in this repo.

## File Classification

| Likely File Target | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scoria/workflows.ex` | service | event-driven | `lib/scoria/workflows.ex` | exact |
| `lib/scoria/observe/approval.ex` | model | CRUD | `lib/scoria/observe/approval.ex` | exact |
| `lib/scoria/connectors.ex` | service | CRUD | `lib/scoria/connectors.ex` | exact |
| `lib/scoria_web/live/orchestrator_live.ex` | LiveView | request-response + streaming | `lib/scoria_web/live/orchestrator_live.ex` | exact |
| `lib/scoria_web/live/workflow_live/show.ex` | LiveView | request-response | `lib/scoria_web/live/workflow_live/show.ex` | exact |
| `lib/scoria_web/components/remote_invocation_evidence_component.ex` | component | transform | `lib/scoria_web/components/incident_evidence_component.ex` | role-match |
| `lib/scoria_web/components/connector_detail_drawer_component.ex` | component | transform | `lib/scoria_web/components/workflow_detail_panel_component.ex` | role-match |
| `lib/scoria/connectors/operator_dashboard.ex` | service/query | CRUD + transform | `lib/scoria/connectors.ex` | partial |
| `test/scoria/workflows_test.exs` | test | event-driven | `test/scoria/workflows_test.exs` | exact |
| `test/scoria_web/live/orchestrator_live_test.exs` | test | LiveView request-response | `test/scoria_web/live/orchestrator_live_test.exs` | exact |
| `test/scoria_web/live/orchestrator_live_sre_test.exs` | test | evidence/timeline integration | `test/scoria_web/live/orchestrator_live_sre_test.exs` | exact |

## Pattern Assignments

### `lib/scoria/workflows.ex`

**Analog:** [lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:294)

**Workflow-owned wait state first, UI second** ([lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:298)):
```elixir
Repo.transaction(fn repo ->
  run = repo.get!(Run, run_id)
  step = repo.get!(Step, step_id)

  updated_run =
    repo.update!(
      Run.changeset(run, %{status: "waiting_for_approval", current_step_id: step.id})
    )

  repo.update!(
    Step.changeset(step, %{status: "waiting_for_approval", started_at: step.started_at || now})
  )
```

**Durable checkpoint + event + approval row in one transaction** ([lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:312)):
```elixir
checkpoint =
  insert_checkpoint(repo, run.id, step.id, %{
    transition: "waiting_for_approval",
    status: "waiting_for_approval",
    snapshot: %{reason: Map.get(attrs, :reason) || Map.get(attrs, "reason")},
    metadata: %{}
  })

insert_event(repo, run.id, step.id, %{
  event_type: "waiting_for_approval",
  payload: %{reason: Map.get(attrs, :reason) || Map.get(attrs, "reason")}
})
```

**Audit event emitted after durable write, then broadcast** ([lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:352)):
```elixir
audit_outbox_event =
  SRE.insert_audit_outbox_event(repo, %{event_type: "approval.requested", ...})

{:ok, {run, approval, audit_outbox_event}} ->
  SRE.emit_audit_outbox_telemetry(audit_outbox_event)
  broadcast(run.id, {:approval_requested, run.id, approval.id})
```

**Resume pattern must stay checkpoint/event based** ([lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:512)):
```elixir
{"waiting_for_approval", _checkpoint, %Approval{status: "approved"} = approval} ->
  Repo.transaction(fn repo ->
    resumed_step = repo.update!(Step.changeset(step, %{status: "queued"}))
    checkpoint = insert_checkpoint(repo, run.id, resumed_step.id, %{transition: "resume_requested", ...})
    insert_event(repo, run.id, resumed_step.id, %{event_type: "resume_requested", payload: %{approval_id: approval.id}})
```

**Decision lineage must recover request context from durable audit rows** ([lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:573)):
```elixir
approval = repo.get!(Approval, approval_id)
audit_context = approval_decision_context(repo, approval, attrs)
updated_approval =
  approval
  |> Approval.changeset(update_attrs)
  |> repo.update!()
```

**Recommendation:** Phase 21 approval inbox, replay eligibility, and remediation read-through should extend this module or a workflow-owned query sibling. Do not create a second approval state machine in LiveView.

### `lib/scoria/observe/approval.ex`

**Analog:** [lib/scoria/observe/approval.ex](/Users/jon/projects/scoria/lib/scoria/observe/approval.ex:1)

**Schema shape** ([lib/scoria/observe/approval.ex](/Users/jon/projects/scoria/lib/scoria/observe/approval.ex:8)):
```elixir
schema "ai_approvals" do
  field(:tool_name, :string)
  field(:arguments, :map, default: %{})
  field(:status, :string, default: "pending")
  field(:actor_id, :string)
  field(:tenant_id, :string)
  field(:session_id, :string)
  field(:run_id, :string)
  field(:workflow_run_id, :binary_id)
  field(:step_id, :binary_id)
  field(:checkpoint_id, :binary_id)
  field(:lock_version, :integer, default: 1)
```

**Concurrency contract** ([lib/scoria/observe/approval.ex](/Users/jon/projects/scoria/lib/scoria/observe/approval.ex:18)):
```elixir
|> validate_required([:tool_name, :status])
|> validate_inclusion(:status, @statuses)
|> optimistic_lock(:lock_version)
```

**Recommendation:** Add Phase 21 fields only if the data cannot be derived from existing workflow, connector, grant, or audit rows. Keep approval semantics narrow.

### `lib/scoria/connectors.ex` or `lib/scoria/connectors/operator_dashboard.ex`

**Analog:** [lib/scoria/connectors.ex](/Users/jon/projects/scoria/lib/scoria/connectors.ex:52)

**List/get boundary with preload and simple filters** ([lib/scoria/connectors.ex](/Users/jon/projects/scoria/lib/scoria/connectors.ex:52)):
```elixir
def list_connectors(filters \\ %{}) do
  filters = Map.new(filters)

  Connector
  |> maybe_filter(:tenant_id, filters)
  |> maybe_filter(:status, filters)
  |> order_by([connector], asc: connector.inserted_at)
  |> Repo.all()
  |> Repo.preload([:capability_snapshot, local_tools: :aliases])
end
```

**Operator action boundary stays explicit** ([lib/scoria/connectors.ex](/Users/jon/projects/scoria/lib/scoria/connectors.ex:63)):
```elixir
def sync_connector(connector_or_id, opts \\ [])
def sync_connector(%Connector{} = connector, opts), do: do_sync_connector(connector, opts)
def sync_connector(connector_id, opts),
  do: get_connector!(connector_id) |> do_sync_connector(opts)
```

**Refresh causes are normalized and low-cardinality** ([lib/scoria/connectors.ex](/Users/jon/projects/scoria/lib/scoria/connectors.ex:122)):
```elixir
trigger_cause = normalize_trigger_cause(attrs[:trigger_cause] || attrs["trigger_cause"])
```

**Audit metadata uses stable nouns, not raw payload detail** ([lib/scoria/connectors.ex](/Users/jon/projects/scoria/lib/scoria/connectors.ex:187)):
```elixir
metadata: %{
  connector_id: connector.id,
  transport_kind: connector.transport_kind,
  auth_mode: connector.auth_mode
}
```

**Recommendation:** Keep fleet table and drawer queries in a context/query module that composes `Connectors` data. Do not let LiveView join connector, grant, tool, and refresh tables ad hoc.

### `lib/scoria_web/live/orchestrator_live.ex`

**Analog:** [lib/scoria_web/live/orchestrator_live.ex](/Users/jon/projects/scoria/lib/scoria_web/live/orchestrator_live.ex:86)

**Async evidence loading pattern** ([lib/scoria_web/live/orchestrator_live.ex](/Users/jon/projects/scoria/lib/scoria_web/live/orchestrator_live.ex:106)):
```elixir
{:noreply,
 socket
 |> refresh_trace_badges(trace_id, run_id)
 |> assign_async(:incident_evidence, fn ->
   {:ok, %{incident_evidence: load_incident_projection(trace_id, run_id)}}
 end)}
```

**Stream-first dashboard list pattern** ([lib/scoria_web/live/orchestrator_live.ex](/Users/jon/projects/scoria/lib/scoria_web/live/orchestrator_live.ex:154)):
```heex
<div id="traces-list" phx-update="stream" class="space-y-4">
  <div :for={{id, trace} <- @streams.traces} id={id} class="bg-white p-4 rounded shadow">
```

**Projection over workflow truth, not UI-owned state** ([lib/scoria_web/live/orchestrator_live.ex](/Users/jon/projects/scoria/lib/scoria_web/live/orchestrator_live.ex:235)):
```heex
<%= if @active_approval do %>
  <div id="approval-modal" ...>
    Record a workflow-owned decision. The approval state and audit evidence are written durably before any resume attempt.
```

**Decision handling pattern** ([lib/scoria_web/live/orchestrator_live.ex](/Users/jon/projects/scoria/lib/scoria_web/live/orchestrator_live.ex:647)):
```elixir
with {:ok, updated_approval} <- Workflows.approve(approval.id, status, attrs),
     {:ok, updated_socket} <- maybe_resume_approval(socket, updated_approval, status) do
  assign(updated_socket, :active_approval, nil)
else
  {:error, reason} ->
    put_flash(socket, :error, approval_error_message(status, reason))
end
```

**Evidence projection pattern: derive compact rows, then render** ([lib/scoria_web/live/orchestrator_live.ex](/Users/jon/projects/scoria/lib/scoria_web/live/orchestrator_live.ex:458)):
```elixir
approval_id =
  first_present([
    alert_event && get_in(alert_event.evidence_refs || %{}, ["approval_id"]),
    incident_event && get_in(incident_event.evidence_refs || %{}, ["approval_id"]),
    incident_event && get_in(incident_event.metadata || %{}, ["approval_id"])
  ])
```

**Recommendation:** Phase 21 can live here initially if needed, but new inbox/table/drawer/evidence projection helpers should remain data-driven and avoid new mutable socket truth.

### `lib/scoria_web/live/workflow_live/show.ex`

**Analog:** [lib/scoria_web/live/workflow_live/show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:9)

**Durable subscription pattern** ([lib/scoria_web/live/workflow_live/show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:9)):
```elixir
if connected?(socket) do
  Workflows.subscribe_run(run_id)
end
```

**Reload on workflow and approval messages** ([lib/scoria_web/live/workflow_live/show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:23)):
```elixir
def handle_info({:workflow_updated, run_id}, socket), do: {:noreply, load_run(socket, run_id)}
def handle_info({:approval_requested, run_id, _approval_id}, socket), do: {:noreply, load_run(socket, run_id)}
```

**Timeline + detail split** ([lib/scoria_web/live/workflow_live/show.ex](/Users/jon/projects/scoria/lib/scoria_web/live/workflow_live/show.ex:43)):
```heex
<div class="grid gap-6 lg:grid-cols-[minmax(0,1.2fr)_minmax(20rem,0.8fr)]">
  <section ...>...</section>
  <WorkflowDetailPanelComponent.workflow_detail_panel ... />
</div>

<section ...>
  <h2 class="text-lg font-semibold">Timeline</h2>
  <ol id="workflow-timeline" class="mt-3 space-y-2">
```

**Recommendation:** Use this as the closest analog for the Phase 21 run-centric evidence notebook and any connector drawer shell.

### `lib/scoria_web/components/remote_invocation_evidence_component.ex`

**Analog:** [lib/scoria_web/components/incident_evidence_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/incident_evidence_component.ex:6)

**Compact rollup first, deeper evidence below** ([lib/scoria_web/components/incident_evidence_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/incident_evidence_component.ex:28)):
```heex
<div class="grid gap-3 lg:grid-cols-5">
  ...
</div>

<div class="mt-4 grid gap-4 xl:grid-cols-[1.25fr,0.9fr]">
```

**Cross-link exact durable nouns** ([lib/scoria_web/components/incident_evidence_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/incident_evidence_component.ex:112)):
```heex
<a class="text-blue-700 underline" href={"#trace-#{incident.trace_id}"}>Trace ...</a>
<a :if={incident.run_id} ... href={"#run-#{incident.run_id}"}>Run ...</a>
<a :if={incident.approval_id} ... href={"#approval-#{incident.approval_id}"}>Approval ...</a>
```

**Badge taxonomy stays fixed and boring** ([lib/scoria_web/components/incident_evidence_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/incident_evidence_component.ex:173)):
```elixir
case {kind, value} do
  {:severity, "critical"} -> ...
  {:routing, "review"} -> ...
  {:audit, "pending"} -> ...
  _ -> ...
end
```

**Recommendation:** Build a new evidence component as a sibling, not a huge expansion of the incident notebook. Keep the same compact-rollup + notebook + side-strip composition.

### `lib/scoria_web/components/connector_detail_drawer_component.ex`

**Analog:** [lib/scoria_web/components/workflow_detail_panel_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/workflow_detail_panel_component.ex:7)

**Simple inspectable detail panel** ([lib/scoria_web/components/workflow_detail_panel_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/workflow_detail_panel_component.ex:9)):
```heex
<aside id="workflow-detail-panel" class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
```

**Definition list pattern for dense operator metadata** ([lib/scoria_web/components/workflow_detail_panel_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/workflow_detail_panel_component.ex:12)):
```heex
<dl class="mt-4 space-y-2 text-sm">
  <div>
    <dt class="font-medium text-stone-600">Role</dt>
    <dd><%= @step.role_id %></dd>
  </div>
```

**Recommendation:** The connector drawer should reuse this dense-inspection pattern, but swap step/checkpoint fields for connector health, grant summary, refresh history, pending tools, and approval links.

### Tests: workflow durability and LiveView evidence

**Workflow durability analog:** [test/scoria/workflows_test.exs](/Users/jon/projects/scoria/test/scoria/workflows_test.exs:114)
```elixir
assert {:ok, approval} =
         Workflows.mark_waiting_for_approval(run.id, step.id, %{...})

updated_run = Workflows.get_run_tree!(run.id)
updated_step = Workflows.get_step!(step.id)

assert updated_run.status == "waiting_for_approval"
assert updated_step.status == "waiting_for_approval"
```

**Connector evidence event analog:** [test/scoria/workflows_test.exs](/Users/jon/projects/scoria/test/scoria/workflows_test.exs:159)
```elixir
assert {:ok, auth_event} = Workflows.record_connector_auth_failure(...)
assert {:ok, scope_event} = Workflows.record_connector_scope_escalation(...)
```

**LiveView approval modal analog:** [test/scoria_web/live/orchestrator_live_test.exs](/Users/jon/projects/scoria/test/scoria_web/live/orchestrator_live_test.exs:189)
```elixir
send(view.pid, {:hitl_request, approval})
render_click(view, "approve", %{})
updated_approval = Repo.get!(Scoria.Observe.Approval, approval.id)
assert updated_approval.status == "approved"
```

**Lazy evidence rendering analog:** [test/scoria_web/live/orchestrator_live_test.exs](/Users/jon/projects/scoria/test/scoria_web/live/orchestrator_live_test.exs:129)
```elixir
render_click(view, "load_retrieval_evidence", %{"id" => "trace-evidence"})
assert render(view) =~ "citation"
```

**Real lineage integration analog:** [test/scoria_web/live/orchestrator_live_sre_test.exs](/Users/jon/projects/scoria/test/scoria_web/live/orchestrator_live_sre_test.exs:82)
```elixir
render_click(view, "load_incident_evidence", %{"id" => trace_id, "run_id" => run.id})
render_async(view)
html = render(view)
assert html =~ approval.id
assert html =~ "approval.requested"
```

**Recommendation:** Phase 21 tests should follow the existing split:
- unit-ish workflow tests for durable approval/resume/event semantics
- LiveView interaction tests for inbox/table/drawer controls
- SRE-backed integration tests for evidence notebook lineage across workflow, audit, connector, and delivery rows

## Shared Patterns

### Workflow-owned approval truth
**Source:** [lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:294)

Apply to inbox rows, connector read-through, and replay flows:
```elixir
Run/Step status -> checkpoint -> event -> approval row -> audit event
```

### Durable resume after explicit decision
**Source:** [lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:512)

Apply to replay/resume affordances:
```elixir
approved approval -> resume_requested checkpoint/event -> step re-queued
```

### Connectors boundary
**Source:** [lib/scoria/connectors.ex](/Users/jon/projects/scoria/lib/scoria/connectors.ex:40)

Apply to dashboard fleet/detail data:
```elixir
get/list/sync live in the context; preload durable associations there; LiveView consumes projections.
```

### Evidence lineage joins by durable ids
**Source:** [lib/scoria_web/live/orchestrator_live.ex](/Users/jon/projects/scoria/lib/scoria_web/live/orchestrator_live.ex:463)

Apply to remote invocation evidence:
```elixir
approval_id is recovered from evidence_refs/metadata and rendered as a linkable stable noun.
```

### Telemetry must stay low-cardinality
**Sources:** [lib/scoria/sre.ex](/Users/jon/projects/scoria/lib/scoria/sre.ex:145), [lib/scoria/sre/telemetry_identity.ex](/Users/jon/projects/scoria/lib/scoria/sre/telemetry_identity.ex:6), [test/scoria/sre/telemetry_test.exs](/Users/jon/projects/scoria/test/scoria/sre/telemetry_test.exs:71)

Copy these constraints:
```elixir
:telemetry.execute([:scoria, :sre, :audit_outbox, :created], %{count: 1}, %{
  event_type: audit_outbox_event.event_type,
  policy_class: audit_outbox_event.policy_class,
  tenant_id: audit_outbox_event.tenant_id,
  trace_id: audit_outbox_event.trace_id,
  workflow_run_id: audit_outbox_event.workflow_run_id,
  step_id: audit_outbox_event.step_id
})
```

```elixir
@label_keys [:tenant_id, :subject_kind, :policy_key, :reason_code, :window_bucket,
             :provider, :model, :tool_name, :integration_kind, :breaker_key, :state, :severity]
@ref_keys   [:trace_id, :run_id, :workflow_run_id, :actor_id, :session_id,
             :scorer_version, :baseline_version]
```

Use stable categories like `approval.requested`, `approval.approved`, `connector.auth_failed`, `connector.scope_escalation`, `operator_sync`, `remote_mcp`, and typed blocker outcomes. Keep exact connector/run/approval detail in row ids and audit metadata, not metric labels.

## Likely Phase 21 Targets

1. Modify [lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:294) to expose workflow-owned approval inbox and replay-readiness queries, or add a tightly scoped sibling query module under `lib/scoria/workflows/`.
2. Modify [lib/scoria/connectors.ex](/Users/jon/projects/scoria/lib/scoria/connectors.ex:52) or add `lib/scoria/connectors/operator_dashboard.ex` for fleet-table and detail-drawer projections over connector, grant, capability snapshot, and pending-tool state.
3. Modify [lib/scoria_web/live/orchestrator_live.ex](/Users/jon/projects/scoria/lib/scoria_web/live/orchestrator_live.ex:145) to add the approvals inbox and connector fleet table, while keeping async evidence loading and workflow-owned decision handling.
4. Add `lib/scoria_web/components/remote_invocation_evidence_component.ex` using the incident notebook composition from [lib/scoria_web/components/incident_evidence_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/incident_evidence_component.ex:28).
5. Add `lib/scoria_web/components/connector_detail_drawer_component.ex` using [lib/scoria_web/components/workflow_detail_panel_component.ex](/Users/jon/projects/scoria/lib/scoria_web/components/workflow_detail_panel_component.ex:9) as the dense detail analog.
6. Extend [test/scoria/workflows_test.exs](/Users/jon/projects/scoria/test/scoria/workflows_test.exs:114), [test/scoria_web/live/orchestrator_live_test.exs](/Users/jon/projects/scoria/test/scoria_web/live/orchestrator_live_test.exs:189), and [test/scoria_web/live/orchestrator_live_sre_test.exs](/Users/jon/projects/scoria/test/scoria_web/live/orchestrator_live_sre_test.exs:82) for durable approval lineage, inbox/drawer UI, and evidence cross-links.

## No Close Analog

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/scoria_web/components/approvals_inbox_component.ex` | component | transform | No dedicated inbox component exists yet; reuse `OrchestratorLive` list rendering and `WorkflowLive.Show` split-pane structure. |
| `lib/scoria_web/components/connector_fleet_table_component.ex` | component | transform | No operator-grade fleet table exists yet; reuse simple table conventions plus current badge taxonomy. |

## Metadata

**Analog search scope:** `lib/scoria`, `lib/scoria_web/live`, `lib/scoria_web/components`, `test/scoria`, `test/scoria_web/live`, `.planning/phases/20-*`, `.planning/phases/21-*`
**Key patterns identified:**
- Approval truth is workflow-owned and persisted before any UI or resume action.
- LiveView surfaces are projections that subscribe/reload from durable workflow events.
- Evidence views stay trace-first, compact-first, and link through stable durable ids.
- Connector/operator actions remain explicit context APIs with normalized causes.
- Telemetry separates low-cardinality labels from correlation refs.
