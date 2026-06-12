---
phase: 13-orientation-spine-ia
plan: "05"
subsystem: ui
tags: [phoenix-liveview, object-pages, information-architecture]
requires:
  - phase: 13-orientation-spine-ia
    provides: IA component primitives from plan 13-01
  - phase: 13-orientation-spine-ia
    provides: Status Home as stable dashboard entry from plan 13-04
provides:
  - object-aware run page header
  - object-aware prompt release header
  - allowlisted origin return chips from route params
  - standardized replay provenance header line
affects: [workflow-show, prompt-release-workbench, object-header]
tech-stack:
  added: []
  patterns:
    - route-param origin context assigned in handle_params/3
    - shared object_header for object-page orientation
key-files:
  created: []
  modified:
    - lib/scoria_web/live/workflow_live/show.ex
    - lib/scoria_web/live/prompt_live/release_workbench_live.ex
    - test/scoria_web/live/workflow_live_test.exs
    - test/scoria_web/live/prompt_live/release_workbench_live_test.exs
    - test/support/ds06_baseline.txt
key-decisions:
  - "Origin context is parsed only in `handle_params/3`, so initial navigation and route-param patches share the same behavior."
  - "Unknown origin nouns are ignored silently instead of rendering an error or fallback chip."
  - "Run and prompt object pages use the shared `<.object_header>` component so copyable IDs, crumbs, status, and recent-object metadata stay consistent."
patterns-established:
  - "`?from={noun}:{id}` is allowlisted to `incident`, `review`, `run`, `dataset`, `eval`, and `prompt`."
  - "Replay provenance header copy follows `Replayed from run ... via checkpoint ... - {date}`."
requirements-completed: [IA-03, IA-05]
duration: 10 min
completed: 2026-06-12
---

# Phase 13 Plan 05: Object-Aware Page Headers

**Run and prompt release object pages now show shared object identity headers with safe return context**

## Performance

- **Duration:** 10 min
- **Started:** 2026-06-12T02:17:00Z
- **Completed:** 2026-06-12T02:26:59Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added LiveView coverage for run object headers, prompt release object headers, route-param origin recomputation, unknown-origin silence, copyable IDs, and replay provenance.
- Replaced bespoke workflow and prompt release headers with `<.object_header>`.
- Added `handle_params/3` origin context assignment to both object pages without adding `from` parsing to `mount/3`.
- Added allowlisted origin parsing for `incident`, `review`, `run`, `dataset`, `eval`, and `prompt`.
- Passed provenance into the workflow header using the standardized replay grammar.
- Reconciled DS-06 baselines after shared component usage lowered raw palette counts in both modified LiveViews.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add object-header LiveView tests** - `6e306ca` (test)
2. **Task 2: Implement object-aware page headers** - `9229aba` (feat)

## Files Created/Modified

- `lib/scoria_web/live/workflow_live/show.ex` - Run object header, replay provenance line, and route-param origin context.
- `lib/scoria_web/live/prompt_live/release_workbench_live.ex` - Prompt object header and route-param origin context.
- `test/scoria_web/live/workflow_live_test.exs` - Workflow object header, origin, and status assertions.
- `test/scoria_web/live/prompt_live/release_workbench_live_test.exs` - Prompt release object header and origin assertions.
- `test/support/ds06_baseline.txt` - Lowered baselines for the two modified object pages.

## Decisions Made

- The workflow header uses `Runs` as the parent crumb and `Run` as the object type; existing page-title text remains covered by the LiveView title.
- Prompt draft status is normalized through the shared UI status label by passing `draft_blocked`, which renders as `Draft blocked`.
- Dataset and eval origins currently route to the eval-spec area because there is no separate dataset object route in this dashboard surface.

## Deviations from Plan

- The plan named `test/scoria_web/live/prompt_live_test.exs`, but the local codebase has a dedicated `test/scoria_web/live/prompt_live/release_workbench_live_test.exs` file for this LiveView. Coverage was added there instead.

**Total deviations:** 1 path correction. **Impact:** No behavior impact; tests are closer to the LiveView under change.

## Issues Encountered

- DS-06 failed after object-header adoption reduced raw repeated palette counts; the baseline was lowered from 42 to 37 for `release_workbench_live.ex` and from 53 to 50 for `workflow_live/show.ex`.
- Existing workflow tests expected lowercase raw status text. Those assertions were updated to match the shared `ScoriaWeb.UI.status_label/1` rendering.

## User Setup Required

None - no external service configuration required.

## Verification

- Red step: `mix test test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/prompt_live/release_workbench_live_test.exs --max-failures 1` - failed before implementation on missing `handle_params/3` and object-header markup.
- Focused pass: `mix test test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/prompt_live/release_workbench_live_test.exs test/scoria_web/ds06_drift_guard_test.exs` - 24 tests, 0 failures.
- Source check: `rg -n 'object_header|origin_context|@origin_nouns|params\["from"\]' lib/scoria_web/live/workflow_live/show.ex lib/scoria_web/live/prompt_live/release_workbench_live.ex` - matched only shared header usage, `handle_params/3` origin assignment, and allowlist helpers.

## Self-Check: PASSED

- Both object pages render `<.object_header>`.
- Origin context is assigned from `handle_params/3` on initial render and route-param updates.
- `mount/3` does not parse `params["from"]`.
- Unknown origins render no chip and no visible error.
- Run and prompt IDs remain available through the shared copyable ID component.
- Replay header provenance uses the standardized `Replayed from run ... via checkpoint ... - {date}` grammar.
- No loop rail, stepper, or wizard wording was introduced.

## Next Phase Readiness

Command palette work can use the `RecordRecentObject` metadata now emitted by `object_header` on run and prompt release object pages.

---
*Phase: 13-orientation-spine-ia*
*Completed: 2026-06-12*
