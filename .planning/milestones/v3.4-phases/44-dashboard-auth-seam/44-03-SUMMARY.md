---
phase: 44-dashboard-auth-seam
plan: 03
subsystem: auth
tags: [phoenix-liveview, dashboard-auth, approvals, tenant-scope, tdd]

requires:
  - phase: 44-dashboard-auth-seam
    provides: ScoriaWeb.DashboardScope resolver and LiveView assigns from 44-01
provides:
  - Tenant-scoped approvals reads and actions consuming DashboardScope assigns
  - Cross-tenant approvals spoof regression coverage
  - Existing approvals tests refreshed for explicit dashboard scope
affects: [phase-44, dashboard-liveviews, approvals, auth-seam, tenant-isolation]

tech-stack:
  added: []
  patterns:
    - Dashboard LiveViews consume socket.assigns.tenant_id/scoria_scope instead of params, session, or default tenant fallbacks.
    - Approval decision audit attrs source tenant and actor from asserted dashboard scope.

key-files:
  created:
    - test/scoria_web/live/dashboard_auth_approvals_test.exs
  modified:
    - lib/scoria_web/live/approvals_live/index.ex
    - test/scoria_web/live/approvals_live_test.exs
    - test/scoria_web/live/approvals_live_integration_test.exs

key-decisions:
  - "ApprovalsLive treats URL tenant/query values as UI hints only; tenant authority comes from DashboardScope assigns."
  - "Approval decision context uses assigned dashboard tenant and actor; no approval-lineage or hardcoded default tenant fallback remains."

patterns-established:
  - "Approvals tests mount through session-backed DashboardScope defaults with explicit tenant and actor values."

requirements-completed: [AUTH-03]
duration: 8m 35s
completed: 2026-07-07
status: complete
---

# Phase 44 Plan 03: Approvals Dashboard Auth Scope Summary

**Approvals dashboard reads, deep links, PubSub filtering, and decision audit context now consume host-asserted DashboardScope tenant data.**

## Performance

- **Duration:** 8m 35s
- **Started:** 2026-07-07T15:12:51Z
- **Completed:** 2026-07-07T15:21:26Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added dashboard-auth regression tests proving tenant query hints cannot switch pending, decided, or deep-linked approvals.
- Routed `ScoriaWeb.ApprovalsLive.Index` through `socket.assigns.tenant_id` and dashboard actor scope for inbox loads, decided filters, selected approval guards, PubSub actions, and decision audit attrs.
- Refreshed existing approvals LiveView and integration helpers so legacy coverage mounts with explicit tenant and actor scope.

## Task Commits

Each task was committed atomically:

1. **Task 1: Write failing dashboard-auth seam tests for approvals spoof paths** - `c45077ad` (test)
2. **Task 2: Consume DashboardScope assigns in ApprovalsLive** - `28030615` (feat)
3. **Task 3: Refresh existing approvals tests around explicit scope** - `d0f8c7b9` (test)

## Files Created/Modified

- `test/scoria_web/live/dashboard_auth_approvals_test.exs` - New regression coverage for tenant-spoofed pending/decided/deep-link URLs, scoped decision audit attrs, and missing dashboard scope failure behavior.
- `lib/scoria_web/live/approvals_live/index.ex` - Approvals LiveView now reads tenant and actor context from dashboard socket assigns instead of URL/session/default fallbacks.
- `test/scoria_web/live/approvals_live_test.exs` - Existing helper defaults now provide explicit tenant and actor session scope.
- `test/scoria_web/live/approvals_live_integration_test.exs` - Integration helper now accepts an explicit actor while preserving existing default behavior.

## Decisions Made

- URL tenant/query values are treated as untrusted navigation hints; the dashboard mount scope remains the only authority for tenant selection.
- Decision audit metadata now records the dashboard actor when assigned and falls back only to `scoria_scope.actor_id` for compatibility with the 44-01 scope shape.

## Verification

- **RED gate:** `MIX_ENV=test mix test test/scoria_web/live/dashboard_auth_approvals_test.exs --warnings-as-errors` produced expected failures before implementation (`3 tests, 2 failures`) for tenant-spoofed approvals behavior.
- **Task 2 focused pass:** `MIX_ENV=test mix test test/scoria_web/live/dashboard_auth_approvals_test.exs test/scoria_web/live/approvals_live_test.exs test/scoria_web/live/approvals_live_integration_test.exs --warnings-as-errors` passed (`43 tests, 0 failures`).
- **Task 3 focused pass:** Same focused command passed after refreshing legacy helpers (`43 tests, 0 failures`).
- **Plan-level pass:** Same focused command passed after all commits (`43 tests, 0 failures`).
- **Formatting:** `mix format --check-formatted lib/scoria_web/live/approvals_live/index.ex test/scoria_web/live/dashboard_auth_approvals_test.exs test/scoria_web/live/approvals_live_test.exs test/scoria_web/live/approvals_live_integration_test.exs` passed.
- **Removed fallback scan:** `rg -n 'params\["tenant"\]|session\["tenant_id"\]|\|\| "default"|session\["actor_id"\]|\|\| "operator"' lib/scoria_web/live/approvals_live/index.ex` returned no matches.
- **Dashboard scope scan:** `rg -n 'socket\.assigns\.tenant_id|socket\.assigns\.actor_id|scoria_scope' lib/scoria_web/live/approvals_live/index.ex` found the expected tenant and actor scope reads.

## TDD Gate Compliance

- RED commit present: `c45077ad` (`test(44-03): add failing approvals auth scope tests`)
- GREEN commit present after RED: `28030615` (`feat(44-03): route approvals through dashboard scope`)
- Follow-up test refresh commit present: `d0f8c7b9` (`test(44-03): refresh approvals tests for dashboard scope`)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The focused test command emits verbose Ecto/Phoenix debug output, but ExUnit completed successfully.

## Known Stubs

None. Stub scan only found an intentional auth-failure assertion in the new regression test and ordinary nil/empty guards in the LiveView.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The approvals dashboard now follows the Phase 44 dashboard auth seam pattern. Future dashboard LiveViews should use the same rule: tenant authority comes from `ScoriaWeb.DashboardScope` assigns, not query params, sessions, or hardcoded defaults.

## Self-Check: PASSED

- Verified all four created/modified plan files exist.
- Verified task commits `c45077ad`, `28030615`, and `d0f8c7b9` exist in git history.
- Verified `.planning/phases/44-dashboard-auth-seam/44-03-SUMMARY.md` exists on disk.

---
*Phase: 44-dashboard-auth-seam*
*Completed: 2026-07-07*
