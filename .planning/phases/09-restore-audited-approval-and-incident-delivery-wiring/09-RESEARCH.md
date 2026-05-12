# Phase 9: Restore Audited Approval and Incident Delivery Wiring - Research

**Researched:** 2026-05-12 [VERIFIED: system date]
**Domain:** Phoenix LiveView approval actions, Ecto transactional invariants, and durable incident delivery lineage in Scoria's Seismograph stack. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md; VERIFIED: lib/scoria/workflows.ex; VERIFIED: lib/scoria/sre/incident_manager.ex; VERIFIED: lib/scoria_web/live/orchestrator_live.ex]
**Confidence:** MEDIUM [VERIFIED: repo code inspection; CITED: https://hexdocs.pm/ecto/Ecto.Multi.html; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

<user_constraints>
## User Constraints (from CONTEXT.md) [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md]

### Locked Decisions
- **D-01:** `Scoria.Workflows.approve/3` is the only blessed mutation path for approval decisions.
- **D-02:** LiveView and any other callers must treat approvals as workflow-owned domain actions, not rows to mutate directly with `Repo.update/2`.
- **D-03:** Approval request, approve, reject, and expire transitions must write workflow truth and durable audit evidence in the same transaction.
- **D-04:** The public mutation contract stays on `Scoria.Workflows` even if implementation later moves into an internal workflow-owned submodule.
- **D-05:** Approval decisions must carry actor, tenant, and trace context so audit evidence remains operator-grade and attributable.
- **D-06:** The operator-facing approve path should feel like one action: record the decision through `Scoria.Workflows.approve/3`, then continue the run only through workflow-owned resume logic after commit rather than via UI-side row mutation.
- **D-07:** `notification_deliveries` are durable local intent rows and must be written in the same transaction that creates or updates the incident graph.
- **D-08:** External sending stays post-commit and asynchronous through `Scoria.SRE.Relay`; adapters never run inside the incident transaction.
- **D-09:** Scoria owns a small boring default routing model:
  - `review` incidents route to `chimeway`
  - `page` incidents route to `mailglass`
- **D-10:** If a dispatcher or routing target is unconfigured, Scoria must preserve local incident and delivery evidence and record the transport as explicit `noop` or `unconfigured`, not silently drop the notification.
- **D-11:** Create delivery rows when an incident first opens and when routing escalates from `review` to `page`; deduped repeats update evidence but should not fan out new responder noise by default.
- **D-12:** Host apps may override sink selection later, but Phase 9 planning should assume Scoria owns the default routing so install-time behavior stays coherent and evidence-first.
- **D-13:** Approval, audit, incident, and delivery evidence stays inside the existing trace-first LiveView notebook rather than a separate dashboard surface.
- **D-14:** Phase 9 must prove end-to-end lineage from operator approval through durable audit-outbox rows and relay or delivery evidence, with drilldowns linked back to the same run and trace.
- **D-15:** Keep evidence loading explicit and lazy; do not auto-load heavy approval, audit, or delivery notebooks on mount.
- **D-16:** The composite health rollup remains a compact summary, not the primary product surface; the trace-first notebook remains the main operator mental model.
- **D-17:** Favor batteries-included defaults and push low-impact decisions left into Scoria-owned behavior unless a choice is materially product-defining or architecture-shaping.
- **D-18:** Planning for this phase should optimize for boring, testable seams and least surprise over abstract flexibility or host-app ceremony.

### Claude's Discretion
- Exact helper/module extraction if `Scoria.Workflows` approval internals need cleanup, so long as the public approval contract remains workflow-owned.
- Exact config shape for default `chimeway` and `mailglass` routing keys.
- Exact metadata fields used to distinguish `noop`, `unconfigured`, `failed`, and `delivered` transport outcomes.
- Exact approval resume hook placement after commit, so long as it remains a workflow-owned action and not a direct UI mutation.

### Deferred Ideas (OUT OF SCOPE)
- A separate approval, audit, or delivery dashboard surface.
- Host-app-owned notification routing as the default posture.
- Direct adapter publishing without durable local delivery rows.
- Aggressive auto-loading or broader incident-control chrome in the main LiveView.
- A cross-cutting standalone `Scoria.Approvals` public context unless approvals later become meaningfully broader than workflow-owned checkpoints and steps.
- Telemetry-wiring and local-bootstrap fixes outside the narrow seams required to verify Phase 9.
</user_constraints>

<phase_requirements>
## Phase Requirements [VERIFIED: .planning/milestones/v1.3-REQUIREMENTS.md]

| ID | Description | Research Support |
|----|-------------|------------------|
| SRE-05 | Approval UI still bypasses the audited workflow boundary. [VERIFIED: .planning/milestones/v1.3-REQUIREMENTS.md; VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md] | Route LiveView approval/reject actions to `Scoria.Workflows.approve/3`, carry actor/tenant/trace attrs, and resume only through workflow-owned logic after commit. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex; VERIFIED: lib/scoria/workflows.ex] |
| SRE-06 | Incident routing does not produce durable delivery rows. [VERIFIED: .planning/milestones/v1.3-REQUIREMENTS.md; VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md] | Extend `Scoria.SRE.IncidentManager.record_alert_event/1` so `NotificationDelivery` rows are created in the same `Ecto.Multi` as incident and incident-event writes. [VERIFIED: lib/scoria/sre/incident_manager.ex; VERIFIED: lib/scoria/sre/notification_delivery.ex; CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| SRE-07 | The live incident -> delivery -> relay -> operator path is broken. [VERIFIED: .planning/milestones/v1.3-REQUIREMENTS.md; VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md] | Prove the real path end-to-end: incident writes create deliveries, relay drains them post-commit, and the existing LiveView evidence notebook renders the resulting lineage lazily. [VERIFIED: lib/scoria/sre/relay.ex; VERIFIED: lib/scoria_web/live/orchestrator_live.ex; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
</phase_requirements>

## Summary

Phase 9 is a seam-repair phase, not a new-surface phase. The existing code already contains the correct durable approval boundary in `Scoria.Workflows.approve/3`, the correct post-commit relay runtime in `Scoria.SRE.Relay`, and the correct trace-first evidence surface in `ScoriaWeb.OrchestratorLive`; the missing pieces are that the LiveView still mutates approval rows directly and `IncidentManager` still never produces `NotificationDelivery` rows on real alert paths. [VERIFIED: lib/scoria/workflows.ex; VERIFIED: lib/scoria_web/live/orchestrator_live.ex; VERIFIED: lib/scoria/sre/incident_manager.ex; VERIFIED: lib/scoria/sre/relay.ex; VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md]

The planning posture should therefore be: keep public call sites narrow, preserve `Ecto.Multi` ownership for local truth changes, and treat external sending as a strictly post-commit concern. Official Ecto guidance supports `Ecto.Multi.run/3` for dependent transactional writes, and official LiveView guidance supports `assign_async/3` plus `render_async/2` for lazy evidence loading and deterministic async tests. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

Verification is the other critical planning concern. The current operator notebook can render seeded SRE evidence, but the phase requirement is real lineage, not seeded placeholders; additionally, the local test baseline already shows one unrelated red test around `AuditOutboxEvent` unique-constraint naming and the workspace still lacks the PostgreSQL `vector` extension, so the plan should include focused verification setup and avoid assuming a clean full-migration path. [VERIFIED: test/scoria_web/live/orchestrator_live_sre_test.exs; VERIFIED: test/scoria/sre/audit_outbox_test.exs; VERIFIED: lib/scoria/sre/audit_outbox_event.ex; VERIFIED: `MIX_ENV=test mix test ...` run on 2026-05-12; VERIFIED: `psql -d postgres -c "SELECT name, default_version, installed_version FROM pg_available_extensions WHERE name = 'vector';"`]

**Primary recommendation:** Keep all approval and incident truth mutations inside existing owning contexts, add delivery-row production inside `IncidentManager`'s transaction, and plan a single end-to-end verification slice that exercises real approval -> audit, incident -> delivery -> relay, and notebook lineage on the existing LiveView surface. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md; VERIFIED: lib/scoria/workflows.ex; VERIFIED: lib/scoria/sre/incident_manager.ex; VERIFIED: lib/scoria_web/live/orchestrator_live.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Operator approval click handling | Frontend Server (LiveView) | API / Backend | The LiveView owns the event and UX, but it must delegate the mutation to `Scoria.Workflows.approve/3` instead of updating the row directly. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex; VERIFIED: lib/scoria/workflows.ex] |
| Durable approval truth and audit evidence | API / Backend | Database / Storage | Approval state, audit outbox rows, and resumable workflow state are persisted together inside workflow-owned transactions. [VERIFIED: lib/scoria/workflows.ex; VERIFIED: test/scoria/sre/audit_outbox_test.exs; CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Workflow resume after approval | API / Backend | Frontend Server (LiveView) | Resume semantics already live in `Scoria.Workflows.resume_run/1` and `Scoria.Workflows.Resume.resume_run/2`; the UI should only trigger them after commit. [VERIFIED: lib/scoria/workflows.ex; VERIFIED: lib/scoria/workflows/resume.ex; VERIFIED: test/scoria/workflows/runtime_test.exs] |
| Incident dedupe and routing decision | API / Backend | Database / Storage | `IncidentManager` computes severity and routing, owns incident root updates, and should also own delivery-intent creation. [VERIFIED: lib/scoria/sre/incident_manager.ex; VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md] |
| Durable delivery intent rows | Database / Storage | API / Backend | `NotificationDelivery` is a persisted queue/state noun that must be created transactionally with incident graph changes. [VERIFIED: lib/scoria/sre/notification_delivery.ex; VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md] |
| External notification fanout | API / Backend | — | `Scoria.SRE.Relay` already claims pending deliveries and publishes them after commit, outside the incident transaction. [VERIFIED: lib/scoria/sre/relay.ex] |
| Operator evidence rendering | Frontend Server (LiveView) | Database / Storage | The notebook reads durable rows lazily with `assign_async/3` and renders trace-first evidence rather than owning truth. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | `1.8.7` released 2026-05-06. [VERIFIED: mix hex.info phoenix] | LiveView host framework and endpoint/router/runtime surface. [VERIFIED: mix.exs] | The phase already lives inside Phoenix LiveView and router-driven operator surfaces; no framework change is warranted. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex; VERIFIED: mix.exs] |
| Phoenix LiveView | `1.1.30` released 2026-05-05. [VERIFIED: mix hex.info phoenix_live_view] | Handles approval events and lazy evidence projection. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] | Official docs support `assign_async/3` and `AsyncResult` for exactly the lazy evidence pattern this phase must preserve. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.AsyncResult.html] |
| Ecto SQL | `3.13.5` released 2026-03-03. [VERIFIED: mix hex.info ecto_sql] | Transactional multi-row writes for approvals, incidents, audit outbox, and deliveries. [VERIFIED: lib/scoria/workflows.ex; VERIFIED: lib/scoria/sre/incident_manager.ex] | Official docs explicitly position `Ecto.Multi` for dependent operations and preflight changeset validation in one transaction. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Postgrex | `0.22.1` locked, with `0.22.2` published 2026-05-12. [VERIFIED: mix hex.info postgrex] | PostgreSQL adapter for durable workflow and SRE rows. [VERIFIED: mix.exs] | The phase depends on real database transactions, locks, and local row claiming already implemented by `Repo` and relay code. [VERIFIED: lib/scoria/sre/relay.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix HTML | `4.3.0` released 2025-09-28. [VERIFIED: mix hex.info phoenix_html] | Backing HTML helpers/components for current LiveView rendering. [VERIFIED: mix.exs] | Use as part of the existing LiveView/component surface; do not introduce a separate frontend stack. [VERIFIED: lib/scoria_web/components/incident_evidence_component.ex] |
| pgvector | `0.3.1` released 2025-06-23. [VERIFIED: mix hex.info pgvector] | Existing workspace dependency unrelated to Phase 9 logic but relevant to migration/test baseline. [VERIFIED: mix.exs] | Only relevant when full migrations run; the current local PostgreSQL instance does not expose the `vector` extension. [VERIFIED: `psql -d postgres -c "SELECT name, default_version, installed_version FROM pg_available_extensions WHERE name = 'vector';"`] |
| `Scoria.Workflows` | repo-local public context. [VERIFIED: lib/scoria/workflows.ex] | Owns durable workflow truth, approval mutation, and resumable transitions. [VERIFIED: lib/scoria/workflows.ex] | Use for every approval decision and resume trigger; do not widen the public contract in this phase. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md] |
| `Scoria.SRE.Relay` | repo-local supervised runtime. [VERIFIED: lib/scoria/sre/relay.ex] | Post-commit fanout for audit and notification rows. [VERIFIED: lib/scoria/sre/relay.ex] | Reuse as-is for dispatch; do not insert vendor calls into incident transactions. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Scoria.Workflows.approve/3` | Direct `Repo.update/2` from LiveView | Rejected because it bypasses audit-outbox creation and workflow-owned resume semantics, which is the exact SRE-05 gap. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex; VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md] |
| Transactional `NotificationDelivery` rows + relay | Direct adapter publish in `IncidentManager` | Rejected because crashes or unconfigured sinks would lose or hide local evidence, violating D-07 through D-10. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md; VERIFIED: lib/scoria/sre/relay.ex] |
| Existing trace-first notebook | New approval/incident dashboard | Rejected because D-13 through D-16 explicitly keep evidence inside the existing LiveView and require lazy loading. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md; VERIFIED: lib/scoria_web/live/orchestrator_live.ex] |

**Installation:** Existing dependencies are already declared; no new package is required for the recommended approach. [VERIFIED: mix.exs]
```bash
mix deps.get
```

## Architecture Patterns

### System Architecture Diagram
```text
Operator click in OrchestratorLive
  -> LiveView event handler
    -> Scoria.Workflows.approve/3
      -> update approval row
      -> insert audit_outbox row
      -> commit
    -> workflow-owned resume trigger after commit
      -> Workflows.resume_run/1 / Workflows.Resume.resume_run/2
        -> runtime continues from stored checkpoint

