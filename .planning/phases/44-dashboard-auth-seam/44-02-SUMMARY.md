---
phase: 44-dashboard-auth-seam
plan: 02
subsystem: auth
tags: [phoenix-liveview, dashboard-scope, tenant-isolation, authz, tdd]

requires:
  - phase: 44-01
    provides: ScoriaWeb.DashboardScope assigns tenant_id before routed dashboard LiveViews mount
  - phase: 44-05
    provides: Scoria.Eval.get_review_candidate_for_tenant/2 for tenant-scoped review candidate lookup
provides:
  - Home, Connectors, and Incidents consume DashboardScope tenant assigns instead of public tenant hints
  - Cross-tenant spoof tests for Home trace hydration, Connectors fleet/runtime presence, and Incidents list/detail
  - Existing Home/Connectors/Incidents harnesses exercise explicit host-session dashboard scope
affects: [dashboard-auth-seam, home-dashboard, connectors-dashboard, incidents-dashboard, eval-review-candidates]

tech-stack:
  added: []
  patterns:
    - Phoenix LiveView mounts derive tenant authority from socket.assigns.tenant_id
    - Public params remain selectors only after tenant-scoped lookup

key-files:
  created:
    - test/scoria_web/live/dashboard_auth_home_connectors_incidents_test.exs
  modified:
    - lib/scoria_web/live/orchestrator_live.ex
    - lib/scoria_web/live/connectors_live/index.ex
    - lib/scoria_web/live/incidents_live/index.ex
    - lib/scoria_web/live/incidents_live/show.ex
    - test/scoria_web/live/orchestrator_live_test.exs
    - test/scoria_web/live/dashboard_auth_home_connectors_incidents_test.exs

key-decisions:
  - "Home, Connectors, and Incidents now consume ScoriaWeb.DashboardScope tenant assigns before tenant-owned reads or PubSub subscriptions."
  - "OrchestratorLive review_candidate_id deep links use Scoria.Eval.get_review_candidate_for_tenant/2 so foreign candidates resolve to nil under the asserted tenant."
  - "Existing page harnesses now provide explicit tenant session scope instead of relying on query params or a hardcoded default tenant."

patterns-established:
  - "Dashboard LiveView tenant authority: use socket.assigns.tenant_id; treat URL tenant values as non-authoritative hints."
  - "Tenant-owned object deep links: accept object IDs from params only through tenant-qualified read APIs."

requirements-completed: [AUTH-03]

duration: 9min
completed: 2026-07-07
status: complete
---

# Phase 44 Plan 02: Dashboard Auth Seam Summary

**Home, Connectors, and Incidents now use DashboardScope tenant authority, with spoof-shaped tests proving URL tenant hints cannot switch tenant data.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-07-07T16:49:15Z
- **Completed:** 2026-07-07T16:57:45Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added a routed LiveView spoof test module using the real `scoria_dashboard("/scoria")` macro.
- Replaced local tenant derivation in Home, Connectors, Incidents index, and Incidents show with `socket.assigns.tenant_id`.
- Switched OrchestratorLive review-candidate deep links to `Scoria.Eval.get_review_candidate_for_tenant/2`.
- Refreshed OrchestratorLive's existing harness to mount with explicit session tenant scope.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add cross-tenant spoof tests for Home, Connectors, and Incidents** - `04765113` (test)
2. **Task 2: Replace local tenant derivation with assigned scope** - `fe163157` (feat)
3. **Task 3: Refresh existing page harnesses for host-asserted scope** - `265659ed` (test)

**Plan metadata:** pending final docs commit

## Files Created/Modified

