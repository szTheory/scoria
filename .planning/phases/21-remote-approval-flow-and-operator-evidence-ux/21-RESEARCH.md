# Phase 21: Remote Approval Flow and Operator Evidence UX - Research

**Researched:** 2026-05-18 [VERIFIED: repo workspace]
**Domain:** Remote connector approval orchestration, operator evidence projection, and dashboard UX in Phoenix LiveView [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: repo review]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Remote approvals should live in a first-class `Approvals Inbox` inside Scoria's embedded dashboard, not only as inline run modals and not primarily inside connector settings. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-02:** The approvals inbox is the canonical operator triage surface for pending remote write, exec, and scope-escalation decisions. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-03:** Run pages and connector detail views should project approval state read-through, but approval truth remains workflow-owned and durable in Ecto rows. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-04:** The current inline modal pattern is acceptable as a local projection or interrupt affordance, but it is not the primary home of remote approval review in the final Phase 21 shape. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-05:** Host-app-facing approval cards are not the core product posture for this phase. They may become an optional extension later, but the embedded operator dashboard is the default Scoria approval surface. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-06:** The primary connector UX should be a fleet table with detail drawer or equivalent scan-first surface, not a connector-event notebook as the top-level IA. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-07:** Operators should be able to scan current connector health, auth/grant state, granted scopes, last refresh status, last good refresh, and pending local-tool adoption state in one compact fleet view. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-08:** The detail drawer should provide the deeper evidence strip for one connector: auth metadata provenance, refresh history summary, scope challenges, pending approvals, and links into exact run/evidence records. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-09:** Connector detail should stay operational and inspectable without feeling like a hosted connector platform. The product center of gravity remains embedded governance, not connector fleet productization. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-10:** Capability refresh should be presented as the latest durable snapshot plus refresh history/evidence, not as a magically live remote truth feed. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-11:** Remote invocation evidence should be presented as a run-centric evidence notebook with a lineage/timeline-first default. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-12:** The default reading order for one remote invocation should be canonical identity and run/step context -> local policy outcome -> approval request/decision lineage -> connector/grant/scope context -> redacted request/response summaries -> replay or follow-on outcome. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-13:** Payload/policy summaries should be secondary panels inside the evidence notebook, not the default top-level IA. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-14:** Connector posture should appear as contextual side information in the invocation evidence view, not as the primary frame for understanding one blocked or approved run. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-15:** Telemetry must remain low-cardinality. Metrics should use stable outcome categories, risk buckets, connector/profile identifiers, and event types, while exact details are recovered through durable record links rather than high-cardinality labels. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-16:** Approval semantics should stay narrow and workflow-owned: an approval answers whether a blocked write, exec, or escalation may proceed. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-17:** Connector maintenance and recovery actions should exist around approvals as typed remediation actions, not as overloaded approval statuses. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-18:** Operators should be able to take the following typed actions when relevant: `approve`, `reject`, `re-auth`, `sync/refresh`, `request scope escalation`, `adopt pending tool`, `replay blocked step`. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-19:** Action availability must be eligibility-driven by the durable blocked outcome. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-20:** `approve and mutate everything` is explicitly the wrong model. Approval rows must not become a generic command bus for arbitrary connector state changes. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-21:** Auto-resume after remediation is not the default. Recovery should produce a fresh durable event/evidence record, then replay or resume explicitly through workflow-owned seams. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-22:** Low-impact decisions should be shifted left into Scoria defaults instead of surfaced for operator choice. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-23:** Human interruption should be reserved for materially impactful moments: remote writes/exec, scope widening, pending tool adoption after catalog drift, and ambiguous or high-risk connector recovery paths. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-24:** The product should copy the best permission-widening lessons from GitHub/Slack-style ecosystems: existing power remains stable, new power requires explicit review, and the UI should explain what changed and why. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md] [CITED: https://docs.github.com/en/enterprise-cloud@latest/apps/maintaining-github-apps/modifying-a-github-app-registration]
- **D-25:** The product should copy the best HITL lessons from durable workflow systems like LangGraph: exact state is persisted before waiting, and resumption depends on durable state rather than transient UI coordination. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md] [CITED: https://docs.langchain.com/oss/python/langgraph/interrupts]
- **D-26:** The coherent Phase 21 operator workflow is the connector dashboard as state surface, the approvals inbox as risk surface, and the run-centric evidence notebook as truth surface. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-27:** Operators should start from the blocked run or inbox item, inspect the typed blocker, jump to connector details if needed, perform the smallest eligible remediation, return to evidence, then approve and replay or reject. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **D-28:** Cross-links between these surfaces are mandatory. Every approval, blocked invocation, grant challenge, and replay should link to the exact connector, run, step, approval, and audit evidence rows involved. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]