Runtime or policy alert
  -> Scoria.SRE.IncidentManager.record_alert_event/1
    -> get/create incident
    -> insert alert_event
    -> insert incident_event
    -> insert notification_deliveries for new open / escalation
    -> commit
  -> Scoria.SRE.Relay.drain_once/0 or supervised poller
    -> claim pending deliveries
    -> publish through adapter or noop/unconfigured sink
    -> persist delivered/failed evidence
  -> OrchestratorLive load_incident_evidence
    -> assign_async/3
      -> query incidents + audit rows + deliveries
      -> IncidentEvidenceComponent renders lineage
```
This is the required data flow because the current code already separates mutation, relay, and projection, and the broken seam is that producer-side delivery rows are missing. [VERIFIED: lib/scoria/workflows.ex; VERIFIED: lib/scoria/sre/incident_manager.ex; VERIFIED: lib/scoria/sre/relay.ex; VERIFIED: lib/scoria_web/live/orchestrator_live.ex]

### Recommended Project Structure
```text
lib/
├── scoria/
│   ├── workflows.ex                 # approval mutation + workflow resume boundary
│   ├── workflows/resume.ex          # exact resume orchestration
│   └── sre/
│       ├── incident_manager.ex      # incident dedupe + delivery production
│       ├── notification_delivery.ex # durable delivery intent/state
│       └── relay.ex                 # post-commit dispatch + retry state
└── scoria_web/
    ├── live/orchestrator_live.ex    # trace-first operator events + lazy evidence loading
    └── components/incident_evidence_component.ex # notebook rendering

