# Phase 10: Wire Production SRE Telemetry and Fix Default Verification Bootstrap - Context

**Gathered:** 2026-05-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 10 closes the remaining Seismograph gaps around live SRE telemetry wiring and boring local verification.

This phase must:

- turn `Scoria.SRE.Telemetry` into a real production contract by wiring it into the live runtime and MCP seams and the durable incident seam
- fix the default verification/bootstrap story so core and SRE work run through an ordinary local test path without manual bootstrap rituals or ad hoc test-local table creation

This phase does not broaden into a new dashboard surface, a deep Parapet adapter stack, delivery-transport-as-SLO design, or making the knowledge layer mandatory infrastructure for unrelated Scoria work.

</domain>

<decisions>
## Implementation Decisions

### Telemetry producer coverage
- **D-01:** Phase 10 should wire and prove live SRE telemetry at the real execution seams: `Scoria.Workflows.Runtime` and `Scoria.MCP.Executor`.
- **D-02:** Phase 10 should also emit separate post-commit incident lifecycle telemetry from the durable incident seam so Scoria can prove the path from bad runtime event to durable operator evidence.
- **D-03:** Delivery and relay outcomes remain DB-first truth in this phase. They may expose coarse health telemetry later, but Phase 10 should not treat transport outcomes as first-class SLI coverage or pager-grade SRE signals.
- **D-04:** Runtime and incident telemetry must be separate namespaces or categories with clear semantics so one semantic failure is not counted twice as SLO burn.

### Telemetry identity contract
- **D-05:** Scoria should use canonical operational identity as the primary live telemetry contract, not incident lifecycle identity.
- **D-06:** Every live SRE telemetry event should carry one shared low-cardinality operational identity shape built from stable dimensions such as `tenant_id`, `subject_kind`, `policy_key`, `reason_code`, and `window_bucket`.
- **D-07:** Introduce a deterministic shared `identity_key` derived from those operational dimensions. This becomes the grouping handle across runtime, incidenting, and external consumers.
- **D-08:** `incident_key` is optional at raw runtime emission time and becomes a derived projection of the same shared identity when an alert or incident is materialized.
- **D-09:** `trace_id` and `run_id` remain correlation refs, not grouping labels.
- **D-10:** Parapet-facing helpers should group on canonical identity fields and `identity_key`, not require every raw event to pretend it already belongs to an incident.

### Verification bootstrap and repo ergonomics
- **D-11:** The boring default for Scoria core and SRE work should be ordinary `mix test` with no manual Docker/bootstrap ritual and no test-local schema patching.
- **D-12:** The knowledge/pgvector path remains first-class but explicit. It should live behind a blessed optional bootstrap/test path rather than being an unconditional prerequisite for unrelated SRE verification.
- **D-13:** The split must happen at the migration/bootstrap boundary, not only in documentation or test tags.
- **D-14:** Remove the architectural need for `ensure_*` table helpers in focused tests; those helpers are evidence of a broken bootstrap boundary, not a long-term pattern.
- **D-15:** CI should exercise at least two explicit lanes:
  - core/SRE on the boring default path
  - knowledge/full on the pgvector-aware path

### DX and GSD preference posture
- **D-16:** Planning for this phase should optimize for least surprise, batteries-included defaults, and narrow explicit escape hatches instead of host-app ceremony.
- **D-17:** Push low-impact defaults left inside Scoria and future GSD flows wherever possible; reserve user interruptions for decisions that are genuinely product-defining, architecture-shaping, or otherwise materially consequential.
- **D-18:** User-facing and operator-facing behavior should keep reading like a calm lab notebook: durable truth first, explicit evidence second, telemetry as a public seam rather than magical hidden glue.

### the agent's Discretion
- Exact module/helper extraction for shared SRE identity building, provided runtime, incident, and adapter layers all use one canonical implementation.
- Exact telemetry event names and namespace splits, provided execution SLI events remain distinct from incident lifecycle events.
- Exact command/alias naming for the explicit knowledge/pgvector test path, provided ordinary `mix test` stays the boring default for non-knowledge work.
- Exact CI workflow naming and matrix layout, provided both the boring core path and the explicit knowledge path are exercised continuously.

</decisions>

<specifics>
## Specific Ideas

- The right answer is not “more telemetry everywhere.” The right answer is telemetry at the true domain seams and durable rows as local truth.
- Execution telemetry should prove real runtime outcomes; incident telemetry should prove durable incident lifecycle after commit; delivery rows should stay the operator source of truth for transport outcomes.
- Scoria should feel like a Phoenix-native field kit, not a metrics-first observability science project.
- The repo should not force SRE contributors to think about pgvector just to run ordinary verification.
- Push low-impact product and architecture defaults left in future GSD behavior so the user is only stopped for decisions they are likely to actually care about.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and gap definition
- `.planning/ROADMAP.md` - Phase 10 title, milestone placement, and narrow intended scope
- `.planning/milestones/v1.3-REQUIREMENTS.md` - locked requirement mapping for `SRE-04` and `SRE-08`
- `.planning/v1.3-MILESTONE-AUDIT.md` - exact live telemetry and bootstrap gaps this phase exists to close
- `.planning/STATE.md` - current project posture and previously locked decisions
- `.planning/MILESTONES.md` - milestone objectives and the Seismograph contract

