# Phase 38: Foundations And Primitive Controls - Context

**Gathered:** 2026-07-02
**Status:** Ready for planning

> **⚠ Auto-decided (revise before planning if desired).** The user stepped away during the
> discussion, so the four gray areas below were resolved with **recommended design-system
> defaults** grounded in the existing tokens, `ScoriaWeb.UI`, and Phase 36/37 decisions. Each
> decision is a concrete choice a downstream agent can act on, but none is a hard user mandate.
> If the user wants to steer toast look, copy affordance, stat anatomy, or the size scale
> differently, re-run `/gsd-discuss-phase 38` (choose "Update it") before `/gsd-plan-phase 38`.

<domain>
## Phase Boundary

Phase 38 tightens Scoria's **shared foundations and primitive controls** in `ScoriaWeb.UI`
and the token/component CSS layers so buttons, icon buttons, copy controls, links, badges, IDs,
timestamps, metadata rows, raw evidence/code blocks, panels, drawers, modals, toasts, forms,
tables, and lists speak **one consistent design-system language** — before Phase 39 rebuilds
page-level operator flows on top of them.

This is a foundations-and-primitives phase. It changes shared components and tokens, not page
flows, not new capabilities. In scope: coherent sizes/spacing/variants/focus-states/accessible-
names across primitives; converging overview stats + signal summaries onto one reusable pattern;
fixing approval warning/error **toast legibility** over dense UI in light and dark; and regression
tests for the four named defects (density controls, oversized copy icons, transparent unreadable
toasts, inconsistent stats).

**Out of scope (deferred, do not pull in):**
- Page orientation, section conventions, approval-drawer decision-first redesign → **Phase 39**.
- Approval **decision history** discoverability (`RISK-APPROVAL-HISTORY`) → **Phase 39**.
- Keyboard/focus-order audits, WCAG 2.2 AA sweep, motion/reduced-motion proof, responsive
  320–1440 proof (`RISK-RESPONSIVE-SCAN`, `RISK-OVERLAY-FOCUS`, `MOTION-01`, `RESP-01`) → **Phase 40**.
- Screenshot-diff CI (`VISUAL-CI-01`) and PhoenixStorybook adoption (`STORYBOOK-01`) → later/deferred.
- Any change to the public `scoria_dashboard/2` macro, Hex `package.files`, or `.scoria-root` scoping.

</domain>

<decisions>
## Implementation Decisions

Requirements DS-01..DS-04 and the five Phase 38 success criteria are the locked spec. The
decisions below resolve *how* to implement them where the criteria leave room.

### Toast & Flash Legibility (Criterion 4 · DS-04 · RISK-TOAST-LEGIBILITY)

**Problem (verified in code):** `assets/css/02-tokens.css` defines tone backgrounds as
translucent tints — `--scoria-tone-warn-bg: color-mix(... 14%, transparent)`,
`--scoria-tone-fail-bg: color-mix(... 14%, transparent)`, `--scoria-tone-neutral-bg: rgba(..., 0.06–0.07)`.
`.scoria-toast` and `.scoria-flash` (`04-components.css`) render those tints directly, so a
warning/error toast over the dense approvals table shows page content bleeding through and fails
legibility — the "transparent unreadable toasts" defect.

- **D-01:** A **toast must render on an opaque surface**. The toast body background composites the
  tone tint over a solid `--scoria-surface`/`--scoria-panel` base (i.e. an opaque token, not a
  transparent `color-mix`), so no underlying dense UI shows through. Status is still conveyed by
  the tone (border + optional leading status dot/icon + text), but readability no longer depends
  on what is behind it. Keep the existing `--scoria-shadow-raised` for elevation.
- **D-02:** Prefer introducing **opaque toast-specific tone tokens** (e.g. a
  `--scoria-toast-<tone>-bg/-fg/-border` set, or a solid-surface + tone-accent composition) rather
  than mutating the shared `--scoria-tone-*-bg` tints — those translucent tints are correct for
  inline banners/badges *inside* the page and should not lose their subtlety. Toasts float over
  arbitrary content and need their own opaque treatment. Downstream agent picks the exact token
  shape; the invariant is "opaque under the toast."
- **D-03:** Apply the same opacity fix to `.scoria-flash` **only where a flash floats over content**;
  in-flow flash banners inside a page may keep tinted backgrounds. If the distinction is fuzzy,
  default flashes to the opaque treatment too — legibility wins over subtlety for status messaging.
- **D-04:** Must hold in **both light and dark** and preserve existing token-contrast guards
  (`token_contrast_guard_test.exs`). Verify the fix against the Component Lab dense-approvals +
  toast-overlay stress fixture from Phase 37 (`RISK-TOAST-LEGIBILITY` probe), not a blank page.

