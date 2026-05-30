---
phase: 80-upgrade-smoke-in-adoption-lane
plan: 02
subsystem: testing
tags: [hex, upgrade-smoke, host-proof, installer-trailers]

requires:
  - phase: 80-01
    provides: baseline fixture and HexConsumerContract baseline APIs
provides:
  - Generator.bump_unpack_dep!/2 for in-place tarball repoint
  - run_mix! expect_exit/expect_trailer and installer step helpers
  - run_upgrade_proof!/2 and expected_upgrade_steps/1 orchestration
  - Upgrade-aware MANIFEST and host_upgrade preserve replay hints
affects: [80-03, host_app_upgrade_proof_test]

tech-stack:
  added: []
  patterns:
    - "Two-phase upgrade proof without extending run_full_proof!/1 (D-57)"
    - "Exact expected_upgrade_steps flat list for assertion parity (D-58)"
    - "deps.clean scoria after bump before deps.get (D-59)"
    - "Installer tri-state trailer pins on check steps (D-60)"
    - "MANIFEST baseline_unpack/current_unpack/upgrade_phase on failure (D-67)"

key-files:
  created: []
  modified:
    - test/support/scoria/host_app_proof/generator.ex
    - test/support/scoria/host_app_proof/runner.ex

key-decisions:
  - "Upgrade phase overlay smokes run after post-upgrade compliant --check per D-58 step order"
  - "preserve replay uses --only host_upgrade when upgrade_phase is set on host"
  - "bump_dep atom covers mix.exs rewrite plus deps.clean scoria in one tracked step"

patterns-established:
  - "run_host_steps!/2 threads host map updates through bump_dep boundary"
  - "Compliant check trailer pinned via @compliant_check_trailer module attribute"

requirements-completed: [HEX-UPGRADE-01]

duration: 10min
completed: 2026-05-29
---

# Phase 80 Plan 02: Runner Upgrade Orchestration Summary

**Host proof Runner and Generator extended with two-phase upgrade orchestration, installer trailer assertions, and upgrade-aware failure MANIFEST**

## Performance

- **Duration:** 10 min
- **Started:** 2026-05-29T21:24:00Z
- **Completed:** 2026-05-29T21:33:52Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- `Generator.bump_unpack_dep!/2` repoints host mix.exs tarball path and updates `host.unpack_root`
- `run_mix!/4` supports `expect_exit` and `expect_trailer`; dedicated installer check/dry-run helpers
- `run_upgrade_proof!/2` runs baseline install → bump → operator chain → re-smoke on same host
- `expected_upgrade_steps/1` returns exact flat baseline ++ upgrade step list per D-58
- Failure MANIFEST and preserve hints include upgrade context and `--only host_upgrade` replay

## Task Commits

Each task was committed atomically:

1. **Task 80-02-01: Add Generator.bump_unpack_dep!/2** - `6748965` (feat)
2. **Task 80-02-02: Extend run_mix! with expect_exit and expect_trailer** - `402df5a` (feat)
3. **Task 80-02-03: Add run_upgrade_proof!/2 and expected_upgrade_steps/1** - `49b97f4` (feat)

## Files Created/Modified

- `test/support/scoria/host_app_proof/generator.ex` - `bump_unpack_dep!/2` rewrites {:scoria, path: ...} dep line
- `test/support/scoria/host_app_proof/runner.ex` - upgrade orchestration, installer helpers, MANIFEST/triage extensions

## Decisions Made

- Upgrade overlay smokes execute after post-upgrade `scoria_install_check` to match D-58 canonical step order
- Single `:bump_dep` step records deps.clean after Generator patch (Runner owns deps.get separately)
- Preserve replay tag switches to `host_upgrade` when `upgrade_phase` is set on host struct

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Verification Results

- `rg -n 'def bump_unpack_dep!' test/support/scoria/host_app_proof/generator.ex` — PASS
- `rg -n 'expect_trailer' test/support/scoria/host_app_proof/runner.ex` — PASS
- `rg -n 'def run_upgrade_proof!' test/support/scoria/host_app_proof/runner.ex` — PASS
- `rg -n 'def expected_upgrade_steps' test/support/scoria/host_app_proof/runner.ex` — PASS
- `rg -n 'upgrade_phase' test/support/scoria/host_app_proof/runner.ex` — PASS
- `MIX_ENV=test mix compile --warnings-as-errors` — PASS

## Next Phase Readiness

Ready for 80-03: `host_app_upgrade_proof_test.exs`, adoption lane wiring, and closeout ceremony.

## Self-Check: PASSED

- Key files exist on disk
- Task commits 6748965, 402df5a, 49b97f4 present in git log
- All acceptance criteria and plan verification commands pass

---
*Phase: 80-upgrade-smoke-in-adoption-lane*
*Completed: 2026-05-29*