### Claude's Discretion
- Exact LiveView routing, whether the inbox/drawer live inside the existing `OrchestratorLive` or adjacent LiveViews, provided the product still presents one obvious embedded dashboard path. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- Exact query/projection modules and presenter boundaries, provided Ecto rows remain truth and LiveView remains projection. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- Exact badge copy, timeline grouping, and tab/drawer composition, provided the IA remains scan-first for connectors and lineage-first for invocation evidence. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- Exact typed remediation schema/module names, provided approval decisions and connector maintenance actions remain separate durable concepts. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)
- Host-app-facing approval cards or end-user embedded approval UX outside the Scoria operator dashboard. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- Rich approval editing flows that let operators rewrite payloads or arguments inline before replay. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- Hosted-style connector fleet operations, assignment-heavy ops workflows, or marketplace-like connector admin breadth. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- Broader profile/install ergonomics and curated connector adoption polish. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- Stateful session-heavy remote connector UX beyond the stateless-first milestone center. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `POLI-03` | Remote write, exec, or scope-escalation paths require workflow-owned approval handling instead of ad hoc UI mutations. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse `Scoria.Workflows.mark_waiting_for_approval/3`, `approve/3`, and `resume_run/1`, but add connector-aware approval payload/projection fields rather than inventing a second approval state machine. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: lib/scoria/connectors/invocation.ex] |
| `EVID-01` | Operators can inspect connector health, granted scopes, and last capability refresh through the embedded Scoria dashboard. [VERIFIED: .planning/REQUIREMENTS.md] | Build a fleet query over `Connector`, `Grant`, `CapabilitySnapshot`, and `LocalTool` state and project it into a scan-first LiveView table plus detail drawer. [VERIFIED: lib/scoria/connectors.ex] [VERIFIED: lib/scoria/connectors/connector.ex] [VERIFIED: lib/scoria/connectors/grant.ex] [VERIFIED: lib/scoria/connectors/capability_snapshot.ex] |
| `EVID-02` | Operators can review remote invocation evidence including actor/session identity, policy outcome, approval lineage, and redacted request/response summaries. [VERIFIED: .planning/REQUIREMENTS.md] | Join workflow events, audit outbox rows, approvals, local tools, grants, and connector rows into a run-centric evidence notebook that follows the locked reading order. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: lib/scoria/connectors/auth.ex] [VERIFIED: lib/scoria_web/components/incident_evidence_component.ex] |
| `EVID-03` | Telemetry and durable evidence preserve low-cardinality metrics while still linking operators to exact connector, approval, and invocation records. [VERIFIED: .planning/REQUIREMENTS.md] | Keep labels in `Scoria.SRE.TelemetryIdentity` stable and put exact IDs in durable rows and deep-link projections rather than in metric label space. [VERIFIED: lib/scoria/sre/telemetry_identity.ex] [VERIFIED: lib/scoria/sre.ex] |
</phase_requirements>

## Summary

Phase 21 should not introduce new runtime truth; it should enrich and project truth that already exists across `Scoria.Workflows`, `Scoria.Connectors`, `Scoria.Connectors.Auth`, `Scoria.Connectors.Invocation`, and `Scoria.SRE.AuditOutboxEvent`. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: lib/scoria/connectors.ex] [VERIFIED: lib/scoria/connectors/auth.ex] [VERIFIED: lib/scoria/connectors/invocation.ex] [VERIFIED: lib/scoria/sre/audit_outbox_event.ex] The main gap is that current approval rows only persist `tool_name`, `arguments`, and workflow identity, while connector-specific lineage mostly lives in workflow-event payloads and audit metadata. [VERIFIED: lib/scoria/observe/approval.ex] [VERIFIED: lib/scoria/connectors/auth.ex]

The planning center of gravity is therefore projection and seam enrichment, not greenfield workflow design. [VERIFIED: repo review] Phase 20 already fail-closes remote invocation with `:auth_required`, `:scope_escalation_required`, `:policy_denied`, and `:tool_unavailable`, and it records durable workflow/audit evidence before outbound execution. [VERIFIED: lib/scoria/connectors/invocation.ex] [VERIFIED: test/scoria/connectors/invocation_test.exs] Phase 21 should turn those outcomes into a first-class approvals inbox, connector fleet dashboard, and run-centric remote evidence notebook with explicit typed remediation actions around approval, not inside approval. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]

