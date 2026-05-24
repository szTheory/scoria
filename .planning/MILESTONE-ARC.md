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

No active milestone. `v1.9 Crucible` is shipped, and the next milestone should be opened explicitly.

## Recommended Candidates

### 1. Bounded handoff productization

**Status:** pending
**Priority:** medium
**Theme:** Public role handoffs without platform drift

**What this step should deliver**

- a narrow public handoff contract over existing durable workflow seams
- projected-context and least-privilege defaults that remain inspectable
- richer operator evidence for delegated role lineage

**Why it is a strong next candidate**

The handoff substrate already exists, and `v1.9` established the replay/score operator loop it would build on. A bounded public handoff layer now compounds existing workflow truth without requiring managed-platform drift.

### 2. Tenant-scoped semantic fast path

**Status:** pending
**Priority:** medium
**Theme:** Inspectable semantic caching for safe read-only classes of work

**What this step should deliver**

- bounded tenant-scoped semantic caching with durable hit/miss evidence
- prompt/version/source-aware invalidation
- operator-visible cache diagnostics instead of invisible magic

**Why it remains second**

Semantic caching is still valuable, but it is a latency/cost optimization with higher correctness and privacy risk. It should still follow the newly shipped replay and scoring trust loop.

## Recommendation

Run `$gsd-new-milestone` to open the next milestone when ready. If priorities remain unchanged, bounded handoff productization is the strongest starting candidate.

## Source Notes

These priorities were informed by:

- current repo state as of 2026-05-22
- `.planning/research/milestone-options-2026-05-12.md`
- archived seed references in `.planning/seeds/`
- repo-local prompt research in `prompts/`
- current official docs for OpenAI Agents SDK, LangGraph, Braintrust, Langfuse, Arize Phoenix, Jido, OpenInference, and MCP authorization
