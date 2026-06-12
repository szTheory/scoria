---
phase: 14-least-iterated-screens-polish
plan: "02"
subsystem: ui
tags: [phoenix-liveview, dataset-builder, promotion, design-system, ds06, tdd]

requires:
  - phase: 14-01
    provides: Dataset Builder route, index surface, and least-iterated screen shell
  - phase: 14-04
    provides: Shared polish patterns for Phase 14 surfaces
  - phase: 12-design-system-component-layer
    provides: ScoriaWeb.UI shared component layer and DS-06 drift guard
provides:
  - URL-driven Dataset Builder promotion reconstruction from stable IDs
  - Shared Dataset Builder drawer host for review and workflow promotion sources
  - PromoteComponent converted to tokenized shared UI surfaces with preserved behavior
  - Removed PromoteComponent row from DS-06 raw-palette baseline after zero leakage
affects: [dataset-builder, review-queue, workflow-show, dataset-promotion, ds06-baseline]

tech-stack:
  added: []
  patterns:
    - Dataset Builder promotion URLs carry stable IDs and intent only
    - Promotion context is reconstructed server-side from canonical review and workflow records
    - LiveComponent actions use shared ScoriaWeb.UI buttons with LiveView event attrs

key-files:
  created:
    - .planning/phases/14-least-iterated-screens-polish/14-02-SUMMARY.md
  modified:
    - lib/scoria_web/live/dataset_live/index.ex
    - test/scoria_web/live/dataset_live/index_test.exs
    - lib/scoria_web/live/dataset_live/promote_component.ex
    - test/scoria_web/live/dataset_live/promote_component_test.exs
    - lib/scoria_web/ui.ex
    - test/support/ds06_baseline.txt

key-decisions:
  - "Dataset Builder reconstructs promotion context from stable IDs instead of encoding raw promotion snapshots or expected-output JSON into URLs."
  - "Invalid or stale promotion params render the exact recoverable UI-SPEC copy and stay on Dataset Builder."
  - "ScoriaWeb.UI.button/1 now accepts phx-target and phx-value-dataset-id so PromoteComponent can use shared buttons for LiveComponent events."
  - "Manual worktree execution intentionally skipped STATE.md and ROADMAP.md updates; the orchestrator owns shared tracking after merge."

patterns-established:
  - "URL-owned drawers: same-LiveView close and selection changes use patch semantics on /scoria/datasets."
  - "DS-06 cleanup: remove a baseline row only after the component source has zero raw-palette matches."

requirements-completed: [SCREEN-02]

duration: 35min
completed: 2026-06-12
---

# Phase 14 Plan 02: Dataset Builder Promotion Summary

**Dataset Builder promotion drawer reconstructed from stable review and workflow IDs, with PromoteComponent moved onto shared UI surfaces and cleared from DS-06 baseline debt**

## Performance

- **Duration:** 35 min
- **Started:** 2026-06-12T17:35:00Z
- **Completed:** 2026-06-12T18:10:10Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added URL-driven promotion state to Dataset Builder for review candidates and workflow run evidence using `promote`, `review_candidate_id`, `run_id`, `step_id`, and `source_variant`.
- Rendered the reused `ScoriaWeb.DatasetLive.PromoteComponent` inside a shared `dataset-promote-drawer` with exact stale-ID recovery copy.
- Converted PromoteComponent markup to shared `panel`, `form_section`, `field`, `button`, `badge`, `empty_state`, and `raw_evidence` surfaces.
- Preserved draft promotion and sealed-baseline approval behavior while removing the PromoteComponent DS-06 baseline row.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add URL-driven promotion reconstruction tests** - `0d141d3` (test)
2. **Task 1 GREEN: Reconstruct promotion drawer from URL params** - `57792b0` (feat)
3. **Task 2 RED: Add PromoteComponent polish coverage** - `e0de3f7` (test)
4. **Task 2 GREEN: Convert PromoteComponent to shared surfaces** - `68cf829` (feat)

**Plan metadata:** committed separately in the final docs commit.

## Files Created/Modified

- `.planning/phases/14-least-iterated-screens-polish/14-02-SUMMARY.md` - Execution summary for plan 14-02.
- `lib/scoria_web/live/dataset_live/index.ex` - Added `handle_params/3`, promotion param reconstruction, drawer state, stale-source state, and close patch handling.
- `test/scoria_web/live/dataset_live/index_test.exs` - Added URL-driven promotion tests for review, workflow, invalid params, and patch semantics.
- `lib/scoria_web/live/dataset_live/promote_component.ex` - Converted markup to shared UI components while preserving existing promotion actions.
- `test/scoria_web/live/dataset_live/promote_component_test.exs` - Added sealed-baseline, invalid JSON, and shared-surface coverage.
- `lib/scoria_web/ui.ex` - Allowed shared buttons to carry the LiveComponent event attributes needed by PromoteComponent.
- `test/support/ds06_baseline.txt` - Removed the PromoteComponent raw-palette baseline row.

