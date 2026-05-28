# Milestone Arc: Scoria

**Created:** 2026-05-12
**Last updated:** 2026-05-27
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

Shipped through **`v2.5 Installer Safety & Upgrade Confidence`** on **2026-05-27**:

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
- delegated evidence surfaces, runtime-first adoption proof, and canonical runtime-to-handoff proof lane
- tenant-scoped semantic fast-path lookup, compatibility-aware invalidation, operator-visible semantic evidence, and a named semantic proof lane
- publish-facing package/docs truth, generated-host adoption proof, and canonical lane-based maintainer/adopter closeout chain
- planner-driven installer `--dry-run` / `--check`, manifest-aware drift-safe apply, and `Scoria.Install.Contract` SSOT

**Done estimate (2026-05-27 assessment):** ~84% for embedded Phoenix AI-ops scope — feature-strong; remaining leverage is maintainer/adopter trust (warnings, Hex, docs-truth), not net-new runtime families.

## Sequencing Principles

1. Prioritize adoption prerequisites before adjacent capability expansion.
2. Prefer milestones that make existing power easier to use in Phoenix apps over milestones that only add more raw surface area.
3. Keep Scoria embedded and boundary-driven; do not drift into a hosted runtime product.
4. Promote milestones that improve installability, public API clarity, and operator trust.
5. Close warning and release-truth gaps before reopening capability expansion.

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
| v2.3 | Runtime-to-handoff adoption example | shipped | Default-to-handoff example, operator evidence, runtime-to-handoff proof lane |
| v2.4 | Adoption Reliability Contract | shipped | Canonical lane contracts, warning baseline, CI lane-order enforcement |
| v2.5 | Installer Safety & Upgrade Confidence | shipped | Planner/check no-write, drift-safe apply, installer contract SSOT |
| v2.6 | Warning Ratchet | **active** | `WARN-03`–`WARN-07` staged WAE ratchet + executable baseline expiry |
| v2.7 | OSS Release + Docs Truth | queued | Hex publish, README shipped-state, drift-test alignment |

## Latest Shipped Milestone

### v2.5 Installer Safety & Upgrade Confidence

**Status:** shipped (2026-05-27)
**Theme:** Make host-app installer mutations predictable, inspectable, and drift-safe before applying writes

**What shipped**

- planner-driven `--dry-run` and `--check` with deterministic no-write surfaces and stable tri-state exits
- manifest-aware drift detection and planner-led apply preflight
- `Scoria.Install.Contract` SSOT, mode equivalence proofs, Nyquist closeout (phases 59–65)

**User-facing outcome**

Adopters can inspect and trust installer mutations before apply, closing the highest remaining host-app surprise risk after v2.4 reliability contracts.

## Active Milestone

### v2.6 Warning Ratchet (`WARN-03`)

**Status:** active (initialized 2026-05-27; phases 66–69)
**Theme:** Staged full-suite warning governance with executable baseline policy

**What this step should deliver**

- inventory and staged ratchet of full-suite warnings (high-signal areas first)
- executable CI check that fails on expired rows in `.planning/WARNING-BASELINE.md`
- unchanged canonical closeout order: `release_preview` → `adoption` → `runtime_to_handoff`

**Why it is next**

v2.5 closed installer trust. Canonical lanes are warning-clean; full-suite debt expires 2026-06-07. Maintainer trust requires WAE honesty before declaring OSS "done."

## Queued Milestones

### v2.7 OSS Release + Docs Truth

**Status:** queued after v2.6
**Theme:** Remove the largest remaining adopter friction — Hex install path and shipped-state honesty

**What this step should deliver**

- first Hex publish (or documented release process with aligned version tags)
- README and support docs reflecting v2.5+ shipped capability
- coordinated update of `adoption_surface_test` shipped-state assertions (currently require v2.1 wording)

### Optional follow-ups (not sequenced as milestones yet)

- semantic lane in CI (without widening closeout order unless deliberate)
- narrow `docs/remote_connectors.md` with embedded-boundary framing
- LiveView async teardown hygiene (WARNING-BASELINE expiry 2026-06-30)

## Deferred / Out of Arc

- new runtime capability families until v2.6 + v2.7 close
- package-family Hex split, hosted onboarding, broad handoff example catalogs
- external semantic cache backends and advanced tuning

## Recommendation

Run `/gsd-new-milestone` for **v2.6 Warning Ratchet only**. Do not combine with Hex publish, semantic CI, or connector docs. After v2.6 ships, open v2.7 for OSS/docs-truth. Then mostly stop on feature milestones unless support burden proves otherwise.

## Source Notes

These priorities were informed by:

- milestone next-step assessment 2026-05-27
- `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/MILESTONES.md`
- `.planning/threads/2026-05-27-warning-ratchet-followup.md`
- `.planning/WARNING-BASELINE.md`
