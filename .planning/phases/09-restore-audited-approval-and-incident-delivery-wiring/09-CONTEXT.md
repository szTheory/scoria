# Phase 9: Restore Audited Approval and Incident Delivery Wiring - Context

**Gathered:** 2026-05-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Restore the live production wiring for two already-intended Seismograph behaviors:

- operator approval actions must flow through the audited workflow boundary instead of mutating approval rows directly
- live incident routing must produce durable notification-delivery rows that the relay and operator notebook can inspect

This phase fixes broken seams in approval, audit, incident, delivery, and operator evidence lineage. It does not widen into new dashboard surfaces, broad telemetry work, or local-bootstrap cleanup beyond what is strictly needed to verify these paths.

</domain>

<decisions>
## Implementation Decisions

### Approval action contract
- **D-01:** `Scoria.Workflows.approve/3` is the only blessed mutation path for approval decisions.
- **D-02:** LiveView and any other callers must treat approvals as workflow-owned domain actions, not rows to mutate directly with `Repo.update/2`.
- **D-03:** Approval request, approve, reject, and expire transitions must write workflow truth and durable audit evidence in the same transaction.
- **D-04:** The public mutation contract stays on `Scoria.Workflows` even if implementation later moves into an internal workflow-owned submodule.
- **D-05:** Approval decisions must carry actor, tenant, and trace context so audit evidence remains operator-grade and attributable.
- **D-06:** The operator-facing approve path should feel like one action: record the decision through `Scoria.Workflows.approve/3`, then continue the run only through workflow-owned resume logic after commit rather than via UI-side row mutation.

### Incident and delivery production
- **D-07:** `notification_deliveries` are durable local intent rows and must be written in the same transaction that creates or updates the incident graph.
- **D-08:** External sending stays post-commit and asynchronous through `Scoria.SRE.Relay`; adapters never run inside the incident transaction.
- **D-09:** Scoria owns a small boring default routing model:
  - `review` incidents route to `chimeway`
  - `page` incidents route to `mailglass`
- **D-10:** If a dispatcher or routing target is unconfigured, Scoria must preserve local incident and delivery evidence and record the transport as explicit `noop` or `unconfigured`, not silently drop the notification.
- **D-11:** Create delivery rows when an incident first opens and when routing escalates from `review` to `page`; deduped repeats update evidence but should not fan out new responder noise by default.
- **D-12:** Host apps may override sink selection later, but Phase 9 planning should assume Scoria owns the default routing so install-time behavior stays coherent and evidence-first.

### Operator evidence and verification expectations
- **D-13:** Approval, audit, incident, and delivery evidence stays inside the existing trace-first LiveView notebook rather than a separate dashboard surface.
- **D-14:** Phase 9 must prove end-to-end lineage from operator approval through durable audit-outbox rows and relay or delivery evidence, with drilldowns linked back to the same run and trace.
- **D-15:** Keep evidence loading explicit and lazy; do not auto-load heavy approval, audit, or delivery notebooks on mount.
- **D-16:** The composite health rollup remains a compact summary, not the primary product surface; the trace-first notebook remains the main operator mental model.

### DX and defaulting posture
- **D-17:** Favor batteries-included defaults and push low-impact decisions left into Scoria-owned behavior unless a choice is materially product-defining or architecture-shaping.
- **D-18:** Planning for this phase should optimize for boring, testable seams and least surprise over abstract flexibility or host-app ceremony.

### the agent's Discretion
- Exact helper/module extraction if `Scoria.Workflows` approval internals need cleanup, so long as the public approval contract remains workflow-owned.
- Exact config shape for default `chimeway` and `mailglass` routing keys.
- Exact metadata fields used to distinguish `noop`, `unconfigured`, `failed`, and `delivered` transport outcomes.
- Exact approval resume hook placement after commit, so long as it remains a workflow-owned action and not a direct UI mutation.

</decisions>

<specifics>
## Specific Ideas

- The project should keep reading like a calm lab notebook that can be audited, not a best-effort collection of side effects.
- The right fix is to make the current trace-first notebook true, not broader.
- For approvals, copy the boundary discipline strong systems use: domain action first, post-commit fanout second.
- For notifications, copy the durable-intent pattern used by outbox and job systems: row first, relay second.
- Push low-impact product and architecture defaults left in future GSD flows so the user is interrupted only for genuinely consequential choices.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and gap definition
- `.planning/ROADMAP.md` - phase title and milestone placement for Phase 9
- `.planning/milestones/v1.3-REQUIREMENTS.md` - locked requirement mapping for SRE-05, SRE-06, and SRE-07
- `.planning/v1.3-MILESTONE-AUDIT.md` - exact broken seams this phase exists to repair
- `.planning/STATE.md` - current project posture and previously locked decisions

