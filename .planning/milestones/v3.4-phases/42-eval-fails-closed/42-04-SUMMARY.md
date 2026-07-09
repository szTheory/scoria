---
phase: 42-eval-fails-closed
plan: 04
subsystem: eval
tags: [eval, offline-replay, exact-match, fail-closed, not_scored]

requires:
  - phase: 42-eval-fails-closed/42-01
    provides: Fail-closed Verdict spine and nil-safe not_scored vocabulary
  - phase: 42-eval-fails-closed/42-02
    provides: Frozen SubjectOutput.resolve/2 capture contract
  - phase: 42-eval-fails-closed/42-03
    provides: ExactMatch deterministic scorer
provides:
  - Offline replay dispatches scorer_kind exact_match through captured subject output
  - Unknown scorer kinds and empty captures persist not_scored rows and inconclusive run verdicts
  - Offline run threshold verdicts derive from Scoria.Eval.Verdict.compute/2
affects: [42-05-judge-runner, 42-07-release-gate, eval-runners]

tech-stack:
  added: []
  patterns:
    - TDD RED contract before runner implementation for fake-green removal
    - Per-item scorer dispatch with explicit not_scored score attrs
    - Database nullability aligned with not_scored nil-score semantics

key-files:
  created:
    - priv/repo/migrations/20260704224300_allow_not_scored_scores_without_score.exs
  modified:
    - lib/scoria/eval/runner.ex
    - test/scoria/eval/offline_runner_test.exs

key-decisions:
  - "Offline replay extracts the configured exact_match field from captured_output before calling ExactMatch.score/3; whole-map comparison remains available through match: \"map\"."
  - "llm_judge scorer_kind stays fail-closed as not_scored unless an explicit injected judge seam is supplied; offline replay never requires a live LLM by default."
  - "ai_scores.score is nullable because not_scored evidence rows intentionally persist score nil."

patterns-established:
  - "Offline runner verdicts are computed once through Scoria.Eval.Verdict and persisted as strings."
  - "Unknown scorer kinds persist a not_scored row with reason unknown_scorer instead of silently passing."

requirements-completed: [EVAL-01, EVAL-02, EVAL-03]

duration: 7 min
completed: 2026-07-04
status: complete
---

# Phase 42 Plan 04: Offline Runner Scorer Dispatch Summary

**Offline replay now scores frozen captured output through ExactMatch and fails closed for mismatches, empty captures, and unknown scorers.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-07-04T22:37:29Z
- **Completed:** 2026-07-04T22:44:36Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Replaced `Runner.record_scores/4` fake-green rows with scorer_kind dispatch.
- Routed `exact_match` through `SubjectOutput.resolve/2` and `ExactMatch.score/3`.
- Persisted not_scored evidence for empty captures, missing scorer_kind, unknown scorers, and default llm_judge without an injected seam.
- Replaced the local offline `threshold_verdict/2` and latency helper with `Verdict.compute/2`.
- Rewrote offline runner tests around real captured output: match passes, mismatch fails, empty capture and unknown scorer are inconclusive.

## Task Commits

Each task was committed atomically:

1. **Task 2 RED: Rewrite offline_runner_test against real captures** - `63d23a5e` (test)
2. **Task 1 GREEN: Real scorer_kind dispatch + Verdict.compute in run_offline** - `ed54fc45` (feat)

_Note: The RED test commit landed before the source implementation to preserve the task's TDD gate despite the plan listing the implementation task first._

## Files Created/Modified

- `test/scoria/eval/offline_runner_test.exs` - Replaces fake-green assertions with exact-match pass/fail and not_scored/inconclusive cases.
- `lib/scoria/eval/runner.ex` - Dispatches per scorer_kind, resolves frozen captured output, records not_scored rows, and uses `Verdict.compute/2`.
- `priv/repo/migrations/20260704224300_allow_not_scored_scores_without_score.exs` - Drops the `ai_scores.score` NOT NULL constraint so not_scored rows can persist score nil.

## Decisions Made

- Preserved TDD by committing the failing offline-runner contract before implementing runner dispatch.
- Extracted the scorer `field` from captured output before calling `ExactMatch.score/3`, matching the existing ExactMatch public contract.
- Kept live judge calls opt-in only through explicit injected modules; absent that seam, offline llm_judge rows are not_scored.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added score-nullability migration for not_scored persistence**
- **Found during:** Task 1 (Real scorer_kind dispatch + Verdict.compute in run_offline)
- **Issue:** `Score.changeset/2` allowed `status: "not_scored"` with `score: nil`, but the database still enforced `ai_scores.score NOT NULL`, blocking the required fail-closed evidence rows.
- **Fix:** Added a reversible migration that drops the NOT NULL constraint on `ai_scores.score`.
- **Files modified:** `priv/repo/migrations/20260704224300_allow_not_scored_scores_without_score.exs`
- **Verification:** `mix ecto.migrate && MIX_ENV=test mix ecto.migrate && mix test test/scoria/eval/offline_runner_test.exs --warnings-as-errors`
- **Committed in:** `ed54fc45`

---

**Total deviations:** 1 auto-fixed (Rule 2 missing critical functionality).
**Impact on plan:** Required for the planned not_scored semantics to persist; no product scope expansion.

## Issues Encountered

- The plan listed the source implementation before a TDD-marked test task. Execution reordered the RED test commit ahead of implementation so the test genuinely failed before GREEN.

## Known Stubs

None.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: schema-nullability | `priv/repo/migrations/20260704224300_allow_not_scored_scores_without_score.exs` | Alters the score storage trust boundary so unmeasured not_scored rows can persist nil score instead of being coerced to a fake numeric value. |

## Verification

- `mix test test/scoria/eval/offline_runner_test.exs --warnings-as-errors` before implementation - RED as expected, 5 tests / 3 failures proving mismatch, empty capture, and unknown scorer still fake-passed.
- `mix ecto.migrate && MIX_ENV=test mix ecto.migrate && mix test test/scoria/eval/offline_runner_test.exs --warnings-as-errors` - PASS, 5 tests.
- `mix test test/scoria/eval/offline_runner_test.exs test/scoria/eval/scorers/exact_match_test.exs test/scoria/eval/verdict_test.exs test/scoria/eval/score_changeset_test.exs --warnings-as-errors` - PASS, 26 tests.
- `mix format --check-formatted lib/scoria/eval/runner.ex priv/repo/migrations/20260704224300_allow_not_scored_scores_without_score.exs test/scoria/eval/offline_runner_test.exs` - PASS.
- Acceptance greps - PASS: no hardcoded offline passed/1.0 phrase, no local `threshold_verdict/2`, and no local `latency_ms/1` in `runner.ex`.

## TDD Gate Compliance

- RED gate present: `63d23a5e` added failing offline-runner tests before the runner implementation.
- GREEN gate present: `ed54fc45` implemented scorer dispatch and made the focused tests pass.
- Refactor gate: not needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `42-05-PLAN.md` to remove the remaining judge-runner self-grade path and consume the same fail-closed verdict spine.

## Self-Check: PASSED

- Verified created/modified files exist on disk.
- Verified task commits exist in git history: `63d23a5e`, `ed54fc45`.
- Verified plan-level acceptance checks passed.

---
*Phase: 42-eval-fails-closed*
*Completed: 2026-07-04*
