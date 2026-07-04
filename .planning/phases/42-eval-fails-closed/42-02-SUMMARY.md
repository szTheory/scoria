---
phase: 42-eval-fails-closed
plan: 02
subsystem: eval
tags: [eval, dataset-capture, subject-output, ecto, tdd]

requires:
  - phase: 42-eval-fails-closed/42-01
    provides: Fail-closed Verdict spine and not_scored vocabulary
provides:
  - Captured subject-output columns on ai_eval_dataset_items
  - Promotion-time capture from Workflows.Step.result_envelope["output"]
  - Shared Scoria.Eval.SubjectOutput.resolve/2 resolver for offline_replay and live_judge
affects: [42-04-offline-runner, 42-05-judge-runner, eval-runners]

tech-stack:
  added: []
  patterns:
    - Promotion loads the existing workflow_step_id source internally; no new promotion attr key
    - Frozen captured_output is hashable via canonical JSON sha256
    - live_judge delegates to frozen capture until live subject regeneration ships later

key-files:
  created:
    - lib/scoria/eval/subject_output.ex
    - priv/repo/migrations/20260704221053_add_dataset_item_captured_output.exs
    - test/scoria/eval/dataset_promotion_test.exs
    - test/scoria/eval/subject_output_test.exs
  modified:
    - lib/scoria/eval/dataset_item.ex
    - lib/scoria/eval/dataset_promotion.ex

key-decisions:
  - "Dataset promotion loads Scoria.Workflows.Step internally from the existing workflow_step_id instead of adding a promotion attr key."
  - "captured_output is populated only when Step.result_envelope[\"output\"] is a non-empty map; empty, absent, or missing steps leave capture nil."
  - "SubjectOutput.resolve/2 returns the frozen captured_output for both offline_replay and live_judge; independent live subject regeneration remains deferred."
  - "Empty or absent captures resolve to {:not_scored, :empty_capture} and never fall back to expected_output."

patterns-established:
  - "Frozen capture: dataset items carry captured_output, captured_output_sha256, and captured_at as promotion-time evidence."
  - "Single resolver contract: future offline and judge runners call SubjectOutput.resolve/2 rather than independently deciding actual output."

requirements-completed: [EVAL-01]

duration: 7 min
completed: 2026-07-04
status: complete
---

# Phase 42 Plan 02: Subject Output Capture Summary

**Dataset promotion now freezes a hashable subject output from workflow step results, and SubjectOutput.resolve/2 fails closed for empty captures across offline and judge modes.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-07-04T22:10:40Z
- **Completed:** 2026-07-04T22:17:23Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added nullable `captured_output`, `captured_output_sha256`, and `captured_at` fields plus an idempotent migration for `ai_eval_dataset_items`.
- Populated capture at promotion from `Scoria.Workflows.Step.result_envelope["output"]`, with canonical sha256 and timestamp, without changing promotion caller attrs.
- Added `Scoria.Eval.SubjectOutput.resolve/2` so `:offline_replay` and `:live_judge` share one frozen-output contract.
- Pinned fail-closed behavior: nil or empty captures return `{:not_scored, :empty_capture}` and never fabricate expected output as actual.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add captured_output fields + migration** - `d792caed` (feat)
2. **Task 2: Populate capture at promotion from real source output** - `2b19e2fe` (feat)
3. **Task 3 RED: SubjectOutput resolver tests** - `404d9195` (test)
4. **Task 3 GREEN: SubjectOutput resolver implementation** - `861a9171` (feat)

_Note: Task 3 followed the required TDD RED -> GREEN sequence._

## Files Created/Modified

