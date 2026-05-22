# Milestone Arc: Scoria

**Created:** 2026-05-12
**Last updated:** 2026-05-22
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

Shipped through `v1.8 Vanguard` on 2026-05-22:

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
| v1.9 | Crucible | active | Replayable debugging and online quality feedback |

## Latest Shipped Milestone

### v1.8 Vanguard

**Status:** shipped
**Priority at close:** highest
**Theme:** Multi-model orchestration and distributed evaluations

**What shipped**

- breaker-aware multi-model routing with automatic fallback
- distributed eval campaign fan-out and worker execution through Oban
- tenant-scoped LiveView model-health and campaign dashboards
- reconciled planning surfaces anchored to the canonical verification chain

**User-facing outcome**

Teams can run resilient multi-model workloads at scale and inspect fallback, health, and campaign progress through the embedded operator surface.

## Active Milestone

### v1.9 Crucible

**Status:** active
**Priority:** highest
**Theme:** Replayable debugging and online quality feedback

**What this milestone should deliver**

- replay branches as durable new runs rooted in existing checkpoint truth
- replay-safe execution defaults for external-write and approval-sensitive seams
- operator-visible replay provenance, diff context, and draft dataset promotion
- asynchronous online scoring with a review queue and explicit promotion boundaries

**Why now**

Scoria already has durable runs, trace-first UI, trace-to-dataset promotion, eval fan-out, and operator dashboards. The next highest-leverage move is to close the operator remediation loop instead of expanding into broader agent-platform or performance-optimization bets.

## Recommended Candidates

### 1. Bounded handoff productization

**Status:** pending
**Priority:** medium
**Theme:** Public role handoffs without platform drift

**What this step should deliver**

- a narrow public handoff contract over existing durable workflow seams
- projected-context and least-privilege defaults that remain inspectable
- richer operator evidence for delegated role lineage

**Why it is after v1.9**

The handoff substrate already exists, but replay and online scoring better compound Scoria's current trace/eval strengths with less risk of product-shape drift.

### 2. Tenant-scoped semantic fast path

**Status:** pending
**Priority:** medium
**Theme:** Inspectable semantic caching for safe read-only classes of work

**What this step should deliver**

- bounded tenant-scoped semantic caching with durable hit/miss evidence
- prompt/version/source-aware invalidation
- operator-visible cache diagnostics instead of invisible magic

**Why it is after v1.9**

Semantic caching is valuable, but it is a latency/cost optimization with higher correctness and privacy risk. It should follow, not precede, the replay and scoring loop that improves operator trust.

## Recommendation

Run `$gsd-plan-phase 37` to start executing `v1.9 Crucible`.

## Source Notes

These priorities were informed by:

- current repo state as of 2026-05-22
- `.planning/research/milestone-options-2026-05-12.md`
- archived seed references in `.planning/seeds/`
- repo-local prompt research in `prompts/`
- current official docs for OpenAI Agents SDK, LangGraph, Braintrust, Langfuse, Arize Phoenix, Jido, OpenInference, and MCP authorization
