---
phase: 12-design-system-component-layer
reviewed: 2026-06-04T18:00:00Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - lib/scoria_web/ui.ex
  - lib/scoria_web/components/remote_invocation_evidence_component.ex
  - lib/scoria_web/live/approvals_live/index.ex
  - lib/scoria_web/live/workflow_live/show.ex
  - assets/css/04-components.css
  - assets/css/05-motion.css
  - test/scoria_web/ui_component_test.exs
  - test/scoria_web/ds06_drift_guard_test.exs
  - test/scoria_web/live/approvals_live_test.exs
  - test/scoria_web/live/workflow_live_test.exs
findings:
  critical: 1
  warning: 5
  info: 4
  total: 10
status: issues_found
---

# Phase 12: Code Review Report

**Reviewed:** 2026-06-04T18:00:00Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Phase 12 added nine design-system components to `ui.ex`, converted `RemoteInvocationEvidenceComponent`
to a `<.notebook>` adapter, wired toast/skeleton into two screens, and activated the DS-06 ratchet guard.
The Elixir component logic is generally sound; most of the HEEx renders correctly and the DS-06 guard
is structurally correct. However, there is one layout defect that will be user-visible on every multi-toast
scenario (all toasts pile at identical viewport coordinates), two a11y omissions on dialog elements,
a silent behavioral bug in `skeleton` when `rows=0` is passed, and several CSS class definitions emitted
by the components that have no corresponding CSS rules — these cause invisible layout gaps.

---

## Critical Issues

### CR-01: Multiple toasts overlap at the same viewport position

**File:** `assets/css/04-components.css:559-591`
**Issue:** `.scoria-toast` declares `position: fixed; bottom: var(--scoria-space-5); right: var(--scoria-space-5)`.
`.scoria-toast-region` also declares `position: fixed` at the same coordinates and uses `display: flex; flex-direction: column; gap`.
A `position: fixed` child inside a `position: fixed` parent is positioned relative to the parent's established containing
block, not the viewport — but the parent itself collapses to zero height because all its children are removed from normal
flow by their own `position: fixed`. The result: every additional toast after the first stacks at the same `(bottom, right)`
coordinates and all toasts are invisible or overlap each other completely. This is user-visible any time two toasts arrive
(e.g., the error path in `approvals_live` triggers `put_flash` + `put_toast` — a single approval action can produce two
toasts in rapid succession).

**Fix:** Remove `position: fixed` (and the associated `bottom`/`right`/`z-index`) from the individual `.scoria-toast` rule.
The containing `.scoria-toast-region` already handles fixed placement, stacking direction, and z-index. The toast should
participate in normal flex flow within the region:

```css
/* Before */
.scoria-toast {
  position: fixed;
  bottom: var(--scoria-space-5);
  right: var(--scoria-space-5);
  z-index: var(--scoria-z-toast);
  min-width: 280px;
  ...
}

/* After */
.scoria-toast {
  /* position is now static inside the flex region */
  min-width: 280px;
  max-width: 400px;
  box-shadow: var(--scoria-shadow-raised);
  border-radius: var(--scoria-radius-md);
  border: 1px solid var(--scoria-tone-neutral-border);
  background: var(--scoria-tone-neutral-bg);
  color: var(--scoria-tone-neutral-fg);
  padding: var(--scoria-space-2) var(--scoria-space-4);
  font-size: var(--scoria-fs-body);
  display: flex;
  align-items: flex-start;
  gap: var(--scoria-space-2);
}
```

The toast can still be used standalone (outside the region) for other callers, in which case it would need
the `position: fixed` added at the call site via a utility class or a separate modifier.

---

## Warnings

### WR-01: `skeleton` renders 2 rows when `rows=0` is passed (off-by-one via descending range)

**File:** `lib/scoria_web/ui.ex:349`
**Issue:** The skeleton component uses `:for={_ <- 1..@rows}`. In Elixir 1.12+, `1..0` is a *decreasing*
range `[1, 0]` (step −1), not an empty range. Passing `rows=0` renders **two** skeleton rows instead of
zero, and the compiler emits: `warning: 1..0 has a default step of -1, please write 1..0//-1 instead`.
While `rows=0` is not used in current callers, the attr has no documented minimum value, and `rows=0` is
a reasonable caller assumption for "no skeleton needed."

**Fix:** Use an explicit step or guard:
```elixir
# Option A — explicit step makes intent clear
<div :for={_ <- 1..max(@rows, 0)//1} class={["scoria-skeleton", "scoria-skeleton--text", @class]}></div>

# Option B — add a minimum validator to the attr declaration
attr(:rows, :integer, default: 1)  # add: no direct fix, but document rows >= 1

# Option C — simplest defensive fix
<div :for={n <- 1..@rows//1, @rows >= 1} class={["scoria-skeleton", "scoria-skeleton--text", @class]}></div>
```

### WR-02: `modal/1` and `drawer/1` missing `aria-labelledby` on `role="dialog"` elements

