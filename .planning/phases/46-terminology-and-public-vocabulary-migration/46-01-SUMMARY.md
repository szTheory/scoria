---
phase: 46-terminology-and-public-vocabulary-migration
plan: 01
subsystem: docs
tags: [terminology, verification-suites, reviewer-broadcast, compatibility, storage-guard]

requires: []
provides:
  - Scoria.VerificationSuites final-vocabulary proof-command surface
  - Scoria.Observe.ReviewerBroadcast final-vocabulary reviewer trace broadcast surface
  - 0.1.x compatibility wrappers for VerificationLanes and OperatorBroadcast
  - Early terminology storage/no-schema guard
affects: [phase-46, docs, verification, observe, workflows, runtime-trace]

tech-stack:
  added: []
  patterns:
    - Public compatibility wrapper delegates to final-vocabulary module
    - Active-source storage guard strips comment-only lines before matching

key-files:
  created:
    - lib/scoria/verification_suites.ex
    - lib/scoria/observe/reviewer_broadcast.ex
    - test/scoria/verification_suites_test.exs
    - test/scoria/observe/reviewer_broadcast_test.exs
    - test/scoria/terminology_contract_test.exs
  modified:
    - lib/scoria/verification_lanes.ex
    - lib/scoria/observe/operator_broadcast.ex
    - lib/scoria/workflows.ex
    - lib/scoria/observe/telemetry.ex
    - test/scoria/verification_lanes_test.exs
    - test/scoria/observe/operator_broadcast_test.exs

key-decisions:
  - "VerificationLanes remains a 0.1.x compatibility wrapper while VerificationSuites owns proof-command data and vocabulary."
  - "OperatorBroadcast remains a 0.1.x compatibility wrapper while ReviewerBroadcast owns tenant-scoped reviewer trace fan-out."
  - "The early terminology guard scopes forbidden final public names to storage/schema/migration fields so later public option aliases can be added safely."

patterns-established:
  - "Final-vocabulary public modules should own behavior while legacy modules delegate without duplicate state."
  - "Terminology source guards should scan active schema/migration sources and ignore comments."

requirements-completed: [TERM-02, TERM-04]

duration: 4 min
completed: 2026-07-09
status: complete
---

# Phase 46 Plan 01: Public Compatibility Surface Summary

**Verification suite and reviewer broadcast aliases now lead with final vocabulary while legacy 0.1.x names continue to work.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-09T22:05:30Z
- **Completed:** 2026-07-09T22:09:50Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- Added `Scoria.VerificationSuites` as the canonical proof-command module with verification suite vocabulary, stable command data, and unchanged closeout order.
- Converted `Scoria.VerificationLanes` into a 0.1.x compatibility wrapper that delegates to `VerificationSuites`.
- Added `Scoria.Observe.ReviewerBroadcast` as the canonical tenant-scoped reviewer trace PubSub fan-out module.
- Converted `Scoria.Observe.OperatorBroadcast` into a 0.1.x compatibility wrapper and updated runtime call sites in `Scoria.Workflows` and `Scoria.Observe.Telemetry` to use `ReviewerBroadcast`.
- Added `Scoria.TerminologyContractTest` to block storage/schema terminology renames before docs migration.

## Task Commits

1. **Task 1 RED: Verification suite contract** - `e4bf03c5` (test)
2. **Task 1 GREEN: Verification suites compatibility surface** - `69789d41` (feat)
3. **Task 2 RED: Reviewer broadcast contract** - `77f2d6f7` (test)
4. **Task 2 GREEN: Reviewer broadcast compatibility surface** - `3e7fec9e` (feat)
5. **Task 3: Terminology storage guard** - `d23c2005` (test)

## Files Created/Modified

- `lib/scoria/verification_suites.ex` - Canonical verification suite command contract and closeout chain.
- `lib/scoria/verification_lanes.ex` - Legacy compatibility wrapper delegating to `VerificationSuites`.
- `lib/scoria/observe/reviewer_broadcast.ex` - Canonical reviewer trace PubSub fan-out implementation.
- `lib/scoria/observe/operator_broadcast.ex` - Legacy compatibility wrapper delegating to `ReviewerBroadcast`.
- `lib/scoria/workflows.ex` - Runtime approval/HITL fan-out now calls `ReviewerBroadcast`.
- `lib/scoria/observe/telemetry.ex` - Telemetry trace fan-out now calls `ReviewerBroadcast`.
- `test/scoria/verification_suites_test.exs` - Canonical verification suite behavior tests.
- `test/scoria/verification_lanes_test.exs` - Legacy wrapper compatibility assertions.
- `test/scoria/observe/reviewer_broadcast_test.exs` - Canonical reviewer broadcast behavior and call-site tests.
- `test/scoria/observe/operator_broadcast_test.exs` - Legacy wrapper compatibility assertions.
- `test/scoria/terminology_contract_test.exs` - Early no-schema/storage terminology guard.

## Decisions Made

- Kept wrapper modules documented instead of hidden so ExDoc can communicate the 0.1.x compatibility path without warning noise.
- Kept PubSub topic names and message tuples unchanged, preserving dashboard behavior while changing public vocabulary.
- Scoped `scoped_context` and `cache_key` guard checks to storage/schema/migration field declarations rather than all source text, because later plans intentionally add those public aliases outside storage.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

None.

## Verification

- `MIX_ENV=test mix test --warnings-as-errors test/scoria/verification_suites_test.exs test/scoria/verification_lanes_test.exs` - PASS, 12 tests, 0 failures.
- `MIX_ENV=test mix test --warnings-as-errors test/scoria/observe/reviewer_broadcast_test.exs test/scoria/observe/operator_broadcast_test.exs` - PASS, 20 tests, 0 failures.
- `MIX_ENV=test mix test --warnings-as-errors test/scoria/terminology_contract_test.exs` - PASS, 4 tests, 0 failures.
- `MIX_ENV=test mix test --warnings-as-errors test/scoria/verification_suites_test.exs test/scoria/verification_lanes_test.exs test/scoria/observe/reviewer_broadcast_test.exs test/scoria/observe/operator_broadcast_test.exs test/scoria/terminology_contract_test.exs` - PASS, 36 tests, 0 failures.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `46-02-PLAN.md`, `46-03-PLAN.md`, and downstream docs plans to use final-vocabulary public names without breaking current 0.1.x callers.

## Self-Check: PASSED

- Verified key created files exist: `lib/scoria/verification_suites.ex`, `lib/scoria/observe/reviewer_broadcast.ex`, and `test/scoria/terminology_contract_test.exs`.
- Verified task commits exist: `e4bf03c5`, `69789d41`, `77f2d6f7`, `3e7fec9e`, and `d23c2005`.
- Verified focused plan tests pass with warnings as errors.

---
*Phase: 46-terminology-and-public-vocabulary-migration*
*Completed: 2026-07-09*
