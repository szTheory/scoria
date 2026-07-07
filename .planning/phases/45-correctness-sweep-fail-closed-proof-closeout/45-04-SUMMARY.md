---
phase: 45-correctness-sweep-fail-closed-proof-closeout
plan: 04
subsystem: eval
tags: [online-scoring, latency, verdict]
requires:
  - phase: 45-correctness-sweep-fail-closed-proof-closeout
    provides: 45-03 monotonic timing helper and latency verdict semantics
provides:
  - Online deterministic score latency metadata
  - Online eval run duration measurement
affects: [eval, online-scoring, phase-45]
tech-stack:
  added: []
  patterns: [negative-signal-only deterministic scoring with measured metadata]
key-files:
  created: []
  modified:
    - lib/scoria/eval/online_scoring.ex
    - test/scoria/eval/online_scoring_test.exs
key-decisions:
  - "Online deterministic scoring remains negative-signal only; clean traces still do not fabricate passed rows."
  - "Online clean traces with judge capture continue through the measured judge path."
patterns-established:
  - "Online deterministic score rows carry measured latency from `Scoria.Eval.Timing`."
requirements-completed: [FIX-04]
duration: 30min
completed: 2026-07-07
status: complete
---

# Phase 45-04: Online Scoring Latency Summary

**Online scoring now records measured deterministic latency and measured completion duration without fabricating clean-trace pass rows.**

## Performance

- **Duration:** 30min
- **Started:** 2026-07-07
- **Completed:** 2026-07-07
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Measured deterministic negative-signal online score latency with `Scoria.Eval.Timing`.
- Measured online eval run completion duration instead of persisting literal zero.
- Preserved Phase 42 behavior where clean traces do not produce deterministic passed rows.

## Task Commits

1. **Online scoring latency** - `57ad7336` (`fix`)

## Files Created/Modified

- `lib/scoria/eval/online_scoring.ex` - Online scoring duration and deterministic score latency measurement.
- `test/scoria/eval/online_scoring_test.exs` - Online metadata and no-fabricated-pass regression proof.

## Decisions Made

Online deterministic scoring still emits only negative evidence. Positive online evidence must come from judge-backed scoring, which now inherits the measured judge path from 45-03.

## Deviations from Plan

None.

## Issues Encountered

None.

## Verification

- `MIX_ENV=test mix test test/scoria/eval/online_scoring_test.exs test/scoria/eval/judge_runner_test.exs test/scoria/eval/verdict_test.exs test/scoria/eval/timing_test.exs --warnings-as-errors` - PASS, 23 tests, 0 failures.

## User Setup Required

None.

## Next Phase Readiness

FIX-04 is ready for final closeout proof across offline, judge, and online scoring paths.

---
*Phase: 45-correctness-sweep-fail-closed-proof-closeout*
*Completed: 2026-07-07*
