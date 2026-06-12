---
phase: 14-least-iterated-screens-polish
plan: "01"
subsystem: ui
tags: [phoenix-liveview, navigation, dataset-builder, design-system, tdd]

requires:
  - phase: 13-orientation-spine-ia
    provides: DashboardNav grouped IA, command metadata, shortcuts, and dashboard live session patterns
  - phase: 12-design-system-component-layer
    provides: ScoriaWeb.UI table, panel, metric, badge, id, and empty_state components
provides:
  - Dataset Builder route at /datasets under scoria_dashboard mounts
  - Dataset Builder Improve navigation item, command row, active-state mapping, and g d shortcut
  - Data-backed Dataset Builder index that lists real open and sealed datasets
  - Dataset Builder LiveView tests covering empty and populated states
affects: [phase-14, dataset-builder, review-queue, workflow-promotion, command-palette]

tech-stack:
  added: []
  patterns:
    - "TDD RED/GREEN per task: route/nav contract tests before metadata, index tests before LiveView implementation"
    - "Dataset Builder reads persisted data through Scoria.Eval and renders through ScoriaWeb.UI components"

key-files:
  created:
    - lib/scoria_web/live/dataset_live/index.ex
    - test/scoria_web/live/dataset_live/index_test.exs
    - .planning/phases/14-least-iterated-screens-polish/14-01-SUMMARY.md
  modified:
    - lib/scoria_web/dashboard_nav.ex
    - lib/scoria_web/router.ex
    - test/scoria_web/dashboard_nav_test.exs
    - test/scoria_web/router_test.exs

key-decisions:
  - "Dataset Builder is a real Improve route and not a coming-soon stub."
  - "The index renders real Eval datasets only; promotion drawer URL handling stays for Plan 14-02."

patterns-established:
  - "Dataset Builder route additions must remain base-path aware through scoria_dashboard('/path') route tests."
  - "New Phase 14 screens should include explicit raw-palette source assertions alongside DS-06."

requirements-completed: [SCREEN-02]

duration: 7 min
completed: 2026-06-12
---

# Phase 14 Plan 01: Dataset Builder Route and Index Summary

**Dataset Builder is now a real `/datasets` dashboard destination with Improve navigation, command metadata, shortcut coverage, and a data-backed dataset table.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-12T17:34:18Z
- **Completed:** 2026-06-12T17:41:41Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added Dataset Builder to Improve navigation after Review Queue and before Eval Workbench.
- Mounted `/datasets` in the existing dashboard live session and covered `/scoria/datasets` route construction.
- Created `ScoriaWeb.DatasetLive.Index` using `Scoria.Eval.list_datasets/0` and real dataset item counts/source metadata.
- Added LiveView tests for exact title, subtitle, empty state, real open/sealed dataset rows, and zero raw-palette leakage.

## Task Commits

1. **Task 1 RED: Add Dataset Builder nav/route contract tests** - `d115166` (test)
2. **Task 1 GREEN: Add Dataset Builder route and navigation** - `8d84f0f` (feat)
3. **Task 2 RED: Add Dataset Builder index coverage** - `5c33fd2` (test)
4. **Task 2 GREEN: Implement Dataset Builder index** - `eb4abfd` (feat)

**Plan metadata:** committed separately in the docs closeout commit.

## Files Created/Modified

- `lib/scoria_web/live/dataset_live/index.ex` - New Dataset Builder index LiveView with metrics, shared table, empty state, and real Eval dataset rows.
- `test/scoria_web/live/dataset_live/index_test.exs` - Route-level LiveView coverage for empty/populated Dataset Builder states and raw-palette absence.
- `lib/scoria_web/dashboard_nav.ex` - Dataset Builder nav item, active key, command row shortcut, and base-prefix stripping.
- `test/scoria_web/dashboard_nav_test.exs` - Improve ordering, aliases, command row, shortcut, active key, and non-stub coverage.
- `lib/scoria_web/router.ex` - `/datasets` dashboard route.
- `test/scoria_web/router_test.exs` - `/scoria/datasets` route coverage.

## Decisions Made

- Kept Dataset Builder index scope to listing and orientation only; URL-driven promotion drawer handling remains in Plan 14-02.
- Rendered the Action column as an internal same-LiveView patch target so the required column exists without inventing unbacked dataset management behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected router metadata assertion shape**
- **Found during:** Task 1 GREEN
- **Issue:** The RED router test expected a five-element `phoenix_live_view` tuple, but Phoenix 1.8 route metadata returns `{module, action, opts, live_session}`.
- **Fix:** Updated the assertion to match the actual Phoenix route metadata contract while preserving the `/scoria/datasets` route check.
- **Files modified:** `test/scoria_web/router_test.exs`
- **Verification:** `mix test test/scoria_web/dashboard_nav_test.exs test/scoria_web/router_test.exs` passed.
- **Committed in:** `8d84f0f`

---

**Total deviations:** 1 auto-fixed (Rule 1). **Impact on plan:** Test contract correction only; shipped behavior and scope are unchanged.

## Issues Encountered

- The fresh assigned worktree had locked Mix dependencies absent. `mix deps.get` fetched the existing lockfile dependencies successfully; no package names were changed or substituted.
- An initial patch attempt targeted the main checkout because the patch tool defaulted to the session cwd. The accidental test-only edits were removed immediately, and all committed plan work was applied under the assigned worktree path.

## Known Stubs

None. The new Dataset Builder page renders real Eval datasets and an honest empty state when no datasets exist.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/scoria_web/live/dataset_live/index_test.exs test/scoria_web/dashboard_nav_test.exs test/scoria_web/router_test.exs test/scoria_web/ds06_drift_guard_test.exs` - 20 tests, 0 failures.
- Source checks passed for `key: :datasets`, `label: "Dataset Builder"`, `path: "/datasets"`, `datasets: "g d"`, and `live("/datasets", ScoriaWeb.DatasetLive.Index, :index)`.
- Source checks passed for `defmodule ScoriaWeb.DatasetLive.Index`, `Eval.list_datasets`, `id="datasets"`, and zero raw-palette matches in the new LiveView.

## Self-Check: PASSED

- Created files exist: `lib/scoria_web/live/dataset_live/index.ex`, `test/scoria_web/live/dataset_live/index_test.exs`, and this summary.
- Commits exist: `d115166`, `8d84f0f`, `5c33fd2`, `eb4abfd`.
- `STATE.md` and `ROADMAP.md` were not modified in this manual worktree closeout.

## Next Phase Readiness

Plan 14-02 can add URL-driven promotion reconstruction and embed the existing Dataset promotion component inside Dataset Builder.

---
*Phase: 14-least-iterated-screens-polish*
*Completed: 2026-06-12*