### Stats Convergence (Criterion 3 · DS-03)

**Problem (verified in code):** `ScoriaWeb.UI` ships **three** overlapping stat components —
`metric/1` (label + big value + delta), `overview_stats/1` (`<dl>` of label/value/detail/tone),
and `signal_strip/1` (a near-identical `<dl>` of label/value/detail/tone). `overview_stats` and
`signal_strip` are essentially duplicates with different class names — the "inconsistent stats" defect.

- **D-05:** Converge on **one canonical stat/summary component**. `overview_stats/1` and
  `signal_strip/1` collapse into a single component (recommended canonical name: **`overview_stats/1`**,
  since it is the more descriptive/self-documenting name and both share the `<dl>` label/value/detail/tone
  anatomy). `signal_strip/1` becomes either (a) removed with call sites migrated, or (b) a thin
  deprecated alias delegating to the canonical component — downstream agent's choice, but there must
  be exactly **one implementation**.
- **D-06:** Canonical stat anatomy stays: **label · value · optional detail slot · tone** (semantic
  tone tint from the existing `:neutral/:pass/:info/:warn/:fail/:trace/:brand` vocabulary). This
  matches the current `overview_stats` slot contract, so most call sites need only a rename.
- **D-07:** Keep **`metric/1` distinct** — it is the single-big-number-with-explicit-delta card
  ("never a magic score", brand book §11.3) and serves a different job than a multi-stat summary row.
  Do not fold `metric/1` into the stat component; just ensure its visual language (spacing, label
  typography, tone) is coherent with the converged component.
- **D-08:** Migrate all call sites of the removed/aliased component in this phase so no page still
  emits the legacy `.scoria-signal*` classes. A regression test asserts there is one canonical stat
  component and (if kept) the alias only delegates.

### Copy-Control Affordance (Criterion 2/5 · DS-02/DS-03)

**Problem (verified in code):** copy affordances are spread across `id/1` (CopyId hook on a
`.scoria-id` span), `raw_evidence` (`copyable` + `copy_label`), and icon buttons that carry the
copy glyph via `scoria-button--icon-#{size}`. The "oversized copy icons" defect is the glyph/target
size drifting large and inconsistent across these.

- **D-09:** Copy controls use **one canonical icon size = the `:sm` icon-button scale** for inline/
  utility copy affordances (copy an ID, copy raw evidence, copy a payload). `icon_button` already
  distinguishes `:md` chrome controls from `:sm` inline utilities — copy is always an inline utility,
  so it renders at `:sm`. A token/utility caps the copy glyph so it can't render oversized.
- **D-10:** **Reveal behavior:** copy affordances are **always visible** (not hover-only), because
  the operator dashboard is used keyboard-first and hover-reveal hides affordances from touch and
  keyboard users. They render at low visual weight (ghost variant) so they don't compete with primary
  actions. (Full keyboard/focus proof is Phase 40; this phase just must not make copy hover-only.)
- **D-11:** **Copy feedback:** prefer a **lightweight inline confirmation** (transient "Copied"
  state on the control itself via the existing CopyId hook / `aria-live="polite"` already on
  `.scoria-id`) over spawning a toast for every copy. Reserve toasts for consequential/async events,
  not routine copies. Downstream agent may keep the current hook behavior if it already does inline
  feedback; the invariant is "routine copy ≠ toast spam."
- **D-12:** Every copy control has an **accessible name** ("Copy <thing>", e.g. `Copy raw evidence`,
  `Copy run ID`) — never an unlabeled icon. `raw_evidence` already has `copy_label`; extend the same
  discipline to all copy affordances.

### Size & Density Scale (Criterion 2/5 · DS-02)

**Problem (verified in code):** `button/1` and `icon_button/1` expose a **two-size scale**
(`:md` default, `:sm`). Fields, badges, and inline controls need to sit coherently against that
scale. The "density controls" the tests must protect are the compact/comfortable spacing rhythm of
tables/lists and inline controls, not a user-facing density toggle.

- **D-13:** **Keep the two-tier size scale** (`:md` comfortable default, `:sm` compact). Do **not**
  introduce a third `:lg`/`:xs` size in this phase — a two-tier scale is sufficient and adding tiers
  invites drift. Any control currently rendering at an ad-hoc size migrates onto `:md` or `:sm`.
- **D-14:** **Default density is comfortable (`:md`).** Compact (`:sm`) is used for inline utilities
  (copy controls, in-cell actions, table toolbars, badge-adjacent buttons) and dense table/list rows.
  Spacing comes from the existing `--scoria-space-*` tokens — no page-local pixel values.