- `lib/scoria/eval/dataset_item.ex` - Adds capture fields to the Ecto schema and changeset cast list.
- `priv/repo/migrations/20260704221053_add_dataset_item_captured_output.exs` - Adds/removes capture columns idempotently.
- `lib/scoria/eval/dataset_promotion.ex` - Loads the workflow step internally and persists non-empty captured output with sha/timestamp.
- `test/scoria/eval/dataset_promotion_test.exs` - Verifies Step output capture, empty/absent capture nil behavior, and no new promotion attr key.
- `lib/scoria/eval/subject_output.ex` - Provides the shared subject-output resolver.
- `test/scoria/eval/subject_output_test.exs` - Pins frozen capture, nil/empty not_scored, no expected-output fallback, and live_judge delegation.

## Decisions Made

- Used an internal `Repo.get(Scoria.Workflows.Step, workflow_step_id)` in promotion so the four existing callers keep their fixed attr set.
- Treated only non-empty map outputs as captured outputs because the destination column is a map and empty maps are explicitly not scoreable.
- Used `Jason.OrderedObject` canonical JSON encoding before sha256 so semantically identical map key order does not change the capture hash.
- Returned the same `:empty_capture` reason for nil and `%{}` because both are nil-equivalent for scoring.

## Verification

- `mix ecto.migrate && mix ecto.rollback && mix ecto.migrate` - passed; migration applies, rolls back, and reapplies.
- `MIX_ENV=test mix ecto.migrate` - passed; test DB schema updated for capture columns.
- `mix test test/scoria/eval/dataset_promotion_test.exs --warnings-as-errors` - passed, 3 tests.
- `mix test test/scoria/eval_test.exs --warnings-as-errors` - passed, 11 tests.
- `mix test test/scoria/eval/subject_output_test.exs --warnings-as-errors` - passed, 4 tests.
- `mix ecto.migrate && mix test test/scoria/eval/subject_output_test.exs test/scoria/eval/dataset_promotion_test.exs --warnings-as-errors` - passed, migrations already up and 7 tests green.
- No live LLM/API keys were used.

## TDD Gate Compliance

- RED gate: `404d9195` added failing `SubjectOutput.resolve/2` tests; failure was expected because the module was not yet defined.
- GREEN gate: `861a9171` added the resolver and the same tests passed.
- Refactor gate: not needed; implementation stayed small and direct after GREEN.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed capture lookup after local attrs shadowing**
- **Found during:** Task 2 (Populate capture at promotion from real source output)
- **Issue:** The first implementation shadowed the original promotion attrs with the item attrs map before computing capture, so `workflow_step_id` was no longer at the top level and real Step output was not captured.
- **Fix:** Kept the assembled item attrs in a separate `item_attrs` variable and passed the original attrs to `captured_output_attrs/1`.
- **Files modified:** `lib/scoria/eval/dataset_promotion.ex`
- **Verification:** `mix test test/scoria/eval/dataset_promotion_test.exs --warnings-as-errors`
- **Committed in:** `2b19e2fe`

---

**Total deviations:** 1 auto-fixed (Rule 1 bug)
**Impact on plan:** Required for correctness; no scope expansion.

## Issues Encountered

- The planned `test/scoria/eval/dataset_promotion_test.exs` did not exist yet; it was created as the focused Task 2 test file.
- The test database initially lacked the new columns after the dev migration; `MIX_ENV=test mix ecto.migrate` resolved the schema mismatch.

## Known Stubs

None. Stub scan hits were intentional nil assertions for empty/absent capture behavior and the pre-existing required-key validation check.

## Threat Flags

None. The new trust-boundary surfaces were already covered by the plan threat model: T-42-07 and T-42-08.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 42-03 ExactMatch and the 42-04/42-05 runner consumers. Both offline and judge runner work can now call `SubjectOutput.resolve/2` instead of self-grading or re-reading mutable traces.

## Self-Check: PASSED

- Created/modified files exist on disk.
- Task commits found in git history: `d792caed`, `2b19e2fe`, `404d9195`, `861a9171`.
- Working tree was clean before summary creation.
- Plan-level verification passed.

---
*Phase: 42-eval-fails-closed*
*Completed: 2026-07-04*
