# Phase 7: Seismograph - Context

**Gathered:** 2026-05-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 7 hardens Scoria into a production-grade control plane: budget enforcement, circuit breakers, Parapet-facing SLO hooks, immutable audit export, and automated regression incidenting.

This phase does not add a new product surface or turn Scoria into a general SRE platform. It keeps Scoria trace-first, evidence-first, and Phoenix-native while adding the minimum guardrails needed for safe production operation.

</domain>

<decisions>
## Implementation Decisions

### Budget enforcement and circuit breakers
- **D-01:** Use a hybrid control plane: Ecto owns policy, reservations, actual usage, and trip history; Hammer accelerates short-window limits; Fuse handles external-effect breakers.
- **D-02:** Reserve estimated spend before paid LLM steps and high-risk tool steps, then reconcile to actual provider/tool usage after execution.
- **D-03:** Put circuit breakers around external effects only: provider calls, remote MCP servers, and other side-effecting integrations.
- **D-04:** Keep the default policy small and explicit: warn at 80%, trip at 100%, and add only a few loop guards such as max workflow steps, repeated tool hash, and consecutive failure caps.
- **D-05:** Treat Plug-level rate limiting as a secondary ingress perimeter, not as the core spend-governance model.

### SLO contract and alerts
- **D-06:** Make the primary SLO contract budget-based, with reason-coded bad events and error budgets.
- **D-07:** Track separate SLIs for latency, quality, cost, and critical tool reliability.
- **D-08:** Page only on fast-burning user-facing budgets or breaker trips.
- **D-09:** CI baseline dips and slower quality/cost regressions should create review alerts or tickets, not production pages by default.
- **D-10:** Keep a composite Scoria health rollup in dashboards, but do not make it the main pager source.
- **D-11:** Version scorers, thresholds, and baselines so incidents always point at a specific scorer/version pair.

### Audit export boundary
- **D-12:** Use a hybrid capture model: write a durable audit-outbox row in the same transaction as the local truth change, then fan out telemetry after commit.
- **D-13:** Keep telemetry as the public integration contract, but do not rely on telemetry handlers alone for sensitive audit delivery.
- **D-14:** Export relays are optional and configurable through a behavior or MFA, with a no-op default; Threadline is not a hard dependency of core Scoria.
- **D-15:** Mandatory external-audit candidates are tool approval requested/approved/denied/expired, sensitive MCP access granted/denied, and policy-sensitive tool invocations.
- **D-16:** Redact raw payloads and arguments at the boundary; prefer references, hashes, policy classes, and trace IDs.

### Ecosystem posture
- **D-17:** Keep core Scoria Phoenix/Ecto/Telemetry-native.
- **D-18:** Prefer telemetry plus narrow behaviors such as `Scoria.AuditSink` and `Scoria.AlertSink` over hard dependencies.
- **D-19:** Ship first-party optional adapters only where they materially improve day-one ergonomics, especially for Threadline, Chimeway, and Mailglass.
- **D-20:** Keep Parapet integration mostly telemetry-driven, with small helper modules rather than a deep adapter stack.

### Operator UX and DX
- **D-21:** Favor boring, least-surprise defaults that surface evidence in the existing trace-first LiveView experience.
- **D-22:** Use stable incident keys so related signals dedupe into one reviewable case.
- **D-23:** Keep notification routing simple in this phase; do not introduce complex alert trees or auto-remediation workflows yet.
- **D-24:** Make every alert and incident deep-link back to the trace explorer and the underlying Ecto evidence.

### the agent's Discretion
- Exact schema field names for `alert_policies`, `alert_events`, `incidents`, `incident_events`, `notification_deliveries`, and `audit_outbox_events`.
- Exact job transport for the audit relay and alert relay, provided the durability and retry semantics stay intact.
- Exact threshold values beyond the default 80% warn / 100% trip policy.

</decisions>

<specifics>
## Specific Ideas

