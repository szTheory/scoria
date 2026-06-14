---
phase: 12-design-system-component-layer
plan: "02"
subsystem: ui
tags: [elixir, phoenix-liveview, design-system, components, exunit, tdd]

# Dependency graph
requires: ["12-01"]
provides:
  - flash_group/1 with semantic scoria-flash--{tone} BEM modifiers, string-keyed, role=alert, tone SVG icons
  - alias Phoenix.LiveView.JS in ui.ex module header
  - table/1 (DS-01): typed :col/:empty/:action/:filter slots, sort emission, density modifiers, pagination, empty state
  - density_class/1 private helper
  - flash_modifier/1 and flash_icon/1 private helpers
  - ui.ex raw palette count = 0 (DS-06 ui_ex_zero assertion green)
affects: [12-03, 12-04, 12-05, 14-least-iterated-screens, 15-high-traffic-screens]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "slot/3 with typed attrs: slot :col do attr :label; attr :key; attr :class end (no :default in slot attrs -- use Map.get/3 in template)"
    - "flash_modifier/1 string-keyed clauses: Phoenix @flash always yields string keys, not atoms"
    - "flash_icon/1 private function returning ~H sigil with inline 16x16 SVG -- idiomatic HEEx helper"
    - "density_class/1 private helper: :compact -> modifier string, :default -> nil (class list filters nil)"
    - "TDD RED/GREEN: test commit before implementation commit -- both verified by test run"

key-files:
  created: []
  modified:
    - lib/scoria_web/ui.ex
    - test/scoria_web/ui_component_test.exs

key-decisions:
  - "slot attrs do not support :default keyword -- use Map.get(column, :key) in template instead (Rule 3 auto-fix: compile error blocked task)"
  - "flash_icon/1 returns ~H sigil with assigns = %{} -- idiomatic way to embed HEEx fragments in private helpers"
  - "table density toggle pill uses Atom.to_string + String.capitalize for label -- avoids hardcoded string list"

patterns-established:
  - "Slot-with-typed-attrs pattern for <.table> :col: label required, key/class optional, accessed via Map.get/3"
  - "TDD cycle for ui.ex components: write render_component assertions first (RED), then implement (GREEN)"

requirements-completed: [DS-05, DS-01]

# Metrics
duration: 8min
completed: 2026-06-04
---

# Phase 12 Plan 02: flash_group Fix + Table Component Summary

**flash_group/1 rewritten with semantic scoria-flash--{tone} string-keyed clauses + role=alert + tone SVG icons; table/1 (DS-01) added with typed :col slots, phx-click=sort emission, density modifiers, pagination strip, filter slot, and default empty state — ui.ex scans to zero raw palette**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-06-04T16:20:00Z
- **Completed:** 2026-06-04T16:28:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Rewrote `flash_group/1` in `lib/scoria_web/ui.ex`: replaced raw-palette `flash_tone_class/1` with string-keyed `flash_modifier/1`; added `role="alert"` to each flash div; added `flash_icon/1` private helper returning 16×16 inline SVG per tone (fail=x-circle, info=information-circle, pass=check-circle, warn=exclamation-triangle) so status is never communicated by color alone
- Added `alias Phoenix.LiveView.JS` after `use Phoenix.Component` in `ui.ex` module header (needed for JS-driven components in later plans)
- Deleted `flash_tone_class/1` entirely (was atom-keyed — never matched Phoenix's string flash keys; all flashes silently fell through to neutral style)
- `ui.ex` now scans to zero raw palette occurrences (`grep -cE` returns 0); DS-06 `ui_ex_zero` assertion passes
- Added `table/1` component (DS-01) to `lib/scoria_web/ui.ex`: typed `slot :col` with `label` (required), `key`, `class` attrs; `slot :empty`, `:action`, `:filter`; attrs for `rows`, `sort_by`, `sort_dir`, `density`, `id`, `page`, `total_pages`, `on_page_change`, `rest`
- Table renders column headers from `@col` slots; keyed columns emit `phx-click="sort"` + `phx-value-by={key}`; active sort column shows up/down chevron SVG colored `--scoria-action`; `:default` shows inactive chevron in `--scoria-text-subtle`
- Density modifier applied via `density_class/1`: `:compact` → `scoria-table--compact`, `:comfortable` → `scoria-table--comfortable`, `:default` → `nil`
- Empty state: `rows == []` renders `<.empty_state title="No records found">` by default; `<:empty>` slot overrides
- Pagination `<nav>` strip rendered only when `total_pages > 1` with prev/next `.scoria-button--ghost.scoria-button--sm` chevrons + "Page X of Y" label
- All 88 `test/scoria_web/` tests pass; zero regressions

## Task Commits

1. **Task 1 RED: Failing tests for flash_group DS-05** - `ba346f7` (test)
2. **Task 1 GREEN: Fix flash_group to semantic tokens** - `0fecd1f` (feat)
3. **Task 2 GREEN: Add table/1 component DS-01** - `0da317d` (feat)

*Note: Task 2 RED was included in the combined test commit `ba346f7` — the table test assertions were written before the implementation existed, confirming the RED phase.*

## Files Created/Modified

- `lib/scoria_web/ui.ex` — Added `alias Phoenix.LiveView.JS`; rewrote `flash_group/1` + `flash_modifier/1` + `flash_icon/1`; deleted `flash_tone_class/1`; added `table/1` + `density_class/1`
- `test/scoria_web/ui_component_test.exs` — Replaced placeholder test with 5 `flash_group` assertions and 5 `table` assertions using `render_component/2`

## Decisions Made

- Slot attrs do not support `:default` keyword in Phoenix LiveView 1.1.30 — compile error `invalid option :default for attr :key in slot :col` occurred; fixed by removing `:default` declarations and using `Map.get(column, :key)` / `Map.get(column, :class)` in the template (Rule 3 auto-fix)
- `flash_icon/1` private helper returns `~H` sigil with local `assigns = %{}` — idiomatic pattern for embedding HEEx fragments in private function helpers
- Table `density_class/1` returns `nil` for `:default` — Phoenix class list filters `nil` values, so no modifier is added to the class string for the default density

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Phoenix slot attr :default keyword not supported**
- **Found during:** Task 2 GREEN implementation
- **Issue:** `slot :col do attr :key, :atom, default: nil end` caused compile error: `invalid option :default for attr :key in slot :col. :default is not supported inside slot attributes`
- **Fix:** Removed `:default` declarations from `slot :col` attrs; replaced `column.key` and `column.class` references in template with `Map.get(column, :key)` and `Map.get(column, :class)` respectively
- **Files modified:** `lib/scoria_web/ui.ex`
- **Commit:** included in `0da317d`

## Known Stubs

None — `table/1` renders real data via `render_slot/2`; flash_group renders real flash messages. No data stubs.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. `flash_group` and `table` use standard HEEx `{...}` interpolation (auto HTML-escaped); `raw/1` is not used on flash messages or row data (T-12-04 mitigated). `ui.ex` is at zero raw palette (T-12-05 mitigated).

## Self-Check: PASSED

- `lib/scoria_web/ui.ex` exists and contains `def table(` and `defp flash_modifier("error")`
- `test/scoria_web/ui_component_test.exs` exists and contains `scoria-flash--fail`
- Commits `ba346f7`, `0fecd1f`, `0da317d` exist in git log
- All 88 `test/scoria_web/` tests pass, zero failures
- `grep -cE` raw palette count on `ui.ex` returns 0
- DS-06 `ui_ex_zero` assertion passes

---
*Phase: 12-design-system-component-layer*
*Completed: 2026-06-04*
