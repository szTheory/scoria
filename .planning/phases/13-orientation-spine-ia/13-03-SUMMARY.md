---
phase: 13-orientation-spine-ia
plan: "03"
subsystem: ui
tags: [phoenix-liveview, routing, stubs, information-architecture]
requires:
  - phase: 13-orientation-spine-ia
    provides: DashboardNav stub metadata from plan 13-02
  - phase: 13-orientation-spine-ia
    provides: stub_page/1 primitive from plan 13-01
provides:
  - shared `/coming/:screen` dashboard route
  - allowlisted ComingSoonLive for five reserved capabilities
  - unknown-slug fallback that does not echo user-controlled params
  - honest future-tense stub copy and What works today links
affects: [coming-soon, sidebar-stubs, command-palette-stubs]
tech-stack:
  added: []
  patterns:
    - shared LiveView stub route backed by DashboardNav allowlist
    - repository issue-search tracking URLs without fabricated issue numbers
key-files:
  created:
    - lib/scoria_web/live/coming_soon_live.ex
    - test/scoria_web/live/coming_soon_live_test.exs
  modified:
    - lib/scoria_web/router.ex
    - test/scoria_web/router_test.exs
key-decisions:
  - "ComingSoonLive looks up screen params through DashboardNav.stub_screen/1 and never titleizes unknown slugs."
  - "Tracking links use GitHub issue-search URLs instead of fabricated issue numbers."
patterns-established:
  - "Reserved-name IA entries route to one shared stub LiveView."
  - "Stub body copy stays future-tense and links only to real current dashboard surfaces."
requirements-completed: [IA-06]
duration: 3 min
completed: 2026-06-12
---

# Phase 13 Plan 03: Coming-Soon Route Summary

**Shared allowlisted LiveView for five reserved dashboard capabilities with honest future-tense stubs**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-12T02:02:55Z
- **Completed:** 2026-06-12T02:05:52Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added route coverage for `/scoria/coming/cost-ledger` in `router_test.exs`.
- Added `coming_soon_live_test.exs` covering all five final stub slugs, approved Cost Ledger / Replay Playground copy, forbidden fake data language, and unknown slug behavior.
- Mounted `live("/coming/:screen", ScoriaWeb.ComingSoonLive, :show)` inside the existing dashboard live session.
- Implemented `ComingSoonLive` using `DashboardNav.stub_screen/1` and `ScoriaWeb.UI.stub_page/1`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add route and LiveView tests for allowlisted stubs** - `76447ae` (test)
2. **Task 2: Implement shared ComingSoonLive from DashboardNav metadata** - `af24726` (feat)

## Files Created/Modified

- `lib/scoria_web/live/coming_soon_live.ex` - Shared allowlisted stub LiveView.
- `lib/scoria_web/router.ex` - Dashboard `/coming/:screen` route.
- `test/scoria_web/live/coming_soon_live_test.exs` - LiveView coverage for stubs and unknown slugs.
- `test/scoria_web/router_test.exs` - Route macro coverage for coming-soon path.

## Decisions Made

- Stub descriptions and current links are fixed by allowlisted slug, while labels and active state come from `DashboardNav`.
- Unknown slugs render a generic capability-not-found page and Home link without showing the raw slug.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed. **Impact:** No scope change.

## Issues Encountered

- The first test version checked forbidden stub words against the whole HTML document, which included bundled CSS. The assertion was narrowed to `<main>` so it verifies rendered stub body content.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/scoria_web/dashboard_nav_test.exs test/scoria_web/router_test.exs test/scoria_web/live/coming_soon_live_test.exs test/scoria_web/ds06_drift_guard_test.exs` - 17 tests, 0 failures.

## Self-Check: PASSED

- `/coming/:screen` route is present in the dashboard live session.
- `ComingSoonLive` calls `DashboardNav.stub_screen/1`.
- Dataset Builder is not in stub metadata or stub tests.
- Unknown slugs are deterministic and do not echo user-controlled labels.

## Next Phase Readiness

Status Home and command palette can link to the reserved capabilities as real clickable IA entries without claiming those backend capabilities exist.

---
*Phase: 13-orientation-spine-ia*
*Completed: 2026-06-12*
