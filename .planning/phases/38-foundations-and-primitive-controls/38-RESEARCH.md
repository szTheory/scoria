# Phase 38: Foundations And Primitive Controls - Research

**Researched:** 2026-07-02
**Domain:** Design-system token/CSS composition + Phoenix.Component primitives (ScoriaWeb.UI)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Requirements DS-01..DS-04 and the five Phase 38 success criteria are the locked spec. The
decisions below resolve *how* to implement them where the criteria leave room.

**Toast & Flash Legibility (Criterion 4 · DS-04 · RISK-TOAST-LEGIBILITY)**

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

**Stats Convergence (Criterion 3 · DS-03)**

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

**Copy-Control Affordance (Criterion 2/5 · DS-02/DS-03)**

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

**Size & Density Scale (Criterion 2/5 · DS-02)**

- **D-13:** **Keep the two-tier size scale** (`:md` comfortable default, `:sm`). Do **not**
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

**Regression Tests (Criterion 5)**

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

### Deferred Ideas (OUT OF SCOPE)

- **Approval decision history** (`RISK-APPROVAL-HISTORY`) — Phase 39.
- **Approval drawer decision-first redesign** and page-flow/orientation work — Phase 39.
- **Keyboard focus order / trap / restore, WCAG 2.2 AA sweep, motion + reduced-motion proof,
  responsive 320–1440 proof** (`RISK-RESPONSIVE-SCAN`, `RISK-OVERLAY-FOCUS`, MOTION-01, RESP-01) — Phase 40.
- **Screenshot-diff CI** (`VISUAL-CI-01`) and **PhoenixStorybook** (`STORYBOOK-01`) — deferred/later.
- A third control size tier (`:lg`/`:xs`) — intentionally not added; revisit only if a real need appears.
- No change to the public `scoria_dashboard/2` macro, Hex `package.files`, or `.scoria-root` scoping.

**Reviewed Todos (not folded):** None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DS-01 | Operator-facing UI uses semantic tokens for color, surface, text, border, focus, status, code, overlay, and motion; raw palette or page-local style drift remains guarded. | New `--scoria-toast-<tone>-bg/-fg/-border` tokens are semantic, `.scoria-root`-scoped, and derived from existing primitives via `color-mix()`/`var()` (Pattern 1). `ds06_drift_guard_test.exs`'s zero-tolerance rule on `ui.ex` and the ratchet on the rest of `lib/scoria_web/` are unaffected (Pitfall 4) — no new raw palette or raw hex introduced. |
| DS-02 | Shared primitive controls have consistent variants, sizes, spacing, icons, focus states, disabled states, loading states, accessible names, and reduced-motion-safe feedback. | Verified: uniform focus ring already global (`01-reset.css:64-68`); uniform disabled/loading already via shared `.scoria-button:disabled` + `phx-disable-with` (Don't Hand-Roll); copy-icon size ceiling already correctly applied at the one real call site, needs only a regression guard (Pattern 3); accessible-name gaps identified and fixed for both copy affordances (Pitfalls 2/3). |
| DS-03 | Overview stats, signal summaries, metadata rows, raw evidence/code blocks, IDs, copy controls, timestamps, badges, buttons, icon buttons, links, panels, drawers, modals, toasts, forms, tables, and lists use one coherent design-system language. | Stat convergence is a deletion, not a migration (Pattern 2, zero `signal_strip` call sites verified). All other primitives listed already share one `ScoriaWeb.UI` implementation each; this phase's edits (toast tokens, copy a11y, stat deletion, regression tests) close the remaining gaps without adding new component variants. |
| DS-04 | Approval toasts remain readable over dense UI in light and dark themes. | Direct focus of Pattern 1 / Pitfall 1 / Validation Architecture — new opaque toast tokens plus a CSS-source regression test plus an extended Playwright assertion against the existing Phase 37 dense-approvals + toast-overlay fixture (`dev/lab/sections/overlays.ex`, `priv/dev/e2e/lab.spec.mjs`). |

</phase_requirements>

## Summary

Phase 38 is smaller and lower-risk than its five success criteria suggest, because most of the
"convergence" work the CONTEXT anticipated is **already structurally in place** or **already dead
code**. Concretely: `overview_stats/1` and `signal_strip/1` are already CSS-unified via comma-joined
selectors in `assets/css/04-components.css` (`.scoria-overview-stat, .scoria-signal { ... }`), and
`signal_strip/1` has **zero call sites anywhere in the codebase** — it isn't even listed in
`docs/MAINTAINERS.md`'s component table. Convergence is therefore a straight deletion (or a one-line
deprecated alias), not a call-site migration. Similarly, the copy-icon sizing defect (D-09) is not
currently visible in code — `raw_evidence/1`'s copy `icon_button` already renders at `size={:sm}`
and `.scoria-button--icon-sm svg { width: 0.875rem; height: 0.875rem }` already caps it — but there
is **no regression guard** preventing a future call site from using `size={:md}` for a copy
affordance, which is exactly what D-17(b) must add. The genuinely hard problem is the toast/flash
opacity fix (D-01–D-04): `--scoria-tone-*-bg` tokens are `color-mix(..., transparent)` formulas that
the project's own `token_contrast_guard_test.exs` **cannot parse** (it explicitly skips any
`color-mix()` declaration), so the new opaque toast tokens must either (a) stay unresolvable by that
guard and be verified by a new, simpler CSS-source-pattern test (recommended — matches the DS-06
guard's own style), or (b) be hardcoded to literal per-theme hex values to make them WCAG-verifiable,
which pulls in the `brandbook/tokens.css`/`tokens.json` parity-checker obligation. Recommendation:
(a).

**Primary recommendation:** Add `--scoria-toast-<tone>-bg` tokens defined as opaque
`color-mix(in srgb, var(--scoria-tone-<tone>-fg) N%, var(--scoria-surface-panel-raised))` (never
mixing toward `transparent`) for both themes; delete `signal_strip/1` and its CSS (no call sites to
migrate); add one new focused test file with four regression assertions (toast opacity,
copy-icon-size ceiling, stat-component singularity, density-scale conformance) proven against the
existing Phase 37 `dev/lab/sections/overlays.ex` dense-approvals+toast fixture and
`priv/dev/e2e/lab.spec.mjs`; leave `token_contrast_guard_test.exs` and `ds06_drift_guard_test.exs`
untouched except for adding the new opaque tokens to the drift guard's semantic-token vocabulary (no
new raw palette/hex).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Token definitions (opacity, tone, size) | CSS token layer (`02-tokens.css`) | — | Single semantic-token SSOT; components must not override colors inline (established pattern, `lib/scoria_web/ui.ex` moduledoc). |
| Component structural CSS (button/badge/toast/stat layout) | CSS component layer (`04-components.css`) | — | BEM class rules consume tokens; no page-local pixel values (D-14). |
| Primitive markup/attrs (button, icon_button, toast, overview_stats, id, raw_evidence) | `ScoriaWeb.UI` (Phoenix function components) | — | Single home for primitive vocabulary; this phase edits existing functions, does not add new files. |
| Copy interaction behavior (click→clipboard, transient state swap) | Browser/JS hook layer (`assets/js/scoria.js`) | `ScoriaWeb.UI` (renders `aria-live`/data attrs the hook reads) | Hooks own DOM-level clipboard writes and transient class toggles; components only render the hook contract (ids, data attrs, aria-live regions). |
| Regression proof | ExUnit (`test/scoria_web/*_test.exs`) | Phase 37 Component Lab + Playwright (`priv/dev/e2e/lab.spec.mjs`) | Static assertions (ExUnit, CSS/HTML string matching) catch token/markup regressions cheaply; the Lab probe proves the fix renders correctly in a real dense-UI+toast-overlay browser scenario (D-19). |
| Page-level call sites (approvals/incidents/review/dataset/prompt LiveViews) | Out of scope this phase | Phase 39 | These call `overview_stats`/`id`/`raw_evidence` today; Phase 38 only touches the primitives + already-existing call sites incidentally affected by the `signal_strip` deletion (none exist) and any ad-hoc-size migration (D-13). |