test/
├── scoria/
│   ├── sre/incident_test.exs
│   ├── sre/relay_test.exs
│   └── workflows/integration_test.exs
└── scoria_web/live/orchestrator_live_sre_test.exs
```
This structure already exists in the repo and should be preserved rather than widened. [VERIFIED: `rg --files lib test` results in session]

### Pattern 1: Workflow-Owned Approval Mutation Plus Post-Commit Resume
**What:** The UI records only an intentful approval decision; `Scoria.Workflows` owns row updates, audit evidence, and resumable state transitions. [VERIFIED: lib/scoria/workflows.ex; VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md]

**When to use:** Use this for `approve`, `reject`, and `expire` paths, and for any future approval action surfaced in LiveView or another boundary. [VERIFIED: lib/scoria/workflows.ex]

**Example:**
```elixir
# Source: lib/scoria/workflows.ex
with {:ok, approval} <-
       Scoria.Workflows.approve(approval_id, "approved", %{
         actor_id: actor_id,
         tenant_id: tenant_id,
         trace_id: trace_id
       }),
     {:ok, _run} <- Scoria.Workflows.Resume.resume_run(approval.workflow_run_id, handlers: handlers) do
  :ok
end
```
The sequencing above is required because `approve/3` already persists the audit outbox row in the transaction, while resume belongs after commit. [VERIFIED: lib/scoria/workflows.ex; VERIFIED: lib/scoria/workflows/resume.ex]

### Pattern 2: Incident Graph and Delivery Intent in One `Ecto.Multi`
**What:** Create or update the incident root, append alert history, append incident history, and insert one or more `NotificationDelivery` rows in a single transaction. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md; CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

**When to use:** Use this only on incident open and routing escalation paths; deduped repeats should update lineage without creating new responder noise. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md]

**Example:**
```elixir
# Source: adapted from lib/scoria/sre/incident_manager.ex + Ecto.Multi docs
Multi.new()
|> Multi.run(:incident, fn repo, _changes -> {:ok, get_or_create_incident(repo, envelope)} end)
|> Multi.run(:alert_event, fn repo, %{incident: {incident, status}} ->
  {:ok, create_alert_event(repo, incident, status, envelope)}
end)
|> Multi.run(:incident_event, fn repo, %{incident: {incident, _}, alert_event: alert_event} ->
  {:ok, append_incident_event_record(repo, incident, alert_event, envelope)}
end)
|> Multi.run(:deliveries, fn repo, %{incident: {incident, status}, alert_event: alert_event} ->
  {:ok, create_notification_deliveries(repo, incident, alert_event, status, envelope)}
end)
|> Repo.transaction()
```
The missing `deliveries` step is the central SRE-06 repair. [VERIFIED: lib/scoria/sre/incident_manager.ex; VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md]

### Pattern 3: Trace-First Lazy Evidence Loading
**What:** Keep heavy SRE notebook data off the initial mount and load it through `assign_async/3`, then await it in tests with `render_async/2`. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

**When to use:** Use this for incident, audit, and delivery drilldowns, but not for mount-time defaults or speculative preloads. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md; VERIFIED: lib/scoria_web/live/orchestrator_live.ex]

**Example:**
```elixir
# Source: lib/scoria_web/live/orchestrator_live.ex
def handle_event("load_incident_evidence", %{"id" => trace_id, "run_id" => run_id}, socket) do
  {:noreply,
   socket
   |> refresh_trace_badges(trace_id, run_id)
   |> assign_async(:incident_evidence, fn ->
     {:ok, %{incident_evidence: load_incident_projection(trace_id, run_id)}}
   end)}
