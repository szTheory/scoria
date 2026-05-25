# Milestone Arc: Scoria

**Created:** 2026-05-12
**Last updated:** 2026-05-25
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

Shipped through `v2.0 Relay` on 2026-05-25:

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

## Latest Shipped Milestone

### v2.0 Relay

**Status:** shipped
**Priority at close:** highest
**Theme:** Formalized bounded public handoff proof and clean closeout

**What shipped**

- explicit bounded public handoff contract rooted under the same durable run
- recursive projected-context safety with explicit rejection for unsafe delegated state
- curated delegated evidence surfaces in runtime detail and workflow UI
- runtime-first docs, checked examples, canonical `mix test.adoption` proof, and a fresh green full-suite `mix test` baseline

**User-facing outcome**

Teams can adopt delegated handoffs through one narrow, inspectable, Phoenix-first runtime lane without guessing about lineage ownership, projected-context safety, or how to prove the integration is working.

## Active Milestone

No active milestone yet. The next candidate should be opened only after choosing between the semantic fast path and any evidence-backed handoff-example follow-up.

## Recommended Candidates

### 1. Tenant-scoped semantic fast path

**Status:** pending
**Priority:** highest
**Theme:** Inspectable semantic caching for safe read-only classes of work

**What this step should deliver**

- bounded tenant-scoped semantic caching with durable hit/miss evidence
- prompt/version/source-aware invalidation
- operator-visible cache diagnostics instead of invisible magic

**Why it is first**

Semantic caching is still valuable, but it is a latency/cost optimization with higher correctness and privacy risk. It should still follow the newly shipped replay and scoring trust loop.

### 2. Advanced adoption examples only if handoff confusion remains

**Status:** pending
**Priority:** low
**Theme:** Clarify capability tiering without widening the product boundary

**What this step should deliver**

- one stronger runtime -> handoff -> review/replay guide or example if support burden remains high
- clearer lane-by-lane explanation of what typical Phoenix teams adopt first vs later

**Why it is third**

This is useful only if the new public handoff lane still feels hard to approach after verification and closeout. It should not outrank the semantic fast path unless real adopter confusion persists.

## Recommendation

Open the next milestone only after confirming whether post-Relay adopter evidence still points at bounded-handoff examples. Without that evidence, tenant-scoped semantic fast path remains the strongest next major candidate.

## Source Notes

These priorities were informed by:

- current repo state as of 2026-05-25
- `.planning/research/milestone-options-2026-05-12.md`
- archived seed references in `.planning/seeds/`
- repo-local prompt research in `prompts/`
- current official docs for OpenAI Agents SDK, LangGraph, Braintrust, Langfuse, Arize Phoenix, Jido, OpenInference, and MCP authorization
