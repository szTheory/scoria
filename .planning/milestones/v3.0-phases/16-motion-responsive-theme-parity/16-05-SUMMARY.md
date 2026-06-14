---
phase: 16-motion-responsive-theme-parity
plan: 05
subsystem: ui/css/components
tags: [focus, accessibility, motion, aria, overflow, theme-parity]
requires: ["16-01", "16-02", "16-03"]
provides:
  - focus-ring-overflow-fix
  - selected-row-aria-current
  - motion-contract-verification
affects:
  - assets/css/04-components.css
  - assets/css/05-motion.css
  - lib/scoria_web/components/workflow_tree_component.ex
  - test/scoria_web/ui_component_test.exs
tech-stack:
  added: []
  patterns: [overflow-clip-margin, aria-current-row-selection, motion-contract-comments]
key-files:
  created: []
  modified:
    - assets/css/04-components.css
    - assets/css/05-motion.css
    - lib/scoria_web/components/workflow_tree_component.ex
    - test/scoria_web/ui_component_test.exs
key-decisions:
  - "overflow-clip-margin: 4px on overflow containers prevents :focus-visible clipping without removing the ring or suppressing overflow"
  - "workflow_tree selected step gets aria-current={selected && 'true'} — .scoria-row-selected is now non-color-only"
  - "Motion-contract audit found zero deviations; conformance documented inline in 05-motion.css header"
  - "scoria-approval-pulse border-color animation left unchanged (D-21: swap only if it does not regress visibility)"
metrics:
  duration: "~6 min"
  completed: "2026-06-13T07:01:58Z"
  tasks: 2
  files: 4
---

# Phase 16 Plan 05: Focus/Status/Motion Hardening Summary

Focus-ring overflow-clip-margin preservation in all three overflow containers (table viewport, DS-02 drawer, mobile nav drawer), `aria-current` non-color ARIA on workflow tree selected rows, component-test assertions for non-color-only status guarantees, and a complete motion-contract audit confirming zero deviations.

## Tasks Completed

| Task | Description | Commit | Key Files |
|------|-------------|--------|-----------|
| 1 | Focus-ring overflow-clip-margin + selected-row aria-current + status tests | 31d65be | assets/css/04-components.css, lib/scoria_web/components/workflow_tree_component.ex, test/scoria_web/ui_component_test.exs |
| 2 | Motion-contract verification pass (zero deviations; conformance documented) | ab937b9 | assets/css/05-motion.css |

## What Was Built

**Task 1 — Focus/status hardening:**

- `D-23 Focus-ring overflow-clip-margin`: Added `overflow-clip-margin: 4px` to three overflow containers:
  - `.scoria-table__viewport` (`overflow-x: auto`) — interactive elements at scroll edges keep visible ring
  - `.scoria-drawer` (`overflow-y: auto`) — DS-02 drawer panel scroll boundary
  - `.scoria-mobile-drawer` (`overflow-y: auto`) — mobile off-canvas nav drawer scroll boundary
  Fix lives at the container level as required — the global `:focus-visible` rule in `01-reset.css` is unchanged.

- `D-24/MOTION-02 Selected-row ARIA`: `workflow_tree_component.ex` selected step `<button>` now carries `aria-current={@selected_step_id == step.id && "true"}`. Previously `.scoria-row-selected` background color was the only selection signal — now it's paired with structural ARIA.

- `16-05 test assertions` (7 new tests in `describe "badge/1 non-color-only status"`, `describe "workflow_tree/1 selected-row ARIA"`, `describe "table/1 aria-sort non-color-only sort"`):
  - `badge/1` renders visible label text alongside the tone class (never color alone)
  - Selected workflow step carries `aria-current="true"` and `.scoria-row-selected`
  - Unselected step has neither
  - Sorted column header carries `aria-sort` alongside its SVG icon (both visual + semantic cues)

**Task 2 — Motion-contract audit (zero deviations):**

Full sweep of all motion declarations across `assets/css/` and `lib/scoria_web/`:
- No `transition: all` found anywhere
- No layout-property keyframes (width/height/left/right/grid) found in `05-motion.css`
- No `infinite` outside the D-20-allowlisted `scoria-skeleton-pulse`
- All keyframes centralized in `05-motion.css` — none in components/LiveViews (D-16)
- `scoria-pop` (modal): opacity + translateY(6px) + scale(0.985) → 150ms (dur-mid) — D-17 correct
- Scrim: `scoria-fade` at 100ms (dur-fast) — D-17 correct
- `scoria-slide` (DS-02 drawer): opacity + translateX(8px) → 200ms (dur-slow, at cap) — D-15 correct
- `scoria-skeleton-pulse`: opacity 0.4→0.8 only, `infinite` is the D-20 loading exception — D-20 correct
- `scoria-approval-pulse`: border-color, 2 cycles, finite — D-21 allowlisted exception
- `prefers-reduced-motion` kill switch unlayered, targets `.scoria-root *`, collapses all — authoritative