end
```
This existing pattern should stay intact; the fix is to make the queried lineage truthful. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex]

### Anti-Patterns to Avoid
- **Direct LiveView row mutation:** `handle_event("approve" | "reject")` currently calls `Repo.update/2` on `Approval`; that is the exact bypass this phase exists to remove. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex; VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md]
- **Adapter calls inside incident transactions:** `Relay` already owns fanout after commit, so duplicating vendor calls inside `IncidentManager` would create split-brain truth under failures. [VERIFIED: lib/scoria/sre/relay.ex; VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md]
- **Verification with seeded placeholders only:** `orchestrator_live_sre_test.exs` seeds incidents and deliveries directly today, which is useful for rendering but insufficient as proof of SRE-07. [VERIFIED: test/scoria_web/live/orchestrator_live_sre_test.exs]
- **Mount-time eager notebook loading:** D-15 forbids auto-loading heavy approval, audit, or delivery notebooks on mount. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Approval decision path | A UI-owned approval state machine | `Scoria.Workflows.approve/3` + existing resume seam | The repo already has the durable workflow boundary and audit insertion path; duplicating it in LiveView would reintroduce SRE-05. [VERIFIED: lib/scoria/workflows.ex; VERIFIED: lib/scoria_web/live/orchestrator_live.ex] |
| Incident dispatch producer | Ad hoc `Repo.insert!` calls scattered across alert code | A single `IncidentManager` `Ecto.Multi` that returns incident, alert event, incident event, and deliveries together | Shared transactional ownership is what keeps incident lineage truthful under rollback and retry. [VERIFIED: lib/scoria/sre/incident_manager.ex; CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Notification sending | Direct vendor dispatch from incident code | Existing `Scoria.SRE.Relay` + optional adapters | Relay already claims pending rows, increments attempts, and persists outcomes locally. [VERIFIED: lib/scoria/sre/relay.ex] |
| Operator evidence proof | Seeded rows as the final acceptance path | Real incident-producing tests that flow through relay and notebook queries | Seeded rendering tests prove projection shape, not end-to-end lineage. [VERIFIED: test/scoria_web/live/orchestrator_live_sre_test.exs; VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md] |

**Key insight:** This phase succeeds by reconnecting already-existing seams, not by adding new abstractions. [VERIFIED: lib/scoria/workflows.ex; VERIFIED: lib/scoria/sre/relay.ex; VERIFIED: lib/scoria_web/live/orchestrator_live.ex]

## Common Pitfalls

### Pitfall 1: Approve/Reject Still Bypass Workflow Ownership
**What goes wrong:** The operator click updates `ai_approvals.status` but creates no new audit outbox row and triggers no workflow-owned continuation. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex; VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md]
**Why it happens:** The LiveView event handler currently reaches for `Repo.update/2` because it already has the approval struct in socket assigns. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex]
**How to avoid:** Replace both handlers with a single context call path that supplies actor, tenant, and trace metadata and then invokes resume only after `approve/3` succeeds. [VERIFIED: lib/scoria/workflows.ex; VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md]
**Warning signs:** A test can approve an item from LiveView and the `Approval` row changes, but no new `AuditOutboxEvent` exists and no resumed step completes. [VERIFIED: test/scoria_web/live/orchestrator_live_test.exs; VERIFIED: test/scoria/workflows/integration_test.exs]

### Pitfall 2: Incident Rows Exist but Relay Has Nothing to Drain
**What goes wrong:** Incidents, alert events, and incident events persist, but `NotificationDelivery` remains empty so relay-based delivery never starts. [VERIFIED: lib/scoria/sre/incident_manager.ex; VERIFIED: lib/scoria/sre/relay.ex; VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md]
**Why it happens:** `record_alert_event/1` currently stops after `incident_event` and never inserts deliveries. [VERIFIED: lib/scoria/sre/incident_manager.ex]
**How to avoid:** Add delivery creation to the same `Ecto.Multi` and branch only on `:new` or escalation states, not on every deduped alert. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md; CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
**Warning signs:** `Relay.drain_once/0` tests pass only when they seed deliveries manually. [VERIFIED: test/scoria/sre/relay_test.exs]

### Pitfall 3: Relay Outcome Evidence Is Lost for Unconfigured Sinks
**What goes wrong:** The system silently drops a notification because no dispatcher is configured, leaving the notebook unable to explain what happened. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md]
**Why it happens:** Optional adapters already return `:noop` envelopes in tests, but producer-side delivery rows do not yet carry an explicit local evidence story for noop or unconfigured cases. [VERIFIED: test/scoria/sre/relay_test.exs; ASSUMED]
**How to avoid:** Always persist the delivery row first, keep fanout async, and record noop/unconfigured semantics in durable delivery status or metadata without suppressing the row. [VERIFIED: lib/scoria/sre/relay.ex; VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md; ASSUMED]
**Warning signs:** Adapter logs mention a noop, but no durable change is visible in `NotificationDelivery` or incident evidence. [ASSUMED]

### Pitfall 4: Lazy Notebook Tests Pass Without Real Lineage
**What goes wrong:** LiveView tests render correct strings but the production path is still broken because the rows were inserted directly in the test setup. [VERIFIED: test/scoria_web/live/orchestrator_live_sre_test.exs; VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md]
**Why it happens:** Component tests are easier to write than a full incident -> relay -> notebook flow. [VERIFIED: test/scoria_web/live/orchestrator_live_sre_test.exs]
**How to avoid:** Keep the seeded rendering tests, but add at least one focused integration test that creates the alert through `IncidentManager`, drains relay, and then loads notebook evidence. [VERIFIED: lib/scoria/sre/incident_manager.ex; VERIFIED: lib/scoria/sre/relay.ex; VERIFIED: lib/scoria_web/live/orchestrator_live.ex]
**Warning signs:** `render_async/2` assertions pass while `NotificationDelivery` creation is still absent from incident tests. [VERIFIED: test/scoria_web/live/orchestrator_live_sre_test.exs; VERIFIED: test/scoria/sre/incident_test.exs]

### Pitfall 5: Phase Verification Depends on an Unstable Local Baseline
**What goes wrong:** The plan assumes the full focused suite is green, but one current audit rollback test fails because the schema names a different unique constraint than the test-local index, and full migration paths still hit the missing `vector` extension. [VERIFIED: lib/scoria/sre/audit_outbox_event.ex; VERIFIED: test/scoria/sre/audit_outbox_test.exs; VERIFIED: `MIX_ENV=test mix test ...` run on 2026-05-12; VERIFIED: `psql -d postgres -c "SELECT name, default_version, installed_version FROM pg_available_extensions WHERE name = 'vector';"`]
**Why it happens:** Local focused tables and repo schema names drifted, and the workspace PostgreSQL instance does not expose `pgvector`. [VERIFIED: lib/scoria/sre/audit_outbox_event.ex; VERIFIED: test/scoria/sre/audit_outbox_test.exs; VERIFIED: `psql -d postgres -c "SELECT name, default_version, installed_version FROM pg_available_extensions WHERE name = 'vector';"`]
**How to avoid:** Plan verification with focused commands plus explicit test-fixture/bootstrap setup, and do not widen into Phase 10 except for the minimum prerequisite needed to make Phase 9 proof possible. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md]
**Warning signs:** `AuditOutboxTest` fails before any Phase 9 logic changes, or `mix ecto.migrate` requires `vector`. [VERIFIED: `MIX_ENV=test mix test ...` run on 2026-05-12; VERIFIED: .planning/phases/07-seismograph/07-04-SUMMARY.md]

## Code Examples

Verified patterns from official sources and current repo code:

### Workflow-Owned Approval
```elixir
# Source: lib/scoria/workflows.ex
def approve(approval_id, status, attrs) when status in ["approved", "rejected", "expired"] do
  Repo.transaction(fn repo ->
    approval = repo.get!(Approval, approval_id)

    updated_approval =
      approval
      |> Approval.changeset(Map.merge(Map.new(attrs), %{status: status}))
      |> repo.update!()

    audit_outbox_event =
      SRE.insert_audit_outbox_event(repo, %{
        tenant_id: Map.get(attrs, :tenant_id) || "system",
        event_type: "approval.#{status}",
        policy_class: "approval",
        actor_ref: Map.get(attrs, :actor_id),
        workflow_run_id: updated_approval.workflow_run_id,
        step_id: updated_approval.step_id,
        trace_id: Map.get(attrs, :trace_id),
        approval_id: updated_approval.id
      })

    {updated_approval, audit_outbox_event}
  end)