**File:** `lib/scoria_web/ui.ex:203, 256`
**Issue:** Both `modal/1` (line 203) and `drawer/1` (line 256) render `role="dialog" aria-modal="true"` 
but omit `aria-labelledby`. The WAI-ARIA authoring practices for `dialog` require either `aria-labelledby`
referencing the dialog's heading element or `aria-label` on the dialog container itself. Without this,
screen readers announce "dialog" with no accessible name — the user cannot identify what dialog has opened
before interacting with its contents. The modal already has `autofocus` on the close button but this does
not substitute for an accessible dialog name.

**Fix:** Add an `id` to the title `h2` and reference it on the panel element:
```elixir
# modal/1 — add id to h2 and aria-labelledby to panel
<div class="scoria-modal__panel" role="dialog" aria-modal="true"
     aria-labelledby={"#{@id}-title"} style={"max-width: #{@max_width}"}>
  <div class="scoria-modal__header">
    <div>
      <h2 :if={@title_slot != []} id={"#{@id}-title"}>{render_slot(@title_slot)}</h2>
      <h2 :if={@title_slot == [] and @title != nil} id={"#{@id}-title"}>{@title}</h2>
    </div>
    ...
```
Apply the same pattern in `drawer/1` using `@id` to build the `aria-labelledby` reference.

### WR-03: `.scoria-drawer` has no positioning — renders inline, not as a side panel

**File:** `assets/css/04-components.css:319-325`
**Issue:** `.scoria-drawer` only defines `border`, `border-radius`, `background`, `padding`, and
`animation`. It has no `position: fixed` (or `absolute`), no `top`/`right`/`bottom`/`width`, and no
`z-index`. The containing `.scoria-drawer-shell` (which wraps the scrim + aside) also has no CSS
definition at all. The `<.drawer>` component will therefore render inline in the document flow below the
scrim overlay, not as a floating side panel. Callers will see the scrim appear but the drawer content
will be scrolled to in the page body rather than sliding in from the edge.

**Fix:** At minimum, `.scoria-drawer-shell` needs `position: fixed; inset: 0; z-index: var(--scoria-z-modal);`
(matching `.scoria-modal`) and `.scoria-drawer` needs `position: fixed; right: 0; top: 0; bottom: 0; width: clamp(320px, 40vw, 560px); overflow-y: auto; z-index: var(--scoria-z-modal);` (or use a grid/flex layout within the shell):

```css
.scoria-drawer-shell {
  position: fixed;
  inset: 0;
  z-index: var(--scoria-z-modal);
  display: flex;
  align-items: stretch;
  justify-content: flex-end; /* or flex-start for left drawer */
}
.scoria-drawer {
  position: relative; /* contained by shell */
  width: clamp(320px, 40vw, 560px);
  overflow-y: auto;
  background: var(--scoria-surface-panel-raised);
  padding: var(--scoria-space-4);
  border-left: 1px solid var(--scoria-border);
  animation: scoria-slide var(--scoria-dur-slow) var(--scoria-ease-out);
}
```

### WR-04: DS-06 ratchet `:new_violation` branch is unreachable dead code

**File:** `test/scoria_web/ds06_drift_guard_test.exs:41-43`
**Issue:** The `cond` in the ratchet test has two branches that both fire for the case of a brand-new
file with palette usage (baseline count = 0, current count > 0):

```elixir
cond do
  count > baseline_count -> {path, count, baseline_count, :regression}       # fires first (0 < count)
  baseline_count == 0 and count > 0 -> {path, count, 0, :new_violation}       # NEVER reached
  true -> nil
end
```

When `baseline_count == 0` and `count > 0`, `count > baseline_count` is `true`, so `:regression` always
fires. The `:new_violation` atom is dead code. This does not cause a false pass (violations are still
caught), but the failure message will incorrectly report `:regression` for genuinely new files instead of
the more informative `:new_violation`. Over time this makes the error messages misleading.

**Fix:**
```elixir
cond do
  baseline_count == 0 and count > 0 -> {path, count, 0, :new_violation}   # check new-file case first
  count > baseline_count             -> {path, count, baseline_count, :regression}
  true                               -> nil
end
```

### WR-05: `on_page_change: nil` (default) allows pagination UI to render without any click handler

**File:** `lib/scoria_web/ui.ex:544, 631-651`
**Issue:** `on_page_change` defaults to `nil`. When `total_pages > 1`, the pagination `<nav>` renders
with `phx-click={nil}` on the prev/next buttons. In HEEx, `phx-click={nil}` omits the attribute
entirely — clicking these buttons does nothing, silently. A caller who passes `total_pages > 1` (explicitly
or via accumulation) without wiring `on_page_change` will see pagination controls that appear clickable
but do nothing. There is no runtime warning or compile-time check.

