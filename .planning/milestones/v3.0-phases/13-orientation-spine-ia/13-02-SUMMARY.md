---
phase: 13-orientation-spine-ia
plan: "02"
subsystem: ui
tags: [phoenix-liveview, navigation, information-architecture, stubs]
requires:
  - phase: 13-orientation-spine-ia
    provides: IA component vocabulary from plan 13-01
provides:
  - DashboardNav groups for Operate, Improve, and Configure
  - Home relabel for the existing `/` route
  - Connectors placement under Configure only
  - five allowlisted coming-soon nav items with stub metadata
  - active-key coverage for WorkflowLive.Index and coming-soon stubs
affects: [sidebar, command-palette, coming-soon, status-home]
tech-stack:
  added: []
  patterns:
    - DashboardNav as shared IA source of truth
    - route-param aware active-key lookup
key-files:
  created:
    - test/scoria_web/dashboard_nav_test.exs
  modified:
    - lib/scoria_web/dashboard_nav.ex
    - lib/scoria_web/components/layouts/app.html.heex
    - assets/css/04-components.css
key-decisions:
  - "Stub slugs live once in DashboardNav metadata and paths are derived from that metadata."
  - "Home keeps the existing `:live_ops` key while presenting the user-facing label `Home`."
patterns-established:
  - "Sidebar, stubs, and later palette metadata should consume DashboardNav.groups/0."
  - "Coming-soon active state is derived from allowlisted `screen` params, not arbitrary labels."
requirements-completed: [IA-01, IA-06]
duration: 4 min
completed: 2026-06-12
---

# Phase 13 Plan 02: Dashboard Navigation SSOT Summary

**Three-group dashboard navigation with allowlisted Soon stubs and route-param aware active state**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-12T01:59:10Z
- **Completed:** 2026-06-12T02:02:08Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `test/scoria_web/dashboard_nav_test.exs` covering groups, stubs, aliases, duplicate nouns, and active keys.
- Reworked `ScoriaWeb.DashboardNav.groups/0` into the locked Operate / Improve / Configure model.
- Added stub helpers `stub_screens/0`, `stub_screen/1`, `stub_key_for_slug/1`, and route-param aware `active_key/2`.
- Added `ScoriaWeb.WorkflowLive.Index => :runs` and `/coming/:screen` suffix handling for embedded mount prefixes.
- Rendered visible `Soon` text badges for clickable stub nav items.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create DashboardNav unit coverage for groups, stubs, aliases, and active keys** - `23b0252` (test)
2. **Task 2: Implement grouped nav SSOT and sidebar Soon badges** - `9e0703d` (feat)

## Files Created/Modified

- `test/scoria_web/dashboard_nav_test.exs` - Unit coverage for the Phase 13 nav contract.
- `lib/scoria_web/dashboard_nav.ex` - Grouped nav metadata, aliases, stub helpers, and active-key lookup.
- `lib/scoria_web/components/layouts/app.html.heex` - Visible `Soon` badge rendering in sidebar links.
- `assets/css/04-components.css` - Token-bound `.scoria-nav__soon` styling.

## Decisions Made

- Kept the internal Home key as `:live_ops` for compatibility while changing the label to `Home`.
- Stored only `stub_slug` in nav metadata and derived `/coming/:screen` paths, keeping each slug literal single-sourced.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed. **Impact:** No scope change.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/scoria_web/dashboard_nav_test.exs test/scoria_web/ds06_drift_guard_test.exs` - 11 tests, 0 failures.
- Source spot-check: each of the five final stub slugs appears exactly once in `lib/scoria_web/dashboard_nav.ex`.

## Self-Check: PASSED

- Group labels are exactly Operate, Improve, Configure.
- Connectors appears once and only in Configure.
- Five reserved capabilities are clickable Soon nav items.
- `WorkflowLive.Index` activates Runs and coming-soon routes activate by allowlisted slug.

## Next Phase Readiness

Plan 13-03 can add the shared `/coming/:screen` LiveView against `DashboardNav.stub_screen/1`; plan 13-06 can derive command palette Navigate rows from the same nav groups.

---
*Phase: 13-orientation-spine-ia*
*Completed: 2026-06-12*