### Prior phase decisions
- `.planning/phases/05-caldera/05-CONTEXT.md` - workflow ownership, trace-first, and projection-vs-truth decisions
- `.planning/phases/06-corpus/06-CONTEXT.md` - evidence-inside-the-trace and lazy-loading operator UX decisions
- `.planning/phases/07-seismograph/07-CONTEXT.md` - audit-outbox, incident routing, optional adapter, and calm operator UX decisions

### Phase 7 research and execution history
- `.planning/phases/07-seismograph/07-RESEARCH.md` - original Seismograph implementation guidance and anti-patterns
- `.planning/phases/07-seismograph/07-PATTERNS.md` - repo-native patterns for context ownership, transactions, relay, and LiveView projection
- `.planning/phases/07-seismograph/07-04-SUMMARY.md` - transactional audit-outbox and incident-routing decisions already landed
- `.planning/phases/07-seismograph/07-05-PLAN.md` - intended operator evidence behavior inside the existing dashboard
- `.planning/phases/07-seismograph/07-08-SUMMARY.md` - relay runtime and optional sink adapter posture
- `.planning/memory/parapet-synergy.md` - durable evidence and low-cardinality operator alert philosophy

### Product vision and architecture guidance
- `prompts/scoria-gsd-kickoff.md` - project thesis, AI ops positioning, and batteries-included expectations
- `prompts/phoenix-ai-lib-deep-research.md` - trace/eval/runtime/control-plane guidance and lessons from adjacent ecosystems
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable, operator-first, Ecto-native architecture rules
- `prompts/scoria-brand-book-deep-research.md` - evidence-over-magic, calm control-room, and lab-notebook UX tone

### Current code surface
- `lib/scoria/workflows.ex` - approval request and decision seams plus workflow-owned transitions
- `lib/scoria/observe/approval.ex` - approval schema and optimistic-lock contract
- `lib/scoria/sre.ex` - public SRE context boundary
- `lib/scoria/sre/incident_manager.ex` - incident routing seam that must start producing delivery rows
- `lib/scoria/sre/notification_delivery.ex` - durable delivery noun
- `lib/scoria/sre/relay.ex` - post-commit relay runtime and retry behavior
- `lib/scoria/sre/adapters/chimeway.ex` - review-delivery adapter seam
- `lib/scoria/sre/adapters/mailglass.ex` - page-delivery adapter seam
- `lib/scoria_web/live/orchestrator_live.ex` - current approval UI seam and trace-first evidence loading
- `lib/scoria_web/components/incident_evidence_component.ex` - existing operator notebook surface that Phase 9 should make truthful
- `test/scoria/sre/audit_outbox_test.exs` - approval audit durability expectations
- `test/scoria/sre/incident_test.exs` - incident routing and dedupe expectations
- `test/scoria/sre/relay_test.exs` - relay and adapter behavior expectations
- `test/scoria/workflows/runtime_test.exs` - approval wait/resume and durable runtime expectations
- `test/scoria_web/live/orchestrator_live_sre_test.exs` - operator evidence rendering expectations

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Workflows.mark_waiting_for_approval/3` already proves the right transactional shape: run state, step state, checkpoint, event, approval row, and audit outbox are co-written in one seam.
- `Scoria.Workflows.approve/3` already exists as the durable approval-decision seam and should become the only UI-facing mutation path.
- `Scoria.SRE.Relay` already provides the post-commit delivery runtime with durable claiming, retries, and adapter routing.
- `ScoriaWeb.IncidentEvidenceComponent` and `ScoriaWeb.OrchestratorLive` already provide the operator surface; the phase should wire truth into them rather than introduce a second UI.

### Established Patterns
- Ecto is the durable source of truth; LiveView is a projection layer.
- `Ecto.Multi` is the repo-native way to preserve multi-row invariants around workflow and SRE truth changes.
- Outbox-style durable rows plus post-commit fanout is already the chosen pattern for sensitive audit delivery.
- Optional first-party adapters with no-op defaults are preferred over hard runtime dependencies.

### Integration Points
- Approval UI actions in `ScoriaWeb.OrchestratorLive` must route into `Scoria.Workflows.approve/3` and any follow-up resume seam.
- Incident routing in `Scoria.SRE.IncidentManager` must start producing `NotificationDelivery` rows consumed by `Scoria.SRE.Relay`.
- The operator notebook should derive approval, audit, incident, and delivery evidence from the same run or trace lineage rather than seeded or inferred placeholders.

</code_context>

<deferred>
## Deferred Ideas

- A separate approval, audit, or delivery dashboard surface.
- Host-app-owned notification routing as the default posture.
- Direct adapter publishing without durable local delivery rows.
- Aggressive auto-loading or broader incident-control chrome in the main LiveView.
- A cross-cutting standalone `Scoria.Approvals` public context unless approvals later become meaningfully broader than workflow-owned checkpoints and steps.
- Telemetry-wiring and local-bootstrap fixes outside the narrow seams required to verify Phase 9.

</deferred>

---

*Phase: 09-restore-audited-approval-and-incident-delivery-wiring*
*Context gathered: 2026-05-12*
