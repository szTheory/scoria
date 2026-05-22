# Phase 29: External Runtime Observability & Operator UX - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Expose real-time external runtime visibility and compaction auditability through Scoria's embedded LiveView dashboard.

This phase turns the transport and compaction seams from Phases 27-28 into an operator-facing surface. It must let operators see connected external runtimes in real time, detect visible offline state, and inspect how raw session history was compacted into durable memory summaries. It does not turn Scoria into a hosted runtime fleet manager, redefine durable runtime truth away from Ecto, or introduce speculative health semantics that the system cannot actually prove.

</domain>

<decisions>
## Implementation Decisions

### Runtime fleet surface
- **D-01:** The dashboard should show external runtimes as a compact adjacent operator surface, not as a new full-width primary fleet console and not as something hidden until drill-down.
- **D-02:** The recommended Phase 29 shape is a runtime status rail or compact card stack beside the existing operator surfaces in `OrchestratorLive`, parallel to approvals and connector posture.
- **D-03:** Each runtime row/card should stay compact and scan-first, emphasizing:
  - runtime identity
  - current presence status
  - active session or run linkage when available
  - last heartbeat or last seen indicator when available
  - compaction freshness / latest compacted-memory linkage
- **D-04:** A dedicated wide fleet table is not the default Phase 29 IA. It is a possible later expansion if tenant/runtime scale proves the compact rail insufficient.
- **D-05:** Runtime scanability matters, but Scoria must not drift into a hosted runtime-control-plane posture. The runtime surface is an operator aid inside the embedded dashboard, not the new center of gravity.

### Presence and health semantics
- **D-06:** Phase 29 should expose status plus runtime identity plus transport/session linkage as the default contract.
- **D-07:** Presence should mean transport/process attachment first, not general remote-agent health. The UI must not imply stronger liveness guarantees than Scoria can prove.
- **D-08:** Status semantics should be:
  - `connected` -> a Presence entry exists and Scoria can resolve runtime identity plus current linkage
  - `offline` -> Presence left / transport closed / runtime no longer attached
  - `degraded` -> only valid if Scoria has an explicit runtime heartbeat or runtime-activity signal independent of transport keepalives
- **D-09:** Scoria must not derive `degraded` from SSE keepalive comments or mere socket openness. A transport that is still attached is not automatically a healthy runtime.
- **D-10:** Offline state should show a typed reason when available, such as:
  - `transport_closed`
  - `presence_left`
  - `session_not_found`
  - `heartbeat_timeout`
  - `operator_disconnect`
- **D-11:** Presence metadata should stay small and ephemeral. Richer operator-visible identity and linkage truth should come from Ecto-backed projections or `fetch/2` enrichment rather than bloated Presence metadata.
- **D-12:** The stable key for runtime presence should be a Scoria-owned runtime instance id, not only a host-app `session_id`. Session/run linkage remains metadata or projection.

### Durable vs ephemeral runtime truth
- **D-13:** Operators need durable runtime identity and linkage beyond the life of a live connection. The following should be durable Ecto-backed truth or equivalent projection inputs:
  - runtime instance id
  - actor/tenant identity
  - host session id when applicable
  - current and last linked run id
  - first seen / last seen
  - last terminal offline reason
  - transport kind
  - bounded runtime descriptors that matter to operators
- **D-14:** The following should remain ephemeral connection-state metadata:
  - Presence refs
  - current transport facts
  - current heartbeat timestamp/age
  - reconnecting/stale labels
  - other volatile live-session hints
- **D-15:** The rule is simple: if operators need it after the process dies, it belongs in durable truth; if it only describes the current live connection, it may remain ephemeral.

### Memory time-travel presentation
- **D-16:** The compaction audit view should use a timeline/notebook model with `raw range -> compacted memory` blocks, not a side-by-side textual diff as the primary presentation.
- **D-17:** Each compaction block should make the transformation explicit and auditable:
  - exact raw sequence range
  - compacted timestamp
  - archived event count
  - token-count metadata
  - summary text
  - expandable raw evidence beneath
- **D-18:** Summary-first collapse behavior is acceptable inside each compaction block, but summary-first is not the top-level information architecture for the page.
- **D-19:** Raw events remain the source of truth. Compacted summaries are operator aids and durable derived memory, not replacements for the original evidence.
- **D-20:** Scoria must not render a fake “diff” that implies event-to-summary alignment the system does not actually store. Current compaction output is a bounded freeform summary over a sequence range, not a structurally aligned patch.
- **D-21:** Sequence boundaries should be the lead audit reference in the UI. Timestamps are useful, but `start_sequence` / `end_sequence` are the actual compaction join keys.
- **D-22:** Token-count labels must be precise. If the persisted token count refers to archived raw tokens rather than summary tokens, the UI must say that explicitly.

