---
phase: 12-design-system-component-layer
plan: "03"
subsystem: ui
tags: [elixir, phoenix-liveview, design-system, components, overlays, forms, a11y, tdd]

# Dependency graph
requires: ["12-02"]
provides:
  - modal/1 (DS-02): slot-based modal shell with role=dialog, triple dismiss contract, guarded footer slot
  - drawer/1 (DS-02): slot-based drawer aside shell with role=dialog, triple dismiss contract, guarded eyebrow/title/actions slots
  - field/1 (DS-03): label+input_slot+help+error wrapper with required a11y affordances, error via icon+text
  - form_section/1 (DS-03): section heading + optional description + inner_block grouping
  - ui.ex raw palette count = 0 (DS-06 ui_ex_zero assertion still green)
affects: [12-04, 12-05, 14-least-iterated-screens, 15-high-traffic-screens]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "slot inner_block in render_component tests: [%{inner_block: fn _changed, _arg -> content end, __slot__: :inner_block}]"
    - "defp slot_block(content) helper in test module — reusable render_component slot constructor for function components"
    - "Triple dismiss contract: phx-window-keydown={@on_dismiss} phx-key='Escape' on outer div + phx-click={@on_dismiss} on scrim + close button"
    - "Field error a11y: 12x12 exclamation SVG prefix ensures error is never communicated by color alone"
    - "Required field a11y: aria-hidden='true' asterisk + sr-only '(required)' span"
    - "TDD RED/GREEN cycle: test commit before implementation commit — both verified by test run"

key-files:
  created: []
  modified:
    - lib/scoria_web/ui.ex
    - test/scoria_web/ui_component_test.exs

key-decisions:
  - "slot inner_block in render_component tests must be a function fn _changed, _arg -> content end — plain strings cause BadFunctionError in call_inner_block! (Rule 1 auto-fix)"
  - "Introduced defp slot_block/1 helper in test module to avoid repeating the fn-wrapping boilerplate across 9 test cases"
  - "drawer/1 named attr slot as title_slot (not :title) to avoid collision with the @title string attr — consistent with modal/1"
  - "field/1 uses sr-only CSS class (same as workflow_live/show.ex) for the visually-hidden required span, not scoria-sr-only"

patterns-established:
  - "Triple dismiss contract in ui.ex overlays: phx-window-keydown + phx-click on scrim + close button — all bound to @on_dismiss"
  - "Field error uses inline SVG icon (not CSS-only indicator) so status is never color-alone (a11y DS-03)"

requirements-completed: [DS-02, DS-03]

# Metrics
duration: 10min
completed: 2026-06-04
---

# Phase 12 Plan 03: Overlay Shells + Form Controls Summary

**modal/1 and drawer/1 slot-based overlay shells (DS-02) with triple dismiss contract; field/1 form wrapper with required a11y affordances and icon-bearing error; form_section/1 heading group — all added to ui.ex; zero raw palette maintained**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-06-04T16:25:00Z
- **Completed:** 2026-06-04T16:36:12Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `modal/1` to `lib/scoria_web/ui.ex` (DS-02): attrs `id` (req), `show` (boolean req), `on_dismiss` (string req), `title` (default nil), `max_width` (default "560px"), `:global rest`; slots `:title_slot`, `:inner_block` (required), `:footer`. Renders nothing when `show={false}` via `:if={@show}`. When shown: scrim with `phx-click={@on_dismiss}`, panel with `role="dialog" aria-modal="true"`, close button with `autofocus`, `aria-label="Close dialog"`, 16×16 X SVG. Keyboard dismiss: `phx-window-keydown={@on_dismiss} phx-key="Escape"` on outer wrapper. Footer rendered `:if={@footer != []}`.

- Added `drawer/1` to `lib/scoria_web/ui.ex` (DS-02): attrs `id`, `show`, `on_dismiss`, `title`, `:global rest`; slots `:eyebrow`, `:title_slot`, `:actions`, `:inner_block` (required). Renders nothing when `show={false}`. When shown: scrim with `phx-click={@on_dismiss}`, `phx-window-keydown={@on_dismiss}`, `phx-key="Escape"`; `<aside class="scoria-drawer">` with `role="dialog" aria-modal="true"`. Header contains guarded `<:eyebrow>`/`<:title_slot>`/`<:actions>` slots and a "Close drawer" ghost button emitting `phx-click={@on_dismiss}`.

- Added `field/1` to `lib/scoria_web/ui.ex` (DS-03): attrs `id` (req), `label` (req), `help` (default nil), `error` (default nil), `required` (default false). Required field: aria-hidden `*` in `--scoria-danger-action` color + `sr-only` `(required)` span. Error: `scoria-field__error` paragraph with 12×12 inline exclamation SVG + error text (never error by color alone). Caller provides input element via `:inner_block` slot.

