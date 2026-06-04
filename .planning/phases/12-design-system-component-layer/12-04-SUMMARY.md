---
phase: 12-design-system-component-layer
plan: "04"
subsystem: ui
tags: [elixir, phoenix-liveview, design-system, components, evidence, notebook, skeleton, toast, a11y, tdd]

# Dependency graph
requires: ["12-03"]
provides:
  - notebook/1 (DS-04): unified tabbed evidence panel shell with :tab/:empty_slot slots, aria-selected/tablist/tabpanel roles, phx-value-tab emission
  - raw_evidence/1 (DS-04): details/summary/pre standardized raw evidence block
  - skeleton/1 (DS-05): accessible loading placeholder with aria-label "Loading…", role=status, token-bound animation in CSS
  - toast/1 (DS-05): server-assign-driven transient notification with phx-mounted JS.hide auto-dismiss, tone icons, manual dismiss
  - ui.ex raw palette count = 0 (DS-06 ui_ex_zero assertion still green)
affects: [12-05, 14-least-iterated-screens, 15-high-traffic-screens]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "notebook empty state uses empty_slot (not :empty) as slot name to avoid conflict with the boolean empty attr"
    - "slot :tab typed with key/label attrs; iteration uses :for={tab <- @tab} with guard tab.key == @selected_tab for panel"
    - "JS.hide without to: option targets self (Pitfall 3 from RESEARCH.md — avoids '#id' string interpolation in component)"
    - "toast_icon/1 private helpers use pattern matching on tone atom; assigns = %{} pattern for defp HEEx helpers"
    - "skeleton pulse animation is entirely CSS-only; prefers-reduced-motion suppression in 05-motion.css"

key-files:
  created: []
  modified:
    - lib/scoria_web/ui.ex
    - assets/css/04-components.css
    - test/scoria_web/ui_component_test.exs

key-decisions:
  - "empty_slot is the slot name (not :empty) in notebook/1 — the :empty name conflicts with the empty boolean attr; callers pass empty_slot: [...] in render_component"
  - "JS.hide in toast/1 omits the to: option so it targets self; RESEARCH.md Pitfall 3 explicitly warns against to: '##{@id}' string interpolation in component context"
  - "tab_slot/3 test helper constructed to match typed slot structure expected by Phoenix.Component slot machinery"
  - "scoria-raw-evidence CSS added to 04-components.css (background --scoria-surface-sunken, font-family --scoria-font-mono, font-size --scoria-fs-badge) — class was missing from prior plan"

patterns-established:
  - "Typed slot with guard: :for={tab <- @tab} + separate <%= for tab <- @tab, tab.key == @selected_tab %> for panel render"
  - "Slot name collision avoidance: when boolean attr and slot have the same desired name, suffix slot with _slot"

requirements-completed: [DS-04, DS-05]

# Metrics
duration: 3min
completed: 2026-06-04
---

# Phase 12 Plan 04: Notebook Shell + Skeleton + Toast Summary

**notebook/1 unified tabbed evidence panel shell (DS-04) with :tab slots, aria-selected/tablist/tabpanel, phx-value-tab; raw_evidence/1 details/pre block; skeleton/1 accessible loading placeholder; toast/1 server-assign-driven transient notification with phx-mounted auto-dismiss — all added to ui.ex; zero raw palette maintained**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-06-04T16:39:28Z
- **Completed:** 2026-06-04T16:42:18Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `notebook/1` to `lib/scoria_web/ui.ex` (DS-04): attrs `id` (req), `title` (req), `eyebrow` (nil), `empty` (boolean, false), `selected_tab` (nil), `on_tab_change` (nil), `:global rest`; typed `slot :tab do attr :key; attr :label end`; `slot :empty_slot`. Renders `<div class="scoria-notebook">` with header. When `@empty`, renders `:empty_slot` content. Otherwise renders `<nav role="tablist">` with `<button role="tab" aria-selected=...>` per tab, plus `<div role="tabpanel">` for the active tab. Defaults to first tab when `selected_tab` is nil.

- Added `raw_evidence/1` to `lib/scoria_web/ui.ex` (DS-04): attr `label` (default "Advanced raw evidence"), `slot :inner_block` (required). Renders `<details class="scoria-raw-evidence"><summary>...</summary><pre class="scoria-raw-evidence__pre">...</pre></details>`. Token binding (mono font, sunken background) handled entirely by CSS.

- Added `scoria-raw-evidence` CSS rules to `assets/css/04-components.css`: base rule with `--scoria-border` frame, `__summary` rule with `--scoria-text-muted`, `__pre` rule with `--scoria-surface-sunken` / `--scoria-font-mono` / `--scoria-fs-badge`.

- Added `skeleton/1` to `lib/scoria_web/ui.ex` (DS-05): attrs `class` (nil), `rows` (integer, 1), `:global rest`. Renders `<div class="scoria-skeleton-group" aria-label="Loading…" role="status">` containing `<div :for={_ <- 1..@rows} class="scoria-skeleton scoria-skeleton--text">`. Pulse animation and reduced-motion suppression are CSS-only.

