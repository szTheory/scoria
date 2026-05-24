# Milestone Arc: Scoria

**Created:** 2026-05-12
**Last updated:** 2026-05-24
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

Shipped through `v1.9 Crucible` on 2026-05-24:

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

Repo-local current truth also includes an unarchived post-`v1.9` adoption wedge:

- public `Scoria.start_handoff_run/3` bounded handoff API over the existing durable workflow substrate
- projected-context defaults and unsafe-key rejection for delegated runs
- handoff docs/source checks plus `mix test.adoption` env-default cleanup
- thin connector/compaction/dashboard shims to keep the normal adoption lane from leaking missing-module drift

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
| v2.0 | Relay | active | Formalize and verify the bounded public handoff wedge already present in the repo |

## Latest Shipped Milestone

### v1.9 Crucible

**Status:** shipped
**Priority at close:** highest
**Theme:** Replayable debugging and online quality feedback

**What shipped**

- replay branches rooted in durable checkpoint truth without mutating original run history
- replay-safe execution defaults with explicit seam-level provenance
- replay comparison and workflow-source dataset promotion in the operator UI
- asynchronous online scoring with a review queue and explicit approval boundaries

**User-facing outcome**

Teams can inspect, replay, score, and promote production workflow evidence through a single embedded operator loop without blurring observed behavior with sealed release truth.

## Active Milestone

### v2.0 Relay

**Status:** active
**Priority at activation:** highest
**Theme:** Formalize and verify the bounded public handoff lane

**What this milestone is expected to deliver**

- canonical milestone proof for the already-implemented `Scoria.start_handoff_run/3` lane
- final support truth for delegated lineage, projected-context safety, and adoption-lane docs
- an explicit answer on whether any remaining handoff work is real adopter value or merely deferable polish

**Why now**

The implementation wedge already exists in the repo, so the main remaining risk is support-truth and verification drift. Activating this milestone keeps Scoria from carrying an ambiguous half-shipped handoff story into the next capability bet.

## Recommended Candidates

### 1. Tenant-scoped semantic fast path

**Status:** pending
**Priority:** medium
**Theme:** Inspectable semantic caching for safe read-only classes of work

**What this step should deliver**

- bounded tenant-scoped semantic caching with durable hit/miss evidence
- prompt/version/source-aware invalidation
- operator-visible cache diagnostics instead of invisible magic

**Why it remains second**

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

Complete `v2.0 Relay` before opening another new milestone. If the bounded handoff lane closes cleanly, tenant-scoped semantic fast path remains the strongest next major candidate; if real adopter confusion remains, revisit the docs/example candidate first.

## Source Notes

These priorities were informed by:

- current repo state as of 2026-05-24
- `.planning/research/milestone-options-2026-05-12.md`
- archived seed references in `.planning/seeds/`
- repo-local prompt research in `prompts/`
- current official docs for OpenAI Agents SDK, LangGraph, Braintrust, Langfuse, Arize Phoenix, Jido, OpenInference, and MCP authorization
