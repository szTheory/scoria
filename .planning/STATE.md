---
gsd_state_version: 1.0
milestone: v2.9
milestone_name: Warning Ratchet
status: executing
last_updated: "2026-05-29T18:32:48Z"
last_activity: 2026-05-29 -- Completed 77.2-01-PLAN.md
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 3
  completed_plans: 2
  percent: 67
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-29)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Phase 77.2 — address-tech-debt-v2-9-planning-hygiene-ci-contract

## Current Position

Phase: 77.2 (address-tech-debt-v2-9-planning-hygiene-ci-contract) — EXECUTING
Plan: 2 of 2
Status: Ready for 77.2-02 (CI contract test)
Last activity: 2026-05-29 -- Completed 77.2-01-PLAN.md

## Performance Metrics

- **Latest Shipped Milestone:** `v2.8 CI Hardening & Post-Ship Hygiene` on 2026-05-29
- **Hex release:** `0.1.0` at git tag `v0.1.0` — https://hex.pm/packages/scoria
- **Active milestone:** v2.9 Adoption Journey & Reference Demo

## Accumulated Context

### Roadmap Evolution

- **Phase 77.1 (INSERTED, URGENT):** Close gap: DOCS-GALL-01 drift guard expansion — extend automated fragment pinning to README + operator verification (after Phase 77).
- **v2.9 (active):** SupportJourney SSOT, host-proof overlay expansion, `examples/support_copilot/` gallery, advisory `mix scoria.test.support_copilot`.
- **v2.8 (shipped):** Semantic lane WAE, knowledge WAE, inventory baseline policy gate.
- **v2.7 (shipped):** Docs truth → release infra → Hex publish + README flip.
- Phase 77.2 inserted after Phase 77: Address tech debt: v2.9 planning hygiene + CI contract (URGENT)

### Evidence

- `.planning/threads/2026-05-29-adoption-journey-assessment.md` — v2.9 scope decision
- `.planning/REQUIREMENTS.md` — JOURN/HOST/GALL/CI-GALL requirements
- `.planning/v2.9-MILESTONE-AUDIT.md` — DOCS-GALL-01 partial drift guard gap
- `.planning/ROADMAP.md` — Phases 74–77.2
- `.planning/v2.9-MILESTONE-AUDIT.md` — tech debt items driving Phase 77.2

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| v2.10+ | Hex consumer proof | queued |
| v2.11+ | Orchestrator live wiring | queued |

## Operator Next Steps

- Execute plan 77.2-02 — `ci_policy_contract_test.exs` gallery-after-knowledge ordering
- `/gsd-execute-phase 77.2` — continue phase 77.2 execution
