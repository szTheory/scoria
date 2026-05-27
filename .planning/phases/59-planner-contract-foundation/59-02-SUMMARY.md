---
phase: 59-planner-contract-foundation
plan: 02
subsystem: installer
tags: [mix-task, installer, check-mode, exit-semantics, verification]
requires:
  - phase: 59-01
    provides: deterministic planner artifact and dry-run/check routing
provides:
  - check-mode tri-state status mapping with deterministic 0/1/2 exits
  - stable machine trailer contract for CI parsing
  - subprocess-backed check semantics and no-write guardrail regression tests
affects: [60-drift-classification-and-safe-apply, 61-proof-and-closeout]
tech-stack:
  added: []
  patterns: [planner-report split, subprocess mix-task contract verification]
key-files:
  created:
    - lib/scoria/install/report.ex
  modified:
    - lib/mix/tasks/scoria.install.ex
    - test/mix/tasks/scoria.install_check_test.exs
    - test/mix/tasks/scoria.install_test.exs
key-decisions:
  - "Route check mode through Scoria.Install.Report so status mapping, human/json rendering, and trailer formatting share one contract surface."
  - "Assert check semantics in subprocess fixtures to verify real process exits and preserve no-write host guarantees."
patterns-established:
  - "Every check run ends with one machine trailer line: SCORIA_CHECK_RESULT status=<status> exit_code=<code>."
  - "Fixture-host subprocess tests pin compliant/drift/manual_review/error outcomes without mutating source fixtures."
requirements-completed: [INST-03, INST-04, INST-05]
duration: 22 min
completed: 2026-05-27
---

# Phase 59 Plan 02: Planner Contract Foundation Summary

**`mix scoria.install --check` now emits deterministic compatibility status with stable trailer output and enforced `0/1/2` exits while remaining no-write.**

## Performance

- **Duration:** 22 min
- **Started:** 2026-05-27T12:35:00Z
- **Completed:** 2026-05-27T12:57:00Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments
- Added `Scoria.Install.Report` with `check_result/1`, human/json renderers, and trailer-line formatting for stable check contracts.
- Updated `Mix.Tasks.Scoria.Install` check mode to use planner + report output and terminate via explicit `System.halt(exit_code)` semantics.
- Replaced check tests with subprocess fixture coverage for compliant (`0`), drift (`1`), manual-review (`1`), and error (`2`) outcomes and exact trailer assertions.
- Added installer regression coverage proving `mix scoria.install --check` does not mutate host files compared to pre-check snapshots.
- Re-verified canonical lane contract tests (`verification_lanes` and `test.adoption`) to ensure v2.4 reliability guardrails remain intact.

## Task Commits

Each task was committed atomically:

1. **Task 1: Task 59-02-01: Implement check result aggregation, stable trailer line, and tri-state exits** - `b5d7c27` (feat)
2. **Task 2: Task 59-02-02: Add subprocess check-semantic tests and reliability-guardrail regression checks** - `6f4d982` (test)

## Verification

All required task and plan verification commands were executed and passed:

- `MIX_ENV=test mix test test/mix/tasks/scoria.install_check_test.exs`
- `MIX_ENV=test mix test test/mix/tasks/scoria.install_check_test.exs test/mix/tasks/scoria.install_test.exs`
- `MIX_ENV=test mix test test/scoria/verification_lanes_test.exs test/mix/tasks/test.adoption_test.exs`
- `MIX_ENV=test mix test test/mix/tasks/scoria.install_test.exs test/mix/tasks/scoria.install_check_test.exs test/scoria/verification_lanes_test.exs test/mix/tasks/test.adoption_test.exs`

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed (none)
**Impact on plan:** None.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 59 planner/check contract closeout is complete with deterministic status + trailer + exit semantics under test.
- Ready for Phase 60 to consume this planner/check truth in drift-aware apply execution work.

---
*Phase: 59-planner-contract-foundation*
*Completed: 2026-05-27*
