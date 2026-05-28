---
phase: 69-ci-trust-and-milestone-closeout
plan: 01
subsystem: testing
tags: [elixir, mix, exunit, warning-ratchet, warning-inventory, ci]

requires:
  - phase: 69-ci-trust-and-milestone-closeout
    plan: 00
    provides: CI gate map docs, maintainer trust context
  - phase: 68-full-suite-warning-closure
    provides: ensure_clean_tmp!/cleanup_transient_tmp!, nested capture guard
provides:
  - Symmetric tmp hygiene in warning_ratchet.test (WR-01)
  - Subprocess ratchet→inventory integration test (WR-02)
affects: [69-02-milestone-closeout]

tech-stack:
  added: []
  patterns:
    - "Ratchet mix tasks: ensure_clean_tmp! → work → cleanup_transient_tmp! in after"
    - "Integration tests invoke ratchet check via System.cmd to avoid nested ExUnit capture"

key-files:
  created: []
  modified:
    - lib/mix/tasks/scoria.warning_ratchet.test.ex
    - test/scoria/warning_inventory/tmp_preflight_test.exs

key-decisions:
  - "warning_ratchet.test mirrors warning_ratchet.check tmp lifecycle (WR-01)"
  - "Ratchet check integration test uses subprocess mix scoria.warning_ratchet.check (WR-02)"

patterns-established:
  - "High-signal ratchet test task cleans test/tmp entries only via shared WarningInventory helpers"

requirements-completed: [CI-03]

duration: 6min
completed: 2026-05-28
---

# Phase 69 Plan 01: Ratchet Maintainer Hygiene Summary

**Symmetric `test/tmp` lifecycle in `warning_ratchet.test` and subprocess ratchet-check integration test restore maintainer ratchet→inventory trust from 68-REVIEW WR-01/WR-02.**

## Performance

- **Duration:** 6 min (code) + ~5 min (subprocess integration test)
- **Started:** 2026-05-28T01:27:00Z
- **Completed:** 2026-05-28T01:33:37Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- `Mix.Tasks.Scoria.WarningRatchet.Test` now calls `ensure_clean_tmp!()` before work and `cleanup_transient_tmp!()` in `after`, matching `WarningRatchet.Check`
- Replaced in-process ratchet check integration test with `System.cmd("mix", ["scoria.warning_ratchet.check"], env: [{"MIX_ENV", "test"}])` so capture is not nested under ExUnit
- Remediated 68-REVIEW maintainer hygiene warnings WR-01 and WR-02

## Task Commits

Each task was committed atomically:

1. **Task 69-01-01: Symmetric tmp hygiene in warning_ratchet.test (WR-01)** - `7faa881` (fix)
2. **Task 69-01-02: Subprocess ratchet→inventory integration test (WR-02)** - `3b8ad66` (test)

## Files Created/Modified

- `lib/mix/tasks/scoria.warning_ratchet.test.ex` — ensure → try/after cleanup symmetry with check task
- `test/scoria/warning_inventory/tmp_preflight_test.exs` — subprocess ratchet check + inventory preflight chain

## Decisions Made

- Reused `WarningInventory.ensure_clean_tmp!/0` and `cleanup_transient_tmp!/0` rather than ad-hoc `rm` (matches 68-00 threat model)
- Subprocess exit asserted as `0` only (normal `mix` exit from `{:shutdown, 0}` in check task)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for **69-02** (milestone closeout): CI-03 checkbox verification, REQUIREMENTS traceability, milestone audit
- Maintainer chain: `mix scoria.warning_ratchet.test` then `mix scoria.warning_inventory --quiet` without manual tmp cleanup
- CI-03 requirement checkbox remains open until 69-02 per D-09

## Self-Check: PASSED

- `rg "ensure_clean_tmp!" lib/mix/tasks/scoria.warning_ratchet.test.ex` — match
- `rg "cleanup_transient_tmp!" lib/mix/tasks/scoria.warning_ratchet.test.ex` — match in `after`
- `rg 'System.cmd\("mix", \["scoria.warning_ratchet.check"\]' test/scoria/warning_inventory/tmp_preflight_test.exs` — match
- No `Mix.Tasks.Scoria.WarningRatchet.Check.run` in integration test
- `MIX_ENV=test mix test test/scoria/warning_inventory/tmp_preflight_test.exs` — 4 tests, 0 failures (303.4s)

---
*Phase: 69-ci-trust-and-milestone-closeout*
*Completed: 2026-05-28*
