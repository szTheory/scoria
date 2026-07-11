# Scoria dashboard design system — maintainer conventions

This guide is for **maintainers** touching `/scoria` dashboard UI. It documents
the conventions Phases 36–41 established for `ScoriaWeb.UI` primitives, their
CSS layer, and the fixture/proof harness — and, for each convention, names the
real test that enforces it today. It is dev/maintainer-only: it documents
`dev/lab/**`, `test/**`, and `assets/css/**` surfaces that never ship to Hex,
mirrors the sibling one-topic-per-file idiom of [Docker dev DX](docker_dev_dx.md)
and [UAT automation](uat_automation.md), and is intentionally **not** in ExDoc
`extras` or Hex `package.files` (`mix.exs`).

For the generated component API (attrs/slots), run `mix docs` and open
`doc/ScoriaWeb.UI.html` — that is the adopter-facing SSOT. This doc is the
maintainer-facing *why* and *what enforces it*.

Each section below follows one fixed shape: **Rule** (the convention) →
**SSOT** (where it lives in source) → **Guard** (the test that enforces it,
with its exact run command) → **Example** (one real snippet from the repo).
A convention with no dedicated enforcing guard says so plainly rather than
implying one exists.

## BEM & CSS selectors

**Rule:** Component classes are block/element/modifier (`.scoria-block`,
`.scoria-block__element`, `.scoria-block--modifier`); prefer inherited token
variables and block-scoped selectors over long structural chains reaching
through unrelated components.
**SSOT:** `assets/css/04-components.css` (class vocabulary); the convention
itself is documented in `guides/maintainers.md`'s "Design-system component
conventions" section.
**Guard:** No test asserts BEM structure directly — this is convention, guarded
only for palette leakage via the zero-tolerance raw-class ratchet:
`mix test test/scoria_web/ds06_drift_guard_test.exs`.
**Example:** `.scoria-table-shell--has-summary .scoria-table__viewport` — a
modifier-to-element selector accepted because that relationship *is* the
component's contract, per `guides/maintainers.md`.

## Tokens

**Rule:** All component color/contrast values flow from CSS custom properties
declared once per theme block, never hardcoded hex/rgb in component markup or
CSS declarations.
**SSOT:** `brandbook/tokens.json` (canonical) → `assets/css/02-tokens.css`
(dark `.scoria-root` block and light `.scoria-root[data-theme="light"]` block).
**Guard:** `mix test test/scoria_web/token_contrast_guard_test.exs` (WCAG AA
floor on semantic pairs, e.g. `--scoria-text`/`--scoria-surface-app` ≥ 4.5:1)
and `mix test test/scoria_web/toast_opacity_guard_test.exs` (opaque
`--scoria-toast-<tone>-bg` per theme, since `color-mix()` values can't be
resolved by the contrast guard).
**Example:** `--scoria-text-subtle` is repointed per-theme (dark → muted-warm,
light → graphite-700 primitive) so both themes clear 4.5:1 (`02-tokens.css`).

## Page headers

**Rule:** Every dashboard page renders exactly one sanctioned page-outline
header (`page_header/1`, `object_header/1`, or `stub_page/1`) — never zero,
never more than one — and no region title restates the page's own title.
**SSOT:** `lib/scoria_web/ui.ex` `page_header/1` (`:256`), `object_header/1`
(`:494`).
**Guard:** `mix test test/scoria_web/single_header_guard_test.exs` (static
source-scan: exactly-one-header + no raw `<h1>`) and
`mix test test/scoria_web/single_header_rendered_guard_test.exs` (rendered-DOM
Floki assertion across 9 static/index routes — the semantic-redundancy case a
source-scan structurally cannot see).
**Example:** `<div class="scoria-pagehead__title"><h1>{@title}</h1></div>`
(`ui.ex:258-263`); region titles render as `.scoria-panel__header h2` /
`.scoria-page-section__header h2`.

## Stats