- "Trace the run. Prove the change. Ship the agent."
- The control room should feel calm during incidents, and the system should read like a lab notebook that can be audited.
- Every claim should point to a trace, eval score, baseline, cost number, prompt version, dataset item, or policy.
- Scoria should show the whole run, not hide behind AI magic.
- The SRE layer should preserve the existing Phoenix-native, trace-first, operator-grade product tone.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone intent
- `.planning/MILESTONES.md` - Phase 7 theme, scope, and the intended relationship to Parapet, Threadline, Chimeway, and Mailglass
- `.planning/STATE.md` - current project state and locked preferences

### Prior phase context and decisions
- `.planning/phases/05-caldera/05-CONTEXT.md` - durable workflow, trace-first, and adapter-boundary decisions that Phase 7 must respect
- `.planning/phases/06-corpus/06-CONTEXT.md` - trace-first evidence UX, install ergonomics, and optional adapter posture

### Research and ecosystem guidance
- `.planning/research/agentcore-lessons.md` - boundary, audit, and observability lessons from adjacent managed-agent work
- `.planning/research/mcp-and-tools.md` - MCP gateway, tool governance, and HITL boundary lessons
- `.planning/research/phase_4_decisions.md` - immutable eval snapshots, CI gates, and rubric versioning lessons
- `.planning/memory/parapet-synergy.md` - SLO, burn-rate, and durable-evidence integration ideas for Parapet

### Product vision and style
- `prompts/scoria-brand-book-deep-research.md` - evidence-first product framing, incident tone, and UI/UX language
- `prompts/sztheory-elixir-dna.md` - ecosystem and architecture constraints
- `prompts/scoria-gsd-kickoff.md` - project thesis and the core product pillars
- `prompts/phoenix-ai-lib-deep-research.md` - AI ops, observability, eval, and dashboard guidance

### Reusable code surface
- `lib/scoria/mcp/executor.ex` - isolated tool execution and telemetry emission
- `lib/scoria/workflows.ex` - transactional lifecycle and durable workflow transitions
- `lib/scoria/workflows/runtime.ex` - runtime boundary for budget and breaker enforcement
- `lib/scoria/observe/redactor.ex` - redaction boundary for sensitive export payloads
- `lib/scoria_web/live/orchestrator_live.ex` - trace-first LiveView projection and streaming UX

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Workflows` already models durable state transitions with `Ecto.Multi`, which is the right place to add budget reservations, breaker state, and incident history.
- `Scoria.MCP.Executor` already isolates paid or side-effecting work, which is the correct boundary for preflight reservations and breaker wrapping.
- `Scoria.Observe.Redactor` already provides a boundary for payload sanitization, which should be reused for audit export and notifications.
- `ScoriaWeb.OrchestratorLive` already presents trace-first projections, which should become the operator surface for incidents, reviews, and evidence drilldown.

### Established Patterns
- Ecto is the durable source of truth; PubSub and LiveView are projections only.
- Telemetry is the public event seam, but not the durable record for security-sensitive or billing-sensitive facts.
- The product favors explicit nouns, transactional writes, and calm operator surfaces over hidden middleware.

### Integration Points
- Budget reservations and breaker decisions should connect to the workflow runtime and MCP executor boundaries.
- Alert review and incident drilldown should appear inside the existing dashboard surface rather than a new standalone UI.
- Audit export should sit beside the existing workflow and approval transitions so evidence can be linked to the exact trace and run state.

</code_context>

<deferred>
## Deferred Ideas

- Full production anomaly detection beyond thresholded windows.
- Auto-remediation or runbook execution.
- Cross-service SLO math in Parapet/Grafana-class detail.
- Fine-grained per-tenant paging policies.
- ML-driven alert correlation.
- Complex notification routing trees beyond simple Chimeway/Mailglass adapters.

</deferred>

---

*Phase: 07-seismograph*
*Context gathered: 2026-05-11*