end
```
This is the contract the UI should use directly. [VERIFIED: lib/scoria/workflows.ex]

### Lazy LiveView Evidence Test
```elixir
# Source: test/scoria_web/live/orchestrator_live_sre_test.exs + LiveView docs
render_click(view, "load_incident_evidence", %{"id" => trace_id, "run_id" => run_id})
render_async(view)
assert render(view) =~ "Composite health rollup"
```
`render_async/2` is the official testing primitive for awaiting `assign_async/3`. [VERIFIED: test/scoria_web/live/orchestrator_live_sre_test.exs; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

### Delivery Claiming Remains Post-Commit
```elixir
# Source: lib/scoria/sre/relay.ex
from(delivery in NotificationDelivery,
  where: delivery.delivery_status in ["pending", "failed"],
  order_by: [asc: delivery.pending_at, asc: delivery.inserted_at],
  limit: ^batch_size,
  lock: "FOR UPDATE SKIP LOCKED"
)
```
The relay's database claiming pattern is already correct and should be reused rather than replaced. [VERIFIED: lib/scoria/sre/relay.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| LiveView mutates approval rows directly. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] | Approval decisions should be workflow-owned domain actions through `Scoria.Workflows.approve/3`, followed by workflow-owned resume after commit. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md; VERIFIED: lib/scoria/workflows.ex] | Locked for Phase 9 on 2026-05-12. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md] | Restores truthful audit lineage and resumability for SRE-05. [VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md] |
| Incident routing persists incidents and events only. [VERIFIED: lib/scoria/sre/incident_manager.ex] | Incident routing should also persist durable `NotificationDelivery` intent rows in the same transaction. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md] | Required in Phase 9 after Phase 7 gap audit on 2026-05-12. [VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md] | Gives relay a real producer and closes SRE-06. [VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md; VERIFIED: lib/scoria/sre/relay.ex] |
| Seeded notebook evidence proves rendering only. [VERIFIED: test/scoria_web/live/orchestrator_live_sre_test.exs] | Real incident -> delivery -> relay -> notebook lineage must be proven end-to-end. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md] | Required for Phase 9 verification. [VERIFIED: .planning/milestones/v1.3-REQUIREMENTS.md] | Prevents false positives on SRE-07. [VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md] |

**Deprecated/outdated:**
- Direct approval mutation in `OrchestratorLive` is outdated for this milestone and should be removed from the happy path. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex; VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md]
- Manual seeding of `NotificationDelivery` for the only proof of notebook lineage is outdated as a final acceptance strategy. [VERIFIED: test/scoria/sre/relay_test.exs; VERIFIED: test/scoria_web/live/orchestrator_live_sre_test.exs]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The cleanest Phase 9 implementation can represent `noop` and `unconfigured` transport outcomes in `NotificationDelivery.metadata` rather than widening the schema. [ASSUMED] | Common Pitfalls / Open Questions | Planner may need a migration if explicit first-class statuses are preferred. |
| A2 | The operator-facing approve path can call workflow-owned resume immediately after `approve/3` commits without introducing unacceptable UX blocking, because resume already exists as a callable seam. [ASSUMED] | Pattern 1 / Open Questions | Planner may need to shift resume triggering to a background or pubsub-mediated path if LiveView responsiveness suffers. |

## Resolved Planning Decisions

1. **Post-commit resume ownership** [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md; VERIFIED: lib/scoria/workflows.ex; VERIFIED: lib/scoria/workflows/resume.ex]
   - Decision: the Phase 9 repair should keep resume as a workflow-owned action invoked only after `Scoria.Workflows.approve/3` commits successfully, with the UI delegating to the workflow seam instead of inventing its own continuation logic.
   - Implementation posture: the immediate trigger may still originate from the LiveView event handler for this phase, but the callable seam stays workflow-owned through `Scoria.Workflows.Resume.resume_run/2` or a narrow helper inside the workflow context so the UI remains a delegator rather than a second source of truth.
   - Why this is resolved: D-06 requires the operator path to feel like one action while preserving workflow ownership after commit, and the existing workflow resume seam already supports that contract without requiring a broader architecture change in Phase 9.

2. **Durable encoding for `noop` and `unconfigured` delivery outcomes** [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md; VERIFIED: test/scoria/sre/relay_test.exs]
   - Decision: keep the existing `NotificationDelivery` lifecycle narrow and encode `noop` and `unconfigured` transport semantics in durable metadata attached to the delivery row, alongside routing provenance and outcome summary, unless implementation proves the notebook cannot distinguish them cleanly.
   - Implementation posture: `delivery_status` should remain aligned with the current validated lifecycle, while metadata carries the operator-facing explanation needed for relay tests and notebook drilldowns.
   - Why this is resolved: D-10 requires explicit local evidence instead of silent drops, and metadata is the smallest repo-native change that preserves durable proof without forcing schema churn during a seam-repair phase.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All Phase 9 code and tests | ✓ [VERIFIED: `elixir --version`] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Mix | Dependency and test commands | ✓ [VERIFIED: `mix --version`] | `1.19.5` [VERIFIED: `mix --version`] | — |
| PostgreSQL server | Ecto transactions, relay claiming, focused tests | ✓ [VERIFIED: `pg_isready`] | `14.17` client reported by `psql --version`; local server accepts connections. [VERIFIED: `psql --version`; VERIFIED: `pg_isready`] | — |
| `vector` PostgreSQL extension | Full workspace migrations because knowledge tables depend on pgvector | ✗ [VERIFIED: `psql -d postgres -c "SELECT name, default_version, installed_version FROM pg_available_extensions WHERE name = 'vector';"`] | — | Use focused table bootstrap or phase-scoped test setup instead of full migration-dependent verification. [VERIFIED: .planning/phases/07-seismograph/07-04-SUMMARY.md] |

**Missing dependencies with no fallback:**
- None for the narrow Phase 9 repair path. [VERIFIED: code and command inspection in session]

**Missing dependencies with fallback:**
- The `vector` extension is unavailable locally, so full migration-driven verification remains unreliable; the fallback is the same focused table bootstrap pattern already used in Phase 7 summaries and tests. [VERIFIED: .planning/phases/07-seismograph/07-04-SUMMARY.md; VERIFIED: `psql -d postgres -c "SELECT name, default_version, installed_version FROM pg_available_extensions WHERE name = 'vector';"`]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`. [VERIFIED: `mix --version`; VERIFIED: test file conventions in `test/`] |
| Config file | `test/test_helper.exs`. [VERIFIED: `rg --files test test/support`] |
| Quick run command | `MIX_ENV=test mix test test/scoria/sre/incident_test.exs test/scoria/sre/relay_test.exs test/scoria/workflows/integration_test.exs test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/orchestrator_live_sre_test.exs` [VERIFIED: existing test layout] |
| Full suite command | `MIX_ENV=test mix test` [VERIFIED: Mix convention; VERIFIED: repo test layout] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SRE-05 | LiveView approval/reject uses `Scoria.Workflows.approve/3`, persists audit evidence, and resumes only through workflow-owned logic. [VERIFIED: requirement and code gap] | integration + LiveView | `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria/workflows/integration_test.exs -x` | ✅ existing files need expansion. [VERIFIED: `rg --files test/scoria_web/live test/scoria/workflows`] |
| SRE-06 | `record_alert_event/1` writes incident graph and `NotificationDelivery` rows in one transaction, with dedupe and escalation behavior. [VERIFIED: requirement and code gap] | unit/integration | `MIX_ENV=test mix test test/scoria/sre/incident_test.exs -x` | ✅ existing file needs expansion. [VERIFIED: `rg --files test/scoria/sre`] |
| SRE-07 | Real incident -> delivery -> relay -> operator notebook lineage renders truthfully without seeded placeholders being the only proof. [VERIFIED: requirement and code gap] | integration + LiveView | `MIX_ENV=test mix test test/scoria/sre/relay_test.exs test/scoria_web/live/orchestrator_live_sre_test.exs -x` | ✅ existing files need expansion or one new integration test. [VERIFIED: `rg --files test/scoria/sre test/scoria_web/live`] |

