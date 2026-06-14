---
phase: 12-design-system-component-layer
plan: "01"
subsystem: ui
tags: [css, design-system, elixir, exunit, phoenix-liveview]

# Dependency graph
requires: []
provides:
  - CSS classes for all Phase 12 components (flash, skeleton, toast, notebook, table density, modal/drawer header/footer, field, form-section)
  - scoria-skeleton-pulse keyframe in 05-motion.css (covered by existing prefers-reduced-motion block)
  - DS-06 ratchet drift-guard test module (ds06_drift_guard_test.exs) with palette regex, .heex coverage, @excluded list, and ui.ex-zero assertion
  - ui_component_test.exs scaffold with shared test header for plans 12-02/03/04 to extend
affects: [12-02, 12-03, 12-04, 12-05, 14-least-iterated-screens, 15-high-traffic-screens]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "DS-06 ratchet guard: File.exists? guard around baseline comparison (vacuous pass until plan 12-05 commits baseline); unconditional ui.ex-zero assertion tagged :ui_ex_zero"
    - "CSS: tone modifier triplet pattern (color/background/border-color via --scoria-tone-{tone}-{fg,bg,border}) extended to flash and toast"
    - "CSS: scoria-toast-region as fixed stacking container with pointer-events passthrough"

key-files:
  created:
    - test/scoria_web/ds06_drift_guard_test.exs
    - test/scoria_web/ui_component_test.exs
  modified:
    - assets/css/04-components.css
    - assets/css/05-motion.css

key-decisions:
  - "DS-06 ratchet uses File.exists? guard so mix test is green before plan 12-05 commits the baseline (no @tag :pending or ExUnit.configure hack needed)"
  - "ui.ex-zero assertion tagged :ui_ex_zero and excluded from plan 12-01 verify — plan 12-02 sweeps flash_tone_class/1; tag is dropped in 12-05 when full guard goes green"
  - "scoria-toast-region uses pointer-events: none on container + auto on children, allowing clicks to pass through the stacking region to elements below"

patterns-established:
  - "DS-06 guard pattern: Path.wildcard with brace expansion {ex,heex}, Regex.scan count per file, @excluded list for files zeroed in Phase 12"
  - "CSS tone modifier pattern: three-property triplet (color/background/border-color) applied to flash and toast, matching existing badge tone modifiers"

requirements-completed: [DS-01, DS-02, DS-03, DS-04, DS-05, DS-06]

# Metrics
duration: 3min
completed: 2026-06-04
---

# Phase 12 Plan 01: CSS Foundation + Test Scaffolds Summary

**Token-bound CSS for all 8 Phase 12 components added to 04-components.css, scoria-skeleton-pulse keyframe added to 05-motion.css, DS-06 ratchet drift-guard and ui_component_test scaffold created — zero Elixir component code touched**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-04T16:13:00Z
- **Completed:** 2026-06-04T16:16:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added all net-new CSS classes required by Phase 12 components to `assets/css/04-components.css`: table density modifiers, modal/drawer headers, field + form-section, notebook shell, flash banners with tone modifiers, skeleton, toast with tone modifiers and stacking region
- Added `scoria-skeleton-pulse` keyframe to `assets/css/05-motion.css` inside the `@layer scoria.components` block; existing unlayered `prefers-reduced-motion` block already suppresses it
- Created `test/scoria_web/ds06_drift_guard_test.exs` with correct palette regex, `.heex` brace-expansion wildcard, `@excluded` list, ratchet comparison (vacuous pass until plan 12-05 commits baseline), and unconditional `ui.ex-zero` assertion tagged `:ui_ex_zero`
- Created `test/scoria_web/ui_component_test.exs` scaffold with shared test header (`use ExUnit.Case, async: true` + `import Phoenix.LiveViewTest`) and doc comment listing DS-01..DS-05 test groups for plans 12-02/03/04

## Task Commits

1. **Task 1: Add net-new component CSS to 04-components.css and skeleton keyframe to 05-motion.css** - `7f07d62` (feat)
2. **Task 2: Create DS-06 ratchet drift-guard test and ui_component_test scaffold** - `4d0dddc` (feat)

**Plan metadata:** (committed with docs commit below)

## Files Created/Modified

- `assets/css/04-components.css` - Added 165 lines: table density modifiers, modal/drawer sub-components, field/form controls, notebook shell, flash banners, skeleton, toast + region
- `assets/css/05-motion.css` - Added `@keyframes scoria-skeleton-pulse` after `scoria-approval-pulse` inside `@layer scoria.components`
- `test/scoria_web/ds06_drift_guard_test.exs` - DS-06 ratchet guard with palette regex, `.heex` coverage, `@excluded`, ratchet test (File.exists? guard), ui.ex-zero assertion (`:ui_ex_zero` tag)
- `test/scoria_web/ui_component_test.exs` - Test scaffold with shared header and placeholder smoke test

## Decisions Made

- DS-06 ratchet uses `File.exists?` guard (not `@tag :pending` / `ExUnit.configure`) so `mix test` stays green without needing global configuration changes before plan 12-05 commits the baseline
- `ui.ex-zero` assertion tagged `:ui_ex_zero` and excluded from this plan's verify — `ui.ex` still has 3 raw palette lines at 195-197 (replaced by plan 12-02); tag dropped in 12-05 when full guard goes green
- `scoria-toast-region` uses `pointer-events: none` on the container + `pointer-events: auto` on children so the fixed stacking region does not block clicks to elements below

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — no data stubs. The `TODO(12-05)` comments in `ds06_drift_guard_test.exs` are intentional sequencing notes, not data placeholders.

## Issues Encountered

None — compile clean, all acceptance criteria passed, test suite green.

## Next Phase Readiness

- `04-components.css` is ready: every CSS class the Phase 12 components will emit exists and is token-bound
- `05-motion.css` is ready: `scoria-skeleton-pulse` keyframe is present and covered by reduced-motion suppression
- `ds06_drift_guard_test.exs` is ready: plans 12-02..12-05 can rely on this guard; plan 12-02 must not introduce new raw palette in non-excluded files
- `ui_component_test.exs` is ready: plans 12-02/03/04 add `render_component` assertions here rather than creating new test modules

---
*Phase: 12-design-system-component-layer*
*Completed: 2026-06-04*