The existing inline LiveView modal is a working interrupt affordance but not the final information architecture. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] The strongest repo-local pattern to reuse is `IncidentEvidenceComponent`: compact rollup first, deep notebook below, and durable IDs projected as link targets rather than volatile UI state. [VERIFIED: lib/scoria_web/components/incident_evidence_component.ex] External guidance only sharpens two locked choices: permission widening should preserve existing access until explicitly re-approved, and human-interrupt flows should persist exact state before waiting and resume from durable state instead of UI-local coordination. [CITED: https://docs.github.com/en/enterprise-cloud@latest/apps/maintaining-github-apps/modifying-a-github-app-registration] [CITED: https://docs.langchain.com/oss/python/langgraph/interrupts]

**Primary recommendation:** Split Phase 21 into four plans: connector-aware approval truth/projections first, operator fleet and inbox UX second, typed remediation plus backend evidence projection third, and the run-centric remote evidence notebook plus low-cardinality telemetry linkage fourth. [VERIFIED: repo review]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Workflow-owned remote approval truth | API / Backend [VERIFIED: lib/scoria/workflows.ex] | Database / Storage [VERIFIED: lib/scoria/observe/approval.ex] | Approval creation, decision, and resume must stay transactional and durable, not LiveView-owned. [VERIFIED: lib/scoria/workflows.ex] |
| Connector fleet state rollup | API / Backend [VERIFIED: lib/scoria/connectors.ex] | Database / Storage [VERIFIED: lib/scoria/connectors/connector.ex] | The fleet view is a projection over connector, grant, snapshot, and local-tool rows. [VERIFIED: lib/scoria/connectors/grant.ex] [VERIFIED: lib/scoria/connectors/capability_snapshot.ex] [VERIFIED: lib/scoria/connectors/local_tool.ex] |
| Approvals inbox and drawer UI | Frontend Server (SSR) [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] | API / Backend [VERIFIED: lib/scoria/workflows.ex] | LiveView should render pending work and invoke typed backend actions, but it must not become the source of approval truth. [VERIFIED: .planning/PROJECT.md] |
| Run-centric remote evidence notebook | Frontend Server (SSR) [VERIFIED: lib/scoria_web/components/incident_evidence_component.ex] | API / Backend [VERIFIED: lib/scoria/sre.ex] | The notebook is a read model stitched from backend evidence rows, then rendered as operator-first IA. [VERIFIED: lib/scoria/workflows.ex] |
| Connector maintenance/remediation actions | API / Backend [VERIFIED: lib/scoria/connectors.ex] | Frontend Server (SSR) [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] | `re-auth`, `sync/refresh`, `adopt pending tool`, and `replay blocked step` are backend commands exposed via dashboard controls. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md] |
| Low-cardinality telemetry | API / Backend [VERIFIED: lib/scoria/sre/telemetry_identity.ex] | Database / Storage [VERIFIED: lib/scoria/sre/audit_outbox_event.ex] | Metrics should emit stable labels; exact connector, approval, and invocation identifiers belong in durable evidence and links. [VERIFIED: lib/scoria/sre.ex] |

## Recommended Plan Decomposition

| Plan | Scope | Depends On | Why First |
|------|-------|------------|-----------|
| `21-01` | Enrich remote approval truth and projection queries. [VERIFIED: repo review] | Phase 20 only. [VERIFIED: .planning/ROADMAP.md] | Inbox, connector drawer, and evidence notebook all need connector-aware approval lineage and a reusable query layer first. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: lib/scoria/observe/approval.ex] |
| `21-02` | Build the operator approvals inbox plus connector fleet table/detail drawer. [VERIFIED: repo review] | `21-01`. [VERIFIED: repo review] | The locked IA says dashboard risk/state surfaces are primary, and they depend on the shared projections from `21-01`. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md] |
| `21-03` | Add typed remediation actions and backend remote evidence projections. [VERIFIED: repo review] | `21-01`. [VERIFIED: repo review] | The workflow and connector seams for replay/remediation should settle before the notebook UI and telemetry verification depend on them. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md] |
| `21-04` | Build the run-centric remote evidence notebook and verify low-cardinality telemetry linkage. [VERIFIED: repo review] | `21-03`; may reuse UI shell patterns from `21-02`. [VERIFIED: repo review] | The notebook is safest once backend evidence projection and remediation semantics already exist. [VERIFIED: repo review] |

**Recommended dependency graph:** `21-01` -> `21-02`; `21-01` -> `21-03`; `21-03` -> `21-04`; `21-04` may reuse navigation shells from `21-02` but should not block on visual polish. [VERIFIED: repo review]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | `1.8.7` [VERIFIED: mix.lock] | Embedded dashboard routing and LiveView host surface. [VERIFIED: mix.exs] | Phase 21 is explicitly an embedded Phoenix operator surface, not a separate app. [VERIFIED: .planning/PROJECT.md] |
| `phoenix_live_view` | `1.1.30` [VERIFIED: mix.lock] | Inbox, fleet table, drawer, and evidence notebook projections. [VERIFIED: mix.lock] | Current operator UX already lives in `OrchestratorLive` and should stay LiveView-based. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] |
| `ecto_sql` | `3.13.5` [VERIFIED: mix.lock] | Durable approval, connector, grant, snapshot, and audit joins. [VERIFIED: mix.lock] | The phase extends durable truth rather than adding process-local caches. [VERIFIED: .planning/PROJECT.md] |
| `oban` | `2.22.1` [VERIFIED: mix.lock] | Existing connector refresh/reconciliation jobs that the UI must surface. [VERIFIED: mix.lock] | Refresh history and pending adoption state already emerge from Oban-backed discovery. [VERIFIED: lib/scoria/connectors/discovery.ex] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `cloak_ecto` | `1.3.0` [VERIFIED: mix.lock] | Encrypted grant secret storage. [VERIFIED: lib/scoria/connectors/grant.ex] | Keep using it whenever evidence views reference grant state; do not surface raw tokens in UI models. [VERIFIED: lib/scoria/connectors/grant.ex] |
| `phoenix_live_dashboard` | `0.8.7` [CITED: https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html] | Ecosystem precedent for embedded operator routing and additional dashboard pages. [CITED: https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html] | Use as IA guidance only; Phase 21 can stay inside `OrchestratorLive` or adjacent LiveViews. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Workflow-backed approval lineage [VERIFIED: lib/scoria/workflows.ex] | A connector-specific approval table [ASSUMED] | Reject this unless the existing approval row proves irreparably narrow, because it would fork the durable interrupt/resume model. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: lib/scoria/observe/approval.ex] |
| One embedded dashboard path [VERIFIED: .planning/PROJECT.md] | A dedicated hosted-style connector admin surface [ASSUMED] | Reject this for v1.5 because it violates the milestone’s embedded Phoenix-first boundary. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/MILESTONE-ARC.md] |

