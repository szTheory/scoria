---
phase: 16-motion-responsive-theme-parity
plan: 02
subsystem: ui/css
tags: [responsive, table, accessibility, aria, mobile, css]
requires: ["16-01"]
provides: [table-overflow-viewport, mobile-summary-slot, aria-sort]
affects: [lib/scoria_web/ui.ex, assets/css/04-components.css, test/scoria_web/ui_component_test.exs]
tech-stack-added: []
tech-stack-patterns: [overflow-x-auto-viewport, css-responsive-modifier-class, aria-sort-state, heex-typed-slot]
key-files-created: []
key-files-modified:
  - lib/scoria_web/ui.ex
  - assets/css/04-components.css
  - test/scoria_web/ui_component_test.exs
decisions:
  - "scoria-table-shell--has-summary modifier class gates responsive CSS swap (mobile summaries visible, viewport hidden below 768px); tables without summaries keep overflow viewport at all widths"
  - "aria-sort added to sortable column headers (ascending/descending/none); paired with existing SVG icon to satisfy non-color-only sort direction (D-24/MOTION-02)"
  - "mobile_summary slot is strictly opt-in; absence means no mobile-summaries container rendered at all (D-10)"
  - "render_slot(@mobile_summary, row) iterates same @rows list as the table body; caller slot content is HEEx-escaped by default (T-16-03 mitigated)"
metrics:
  duration: "~10 min"
  completed: "2026-06-13T06:45:36Z"
  tasks: 1
  files: 3
---

# Phase 16 Plan 02: Table Overflow Viewport and Opt-In Mobile Summary Summary

Keyboard-reachable `scoria-table__viewport` overflow wrapper around every `<.table>` plus an opt-in per-row `mobile_summary` slot and `aria-sort` on sorted column headers — one shared-component change that pays dividends across every table screen without per-screen mobile forks.

## Tasks Completed

| Task | Description | Commit | Key Files |
|------|-------------|--------|-----------|
| RED | Failing tests for viewport wrapper, mobile_summary slot, and aria-sort | 1a006a1 | test/scoria_web/ui_component_test.exs |
| GREEN | Implement viewport wrapper, slot, aria-sort, and responsive CSS | 7b1f5f0 | lib/scoria_web/ui.ex, assets/css/04-components.css |

## What Was Built

**`lib/scoria_web/ui.ex` — `table/1` component changes:**
- Wrapped the `<table>` element in `<div class="scoria-table__viewport" tabindex="0">` — every table is now inside a keyboard-reachable horizontal scroll container (D-13). Sticky `thead th` continues to work because vertical sticky is unaffected by `overflow-x: auto`.
- Added `slot :mobile_summary` (opt-in, typed) following the same typed-slot convention as `:col`, `:action`, `:filter`. When the slot is absent, no mobile-summaries container renders.
- When `:mobile_summary` is provided, a sibling `<div class="scoria-table__mobile-summaries">` renders with one child per row via `render_slot(@mobile_summary, row)`. Content comes entirely from the caller's slot — no fields are hardcoded.
- Added `aria-sort="ascending"` / `aria-sort="descending"` on the currently sorted column header; `aria-sort="none"` on other sortable column headers. Direction is now exposed to assistive tech in addition to the existing SVG icon and color (D-24/MOTION-02).
- Added `scoria-table-shell--has-summary` modifier class on the `.scoria-table-shell` div when the mobile_summary slot is present. CSS uses this to gate the below-768px visibility swap.

**`assets/css/04-components.css` — new CSS rules (appended inside `.scoria-root` block):**
- `.scoria-table__viewport { overflow-x: auto; }` — horizontal scroll container.
- `.scoria-table__mobile-summaries { display: none; padding: var(--scoria-space-4); background: var(--scoria-surface-panel); gap: var(--scoria-space-4); flex-direction: column; }` — default hidden, semantically tokenized.
- `@media (max-width: 767px)` scoped to `.scoria-table-shell--has-summary`: hides the viewport, shows summaries as `display: flex`.
- `@media (min-width: 768px)`: force-hides summaries (`display: none !important`) and restores viewport display on summary-enabled tables.
- Tables WITHOUT the `--has-summary` modifier keep honest overflow at all widths (D-10).
- All new rules use semantic tokens only (`--scoria-surface-panel`, `--scoria-space-4`) — no raw hex or palette classes.

**`test/scoria_web/ui_component_test.exs` — new test describe block:**
- `describe "table/1 responsive viewport (16-02)"` with 9 tests covering: viewport wrapper presence, tabindex=0, absence of mobile-summaries when slot absent, presence and per-row rendering when slot present, desktop `<table>` always present, aria-sort ascending/descending/none on correct columns, and `--has-summary` modifier class.

## Acceptance Criteria Verification

- [x] `table/1` output wraps `<table>` in an element with class `scoria-table__viewport` and `tabindex="0"`
- [x] `slot :mobile_summary` is declared and `render_slot(@mobile_summary, row)` appears in the render
- [x] When no `mobile_summary` slot passed: output contains no `scoria-table__mobile-summaries` element (test asserts)
- [x] When `mobile_summary` slot passed: output contains `scoria-table__mobile-summaries` with one child per row (test asserts)
- [x] `<table>` element always present (desktop semantics preserved); tests assert with and without mobile_summary
- [x] Sorted column header carries `aria-sort` reflecting `sort_dir`; unsorted sortable headers carry `aria-sort="none"`
- [x] `04-components.css` defines `.scoria-table__viewport { overflow-x: auto; }`, `.scoria-table__mobile-summaries` rule, and `@media (min-width: 768px)` rule toggling summary/viewport visibility
- [x] `mix test test/scoria_web/ui_component_test.exs` — 79 tests, 0 failures
- [x] `mix test test/scoria_web/ds06_drift_guard_test.exs` — passes (no raw palette in new CSS/HEEx)
- [x] `mix test test/scoria_web/ui_drift_guard_test.exs` — passes (no re-introduced per-component helpers)

## Deviations from Plan

None — plan executed exactly as written.

## Threat Flags

No new attack surface. Mobile summary content is rendered via `render_slot/2` (HEEx auto-escaping applies; no `Phoenix.HTML.raw` used) — T-16-03 mitigated. No new routes, auth paths, or data flows introduced.

## Known Stubs

None. The mobile_summary slot is purely opt-in; callers supply content. No data is hardcoded or left as a placeholder.

## Self-Check: PASSED

Files confirmed:
- `lib/scoria_web/ui.ex` — exists with `scoria-table__viewport`, `tabindex="0"`, `slot :mobile_summary`, `render_slot(@mobile_summary`, `aria-sort`
- `assets/css/04-components.css` — exists with `.scoria-table__viewport`, `.scoria-table__mobile-summaries`, `@media (min-width: 768px)` rules
- `test/scoria_web/ui_component_test.exs` — exists with `describe "table/1 responsive viewport (16-02)"`

Commits confirmed:
- `1a006a1` — test(16-02): add failing tests for table/1 overflow viewport and mobile_summary slot
- `7b1f5f0` — feat(16-02): table/1 overflow viewport, opt-in mobile_summary slot, and aria-sort
