---
phase: 13-orientation-spine-ia
plan: "04"
subsystem: ui
tags: [phoenix-liveview, status-home, information-architecture]
requires:
  - phase: 13-orientation-spine-ia
    provides: IA component primitives from plan 13-01
  - phase: 13-orientation-spine-ia
    provides: DashboardNav paths from plan 13-02
provides:
  - Status Home at the existing dashboard `/` route
  - async tenant-scoped Home summary counts
  - conditional attention cards for approvals, incidents, connector health, and flagged runs
  - day-zero trace stream empty state
affects: [home, orchestrator-live, operator-surface]
tech-stack:
  added: []
  patterns:
    - assign_async-backed read-only Home status summary
    - token-styled Status Home composition using IA primitives
key-files:
  created: []
  modified:
    - lib/scoria_web/live/orchestrator_live.ex
    - lib/scoria_web/operator_surface.ex
    - assets/css/04-components.css
    - test/scoria_web/live/orchestrator_live_test.exs
    - test/support/ds06_baseline.txt
key-decisions:
  - "Home stays mounted at the existing `/scoria` route and sets the page title to `Home`."
  - "Connector health uses cheap tenant-scoped aggregate counts instead of the heavier fleet row projection."
  - "The old vanity dashboard cards were removed; the trace stream remains the primary operational feed."
patterns-established:
  - "Status Home cards render only for nonzero actionable counts."
  - "Day-zero empty state copy is separate from the LiveView stream container, so `traces-list` remains stable."
requirements-completed: [IA-02]
duration: 8 min
completed: 2026-06-12
---

# Phase 13 Plan 04: Status Home Summary

**Existing dashboard root now orients operators with exact Home copy, actionable attention cards, and the live trace stream**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-12T02:09:00Z
- **Completed:** 2026-06-12T02:16:59Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added Status Home LiveView tests for exact title, identity sentence, all-clear copy, day-zero stream empty copy, attention-card CTAs, and stream preservation.
- Replaced the old `Live Ops` landing composition with `Home`, the locked identity line, async needs-attention strip, and a day-zero trace empty state.
- Added `OperatorSurface.status_home_summary/1` with tenant-scoped read-only counts for approvals, incidents, connectors, and review candidates.
- Added token-based CSS hooks for the Home identity line, attention strip, all-clear text, and trace empty copy.
- Tightened the DS-06 palette baseline for `orchestrator_live.ex` from 36 to 26 after removing old raw palette card markup.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Status Home LiveView tests** - `795374a` (test)
2. **Task 2: Implement Status Home summary and attention strip** - `9401b65` (feat)

## Files Created/Modified

- `lib/scoria_web/live/orchestrator_live.ex` - Status Home copy, async summary assignment, conditional attention cards, and day-zero trace empty state.
- `lib/scoria_web/operator_surface.ex` - Tenant-scoped Status Home read model.
- `assets/css/04-components.css` - Token-based Status Home CSS hooks.
- `test/scoria_web/live/orchestrator_live_test.exs` - Status Home and async summary coverage.
- `test/support/ds06_baseline.txt` - Lowered raw palette baseline for `orchestrator_live.ex`.

## Decisions Made

- Home remains at the existing dashboard root; no `/home` or `/live_ops` route was added.
- Connector health cards use direct aggregate counts because Home needs a cheap status signal, not full connector fleet rows.
- Review-candidate context remains available for deep links, but it now renders after the preserved trace stream so the top-of-page order stays title, identity, attention, stream.

## Deviations from Plan

- The connector count implementation uses a direct tenant-scoped aggregate helper instead of `fleet_summary/1` because the full fleet row projection was heavier than Home needs and masked connector health under LiveView async test conditions.

**Total deviations:** 1 intentional adjustment. **Impact:** Reduced query surface for Home while preserving the required connector-health attention card behavior.

## Issues Encountered

- DS-06 failed as expected after raw palette usage dropped in `orchestrator_live.ex`; the committed baseline was lowered to match the new count.
- Existing Orchestrator LiveView tests needed to wait for the new async status assignment after mount so the SQL sandbox owner does not close before the async read finishes.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/scoria_web/live/orchestrator_live_test.exs --max-failures 1` - failed before implementation on missing locked Home copy, as expected for the red step.
- `mix test test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/ds06_drift_guard_test.exs` - 15 tests, 0 failures.
- Source check: `rg -n '(/home|/live_ops)' lib/scoria_web/router.ex lib/scoria_web/live/orchestrator_live.ex || true` - no matches.

## Self-Check: PASSED

- `/scoria` remains the Home route; no new Home route strings were introduced.
- `OrchestratorLive` assigns page title `Home`.
- Exact identity, all-clear, and day-zero stream empty copy render.
- Attention cards render only for nonzero actionable counts.
- `id="traces-list"` remains present and streaming trace tests still pass.
- DS-06 passes with the lowered baseline.

## Next Phase Readiness

Command palette work can rely on Home as the stable first screen and use the same navigation nouns/CTA labels surfaced by the attention strip.

---
*Phase: 13-orientation-spine-ia*
*Completed: 2026-06-12*