**Installation:** No new dependency is required for the recommended Phase 21 path. [VERIFIED: mix.exs]

```bash
mix deps.get
```

## Architecture Patterns

### System Architecture Diagram

```text
remote invocation request
  -> Scoria.Connectors.Invocation preflight
     -> local tool lifecycle check
     -> local policy check
     -> grant/scope check
        -> auth missing/expired
           -> Auth.record_remote_auth_failure
           -> workflow event + audit outbox evidence
           -> approval inbox item / remediation candidate
        -> scope widening required
           -> Auth.record_scope_escalation
           -> workflow event + audit outbox evidence
           -> approval inbox item / remediation candidate
        -> allowed
           -> MCP.Executor.execute
           -> tool invocation evidence

operator dashboard
  -> approvals inbox query
     -> approvals + request/decision audit rows + run/step/local tool/connector refs
  -> connector fleet query
     -> connector + latest grant + latest snapshot + pending local tool state
  -> run evidence notebook query
     -> run + step + workflow events + approvals + audit rows + connector/grant/local tool context

operator action
  -> approve/reject via Scoria.Workflows
  -> re-auth/sync/adopt/replay via typed connector/workflow APIs
  -> fresh evidence row recorded
  -> explicit replay/resume
```

### Recommended Project Structure

```text
lib/scoria/
├── workflows/
│   └── remote_approval_projection.ex      # inbox + lineage query helpers
├── connectors/
│   ├── operator_projection.ex             # fleet table + drawer read models
│   ├── remediation.ex                     # typed non-approval actions
│   └── evidence_projection.ex             # connector/grant/local-tool evidence joins
lib/scoria_web/
├── live/
│   ├── orchestrator_live.ex               # keep interrupt affordance + cross-links
│   ├── approvals_inbox_live.ex            # optional split if OrchestratorLive becomes overloaded
│   └── connectors_live.ex                 # optional fleet view split
└── components/
    ├── incident_evidence_component.ex     # reuse pattern
    └── remote_invocation_evidence_component.ex
```

### Pattern 1: Workflow-Owned Approval Gate
**What:** Keep approval request, decision, and resume inside `Scoria.Workflows`, and project connector context into that durable path instead of branching around it. [VERIFIED: lib/scoria/workflows.ex]  
**When to use:** For remote `write`, `exec`, scope-escalation, and pending-tool adoption decisions that materially affect blast radius. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]  
**Example:**

```elixir
# Source: lib/scoria/workflows.ex
approval =
  %Approval{}
  |> Approval.changeset(approval_attrs)
  |> repo.insert!()

audit_outbox_event =
  SRE.insert_audit_outbox_event(repo, %{
    event_type: "approval.requested",
    workflow_run_id: run.id,
    step_id: step.id,
    approval_id: approval.id
  })
```

### Pattern 2: Typed Blocker -> Typed Remediation
**What:** Treat remote blocked outcomes as typed evidence that drives eligible actions around the approval, not as overloaded approval statuses. [VERIFIED: lib/scoria/connectors/invocation.ex] [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]  
**When to use:** On inbox rows, connector drawer actions, and run notebook callouts. [VERIFIED: repo review]  
**Example:**

```elixir
# Source: lib/scoria/connectors/invocation.ex
{:error,
 %{
   status: :scope_escalation_required,
   connector_id: connector.id,
   local_tool_id: local_tool.id,
   missing_scopes: missing_scopes,
   audit_outbox_event_id: evidence.audit_outbox_event.id,
   workflow_event_id: evidence.workflow_event_id
 }}
```

### Pattern 3: Evidence Notebook from Durable Rows
**What:** Follow the `IncidentEvidenceComponent` pattern: compact summary cards first, timeline/notebook detail below, and durable IDs used as link targets. [VERIFIED: lib/scoria_web/components/incident_evidence_component.ex]  
**When to use:** For the run-centric remote evidence surface. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]  

### Anti-Patterns to Avoid

- **Approval row as command bus:** Do not add statuses like `reauthed`, `synced`, or `adopted`; keep those as separate typed actions with their own evidence rows. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- **LiveView-owned approval truth:** The current modal calls `Workflows.approve/3` and `Resume.resume_run/1`; Phase 21 should preserve that direction and only expand projection. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] [VERIFIED: lib/scoria/workflows.ex]
- **Metric labels with exact IDs:** `TelemetryIdentity` keeps labels intentionally low-cardinality; do not push connector IDs, approval IDs, or invocation IDs into labels. [VERIFIED: lib/scoria/sre/telemetry_identity.ex]
- **Blob-first evidence pages:** Default to lineage and outcomes first, with redacted payload panels secondary. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]