## Standard Stack

This phase adds no new runtime dependencies, packages, or libraries. It edits existing first-party
code: `lib/scoria_web/ui.ex` (Phoenix.Component), `assets/css/02-tokens.css` /
`assets/css/04-components.css` (plain CSS, no preprocessor), and `assets/js/scoria.js` (vanilla JS
hooks, no bundler — confirmed by the file's own header comment "No bundler required — the library
ships its own self-contained LiveSocket + hooks"). No `mix.exs` or `package.json` changes are
expected.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix.Component | (project's existing Phoenix/LiveView pin) | `attr`/`slot` function components | Already the established primitive shape across `ui.ex`; no alternative considered. |
| CSS `@layer` + custom properties | native browser feature | token/component layering | Already established (`02-tokens.css`, `04-components.css` use `@layer scoria.tokens`/`scoria.components`). |
| CSS `color-mix()` | native (Baseline-widely-available) | composing tone tints and the new opaque toast surface | Already used throughout `02-tokens.css` for every existing tone token; this is the established idiom, not a new technique. |

### Supporting
None — no new supporting libraries needed.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Opaque `color-mix()` toast tokens (2 args: tone color into a solid surface) | Literal precomputed hex per tone/theme | Hex enables `token_contrast_guard_test.exs`'s existing WCAG-math resolver to verify automatically, but requires manual color computation, duplicated maintenance in `brandbook/tokens.css`/`tokens.json` (parity checker `node brandbook/tools/check-consistency.mjs`), and drifts from the "opaque under the toast" *intent* (a formula) into a magic constant. Rejected as non-boring for this phase; `color-mix()` keeps the same derivation pattern as every other tone token. |
| Deleting `signal_strip/1` outright | Thin deprecated alias (`def signal_strip(assigns), do: overview_stats(assigns)` with slot-name shim) | Alias adds a compatibility shim for zero known callers — pure risk-aversion with no current benefit. Deletion is simpler and D-05 explicitly permits either; recommend deletion since a slot-name-changing alias (`:signal` slot → `:stat` slot) can't be a bare pass-through anyway (see Don't Hand-Roll below) and there is nothing to preserve compatibility for. |
| New CSS-source-pattern regression test for toast opacity | Extending `token_contrast_guard_test.exs`'s `@checked_pairs` list | The guard's `resolve_token/3` explicitly returns `nil` — and the calling `assert_pairs/3` **flunks** (not skips) — for any token whose declaration starts with `color-mix(` (see `parse_declarations/1`, `token_contrast_guard_test.exs:167-179` and `is_nil(fg_hex) -> flunk(...)` at `token_contrast_guard_test.exs:78`). Adding a `color-mix()`-defined toast pair to `@checked_pairs` would make the guard fail immediately, not verify contrast. A new lightweight test (regex/string assertion on the CSS source, matching the `ds06_drift_guard_test.exs` style) is the correct mechanism. |

**Installation:** N/A — no new packages.

**Version verification:** N/A — no package versions to verify (first-party code only).

## Package Legitimacy Audit

Not applicable. This phase installs no external packages (no `mix.exs` dependency changes, no
`package.json` changes). Skipping the Package Legitimacy Gate per its own scope condition.

## Architecture Patterns

### System Architecture Diagram

```
Operator browser (light/dark/system theme)
        │
        ▼
.scoria-root[data-theme] ──resolves──▶ 02-tokens.css semantic tokens
        │                                   │
        │                                   ▼
        │                         --scoria-toast-<tone>-bg/-fg/-border   (NEW, opaque)
        │                         --scoria-tone-<tone>-bg/-fg/-border    (existing, translucent — unchanged)
        ▼
LiveView render (ScoriaWeb.UI primitives)
        │
        ├─▶ <.toast tone={...}> ──emits──▶ .scoria-toast--<tone> ──consumes──▶ --scoria-toast-<tone>-* (opaque)
        │        (renders inside the existing fixed .scoria-toast-region;
        │         toast itself stays non-fixed per CR-01)
        │
        ├─▶ <.flash_group> ──emits──▶ .scoria-flash--<tone> ──consumes──▶ opaque toast tokens ONLY where
        │                                                                  floating (D-03); in-flow flash
        │                                                                  keeps tinted --scoria-tone-*-bg
        │
        ├─▶ <.overview_stats> (canonical) ──emits──▶ .scoria-overview-stat(s) ──consumes──▶ --scoria-tone-*
        │        (signal_strip/1 DELETED; zero call sites today — verified, see Stats Convergence)
        │
        ├─▶ <.id>/<.raw_evidence copyable> ──renders──▶ data-copy / data-raw-evidence-copy
        │        │                                            │
        │        ▼                                            ▼
        │   assets/js/scoria.js CopyId hook          assets/js/scoria.js document click listener
        │        │                                            │
        │        ▼                                            ▼
        │   clipboard write → toggles .scoria-id--copied  clipboard write → toggles
        │   + textContent="Copied" (aria-live="polite")   .scoria-raw-evidence__copy--copied
        │                                                 (status span — MISSING aria-live, see Pitfalls)
        │
        └─▶ <.button>/<.icon_button> ──emits──▶ .scoria-button[--variant][--size] ──consumes──▶
                 shared focus ring (.scoria-root :where(:focus-visible) in 01-reset.css, ALREADY uniform),
                 :disabled opacity (ALREADY uniform), phx-disable-with loading text (ALREADY the loading
                 primitive — no spinner component exists or is needed)
```

### Recommended Project Structure
No new files/folders. All edits land in the existing locations:
```
lib/scoria_web/ui.ex              # edit button/icon_button/toast/flash_group/overview_stats;
                                   # delete signal_strip/1; add aria-live to raw_evidence copy status
assets/css/02-tokens.css           # add --scoria-toast-<tone>-bg/-fg/-border tokens (dark + light)
assets/css/04-components.css       # point .scoria-toast--<tone>/.scoria-flash--<tone> (floating) at
                                   # the new tokens; delete .scoria-signal* rules (or leave as
                                   # documented-dead if aliasing)
test/scoria_web/ui_component_test.exs   # extend with the 4 new defect-guard describe blocks
priv/dev/e2e/lab.spec.mjs          # extend the existing "dense approvals + toast" test with an
                                   # opacity/contrast-observable assertion (see Validation Architecture)
```

### Pattern 1: Opaque-over-solid-surface toast tokens
**What:** Define toast-specific tone tokens that composite the tone color into an already-opaque
surface token, never into `transparent`.
**When to use:** Any surface that floats over arbitrary page content (toast, and floating flash per
D-03). Do NOT use for in-page tinted surfaces (badges, inline banners, stat borders) — those keep
the existing translucent `--scoria-tone-*-bg` per D-02.
**Example:**
```css
/* Source: pattern derived from existing --scoria-tone-*-bg color-mix idiom,
   assets/css/02-tokens.css:134 (--scoria-tone-pass-bg), adapted to mix into an
   opaque surface instead of `transparent`. */
.scoria-root {
  /* ... existing --scoria-tone-pass-bg: color-mix(in srgb, var(--scoria-success-dark) 14%, transparent); ... */

  /* NEW — opaque toast-specific tokens (dark theme block) */
  --scoria-toast-neutral-bg: var(--scoria-surface-panel-raised);
  --scoria-toast-pass-bg: color-mix(in srgb, var(--scoria-tone-pass-fg) 16%, var(--scoria-surface-panel-raised));
  --scoria-toast-info-bg: color-mix(in srgb, var(--scoria-tone-info-fg) 16%, var(--scoria-surface-panel-raised));
  --scoria-toast-warn-bg: color-mix(in srgb, var(--scoria-tone-warn-fg) 16%, var(--scoria-surface-panel-raised));
  --scoria-toast-fail-bg: color-mix(in srgb, var(--scoria-tone-fail-fg) 16%, var(--scoria-surface-panel-raised));
}
```
```css
/* Component layer: point the toast (and floating flash) at the new tokens.
   fg/border can keep reusing the existing --scoria-tone-<tone>-fg/-border —
   only the background composited-with-transparent problem needs the opaque fix (D-01). */
.scoria-toast--pass { background: var(--scoria-toast-pass-bg); border-color: var(--scoria-tone-pass-border); color: var(--scoria-tone-pass-fg); }
```
**Why `--scoria-surface-panel-raised` and not `--scoria-surface-panel`:** the toast already carries
`--scoria-shadow-raised` (elevation), and `panel-raised` is the existing "floating/elevated surface"
token (used by `.scoria-modal__panel`-adjacent surfaces and `.scoria-notebook__panel`), matching D-01's
"solid `--scoria-surface`/`--scoria-panel` base" instruction precisely.

### Pattern 2: Stat component singularity (delete, don't migrate)
**What:** `overview_stats/1` (`lib/scoria_web/ui.ex:249`) and `signal_strip/1` (`ui.ex:280`) already
share an identical `<dl>` slot contract (`label`/`value`/`tone` attrs on a `stat`/`signal` slot,
rendered as `<dt>`/`dd`/`dd`). **`grep -rn "signal_strip" lib/ dev/ priv/dev/ test/` returns only the
definition itself** (`ui.ex:280,282,285`) — zero call sites in any LiveView, component, dev-lab
section, or test. CSS confirms the same convergence already happened at the stylesheet level:
`assets/css/04-components.css:1521-1588` defines every stat rule as a comma-joined selector
(`.scoria-overview-stat, .scoria-signal { ... }`, `.scoria-overview-stat__label, .scoria-signal__label
{ ... }`, etc.) — there is no independent `.scoria-signal*` visual language left to preserve.
**When to use:** Delete `signal_strip/1` from `ui.ex` and delete the `.scoria-signal*` selectors from
`04-components.css` in the same commit that adds the D-17(c) regression test asserting no
`signal_strip` symbol and no `.scoria-signal` CSS class remain.
**Example:**
```elixir
# Source: lib/scoria_web/ui.ex:264-293 (existing signal_strip/1) — REMOVE this function
# entirely. overview_stats/1 (ui.ex:233-262) is unchanged; it is already the canonical
# implementation both in markup and CSS.
```

### Pattern 3: Copy-control icon ceiling as a CSS-enforced invariant, not a call-site convention
**What:** `.scoria-button--icon-sm svg { width: 0.875rem; height: 0.875rem; }`
(`assets/css/04-components.css:701-709`) already applies to *any* `svg` descendant of an
`icon_button size={:sm}`, including the two nested nested nested SVGs inside
`raw_evidence/1`'s `<span class="scoria-raw-evidence__copy-icons">` wrapper (`ui.ex:1062-1084`),
because the CSS selector is a descendant combinator (`... svg`), not a direct-child combinator. The
copy glyph is therefore **already correctly capped today** for the one real copy-icon call site in
the codebase. There is no third, bespoke copy-icon implementation anywhere (`grep -rn
"copy\|Copy" lib/scoria_web/live lib/scoria_web/components` surfaces only `<.id copy={...}>` and
`raw_evidence copyable={true}` — both already `:sm`-scale or icon-less).
**When to use:** The regression risk is *prospective*, not a currently-visible bug: nothing stops a
future call site from rendering a copy affordance via `icon_button size={:md}`. The D-17(b) guard
should assert this invariant structurally (e.g., grep-style: any element carrying
`data-raw-evidence-copy` or a future `data-copy-*` marker never also carries
`scoria-button--icon-md`), not re-derive it from scratch.
**Example:**
```elixir
# Source: lib/scoria_web/ui.ex:1054-1061 (existing, already-compliant call site)
<.icon_button
  :if={@copyable}
  size={:sm}
  class="scoria-raw-evidence__copy"
  data-raw-evidence-copy
  aria-label={@copy_label}
  title={@copy_label}
>
```

### Anti-Patterns to Avoid
- **Mutating shared `--scoria-tone-*-bg` tokens to fix toast opacity:** D-02 explicitly forbids this
  — those translucent tints are correct for inline badges/banners and used throughout
  `04-components.css` (badges, evidence-section notices, incident signals). Mutating them to be
  opaque would fix toasts but break every in-page tinted surface's subtlety.
- **Adding a third size tier to fix "inconsistent" control sizing:** D-13 explicitly forbids a
  `:lg`/`:xs` tier. Any control found at an ad-hoc size must be migrated onto `:md` or `:sm`, not
  given a new tier.
- **Inventing a new copy-toast pattern:** D-11 explicitly prefers the existing inline
  "Copied" confirmation (already implemented for both `.scoria-id` via the CopyId hook and
  `raw_evidence` via the icon-swap + status span) over spawning a toast per copy. Do not wire copy
  actions into the `@toasts`/`<.toast>` flow.
- **Extending `token_contrast_guard_test.exs`'s `@checked_pairs` with a `color-mix()`-valued token
  name:** as shown above, this will `flunk`, not skip. Use a dedicated string/regex assertion for the
  opacity invariant instead.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Opaque toast surface | A new "solid card" component or inline `style="background: ..."` override | A new `--scoria-toast-<tone>-bg` semantic token consumed the same way every other tone token is consumed (`background: var(--scoria-toast-<tone>-bg)`) | Keeps the single token-gateway pattern `ui.ex`'s moduledoc establishes; avoids a second color-mapping surface that could drift from `tone/1`. |
| Copy affordance keyboard/focus semantics | A bespoke `role="button" tabindex="0" onKeydown` shim on `.scoria-id`'s `<span>` in this phase | Nothing — leave as a documented gap; full keyboard operability is explicitly Phase 40 scope (A11Y-01) | `.scoria-id` today has no `role`/`tabindex`/keydown handler (mouse-click-only via the CopyId hook's `click` listener, `assets/js/scoria.js:23`). Retrofitting real keyboard operability mid-Phase-38 would silently pull Phase 40 scope forward and risk a half-finished a11y contract. Phase 38's D-12 obligation (accessible *name*) is satisfiable without touching interaction semantics — see Pitfalls. |
| Stat "canonical component" enforcement | A custom AST/HEEx linter | A plain `grep`/`Regex.scan` ExUnit test over `lib/scoria_web/**/*.{ex,heex}` for `signal_strip` and `.scoria-signal` (mirrors the exact technique `ds06_drift_guard_test.exs` already uses for raw palette) | Matches D-19 ("prove... rather than bespoke test scaffolding") and the codebase's own established regex-over-source-files test idiom. |
| Loading-state spinner/skeleton for buttons | A new spinner component or CSS animation on `.scoria-button` | The existing `phx-disable-with` + `:disabled` pseudo-class treatment (`.scoria-button:disabled { opacity: 0.5; cursor: not-allowed; }`, already shared across all button variants) | Every current button-triggered async action (`prompt_live/index.ex:133`, `review_queue_live.ex:206`, `dataset_live/promote_component.ex:400`, `eval_spec_live/index.ex:108`) already uses `phx-disable-with`, and LiveView's own client sets `disabled` + `.phx-click-loading` during the round-trip — this is already the uniform "loading" primitive D-16 asks for. No new motion/spinner language should be invented (Phase 40 owns motion). |

