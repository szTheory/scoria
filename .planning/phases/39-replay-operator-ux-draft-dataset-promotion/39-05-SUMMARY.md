---
phase: 39-replay-operator-ux-draft-dataset-promotion
plan: 5
subsystem: runtime
tags: [replay, runtime, liveview, dataset-promotion, eval]
requires:
  - phase: 39-02
    provides: replay workflow comparison data and workflow-page promotion context wiring
  - phase: 39-03
    provides: frozen workflow-source dataset promotion service and open-dataset modal path
  - phase: 39-04
    provides: sealed baseline approval lane without reopening draft promotion semantics
provides:
  - durable replay source checkpoint lineage in the runtime comparison contract
  - workflow promotion contexts that preserve replay provenance and safety keys end to end
  - dataset item metadata persistence for replay disposition and replay reason from runtime-driven payloads
affects: [phase-40-online-scoring, replay-operator-ux, dataset-promotion]
tech-stack:
  added: []
  patterns: [runtime-derived replay promotion regressions, safety-first replay metadata persistence]
key-files:
  created: [.planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-05-SUMMARY.md]
  modified:
    - lib/scoria/runtime/replay_comparison.ex
    - lib/scoria_web/live/workflow_live/show.ex
    - lib/scoria/eval/dataset_promotion.ex
    - test/scoria/runtime_view_test.exs
    - test/scoria/eval_test.exs
    - test/scoria_web/live/dataset_live/promote_component_test.exs
key-decisions:
  - "Replay comparison provenance now duplicates replay disposition and replay reason alongside the safety group so downstream consumers do not infer safety context."
  - "Dataset promotion persists replay disposition and replay reason from `safety` first, with provenance as a fallback, because the runtime/UI contract already treats safety as the canonical replay metadata surface."
patterns-established:
  - "Runtime-driven replay promotion tests: build replay payloads from `Runtime.get_run_detail!/1` instead of fabricated params."
  - "Replay lineage binding: `source_checkpoint_id` for replay promotions must resolve from durable source refs, never the replay checkpoint row id."
requirements-completed: [RPLY-03, DATA-01]
duration: 5min
completed: 2026-05-23
---

# Phase 39 Plan 5: Replay Operator UX Draft Dataset Promotion Summary

**Replay promotions now carry durable source lineage and persist replay safety metadata from the runtime-selected contract into immutable dataset items**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-23T13:20:47Z
- **Completed:** 2026-05-23T13:25:59Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Fixed replay comparison provenance so replay selections expose the original source checkpoint lineage plus replay disposition and replay reason in the runtime contract.
- Kept the workflow-page promotion payload aligned with the runtime comparison groups and prevented replay metadata reshaping at the LiveView seam.
- Persisted replay disposition and replay reason into dataset item metadata from runtime-driven replay payloads and replaced fabricated replay promotion tests with end-to-end regressions.

## Task Commits

Each task was committed atomically through TDD gates:

1. **Task 1: Correct the replay promotion contract at the runtime and workflow-page seams** - `361dfe0` (test), `f35884a` (feat)
2. **Task 2: Persist replay metadata end-to-end and replace synthetic promotion coverage with runtime-driven regressions** - `9d4bdf4` (test), `23cfc0f` (feat)

**Plan metadata:** pending current execution commit

## Files Created/Modified
- `lib/scoria/runtime/replay_comparison.ex` - binds replay provenance to durable source refs and mirrors replay metadata into provenance and safety groups.
- `lib/scoria_web/live/workflow_live/show.ex` - forwards replay promotion context from the selected runtime entry without renaming replay keys.
- `lib/scoria/eval/dataset_promotion.ex` - persists replay disposition and replay reason from the runtime safety payload with provenance fallback.
- `test/scoria/runtime_view_test.exs` - locks replay lineage and promotion-group contract behavior.
- `test/scoria/eval_test.exs` - verifies runtime-derived replay promotions persist immutable metadata into dataset items.
- `test/scoria_web/live/dataset_live/promote_component_test.exs` - verifies replay promotions and sealed-baseline requests use runtime-derived replay contexts.
- `.planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-05-SUMMARY.md` - execution summary for this plan.

## Decisions Made
- Duplicated replay disposition and replay reason into both `provenance` and `safety` for replay comparison entries so persistence and UI consumers can read the same evidence path without recomputation.
- Kept `source_checkpoint_id` canonical in `provenance` and sourced it from durable replay source refs to avoid persisting the replay checkpoint row id as lineage.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Hardened replay comparison source ref reads for partial structs**
- **Found during:** Task 1 (Correct the replay promotion contract at the runtime and workflow-page seams)
- **Issue:** The new runtime regression called `ReplayComparison.build/2` with a partially loaded source run, and `source_refs_for_step/2` assumed all associations were preloaded.
- **Fix:** Added association guards so replay/source ref extraction treats unloaded associations as empty lists instead of crashing.
- **Files modified:** `lib/scoria/runtime/replay_comparison.ex`
- **Verification:** `mix test test/scoria/runtime_view_test.exs`
- **Committed in:** `f35884a` (part of task commit)

---

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** The auto-fix was required to keep the replay comparison builder safe for direct runtime-helper usage. No scope creep.

## Issues Encountered
The targeted tests initially failed on fixture issues while converting replay coverage to runtime-derived payloads. Those were corrected inside the test slices so the RED gates failed for the intended contract mismatch rather than invalid fixture state.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Replay promotions now preserve the exact lineage and safety metadata needed by later operator review and scoring flows.
- Future phases can rely on the runtime/LiveView replay promotion contract being locked by end-to-end tests instead of synthetic payloads.

## Self-Check: PASSED

- Verified `.planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-05-SUMMARY.md` exists on disk.
- Verified task commits `361dfe0`, `f35884a`, `9d4bdf4`, and `23cfc0f` exist in git history.

---
*Phase: 39-replay-operator-ux-draft-dataset-promotion*
*Completed: 2026-05-23*