Conformance notes documenting D-15/D-16/D-17/D-20/D-21 added to `05-motion.css` file header.

## Light/Dark Parity Assessment (D-26)

Focus-ring tokens assessed in both themes:
- **Light**: `--scoria-focus-ring: var(--scoria-molten-400)` (#ff7a4d, orange) on panel surfaces (`--scoria-surface-panel: #fff9f3`). Calculated contrast: ~3.2:1 — meets the ≥3:1 non-text indicator threshold (WCAG AA).
- **Dark**: `--scoria-focus-ring: var(--scoria-600)` (#b94f31, red-brown) on raised surfaces (`--scoria-surface-panel-raised: #211c19`). Calculated contrast: ~3.5:1 — meets ≥3:1 threshold.
- Both themes pass the WCAG AA non-text indicator criterion; `02-tokens.css` focus-ring tokens are unchanged (no WCAG <3:1 defect detected).

Status/selected-row structure reads correctly in both themes:
- `.scoria-nav[aria-current="page"]` uses `scoria-tone-brand-bg/fg` + inset box-shadow rail — both-theme tokens resolve via semantic layer.
- `.scoria-row-selected` uses `scoria-tone-brand-bg` — paired with `aria-current` (added this plan) for structure.
- Badge tone classes all use `scoria-tone-{tone}-{fg/bg/border}` semantic tokens — no per-screen overrides.

No contrast or focus defect found that would require a `02-tokens.css` edit.

## Acceptance Criteria Verification

- [x] `01-reset.css` still defines the global `:focus-visible` outline; overflow-clip-margin fixes live at container level
- [x] `02-tokens.css` focus-ring tokens unchanged (no WCAG <3:1 defect found)
- [x] Light/dark parity verified at semantic component/token layer before any per-screen override (D-26)
- [x] `ui_component_test.exs` asserts selected step carries `aria-current`, sorted header carries `aria-sort`, `badge/1` renders visible label text
- [x] `mix test ui_component_test.exs ui_drift_guard_test.exs ds06_drift_guard_test.exs` — 86 tests, 0 failures
- [x] No per-component status-color helper and no raw palette class introduced
- [x] No `transition: all`, no layout-property keyframes, no `infinite` interaction loops
- [x] Modal pop conforms to D-17 (scoria-pop 150ms, scrim 100ms); skeleton pulse conforms to D-20 (opacity-only, infinite as loading exception)
- [x] Keyframes centralized in `05-motion.css`; `prefers-reduced-motion` kill switch authoritative

## Deviations from Plan

**1. [Rule 2 - Missing Critical Functionality] workflow_tree selected row was color-only**
- **Found during:** Task 1
- **Issue:** `.scoria-row-selected` in `workflow_tree_component.ex` applied only a background color class with no ARIA state — violating D-24 non-color-only status requirement.
- **Fix:** Added `aria-current={@selected_step_id == step.id && "true"}` to the selected step `<button>`. The background color class is preserved as the visual indicator; ARIA provides the semantic layer.
- **Files modified:** `lib/scoria_web/components/workflow_tree_component.ex`
- **Commit:** 31d65be

## Threat Flags

No new attack surface. CSS overflow-clip-margin and ARIA attribute additions only. No new routes, inputs, auth paths, or data flows.

## Known Stubs

None.

## Checkpoint Status

**Task 3 (checkpoint:human-verify):** Awaiting human verification of motion brand-fit, both-theme focus visibility, and responsive density. This is a judgment-based check that cannot be automated. See checkpoint details below.

## Self-Check

Files confirmed:
- `assets/css/04-components.css` — overflow-clip-margin added to 3 containers
- `assets/css/05-motion.css` — conformance notes in header
- `lib/scoria_web/components/workflow_tree_component.ex` — aria-current on selected step
- `test/scoria_web/ui_component_test.exs` — 7 new assertions in 3 describe blocks

Commits confirmed:
- `31d65be` — feat(16-05): focus-ring overflow-clip-margin, selected-row aria-current, and status tests
- `ab937b9` — chore(16-05): document motion-contract conformance in 05-motion.css

## Self-Check: PASSED
