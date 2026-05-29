---
phase: 80-upgrade-smoke-in-adoption-lane
plan: 03
subsystem: testing
tags: [hex, upgrade-smoke, adoption-lane, host-proof, closeout]

requires:
  - phase: 80-01
    provides: baseline fixture and HexConsumerContract baseline APIs
  - phase: 80-02
    provides: run_upgrade_proof!/2 and expected_upgrade_steps/1
provides:
  - Merge-blocking host_app_upgrade_proof_test.exs in adoption lane
  - HEX-UPGRADE-01 requirement Complete with 80-VERIFICATION.md
  - Baseline-compatible overlay sourcing for v0.1.0 upgrade phase
affects: [81-post-publish-registry-gate, mix-test-adoption]

tech-stack:
  added: []
  patterns:
    - "Baseline overlays from v0.1.0 fixture; HEAD overlays after bump (80-03)"
    - "Pre-apply install check accepts drift or compliant when surfaces unchanged"
    - "Per-phase overlay step atoms in expected_upgrade_steps/1"

key-files:
  created:
    - test/scoria/host_app_upgrade_proof_test.exs
    - .planning/phases/80-upgrade-smoke-in-adoption-lane/80-VERIFICATION.md
  modified:
    - lib/mix/tasks/test.adoption.ex
    - test/mix/tasks/test.adoption_test.exs
    - test/support/scoria/host_app_proof/generator.ex
    - test/support/scoria/host_app_proof/runner.ex
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "Baseline host copies overlays from v0.1.0 fixture; bump refreshes HEAD overlays for handoff/runtime"
  - "Pre-apply --check accepts compliant when install surfaces identical at same semver (content-revision)"
  - "Criterion #4 migration ordering documented latent — 24 identical migrations at v0.1.0 and HEAD"

patterns-established:
  - "@moduletag :host_upgrade for ~64s local iteration separate from :host_proof ~61s"
  - "HEX-UPGRADE-01 Complete only after green mix test.adoption in same plan tail"

requirements-completed: [HEX-UPGRADE-01]

duration: 25min
completed: 2026-05-29
---

# Phase 80 Plan 03: Upgrade Test + Adoption Lane Closeout Summary

**Merge-blocking content-revision upgrade smoke wired into adoption lane with v0.1.0 baseline overlays, HEX-UPGRADE-01 traceability, and Phase 80 verification ceremony**

## Performance

- **Duration:** 25 min
- **Started:** 2026-05-29T21:20:00Z
- **Completed:** 2026-05-29T21:45:00Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- `host_app_upgrade_proof_test.exs` proves two-phase upgrade from v0.1.0 baseline to HEAD tarball on same host
- Adoption lane includes upgrade proof; guard test updated
- `80-VERIFICATION.md` passed with criteria 1–3 green and criterion #4 latent
- HEX-UPGRADE-01 marked Complete; Phase 80 closed; STATE focus → Phase 81

## Task Commits

Each task was committed atomically:

1. **Task 80-03-01: Create host_app_upgrade_proof_test.exs** - `987a2a7` (test)
2. **Task 80-03-02: Register upgrade test in adoption lane** - `31205f9` (feat)
3. **Task 80-03-03: Phase 80 verification and closeout ceremony** - `96bf464` (docs)

## Files Created/Modified

- `test/scoria/host_app_upgrade_proof_test.exs` - Content-revision upgrade proof with `:host_upgrade` tag
- `test/support/scoria/host_app_proof/generator.ex` - `overlay_source` option and `refresh_overlay!/2`
- `test/support/scoria/host_app_proof/runner.ex` - Per-phase overlay steps; flexible pre-apply check
- `lib/mix/tasks/test.adoption.ex` - Added upgrade test to adoption file list
- `test/mix/tasks/test.adoption_test.exs` - Guard list updated
- `.planning/phases/80-upgrade-smoke-in-adoption-lane/80-VERIFICATION.md` - Passed verification ledger

## Decisions Made

- v0.1.0 baseline lacks SupportJourney — baseline overlays sourced from fixture, not HEAD
- Pre-apply `--check` returns compliant (not drift) when install surfaces unchanged between baseline and HEAD
- Migration ordering proof deferred as latent until first post-0.1.0 migration ships

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Baseline overlay incompatibility with v0.1.0 dep**
- **Found during:** Task 1 (upgrade proof test)
- **Issue:** HEAD overlay tests reference SupportJourney absent from v0.1.0 tarball; baseline overlay_smoke failed
- **Fix:** Added `overlay_source` to Generator; baseline overlays from fixture; `refresh_overlay!` after bump
- **Files modified:** generator.ex, runner.ex, host_app_upgrade_proof_test.exs
- **Verification:** `mix test --only host_upgrade` green
- **Committed in:** `987a2a7`

**2. [Rule 1 - Bug] Pre-apply install check expected drift but got compliant**
- **Found during:** Task 1 (upgrade proof test)
- **Issue:** Identical install surfaces at v0.1.0 and HEAD cause `--check` to return compliant after dep bump
- **Fix:** `scoria_install_check_pre_apply!` accepts drift or compliant via `accept_check_results`
- **Files modified:** runner.ex
- **Verification:** Full upgrade proof passes
- **Committed in:** `987a2a7`

---

**Total deviations:** 2 auto-fixed (2 bugs)
**Impact:** Both fixes required for correct content-revision upgrade proof at same semver. No scope creep.

## Issues Encountered

None beyond auto-fixed overlay and pre-apply check behavior.

## User Setup Required

None - no external service configuration required.

## Verification Results

- `MIX_ENV=test mix test --only host_upgrade` — PASS — 1 test, ~64s
- `MIX_ENV=test mix test test/mix/tasks/test.adoption_test.exs` — PASS — 1 test
- `MIX_ENV=test mix test.adoption` — PASS — 52 tests, ~116s

## Next Phase Readiness

Phase 80 complete. Ready for Phase 81: live Hex registry post-publish gate (HEX-REGISTRY-01).

## Self-Check: PASSED

- Key files exist on disk
- Task commits 987a2a7, 31205f9, 96bf464 present in git log
- All acceptance criteria and plan verification commands pass

---
*Phase: 80-upgrade-smoke-in-adoption-lane*
*Completed: 2026-05-29*
