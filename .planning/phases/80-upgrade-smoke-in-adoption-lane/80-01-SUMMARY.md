---
phase: 80-upgrade-smoke-in-adoption-lane
plan: 01
subsystem: testing
tags: [hex, upgrade-smoke, fixture, fingerprint, drift-guard]

requires:
  - phase: 78-hex-consumer-contract-foundation
    provides: HexConsumerContract SSOT and tarball dep helpers
  - phase: 79-tarball-consumer-overlay-proof
    provides: Host proof harness patterns
provides:
  - Committed v0.1.0 frozen hex unpack fixture with drift stamp
  - baseline_unpack_root!/0, baseline_package_fingerprint/0, same_semver_content_upgrade?/0
  - Maintainer refresh task and fixture drift guard tests
affects: [80-02, 80-03, host_app_upgrade_proof]

tech-stack:
  added: []
  patterns:
    - "Committed frozen baseline unpack separate from HEAD tarball cache (D-50)"
    - "Stamp fingerprint + git SHA drift guard (D-51)"
    - "SCORIA_HEX_BASELINE_UNPACK_ROOT maintainer override, never CI (D-52)"

key-files:
  created:
    - test/fixtures/hex_consumer/scoria-0.1.0-unpack/
    - test/fixtures/hex_consumer/.scoria-hex-baseline.stamp
    - lib/mix/tasks/scoria.hex_consumer.refresh_baseline_fixture.ex
    - test/scoria/hex_consumer_baseline_fixture_test.exs
  modified:
    - lib/scoria/hex_consumer_contract.ex
    - test/scoria/hex_consumer_contract_test.exs

key-decisions:
  - "Baseline fingerprint 505300b825f9 from v0.1.0 tag package files — distinct from HEAD 07222b27e349"
  - "Fixture package files parsed from committed mix.exs for fingerprint parity with package_fingerprint/0"

patterns-established:
  - "Phase 80 content-revision upgrade uses committed fixture; Phase 81 owns registry semver"

requirements-completed: [HEX-UPGRADE-01]

duration: 8min
completed: 2026-05-29
---

# Phase 80 Plan 01: Baseline Fixture + Contract APIs Summary

**Committed v0.1.0 hex unpack fixture with fingerprint drift guard and HexConsumerContract baseline APIs for upgrade smoke proof**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-29T21:24:00Z
- **Completed:** 2026-05-29T21:32:07Z
- **Tasks:** 3
- **Files modified:** 225

## Accomplishments

- Frozen v0.1.0 unpack tree committed at `test/fixtures/hex_consumer/scoria-0.1.0-unpack/` from git tag `v0.1.0`
- Drift stamp records fingerprint `505300b825f9` and tag SHA `49f2d60018c4c79fbc09969116526c48454a8e84`
- `HexConsumerContract` baseline APIs enable content-revision upgrade detection (`same_semver_content_upgrade?/0` true at HEAD)
- Maintainer refresh task and policy tests guard fixture integrity

## Task Commits

Each task was committed atomically:

1. **Task 80-01-01: Build and commit v0.1.0 baseline unpack fixture** - `5cef8b1` (feat)
2. **Task 80-01-02: Add HexConsumerContract baseline APIs** - `7c17d57` (feat)
3. **Task 80-01-03: Refresh task, contract tests, fixture drift guard** - `1cb4657` (feat)

## Files Created/Modified

- `test/fixtures/hex_consumer/scoria-0.1.0-unpack/` - Frozen 0.1.0 hex.build unpack tree (222 files)
- `test/fixtures/hex_consumer/.scoria-hex-baseline.stamp` - Fingerprint + git SHA drift guard
- `lib/scoria/hex_consumer_contract.ex` - baseline_unpack_root!/0, baseline_package_fingerprint/0, same_semver_content_upgrade?/0
- `lib/mix/tasks/scoria.hex_consumer.refresh_baseline_fixture.ex` - Maintainer-only refresh from v0.1.0 tag
- `test/scoria/hex_consumer_contract_test.exs` - Baseline path and upgrade signal assertions
- `test/scoria/hex_consumer_baseline_fixture_test.exs` - Stamp fingerprint/SHA policy test

## Decisions Made

- Baseline fingerprint computed from v0.1.0 package file list (not HEAD's expanded docs set) — matches published 0.1.0 artifact
- Fixture excluded from mix.exs `:package` `:files`; directory not gitignored per D-52

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Verification Results

- `MIX_ENV=test mix test test/scoria/hex_consumer_contract_test.exs test/scoria/hex_consumer_baseline_fixture_test.exs` — 8 tests, 0 failures
- `MIX_ENV=test mix compile --warnings-as-errors` — pass
- `mix help scoria.hex_consumer.refresh_baseline_fixture` — task registered

## Next Phase Readiness

Ready for 80-02: `Runner.run_upgrade_proof!/2`, `expected_upgrade_steps/1`, and `Generator.bump_unpack_dep!/2`.

## Self-Check: PASSED

- All key files exist on disk
- Task commits 5cef8b1, 7c17d57, 1cb4657 present in git log
- All acceptance criteria and plan verification commands pass

---
*Phase: 80-upgrade-smoke-in-adoption-lane*
*Completed: 2026-05-29*