**Rule:** Page-level operational summaries use `overview_stats/1` (label +
value + detail + tone); `metric/1` is for a single scalar analytic value with
an explicit delta, never a page overview. There is exactly one stat surface —
the legacy `signal_strip/1` was removed.
**SSOT:** `lib/scoria_web/ui.ex` `overview_stats/1` (`:306`), `metric/1`
(`:280`).
**Guard:** `mix test test/scoria_web/ui_component_test.exs` — describe block
"stat component singularity (DS-03/D-05/D-08)" (`:1609`) asserts
`signal_strip/1` is no longer exported and no `.scoria-signal` CSS class token
remains.
**Example:** `<dl class="scoria-overview-stats" aria-label={@label}>` wrapping
`.scoria-overview-stat--#{tone}` rows (`ui.ex:308-317`).

## Overlays

**Rule:** Every dialog surface (`modal/1`, `drawer/1`) pairs `role="dialog"`
with `aria-modal="true"`, traps focus on open via `focus_wrap`, and restores
focus to its trigger on close.
**SSOT:** `lib/scoria_web/ui.ex` `modal/1` (`:718`), `drawer/1` (`:806`) —
`phx-remove={JS.pop_focus()}` on the outer shell, `phx-mounted={JS.focus_first()}`
on `focus_wrap`.
**Guard:** `mix test test/scoria_web/a11y_structural_guard_test.exs` (static
`role="dialog"`/`aria-modal="true"` pairing, D-08(a)) plus the browser-proven
`mix scoria.ui.e2e` lane's `priv/dev/e2e/modal_focus.spec.mjs` and
`priv/dev/e2e/drawer_focus.spec.mjs` (trap + restore, both throwing).
**Example:** `<div class="scoria-modal__panel" role="dialog" aria-modal="true" ...>`
(`ui.ex:730-733`).

## Evidence & code

**Rule:** Tabbed evidence surfaces use `notebook/1` (tab/tabpanel roles, one
active tab always resolved); raw payloads render via `raw_evidence/1` with an
optional copy control, never a bare `<pre>`.
**SSOT:** `lib/scoria_web/ui.ex` `notebook/1` (`:1034`), `raw_evidence/1`
(`:1120`), plus `evidence_section/1`/`evidence_rows/1`/`evidence_action_row/1`/
`evidence_empty/1`.
**Guard:** `mix test test/scoria_web/ui_component_test.exs` — describe blocks
"notebook/1" (`:817`), "raw_evidence/1" (`:896`), and "evidence primitive CSS"
(`:1050`).
**Example:** a single-tab notebook renders a non-interactive
`.scoria-notebook__tab` span instead of an inert clickable button (`ui.ex`
WR-05 comment, `:1080-1083`).

## Copy controls

