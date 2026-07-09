---
phase: 44-dashboard-auth-seam
plan: 04
subsystem: auth
tags: [phoenix-liveview, dashboard-scope, tenant-isolation, workflows]

requires:
  - phase: 44-dashboard-auth-seam
    provides: ScoriaWeb.DashboardScope assigns from Plan 44-01
provides:
  - Tenant-scoped workflow run index reads
  - Tenant-scoped workflow run detail reads
  - Tenant-scoped linked workflow evidence guards before subscriptions or hydration
affects: [dashboard-auth, workflow-live, operator-surface]

tech-stack:
  added: []
  patterns:
    - Dashboard LiveViews consume tenant from ScoriaWeb.DashboardScope assigns.
    - OperatorSurface owns tenant-qualified dashboard read helpers.

key-files:
  created:
    - test/scoria_web/live/dashboard_auth_workflows_test.exs
  modified:
    - lib/scoria_web/operator_surface.ex
    - lib/scoria_web/live/workflow_live/index.ex
    - lib/scoria_web/live/workflow_live/show.ex
    - test/scoria_web/live/workflow_live_test.exs

key-decisions:
  - "Workflow list and detail reads use ScoriaWeb.DashboardScope assigns instead of params, session fallbacks, or default tenant derivation."
  - "Workflow detail checks tenant visibility before runtime hydration, linked incident lookup, review candidate projection, remote evidence lookup, or PubSub subscription."
  - "Review candidate deep links are tenant-gated in OperatorSurface before calling the existing Eval projection, because the projected DTO does not expose tenant_id."

patterns-established:
  - "Tenant-scoped dashboard read helper: validate route IDs, prove tenant visibility with Repo query, then call broader context/detail builders."
  - "Foreign workflow detail renders not-found/unavailable copy instead of hydrating tenant-owned linked evidence."

requirements-completed: [AUTH-03]

duration: 11m26s
completed: 2026-07-07
status: complete
---

# Phase 44 Plan 04: Workflow Dashboard Auth Scope Summary

**Workflow dashboard list/detail tenant isolation using DashboardScope assigns and OperatorSurface tenant gates**

## Performance

- **Duration:** 11m26s
- **Started:** 2026-07-07T15:59:16Z
- **Completed:** 2026-07-07T16:10:42Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added cross-tenant workflow auth tests proving the index ignores tenant query hints and detail rejects foreign run IDs before linked evidence is hydrated.
- Added `OperatorSurface.list_tenant_runs/1`, `fetch_tenant_run_detail/2`, and `fetch_tenant_review_candidate/3` to centralize tenant-qualified workflow dashboard reads.
- Rewired workflow LiveViews to use `socket.assigns.tenant_id` from `ScoriaWeb.DashboardScope` and to subscribe only after tenant-visible run lookup succeeds.
- Refreshed existing workflow LiveView tests to seed explicit tenant IDs and mount with matching dashboard sessions.

## Task Commits

1. **Task 1: Prove workflow list and detail reject foreign tenant data** - `e0092c24` (test)
2. **Task 2: Add tenant-qualified workflow read helpers and wire LiveViews** - `94e9c402` (feat)
3. **Task 3: Refresh workflow tests for scoped dashboard sessions** - `39e24111` (test)

**Plan metadata:** pending

## Files Created/Modified

- `test/scoria_web/live/dashboard_auth_workflows_test.exs` - new cross-tenant workflow list/detail regression tests.
- `lib/scoria_web/operator_surface.ex` - tenant-scoped workflow list, detail, linked incident, and review candidate read helpers.
- `lib/scoria_web/live/workflow_live/index.ex` - workflow index now lists runs for the assigned dashboard tenant.
- `lib/scoria_web/live/workflow_live/show.ex` - workflow detail now validates tenant visibility before render, evidence hydration, async loads, and subscription.
- `test/scoria_web/live/workflow_live_test.exs` - existing workflow tests now create scoped runs and sessions.

## Decisions Made

- Workflow pages treat URL run IDs as selectors only; authorization is `{tenant_id, run_id}` through `OperatorSurface`.
- The workflow detail not-found state is the safe foreign-run response.
- Existing prompt catalog checks remain global metadata, but tenant-owned linked evidence is gated behind a visible run.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Security] Added tenant-scoped review candidate projection guard**
- **Found during:** Task 3 verification.
- **Issue:** `Eval.get_review_candidate/1` returns a projected DTO without `tenant_id`, so a strict tenant check in `WorkflowLive.Show` rejected valid same-tenant review candidate deep links.
- **Fix:** Added `OperatorSurface.fetch_tenant_review_candidate/3`, which checks the raw candidate row by tenant and workflow run before returning the existing projected DTO.
- **Files modified:** `lib/scoria_web/operator_surface.ex`, `lib/scoria_web/live/workflow_live/show.ex`
- **Verification:** Focused workflow tests and combined workflow auth tests pass with `--warnings-as-errors`.
- **Committed in:** `94e9c402`

---

**Total deviations:** 1 auto-fixed (Rule 2).
**Impact on plan:** The fix stayed inside planned files and strengthened the linked evidence tenant gate required by AUTH-03.

## Issues Encountered

- Task 2 source changes initially made existing workflow tests fail because those tests still mounted with empty sessions and tenantless runs. This was expected by Task 3 and resolved by refreshing the tests to use scoped sessions and tenant fixtures.

## Verification

- `MIX_ENV=test mix test test/scoria_web/live/dashboard_auth_workflows_test.exs --warnings-as-errors` - RED failed before implementation as expected.
- `MIX_ENV=test mix test test/scoria_web/live/dashboard_auth_workflows_test.exs test/scoria_web/live/workflow_live_test.exs --warnings-as-errors` - PASS, 21 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria_web/live/workflow_live_test.exs --warnings-as-errors` - PASS, 19 tests, 0 failures.
- `rg -n "list_tenant_runs|fetch_tenant_run_detail|fetch_tenant_review_candidate|socket\.assigns\.tenant_id" lib/scoria_web/operator_surface.ex lib/scoria_web/live/workflow_live/index.ex lib/scoria_web/live/workflow_live/show.ex` - found the tenant helper exports and assigned-scope LiveView call sites.

## Known Stubs

None. Stub scan found only intentional not-found/provenance fallback copy and empty-list comparisons.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

AUTH-03 workflow dashboard isolation is complete. Future dashboard routes should follow the same pattern: consume `ScoriaWeb.DashboardScope` assigns, query through `OperatorSurface`, and gate linked evidence after tenant-visible parent lookup.

## Self-Check: PASSED

- Created/modified files exist.
- Task commits found: `e0092c24`, `94e9c402`, `39e24111`.
- Plan-level focused verification passed: 21 tests, 0 failures.

---
*Phase: 44-dashboard-auth-seam*
*Completed: 2026-07-07*
