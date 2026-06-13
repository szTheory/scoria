# Phase 16: Motion + responsive + theme parity - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 11 create/modify targets
**Analogs found:** 11 / 11 (all in-repo; this is a hardening sweep, not greenfield)

> Phase 16 touches an established design system. Almost every "new" surface is an
> extension of an existing scoped component (`ui.ex`), an existing CSS layer
> (`assets/css/*`), an existing JS hook (`assets/js/scoria.js`), or an existing
> Playwright spec. There are no truly novel file roles. The closest analog for each
> file is therefore the file itself (modify) or an immediate sibling (create).
> Planner should copy the established conventions rather than invent new ones.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria_web/components/layouts/app.html.heex` (modify) | layout/shell | request-response (SSR) | self + `command_palette`/shortcuts overlay in same file | exact |
| `assets/css/04-components.css` (modify) | config/CSS | n/a (static) | self — `.scoria-shell`, `.scoria-table`, `.scoria-drawer` blocks | exact |
| `assets/css/05-motion.css` (modify) | config/CSS | n/a (static) | self — `scoria-pop`/`scoria-slide`/reduced-motion guard | exact |
| `assets/css/06-utilities.css` (modify) | config/CSS | n/a (static) | self — `@media (min-width: …)` responsive grid block | exact |
| `assets/css/01-reset.css` (audit, maybe modify) | config/CSS | n/a (static) | self — `:where(:focus-visible)` rule | exact |
| `assets/js/scoria.js` (modify) | hook/JS | event-driven (browser) | self — `Hooks.CommandPalette` open/close/trap/restore | exact |
| `lib/scoria_web/ui.ex` `table/1` (modify) | component | CRUD/scan (SSR) | self — existing `table/1` + `drawer/1` slot conventions | exact |
| `lib/scoria_web/dashboard_nav.ex` (read-only SSOT) | data | n/a | self — `nav_groups/0` consumed, not duplicated | exact |
| `priv/dev/e2e/phase16_parity.spec.mjs` (create) | test | event-driven (browser) | `priv/dev/e2e/command_palette.spec.mjs`, `uat.spec.mjs` | role+flow match |
| `test/scoria_web/ui_component_test.exs` (modify) | test | request-response | self — `describe "table/1"`/`drawer/1` blocks | exact |
| `test/scoria_web/*contrast*_test.exs` (create, optional D-31) | test | transform/assert | `ui_drift_guard_test.exs`, `ds06_drift_guard_test.exs` | role match |
| evidence/notebook components (modify utilities) | component | transform (SSR) | each other; `06-utilities.css` named-class replacement | exact |

---

## Pattern Assignments

### `lib/scoria_web/components/layouts/app.html.heex` (shell, SSR) — add mobile topbar + nav drawer

**Analog:** self (the shortcuts overlay block, lines 61-127, is the in-repo model for an
accessible, scrim+escape+focus overlay rendered in this layout).

**Nav-group render pattern to reuse for the mobile drawer** (lines 7-21) — render from the
same `nav_groups()` SSOT, do NOT duplicate nav data (D-03):
```heex
<nav class="space-y-4" aria-label="Dashboard sections">
  <div :for={group <- nav_groups()} class="scoria-navgroup">
    <p class="scoria-navgroup__label">{group.label}</p>
    <.link
      :for={item <- group.items}
      navigate={(assigns[:scoria_base] || "") <> item.path}
      class="scoria-nav"
      aria-current={if item.key == assigns[:scoria_nav], do: "page"}
    >
      <.icon name={item.icon} />
      <span>{item.label}</span>
      <span :if={item[:soon?]} class="scoria-nav__soon">Soon</span>
    </.link>
  </div>
</nav>
```
Note: `:soon?` -> `Soon` badge must survive into the drawer (CONTEXT specifics).

**Overlay markup contract to copy for the mobile drawer** (lines 61-83) — same data-state +
hidden + scrim + panel(tabindex=-1) shape the shortcuts overlay already uses:
```heex
<div id="scoria-shortcuts" class="scoria-command" role="dialog" aria-modal="true"
     aria-labelledby="scoria-shortcuts-title" data-shortcuts-overlay data-state="closed" hidden>
  <div class="scoria-command__scrim" data-shortcuts-close aria-hidden="true"></div>
  <section class="scoria-command__panel" tabindex="-1" data-shortcuts-panel>
    <header class="scoria-command__header">
      <h2 id="scoria-shortcuts-title">Keyboard shortcuts</h2>
      <button type="button" class="scoria-button scoria-button--ghost scoria-button--sm"
              aria-label="Close keyboard shortcuts" data-shortcuts-close>
        <.kbd>Esc</.kbd>
      </button>
    </header>
    ...
  </section>
</div>
```
The mobile nav drawer should mirror this: `data-*` open/close hooks, a scrim element, a
focusable panel, and a visible close control. Copy from UI-SPEC: open button is
`Menu` with `aria-label="Open navigation"`; close is `Close navigation`.

**Topbar control pattern to reuse for mobile topbar buttons** (lines 30-53) — ghost buttons,
`data-command-open` for palette, `phx-hook="ThemeToggle"` id `scoria-theme-toggle` for theme:
```heex
<button id="scoria-command-open" type="button"
        class="scoria-button scoria-button--ghost scoria-button--sm"
        aria-label="Open command palette" aria-controls="scoria-command-palette" data-command-open>...</button>
<button type="button" class="scoria-button scoria-button--ghost scoria-button--sm"
        phx-hook="ThemeToggle" id="scoria-theme-toggle" aria-label="Toggle light or dark theme">...</button>
```
The mobile `Menu` button keeps the same ghost-button vocabulary and a 44px hit target
(UI-SPEC spacing exception). Do not introduce raw palette classes (D-27).

---

### `assets/css/04-components.css` (CSS) — mobile-first shell, table viewport, drawer slide

**Analog:** self. Three existing blocks are the patterns to extend.

**Shell grid to make mobile-first** (lines 7-45) — current desktop-first grid that pitfall #1
flags; Phase 16 makes single-column the default and restores this grid at `>=768px`:
```css
.scoria-shell {
  display: grid;
  grid-template-columns: 248px minmax(0, 1fr);
  grid-template-rows: auto 1fr;
  grid-template-areas: "sidebar topbar" "sidebar main";
  min-height: 100vh;
}
.scoria-sidebar { grid-area: sidebar; position: sticky; top: 0; height: 100vh; overflow-y: auto; }
.scoria-topbar  { grid-area: topbar; position: sticky; top: 0; z-index: var(--scoria-z-sticky); }
.scoria-main    { grid-area: main; padding: var(--scoria-space-6); max-width: 1280px; }
```
Restructure to: default = single column (hide `.scoria-sidebar`, show mobile topbar);
`@media (min-width: 768px)` = restore the two-column grid and hide the mobile topbar.
Existing breakpoint precedent for the `@media (min-width: 768px)` wrapper lives in
`06-utilities.css` lines 167-183.

**Table cell + sticky-header pattern to wrap in a viewport** (lines 545-564) — sticky `thead th`
already exists; the new `.scoria-table__viewport` must keep `position: sticky; top: 0` working
inside an `overflow-x: auto` container (D-13):
```css
.scoria-table thead th { position: sticky; top: 0; background: var(--scoria-surface-panel); ... }
.scoria-table tbody td { padding: var(--scoria-space-3); border-bottom: 1px solid var(--scoria-border); }
```
Table-shell wrapper conventions already present (line 1006): `.scoria-table-shell { display:flex; flex-direction:column; gap: var(--scoria-space-3); }` — add `.scoria-table__viewport { overflow-x: auto; }` plus the `tabindex="0"` keyboard-reachable behavior here.

**Drawer panel pattern for mobile nav drawer styling** (lines 593-621) — `.scoria-drawer-shell`
(fixed overlay) + `.scoria-drawer` (panel). The mobile nav drawer borrows this CSS lesson but
its transition must be transform/opacity only (D-04/D-18), never width/left/right.

**Hover transition convention to follow** (lines 85-96) — note it already animates only
`background-color`/`color`, never `all`; selected nav uses structure (`box-shadow: inset`) +
tone, not color alone:
```css
.scoria-nav { transition: background-color var(--scoria-dur-fast) var(--scoria-ease-out),
                          color var(--scoria-dur-fast) var(--scoria-ease-out); }
.scoria-nav[aria-current="page"] { background: var(--scoria-tone-brand-bg);
  color: var(--scoria-tone-brand-fg); box-shadow: inset 2px 0 0 var(--scoria-action); }
```

---

### `assets/css/05-motion.css` (CSS) — keyframes home, reduced-motion guard

**Analog:** self. This file is the ONLY allowed home for keyframes (D-16). New drawer slide
primitive (e.g. `scoria-slide-inline-end`) and any reuse of `scoria-pop`/`scoria-fade` go here.

**Existing named primitives to reuse / model** (lines 7-26) — transform/opacity-only, all
collapse under reduced motion:
```css
@keyframes scoria-fade { from { opacity: 0; } to { opacity: 1; } }
@keyframes scoria-pop  { from { opacity: 0; transform: translateY(6px) scale(0.985); }
                         to   { opacity: 1; transform: translateY(0) scale(1); } }
@keyframes scoria-slide { from { opacity: 0; transform: translateX(8px); }
                          to   { opacity: 1; transform: translateX(0); } }
```

**Allowlisted state-indicator exceptions to preserve** (lines 19-32) — attention pulse capped
at 2 cycles; skeleton pulse opacity-only (D-20/D-21):
```css
@keyframes scoria-approval-pulse { 0%,100% { border-color: var(--scoria-tone-warn-border); }
                                   50% { border-color: var(--scoria-tone-warn-fg); } }
.scoria-attention { animation: scoria-approval-pulse 600ms var(--scoria-ease-in-out) 2;
                    border: 1px solid var(--scoria-tone-warn-border); }
@keyframes scoria-skeleton-pulse { 0%,100% { opacity: 0.4; } 50% { opacity: 0.8; } }
```
D-21 note: if a strict motion guard is added, prefer outline/opacity/filter over the existing
border-color animation. The command-fade transition pattern (lines 39-51) is the model for the
mobile-drawer open/close (opacity via `data-state`), but the drawer adds a `transform` for the
edge-origin slide.

**Reduced-motion kill switch to keep authoritative** (lines 55-64) — unlayered so it wins;
Playwright reduced-motion checks assert against this:
```css
@media (prefers-reduced-motion: reduce) {
  .scoria-root *, .scoria-root *::before, .scoria-root *::after {
    animation-duration: 0.001ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.001ms !important;
    scroll-behavior: auto !important;
  }
}
```

---

### `assets/css/06-utilities.css` (CSS) — replace unsupported responsive utilities (D-12)

**Analog:** self. The supported responsive block (lines 166-183) defines exactly which
`md:`/`lg:`/`xl:` utilities exist. Arbitrary `grid-cols-[…]` and `sm:*` are NOT implemented:
```css
@media (min-width: 768px) {
  .scoria-root .md\:grid-cols-2 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .scoria-root .md\:grid-cols-3 { ... }
}
@media (min-width: 1024px) {
  .scoria-root .lg\:grid-cols-2 { ... }
  .scoria-root .lg\:flex-row { flex-direction: row; }
}
@media (min-width: 1280px) { .scoria-root .xl\:grid-cols-4 { ... } }
```
Two fix paths (both already used in this file): add a general token-bound utility here, OR
emit a named Scoria component class in `04-components.css`. Color-bearing utilities resolve to
semantic tokens (lines 120-143) — preserve that so DS-06 stays green.

**Callsites that use unsupported syntax** (must be replaced — these have NO matching CSS):
| File:line | Current class | Notes |
|-----------|---------------|-------|
| `lib/scoria_web/live/incidents_live/index.ex:67` | `grid gap-4 sm:grid-cols-3 mb-6` | `sm:` tier unsupported entirely |
| `lib/scoria_web/live/incidents_live/index.ex:73` | `grid gap-6 xl:grid-cols-[0.85fr,1.15fr]` | arbitrary cols unsupported |
| `lib/scoria_web/live/review_queue_live.ex:74` | `grid gap-6 lg:grid-cols-[minmax(0,1.05fr)_minmax(22rem,0.95fr)]` | arbitrary cols |
| `lib/scoria_web/live/workflow_live/show.ex:223` | `grid gap-6 lg:grid-cols-[minmax(0,1.2fr)_minmax(20rem,0.8fr)]` | arbitrary cols; D-11 stack target |
| `lib/scoria_web/components/incident_evidence_component.ex:57` | `grid gap-4 xl:grid-cols-[1.25fr,0.9fr]` | evidence grid |
| `lib/scoria_web/components/semantic_evidence_notebook_component.ex:22` | `grid gap-4 xl:grid-cols-[1.1fr,0.9fr]` | evidence grid |
| `lib/scoria_web/components/replay_evidence_notebook_component.ex:47` | `grid gap-4 xl:grid-cols-[1.25fr,0.9fr]` | comparison grid |

Precedent for a named two-column evidence/comparison class already exists in
`04-components.css:885` (`grid-template-columns: minmax(120px, 0.36fr) minmax(0, 1fr)`) — model
the replacement component classes on that.

---

### `assets/css/01-reset.css` (CSS) — focus-visible audit (D-23)

**Analog:** self (lines 64-68). The global rule exists; Phase 16 audits whether component
backgrounds/overflow clip it, and adjusts component CSS (not necessarily this file) so the ring
stays visible in both themes:
```css
.scoria-root :where(:focus-visible) {
  outline: 2px solid var(--scoria-focus-ring);
  outline-offset: 2px;
  border-radius: var(--scoria-radius-sm);
}
```
Token edits to `--scoria-focus-ring` are allowed only for a real WCAG defect (D-25). Prefer
fixing clipping at the `.scoria-table__viewport`/drawer overflow level.

---

### `assets/js/scoria.js` (JS hook) — mobile nav open/close/trap/restore

**Analog:** self — `Hooks.CommandPalette` is a complete, in-repo model for an accessible
overlay. RESEARCH open-question recommends reusing these helpers and adding a scoped hook only
if markup can't be expressed with them.

**Focusable-elements helper to reuse** (lines 104-113):
```js
function focusableElements(root) {
  return Array.prototype.filter.call(
    root.querySelectorAll(
      "a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex='-1'])"
    ),
    function (el) { return !el.hidden && el.getClientRects().length > 0; }
  );
}
```

**Open/close + restore-focus + hidden-delay pattern to copy** (lines 242-270) — note the
data-state flip drives the CSS fade, then `setTimeout(…120)` flips `hidden` so the fade can run
(D-19: JS owns delay only, not choreography):
```js
openPalette: function (opener) {
  this.restoreFocus = opener || document.activeElement;
  this.el.hidden = false;
  this.el.removeAttribute("aria-hidden");
  this.el.setAttribute("data-state", "open");
  if (this.input) this.input.focus({ preventScroll: true });
},
closePalette: function (restore) {
  var self = this;
  this.el.setAttribute("data-state", "closed");
  this.el.setAttribute("aria-hidden", "true");
  this.closeTimer = setTimeout(function () { self.el.hidden = true; }, 120);
  if (restore && this.restoreFocus && this.restoreFocus.focus)
    this.restoreFocus.focus({ preventScroll: true });
},
```

**Focus-trap helper to reuse verbatim** (lines 496-508):
```js
trapFocus: function (e, root) {
  var focusables = focusableElements(root);
  if (focusables.length === 0) return;
  var first = focusables[0], last = focusables[focusables.length - 1];
  if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
  else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
},
```

**Escape handling precedent** (lines 379-393) — document keydown closes topmost overlay; mobile
drawer should slot into the same Escape priority chain. Hook registration follows the
`Hooks.X = { mounted, destroyed }` shape (lines 40-69 `Dismissable`, 122-218 `CommandPalette`);
register listeners in `mounted`, remove them in `destroyed`. New hook is added to the `Hooks`
map before `new LiveSocket(...)` (lines 543-546).

---

### `lib/scoria_web/ui.ex` `table/1` (component, CRUD/scan) — overflow viewport + opt-in mobile summary

**Analog:** self (lines 904-992) for the table; `drawer/1` (lines 478-516) for slot-shell
conventions (typed `slot`, `render_slot`, ARIA, `:if` guards, raise-on-misuse).

**Current render shape to wrap** (lines 914-934) — wrap the `<table>` in `.scoria-table__viewport`
(tabindex=0, keyboard reachable per D-13) while preserving `scoria-table-shell`, filter slot,
density toggle, and sticky thead:
```heex
<div class="scoria-table-shell">
  <div :if={@filter != []} class="scoria-table__filter">{render_slot(@filter)}</div>
  <div :if={@on_density_change} class="scoria-table__density-toggle" role="group" aria-label="Row density">...</div>
  <table class={["scoria-table", density_class(@density)]} id={@id} {@rest}>
    <thead>...</thead>
    <tbody>...</tbody>
  </table>
</div>
```

**Slot + raise-on-misuse convention to follow for the new mobile-summary slot** (lines 876-912):
```elixir
slot :col, doc: "Table column" do
  attr(:label, :string, required: true)
  attr(:key, :atom)
  attr(:class, :string)
end
slot(:empty); slot(:action); slot(:filter)
...
def table(assigns) do
  if assigns.total_pages > 1 and is_nil(assigns.on_page_change) do
    raise ArgumentError, "<.table> with total_pages > 1 requires on_page_change; ..."
  end
```
Add `slot :mobile_summary` (per-row, opt-in) using the same typed-slot style. The summary
should be rendered in a sibling block hidden at `>=768px` and the `<table>` viewport hidden
below it on summary-enabled tables (D-08/D-10). Use `render_slot(@mobile_summary, row)`.

**Sort-state non-color-only pattern already present** (lines 944-970) — sort uses an SVG icon
that flips on `sort_dir` plus color; keep BOTH (D-24). Add accessible text/`aria-sort` if the
audit finds the icon alone is insufficient.

**Empty-state copy convention** (lines 976-985) — UI-SPEC supplies sharper per-domain headings
(`No runs match this view`, etc.) to thread through the `<:empty>` slot at callsites.

---

### `priv/dev/e2e/phase16_parity.spec.mjs` (test, browser truth) — CREATE

**Analog:** `priv/dev/e2e/command_palette.spec.mjs` (closest — focus/keyboard/viewport browser
truth) and `priv/dev/e2e/uat.spec.mjs` (overlay + seeded-fixture patterns).

**Spec scaffolding to copy** (command_palette.spec.mjs lines 1-43):
```js
import { test, expect } from '@playwright/test';
import { waitForReady } from './lib/ready.mjs';
const BASE = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:4000/scoria';
async function openHome(page) { await page.goto(BASE); await waitForReady(page); }
```

**Config facts the new spec inherits** (playwright.config.mjs) — `testMatch '**/*.spec.mjs'`
auto-includes the new file; single chromium project; no fixed sleeps, rely on `waitForReady` +
expect auto-wait; `retries: 2` only in CI.