### Prior phase decisions
- `.planning/phases/05-caldera/05-CONTEXT.md` - workflow ownership, durable truth, and projection-vs-truth decisions
- `.planning/phases/06-corpus/06-CONTEXT.md` - knowledge-layer optionality, install ergonomics, and trace-first evidence UX
- `.planning/phases/07-seismograph/07-CONTEXT.md` - locked Seismograph architecture, telemetry posture, operator UX, and adapter boundaries
- `.planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-CONTEXT.md` - durable incident/delivery truth, lazy operator evidence loading, and defaulting posture

### Phase 7 and 9 research/execution history
- `.planning/phases/07-seismograph/07-RESEARCH.md` - original Seismograph research synthesis and implementation guidance
- `.planning/phases/07-seismograph/07-03-PLAN.md` - intended breaker and telemetry contract
- `.planning/phases/07-seismograph/07-04-SUMMARY.md` - transactional audit/incident design and the previous pgvector-related bootstrap deviation
- `.planning/phases/07-seismograph/07-05-PLAN.md` - trace-first incident evidence intent
- `.planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-01-SUMMARY.md` - workflow-owned approval/audit boundary restoration
- `.planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-02-SUMMARY.md` - durable notification delivery production and relay verification shape
- `.planning/phases/09-restore-audited-approval-and-incident-delivery-wiring/09-03-SUMMARY.md` - operator evidence lineage and relay outcome projection

### Product vision and architecture guidance
- `prompts/scoria-gsd-kickoff.md` - project thesis, batteries-included expectations, and operator-first goals
- `prompts/phoenix-ai-lib-deep-research.md` - ecosystem lessons around runtime, evals, telemetry, and control-plane design
- `prompts/scoria-brand-book-deep-research.md` - evidence-first, calm control-room, and lab-notebook product tone
- `prompts/sztheory-elixir-dna.md` - batteries-included but composable, Ecto-native, operator-first architecture rules

### Current code surface
- `lib/scoria/sre/telemetry.ex` - current public telemetry helper contract
- `lib/scoria/sre/adapters/parapet.ex` - telemetry-facing external helper translation
- `lib/scoria/workflows/runtime.ex` - workflow execution seam that must emit live SLI telemetry
- `lib/scoria/mcp/executor.ex` - tool/MCP execution seam that must emit live SLI telemetry
- `lib/scoria/sre.ex` - public SRE boundary
- `lib/scoria/sre/incident_manager.ex` - durable incident seam that should emit post-commit lifecycle telemetry
- `lib/scoria/sre/relay.ex` - delivery/relay runtime whose truth remains DB-first in this phase
- `mix.exs` - Mix aliases and repo test ergonomics
- `config/test.exs` - current test repo configuration
- `test/test_helper.exs` - current test bootstrap baseline
- `test/support/knowledge_case.exs` - current opt-in knowledge bootstrap shape
- `lib/mix/tasks/scoria.pgvector.bootstrap.ex` - explicit pgvector bootstrap task
- `priv/repo/migrations/20260511000300_create_knowledge_tables.exs` - knowledge migration that currently forces vector early in the chain
- `priv/repo/migrations/20260511171000_create_sre_incident_and_audit_tables.exs` - later SRE schema that should not depend on optional knowledge bootstrap
- `test/scoria/sre/telemetry_test.exs` - helper-level telemetry contract tests
- `test/scoria/sre_test.exs` - current failing focused SRE verification path
- `test/scoria/workflows/runtime_test.exs` - real workflow runtime verification seam
- `test/scoria/sre/audit_outbox_test.exs` - durable audit expectations
- `test/scoria/sre/relay_test.exs` - relay/delivery truth verification
- `test/scoria_web/live/orchestrator_live_sre_test.exs` - operator evidence rendering path

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scoria.Workflows.Runtime` and `Scoria.MCP.Executor` are already the narrowest trustworthy execution seams, so they are the right producers for live SLI telemetry.
- `Scoria.SRE.Telemetry` and `Scoria.SRE.Adapters.Parapet` already define the external shape of the telemetry contract; Phase 10 should wire them into production paths rather than redesign them from scratch.
- `Scoria.SRE.IncidentManager` already owns durable incident and delivery truth, making it the correct place for post-commit incident lifecycle telemetry instead of pushing those semantics down into runtime emitters.
- `KnowledgeCase` and `scoria.pgvector.bootstrap` already show the intended shape of an explicit knowledge path; the repo bootstrap issue is that this boundary is not yet reflected in the shared migration and default test flow.

### Established Patterns
- Ecto rows are the durable source of truth; telemetry is a public observation seam, not the authoritative local state for incidents, audit, or delivery.
- Narrow seam emission is preferred over scattered caller-side instrumentation.
- The product favors batteries-included defaults, explicit adapters, and trace-first operator evidence over hidden magic or broad host-app configuration.

### Integration Points
- Runtime/MCP outcome classification should be shared so telemetry semantics do not drift between execution paths.
- Incident identity derivation should be shared across runtime producers, incident manager, and Parapet-facing translation.
- Mix aliases, migration organization, and test helpers must align so core/SRE verification no longer depends on knowledge bootstrap side effects.

</code_context>

<deferred>
## Deferred Ideas

- Making delivery or relay transport outcomes first-class pager/SLO sources by default.
- Forcing every raw runtime telemetry event to carry incident lifecycle identity.
- Treating pgvector as mandatory baseline infrastructure for all Scoria contributors and all core/SRE test paths.
- Auto-starting Docker or mutating local environment implicitly from ordinary `mix test`.
- A deeper Parapet runtime dependency or a larger observability product surface in this phase.

</deferred>

---

*Phase: 10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap*
*Context gathered: 2026-05-12*
