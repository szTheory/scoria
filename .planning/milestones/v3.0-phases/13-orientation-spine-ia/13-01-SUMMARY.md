---
phase: 13-orientation-spine-ia
plan: "01"
subsystem: ui
tags: [phoenix-liveview, design-system, ia, command-palette, stubs]
requires:
  - phase: 12-design-system-component-layer
    provides: token-gateway UI components and DS-06 raw-color guard
provides:
  - attention-card primitive for Status Home actionable states
  - object-header primitive for breadcrumbs, copyable IDs, status, provenance, and return context
  - honest stub-page primitive for reserved capabilities
  - accessible command-palette shell and keyboard shortcut chip
  - semantic IA CSS classes and opacity-only command palette motion
affects: [phase-13, phase-14, dashboard-navigation, status-home, object-pages]
tech-stack:
  added: []
  patterns:
    - Phoenix function components with semantic scoria-* CSS classes
    - token-bound IA component vocabulary
key-files:
  created: []
  modified:
    - lib/scoria_web/ui.ex
    - assets/css/04-components.css
    - assets/css/05-motion.css
    - test/scoria_web/ui_component_test.exs
key-decisions:
  - "Object IDs use the locked middle-truncation display grammar `prefix...suffix` while preserving the full ID in `title` and `data-copy`."
  - "The command palette is server-rendered as static dialog/listbox markup; client filtering remains a later JS hook responsibility."
patterns-established:
  - "IA primitives live in ScoriaWeb.UI and emit only semantic classes."
  - "Reserved capability stubs render future-tense copy, What works today links, and Track progress without fake data."
requirements-completed: [IA-02, IA-03, IA-04, IA-06]
duration: 4 min
completed: 2026-06-12
---

# Phase 13 Plan 01: IA Component Vocabulary Summary

**Shared Phoenix LiveView primitives for Status Home attention, object orientation, honest stubs, and command palette markup**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-12T01:55:00Z
- **Completed:** 2026-06-12T01:59:06Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added contract tests for `attention_card/1`, `object_header/1`, `stub_page/1`, `command_palette/1`, and `kbd/1`.
- Implemented the five IA primitives in `ScoriaWeb.UI`, including copyable object IDs and accessible command palette roles.
- Added token-bound semantic CSS for `.scoria-attention-card`, `.scoria-object-header`, `.scoria-stub`, `.scoria-command`, and `.scoria-kbd`.
- Added opacity-only command palette open/closed state motion in `assets/css/05-motion.css`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add component contract tests for Phase 13 IA primitives** - `9fd16ec` (test)
2. **Task 2: Implement IA primitives and semantic component CSS** - `eebebcb` (feat)

## Files Created/Modified

- `test/scoria_web/ui_component_test.exs` - Component contracts for the new IA vocabulary.
- `lib/scoria_web/ui.ex` - New attention card, object header, stub page, command palette, and shortcut chip components.
- `assets/css/04-components.css` - Token-bound component classes for IA surfaces.
- `assets/css/05-motion.css` - Opacity-only command palette state transition.

## Decisions Made

- Object ID display uses `trc_01J8...QK4` style middle truncation while preserving full ID in `title` and `data-copy`.
- The command palette component renders static DOM sections and rows; no LiveComponent or socket filtering is introduced.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed. **Impact:** No scope change.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/scoria_web/ui_component_test.exs test/scoria_web/ds06_drift_guard_test.exs` - 58 tests, 0 failures.

## Self-Check: PASSED

- Required components exist in `lib/scoria_web/ui.ex`.
- Required semantic CSS selectors exist in `assets/css/04-components.css`.
- Command palette motion is opacity-only for `.scoria-command`.
- DS-06 raw-color drift guard passed.

## Next Phase Readiness

Plan 13-02 can consume these primitives indirectly through nav and palette metadata. Later object-page, stub, and Status Home plans can use `object_header/1`, `stub_page/1`, and `attention_card/1` without one-off markup.

---
*Phase: 13-orientation-spine-ia*
*Completed: 2026-06-12*