## Decisions Made

- Review promotion URLs reconstruct through `Eval.get_review_candidate/1` and reuse the persisted `promotion_context`.
- Workflow promotion URLs reconstruct through persisted run details and selected source variant data rather than carrying arbitrary maps in query params.
- Stale or invalid promotion params show the exact UI-SPEC heading `Promotion source not found` and body copy instead of navigating away.
- PromoteComponent remains the stateful behavior owner; the work only changed the shell and surface components.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Restored missing locked Mix deps in the fresh worktree**
- **Found during:** Task 1 verification setup
- **Issue:** The assigned worktree did not have locked dependencies available, which blocked running the planned Mix tests.
- **Fix:** Ran `mix deps.get`; no dependency versions or tracked files changed.
- **Files modified:** None
- **Verification:** Planned Mix tests ran after dependency restoration.
- **Committed in:** Not committed; environment setup only.

**2. [Rule 3 - Blocking] Added LiveComponent event attrs to shared button**
- **Found during:** Task 2 conversion
- **Issue:** PromoteComponent could not fully use shared `<.button>` for LiveComponent actions because the shared button did not accept `phx-target` or `phx-value-dataset-id`.
- **Fix:** Added those attrs to `ScoriaWeb.UI.button/1`.
- **Files modified:** `lib/scoria_web/ui.ex`
- **Verification:** PromoteComponent tests and DS-06 drift guard passed.
- **Committed in:** `68cf829`

**3. [Rule 1 - Test Correction] Removed over-specified stale-ID path rewrite expectation**
- **Found during:** Task 1 GREEN
- **Issue:** The initial RED stale-ID assertion over-specified URL cleanup. The plan required exact recoverable copy and remaining on Dataset Builder, not stripping query params.
- **Fix:** Adjusted the test to assert the required recoverable state without inventing extra navigation behavior.
- **Files modified:** `test/scoria_web/live/dataset_live/index_test.exs`
- **Verification:** Dataset Builder index tests passed.
- **Committed in:** `57792b0`

---

**Total deviations:** 3 auto-fixed (1 Rule 1, 2 Rule 3)
**Impact on plan:** No scope expansion. Fixes were necessary to complete the planned behavior and preserve shared-component usage.

## Issues Encountered

- The sealed-baseline PromoteComponent test needed persisted workflow context rather than a synthetic run ID so existing baseline promotion lookup behavior could execute normally.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/scoria_web/live/dataset_live/index_test.exs test/scoria_web/live/dataset_live/promote_component_test.exs test/scoria_web/ds06_drift_guard_test.exs` passed with 17 tests and 0 failures.
- `rg -n "Jason\\.encode|Base\\.encode" lib/scoria_web/live/dataset_live/index.ex` returned no matches.
- `rg -n "\\b(stone|rose|sky|emerald|amber|blue|gray|slate|zinc|neutral|red|green|yellow|purple|pink|indigo|teal|cyan|lime|orange|violet|fuchsia)-\\d" lib/scoria_web/live/dataset_live/promote_component.ex` returned no matches.
- `grep -E '^lib/scoria_web/live/dataset_live/promote_component\\.ex:' test/support/ds06_baseline.txt` returned no matches.

## Known Stubs

None.

## Threat Flags

None. The new query-param trust boundary and promotion form trust boundary were already covered by the plan threat model.

## TDD Gate Compliance

- RED gate present for Task 1: `0d141d3`
- GREEN gate present for Task 1: `57792b0`
- RED gate present for Task 2: `e0de3f7`
- GREEN gate present for Task 2: `68cf829`

## Next Phase Readiness

Dataset Builder now owns the shared promotion entry point needed by later source screens. Follow-on polish can link review and workflow screens into the Dataset Builder promotion URL shape without duplicating promotion UI.

## Self-Check: PASSED

- Summary file created at `.planning/phases/14-least-iterated-screens-polish/14-02-SUMMARY.md`.
- Implementation commits found: `0d141d3`, `57792b0`, `e0de3f7`, `68cf829`.
- Plan verification command passed before summary creation.
- `.planning/STATE.md` and `.planning/ROADMAP.md` were not modified in this manual worktree.

---
*Phase: 14-least-iterated-screens-polish*
*Completed: 2026-06-12*
