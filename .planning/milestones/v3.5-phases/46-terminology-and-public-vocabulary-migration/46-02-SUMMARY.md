---
phase: 46-terminology-and-public-vocabulary-migration
plan: 02
subsystem: web
tags: [terminology, reviewer-surface, dashboard, compatibility, tenant-authority]

requires: []
provides:
  - ScoriaWeb.ReviewerSurface final-vocabulary dashboard read model
  - ScoriaWeb.OperatorSurface 0.1.x compatibility wrapper
  - Dashboard LiveView aliases migrated to reviewer read-model vocabulary
  - Tenant-authority regression tests for reviewer read-model calls
affects: [phase-46, dashboard, workflows, incidents, connectors, dataset]

tech-stack:
  added: []
  patterns:
    - Public compatibility wrapper delegates to final-vocabulary module
    - Dashboard read models preserve session-owned tenant authority

key-files:
  created:
    - lib/scoria_web/reviewer_surface.ex
    - test/scoria_web/reviewer_surface_test.exs
  modified:
    - lib/scoria_web/operator_surface.ex
    - lib/scoria_web/live/orchestrator_live.ex
    - lib/scoria_web/live/workflow_live/index.ex
    - lib/scoria_web/live/workflow_live/show.ex
    - lib/scoria_web/live/connectors_live/index.ex
    - lib/scoria_web/live/incidents_live/index.ex
    - lib/scoria_web/live/incidents_live/show.ex
    - lib/scoria_web/live/dataset_live/index.ex

key-decisions:
  - "ReviewerSurface now owns the dashboard read-model implementation while OperatorSurface remains a delegate-only 0.1.x compatibility wrapper."
  - "LiveView call sites use reviewer vocabulary without changing route or query parameter semantics."
  - "Tenant authority remains scoped to DashboardScope assigns; URL tenant values continue to act as selectors only."

patterns-established:
  - "Final-vocabulary web modules should own behavior while legacy modules delegate without duplicating queries."
  - "Terminology migrations across dashboard code should be paired with tenant-spoof regression coverage."

requirements-completed: [TERM-02, TERM-04]

duration: 6 min
completed: 2026-07-09
status: complete
---

# Phase 46 Plan 02: Reviewer Surface Summary

**The dashboard read model now leads with reviewer vocabulary while the 0.1.x operator module name remains compatible.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-09T22:10:00Z
- **Completed:** 2026-07-09T22:16:00Z
- **Tasks:** 1
- **Files modified:** 10

## Accomplishments

- Added `ScoriaWeb.ReviewerSurface` as the canonical reviewer dashboard read model.
- Converted `ScoriaWeb.OperatorSurface` into a delegate-only compatibility wrapper with no independent Ecto query or Repo implementation.
- Updated dashboard LiveViews for Live Ops, workflows, connectors, incidents, and dataset promotion context to alias `ReviewerSurface`.
- Added `ScoriaWeb.ReviewerSurfaceTest` to prove behavior parity across the new and legacy module names and preserve tenant-scoped object access.
- Re-ran dashboard scope and tenant-spoof regression tests covering host-owned tenant authority.

## Task Commits

1. **Task 1 RED: Reviewer surface contract** - `cf61fa09` (test)
2. **Task 1 GREEN: Reviewer surface compatibility alias** - `5c7d8393` (feat)

## Files Created/Modified

- `lib/scoria_web/reviewer_surface.ex` - Canonical reviewer dashboard read-model implementation.
- `lib/scoria_web/operator_surface.ex` - Legacy compatibility wrapper delegating to `ReviewerSurface`.
- `lib/scoria_web/live/orchestrator_live.ex` - Live Ops status and trace badges now call `ReviewerSurface`.
- `lib/scoria_web/live/workflow_live/index.ex` - Workflow list now calls `ReviewerSurface`.
- `lib/scoria_web/live/workflow_live/show.ex` - Workflow detail and review candidate lookups now call `ReviewerSurface`.
- `lib/scoria_web/live/connectors_live/index.ex` - Connector fleet and drawer reads now call `ReviewerSurface`.
- `lib/scoria_web/live/incidents_live/index.ex` - Incident list and legacy run-origin lookup now call `ReviewerSurface`.
- `lib/scoria_web/live/incidents_live/show.ex` - Incident detail and evidence projection now call `ReviewerSurface`.
- `lib/scoria_web/live/dataset_live/index.ex` - Dataset promotion workflow context now calls `ReviewerSurface`.
- `test/scoria_web/reviewer_surface_test.exs` - ReviewerSurface parity, wrapper, call-site, and tenant-authority tests.

## Decisions Made

- Kept public function names and return shapes unchanged so route handlers and legacy callers do not need behavior changes.
- Used explicit `defdelegate` wrappers in `OperatorSurface` to make compatibility obvious and keep query logic in one module.
- Left dashboard URL/query tenant handling unchanged; Phase 44 DashboardScope authority remains the source of truth.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- Initial RED test normalization referenced an outdated run-detail shape; the assertion now uses `detail.summary.run_id`, matching the existing runtime projection.

## Verification

- `MIX_ENV=test mix test --warnings-as-errors test/scoria_web/reviewer_surface_test.exs` - PASS, 5 tests, 0 failures.
- `MIX_ENV=test LOG_LEVEL=warning mix test --warnings-as-errors test/scoria_web/reviewer_surface_test.exs test/scoria_web/dashboard_scope_source_guard_test.exs test/scoria_web/live/dashboard_auth_home_connectors_incidents_test.exs test/scoria_web/live/dashboard_auth_workflows_test.exs` - PASS, 17 tests, 0 failures.
- `rg -n "defmodule ScoriaWeb\\.ReviewerSurface" lib/scoria_web/reviewer_surface.ex` - PASS.
- `rg -n "OperatorSurface" lib/scoria_web/live/orchestrator_live.ex lib/scoria_web/live/workflow_live/index.ex lib/scoria_web/live/workflow_live/show.ex lib/scoria_web/live/connectors_live/index.ex lib/scoria_web/live/incidents_live/index.ex lib/scoria_web/live/incidents_live/show.ex lib/scoria_web/live/dataset_live/index.ex` - PASS, no matches.
- `rg -n "import Ecto\\.Query|alias Scoria\\.Repo" lib/scoria_web/operator_surface.ex` - PASS, no matches.
- `rg -n "defdelegate" lib/scoria_web/operator_surface.ex` - PASS.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `46-03-PLAN.md` to migrate public package and adopter surface vocabulary with `ReviewerSurface` and earlier compatibility aliases available.

## Self-Check: PASSED

- Verified `ScoriaWeb.ReviewerSurface` exists and owns the read-model implementation.
- Verified `ScoriaWeb.OperatorSurface` delegates to the new canonical module.
- Verified all listed dashboard LiveViews use `ReviewerSurface`.
- Verified task commits exist: `cf61fa09` and `5c7d8393`.
- Verified focused plan tests pass with warnings as errors.

---
*Phase: 46-terminology-and-public-vocabulary-migration*
*Completed: 2026-07-09*
