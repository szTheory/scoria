# Milestone Arc: Scoria

**Created:** 2026-05-12
**Last updated:** 2026-05-17
**Status:** active planning artifact

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

Shipped through `v1.4 Keystone` on 2026-05-17:

- observability and trace storage
- MCP gateway and governance seams
- LiveView operator surface
- evaluation flywheel
- durable workflows and handoffs
- knowledge, citations, and grounding
- SRE budgets, breakers, audit lineage, incident routing, and telemetry
- canonical runtime identity, public runtime APIs, install defaults, adoption docs, and executable guardrails

`v1.5 Switchyard` is now active.

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
| v1.5 | Switchyard | active | Remote MCP connector productization |
| v1.6 | Flightpath | candidate | Release gates, prompt lifecycle, and evaluation operations |

## Latest Shipped Milestone

### v1.4 Keystone

**Status:** shipped
**Priority at close:** highest
**Theme:** Embedded app defaults, identity, and public runtime surface

**What shipped**

- explicit actor, tenant, and session identity as first-class runtime nouns
- a clean public `Scoria` runtime API for starting, resuming, and inspecting app-facing AI runs
- provider/model/prompt-policy configuration that matches Phoenix app expectations
- install and verification defaults that stay boring for normal Phoenix adoption
- documentation and example flows tied to executable proof lanes

**User-facing outcome**

A Phoenix team can install Scoria, wire a normal app request or chat/session flow into it, and get identity-aware traces, workflow state, approvals, and evidence without guessing where the product boundary is.

## Active Milestone

### v1.5 Switchyard

**Status:** active
**Priority:** highest
**Theme:** Tool and MCP connector productization

**What this milestone should deliver**

- remote MCP connector support with boring discovery, auth, and capability refresh defaults
- policy-backed tool scopes and workflow-owned approval UX for remote connector invocations
- stronger audit and operator visibility for connector identity, grants, approvals, and access failures
- a small curated connector/profile layer that improves DX without turning Scoria into a hosted connector marketplace

**How this milestone is intentionally bounded**

- stateless-first remote invocation is the default path
- stateful remote session lifecycle is opt-in per connector, not the default milestone center
- browser/code-exec productization remains out of scope
- hosted connector-broker behavior remains out of scope

**Why now**

Keystone clarified Scoria's app-facing identity, runtime API, and boring install path. The next highest-leverage step is extending those same public boundaries into remote tool connectivity before adding release-ops or future-bet runtime surfaces.

**Depends on**

- `v1.4 Keystone`

## Recommended Candidates

### 1. v1.6 Flightpath

**Status:** candidate
**Priority:** medium
**Theme:** Release gates, prompt lifecycle, and evaluation operations

**What this milestone should deliver**

- first-class prompt/version registry tied to traces and evals
- dataset curation, baseline comparisons, and approval-to-release gates
- CI-friendly regression workflows that let teams prove a change is safe before rollout
- better operator storytelling from trace -> dataset -> eval run -> decision

**Why this matters**

Teams expect to iterate on prompts, models, and tools without flying blind. Scoria already has part of the eval substrate; this milestone would turn it into a more complete release discipline.

**Depends on**

- `v1.4 Keystone`
- ideally `v1.5 Switchyard` for tool-aware evaluation coverage

### 2. v1.7 Outrider

**Status:** candidate
**Priority:** medium
**Theme:** Advanced ecosystem integrations and future-bet runtime surfaces

**What this milestone could deliver**

- optional deep integrations with external agent runtimes or hosted tool systems
- more advanced memory/session compaction strategies
- multi-runtime interoperability without giving up the embedded Phoenix shape

**Why this is not first**

This is valuable, but it is a future bet. It should not outrank the work required to make Scoria feel complete and unsurprising in ordinary Phoenix adoption paths.

## Recommendation

The active milestone is `v1.5 Switchyard`. The next recommendation after it remains `v1.6 Flightpath`.

## Source Notes

These priorities were informed by:

- current repo state as of 2026-05-17
- `.planning/research/milestone-options-2026-05-12.md`
- `.planning/research/v1.5-switchyard-recommendation.md`
- dormant `SEED-001-agentcore-lessons`
