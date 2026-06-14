---
phase: 13-orientation-spine-ia
plan: "06"
subsystem: ui
tags: [phoenix-liveview, command-palette, keyboard-navigation, e2e]
requires:
  - phase: 13-orientation-spine-ia
    provides: IA component primitives from plan 13-01
  - phase: 13-orientation-spine-ia
    provides: Dashboard nav SSOT from plan 13-02
  - phase: 13-orientation-spine-ia
    provides: Object recents metadata from plan 13-05
provides:
  - dashboard-scoped command palette
  - local browser filtering with no socket traffic
  - keyboard shortcuts overlay and g-chord navigation
  - browser-local recent object tracking
  - Playwright e2e gate for command palette UAT
affects: [dashboard-layout, dashboard-nav, object-header, browser-e2e]
tech-stack:
  added: []
  patterns:
    - server-rendered command metadata consumed by vanilla JS hook
    - localStorage key scoped by dashboard mount base
    - Playwright spec as replacement for manual browser checkpoint
key-files:
  created:
    - priv/dev/e2e/command_palette.spec.mjs
  modified:
    - lib/scoria_web/dashboard_nav.ex
    - lib/scoria_web/components/layouts/app.html.heex
    - lib/scoria_web/components/layouts.ex
    - lib/scoria_web/ui.ex
    - assets/js/scoria.js
    - assets/css/04-components.css
    - test/scoria_web/dashboard_nav_test.exs
    - test/scoria_web/live/orchestrator_live_test.exs
    - priv/dev/e2e/uat.spec.mjs
    - priv/static/scoria/app.css
    - priv/static/scoria/app.js
key-decisions:
  - "Command metadata is derived from `DashboardNav.groups/0` so palette navigation stays aligned with the sidebar."
  - "Filtering and recents remain browser-local; typing does not call LiveView events or introduce new dependencies."
  - "The former manual browser checkpoint is now `priv/dev/e2e/command_palette.spec.mjs`, automatically covered by the existing CI e2e job."
patterns-established:
  - "`Hooks.CommandPalette` owns Ctrl/Cmd+K, `?`, Escape, Tab trap, Arrow navigation, Enter activation, and g-chords."
  - "`Hooks.RecordRecentObject` stores only visible object metadata under `scoria:recents:<mount-base>` and caps rows at 8."
  - "Browser-only interaction requirements should be captured in `priv/dev/e2e/*.spec.mjs` so `mix scoria.ui.e2e` remains the UAT gate."
requirements-completed: [IA-04, IA-06]
duration: 45 min
completed: 2026-06-12
---

# Phase 13 Plan 06: Command Palette and Shortcuts

**Dashboard navigation is now keyboard-first and covered by recurring browser automation**

## Performance

- **Duration:** 45 min
- **Started:** 2026-06-12T13:42:00Z
- **Completed:** 2026-06-12T14:26:35Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- Added `DashboardNav.command_sections/1` as the server-rendered command metadata source for Navigate and Actions rows.
- Added the dashboard command palette, topbar opener, shortcut overlay, kbd hints, and local palette rows to the shared app layout.
- Implemented `Hooks.CommandPalette` for Ctrl/Cmd+K open, local filtering, Arrow/Enter activation, Escape close, focus trap/restoration, `?` shortcut overlay, and g-chord navigation.
- Implemented `Hooks.RecordRecentObject` and connected shared object headers to browser-local recent-object storage.
- Added server-rendered LiveView tests for palette metadata and markup.
- Added `priv/dev/e2e/command_palette.spec.mjs` to automate the former human UAT lane.
- Confirmed CI already runs `mix scoria.ui.e2e`; no workflow edit was needed for recurring value.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add command palette contracts** - `0328085` (test)
2. **Task 2: Add dashboard command palette** - `6c3772b` (feat)
3. **Task 3: Automate command palette browser checkpoint** - `b3fe315` (test)

## Files Created/Modified

- `priv/dev/e2e/command_palette.spec.mjs` - Browser coverage for Ctrl+K, local filtering, focus trap, shortcut overlay, g-chords, and recents.
- `lib/scoria_web/dashboard_nav.ex` - Command metadata helpers derived from the nav SSOT.
- `lib/scoria_web/components/layouts/app.html.heex` - Palette dialog, topbar opener, and shortcut overlay.
- `lib/scoria_web/components/layouts.ex` - Command data helper for the dashboard layout.
- `lib/scoria_web/ui.ex` - Stable object-header id so the recent-object hook mounts reliably.
- `assets/js/scoria.js` - Command palette and recent-object vanilla hooks.
- `assets/css/04-components.css` - Hidden-state fixes for palette and filtered rows.
- `test/scoria_web/dashboard_nav_test.exs` - Command metadata assertions.
- `test/scoria_web/live/orchestrator_live_test.exs` - Server-rendered palette and shortcut overlay assertions.
- `priv/dev/e2e/uat.spec.mjs` - Updated existing skeleton e2e assertion to the shared object header.
- `priv/static/scoria/app.css` and `priv/static/scoria/app.js` - Rebuilt tracked dashboard bundles.

## Decisions Made

- Actions are limited to `Toggle theme`, `Keyboard shortcuts`, and `Copy current page URL`; destructive operations remain out of palette scope.
- Recents store visible object kind, id, label, and path only; there is no backend persistence.
- The e2e lane is the verification source for browser-only behavior, so Phase 13 no longer blocks on human UAT for this plan.

## Deviations from Plan

- The original plan had a blocking human browser checkpoint. Per product direction, that checkpoint was converted into Playwright automation and wired into the existing e2e task.

**Total deviations:** 1 verification-mode change. **Impact:** Better repeatability; no manual verification required.

## Issues Encountered

- Browser automation exposed that component CSS overrode native `[hidden]` behavior for the palette and filtered rows. Explicit hidden selectors now preserve visibility semantics.
- `RecordRecentObject` did not mount until shared object headers had a stable DOM id, which LiveView hooks require.
- The existing skeleton e2e spec still looked for the pre-13-05 `Workflow Run` heading. It now asserts the shared object header instead.

## User Setup Required

None - no external service configuration required.

## Verification

- JS syntax: `node --check assets/js/scoria.js && node --check priv/dev/e2e/command_palette.spec.mjs` - passed.
- Asset build: `mix scoria.assets.build` - passed.
- Focused browser pass: `PLAYWRIGHT_BASE_URL=http://localhost:4001/scoria npx playwright test --config e2e/playwright.config.mjs e2e/command_palette.spec.mjs` - 4 passed.
- Full browser pass: `mix scoria.ui.e2e --base-url http://localhost:4001/scoria` - 8 passed, 3 skipped.
- Web suite: `mix test test/scoria_web/ --max-failures 1` - 159 tests, 0 failures.

## Self-Check: PASSED

- Command palette opens with Ctrl/Cmd+K and focuses the search input.
- Local filtering hides unrelated rows without socket traffic.
- Escape closes palette/overlay and restores focus.
- Shortcut overlay traps focus and ignores editable targets.
- G-chords navigate to the locked dashboard destinations.
- Recents use `scoria:recents:/scoria`, show 5 rows, and store at most 8.
- Existing CI e2e job already picks up the new spec through `mix scoria.ui.e2e`.
- No new JS package dependency was added.

## Next Phase Readiness

Phase 13 can proceed to Plan 07 with keyboard navigation and recents now covered by recurring automated browser verification instead of a manual UAT checkpoint.

---
*Phase: 13-orientation-spine-ia*
*Completed: 2026-06-12*
