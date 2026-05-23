---
phase: 39-replay-operator-ux-draft-dataset-promotion
plan: 01
subsystem: runtime
tags: [elixir, ecto, runtime, replay, dto, provenance]
requires:
  - phase: 38-replay-safe-execution-tool-modes
    provides: replay-safe checkpoint, event, and approval provenance truth
provides:
  - replay comparison maps keyed by workflow step
  - replay provenance strip DTO data for operator UI
  - promotion snapshot contracts for original and replay variants
affects: [workflow-live, dataset-promotion, replay-operator-ux]
tech-stack:
  added: []
  patterns: [runtime-boundary source-run loading, curated replay comparison DTOs, TDD contract locking]
key-files:
  created: [lib/scoria/runtime/replay_comparison.ex]
  modified: [lib/scoria/runtime.ex, lib/scoria/runtime/run_detail.ex, test/scoria/runtime_view_test.exs, test/scoria/runtime_test.exs]
key-decisions:
  - "Keep replay source-run lookup inside Scoria.Runtime.get_run_detail!/1 so LiveView never assembles comparison state from raw workflow structs."
  - "Prefer explicit source_step_id lineage from checkpoints, events, and approvals before falling back to step sequence matching."
patterns-established:
  - "Replay UI reads comparison_by_step and replay_provenance_strip from runtime DTO truth rather than template-side inspection."
  - "Promotion snapshot metadata is built as grouped original/replay evidence with stable workflow_run_id, workflow_step_id, source_variant, recorded_outcome, and replay_reason_code keys."
requirements-completed: [RPLY-03]
duration: 7min
completed: 2026-05-23
---

# Phase 39 Plan 01: Replay runtime DTO comparison contracts Summary

**Replay-aware runtime DTOs now expose original-versus-replay evidence groups, promotion snapshot metadata, and provenance-strip fields from durable workflow truth**

## Performance

- **Duration:** 7 min
- **Started:** 2026-05-23T12:11:00Z
- **Completed:** 2026-05-23T12:18:55Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Added `Scoria.Runtime.ReplayComparison` to normalize original and replay evidence into grouped `provenance`, `overrides`, `checkpoint_output`, `safety`, and `promotion_snapshot` maps per replay step.
- Expanded `Scoria.Runtime.RunDetail` so step DTOs carry `projected_context`, `result_envelope`, `error_envelope`, `idempotency_key`, plus top-level `comparison_by_step` and `replay_provenance_strip`.
- Moved source-run loading and nil-safe replay provenance shaping into `Scoria.Runtime.get_run_detail!/1`, with regressions proving live runs remain supported without a persisted source run.

## Task Commits

Each task was committed atomically:

1. **Task 1: Define replay comparison contracts and promotion-source groups** - `58a893a` (test), `406e3e5` (feat)
2. **Task 2: Load replay source runs through the runtime boundary and lock the DTO regressions** - `db4d737` (test)

## Files Created/Modified
- `lib/scoria/runtime/replay_comparison.ex` - Builds grouped original/replay comparison variants and provenance-strip maps.
- `lib/scoria/runtime.ex` - Loads replay source runs at the runtime boundary and feeds both trees into the DTO builder.
- `lib/scoria/runtime/run_detail.ex` - Expands the public detail DTO with replay comparison, provenance strip, and richer step/checkpoint fields.
- `test/scoria/runtime_view_test.exs` - Locks replay comparison, promotion snapshot, and provenance-strip contracts.
- `test/scoria/runtime_test.exs` - Proves live runs still resolve detail DTOs without source-run loading.

## Decisions Made

- Kept source-run lookup optional for replay runs because existing replay provenance can reference historical IDs without a persisted source tree in tests.
- Left `Scoria.Runtime.ReplayComparison` query-free and fed it only fully loaded run trees from `Scoria.Runtime`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Made replay source-run lookup nil-safe**
- **Found during:** Task 1 (Define replay comparison contracts and promotion-source groups)
- **Issue:** Existing replay regression coverage uses lineage identifiers that do not always have a persisted source run tree; unconditional lookup raised `:not_found`.
- **Fix:** Rescued missing source-run lookups inside `Scoria.Runtime.get_run_detail!/1` and let comparison building degrade to an empty map when no source tree exists.
- **Files modified:** `lib/scoria/runtime.ex`
- **Verification:** `mix test test/scoria/runtime_view_test.exs` and `mix test test/scoria/runtime_view_test.exs test/scoria/runtime_test.exs`
- **Committed in:** `406e3e5`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The auto-fix preserved the intended runtime boundary while keeping pre-existing replay lineage scenarios readable. No scope creep.

## Issues Encountered

- The RED test commit initially exposed a couple of pattern-match mistakes in the new assertions; those were corrected before capturing the failing contract.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `comparison_by_step` and `replay_provenance_strip` are ready for the Phase 39 workflow-page notebook UI.
- Promotion flows can now consume stable original/replay source-variant metadata without inspecting workflow structs directly.

## Self-Check

PASSED
- Found summary file: `.planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-01-SUMMARY.md`
- Found task commits: `58a893a`, `406e3e5`, `db4d737`

---
*Phase: 39-replay-operator-ux-draft-dataset-promotion*
*Completed: 2026-05-23*