**Rule:** Every copyable value (`id/1`, `raw_evidence/1`'s copy affordance)
exposes a real accessible name (`aria-label="Copy <value>"`) and an
`aria-live="polite"` status announcement — never an icon-only control with no
text alternative — and copy icon buttons render at `:sm` scale, never `:md`.
**SSOT:** `lib/scoria_web/ui.ex` `id/1` (`:333`), `raw_evidence/1` copy button
(`:1120`).
**Guard:** `mix test test/scoria_web/ui_component_test.exs` — describe block
"copy controls (DS-02/DS-03/D-09/D-12)" (`:1631`), specifically the tests at
`:1632` (icon scale), `:1645` (accessible name), `:1657` (aria-live).
**Example:** `<span class="scoria-id" aria-label="Copy appr-9b1d4e2a" aria-live="polite">`.

## Fixtures

**Rule:** Dev-only stress fixtures live in one deterministic module, never
scattered ad hoc across LiveView tests or the seed script; every canonical
primitive/group inventory ID must appear referenced under `dev/lab/**`.
**SSOT:** `dev/lab/fixtures.ex` (`DevLab.Fixtures`, 15 scenarios across 8
domains) + `priv/repo/dev_seed.exs`.
**Guard:** `mix test test/scoria_web/dev_lab_boundary_test.exs` — the D-21
boundary scan (zero `lib/` → `DevLab.*` references, since `dev/` never
compiles under `:test` or a Hex install) plus the "Guard #7" inventory-ID
coverage floor.
**Example:** `dev/lab/sections/states.ex`'s `state_tone/1` embeds the shared
D-11 state vocabulary into every fixture's rendered tone.

## Motion

**Rule:** Every CSS transition and animation uses tokenized duration/easing
(`--scoria-dur-*`, `--scoria-ease-*`); `@keyframes` bodies animate only
transform/opacity (border-color is one documented exception); no
`transition: all`/`transition-property: all` anywhere; `@keyframes` at-rules
live in exactly one file.
**SSOT:** `assets/css/05-motion.css` (the only file allowed to declare
`@keyframes`).
**Guard:** `mix test test/scoria_web/motion_drift_guard_test.exs` (browserless
source-scan, 4 assertions) plus the browser-proven `mix scoria.ui.e2e` lane's
`priv/dev/e2e/reduced_motion.spec.mjs` (duration collapse under
`prefers-reduced-motion`).
**Example:** `scoria-skeleton-pulse` (opacity-only, D-20 exception) and
`scoria-approval-pulse` (`600ms`, border-color, D-21 exception) are both
allow-listed by animation **name**, not duration string, in the guard
(`05-motion.css:35-46`).

## Accessibility

**Rule:** Icon-only buttons carry an accessible name; status is never
color-only (every `<.badge>` supplies a text label); the horizontally
scrollable table viewport carries `tabindex="0"` and an `aria-label`; filter
controls and copy controls are real interactive elements, never a bare
clickable `<div>`.
**SSOT:** `lib/scoria_web/ui.ex` `icon_button/1` (`:139`), `badge/1`, and the
`.scoria-table__viewport` scroll region (`:1320`).
**Guard:** `mix test test/scoria_web/a11y_structural_guard_test.exs` — icon
accessible name (`:42`), no-color-only badge (`:59`), table viewport
`tabindex`+`aria-label` (`:116`) — plus the browser-proven `mix scoria.ui.e2e`
lane's `priv/dev/e2e/a11y_axe.spec.mjs` (axe-core WCAG 2.2 AA assert-zero on
all 7 seeded real pages, both themes).
**Example:** `<div class="scoria-table__viewport" tabindex="0" aria-label="Scrollable table content">`
(`ui.ex:1320`).

## Screenshot-proof + drift-guard roster

**Rule:** UI iteration is proven with a dated, human-reviewable 6-viewport
contact sheet — evidence a maintainer eyeballs, **never a CI pixel gate**
(blocking screenshot diffing is deferred; see `VISUAL-CI-01` in
`.planning/REQUIREMENTS.md`). PNGs/JSON/HTML are gitignored; the committed
proof-of-record is the markdown manifest.
**SSOT:** `priv/dev/shots.mjs` (capture, `SCREENS` matrix, 6 viewports),
`priv/dev/contact_sheet.mjs` (renderer), `priv/shots/contact_sheet_index.md`
(committed manifest).
**Guard:** No automated pixel-diff gates this section by design (D-13); the
capture commands themselves are `mix scoria.ui.shots` and
`mix scoria.ui.e2e` (the latter blocking). The full roster of blocking
browserless drift guards this doc names above:
`ds06_drift_guard_test.exs`, `token_contrast_guard_test.exs`,
`toast_opacity_guard_test.exs`, `single_header_guard_test.exs`,
`single_header_rendered_guard_test.exs`, `a11y_structural_guard_test.exs`,
`motion_drift_guard_test.exs`, `dev_lab_boundary_test.exs`,
`ui_component_test.exs`, and this doc's own
`design_system_doc_contract_test.exs`.
**Example:** `priv/shots/contact_sheet_index.md`'s dated baseline→final table
(mirrors the v3.0 `priv/shots/gap_register_final.md` precedent).