**Fix:** Add a compile-time guard or a runtime assertion:
```elixir
# Option A — make on_page_change required when total_pages can exceed 1
# (document this in the attr's doc comment clearly)
attr :on_page_change, :string, default: nil
# Add in table/1 body:
if @total_pages > 1 and is_nil(@on_page_change) do
  raise ArgumentError, "<.table> total_pages=#{@total_pages} but on_page_change is nil"
end

# Option B — only render pagination when on_page_change is also set
<nav :if={@total_pages > 1 and not is_nil(@on_page_change)} ...>
```

---

## Info

### IN-01: `scoria-notebook__tab--active` CSS class emitted but has no CSS definition

**File:** `lib/scoria_web/ui.ex:487` / `assets/css/04-components.css`
**Issue:** The notebook tab button emits `"scoria-notebook__tab--active"` as a BEM modifier class when
a tab is selected. No CSS rule for `.scoria-notebook__tab--active` exists; the active-tab styling is
entirely driven by `.scoria-notebook__tab[aria-selected="true"]`. The `--active` class is a no-op.
This is misleading to future developers who may try to add overrides targeting the class, and
it indicates the BEM/attribute-selector pattern is split across the two files inconsistently.

**Fix:** Either define the modifier class in CSS (and keep both for belt-and-suspenders):
```css
.scoria-notebook__tab--active,
.scoria-notebook__tab[aria-selected="true"] {
  color: var(--scoria-text);
  border-bottom-color: var(--scoria-action);
}
```
Or remove the class emission from `ui.ex` line 487 and rely solely on `aria-selected`.

### IN-02: Multiple scoria-* CSS classes emitted by components but not defined

**File:** `assets/css/04-components.css` (gap) / `lib/scoria_web/ui.ex` (emitters)
**Issue:** The following classes are emitted by `ui.ex` components but have no corresponding CSS rule
in `04-components.css` or any other CSS file in `assets/css/`:

- `scoria-drawer-shell` (outer drawer wrapper — also flagged in WR-03)
- `scoria-drawer__body`, `scoria-drawer__header-text`, `scoria-drawer__header-actions`
- `scoria-modal__body`
- `scoria-notebook__header`, `scoria-notebook__title`
- `scoria-skeleton-group` (no gap/spacing between stacked rows)
- `scoria-table-shell`, `scoria-table__filter`, `scoria-table__density-toggle`
- `scoria-table__pagination`, `scoria-table__page-label`, `scoria-table__td--actions`

Most are structural/layout helpers where missing CSS means default browser styling (block elements,
no explicit gaps). The most impactful absent definitions are the drawer ones (covered in WR-03), and
`scoria-skeleton-group` (skeleton rows have no gap/spacing between them).

**Fix:** Add minimal CSS definitions for each missing class. At minimum, add gap to skeleton group:
```css
.scoria-skeleton-group {
  display: flex;
  flex-direction: column;
  gap: var(--scoria-space-2);
}
```
And define the structural drawer/modal body/table layout classes as appropriate.

### IN-03: Toast JS.hide fade transition references undefined CSS classes

**File:** `lib/scoria_web/ui.ex:369, 374`
**Issue:** The `JS.hide` calls use `transition: {"scoria-fade", "opacity-100", "opacity-0"}`. The
`opacity-100` and `opacity-0` classes are Tailwind CSS utility classes that are not defined anywhere
in the library's own CSS (`assets/css/`). The `scoria-fade` string is an `@keyframes` name in
`05-motion.css`, not a CSS class. Host applications that do not include Tailwind will silently get an
instant hide (no animation) instead of a fade — functionally correct but not the designed behavior.
This creates an undocumented dependency on the host app's Tailwind installation.

**Fix:** Define the transition classes in the library's own CSS, or use a `scoria-` prefixed transition
class that does not rely on Tailwind:
```css
/* In 04-components.css or 06-utilities.css */
.scoria-fade-transition {
  transition: opacity var(--scoria-dur-fast) var(--scoria-ease-out);
}
.opacity-0 { opacity: 0; }
.opacity-100 { opacity: 1; }
```
Then update the JS.hide call to `transition: {"scoria-fade-transition", "opacity-100", "opacity-0"}`.

### IN-04: Test endpoint `secret_key_base` is exactly 64 characters — borderline for LiveView signing

**File:** `test/scoria_web/live/approvals_live_test.exs:60` / `test/scoria_web/live/workflow_live_test.exs:44`
**Issue:** Both test endpoints use the same `secret_key_base` value of exactly 64 characters
(`"uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1M"`). Per the project's own
MEMORY.md note: "LiveView test endpoints need a ≥64-char secret_key_base or the page 500s (masked as
missing ErrorView)." The value is exactly at the boundary, not above it. While this currently works,
it is fragile — any truncation (copy-paste, tooling, etc.) would produce a silent 500. Additionally,
both test modules share the identical key, which is fine for test isolation but worth noting.

**Fix:** Use a clearly over-length key (80+ chars) to have comfortable margin:
```elixir
secret_key_base: String.duplicate("scoria_test_key_", 5)  # 80 chars, obviously synthetic
```

---

_Reviewed: 2026-06-04T18:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
