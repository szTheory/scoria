---
gsd_state_version: 1.0
milestone: v2.10
milestone_name: Hex Consumer Proof & Upgrade Smoke
status: executing
last_updated: "2026-05-29T19:43:17Z"
last_activity: 2026-05-29 -- Completed 78-01-PLAN.md
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 3
  completed_plans: 1
  percent: 33
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-29)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Phase 78 — hex-consumer-contract-foundation (plan 78-02 next)

## Current Position

Phase: 78 (hex-consumer-contract-foundation) — EXECUTING
Plan: 2 of 3 (78-02 unpack cache next)
Status: Plan 78-01 complete — HexConsumerContract SSOT + drift guards shipped
Last activity: 2026-05-29 -- Completed 78-01-PLAN.md

## Performance Metrics

- **Active milestone:** `v2.10 Hex Consumer Proof & Upgrade Smoke` (5 phases, 4 requirements)
- **Latest Shipped Milestone:** `v2.9 Adoption Journey & Reference Demo` on 2026-05-29
- **Hex release:** `0.1.0` at git tag `v0.1.0` — https://hex.pm/packages/scoria
- **Phase 78 progress:** 1/3 plans complete (78-01)

## Accumulated Context

### Roadmap Evolution

- **v2.10 (executing):** Tarball consumer proof in adoption closeout; upgrade smoke; post-publish registry gate; HexConsumerContract docs alignment.
- **Phase 78-01 (complete):** `Scoria.HexConsumerContract` SSOT, unit drift guards, `package_surface_test` contract import.
- **v2.9 (shipped):** SupportJourney SSOT, host-proof overlay expansion, `examples/support_copilot/` gallery, advisory `mix scoria.test.support_copilot`, phases 77.1/77.2 audit closure.

### Decisions

- HexConsumerContract separate from AdopterDocContract — capability prose vs Hex mechanics (D-05, 78-01)
- ensure_current_unpack_root!/0 stub until 78-02 implements fingerprint cache (D-10 wave split, 78-01)

### Evidence

- `.planning/phases/78-hex-consumer-contract-foundation/78-01-SUMMARY.md` — plan 78-01 complete
- `.planning/REQUIREMENTS.md` — v2.10 requirements (HEX-CONSUMER-01, HEX-UPGRADE-01, HEX-REGISTRY-01, DOCS-HEX-01)
- `.planning/ROADMAP.md` — Phases 78–82

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| Phase 78-02 | ensure_current_unpack_root!/0 fingerprint cache | next |
| Phase 78-03 | Generator dep_mode + consumer proof + CI env | queued |
| v2.11+ | Orchestrator live wiring | queued |

## Operator Next Steps

- Execute plan 78-02 — unpack cache + package_surface_test hex preview refactor
- `/gsd-execute-phase 78` — continue phase execution