## Repo-Local Seams to Reuse

- `Scoria.Workflows.mark_waiting_for_approval/3`, `approve/3`, and `resume_run/1` already implement the durable interrupt/resume spine. [VERIFIED: lib/scoria/workflows.ex]
- `Scoria.Connectors.Invocation.invoke/5` already emits connector-aware blocked envelopes with `local_tool_id`, `connector_id`, and evidence refs. [VERIFIED: lib/scoria/connectors/invocation.ex]
- `Scoria.Connectors.Auth.record_remote_auth_failure/5` and `record_scope_escalation/5` already create workflow events plus redacted audit rows. [VERIFIED: lib/scoria/connectors/auth.ex]
- `Scoria.Connectors.list_connectors/1` already preloads `capability_snapshot` and `local_tools: :aliases`, which is the right starting point for the fleet table. [VERIFIED: lib/scoria/connectors.ex]
- `Scoria.Connectors.Discovery.refresh_connector/2` already produces refresh evidence that includes pending and removed local tool outcomes, which Phase 21 should surface rather than recompute in LiveView. [VERIFIED: lib/scoria/connectors/discovery.ex]
- `ScoriaWeb.IncidentEvidenceComponent` already demonstrates the operator-grade rollup + notebook pattern the remote evidence page should mirror. [VERIFIED: lib/scoria_web/components/incident_evidence_component.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Remote approval state machine | A connector-only approval subsystem [ASSUMED] | `Scoria.Workflows` approval lifecycle. [VERIFIED: lib/scoria/workflows.ex] | The repo already persists approval request, decision, and resume lineage durably. [VERIFIED: lib/scoria/workflows.ex] |
| Connector fleet health cache | Socket-local connector state [ASSUMED] | Query projections over connector/grant/snapshot/local-tool rows. [VERIFIED: lib/scoria/connectors.ex] | Health, scopes, and refresh state already live durably. [VERIFIED: lib/scoria/connectors/connector.ex] [VERIFIED: lib/scoria/connectors/grant.ex] [VERIFIED: lib/scoria/connectors/capability_snapshot.ex] |
| Permission-widening policy | Silent auto-upgrade on new scopes [ASSUMED] | Explicit approval/remediation flow that preserves prior power until review. [CITED: https://docs.github.com/en/enterprise-cloud@latest/apps/maintaining-github-apps/modifying-a-github-app-registration] | This matches the locked UX posture and avoids surprising operators. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md] |
| Interrupt coordination | Browser-local resume sequencing [ASSUMED] | Durable workflow state then explicit resume/replay call. [VERIFIED: lib/scoria/workflows.ex] [CITED: https://docs.langchain.com/oss/python/langgraph/interrupts] | Durable resume is already Scoria’s workflow posture. [VERIFIED: lib/scoria/workflows.ex] |

**Key insight:** The hard part is not “adding a modal” or “showing connector rows”; it is preserving one durable causal chain from blocked invocation -> approval/remediation -> replay/resume without breaking low-cardinality telemetry or embedded product shape. [VERIFIED: repo review]

## Key Risks

### Risk 1: Approval schema is too thin for connector-native inbox queries
`ai_approvals` currently stores `tool_name`, `arguments`, status, actor/tenant/session, and workflow refs, but not `connector_id`, `local_tool_id`, or blocker type. [VERIFIED: lib/scoria/observe/approval.ex] If Phase 21 leaves that unchanged, inbox and notebook queries will over-rely on audit JSON lookups and repeated joins through `approval.requested` events. [VERIFIED: lib/scoria/workflows.ex]  
**Proof lane:** Spike whether adding explicit connector-facing columns to `Approval` is warranted or whether a projection table/view module is enough. [VERIFIED: repo review]

### Risk 2: Typed remediation can collapse back into ad hoc LiveView mutations
`OrchestratorLive` currently approves/rejects and auto-resumes approved runs directly from the modal path. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] Adding `re-auth`, `sync`, `adopt`, or `replay` buttons without backend command seams would reintroduce hidden mutable UI state. [VERIFIED: .planning/PROJECT.md]  
**Proof lane:** Require one backend function per remediation class and assert fresh evidence rows for each action. [VERIFIED: repo review]

### Risk 3: Telemetry cardinality creep
`TelemetryIdentity` excludes exact connector/approval IDs from labels on purpose. [VERIFIED: lib/scoria/sre/telemetry_identity.ex] A naive Phase 21 implementation could add IDs or scope lists into metric labels instead of durable evidence metadata. [VERIFIED: lib/scoria/sre.ex]  
**Proof lane:** Add tests or assertions that remote approval telemetry emits stable `integration_kind`, `policy_key`, `reason_code`, and outcome labels only. [VERIFIED: repo review]

## Proof Lanes and Verification Commands

| Lane | Command | Purpose | Current Status |
|------|---------|---------|----------------|
| Targeted connector invocation evidence | `mix test test/scoria/connectors/invocation_test.exs` [VERIFIED: test/scoria/connectors/invocation_test.exs] | Guards auth failure, scope escalation, and tool-unavailable evidence lineage. [VERIFIED: test/scoria/connectors/invocation_test.exs] | Blocked in this shell by compile-time/runtime repo-config mismatch on PostgreSQL port `55432` vs `5432`. [VERIFIED: mix test test/scoria/connectors/invocation_test.exs test/scoria_web/live/orchestrator_live_test.exs] |
| Targeted LiveView operator UX | `mix test test/scoria_web/live/orchestrator_live_test.exs` [VERIFIED: test/scoria_web/live/orchestrator_live_test.exs] | Guards approval modal behavior and current evidence loading patterns. [VERIFIED: test/scoria_web/live/orchestrator_live_test.exs] | Same environment blocker. [VERIFIED: mix test test/scoria/connectors/invocation_test.exs test/scoria_web/live/orchestrator_live_test.exs] |
| Full phase lane | `mix test` [ASSUMED] | Catch projection/query regressions across workflows, SRE, and connectors. [VERIFIED: mix.exs] | Likely blocked until repo config mismatch is reconciled. [VERIFIED: mix test test/scoria/connectors/invocation_test.exs test/scoria_web/live/orchestrator_live_test.exs] |

## Common Pitfalls

### Pitfall 1: Treating approval as the remediation itself
**What goes wrong:** Operators click “approve” expecting Scoria to silently re-auth, refresh scopes, adopt tools, and resume everything. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]  
**How to avoid:** Keep approval narrow and expose remediation as separate typed actions with their own evidence rows. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]