**Per-test viewport/colorScheme/reducedMotion overrides** (from RESEARCH, supported by config):
```js
test.use({ viewport: { width: 375, height: 812 }, colorScheme: 'dark' });
// or per test:  await page.emulateMedia({ reducedMotion: 'reduce' });
```
Required coverage (D-29 / UI-SPEC verification): no page-level horizontal overflow at 375px on
shell + one table screen; visible focus outline on representative link/button/input/table
action/command item/mobile nav item; reduced-motion collapse on one drawer/modal path and one
skeleton/attention cue; theme-toggle smoke on Home/shell + one table + one evidence + one
overlay. Keep selectors stable and light; no screenshot comparisons in CI (D-30/D-32). Seeded-
fixture and serial/destructive conventions if needed: copy uat.spec.mjs lines 29-47.

---

### `test/scoria_web/ui_component_test.exs` (test) — MODIFY for new table API

**Analog:** self — existing `describe "table/..."`, `describe "drawer/1"` (line 312),
`describe "modal/1"` (line 219) blocks. Add assertions for the new `.scoria-table__viewport`
wrapper and the `mobile_summary` slot rendering. Match the existing `render_component`/Floki
assertion style (these are server-render truths; browser-only truths go to the Playwright spec).

---

### `test/scoria_web/*contrast*_test.exs` (test) — CREATE, OPTIONAL (D-31)