- `test/scoria_web/live/dashboard_auth_home_connectors_incidents_test.exs` - New cross-tenant spoof regression tests for Home, Connectors, Incidents, and missing dashboard scope.
- `lib/scoria_web/live/orchestrator_live.ex` - Home mount now reads `socket.assigns.tenant_id`; review candidates use tenant-scoped lookup.
- `lib/scoria_web/live/connectors_live/index.ex` - Connectors mount now uses assigned tenant scope for runtime subscriptions and data reads.
- `lib/scoria_web/live/incidents_live/index.ex` - Incidents index now uses assigned tenant scope for list and run-origin lookup behavior.
- `lib/scoria_web/live/incidents_live/show.ex` - Incident detail now relies on assigned tenant scope before tenant-qualified incident lookup.
- `test/scoria_web/live/orchestrator_live_test.exs` - Existing tests now mount with explicit tenant sessions.

## Decisions Made

- Tenant authority for these LiveViews is exclusively `ScoriaWeb.DashboardScope` via `socket.assigns.tenant_id`.
- URL params such as `runtime`, `from`, `review_candidate_id`, and object IDs remain selectors only; they do not define tenant authority.
- Existing Connectors and Incidents harnesses already used explicit sessions, so only OrchestratorLive needed broad harness refresh.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Loaded the Connectors module in the focused spoof test setup**
- **Found during:** Task 2 verification
- **Issue:** The narrow focused test process could reach `OperatorSurface.connector_fleet/1` before `Scoria.Connectors` was loaded, making `function_exported?/3` take the fallback path and hiding seeded connector rows.
- **Fix:** Added `Code.ensure_loaded!(Scoria.Connectors)` in the new focused test setup.
- **Files modified:** `test/scoria_web/live/dashboard_auth_home_connectors_incidents_test.exs`
- **Verification:** `MIX_ENV=test mix test test/scoria_web/live/dashboard_auth_home_connectors_incidents_test.exs --warnings-as-errors` passed with 4 tests, 0 failures.
- **Committed in:** `fe163157`

---

**Total deviations:** 1 auto-fixed blocking test harness issue.
**Impact on plan:** No product scope expansion; the fix made the planned tenant-isolation test observe the intended connector read path.

## Issues Encountered

- The RED test pass failed as intended before production cleanup: 4 tests, 3 failures covering Home, Connectors, and Incidents cross-tenant spoof paths.
- Before Task 3, the focused page set failed only in the existing OrchestratorLive harness because it still mounted with empty sessions or query-param tenant authority. Task 3 updated that harness.

## Verification

- `MIX_ENV=test mix test test/scoria_web/live/dashboard_auth_home_connectors_incidents_test.exs --warnings-as-errors`
  - RED before production change: 4 tests, 3 expected failures.
  - GREEN after Task 2: 4 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_test.exs --warnings-as-errors`
  - After Task 3: 12 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria_web/live/dashboard_auth_home_connectors_incidents_test.exs test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/live/connectors_live_test.exs test/scoria_web/live/incidents_live_test.exs --warnings-as-errors`
  - Plan-level verification: 31 tests, 0 failures.
- `rg -n "params\\[\\\"tenant\\\"\\]|session\\[\\\"tenant_id\\\"\\]|\\|\\| \\\"default\\\"" ...`
  - No matches in the scoped LiveViews or refreshed focused test files.
- `rg -n "socket.assigns.tenant_id|get_review_candidate_for_tenant|tenant_id = socket.assigns.tenant_id|This Scoria dashboard is not available for this session" ...`
  - Confirmed assigned-tenant usage in all four LiveViews and tenant-scoped review-candidate lookup in OrchestratorLive.

## Known Stubs

None. The stub scan found only intentional empty-state, not-found, and control-flow patterns already used by these pages.

## Threat Flags

None. This plan did not add new endpoints, schemas, or trust boundaries; it tightened tenant authority at existing LiveView mount and read boundaries.

## Auth Gates

None.

## User Setup Required

None.

## Next Phase Readiness

AUTH-03 coverage for Home, Connectors, and Incidents is complete. Remaining Phase 44 work can consume the same `DashboardScope` assign pattern without relying on public tenant hints.

## Self-Check: PASSED

- Verified summary and changed code/test files exist.
- Verified task commits exist: `04765113`, `fe163157`, `265659ed`.

---
*Phase: 44-dashboard-auth-seam*
*Completed: 2026-07-07*