**Key insight:** almost every "Don't Hand-Roll" risk in this phase is a risk of *doing too much* —
retrofitting keyboard semantics, inventing a spinner, or writing a new lint framework — not of
missing infrastructure. The existing token/CSS/hook/test patterns already cover 90% of what D-01–D-19
ask for; the actual work is narrow (new toast tokens + one deletion + one new test file).

## Common Pitfalls

### Pitfall 1: `token_contrast_guard_test.exs` flunks (not skips) on `color-mix()` pairs
**What goes wrong:** Someone adds a new toast token pair to `@checked_pairs` in
`token_contrast_guard_test.exs` expecting the "skipped with a notation" behavior described in the
module's own `@moduledoc`, but the actual code (`assert_pairs/3`, lines 77-90) calls `flunk/1` when
`resolve_token/3` returns `nil` for a `color-mix()`-valued token — the docstring and the code
disagree. CI goes red for a reason that looks like a real contrast failure but is actually "this
guard cannot parse this token."
**Why it happens:** `parse_declarations/1` (lines 167-179) silently drops any declaration starting
with `color-mix(` from the parsed token map entirely, so `resolve_token/3` sees a missing key, not a
resolvable-but-noncompliant one.
**How to avoid:** Do not add the new opaque toast tokens to `@checked_pairs`. Write a separate,
purpose-built test (string/regex over `assets/css/02-tokens.css`) for the opacity invariant instead.
**Warning signs:** A contrast-guard test failure whose message is
`"could not resolve --scoria-toast-*-bg... uses color-mix()"` rather than an actual ratio number.