### Default navigation path
- **D-23:** Scoria should support both a top-level runtime scan surface and deep workflow/session evidence, but with one clearly primary truth path.
- **D-24:** The dashboard root remains the scan/state surface. Workflow/session detail remains the truth surface.
- **D-25:** The primary drill-in from a runtime row should go to the linked workflow/session when one exists, not to a runtime-only page as the default path.
- **D-26:** The workflow/session page should become the place where runtime presence context, session timeline, and memory time-travel evidence are read together.
- **D-27:** Reciprocal links are mandatory:
  - runtime row -> linked workflow/session
  - workflow/session -> linked runtime card or drawer
  - compaction block -> exact runtime presence snapshot/context when available
  - offline runtime alert -> last active session/run
- **D-28:** If a dedicated runtime detail page exists later, it is a secondary ops surface for triage, not the primary truth surface.

### Shift-left defaults and GSD posture
- **D-29:** Low-impact Phase 29 choices should be shifted left into Scoria defaults and treated as locked by downstream GSD planning rather than re-asked:
  - rail/card runtime presentation over wide-table-first IA
  - workflow/session truth path over runtime-detail-first navigation
  - `connected` / `offline` semantics from Presence
  - no `degraded` without a real heartbeat contract
  - notebook-style compaction audit instead of side-by-side diff
  - compact runtime rows with one obvious primary action
  - lazy loading for deep archived raw evidence
  - explicit copy that raw events are truth and summaries are derived memory
- **D-30:** User interruption should be reserved for materially impactful future choices only:
  - introducing a real heartbeat contract that changes health semantics
  - making runtime fleet management a primary product surface
  - broadening into stateful remote runtime/session management
  - changing raw-event retention/archival posture in ways that affect audit truth

### the agent's Discretion
- Exact component/module names for runtime projections, drawers, and notebook rows, provided the split between dashboard scan surface and workflow/session truth surface remains intact.
- Exact card density, badge copy, and visual grouping, provided the UI stays calm, compact, operator-grade, and embedded rather than hosted-control-plane-like.
- Exact query/projection boundaries and async-loading strategy, provided heavy archived evidence stays lazy and LiveView does not become the source of truth.
- Exact route/anchor structure for cross-links, provided the primary drill-in remains workflow/session-first and runtime-only pages stay secondary.

</decisions>

<specifics>
## Specific Ideas

- The coherent Phase 29 product shape is:
  - runtime rail/cards on the dashboard for scanability
  - workflow/session detail as the main explanatory surface
  - notebook-style compaction audit rather than textual diff theater
  - Presence as live attachment signal, not overclaimed health oracle
- The strongest adjacent lessons that apply directly:
  - Phoenix LiveDashboard / Oban Web: scan-first embedded operator surfaces with drilldown
  - Honeycomb: summary + waterfall/sidebar detail beats giant blob views
  - Sentry: event detail and replay belong beside the exact incident object
  - Langfuse: sessions are a useful grouping/reporting noun, but the detailed replay/evidence path still matters
  - GitHub permission review: keep existing truth stable, require explicit review for widened power
- Footguns to avoid:
  - treating Presence as canonical runtime truth
  - inferring health from transport keepalive noise
  - inventing a side-by-side diff the data model cannot justify
  - overloading the dashboard with a premature fleet table
  - making runtime management feel more primary than trace/run evidence

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement intent
- `.planning/ROADMAP.md` - Phase 29 goal, dependency on Phase 28, and success criteria.
- `.planning/PROJECT.md` - embedded Phoenix-first product boundary and operator-grade product posture.
- `.planning/REQUIREMENTS.md` - `OUTRIDER-02`, `OUTRIDER-06`, and `OUTRIDER-07`.
- `.planning/STATE.md` - current milestone posture and sequencing context.

### Prior locked Scoria decisions
- `.planning/phases/19-remote-connector-boundary-and-auth-discovery/19-CONTEXT.md` - durable runtime/connectivity truth vs projection boundaries.
- `.planning/phases/20-policy-stable-tool-identity-and-stateless-invocation/20-CONTEXT.md` - stateless-first posture, durable identity, and least-surprise operator behavior.
- `.planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-CONTEXT.md` - scan/risk/truth surface split and evidence-first dashboard posture.
- `.planning/phases/22-curated-connector-profiles-and-boring-adoption-path/22-CONTEXT.md` - boring defaults and shift-left product posture.
- `.planning/phases/28-async-session-compaction-engine/DECISIONS.md` - compacted-memory schema, trigger, and raw-event retention decisions.
- `.planning/phases/28-async-session-compaction-engine/28-RESEARCH.md` - compaction architecture, pitfalls, and Phase 29 handoff expectations.