- Added `toast/1` to `lib/scoria_web/ui.ex` (DS-05): attrs `id` (req), `tone` (atom, :neutral), `message` (req), `duration_ms` (4000). Renders `<div class="scoria-toast scoria-toast--{tone}" role="status" phx-mounted={JS.hide(...)}>` with `toast_icon(@tone)` SVG, `<p>{@message}</p>`, and dismiss button with `aria-label="Dismiss"`. JS.hide omits `to:` (self-targeting, Pitfall 3). Added private `toast_icon/1` with 4 tone-specific SVGs + default fallback.

- All 42 `ui_component_test.exs` tests pass; full web suite 120 tests pass; zero regressions.

- `ui.ex` scans to zero raw palette occurrences; DS-06 `ui_ex_zero` assertion still passes.

## Task Commits

1. **Task 1 RED: Failing tests for notebook/raw_evidence DS-04** — `e909f28` (test)
2. **Task 1 GREEN: Add notebook/1 and raw_evidence/1 shell components DS-04** — `7ad9d15` (feat)
3. **Task 2 RED: Failing tests for skeleton/toast DS-05** — `26a19b5` (test)
4. **Task 2 GREEN: Add skeleton/1 and toast/1 transient feedback components DS-05** — `3c1c083` (feat)

## Files Created/Modified

- `lib/scoria_web/ui.ex` — Added `notebook/1`, `raw_evidence/1`, `skeleton/1`, `toast/1`, `toast_icon/1`
- `assets/css/04-components.css` — Added `.scoria-raw-evidence` + `__summary` + `__pre` CSS rules
- `test/scoria_web/ui_component_test.exs` — Added 7 notebook/raw_evidence DS-04 tests + 7 skeleton/toast DS-05 tests + `tab_slot/3` helper

## Decisions Made

- `notebook/1` slot for empty content is named `:empty_slot` (not `:empty`) to avoid a conflict with the `empty` boolean attr. Callers pass `empty_slot: slot_block(...)` in tests. This naming is a documented deviation from the plan's `:empty` reference.
- `JS.hide` in `toast/1` omits the `to:` option so the directive targets self — RESEARCH.md Pitfall 3 explicitly warns that `to: "##{@id}"` string interpolation inside the component renders the wrong DOM id due to how JS encoding works. Self-targeting is the correct behavior.
- `scoria-raw-evidence` CSS was missing from prior plans' CSS files; added in Task 1 as Rule 2 (missing CSS for correct component rendering).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] scoria-raw-evidence CSS classes not in 04-components.css**
- **Found during:** Task 1 GREEN
- **Issue:** The plan's action mentioned checking if `.scoria-raw-evidence*` classes exist (grep first), and they did not exist in the CSS file.
- **Fix:** Added `.scoria-raw-evidence`, `.scoria-raw-evidence__summary`, `.scoria-raw-evidence__pre` to `04-components.css` using `--scoria-surface-sunken`, `--scoria-font-mono`, `--scoria-fs-badge` token bindings.
- **Files modified:** `assets/css/04-components.css`
- **Commit:** Included in `7ad9d15` (GREEN commit for Task 1)

**2. [Rule 1 - Bug] Test for empty state used duplicate keyword key**
- **Found during:** Task 1 GREEN (first test run)
- **Issue:** The initial test for `empty: true` used `empty: slot_block("...")` as a keyword arg which overwrote `empty: true` in the same keyword list. The slot name `:empty_slot` was correct in the component but the test passed `empty:` twice.
- **Fix:** Updated test to use `empty_slot: slot_block(...)` and test description updated to match.
- **Files modified:** `test/scoria_web/ui_component_test.exs`
- **Commit:** Included in `7ad9d15` (GREEN commit for Task 1)

## Known Stubs

None — all four components are fully implemented with no placeholder data. `toast_icon/1` includes per-tone SVGs for all 5 tone values. `raw_evidence/1` renders caller-provided content. `skeleton/1` renders the requested number of rows.

## Threat Surface Scan

No new network endpoints, auth paths, or schema changes. All caller-provided strings (`@title`, `@eyebrow`, `@message`, `@label`) are interpolated via HEEx `{...}` auto-escaping (T-12-10 mitigated). `raw/1` is not used on any caller-provided content. `<pre>` content is HEEx-escaped (shown by test asserting `{&quot;key&quot;: &quot;value&quot;}`). `toast/1` `duration_ms` is an integer serialized into a JS.hide `time:` value — not a string interpolated into HTML (T-12-11 mitigated). `ui.ex` remains at zero raw palette (T-12-12 mitigated).

## Self-Check: PASSED

- `lib/scoria_web/ui.ex` contains `def notebook(` — FOUND
- `lib/scoria_web/ui.ex` contains `slot :tab` — FOUND
- `lib/scoria_web/ui.ex` contains `def raw_evidence(` — FOUND
- `lib/scoria_web/ui.ex` contains `def skeleton(` — FOUND
- `lib/scoria_web/ui.ex` contains `def toast(` — FOUND
- `lib/scoria_web/ui.ex` contains `JS.hide` without `to:` in toast — FOUND (checked: no `to:` option in toast JS.hide calls)
- `mix test test/scoria_web/ui_component_test.exs` exits 0 — PASSED (42 tests)
- `mix test test/scoria_web/` exits 0 — PASSED (120 tests)
- `grep -cE` raw palette count on `ui.ex` = 0 — PASSED
- Commits `e909f28`, `7ad9d15`, `26a19b5`, `3c1c083` present in git log — VERIFIED

---
*Phase: 12-design-system-component-layer*
*Completed: 2026-06-04*