### Pitfall 2: `raw_evidence/1`'s copy-status span lacks `aria-live`
**What goes wrong:** The copy confirmation for `raw_evidence` (`<span class="sr-only"
data-raw-evidence-copy-status>{@copy_label}</span>`, `ui.ex:1085`) has no `aria-live` attribute,
unlike `.scoria-id`'s copy span which explicitly carries `aria-live="polite"` (`ui.ex:320`). A screen
reader user triggering the raw-evidence copy may not hear the "Copied"/"Copy unavailable" state
change announced, even though the JS (`setRawEvidenceCopyState`, `assets/js/scoria.js:42-54`) does
update the span's `textContent` on every copy.
**Why it happens:** The two copy affordances (`id/1` and `raw_evidence`) were built at different
times and the `aria-live` discipline wasn't back-ported to the newer one.
**How to avoid:** Add `aria-live="polite"` to the `data-raw-evidence-copy-status` span as part of the
D-12 accessible-name/feedback pass — this is a one-line fix consistent with the existing `.scoria-id`
pattern, not new design.
**Warning signs:** Manual screen-reader test of the raw-evidence copy button reports no
announcement on click.

### Pitfall 3: `.scoria-id`'s accessible name is the raw ID text, not a "Copy" verb
**What goes wrong:** `.scoria-id` (`ui.ex:307-325`) is a `<span>` with a `title="Click to copy"`
default and `aria-live="polite"`, but no `aria-label`. Its accessible name (per the accname
computation) resolves to its visible text content — the ID value itself (e.g. `"appr-9b1d4e2a"`) —
not an action description. `title` attributes are an unreliable accessible-name source (ignored by
many mobile/touch screen readers and not exposed at all until hover on desktop), so this does not
robustly satisfy D-12's "every copy control has an accessible name" for AT users navigating by role
rather than by reading text.
**Why it happens:** `.scoria-id` was designed primarily as a *display* affordance (a copyable ID
chip) that happens to also be clickable, not as a "copy button" first.
**How to avoid:** Add an explicit `aria-label` (e.g., `"Copy #{@value}"` — the same pattern
`raw_evidence`'s `copy_label` attr already uses) without changing `.scoria-id`'s element type,
`role`, or keyboard operability (those remain Phase 40 scope, see Don't Hand-Roll).
**Warning signs:** Automated a11y scan (axe or similar, if run ad hoc) flags `.scoria-id` for an
ambiguous/non-descriptive accessible name; this may not currently fail any *existing* test since no
test asserts on `.scoria-id`'s accessible name today.

### Pitfall 4: Deleting `.scoria-signal*` CSS without checking the DS-06 baseline file
**What goes wrong:** `test/support/ds06_baseline.txt` is a ratchet baseline keyed by file path and
raw-palette-class *count*, not by specific selector names — deleting `signal_strip/1` and its CSS
does not interact with that baseline (no raw palette classes are involved), so this is a false-alarm
risk, not a real one. Flagging explicitly so the plan doesn't waste a task "updating the DS-06
baseline" for an unrelated change.
**Why it happens:** Multiple Phase 38 changes touch `ui.ex`, which is one of the two `@excluded`
files in `ds06_drift_guard_test.exs` anyway (line 34) — its raw-palette count is asserted to be
exactly zero, not ratcheted, so no baseline file edit is ever needed for `ui.ex` changes.
**How to avoid:** No action needed; noted only to prevent an unnecessary planned task.

## Code Examples

### Toast tone background — before/after (dark theme)
```css
/* Source: assets/css/04-components.css:1711-1715 (BEFORE — reads the shared translucent tint) */
.scoria-toast--warn { border-color: var(--scoria-tone-warn-border); background: var(--scoria-tone-warn-bg); color: var(--scoria-tone-warn-fg); }
```
```css
/* AFTER — reads the new opaque toast-specific token; fg/border unchanged */
.scoria-toast--warn { border-color: var(--scoria-tone-warn-border); background: var(--scoria-toast-warn-bg); color: var(--scoria-tone-warn-fg); }
```

### Existing inline copy-confirmation pattern to replicate for consistency (D-11)
```javascript
// Source: assets/js/scoria.js:20-40 (CopyId hook — the reference inline-confirmation
// implementation; raw_evidence's document-level listener at line 56+ follows the same
// shape and should stay the model for any future copy control — no toast-per-copy).
Hooks.CopyId = {
  mounted: function () {
    var el = this.el;
    el.addEventListener("click", function () {
      var text = el.getAttribute("data-copy") || el.textContent.trim();
      if (!navigator.clipboard) return;
      navigator.clipboard.writeText(text).then(function () {
        var prevText = el.textContent;
        var prevTitle = el.getAttribute("title");
        el.classList.add("scoria-id--copied");
        el.setAttribute("title", "Copied");
        el.textContent = "Copied";
        setTimeout(function () {
          el.classList.remove("scoria-id--copied");
          el.textContent = prevText;
          if (prevTitle) el.setAttribute("title", prevTitle);
        }, 1200);
      });
    });
  },
};
```

### Existing uniform focus ring (already satisfies D-15 — no new work needed)
```css
/* Source: assets/css/01-reset.css:64-68 — applies to every focusable element inside
   .scoria-root via :where(), so buttons/icon buttons/links/fields/copy controls all
   already share one focus treatment. Verify this stays true; do not add per-component
   focus-ring overrides while implementing D-01/D-05/D-09/D-13. */
.scoria-root :where(:focus-visible) {
  outline: 2px solid var(--scoria-focus-ring);
  outline-offset: 2px;
  border-radius: var(--scoria-radius-sm);
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| N/A (no prior toast-legibility fix attempted) | Opaque toast-tone tokens layered over the existing translucent tone-tint system | This phase (38) | First deliberate split between "in-page tint" and "floating-surface opaque" token families for status color. |
| `overview_stats/1` and `signal_strip/1` coexisting as separate (unused) implementations | Single canonical `overview_stats/1`; `signal_strip/1` removed | This phase (38) | Removes dead code; no behavior change for any real page (zero current callers of `signal_strip/1`). |

**Deprecated/outdated:**
- `signal_strip/1` (`lib/scoria_web/ui.ex:264-293`) and its CSS (`.scoria-signal*`,
  `assets/css/04-components.css`, comma-joined with `.scoria-overview-stat*` selectors): confirmed
  dead code as of this research (zero call sites, absent from `docs/MAINTAINERS.md`'s "Components at
  a glance" table). Remove in this phase.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | An opaque `color-mix()` mix percentage of ~16% tone-into-surface-panel-raised will read as clearly toned (not near-invisible) in both themes | Pattern 1 / Code Examples | Low — this is a starting value for the downstream implementer to tune visually against the Phase 37 lab fixture; it does not need to be exactly 16%, and the regression test (opacity-only) does not pin an exact percentage. |
| A2 | `--scoria-surface-panel-raised` (not `--scoria-surface-panel` or a brand-new `--scoria-surface-toast`) is the correct opaque base per D-01's "solid `--scoria-surface`/`--scoria-panel` base" instruction | Pattern 1 | Low — D-01/D-02 explicitly leave the exact token shape to downstream discretion; `panel-raised` is the closest existing "elevated/floating surface" token and is already paired with the toast's existing `--scoria-shadow-raised`, but the planner/implementer could reasonably choose a dedicated new token instead. |
| A3 | Deleting `signal_strip/1` outright (vs. aliasing) is safe because there are truly zero call sites | Pattern 2 / Standard Stack (Alternatives) | Low — verified by `grep -rn "signal_strip"` across `lib/`, `dev/`, `priv/dev/`, `test/`, returning only the function's own definition. Re-run this grep once more immediately before deleting, in case an uncommitted branch elsewhere in the working tree adds a caller between research and implementation. |

**If this table is empty:** N/A — see above; all three assumptions are low-risk/verified-in-code, not
speculative.

## Open Questions

1. **Should the new opaque toast tokens also get flash-floating variants, or does floating flash
   reuse the toast tokens directly?**
   - What we know: D-03 says floating flash gets the same opacity fix, and defaults to opaque if the
     in-flow/floating distinction is fuzzy. Today `flash_group/1` always renders in-flow (inside the
     page, via `<.flash_group flash={@flash} />` calls in layouts) — there is no currently-shipped
     "floating flash" call site to inspect.
   - What's unclear: whether any current layout ever positions `.scoria-flash` as `position:fixed`/
     floating (a quick `grep -rn "scoria-flash" lib/scoria_web/components/layouts` would resolve
     this, but was not required reading for this phase's scope and wasn't checked in depth here).
   - Recommendation: Per D-03's own fallback ("default flashes to the opaque treatment too"), the
     simplest compliant choice is to point `.scoria-flash--<tone>` at the same new
     `--scoria-toast-<tone>-bg` tokens unconditionally, rather than maintaining two parallel token
     sets for an in-flow-vs-floating distinction that isn't currently exercised anywhere in the
     codebase. The planner should confirm this against the actual `flash_group` call sites before
     locking it.

2. **Exact regression-test file placement: extend `ui_component_test.exs` or add a new file?**
   - What we know: D-19/D-17 prefer extending `ui_component_test.exs` where practical; the toast
     opacity assertion in particular reads `assets/css/02-tokens.css` directly (like
     `token_contrast_guard_test.exs` and `ds06_drift_guard_test.exs` do), which is a different
     access pattern (raw CSS file read + regex) than `ui_component_test.exs`'s existing
     `render_component/2`-based assertions.
   - What's unclear: whether mixing "renders HTML and asserts on it" tests with "reads a CSS file and
     regexes it" tests in the same file harms readability.
   - Recommendation: Put the HTML-rendering assertions (copy-icon-size ceiling via rendered markup,
     stat-singularity via `Code.ensure_loaded?`/function-export check, density-scale via rendered
     class strings) in `ui_component_test.exs`; put the CSS-source-only toast-opacity assertion in a
     new small file (e.g. `test/scoria_web/toast_opacity_guard_test.exs`) that mirrors
     `ds06_drift_guard_test.exs`'s exact source-scanning style. Downstream agent's final call per
     Claude's Discretion in the CONTEXT.

## Environment Availability

Skipped — this phase has no new external dependencies. All work is edits to already-present
first-party Elixir/CSS/JS files and already-configured test tooling (`mix test`,
`mix scoria.ui.e2e`, both already wired per `docs/MAINTAINERS.md`).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (`mix test`) + Playwright (`mix scoria.ui.e2e`, config `playwright.config.mjs`, testMatch `**/*.spec.mjs`) |
| Config file | `test/test_helper.exs` (ExUnit); `playwright.config.mjs` (Playwright) — both pre-existing, no new config needed |
| Quick run command | `SCORIA_DB_PORT=55432 mix test test/scoria_web/ui_component_test.exs test/scoria_web/ds06_drift_guard_test.exs test/scoria_web/token_contrast_guard_test.exs` (+ the new toast-opacity guard file once added) |
| Full suite command | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test --warnings-as-errors` (per `docs/MAINTAINERS.md`'s documented `test` alias); `mix scoria.ui.e2e --base-url http://localhost:4799/scoria` for browser proof |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DS-01 (semantic tokens, criterion 1) | Raw-palette/drift guards still pass after all edits | unit | `mix test test/scoria_web/ds06_drift_guard_test.exs` | ✅ existing, extend if new selectors touch `ui.ex`'s zero-palette rule (they don't — no raw palette introduced) |
| DS-04 / criterion 4 (toast opacity) | `--scoria-toast-<tone>-bg` resolves to a non-`transparent`-composited, opaque value in both theme blocks | unit | `mix test test/scoria_web/toast_opacity_guard_test.exs` (NEW) | ❌ Wave 0 — create; regex-scan `assets/css/02-tokens.css` per-theme block for the new token names, assert the declaration does not contain the substring `transparent` and is not an `rgba(...)` with alpha < 1 |
| DS-04 / criterion 4 (toast opacity, browser-observable) | The dense-approvals + toast-overlay lab fixture renders the toast visibly opaque over dense table content, in both themes | e2e | `mix scoria.ui.e2e` (extends `priv/dev/e2e/lab.spec.mjs`'s existing `'Component Lab — dense approvals table + toast-over-dense-UI stress fixture'` describe block) | 🔶 existing describe block proves toast *presence/count*; extend with a computed-style or screenshot-free color-sampling assertion (e.g., `page.evaluate` reading `getComputedStyle(...).backgroundColor` and asserting alpha === 1) for both `data-theme="light"` and `"dark"` |
| DS-03 / criterion 3 (stat convergence) | Exactly one canonical stat component exists; no `.scoria-signal*` class emitted anywhere under `lib/` | unit | `mix test test/scoria_web/ui_component_test.exs` (new describe block) | 🔶 extend existing file — assert `function_exported?(ScoriaWeb.UI, :signal_strip, 1) == false` and `Regex.scan(~r/scoria-signal(?!-strip)?/, File.read!("assets/css/04-components.css")) == []` (grep-style check mirroring `ds06_drift_guard_test.exs`'s technique) |
| DS-02/DS-03 / criterion 2 (copy-icon ceiling) | Copy controls (`raw_evidence`, any future copy affordance) never render with `scoria-button--icon-md` | unit | `mix test test/scoria_web/ui_component_test.exs` (new describe block) | 🔶 extend — `render_component(&ScoriaWeb.UI.raw_evidence/1, copyable: true, ...)` and assert the rendered HTML contains `scoria-button--icon-sm` and does not contain `scoria-button--icon-md` |
| DS-02/DS-03 / criterion 2 (copy control, browser-observable) | The Fixtures-section "Copy fixture payload" control is clickable and reflects a real click outcome | e2e | `mix scoria.ui.e2e` | ✅ already covered — `priv/dev/e2e/lab.spec.mjs`'s `'Component Lab — "Copy fixture payload" copy control'` describe block (lines 274-313); no change needed unless the accessible-name fix (Pitfall 3) warrants an added `aria-label` assertion |
| DS-02 / criterion 2 (density scale) | Controls use only `:md`/`:sm` size tokens; no ad-hoc pixel sizing | unit | `mix test test/scoria_web/ui_component_test.exs` (new describe block) | 🔶 extend — assert `button/1`'s `attr(:size, ...)` values list stays exactly `[:md, :sm]` (a `ScoriaWeb.UI.__attrs__` compile-time check or a simple pattern-match on the module's `attr` declaration) and/or a source-regex over `lib/scoria_web/**/*.{ex,heex}` for disallowed literal `style="width:` / `style="height:` pixel overrides on button-adjacent elements |
| DS-02 / criterion 2 (focus/disabled/loading uniform) | One shared `:focus-visible` treatment; consistent `:disabled` opacity; `phx-disable-with` loading text | unit + manual-confirm | `mix test test/scoria_web/ui_component_test.exs` (spot-check) | ✅ largely covered structurally already (`01-reset.css:64-68` is global; `.scoria-button:disabled` is shared); add one assertion that no component CSS overrides `:focus-visible`/`outline` locally (regex-scan `04-components.css` for `outline:` outside `01-reset.css`) if not already implicitly proven |

### Sampling Rate
- **Per task commit:** the quick-run command above (three-to-four existing/new focused test files).
- **Per wave merge:** `mix scoria.ui.e2e` (Playwright, deterministic, no fixed sleeps per its own
  `lib/ready.mjs` waitForReady pattern) against the extended `lab.spec.mjs`.
- **Phase gate:** full ExUnit suite (`mix test --warnings-as-errors`) plus `mix scoria.ui.e2e` green
  before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/scoria_web/toast_opacity_guard_test.exs` (or an added describe block in
      `ui_component_test.exs`, per Open Question 2) — covers DS-04/criterion 4/D-01/D-02/D-04.
- [ ] Extend `test/scoria_web/ui_component_test.exs` with four new describe blocks: stat
      singularity (D-05/D-08), copy-icon ceiling (D-09), density scale (D-13/D-14), focus/disabled
      uniformity spot-check (D-15/D-16).
- [ ] Extend `priv/dev/e2e/lab.spec.mjs`'s existing dense-approvals+toast describe block
      (lines 247-268) with a computed-style opacity/alpha assertion in both light and dark theme
      (the existing test only asserts presence/count, not visual opacity).
- [ ] No new test framework/config install needed — both ExUnit and Playwright are already fully
      wired.

## Security Domain

Not applicable in the ASVS-controls sense — this phase makes no changes to authentication, session
management, access control, input validation of user-submitted data, or cryptography. It is a CSS
token/markup/JS-hook consistency pass on an already-existing internal admin UI.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | no | N/A — no auth surface touched |
| V3 Session Management | no | N/A |
| V4 Access Control | no | N/A |
| V5 Input Validation | no | No new user input paths; `raw_evidence`'s rendered `@value`/`render_slot` content is unchanged, still passes through Phoenix's existing HTML-escaping in `~H` templates |
| V6 Cryptography | no | N/A |

### Known Threat Patterns for {stack}

Not applicable — no new attack surface (no new routes, no new data flows, no new client-supplied
input handling). The one client-side behavior touched (clipboard writes via `navigator.clipboard`)
is pre-existing and unchanged by this phase; only its visual/CSS/aria presentation is edited.

## Sources

### Primary (HIGH confidence)
- `lib/scoria_web/ui.ex` (read in full) — all primitive definitions, slot contracts, existing copy
  hooks, accessible-name gaps.
- `assets/css/02-tokens.css` (read in full) — token SSOT, tone-tint `color-mix()` formulas, dark/light
  semantic re-pointing.
- `assets/css/04-components.css` (targeted reads: lines 625-830, 1280-1400, 1510-1800) — button,
  badge, id, metric, raw-evidence, stat, toast, flash, focus-adjacent rules.
- `assets/css/01-reset.css` (read in full) — confirms the already-uniform global `:focus-visible`
  treatment.
- `assets/css/05-motion.css` (read in full) — confirms no spinner/loading motion primitive exists or
  should be invented (D-16, Phase 40 boundary).
- `assets/js/scoria.js` (targeted reads: CopyId hook, raw-evidence copy click listener) — confirms
  existing inline-confirmation mechanism (D-11) and the `aria-live` gap (Pitfall 2).
- `test/scoria_web/token_contrast_guard_test.exs` (read in full) — confirms the `color-mix()`
  flunk-not-skip behavior driving the toast-opacity test-design recommendation.
- `test/scoria_web/ds06_drift_guard_test.exs` (read in full) — confirms drift-guard style/pattern to
  mirror for new regression tests, and that `ui.ex` is excluded from the ratchet (zero-tolerance
  instead).
- `test/scoria_web/ui_component_test.exs` (partial read) — confirms `render_component/2` test idiom.
- `priv/dev/e2e/lab.spec.mjs` (read in full) — confirms the exact dense-approvals+toast-overlay
  browser probe (D-19's required proof surface) and its current assertions/gaps.
- `dev/lab/sections/overlays.ex` (targeted read) — confirms the Phase 37 stress-fixture markup/route
  (`/scoria/_lab/overlays`) this phase's fixes must be proven against.
- `docs/MAINTAINERS.md` (targeted reads) — confirms `signal_strip/1` is undocumented/dead and the
  brandbook token-parity tooling (`brandbook/tools/check-consistency.mjs`) scope.
- `brandbook/README.md` (read in full) — confirms the two-token-SSOT parity obligation only applies
  to `raw.color` primitives, not to derived semantic `color-mix()` tokens (informs Alternatives
  Considered).
- `.planning/phases/38-foundations-and-primitive-controls/38-CONTEXT.md`,
  `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`,
  `.planning/phases/36-baseline-and-inventory/36-CONTEXT.md`/`36-INVENTORY.md`,
  `.planning/phases/37-dev-component-lab-and-stress-fixtures/37-CONTEXT.md` (all read in full) —
  locked decisions, deferred scope, and risk-register provenance.

### Secondary (MEDIUM confidence)
- None — all findings in this document were verified directly against the checked-in codebase in
  this session; no web/external documentation lookups were needed (this phase is entirely
  first-party code with no new libraries).

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; every technique (color-mix, @layer, Phoenix.Component,
  regex-source-scanning tests) is already established and verified in the current codebase.
- Architecture: HIGH — every claim about component/CSS/test structure was verified by reading the
  actual file and line ranges cited above, not inferred.
- Pitfalls: HIGH — all four pitfalls are grounded in specific, quoted lines of existing test/CSS/JS
  code (the `color-mix()` flunk behavior, the missing `aria-live`, the `title`-only accessible name,
  the DS-06 baseline non-interaction).

**Research date:** 2026-07-02
**Valid until:** 30 days (stable first-party codebase; no external dependency version drift risk)