### Sampling Rate
- **Per task commit:** Run the smallest focused command that covers the seam being edited. [VERIFIED: current test file boundaries]
- **Per wave merge:** Run the combined Phase 9 quick suite above. [VERIFIED: current test file boundaries]
- **Phase gate:** Run the combined quick suite plus targeted approval audit tests, and record any remaining unrelated baseline failures explicitly. [VERIFIED: `MIX_ENV=test mix test ...` run on 2026-05-12]

### Wave 0 Gaps
- [ ] Expand `test/scoria_web/live/orchestrator_live_test.exs` so `approve` and `reject` assert `Workflows.approve/3` effects, not just `Approval.status` changes. [VERIFIED: test/scoria_web/live/orchestrator_live_test.exs]
- [ ] Expand `test/scoria/sre/incident_test.exs` to assert delivery-row creation for new incidents and no new delivery for deduped repeats unless routing escalates. [VERIFIED: lib/scoria/sre/incident_manager.ex; VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md]
- [ ] Add one integration path that creates an incident through `IncidentManager`, drains relay, and then loads the notebook evidence from LiveView without direct DB seeding of the delivery row. [VERIFIED: test/scoria/sre/relay_test.exs; VERIFIED: test/scoria_web/live/orchestrator_live_sre_test.exs]
- [ ] Resolve or isolate the existing `AuditOutboxEvent` unique-constraint naming mismatch so focused approval durability tests are trustworthy during Phase 9 work. [VERIFIED: lib/scoria/sre/audit_outbox_event.ex; VERIFIED: test/scoria/sre/audit_outbox_test.exs; VERIFIED: `MIX_ENV=test mix test ...` run on 2026-05-12]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Carry operator identity through `actor_id`/`actor_ref` on approval and incident evidence so actions remain attributable. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md; VERIFIED: lib/scoria/workflows.ex; VERIFIED: lib/scoria/sre/incident_manager.ex] |
| V3 Session Management | no | Phase 9 does not introduce new session primitives; it stays inside existing LiveView session handling. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] |
| V4 Access Control | yes | Approval mutation must stay behind workflow-owned actions rather than arbitrary row updates, reducing unauthorized or unaudited state changes. [VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md; VERIFIED: lib/scoria_web/live/orchestrator_live.ex; VERIFIED: lib/scoria/workflows.ex] |
| V5 Input Validation | yes | Continue validating approval, incident, audit, and delivery rows through Ecto changesets and constrained status vocabularies. [VERIFIED: lib/scoria/observe/approval.ex; VERIFIED: lib/scoria/sre/notification_delivery.ex; VERIFIED: lib/scoria/sre/audit_outbox_event.ex] |
| V6 Cryptography | yes | Preserve existing payload hashing and redacted refs at the audit/delivery evidence boundary; do not hand-roll new crypto semantics in this phase. [VERIFIED: lib/scoria/sre.ex; VERIFIED: test/scoria/sre/audit_outbox_test.exs] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized approval mutation from UI code | Tampering / Repudiation | Route through `Scoria.Workflows.approve/3` and persist actor/tenant/trace context in the same transaction as approval truth. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md; VERIFIED: lib/scoria/workflows.ex] |
| Lost incident notifications after crash or rollback | Repudiation / Availability | Create `NotificationDelivery` rows transactionally with incident graph changes, then let relay dispatch after commit. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md; VERIFIED: lib/scoria/sre/relay.ex; CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Duplicate pages on deduped repeats | Denial of Service | Reuse stable incident keys and only create new deliveries on first open or escalation to `page`. [VERIFIED: .planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md; VERIFIED: lib/scoria/sre/incident_manager.ex] |
| Sensitive payload leakage into operator notebook | Information Disclosure | Keep redaction at audit boundaries and show evidence refs, statuses, and lineage rather than raw payload bodies by default. [VERIFIED: lib/scoria/sre.ex; VERIFIED: test/scoria/sre/audit_outbox_test.exs; VERIFIED: lib/scoria_web/components/incident_evidence_component.ex] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md` - locked decisions, scope, and deferred boundaries. [VERIFIED: local file]
- `.planning/milestones/v1.3-REQUIREMENTS.md` - requirement IDs and milestone traceability. [VERIFIED: local file]
- `.planning/v1.3-MILESTONE-AUDIT.md` - exact failure evidence for SRE-05, SRE-06, and SRE-07. [VERIFIED: local file]
- `lib/scoria/workflows.ex` - existing approval mutation and resume seams. [VERIFIED: local file]
- `lib/scoria/sre/incident_manager.ex` - current incident routing behavior and missing delivery production. [VERIFIED: local file]
- `lib/scoria/sre/notification_delivery.ex` - durable delivery schema and status vocabulary. [VERIFIED: local file]
- `lib/scoria/sre/relay.ex` - post-commit claim/deliver/retry runtime. [VERIFIED: local file]
- `lib/scoria_web/live/orchestrator_live.ex` - current approval bypass and lazy notebook loading pattern. [VERIFIED: local file]
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - transactional multi-step write pattern. [CITED]
- `https://hexdocs.pm/ecto/Ecto.Changeset.html` - `unique_constraint/3` and optimistic locking behavior. [CITED]
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html` - `assign_async/3` and async result behavior. [CITED]
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html` - `render_async/2` for deterministic async testing. [CITED]

