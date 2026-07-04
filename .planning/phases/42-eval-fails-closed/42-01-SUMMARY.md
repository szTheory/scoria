---
phase: 42-eval-fails-closed
plan: 01
subsystem: eval
tags: [eval, verdict, fail-closed, not_scored, dashboard]

# Dependency graph
requires: []
provides:
  - Fail-closed Scoria.Eval.Verdict spine for threshold verdict decisions
  - Honest not_scored item-score validation with nil measurements
  - Amber dashboard vocabulary for not_scored and inconclusive eval states
affects: [phase-42, release-gate, eval-runners, dashboard-vocabulary]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Pure verdict module with canonical passing string helper
    - Conditional Ecto changeset validation based on cast status
    - Warning-tone operator rendering for unmeasured/inconclusive eval states

key-files:
  created:
    - lib/scoria/eval/verdict.ex
    - test/scoria/eval/verdict_test.exs
    - test/scoria/eval/score_changeset_test.exs
    - test/scoria_web/eval_vocabulary_test.exs
  modified:
    - lib/scoria/eval/score.ex
    - lib/scoria_web/ui.ex
    - lib/scoria_web/copy.ex

key-decisions:
  - "Verdict.compute/2 returns :inconclusive for empty, all-unscored, or strict-coverage-violating score sets; only real scored subsets can pass."
  - "Score.changeset/2 accepts status \"not_scored\" with score nil and derives not_scored counts from total - passed - failed instead of adding storage."
  - "Dashboard eval states not_scored and inconclusive render as :warn amber with curated operator labels."

patterns-established:
  - "Fail-closed verdict authority: Scoria.Eval.Verdict.passing_verdict/0 is the single passing string source for later release-gate and runner plans."
  - "Nil-safe eval aggregation: item_scored?/1 filters not_scored or nil-score rows before mean/pass-rate/latency math."

requirements-completed: [EVAL-03]

# Metrics
duration: 6 min
completed: 2026-07-04
status: complete
---

# Phase 42 Plan 01: Verdict Spine Summary

**Fail-closed eval verdict spine with honest not_scored persistence and amber inconclusive dashboard vocabulary**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-04T21:58:20Z
- **Completed:** 2026-07-04T22:04:47Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Added `Scoria.Eval.Verdict` with `compute/2`, `blocks_release?/1`, `item_scored?/1`, and a canonical passing verdict string helper.
- Made verdict math fail closed for empty, zero-coverage, and strict coverage violations while filtering nil/not_scored rows before aggregation.
- Allowed `Scoria.Eval.Score` rows with `status: "not_scored"` to persist `score: nil`, without adding schema columns.
- Routed `not_scored` and `inconclusive` to amber `:warn` dashboard tone and curated labels.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Create Scoria.Eval.Verdict contract tests** - `208918ff` (test)
2. **Task 1 GREEN: Implement fail-closed verdict spine** - `07572d1a` (feat)
3. **Task 2 RED: Add Score.changeset not_scored tests** - `f9bb1e66` (test)
4. **Task 2 GREEN: Allow not_scored nil-score rows** - `d328ad58` (feat)
5. **Task 3: Dashboard amber vocabulary** - `33eb7861` (feat)

_Note: TDD tasks produced RED and GREEN commits as required._

## Files Created/Modified

- `lib/scoria/eval/verdict.ex` - Central fail-closed verdict API and nil-safe policy aggregation.
- `lib/scoria/eval/score.ex` - Conditional `:score` requirement for `not_scored` rows.
- `lib/scoria_web/ui.ex` - Warning-tone bucket now includes `not_scored` and `inconclusive`.
- `lib/scoria_web/copy.ex` - Curated labels for `Not scored` and `Inconclusive`.
- `test/scoria/eval/verdict_test.exs` - Pure verdict contract tests for empty, zero-coverage, strict coverage, tolerance, nil-safe math, release blocking, and item scoring.
- `test/scoria/eval/score_changeset_test.exs` - Changeset validation tests for not_scored nil-score behavior and passed/failed regressions.
- `test/scoria_web/eval_vocabulary_test.exs` - UI/copy guard for eval warning states and pass/fail tone stability.

## Decisions Made

- `blocks_release?/1` intentionally treats only persisted string `"passed"` as non-blocking; atom `:passed` remains blocking so later DB-backed callers use the canonical persisted form.
- `not_scored_tolerance` is only an explicit escape hatch; absent tolerance, any unscored or nil-score item makes the run `:inconclusive`.
- `not_scored` counts are derived from existing totals instead of adding a migration or column.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope changes.

## Issues Encountered

- During Task 2 RED, the first test fixture used a UUID for `dataset_item_id`; the existing `Score` schema casts that association as `:id`. The fixture was corrected before the RED commit so the test failed only on the planned `not_scored` behavior.

## Known Stubs

None.

## Verification

- `mix test test/scoria/eval/verdict_test.exs --warnings-as-errors` — PASS (9 tests, 0 failures)
- `mix test test/scoria/eval/score_changeset_test.exs --warnings-as-errors` — PASS (3 tests, 0 failures)
- `mix test test/scoria_web/eval_vocabulary_test.exs --warnings-as-errors` — PASS (2 tests, 0 failures)
- `mix test test/scoria/eval/verdict_test.exs test/scoria/eval/score_changeset_test.exs test/scoria_web/eval_vocabulary_test.exs --warnings-as-errors` — PASS (14 tests, 0 failures)

## TDD Gate Compliance

- RED gate present: `208918ff` before `07572d1a` for Verdict.
- GREEN gate present: `07572d1a` after the failing Verdict test.
- RED gate present: `f9bb1e66` before `d328ad58` for Score changeset.
- GREEN gate present: `d328ad58` after the failing Score changeset test.
- Refactor gate: not needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `42-02-PLAN.md` and downstream Phase 42 runner/gate plans to consume `Scoria.Eval.Verdict` as the single fail-closed verdict authority.

## Self-Check: PASSED

- Verified created files exist: `lib/scoria/eval/verdict.ex`, `test/scoria/eval/verdict_test.exs`, `test/scoria/eval/score_changeset_test.exs`, `test/scoria_web/eval_vocabulary_test.exs`, and this summary.
- Verified task commits exist: `208918ff`, `07572d1a`, `f9bb1e66`, `d328ad58`, `33eb7861`.

---
*Phase: 42-eval-fails-closed*
*Completed: 2026-07-04*
