---
phase: 45-correctness-sweep-fail-closed-proof-closeout
plan: 03
subsystem: eval
tags: [latency, verdict, offline-runner, judge-runner]
requires:
  - phase: 42-eval-fails-closed
    provides: fail-closed eval verdict spine and score persistence
provides:
  - Monotonic eval timing helper
  - Fail-closed `max_latency_ms` verdict semantics
  - Offline and judge score latency metadata
affects: [eval, release-gates, phase-45]
tech-stack:
  added: []
  patterns: [monotonic measurement, configured-missing-latency inconclusive]
key-files:
  created:
    - lib/scoria/eval/timing.ex
    - test/scoria/eval/timing_test.exs
  modified:
    - lib/scoria/eval/verdict.ex
    - lib/scoria/eval/runner.ex
    - lib/scoria/eval/judge_runner.ex
    - test/scoria/eval/verdict_test.exs
    - test/scoria/eval/offline_runner_test.exs
    - test/scoria/eval/judge_runner_test.exs
key-decisions:
  - "Configured missing or invalid scored-item latency returns `:inconclusive` instead of being coerced to zero."
  - "Offline and judge score latency is measured at the score writer, while run duration measures the whole eval run."
patterns-established:
  - "Use `Scoria.Eval.Timing.measure/1` for per-score latency and `elapsed_ms/1` for run completion duration."
requirements-completed: [FIX-04]
duration: 1h
completed: 2026-07-07
status: complete
---

# Phase 45-03: Eval Latency Summary

**Offline and judge eval paths now record measured score latency and fail closed when configured latency evidence is missing.**

## Performance

- **Duration:** 1h
- **Started:** 2026-07-07
- **Completed:** 2026-07-07
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Added `Scoria.Eval.Timing` for monotonic per-score and whole-run duration measurement.
- Updated `Verdict.compute/2` so `max_latency_ms` fails on over-threshold latency and returns `:inconclusive` for missing or invalid latency metadata.
- Replaced hardcoded offline and judge score latency/duration zeroes with measured values.
- Preserved Phase 42 no-live-LLM judge seams and fail-closed `not_scored` behavior.

## Task Commits

1. **Offline and judge eval latency** - `1de6ea0d` (`fix`)

## Files Created/Modified

- `lib/scoria/eval/timing.ex` - Internal monotonic timing helper.
- `lib/scoria/eval/verdict.ex` - Configured latency policy evaluation.
- `lib/scoria/eval/runner.ex` - Offline score and run timing.
- `lib/scoria/eval/judge_runner.ex` - Judge score and run timing.
- `test/scoria/eval/timing_test.exs` - Timing helper tests.
- `test/scoria/eval/verdict_test.exs` - Latency policy tests.
- `test/scoria/eval/offline_runner_test.exs` - Offline metadata proof.
- `test/scoria/eval/judge_runner_test.exs` - Judge metadata proof.

## Decisions Made

`max_latency_ms` remains a score-level policy. Whole-run `duration_ms` is measured and stored, but the verdict gate evaluates scored-item latency metadata.

## Deviations from Plan

None.

## Issues Encountered

None.

## Verification

- `MIX_ENV=test mix test test/scoria/eval/timing_test.exs test/scoria/eval/verdict_test.exs test/scoria/eval/offline_runner_test.exs test/scoria/eval/judge_runner_test.exs --warnings-as-errors` - PASS, 22 tests, 0 failures.

## User Setup Required

None.

## Next Phase Readiness

The shared timing helper and verdict semantics are ready for online scoring and final closeout proof.

---
*Phase: 45-correctness-sweep-fail-closed-proof-closeout*
*Completed: 2026-07-07*
