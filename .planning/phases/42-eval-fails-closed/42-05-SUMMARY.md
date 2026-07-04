---
phase: 42-eval-fails-closed
plan: 05
subsystem: eval
tags: [eval, judge-runner, subject-output, verdict, fail-closed, tdd]

requires:
  - phase: 42-eval-fails-closed/42-01
    provides: Fail-closed Verdict spine and nil-safe not_scored vocabulary
  - phase: 42-eval-fails-closed/42-02
    provides: Frozen SubjectOutput.resolve/2 capture contract
provides:
  - Judge runner prompts use frozen captured_output as Actual via SubjectOutput.resolve/2
  - Empty judge captures persist not_scored rows and skip the judge call
  - Judge runner threshold verdicts derive from Scoria.Eval.Verdict.compute/2
affects: [42-06-online-scoring, 42-07-release-gate, eval-runners]

tech-stack:
  added: []
  patterns:
    - TDD RED guard before judge-runner implementation
    - Injected ReqLLM seam verifies live judge behavior without API keys
    - Shared SubjectOutput and Verdict contracts across offline and judge runners

key-files:
  created: []
  modified:
    - lib/scoria/eval/judge_runner.ex
    - test/scoria/eval/judge_runner_test.exs

key-decisions:
  - "Executed the TDD-marked judge-runner regression tests before the source implementation so the self-grade and empty-capture failures were observed RED."
  - "Judge Actual is JSON-encoded frozen captured_output from SubjectOutput.resolve(dataset_item, :live_judge), never expected_output[\"answer\"]."
  - "Empty or absent captures produce not_scored score evidence with reason empty_capture and do not invoke the injected judge seam."
  - "Judge run threshold_verdict is persisted from Verdict.compute/2; the local threshold_verdict/2 and latency helper were removed."

patterns-established:
  - "Judge runner fail-closed skip path: unscoreable subject output becomes a persisted not_scored score rather than a fabricated Actual."
  - "Zero-live-LLM regression testing: tests assert ReqLLMStub messages for called items and refute messages for skipped items."

requirements-completed: [EVAL-01, EVAL-03]

duration: 39 min
completed: 2026-07-04
status: complete
---

# Phase 42 Plan 05: Judge Runner Capture Summary

**Judge runner now grades frozen captured output, skips empty captures as not_scored, and persists Verdict-derived run verdicts without live LLM dependencies.**

## Performance

- **Duration:** 39 min
- **Started:** 2026-07-04T22:49:50Z
- **Completed:** 2026-07-04T23:28:42Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added RED regression tests proving the judge prompt's Actual comes from `captured_output`, not the sealed expected answer.
- Added a no-capture regression proving the judge seam is not invoked and the score is persisted as `not_scored`.
- Replaced `build_subject_output/1` with `SubjectOutput.resolve(dataset_item, :live_judge)`.
- Replaced the duplicate judge-runner `threshold_verdict/2` with `Scoria.Eval.Verdict.compute/2`.

## Task Commits

Each task was committed atomically:

1. **Task 2 RED: Judge runner tests prove no self-grade/no live LLM** - `014e14ee` (test)
2. **Task 1 GREEN: Replace self-grade with SubjectOutput.resolve + Verdict** - `2cc621ba` (feat)

_Note: The RED test commit landed before the source implementation to preserve the TDD gate despite the plan listing the implementation task first._

## Files Created/Modified

- `test/scoria/eval/judge_runner_test.exs` - Adds captured Actual, empty-capture skip, no-live-LLM, and Verdict-derived threshold assertions.
- `lib/scoria/eval/judge_runner.ex` - Resolves Actual through `SubjectOutput`, persists not_scored for empty captures, JSON-encodes Actual in the prompt, and persists `Verdict.compute/2` output.

## Decisions Made

- Preserved TDD by executing and committing the failing test task before the implementation task.
- Kept the existing `req_llm_module` seam for all judge interaction; tests never call a live model or require API keys.
- Set judge-runner completion verdicts through `Verdict.compute(scores, eval_spec.threshold_policy) |> Atom.to_string()` for both `run_live/1` and `run_existing/2`.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope changes.

## Issues Encountered

- The plan listed the source implementation before a TDD-marked test task. Execution reordered the RED test commit before implementation so the tests genuinely failed on the old self-grade behavior.

## Known Stubs

None.

## Verification

- `mix test test/scoria/eval/judge_runner_test.exs --warnings-as-errors` before implementation - RED as expected, 2 tests / 2 failures proving Actual still self-graded and empty capture still called the judge.
- `mix test test/scoria/eval/judge_runner_test.exs --warnings-as-errors` - PASS, 2 tests.
- `mix format --check-formatted lib/scoria/eval/judge_runner.ex test/scoria/eval/judge_runner_test.exs` - PASS.
- Acceptance scans - PASS: `build_subject_output`, `defp threshold_verdict`, and `defp latency_ms` removed from `judge_runner.ex`; `SubjectOutput.resolve/2`, `Verdict.compute/2`, JSON-encoded Actual, and not_scored skip path present.
- `mix test test/scoria/eval/judge_runner_test.exs test/scoria/eval/subject_output_test.exs test/scoria/eval/verdict_test.exs --warnings-as-errors` - PASS, 15 tests.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `42-06-PLAN.md` to remove online-scoring fabricated pass rows. The judge runner now shares the same frozen SubjectOutput and Verdict contracts as offline replay.

## Self-Check: PASSED

- Verified summary file exists on disk.
- Verified task commits exist in git history: `014e14ee`, `2cc621ba`.
- Verified plan-level acceptance checks passed.

---
*Phase: 42-eval-fails-closed*
*Completed: 2026-07-04*