### Pitfall 2: Building the inbox from transient UI messages
**What goes wrong:** The current `{:hitl_request, approval}` message path becomes the pseudo-source of inbox truth. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex]  
**How to avoid:** Drive inbox rows from durable `Approval` plus linked audit/workflow evidence and treat socket messages as optional real-time refresh only. [VERIFIED: lib/scoria/workflows.ex]

### Pitfall 3: Surfacing connector “live truth” instead of durable snapshot truth
**What goes wrong:** The dashboard implies a real-time remote control plane instead of showing last known durable health and refresh evidence. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]  
**How to avoid:** Present `last_refresh_status`, `last_good_refresh_at`, pending local-tool outcomes, and links to refresh evidence, not a magical live feed. [VERIFIED: lib/scoria/connectors/connector.ex] [VERIFIED: lib/scoria/connectors/discovery.ex]

## Code Examples

### Durable approval request write path
```elixir
# Source: lib/scoria/workflows.ex
updated_run =
  repo.update!(Run.changeset(run, %{status: "waiting_for_approval", current_step_id: step.id}))

approval =
  %Approval{}
  |> Approval.changeset(%{
    workflow_run_id: run.id,
    step_id: step.id,
    checkpoint_id: checkpoint.id,
    status: "pending"
  })
  |> repo.insert!()
```

