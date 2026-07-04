---
phase: 42-eval-fails-closed
plan: 06
subsystem: eval
tags: [eval, online-scoring, verdict, fail-closed, tdd]

requires:
  - phase: 42-01
    provides: Scoria.Eval.Verdict fail-closed verdict semantics
  - phase: 42-05
    provides: captured-output judge runner contracts used by clean online samples
provides:
  - Online deterministic scoring as a negative-signal detector only
  - Span ERROR and workflow step output signal loading for online scoring
  - Verdict.compute-backed online threshold verdicts
  - Regression coverage proving clean traces do not persist fabricated deterministic pass rows
affects: [42-07-release-gate, eval-runners, online-scoring, dataset-promotion]

tech-stack:
  added: []
  patterns:
    - Reference-free deterministic online scoring may only produce negative evidence
    - Promotion requires a non-empty set of real scored passes
    - Online terminal verdicts flow through Scoria.Eval.Verdict

key-files:
  created:
    - test/scoria/eval/online_scoring_test.exs
  modified:
    - lib/scoria/eval/online_scoring.ex
    - test/scoria/eval/campaign_worker_test.exs

key-decisions:
  - "Clean online traces emit no deterministic base scores; only the judge can produce a positive score."
  - "Empty and not_scored online score sets remain needs_review and compute to inconclusive instead of passed."
  - "Campaign worker fixtures now provide captured output when they are intended to exercise the live judge path."

patterns-established:
  - "Negative-signal detector: policy_trigger, ERROR spans, and empty step output produce failed deterministic rows; clean traces produce []."
  - "Online summary gate: failed, empty, or not_scored score sets stay needs_review; promotion_candidate requires non-empty all-passed real scores."
  - "Verdict reuse: online threshold verdicts are derived with Scoria.Eval.Verdict.compute/2."

requirements-completed: [EVAL-05]

duration: 11m
completed: 2026-07-04
status: complete
---

# Phase 42 Plan 06: Online Scoring Negative-Signal Summary

**Online scoring now fails closed: deterministic scoring emits only real negative signals, and promotion requires non-empty real passes.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-07-04T23:37:18Z
- **Completed:** 2026-07-04T23:47:54Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Replaced fabricated deterministic pass rows with negative-signal detection for `policy_trigger`, ERROR spans, and empty or absent workflow step output.
- Routed online terminal verdicts through `Scoria.Eval.Verdict.compute/2`, so empty score sets are inconclusive instead of passed.
- Added seeded online scoring regression tests covering policy triggers, ERROR spans, empty output, clean traces without judge capture, clean traces with judge capture, and empty score sets.
- Updated existing campaign worker online assertions so clean samples persist judge scores without deterministic evidence.

## Task Commits

Each task was committed atomically:

1. **Task 3 RED: Negative-signal fixtures** - `05927779` (test)
2. **Task 1: Negative-signal deterministic scoring** - `85e68391` (feat)
3. **Task 3 RED: Clean trace and empty set fixtures** - `d262a0e3` (test)
4. **Task 2: Verdict-backed summaries** - `639b0072` (feat)

_Note: Task 3 was TDD, so its RED coverage was committed before and between implementation commits._

## Files Created/Modified

- `lib/scoria/eval/online_scoring.ex` - Adds span preload, Step output lookup, negative-signal classification, Verdict-backed threshold verdicts, and promotion gating.
- `test/scoria/eval/online_scoring_test.exs` - Adds seeded regression coverage for online negative signals, clean traces, and empty score sets without live LLM calls.
- `test/scoria/eval/campaign_worker_test.exs` - Aligns existing online worker assertions with the no-fabricated-deterministic-pass contract.

## Decisions Made

- Clean traces emit `[]` from deterministic scoring; the judge path is the only producer of positive online scores.
- Empty, failed, or not_scored score sets keep candidates in `needs_review`.
- Existing campaign worker live-judge fixtures include captured output explicitly so those tests continue to exercise judge execution.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test Contract] Updated stale campaign worker online assertions**
- **Found during:** Task 2 (summarize_scores + verdict via Verdict)
- **Issue:** Existing worker coverage still expected a clean online trace to persist a deterministic pass row alongside judge evidence.
- **Fix:** Updated the assertions to require no deterministic evidence for clean samples, added negative-signal metadata checks for policy triggers, and made the fixture's captured output explicit for live-judge paths.
- **Files modified:** `test/scoria/eval/campaign_worker_test.exs`
- **Verification:** `mix test test/scoria/eval/online_scoring_test.exs test/scoria/eval/campaign_worker_test.exs --warnings-as-errors`
- **Committed in:** `639b0072`

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** The adjustment was required to keep pre-existing tests aligned with the new fail-closed online scoring contract. No scope was added.

## Issues Encountered

- The plan listed Task 3 as TDD after implementation tasks, while Task 1 and Task 2 verification referenced the new online scoring test file. I preserved RED/GREEN ordering by committing failing tests before the corresponding implementation changes.

## Known Stubs

None.

## Threat Flags

None.

## Verification

- `mix test test/scoria/eval/online_scoring_test.exs test/scoria/eval/campaign_worker_test.exs --warnings-as-errors` - 16 tests, 0 failures
- `mix test test/scoria/eval/judge_runner_test.exs test/scoria/eval/subject_output_test.exs test/scoria/eval/verdict_test.exs --warnings-as-errors` - 15 tests, 0 failures
- `rg -n "Verdict\\.compute|Repo\\.preload\\(trace, :spans\\)|Repo\\.get\\(Step|alias Scoria\\.Workflows\\.Step" lib/scoria/eval/online_scoring.ex` - required link/load patterns present
- `rg -n "Deterministic online checks passed|score_status = if|score_value = if|status: \"passed\"|score: 1\\.0" lib/scoria/eval/online_scoring.ex || true` - no fabricated deterministic pass patterns found

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 42-07 can rely on online scoring failing closed: clean or uncertain traces are review items, and dataset-promotion candidates require real all-passed score evidence.

## Self-Check: PASSED

- Found `.planning/phases/42-eval-fails-closed/42-06-SUMMARY.md`
- Found `lib/scoria/eval/online_scoring.ex`
- Found `test/scoria/eval/online_scoring_test.exs`
- Found `test/scoria/eval/campaign_worker_test.exs`
- Found commits `05927779`, `85e68391`, `d262a0e3`, and `639b0072`

---
*Phase: 42-eval-fails-closed*
*Completed: 2026-07-04*