**Analog:** `test/scoria_web/ui_drift_guard_test.exs` and `ds06_drift_guard_test.exs` — both are
deterministic source/token guards that parse repo files. A token contrast guard must read pairs
from `assets/css/02-tokens.css` only (no parallel token source) and assert AA floors. Only build
it if it reuses the single token SSOT; otherwise skip per D-31.

---

## Shared Patterns

### Navigation SSOT (apply to: mobile drawer, any nav surface)
**Source:** `lib/scoria_web/dashboard_nav.ex` via `nav_groups/0`, consumed in
`app.html.heex:8`. Render mobile nav from this; never duplicate nav data (D-03, security:
prevents navigation spoofing).

### Accessible overlay contract (apply to: mobile nav drawer)
**Source:** `app.html.heex:61-127` (shortcuts overlay markup) + `scoria.js:242-508`
(`Hooks.CommandPalette` open/close/trap/restore). Contract: `role="dialog"` `aria-modal="true"`,
scrim element, focusable panel (`tabindex="-1"`), `data-state` open/closed driving CSS fade,
`hidden` toggled after a ~120ms delay, Escape + scrim-click dismiss, focus trap while open,
focus restore to opener.

### Reduced-motion safety (apply to: all new motion in 04/05-motion.css)
**Source:** `assets/css/05-motion.css:55-64`. Every transition/animation must collapse under
`prefers-reduced-motion: reduce`. Interaction motion is transform/opacity-only, <=200ms.

