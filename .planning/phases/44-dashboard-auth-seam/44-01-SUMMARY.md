---
phase: 44-dashboard-auth-seam
plan: 01
subsystem: auth
tags: [phoenix-liveview, dashboard-auth, tenant-scope, router, tdd]

# Dependency graph
requires:
  - phase: 43-knowledge-tenant-isolation
    provides: fail-closed explicit tenant scope normalization pattern
provides:
  - Host on_mount hook pass-through for scoria_dashboard/2
  - ScoriaWeb.DashboardScope resolver behavior, struct, and fail-closed LiveView gate
  - Router and scope tests proving AUTH-01/AUTH-02 seam behavior
affects: [phase-44, dashboard-liveviews, auth-seam, tenant-isolation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Phoenix live_session on_mount chain built from host hooks plus Scoria-owned hooks
    - LiveView on_mount gate normalizes host-asserted tenant scope before dashboard reads

key-files:
  created:
    - lib/scoria_web/dashboard_scope.ex
    - test/scoria_web/dashboard_scope_test.exs
  modified:
    - lib/scoria_web/router.ex
    - test/scoria_web/router_test.exs

key-decisions:
  - "scoria_dashboard/2 accepts only :on_mount and :scope_resolver for this seam; root_layout and Scoria hooks remain owned by Scoria."
  - "The default dashboard scope resolver reads host session/socket assigns and ignores query params as tenant authority."
  - "Custom resolver failures either fail closed with generic Scoria copy, redirect/halt under host control, or raise InvalidReturnError for malformed returns."

patterns-established:
  - "Hook chain: host on_mount hooks, then ScoriaWeb.DashboardScope, then ScoriaWeb.DashboardNav."
  - "Dashboard scope assigns: :scoria_scope and :tenant_id are always assigned on success; :actor_id and :session_id are assigned only when present."

requirements-completed: [AUTH-01, AUTH-02]

# Metrics
duration: 7 min
completed: 2026-07-07
status: complete
---

# Phase 44 Plan 01: Dashboard Auth Seam Summary

**Phoenix-native dashboard auth seam with host hook pass-through and fail-closed tenant scope resolution**

## Performance

- **Duration:** 7 min
- **Started:** 2026-07-07T14:56:42Z
- **Completed:** 2026-07-07T15:04:09Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- `scoria_dashboard/2` now preserves the bare `scoria_dashboard("/scoria")` form while accepting host `on_mount:` hooks.
- Host hooks run before `ScoriaWeb.DashboardScope`, and `ScoriaWeb.DashboardNav` remains last in the LiveView hook chain.
- Added `ScoriaWeb.DashboardScope` with a public resolver behavior, normalized scope struct, module/MFA resolver support, and fail-closed `on_mount/4`.
- Added focused router and scope tests proving query params are not tenant authority and generic failure copy is used for Scoria-owned failures.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Prove router macro compatibility and hook order** - `abf26e7e` (test)
2. **Task 2 RED: Add dashboard scope contract tests** - `e37bcf42` (test)
3. **Task 2 GREEN: Add fail-closed dashboard scope gate** - `8e38b557` (feat)
4. **Task 3 RED: Add scope_resolver router proof** - `f91c345a` (test)
5. **Task 3 GREEN: Wire scoria_dashboard/2 opts into fixed hook chain** - `1c15790b` (feat)

_Note: TDD tasks produced RED then GREEN commits. Task 1's RED router tests were made green by Task 3._

## Files Created/Modified

- `lib/scoria_web/router.ex` - `scoria_dashboard/2` now normalizes host hooks with `List.wrap/1`, accepts `:scope_resolver`, and builds the fixed Scoria hook chain.
- `lib/scoria_web/dashboard_scope.ex` - New dashboard scope struct, resolver behavior, normalization, resolver dispatch, and fail-closed LiveView mount gate.
- `test/scoria_web/router_test.exs` - Router macro compatibility tests for bare macro, host hook forms, hook order, resolver argument, root layout ownership, and invalid hook validation.
- `test/scoria_web/dashboard_scope_test.exs` - Scope normalization, resolver, fail-closed, redirect/halt, malformed return, copy, and query-param spoof tests.

## Decisions Made

- Kept router option handling narrow: only `:on_mount` and `:scope_resolver` are consumed; there is no broad `live_session_opts` pass-through.
- Used `:default` as the bare DashboardScope hook arg and `{ScoriaWeb.DashboardScope, resolver}` only for configured resolver forms.
- Treated missing default scope as a halted Scoria-owned unavailable state, while malformed custom resolver returns raise `ScoriaWeb.DashboardScope.InvalidReturnError`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None. The only "not available" text found in the touched files is the required generic auth/scope failure copy from the UI spec.

## Verification

- `MIX_ENV=test mix test test/scoria_web/router_test.exs --warnings-as-errors` - RED before router changes: failed on missing DashboardScope hook, ignored host hooks, and ignored invalid hook validation.
- `MIX_ENV=test mix test test/scoria_web/dashboard_scope_test.exs --warnings-as-errors` - RED before scope implementation: failed because `ScoriaWeb.DashboardScope` did not exist.
- `MIX_ENV=test mix test test/scoria_web/dashboard_scope_test.exs --warnings-as-errors` - PASS after Task 2 GREEN (10 tests, 0 failures).
- `MIX_ENV=test mix test test/scoria_web/router_test.exs test/scoria_web/dashboard_scope_test.exs --warnings-as-errors` - PASS after Task 3 GREEN (22 tests, 0 failures).
- `rg -n "ScoriaWeb\\.DashboardScope|scope_resolver|List\\.wrap|DashboardNav" lib/scoria_web/router.ex lib/scoria_web/dashboard_scope.ex test/scoria_web/router_test.exs test/scoria_web/dashboard_scope_test.exs` - PASS; required seam symbols present.

## TDD Gate Compliance

- RED gates present: `abf26e7e`, `e37bcf42`, `f91c345a`.
- GREEN gates present after RED: `8e38b557`, `1c15790b`.
- Refactor gate: not needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `44-02-PLAN.md` and downstream dashboard LiveView slices to consume `socket.assigns.scoria_scope` and `socket.assigns.tenant_id` instead of params/session/default tenant derivation.

## Self-Check: PASSED

- Verified created/modified files exist: `lib/scoria_web/router.ex`, `lib/scoria_web/dashboard_scope.ex`, `test/scoria_web/router_test.exs`, `test/scoria_web/dashboard_scope_test.exs`, and this summary.
- Verified task commits exist: `abf26e7e`, `e37bcf42`, `8e38b557`, `f91c345a`, and `1c15790b`.
- Verified SUMMARY frontmatter includes `status: complete` and `requirements-completed: [AUTH-01, AUTH-02]`.

---
*Phase: 44-dashboard-auth-seam*
*Completed: 2026-07-07*