### Connector auth/scope blocker evidence
```elixir
# Source: lib/scoria/connectors/auth.ex
with {:ok, workflow_event_id} <- maybe_record_workflow_event(event_type, context, payload),
     {:ok, audit_outbox_event} <- SRE.create_audit_outbox_event(%{
       workflow_run_id: context["run_id"],
       step_id: context["step_id"],
       event_type: event_type,
       reason_code: reason_code
     }) do
  {:ok, %{workflow_event_id: workflow_event_id, audit_outbox_event: audit_outbox_event}}
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Inline modal as primary approval UX [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] | Inbox-first operator review with run/connector projections. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md] | Locked in Phase 21 context on 2026-05-17. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md] | Planning should center on list/detail read models, not modal polish. [VERIFIED: repo review] |
| Implicit permission widening [ASSUMED] | Existing access stays stable; new access requires explicit approval. [CITED: https://docs.github.com/en/enterprise-cloud@latest/apps/maintaining-github-apps/modifying-a-github-app-registration] | Current GitHub docs as opened on 2026-05-18. [CITED: https://docs.github.com/en/enterprise-cloud@latest/apps/maintaining-github-apps/modifying-a-github-app-registration] | Scope-escalation UX should explain “what changed” and preserve last approved state. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md] |
| UI-coordinated HITL resume [ASSUMED] | Persist exact state before waiting, then resume from durable state. [CITED: https://docs.langchain.com/oss/python/langgraph/interrupts] | Current LangGraph interrupts docs as opened on 2026-05-18. [CITED: https://docs.langchain.com/oss/python/langgraph/interrupts] | Scoria should keep `Workflows` as the resume source of truth. [VERIFIED: lib/scoria/workflows.ex] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A connector-specific approval table is a plausible alternative shape. [ASSUMED] | Standard Stack -> Alternatives Considered | Low risk; the recommendation still prefers the existing workflow approval spine. [VERIFIED: lib/scoria/workflows.ex] |
| A2 | A dedicated hosted-style connector admin surface is a plausible alternative shape. [ASSUMED] | Standard Stack -> Alternatives Considered | Low risk; milestone constraints already rule it out. [VERIFIED: .planning/PROJECT.md] |
| A3 | A connector-only approval subsystem is the likely hand-rolled failure mode if Phase 21 drifts. [ASSUMED] | Don't Hand-Roll | Low risk; the mitigation is still to reuse `Scoria.Workflows`. [VERIFIED: lib/scoria/workflows.ex] |
| A4 | Socket-local connector fleet state is the likely hand-rolled failure mode if projection seams are skipped. [ASSUMED] | Don't Hand-Roll | Medium risk; if wrong, the planner still needs a backend projection layer. [VERIFIED: lib/scoria/connectors.ex] |
| A5 | Docker may be part of the local DB alignment path on this machine. [ASSUMED] | Environment Availability | Low risk; Phase 21 code work does not depend on Docker directly. [VERIFIED: `docker --version`] |

## Resolved Planning Decisions

1. **`ai_approvals` should gain explicit connector-facing lineage columns in `21-01`.** [VERIFIED: lib/scoria/observe/approval.ex]
   Resolution: Phase 21 should add explicit approval fields for the durable nouns the inbox and notebook must query repeatedly, including `connector_id`, `local_tool_id`, blocker kind, and exact evidence refs needed for workflow-owned replay/read-through. [VERIFIED: lib/scoria/observe/approval.ex] [VERIFIED: lib/scoria/connectors/auth.ex]
   Why: keeping that context only in audit/workflow JSON would force every dashboard path to reconstruct core approval truth from indirect evidence joins, which is exactly the failure mode the checker flagged. [VERIFIED: repo review]
   Planning implication: `21-01` must include a migration, approval-schema update, and tests proving remote write/exec plus auth/scope blockers create workflow-owned approvals with connector-aware lineage. [VERIFIED: repo review]

2. **Phase 21 should stay inside `OrchestratorLive` by default, with extraction optional later.** [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
   Resolution: the approvals inbox and connector fleet/drawer should land in `OrchestratorLive` during `21-02`, using extracted components and projection modules so a later route split remains possible without changing durable truth or backend seams. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex]
   Why: the context explicitly prefers one obvious embedded dashboard path, and the repo already uses `OrchestratorLive` as the interrupt/triage shell. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md] [VERIFIED: lib/scoria_web/live/orchestrator_live.ex]
   Planning implication: Phase 21 should invest in projection boundaries and components first, not new route topology. Any LiveView split is deferred unless execution proves `OrchestratorLive` becomes unmaintainable. [VERIFIED: repo review]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Build and test lane. [VERIFIED: mix.exs] | ✓ [VERIFIED: `elixir --version`] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Mix | Build and test lane. [VERIFIED: mix.exs] | ✓ [VERIFIED: `mix --version`] | `1.19.5` [VERIFIED: `mix --version`] | — |
| PostgreSQL client | Investigating test/runtime DB posture. [VERIFIED: repo review] | ✓ [VERIFIED: `psql --version`] | `14.17` [VERIFIED: `psql --version`] | — |
| Docker | Likely used to align local DB services. [ASSUMED] | ✓ [VERIFIED: `docker --version`] | `29.4.1` [VERIFIED: `docker --version`] | — |

**Missing dependencies with no fallback:** None found. [VERIFIED: environment probe]

**Missing dependencies with fallback:** Test execution is currently blocked by a repo compile-time/runtime DB port mismatch rather than a missing binary. [VERIFIED: mix test test/scoria/connectors/invocation_test.exs test/scoria_web/live/orchestrator_live_test.exs]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix LiveView test helpers. [VERIFIED: test/scoria/connectors/invocation_test.exs] [VERIFIED: test/scoria_web/live/orchestrator_live_test.exs] |
| Config file | None found at repo root; tests are driven through Mix and `test/support`. [VERIFIED: repo grep] |
| Quick run command | `mix test test/scoria/connectors/invocation_test.exs test/scoria_web/live/orchestrator_live_test.exs` [VERIFIED: repo review] |
| Full suite command | `mix test` [VERIFIED: mix.exs] |

### Wave 0 Gaps

- Add targeted tests for a connector-aware approvals inbox query module before building the LiveView shell. [VERIFIED: repo review]
- Add targeted tests for connector fleet projection rows, especially pending tool adoption and stale refresh history. [VERIFIED: lib/scoria/connectors/discovery.ex]
- Add targeted LiveView tests for inbox filtering, connector drawer cross-links, and evidence notebook reading order. [VERIFIED: repo review]
- Fix the compile-time/runtime repo-config mismatch before relying on local `mix test` output as a phase gate. [VERIFIED: mix test test/scoria/connectors/invocation_test.exs test/scoria_web/live/orchestrator_live_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: .planning/REQUIREMENTS.md] | Connector auth and grant durability through `Scoria.Connectors.Auth` and `Grant`. [VERIFIED: lib/scoria/connectors/auth.ex] [VERIFIED: lib/scoria/connectors/grant.ex] |
| V3 Session Management | yes [VERIFIED: .planning/PROJECT.md] | Keep stateless-first remote invocation and avoid hidden session brokering. [VERIFIED: lib/scoria/connectors/invocation.ex] [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-RESEARCH.md] |
| V4 Access Control | yes [VERIFIED: .planning/REQUIREMENTS.md] | Dual-plane policy plus workflow-owned approvals. [VERIFIED: lib/scoria/connectors/invocation.ex] [VERIFIED: lib/scoria/workflows.ex] |
| V5 Input Validation | yes [VERIFIED: repo architecture] | Continue using changesets and redaction on approval and evidence payloads. [VERIFIED: lib/scoria/observe/approval.ex] [VERIFIED: lib/scoria/sre.ex] |
| V6 Cryptography | yes [VERIFIED: .planning/REQUIREMENTS.md] | Keep grant secrets encrypted with `CloakEcto`; never surface raw token fields in operator projections. [VERIFIED: lib/scoria/connectors/grant.ex] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Scope widening without explicit review [VERIFIED: .planning/REQUIREMENTS.md] | Elevation of Privilege | Preserve existing grants and require explicit operator review for new scopes. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md] [CITED: https://docs.github.com/en/enterprise-cloud@latest/apps/maintaining-github-apps/modifying-a-github-app-registration] |
| Secret leakage in evidence UI [VERIFIED: lib/scoria/connectors/grant.ex] | Information Disclosure | Rely on encrypted grant fields and `SRE.Redactor`-backed redacted refs for evidence summaries. [VERIFIED: lib/scoria/connectors/grant.ex] [VERIFIED: lib/scoria/sre.ex] |
| UI-only approval mutation [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] | Tampering | Route all decisions and resumptions through `Scoria.Workflows`. [VERIFIED: lib/scoria/workflows.ex] |
| High-cardinality telemetry labels [VERIFIED: lib/scoria/sre/telemetry_identity.ex] | Denial of Service | Keep exact IDs in durable evidence links, not metric labels. [VERIFIED: lib/scoria/sre/telemetry_identity.ex] |

## Sources

### Primary (HIGH confidence)
- `.planning/ROADMAP.md` - Phase 21 goal, requirements, and success criteria. [VERIFIED: .planning/ROADMAP.md]
- `.planning/REQUIREMENTS.md` - `POLI-03`, `EVID-01`, `EVID-02`, and `EVID-03`. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/PROJECT.md` - embedded product boundary and dashboard posture. [VERIFIED: .planning/PROJECT.md]
- `.planning/STATE.md` - active milestone posture. [VERIFIED: .planning/STATE.md]
- `.planning/MILESTONE-ARC.md` - milestone sequencing rationale. [VERIFIED: .planning/MILESTONE-ARC.md]
- `.planning/research/v1.5-switchyard-recommendation.md` - Switchyard defaults and risks. [VERIFIED: .planning/research/v1.5-switchyard-recommendation.md]
- `.planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md` - locked decisions and IA. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md]
- `.planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md` and `20-RESEARCH.md` - Phase 20 remote invocation posture. [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md] [VERIFIED: .planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-RESEARCH.md]
- `lib/scoria/workflows.ex`, `lib/scoria/observe/approval.ex`, `lib/scoria/connectors*.ex`, `lib/scoria_web/live/orchestrator_live.ex`, `lib/scoria_web/components/incident_evidence_component.ex` - implementation seams reviewed directly. [VERIFIED: repo code review]
- `test/scoria/connectors/invocation_test.exs` and `test/scoria_web/live/orchestrator_live_test.exs` - current proof lanes and expected behavior. [VERIFIED: repo code review]

