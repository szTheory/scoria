---
gsd_state_version: 1.0
milestone: v2.10
milestone_name: Hex Consumer Proof & Upgrade Smoke
status: planning
last_updated: "2026-05-30T00:23:19.150Z"
last_activity: 2026-05-29
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 9
  completed_plans: 9
  percent: 60
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-29)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Phase 81 — post publish registry gate

## Current Position

Phase: 81
Plan: Not started
Status: Ready to plan
Last activity: 2026-05-29

## Performance Metrics

- **Active milestone:** `v2.10 Hex Consumer Proof & Upgrade Smoke` (5 phases, 4 requirements)
- **Latest Shipped Milestone:** `v2.9 Adoption Journey & Reference Demo` on 2026-05-29
- **Hex release:** `0.1.0` at git tag `v0.1.0` — https://hex.pm/packages/scoria
- **Phase 78 progress:** 3/3 plans complete
- **Phase 79 progress:** 3/3 plans complete
- **Phase 80 progress:** 3/3 plans complete

## Accumulated Context

### Roadmap Evolution

- **v2.10 (executing):** Tarball consumer proof in adoption closeout; upgrade smoke; post-publish registry gate; HexConsumerContract docs alignment.
- **Phase 80 (complete):** Content-revision upgrade smoke from v0.1.0 baseline fixture to HEAD tarball in adoption lane. See `80-VERIFICATION.md`.
- **Phase 79 (complete):** Full overlay tarball consumer proof (handoff + route + runtime), failure diagnostics, CI failure artifact upload. See `79-VERIFICATION.md`.
- **Phase 78 (complete):** HexConsumerContract SSOT, fingerprinted unpack cache, tarball route adoption harness + CI env reuse.
- **v2.9 (shipped):** SupportJourney SSOT, host-proof overlay expansion, `examples/support_copilot/` gallery, advisory `mix scoria.test.support_copilot`, phases 77.1/77.2 audit closure.

### Decisions

- HexConsumerContract separate from AdopterDocContract — capability prose vs Hex mechanics (D-05, 78-01)
- ensure_current_unpack_root!/0 fingerprint cache with O_EXCL lock fallback on OTP 28 (78-02)
- Shared cache tmp/scoria-hex-consumer/ never deleted in test on_exit (D-10, 78-02)
- Generator requires explicit dep_mode :hex_tarball | :path — no silent repo-root default (78-03)
- Consumer proof uses run_full_proof!/1 with derived expected_steps/1 — not run_route_proof!/1 (D-30, D-32, D-33, 79-01)
- Step order follows sorted overlay basenames: handoff → route → runtime (D-32, 79-01)
- @moduletag :host_proof enables mix test --only host_proof local iteration (D-43, 79-01)
- Warm full overlay ~50–58s — under D-36 p50 ≤90s; 180_000 module tag unchanged (D-34, D-36, 79-01)
- Triage raise includes replay/preserve hints; omits SCORIA_DB_PASSWORD (D-39, T-79-06, 79-02)
- SCORIA_PRESERVE_HOST opt-in skips on_exit rm_rf; default cleanup unchanged (D-40, D-44, 79-02)
- Failure snapshot at tmp/scoria-host-proof-last-failure/ with MANIFEST.txt; copy best-effort (D-41, 79-02)
- CI uploads failure snapshot on adoption lane failure only; 7-day retention; if-no-files-found ignore (D-42, 79-03)
- HEX-CONSUMER-01 milestone Complete at Phase 79; DOCS-HEX-01 prose sweep remains Phase 82 (D-45, D-46, 79-03)
- Committed frozen v0.1.0 unpack at test/fixtures/hex_consumer/scoria-0.1.0-unpack/ — not HEAD rebuild in CI (D-50, 80-01)
- Baseline stamp fingerprint + git SHA drift guard via baseline_package_fingerprint/0 (D-51, 80-01)
- SCORIA_HEX_BASELINE_UNPACK_ROOT maintainer-only env override — never CI (D-52, 80-01)
- same_semver_content_upgrade?/0 asserts HEAD fingerprint differs from baseline fixture (D-54, 80-01)
- run_upgrade_proof!/2 separate from run_full_proof!/1 — two-phase baseline then upgrade (D-57, 80-02)
- expected_upgrade_steps/1 flat baseline++upgrade list for exact assertion (D-58, 80-02)
- bump_dep runs deps.clean scoria after mix.exs repoint (D-59, 80-02)
- Installer check steps pin expect_exit and expect_trailer (D-60, 80-02)
- MANIFEST includes baseline_unpack, current_unpack, upgrade_phase; preserve uses host_upgrade (D-67, D-62, 80-02)
- Baseline overlays copied from v0.1.0 fixture; HEAD overlays refreshed after bump (80-03)
- Pre-apply install check accepts drift or compliant when install surfaces unchanged (80-03)
- Migration ordering criterion #4 latent — 24 identical migrations at v0.1.0 and HEAD (D-65, 80-03)
- HEX-UPGRADE-01 Complete at Phase 80; Phase 81 owns registry semver (D-55, D-68, 80-03)

### Evidence

- `.planning/phases/80-upgrade-smoke-in-adoption-lane/80-VERIFICATION.md` — Phase 80 passed verification ledger
- `.planning/phases/80-upgrade-smoke-in-adoption-lane/80-03-SUMMARY.md` — plan 80-03 complete
- `.planning/phases/80-upgrade-smoke-in-adoption-lane/80-02-SUMMARY.md` — plan 80-02 complete
- `.planning/phases/80-upgrade-smoke-in-adoption-lane/80-01-SUMMARY.md` — plan 80-01 complete
- `.planning/REQUIREMENTS.md` — HEX-UPGRADE-01 Complete (80)

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| Phase 81 | Live Hex registry post-publish gate | next |
| Phase 82 | DOCS-HEX-01 prose sweep + drift pins | queued |
| v2.11+ | Orchestrator live wiring | queued |

## Operator Next Steps

- `/gsd-plan-phase 81` — plan post-publish registry gate (HEX-REGISTRY-01)