- **D-15:** **Focus states are token-bound and uniform** across buttons, icon buttons, links, fields,
  and copy controls — one visible focus ring treatment from the existing focus tokens, not per-
  component variation. (Focus-*order*/trap/restore proof is Phase 40; this phase ensures the focus
  *style* is consistent and present.)
- **D-16:** **Disabled and loading states** are consistent primitives across controls: disabled uses
  the existing reduced-opacity + non-interactive treatment; loading uses the existing skeleton/spinner
  token language and is reduced-motion-safe. No new motion language invented here (that's Phase 40).

### Regression Tests (Criterion 5)

- **D-17:** Add or extend focused tests that guard each named defect so Phase 39+ can't silently
  regress it: (a) **toast/flash opacity** — assert toast tone backgrounds resolve to an opaque
  surface, not a `transparent`-composited tint; (b) **copy icon size** — assert copy controls use the
  `:sm` icon scale / capped glyph, no oversized variant; (c) **stat convergence** — assert one
  canonical stat component and no lingering legacy `.scoria-signal*` emission from pages; (d) **density**
  — assert controls use the two-tier `:md/:sm` scale and token spacing, no ad-hoc sizes.
- **D-18:** **Do not weaken existing guards.** DS-06 raw-palette drift guard (`ds06_drift_guard_test.exs`)
  and `token_contrast_guard_test.exs` must stay green — Criterion 1. New tokens must be semantic and
  routed through `.scoria-root`; raw-palette count stays a verified zero.
- **D-19:** Prove primitive coverage against the **Phase 37 Component Lab** stress fixtures rather
  than bespoke test scaffolding where practical — the lab already renders these primitives across
  state/theme/viewport/ugly-data and is the intended proof surface for this phase.

### Claude's Discretion

Downstream agents choose exact new token names, whether the converged stat component removes or
aliases `signal_strip`, the precise copy-glyph sizing mechanism, and test file placement — as long
as D-01..D-19 hold. Prefer boring, minimal token additions and small, explicit tests over a new
abstraction layer. Do not expand the size/tone/state vocabularies locked in Phases 36/37.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase & Milestone Scope
- `.planning/ROADMAP.md` — Phase 38 goal + 5 success criteria; Phase 39/40 boundaries.
- `.planning/REQUIREMENTS.md` — DS-01, DS-02, DS-03, DS-04 (and the FLOW/A11Y/MOTION/RESP reqs owned by 39/40).
- `.planning/PROJECT.md` — Scoria posture and v3.3 Design System Stress Test milestone intent ("under-adopted, not under-built").
- `.planning/STATE.md` — current phase position and deferred items.
- `.planning/phases/36-baseline-and-inventory/36-CONTEXT.md` — locked inventory, design-system, and risk decisions.
- `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md` — human-readable inventory + risk register (`RISK-TOAST-LEGIBILITY` = Phase 38).
- `.planning/phases/36-baseline-and-inventory/36-inventory.json` — canonical inventory row IDs, statuses, risk refs, coverage enums.
- `.planning/phases/37-dev-component-lab-and-stress-fixtures/37-CONTEXT.md` — Component Lab boundary, state/tone vocabulary, fixture ownership, and the dense-approvals/toast-overlay stress probe this phase proves against.

### Brand & Token Source of Truth
- `brandbook/brand-book.md` — canonical voice/UI/microcopy; §8.5 buttons, §11.3 metric "never a magic score".
- `brandbook/tokens.json` / `brandbook/tokens.css` — semantic/raw token references; runtime hexes must stay consistent.
- `brandbook/README.md` — token SSOT ownership rules.

### Runtime UI, Tokens, Components, Tests (the surface Phase 38 edits)
- `lib/scoria_web/ui.ex` — `ScoriaWeb.UI` primitive vocabulary; the home for `button/1`, `icon_button/1`, `badge/1`, `overview_stats/1`, `signal_strip/1`, `metric/1`, `id/1`, `time/1`, `toast/1`, `flash_group/1`, `panel/1`, `drawer/1`, `modal/1`, `field/1`, `table/1`, `raw_evidence`.
- `assets/css/02-tokens.css` — token SSOT; the translucent `--scoria-tone-*-bg` values behind the toast-legibility defect (lines ~131–212).
- `assets/css/04-components.css` — `.scoria-toast`, `.scoria-toast-region`, `.scoria-flash`, and structural component CSS (toast rules ~1694–1735, flash ~1667–1683).
- `assets/css/05-motion.css` — motion/reduced-motion tokens (do not extend here; Phase 40 owns motion).
- `assets/js/scoria.js` — CopyId, theme, dismissable overlay, command palette hooks (copy feedback lives here).
- `test/scoria_web/ds06_drift_guard_test.exs` — raw-palette zero-drift guard (Criterion 1; must stay green).
- `test/scoria_web/token_contrast_guard_test.exs` — token contrast proof (must stay green; toast fix must satisfy).
- `test/scoria_web/ui_component_test.exs` — existing component proof surface to extend with the four defect guards.

### Component Lab Proof Surface (Phase 37 output)
- `dev/` lab LiveViews + `ScoriaWeb.DevRouter` mount of `/scoria/_lab` — renders primitives across state/theme/viewport/ugly-data.
- `priv/dev/e2e/` + `priv/dev/lab.spec.mjs` — deterministic lab browser proof to reuse for Phase 38 legibility/stat checks.
- `docs/MAINTAINERS.md` — maintainer proof + design-system docs to keep in sync.

### External Precedent
- `https://www.w3.org/WAI/WCAG22/Understanding/` — WCAG 2.2 AA intent for accessible names / contrast (full sweep is Phase 40; names/contrast start here).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ScoriaWeb.UI` already owns every primitive this phase tightens — the work is editing existing
  function components + their CSS, not adding new ones (except possibly opaque toast tokens).
- `overview_stats/1` and `signal_strip/1` share an identical `<dl>` label/value/detail/tone slot
  contract — convergence is largely a rename + call-site migration, low risk.
- The semantic tone system (`tone/1`, `:neutral/:pass/:info/:warn/:fail/:trace/:brand`) is the single
  source of truth for status color; toast/stat tones reuse it.
- Phase 37 Component Lab + dev fixtures are the intended stress surface — reuse, don't rebuild.

### Established Patterns
- Token-first CSS scoped through `.scoria-root`; raw-palette drift is a guarded, verified zero (DS-06).
- `attr`/`slot` function components are the reusable primitive shape.
- Two-tier control size scale (`:md`/`:sm`) already exists on `button/1` and `icon_button/1`.
- Toasts flow inside a fixed `.scoria-toast-region` (CR-01); individual toasts are not `position:fixed`.

### Integration Points
- Edit `ScoriaWeb.UI` components in `lib/scoria_web/ui.ex`.
- Add/adjust tokens in `assets/css/02-tokens.css`; component rules in `assets/css/04-components.css`.
- Copy feedback via existing hooks in `assets/js/scoria.js`.
- Guards extend `test/scoria_web/ui_component_test.exs`; must not break `ds06_drift_guard_test.exs`
  or `token_contrast_guard_test.exs`.
- Prove against `dev/` lab routes + `priv/dev/e2e/`.

</code_context>

<specifics>
## Specific Ideas

- Named defects to eliminate (Criterion 5): **transparent unreadable toasts**, **oversized copy
  icons**, **inconsistent stats**, **density-control regressions**. Each gets a regression guard.
- Toast fix invariant: **opaque under the toast** in light AND dark; prove against the dense-
  approvals + toast-overlay lab fixture, not a blank page.
- Stats fix invariant: **exactly one** canonical stat/summary component (recommended `overview_stats/1`);
  `metric/1` stays distinct.
- Copy fix invariant: `:sm` icon scale, always-visible, inline confirmation (not toast-per-copy),
  accessible name on every copy control.
- Size/density invariant: keep the two-tier `:md/:sm` scale, comfortable default, token spacing, no
  ad-hoc sizes, uniform token-bound focus/disabled/loading states.

</specifics>

<deferred>
## Deferred Ideas

- **Approval decision history** (`RISK-APPROVAL-HISTORY`) — Phase 39.
- **Approval drawer decision-first redesign** and page-flow/orientation work — Phase 39.
- **Keyboard focus order / trap / restore, WCAG 2.2 AA sweep, motion + reduced-motion proof,
  responsive 320–1440 proof** (`RISK-RESPONSIVE-SCAN`, `RISK-OVERLAY-FOCUS`, MOTION-01, RESP-01) — Phase 40.
- **Screenshot-diff CI** (`VISUAL-CI-01`) and **PhoenixStorybook** (`STORYBOOK-01`) — deferred/later.
- A third control size tier (`:lg`/`:xs`) — intentionally not added; revisit only if a real need appears.

### Reviewed Todos (not folded)
None — discussion stayed within phase scope.

</deferred>

---

*Phase: 38-Foundations And Primitive Controls*
*Context gathered: 2026-07-02*