### Secondary (MEDIUM confidence)
- `https://docs.github.com/en/enterprise-cloud@latest/apps/maintaining-github-apps/modifying-a-github-app-registration` - permission-widening approval semantics. [CITED: https://docs.github.com/en/enterprise-cloud@latest/apps/maintaining-github-apps/modifying-a-github-app-registration]
- `https://docs.langchain.com/oss/python/langgraph/interrupts` - durable interrupt/resume semantics. [CITED: https://docs.langchain.com/oss/python/langgraph/interrupts]
- `https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html` - embedded dashboard routing precedent. [CITED: https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html]

## Metadata

**Confidence breakdown:**  
- Standard stack: HIGH - all recommended libraries are already in the repo and version-verified through `mix.lock`. [VERIFIED: mix.lock]  
- Architecture: HIGH - the phase is mostly an extension of directly inspected workflow, connector, SRE, and LiveView seams. [VERIFIED: repo code review]  
- Pitfalls: HIGH - they derive from explicit current code limitations plus locked phase decisions. [VERIFIED: repo review]

**Research date:** 2026-05-18 [VERIFIED: repo workspace]  
**Valid until:** 2026-06-17 for repo-local seams; recheck external UX references if planning slips beyond 30 days. [VERIFIED: repo review]

## RESEARCH COMPLETE

**Phase:** 21 - Remote Approval Flow and Operator Evidence UX [VERIFIED: .planning/ROADMAP.md]  
**Confidence:** HIGH [VERIFIED: repo review]

**Recommended plan split:**  
1. `21-01` - connector-aware approval truth and projection seam. [VERIFIED: repo review]  
2. `21-02` - approvals inbox plus connector fleet table/detail drawer. [VERIFIED: repo review]  
3. `21-03` - typed remediation actions plus backend remote evidence projection. [VERIFIED: repo review]
4. `21-04` - run-centric remote evidence notebook and telemetry/evidence verification. [VERIFIED: repo review]
