---
phase: 42-eval-fails-closed
plan: 03
subsystem: eval
tags: [eval, exact-match, deterministic-scorer, not_scored, tdd]

requires:
  - phase: 42-eval-fails-closed/42-01
    provides: Fail-closed Verdict spine and not_scored vocabulary
  - phase: 42-eval-fails-closed/42-02
    provides: Frozen SubjectOutput.resolve/2 capture contract for runner consumers
provides:
  - Scoria.Eval.Scorers.ExactMatch.score/3 pure deterministic scorer
  - Binary exact-match pass/fail verdicts with explicit not_scored couldn't-run outcomes
  - Normalized string comparison plus canonical whole-map comparison
affects: [42-04-offline-runner, 42-05-judge-runner, eval-scorer-dispatch]

tech-stack:
  added: []
  patterns:
    - Pure scorer module returning persisted score maps or {:not_scored, reason}
    - Atom/string key lookup without creating atoms from external field names
    - TDD RED/GREEN cycles for pure eval behavior

key-files:
  created:
    - lib/scoria/eval/scorers/exact_match.ex
    - test/scoria/eval/scorers/exact_match_test.exs
  modified: []

key-decisions:
  - "ExactMatch.score/3 treats clean string mismatches as status \"failed\" with score 0.0, while missing actual, missing expected, and incomparable values return {:not_scored, reason}."
  - "String comparison normalizes Unicode NFC, trims, collapses internal whitespace, and remains case-sensitive unless case_insensitive is true."
  - "Whole-map matching is opt-in via match: \"map\" and canonicalizes atom/string keys recursively."

patterns-established:
  - "Exact scorer contract: score/3 returns %{status, score, scorer_kind, scorer_version, details} only after a real comparison."
  - "Couldn't-run boundary: not_scored is reserved for absent/incomparable inputs and is never used for a real mismatch."

requirements-completed: [EVAL-02]

duration: 8 min
completed: 2026-07-04
status: complete
---

# Phase 42 Plan 03: ExactMatch Deterministic Scorer Summary

**A key-free exact-match scorer now compares real actual output against expected output with binary pass/fail results and explicit not_scored couldn't-run outcomes.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-04T22:22:37Z
- **Completed:** 2026-07-04T22:30:13Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- Added `Scoria.Eval.Scorers.ExactMatch.score/3` with `scorer_kind: "exact_match"` and `scorer_version: "exact-match@1"`.
- Implemented normalized exact string comparison: Unicode NFC, trim, internal whitespace collapse, case-sensitive by default, opt-in case-insensitive matching.
- Implemented explicit `{:not_scored, reason}` returns for missing actual output, missing/nil expected fields, and incomparable types.
- Added canonical whole-map comparison via `match: "map"` with recursive atom/string key normalization.
- Pinned every planned behavior in tests, including the sharp line between ran-and-mismatched (`"failed"`/`0.0`) and couldn't-run (`{:not_scored, _}`).

## Task Commits

Each TDD gate was committed atomically:

1. **Task 1 RED: ExactMatch happy path contract** - `b0a9603e` (test)
2. **Task 1 GREEN: Minimal exact match scorer** - `bb3a330a` (feat)
3. **Task 1 RED: ExactMatch edge-case contract** - `45bf5225` (test)
4. **Task 1 GREEN: Full exact match scorer behavior** - `f0c41c3d` (feat)

## Files Created/Modified

- `lib/scoria/eval/scorers/exact_match.ex` - Pure deterministic scorer for exact string and map comparisons.
- `test/scoria/eval/scorers/exact_match_test.exs` - Behavior tests for pass, fail, normalization, field lookup, map matching, and not_scored outcomes.

## Decisions Made

- Used `:missing_actual`, `:missing_expected`, and `:incomparable_types` as stable not-scored reason atoms.
- Kept map matching opt-in so non-string actual values do not get silently coerced in default field mode.
- Implemented atom/string key lookup by comparing key string forms instead of converting external strings into atoms.

## Verification

- `mix test test/scoria/eval/scorers/exact_match_test.exs --warnings-as-errors` - PASS, 9 tests.
- `mix format --check-formatted lib/scoria/eval/scorers/exact_match.ex test/scoria/eval/scorers/exact_match_test.exs` - PASS.
- `rg -n "Grounding\\.status|status\\(" lib/scoria/eval/scorers/exact_match.ex` - PASS, no matches.
- `rg -n "fuzzy|semantic|Levenshtein|embedding|distance|similar" lib/scoria/eval/scorers/exact_match.ex test/scoria/eval/scorers/exact_match_test.exs` - PASS, no matches.
- `mix test --warnings-as-errors` - FAILED with 4 unrelated residual failures outside 42-03 scope:
  `ScoriaWeb.DevLabBoundaryTest` missing `.planning/phases/36-baseline-and-inventory/36-inventory.json`,
  `Scoria.CiPolicyContractTest` planning-ledger expectation,
  `Scoria.SupportCopilotGalleryTest` gallery/adoption failure,
  and `Scoria.WarningInventory.CaptureParityTest` full-suite-order failure.
- `mix test test/scoria/warning_inventory/capture_parity_test.exs --warnings-as-errors` - PASS in isolation, 2 tests.

## TDD Gate Compliance

- RED gate present: `b0a9603e` before `bb3a330a`; failure was expected because `Scoria.Eval.Scorers.ExactMatch.score/3` did not exist.
- GREEN gate present: `bb3a330a` made the first public contract pass.
- RED gate present: `45bf5225` before `f0c41c3d`; eight planned behavior cases failed against the minimal implementation.
- GREEN gate present: `f0c41c3d` made all nine behavior tests pass.
- Refactor gate: not needed; implementation stayed focused after GREEN and `mix format --check-formatted` passed.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope changes.

## Issues Encountered

- The expanded RED test initially used a direct `0.0` float pattern that triggers an OTP 27 warning. The test was corrected before the RED commit so failures represented planned scorer behavior only.
- The full suite has unrelated residual failures in planning-artifact and support-copilot/gallery contract tests. The plan-specific scorer suite, formatting check, and acceptance greps all pass.

## Known Stubs

None.

## Threat Flags

None. The new trust-boundary behavior is covered by the plan threat model: couldn't-run inputs return `{:not_scored, reason}` and clean mismatches return `"failed"`/`0.0`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `42-04-PLAN.md` to dispatch `scorer_kind: "exact_match"` from the offline runner into this scorer and persist results through the existing `ai_scores` sink.

## Self-Check: PASSED

- Verified created files exist: `lib/scoria/eval/scorers/exact_match.ex`, `test/scoria/eval/scorers/exact_match_test.exs`, and this summary.
- Verified task commits exist in git history: `b0a9603e`, `bb3a330a`, `45bf5225`, `f0c41c3d`.
- Verified working tree was clean before summary creation.
- Verified plan-level acceptance criteria passed.

---
*Phase: 42-eval-fails-closed*
*Completed: 2026-07-04*