### Secondary (MEDIUM confidence)
- `mix hex.info phoenix_live_view` - current package version and release date. [VERIFIED: local command]
- `mix hex.info phoenix` - current package version and release date. [VERIFIED: local command]
- `mix hex.info ecto_sql` - current package version and release date. [VERIFIED: local command]
- `mix hex.info postgrex` - current package version and release date. [VERIFIED: local command]
- `mix hex.info phoenix_html` - current package version and release date. [VERIFIED: local command]
- `mix hex.info pgvector` - current package version and release date. [VERIFIED: local command]

### Tertiary (LOW confidence)
- None. Low-confidence claims are isolated in the Assumptions Log instead of being presented as authoritative facts. [VERIFIED: this document]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Versions were verified live from Hex and the phase uses existing framework seams rather than speculative new tooling. [VERIFIED: mix hex.info phoenix phoenix_live_view ecto_sql postgrex phoenix_html pgvector]
- Architecture: HIGH - The key repair targets are directly observable in repo code and the milestone audit. [VERIFIED: lib/scoria/workflows.ex; VERIFIED: lib/scoria/sre/incident_manager.ex; VERIFIED: lib/scoria_web/live/orchestrator_live.ex; VERIFIED: .planning/v1.3-MILESTONE-AUDIT.md]
- Pitfalls: MEDIUM - Most are code-backed, but the exact durable encoding of noop/unconfigured outcomes remains a discretionary implementation detail. [VERIFIED: test/scoria/sre/relay_test.exs; ASSUMED]

**Research date:** 2026-05-12 [VERIFIED: system date]
**Valid until:** 2026-06-11 for repo-local architecture and 2026-05-19 for package-version currency. [ASSUMED]