### Product and architecture guidance
- `.planning/research/liveview-operator-ux.md` - embedded dashboard, async loading, and operator-first LiveView patterns.
- `.planning/research/07-outrider-ARCHITECTURE.md` - external runtime presence + compaction architecture split.
- `.planning/research/07-outrider-FEATURES.md` - milestone feature expectations including Presence and memory time-travel.
- `.planning/research/07-outrider-PITFALLS.md` - compaction lossiness and runtime liveness caveats.
- `.planning/research/agentcore-lessons.md` - keep runtime session state separate from durable product truth.
- `prompts/scoria-gsd-kickoff.md` - Scoria vision and operator UI north star.
- `prompts/sztheory-elixir-dna.md` - embedded LiveView, Ecto-native truth, and operator-first DX rules.
- `prompts/phoenix-ai-lib-deep-research.md` - broader product and ecosystem lessons for Phoenix-native AI ops surfaces.
- `prompts/scoria-brand-book-deep-research.md` - calm, evidence-first, operator-grade product voice and UX posture.

### Current code surface
- `lib/scoria_web/router.ex` - current dashboard/run routing structure.
- `lib/scoria_web/live/orchestrator_live.ex` - dashboard scan surfaces, PubSub subscription, and adjacent operator layout.
- `lib/scoria_web/live/workflow_live/show.ex` - workflow/session truth surface to extend with runtime + compaction evidence.
- `lib/scoria_web/components/connector_detail_drawer_component.ex` - compact scan surface -> detail drawer pattern.
- `lib/scoria_web/components/incident_evidence_component.ex` - dense evidence notebook composition style.
- `lib/scoria_web/components/remote_invocation_evidence_component.ex` - lineage-first evidence presentation pattern.
- `lib/scoria/compaction/summarize_worker.ex` - actual compaction output semantics and token-count behavior.
- `lib/scoria/runtime/compacted_memory.ex` - compacted-memory range schema and validations.
- `test/scoria_web/live/workflow_live_test.exs` - current workflow/run rendering expectations and durable evidence posture.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `OrchestratorLive` already has the right operator-layout posture: multiple adjacent scan surfaces with lazy evidence loading rather than one giant top-level notebook.
- `WorkflowLive.Show` is already the natural truth surface for linked runtime/session detail and can absorb runtime presence plus compaction notebook work without inventing a separate truth route.
- `ConnectorDetailDrawerComponent` is a strong precedent for compact operator rows that open deeper detail without moving truth into the dashboard root.
- `IncidentEvidenceComponent` and `RemoteInvocationEvidenceComponent` already model the right compositional language: compact rollup first, lineage/evidence next, dense cards instead of raw payload walls.
- `SummarizeWorker` and `CompactedMemory` define the exact truth boundary the UI must respect: range-scoped summaries over archived raw events.

### Established Patterns
- Ecto rows are durable truth; Presence, PubSub, and LiveView are projections over that truth.
- The repo prefers one obvious operator path with strong cross-links over multiple competing primary surfaces.
- Heavy evidence is loaded lazily with async patterns rather than front-loading all detail at mount time.
- Security/reliability-sensitive state is represented with typed durable seams rather than implied from transient UI state.

### Integration Points
- Phase 29 should add a runtime operator projection parallel to existing connector posture projections.
- Runtime presence updates should flow through Presence/PubSub into compact dashboard cards or rows, not dump full presence state into large LiveView assigns.
- Workflow/session detail should join runtime linkage plus compacted-memory ranges and raw archived events into a notebook view.
- Cross-links between dashboard runtime rows, workflow/session pages, and compaction blocks should use durable ids and sequence ranges rather than UI-local state.

</code_context>

<deferred>
## Deferred Ideas

- A full runtime fleet table with heavier filtering/sorting and runtime-only drilldown as a primary surface.
- Strict runtime heartbeat/degraded semantics unless and until external runtimes expose an explicit heartbeat/activity contract.
- Hosted-control-plane-style runtime administration beyond the embedded dashboard posture.
- State-heavy remote runtime/session management that hides transport/session lifecycle behind Scoria defaults.
- Rich textual diffing or semantic alignment views that require data Scoria does not currently persist.

</deferred>

---

*Phase: 29-external-runtime-observability-and-operator-ux*
*Context gathered: 2026-05-19*