### Non-color-only status (apply to: tables, badges, selected rows, sort, nav)
**Source:** `ui.ex` badge (line 70, tone class + label text), table sort icon (lines 944-970),
nav `aria-current` + inset shadow (`04-components.css:92-96`). Always pair tone color with
text/icon/ARIA/structure (D-24, MOTION-02).

### Semantic-token-only color (apply to: all touched CSS/HEEx)
**Source:** `02-tokens.css` SSOT; `06-utilities.css:120-143` maps legacy palette classes to
tokens. No raw hex, no primitive palette tokens, no new raw Tailwind palette classes under
`lib/scoria_web/`. DS-06 ratchet (`ds06_drift_guard_test.exs`) and `ui.ex` zero-raw-palette
assertion enforce this (D-27).

### Scoped-everything (apply to: all CSS/JS)
**Source:** `01-reset.css:5` (`@layer scoria.reset`, `.scoria-root` scope) and `scoria.js`
(self-contained LiveSocket, hooks scoped to dashboard). No global reset, no Tailwind runtime,
no new JS framework, mount-prefix-safe paths (`assigns[:scoria_base]`) (D-34).

### LiveView hook lifecycle (apply to: any new JS hook)
**Source:** `scoria.js` `Hooks.Dismissable` (40-69) and `Hooks.ThemeToggle` (40-52). Shape:
`{ mounted: fn, destroyed: fn }`; add to `Hooks` map before `new LiveSocket(...)` (543-546);
register listeners in `mounted`, remove in `destroyed`.

---

## No Analog Found

None. Every Phase 16 surface extends an existing component, CSS layer, JS hook, or spec. The
only genuinely new files (`phase16_parity.spec.mjs`, optional contrast guard) have strong
sibling analogs in `priv/dev/e2e/` and `test/scoria_web/` respectively.

---

## Metadata

**Analog search scope:** `lib/scoria_web/` (layouts, ui.ex, dashboard_nav, live/*, components/*),
`assets/css/*.css`, `assets/js/scoria.js`, `priv/dev/e2e/*`, `test/scoria_web/*`.
**Files scanned:** ~16 read in full or targeted; full repo grep for unsupported responsive
utilities and component definitions.
**Pattern extraction date:** 2026-06-13
**Project skills:** none found (`.claude/skills`, `.agents/skills` absent). No root `CLAUDE.md`.
