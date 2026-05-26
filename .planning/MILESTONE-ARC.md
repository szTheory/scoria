# Milestone Arc: Scoria

**Created:** 2026-05-12
**Last updated:** 2026-05-26
**Status:** maintained planning artifact

## Purpose

Keep a rolling, prioritized view of the next 2-4 milestones so Scoria keeps moving toward being the principle-of-least-surprise AI quality layer for real Phoenix applications.

This file is the strategic source of truth for milestone sequencing. It should be consulted before starting a new milestone and updated when a shipped milestone changes what should come next.

## Product North Star

Scoria should feel like the obvious thing Phoenix teams reach for when they need AI observability, durable agent workflow state, retrieval grounding, approvals, evaluation, guardrailed tool use, and replayable operator evidence inside an existing application.

The product should stay:

- embedded and Phoenix-first, not a managed agent platform
- Ecto and Telemetry native, not bolt-on infrastructure theater
- operator-visible by default, not magical
- boring to install, configure, and verify in a normal Phoenix app

## Current Baseline

Shipped through `v2.2 OSS adopter onramp` on 2026-05-26:

- observability and trace storage
- MCP gateway and governance seams
- LiveView operator surface
- evaluation flywheel
- durable workflows and handoffs
- knowledge, citations, and grounding
- SRE budgets, breakers, audit lineage, incident routing, and telemetry
- canonical runtime identity, public runtime APIs, install defaults, adoption docs, and executable guardrails
- remote MCP connector productization, prompt lifecycle, async compaction, and external runtime observability
- resilient multi-model fallback orchestration, distributed evaluation fan-out, and real-time operator dashboards
- replay branching from durable checkpoint truth with replay-safe execution defaults
- replay comparison, workflow-source dataset promotion, and asynchronous online scoring review queues
- public `Scoria.start_handoff_run/3` bounded handoff API with explicit same-run lineage and projected-context safety
- delegated evidence surfaces, runtime-first adoption proof, and a clean full-suite closeout baseline
- tenant-scoped semantic fast-path lookup, compatibility-aware invalidation, operator-visible semantic evidence, and a named semantic proof lane
- publish-facing package/docs truth, generated-host adoption proof, and a canonical lane-based maintainer/adopter closeout chain

## Sequencing Principles

1. Prioritize adoption prerequisites before adjacent capability expansion.
2. Prefer milestones that make existing power easier to use in Phoenix apps over milestones that only add more raw surface area.
3. Keep Scoria embedded and boundary-driven; do not drift into a hosted runtime product.
4. Promote milestones that improve installability, public API clarity, and operator trust.
5. Close the trace -> replay -> score -> promote loop before moving on to broader future-bet capability families.

## Milestone Ledger

| Version | Name | Status | Notes |
|---------|------|--------|-------|
| v1.0 | MVP | shipped | Observability, MCP governance, operator UX, evaluation |
| v1.1 | Caldera | shipped | Durable workflows and handoffs |
| v1.2 | Corpus | shipped | Knowledge, citations, grounding |
| v1.3 | Seismograph | shipped | SRE budgets, breakers, telemetry, audit, incident delivery |
| v1.4 | Keystone | shipped | Identity, sessions, public runtime API, install defaults, docs |
| v1.5 | Switchyard | shipped | Remote MCP connector productization |
| v1.6 | Flightpath | shipped | Prompt lifecycle and evaluation operations |
| v1.7 | Outrider | shipped | Advanced ecosystem integrations and future-bet runtime surfaces |
| v1.8 | Vanguard | shipped | Multi-model orchestration, distributed evaluations, and reconciled shipped milestone truth |
| v1.9 | Crucible | shipped | Replayable debugging and online quality feedback |
| v2.0 | Relay | shipped | Formalized the bounded public handoff wedge, delegated evidence story, and canonical adoption proof |
| v2.1 | Tenant-scoped semantic fast path | shipped | Durable semantic reuse, invalidation truth, operator evidence, and a bounded semantic proof lane |
| v2.2 | OSS adopter onramp | shipped | Release-grade package truth, host-app install proof, and lane-based support closure |

## Latest Shipped Milestone

### v2.2 OSS adopter onramp

**Status:** shipped
**Priority at close:** highest
**Theme:** Make the default Phoenix adoption path publishable, consumer-proven, and support-truthful

**What shipped**

- a real local docs-build lane plus a bounded `mix scoria.release_preview` package/docs proof
- a default-lane installer contract that is truthful about copied migrations, runtime defaults, unsupported routers, and optional Tailwind behavior
- a generated-host Phoenix proof path for dependency -> install -> migrate -> runtime -> operator inspection
- one lane-based support story that clearly separates default runtime, bounded handoff, semantic fast path, and optional knowledge adoption

**User-facing outcome**

Teams can now adopt Scoria through a boring, executable Phoenix-first path instead of relying on maintainer lore around package surface, install steps, or verification order.

## Active Milestone

No active milestone. Start the next one through `$gsd-new-milestone`.

## Recommended Candidates

### 1. Advanced adoption examples only if handoff confusion remains

**Status:** pending
**Priority:** medium
**Theme:** Clarify capability tiering without widening the product boundary

**What this step should deliver**

- one stronger runtime -> handoff -> review or replay guide or example if support burden remains high
- clearer lane-by-lane explanation of what typical Phoenix teams adopt first vs later once the default onramp is boring

**Why it is next**

This remains contingent on real support evidence. It is the highest-leverage next candidate only if the shipped OSS onramp still leaves Phoenix teams confused about when to adopt bounded handoffs or adjacent lanes.

### 2. External semantic cache backends and advanced tuning

**Status:** pending
**Priority:** low
**Theme:** Expand semantic-cache infrastructure only after the default embedded path is boring

**What this step should deliver**

- optional external cache backends beyond the default Ecto-native truth store
- advanced ANN tuning and analytics controls only if operator trust remains intact

**Why it follows later**

These are natural extensions of `v2.1`, but they widen scope and should wait until the embedded default path and the fresh-adopter story both prove boring in practice.

## Recommendation

Do not auto-open a new milestone from leftover `v2.2` momentum. Start the next milestone only after choosing between a support-evidence-driven adoption-example follow-up and later semantic infrastructure expansion; the current recommendation is the adoption-example path if real user confusion appears.

## Source Notes

These priorities were informed by:

- current repo state as of 2026-05-26
- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/research/SUMMARY.md`
- archived seed references in `.planning/seeds/`
- official Hex publishing guidance: https://hex.pm/docs/publish
- official Mix project docs: https://hexdocs.pm/mix/Mix.Project.html
- official ExDoc docs: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html
