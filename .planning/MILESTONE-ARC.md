# Milestone Arc: Scoria

**Created:** 2026-05-12
**Last updated:** 2026-05-22
**Status:** maintained planning artifact

## Purpose

Keep a rolling, prioritized view of the next 2-4 milestones so Scoria keeps moving toward being the principle-of-least-surprise AI quality layer for real Phoenix applications.

This file is the strategic source of truth for milestone sequencing. It should be consulted before starting a new milestone and updated when a shipped milestone changes what should come next.

## Product North Star

Scoria should feel like the obvious thing Phoenix teams reach for when they need AI observability, durable agent workflow state, retrieval grounding, approvals, evaluation, and guardrailed tool use inside an existing application.

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
5. Keep future bets visible, but do not promote them ahead of missing product basics without an explicit decision.

## Milestone Ledger

| Version | Name | Status | Notes |
|---------|------|--------|-------|
| v1.0 | MVP | shipped | Observability, MCP governance, operator UX, evaluation |
| v1.1 | Caldera | shipped | Durable workflows and handoffs |
| v1.2 | Corpus | shipped | Knowledge, citations, grounding |
| v1.3 | Seismograph | shipped | SRE budgets, breakers, telemetry, audit, incident delivery |
| v1.4 | Keystone | shipped | Identity, sessions, public runtime API, install defaults, docs |
| v1.5 | Switchyard | shipped | Remote MCP connector productization |
| v1.6 | Flightpath | shipped | Release gates, prompt lifecycle, and evaluation operations |
| v1.7 | Outrider | shipped | Advanced ecosystem integrations and future-bet runtime surfaces |
| v1.8 | Vanguard | shipped | Multi-model orchestration, distributed evaluations, and reconciled shipped milestone truth |

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

No active milestone. `v1.8 Vanguard` is shipped, and the next milestone has not been opened yet.

## Recommended Candidates

### 1. Next milestone discovery

**Status:** pending
**Priority:** highest
**Theme:** Define the next adoption-relevant milestone

**What this step should deliver**

- a fresh requirements surface and roadmap via `$gsd-new-milestone`
- explicit prioritization against Scoria's Phoenix-first product shape
- a clear choice between adoption basics, operator trust improvements, and future-bet capability expansion

**Why this is first**

There is no active milestone after `v1.8`. The next correct move is to choose the next milestone deliberately instead of carrying closure-era assumptions forward.

## Recommendation

Run `$gsd-new-milestone` when you want to open the next milestone.

## Source Notes

These priorities were informed by:

- current repo state as of 2026-05-17
- `.planning/research/milestone-options-2026-05-12.md`
- `.planning/research/v1.5-switchyard-recommendation.md`
- archived seed references in `.planning/seeds/`
