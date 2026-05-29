---
gsd_state_version: 1.0
milestone: v2.10
milestone_name: Hex Consumer Proof & Upgrade Smoke
status: executing
last_updated: "2026-05-29T20:13:00Z"
last_activity: 2026-05-29 -- Completed 78-03-PLAN.md
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 3
  completed_plans: 3
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-29)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Phase 78 complete — ready for Phase 79 tarball consumer overlay proof

## Current Position

Phase: 78 (hex-consumer-contract-foundation) — COMPLETE
Plan: 3 of 3 (78-03 harness + CI env complete)
Status: Phase 78 complete — tarball route adoption proof wired through HostAppProof harness
Last activity: 2026-05-29 -- Completed 78-03-PLAN.md

## Performance Metrics

- **Active milestone:** `v2.10 Hex Consumer Proof & Upgrade Smoke` (5 phases, 4 requirements)
- **Latest Shipped Milestone:** `v2.9 Adoption Journey & Reference Demo` on 2026-05-29
- **Hex release:** `0.1.0` at git tag `v0.1.0` — https://hex.pm/packages/scoria
- **Phase 78 progress:** 3/3 plans complete (78-01, 78-02, 78-03)

## Accumulated Context

### Roadmap Evolution

- **v2.10 (executing):** Tarball consumer proof in adoption closeout; upgrade smoke; post-publish registry gate; HexConsumerContract docs alignment.
- **Phase 78 (complete):** HexConsumerContract SSOT, fingerprinted unpack cache, tarball route adoption harness + CI env reuse.
- **v2.9 (shipped):** SupportJourney SSOT, host-proof overlay expansion, `examples/support_copilot/` gallery, advisory `mix scoria.test.support_copilot`, phases 77.1/77.2 audit closure.

### Decisions

- HexConsumerContract separate from AdopterDocContract — capability prose vs Hex mechanics (D-05, 78-01)
- ensure_current_unpack_root!/0 fingerprint cache with O_EXCL lock fallback on OTP 28 (78-02)
- Shared cache tmp/scoria-hex-consumer/ never deleted in test on_exit (D-10, 78-02)
- Generator requires explicit dep_mode :hex_tarball | :path — no silent repo-root default (78-03)
- Phase 78 adoption proves tarball dep + route smoke only; full overlay in Phase 79 (78-03)

### Evidence

- `.planning/phases/78-hex-consumer-contract-foundation/78-03-SUMMARY.md` — plan 78-03 complete
- `.planning/REQUIREMENTS.md` — v2.10 requirements (HEX-CONSUMER-01, HEX-UPGRADE-01, HEX-REGISTRY-01, DOCS-HEX-01)
- `.planning/ROADMAP.md` — Phases 78–82

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| Phase 79 | Full overlay tarball consumer proof (run_full_proof!/1) | next |
| v2.11+ | Orchestrator live wiring | queued |

## Operator Next Steps

- Plan Phase 79 — switch consumer test to run_full_proof!/1 with full overlay from tarball dep
- `/gsd-plan-phase 79` — tarball consumer overlay proof
