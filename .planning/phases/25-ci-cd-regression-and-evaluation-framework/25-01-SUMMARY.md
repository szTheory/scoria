---
phase: 25-ci-cd-regression-and-evaluation-framework
plan: 01
subsystem: database
tags: [ecto, postgres, evals, persistence]
requires:
  - phase: 24-trace-to-dataset-curation-via-liveview
    provides: sealed dataset lineage in ai_eval_datasets and ai_eval_dataset_items
provides:
  - canonical eval persistence rooted in Phase 24 dataset tables
  - typed EvalSpec embeds with immutable versioning
  - durable EvalRun and Score persistence APIs for later replay and judge lanes
affects: [phase-25-02, phase-25-03, evals, ci]
tech-stack:
  added: []
  patterns: [typed embeds for eval contracts, explicit run header facts, per-item evidence persistence]
key-files:
  created: [.planning/phases/25-ci-cd-regression-and-evaluation-framework/25-01-SUMMARY.md]
  modified: [lib/scoria/eval.ex, lib/scoria/eval/eval_spec.ex, lib/scoria/eval/eval_run.ex, lib/scoria/eval/score.ex, priv/repo/migrations/20260519000000_converge_eval_persistence.exs, test/scoria/eval/eval_run_persistence_test.exs]
key-decisions:
  - "Made ai_eval_datasets and ai_eval_dataset_items the only canonical dataset lineage for eval persistence."
  - "Replaced the untyped rubric blob with typed subject, scorers, and threshold embeds on EvalSpec."
  - "Persisted aggregate EvalRun facts separately from per-item Score evidence rows."
patterns-established:
  - "Eval specs snapshot sealed dataset identity and reject mutable alias inputs."
  - "Run persistence flows through create_eval_run/1, record_eval_scores/2, and complete_eval_run/2."
requirements-completed: [EVAL-04]
duration: 25m
completed: 2026-05-19
---

# Phase 25: CI/CD Regression & Evaluation Framework Summary

**Canonical eval persistence now hangs off sealed Phase 24 datasets with typed specs, explicit run headers, and durable per-item evidence rows.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-05-19T13:32:00Z
- **Completed:** 2026-05-19T13:57:42Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- Converged eval foreign keys from the legacy dataset tables onto `ai_eval_datasets` and `ai_eval_dataset_items`.
- Replaced `EvalSpec.rubric` with typed `subject`, `scorers`, and `threshold_policy` embeds plus immutable version bump behavior.
- Added durable `EvalRun` header facts, explicit `Score` evidence fields, and context helpers for run creation, score recording, and completion.

## Task Commits

1. **Task 1: Converge the old eval tables onto the Phase 24 dataset lineage** - `26b2dc6`, `06eb037`
2. **Task 2: Replace the untyped eval spec contract with explicit typed embeds and immutable version rules** - `81271f2`
3. **Task 3: Expand eval runs and score rows into durable header facts plus evidence APIs** - completed in the working tree during Wave 1 verification and migration repair

## Files Created/Modified
- `priv/repo/migrations/20260519000000_converge_eval_persistence.exs` - converges legacy eval storage onto the canonical dataset lineage and expands spec/run/score columns.
- `lib/scoria/eval/eval_spec.ex` - typed embedded eval contract with immutable version validation.
- `lib/scoria/eval/eval_run.ex` - explicit run header schema for replay/judge execution facts.
- `lib/scoria/eval/score.ex` - explicit per-item evidence schema without reasoning blobs.
- `lib/scoria/eval.ex` - public persistence APIs for eval specs, runs, score recording, and completion.
- `test/scoria/eval/eval_run_persistence_test.exs` - regression coverage for canonical lineage, typed specs, and durable run/evidence persistence.

## Decisions Made

- Stored `scorers` as an array-of-maps in Postgres so `embeds_many` matches the database shape and migrations run cleanly from a fresh database.
- Derived run snapshot defaults from the immutable `EvalSpec` so later replay/judge plans inherit a stable truth boundary.
- Kept score explanations concise and moved extra execution facts into explicit `metadata` and `evidence_refs` fields rather than opaque blobs.

## Deviations from Plan

### Auto-fixed Issues

**1. Migration storage-shape mismatch**
- **Found during:** Task 2/3 verification
- **Issue:** The convergence migration initially stored `scorers` with a scalar `:map` type, which breaks fresh database bootstrap for `embeds_many`.
- **Fix:** Changed the column to `{:array, :map}` with a list default and re-ran the test database bootstrap from scratch.
- **Files modified:** `priv/repo/migrations/20260519000000_converge_eval_persistence.exs`
- **Verification:** `MIX_ENV=test mix ecto.drop && MIX_ENV=test mix ecto.create && MIX_ENV=test mix ecto.migrate`, `mix test test/scoria/eval/eval_run_persistence_test.exs`

---

**Total deviations:** 1 auto-fixed
**Impact on plan:** Required for correctness. No scope expansion.

## Issues Encountered

- The first Wave 1 executor pass left the migration half-finished and the test database in a stale schema state. Repair required resetting the test database and validating the migration against a clean bootstrap.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan `25-02` can now build the offline replay lane on top of the canonical `EvalSpec`, `EvalRun`, and `Score` APIs.
- The local test database was reset during verification so future targeted tests start from the converged Phase 25 schema.

---
*Phase: 25-ci-cd-regression-and-evaluation-framework*
*Completed: 2026-05-19*