- Added `form_section/1` to `lib/scoria_web/ui.ex` (DS-03): attrs `title` (req), `description` (default nil). Renders `<section class="scoria-form-section">` with `<h3>` + optional `<p>` + `inner_block`.

- All 28 `ui_component_test.exs` tests pass; full web suite 106 tests pass; zero regressions.

- `ui.ex` scans to zero raw palette occurrences; DS-06 `ui_ex_zero` assertion still passes.

## Task Commits

1. **Task 1 RED: Failing tests for modal/drawer DS-02** — `cce9ef6` (test)
2. **Task 1 GREEN: Add modal/1 and drawer/1 slot-based overlay shells DS-02** — `1dc8f1d` (feat)
3. **Task 2 RED: Failing tests for field/form_section DS-03** — `cb3e533` (test)
4. **Task 2 GREEN: Add field/1 and form_section/1 form control wrappers DS-03** — `11b0191` (feat)

## Files Created/Modified

- `lib/scoria_web/ui.ex` — Added `modal/1`, `drawer/1`, `field/1`, `form_section/1`
- `test/scoria_web/ui_component_test.exs` — Added 9 modal/drawer DS-02 tests + 8 field/form_section DS-03 tests + `slot_block/1` helper

## Decisions Made

- `slot inner_block` in `render_component` tests must be a function `fn _changed, _arg -> content end`, not a plain string. Plain strings cause `BadFunctionError` in `Phoenix.Component.call_inner_block!/3`. Introduced `defp slot_block(content)` helper in the test module to DRY this up across 9 calls (Rule 1 auto-fix: bug in test construction caught at RED phase).
- `drawer/1` uses slot name `:title_slot` (not `:title`) to avoid collision with the `title` string attr — consistent with `modal/1` naming. The attr `title` provides a shorthand when no slot markup is needed.
- `field/1` uses `sr-only` CSS class (not `scoria-sr-only`) for the visually-hidden required span — this matches the existing usage in `workflow_live/show.ex`.
- Modal `autofocus` attribute on close button (not a JS hook) — hooks are no-ops in `LiveViewTest` and the spec explicitly calls this out.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Plain string inner_block causes BadFunctionError in render_component tests**
- **Found during:** Task 1 GREEN verification (first test run)
- **Issue:** The initial test approach passed `inner_block: [%{inner_block: "Modal content"}]` but `Phoenix.Component.call_inner_block!/3` calls `fun.(changed, argument)` and a plain string is not callable.
- **Fix:** Changed all slot content to `fn _changed, _arg -> content end` pattern; extracted `defp slot_block/1` helper to DRY the pattern. Also updated test for "caller inner_block rendered" from `~s(<input id="myinput" .../>)` (which gets HTML-escaped) to plain text content.
- **Files modified:** `test/scoria_web/ui_component_test.exs`
- **Commit:** included in `1dc8f1d` (GREEN commit for Task 1)

## Known Stubs

None — modal, drawer, field, and form_section are fully wired components with no placeholder data. The `slot_block/1` test helper returns actual string content, not empty stubs.

## Threat Surface Scan

No new network endpoints, auth paths, or schema changes. `modal/1`, `drawer/1`, `field/1`, and `form_section/1` use standard HEEx `{...}` interpolation (auto HTML-escaped) for all caller-provided strings (`@title`, `@label`, `@help`, `@error`). `raw/1` is not used on any caller-provided string (T-12-07 mitigated). `ui.ex` remains at zero raw palette (T-12-08 mitigated). `phx-window-keydown` is scoped to `:if={@show}` so the global keyboard listener is only active when the overlay is visible (T-12-09 accepted per spec).

## Self-Check: PASSED

- `lib/scoria_web/ui.ex` contains `def modal(` — FOUND
- `lib/scoria_web/ui.ex` contains `def drawer(` — FOUND
- `lib/scoria_web/ui.ex` contains `def field(` — FOUND
- `lib/scoria_web/ui.ex` contains `def form_section(` — FOUND
- `test/scoria_web/ui_component_test.exs` contains `Close dialog` — FOUND
- `mix test test/scoria_web/ui_component_test.exs` exits 0 — PASSED (28 tests)
- `mix test test/scoria_web/` exits 0 — PASSED (106 tests)
- `grep -cE` raw palette count on `ui.ex` = 0 — PASSED
- Commits `cce9ef6`, `1dc8f1d`, `cb3e533`, `11b0191` present in git log

---
*Phase: 12-design-system-component-layer*
*Completed: 2026-06-04*
