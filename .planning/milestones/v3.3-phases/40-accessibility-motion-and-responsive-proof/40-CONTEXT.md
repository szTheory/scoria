# Phase 40: Accessibility, Motion, And Responsive Proof - Context

**Gathered:** 2026-07-03
**Status:** Ready for planning

> **Research-backed + red-team-hardened, one-shot decisions.** The four gray areas were each
> resolved through a dedicated deep-research pass (idiom for an embedded Phoenix LiveView **library**,
> lessons from LiveDashboard/Oban Web/PhoenixStorybook/Backpex + cross-ecosystem GOV.UK/Radix/React-Aria/
> Carbon, DX, and all design pillars), then **adversarially red-teamed** by a fifth agent whose only job
> was to find where those decisions were wrong against the actual code. The red-team produced material
> deltas — the decisions below are the **hardened** locked spec. Decisions changed/tightened by the
> red-team are marked **(revised)**. Read **The Proof Spine** first; it is load-bearing.

<domain>
## Phase Boundary

Phase 40 is the milestone's **proof phase**: it proves the Phase 36–39 redesigned primitives and
operator flows are **operable (keyboard), readable (WCAG 2.2 AA), and stable (motion + responsive
320→wide)** — closing `A11Y-01`, `A11Y-02`, `MOTION-01`, `RESP-01`. In scope: (1) keyboard-only
operability + visible focus + focus restoration across app shell, command palette, tables/lists,
drawers, modals, disclosures, copy controls, and forms; (2) WCAG 2.2 AA intent for dialogs, drawers,
tabs/disclosures, icon buttons, status, forms, empty states, toasts, tables/lists via native semantics
or correct ARIA; (3) restrained, tokenized, reduced-motion-respecting motion; (4) usability at 320,
375, 768, 1024, 1440, and wide desktop with no clipped content, trapped scroll, squished essential
columns, or floating controls covering navigation.

**This phase PROVES and FIXES to green** (see The Proof Spine / D-01). Prior phases built accessibly on
purpose — native `<details>`, labelled copy controls with accessible names, status-never-color-only,
a uniform token-bound focus ring (Phase 38 D-15), and a tokenized motion layer with a `prefers-reduced-
motion` kill switch already exist — so this phase closes the residual gaps and locks them, it does not
rebuild the design system. Enforcement is **warning-grade this phase; Phase 41 hardens** to blocking
gates + docs + screenshot proof + the final gap register.

**Out of scope (deferred — do NOT pull in):**
- Hardened/blocking regression guards, maintainer accessibility/responsive docs, screenshot proof, and
  the **final** gap register (`PROOF-01/02/03`) → **Phase 41**. This phase authors *warning-grade*
  guards + *non-throwing* e2e collectors and *starts* a running gap register that Phase 41 finalizes.
- Any change to the **locked primitive vocabulary** (tone/size/state enums, the public `attr`/`slot`
  API of `button/1`, `table/1`, `drawer/1`, `modal/1`, etc.), the public `scoria_dashboard/2` macro,
  Hex `package.files`, or `.scoria-root` scoping. (Adding *internal a11y behavior* — a focus trap,
  focus restore, `focus_wrap`, a private hook on an existing `id` — is NOT a vocabulary change and IS
  in scope; see D-10.)
- Any **new Hex runtime dependency**. (A **dev-only** npm devDependency in `priv/dev/` — which is
  excluded from Hex `package.files` — is allowed; see D-05.)
- `prefers-contrast` / `forced-colors` (Windows High Contrast) support — **explicit non-goal** this
  milestone (not in A11Y-01/02); named so its omission isn't mistaken for a defect (D-19).
- Screenshot-diff CI as a **blocking pixel gate** (`VISUAL-CI-01`), PhoenixStorybook adoption
  (`STORYBOOK-01`) — deferred/later. Phase 40 uses screenshots as **human evidence only**, never a gate.

</domain>

<decisions>
## Implementation Decisions

Requirements A11Y-01, A11Y-02, MOTION-01, RESP-01 and the five Phase 40 success criteria are the
locked spec. The decisions below resolve *how* to prove and close them.

### The Proof Spine (read first — the whole phase hangs off this)

The four requirements are proven by **one shared harness with two lanes**, not four disjoint efforts:

1. **Prove-and-fix to green (D-01).** Phase 40 fixes every defect its proof surfaces so the roadmap's
   positively-stated criteria ("keyboard-only navigation *works*") are literally true at phase close,
   and locks each fix. The *only* exception is a defect whose sole fix would cross a locked out-of-scope
   boundary — those are **registered**, not fixed. The line is drawn by **scope boundary, never effort**.
2. **Two proof lanes on shared infrastructure.** (a) A **browserless ExUnit lane** (`mix test`, `async`,
   sub-second) for structural/source-scan invariants that must gate every PR without a browser; (b) a
   **browser e2e lane** (`mix scoria.ui.e2e`, Playwright 1.60, already a **required CI gate**) for
   computed truths — axe WCAG scans, keyboard/focus driving, per-viewport responsive assertions, and
   reduced-motion collapse. One `data-scoria-ready` sentinel (`waitForReady`), one `VIEWPORT_WIDTHS`
   constant, one config — the new specs are additive files, not a new toolchain.
3. **The CI two-bucket rule (D-04, revised — the single most load-bearing mechanism).** Because the
   e2e lane is a **hard-fail required gate**, a naive new assertion on a not-yet-fixed surface would
   red-wall CI before its fix merges. So: **hard-fail (gating) checks ship fix-and-assert atomically in
   the same plan/commit**; **warning-grade checks are non-throwing collectors** (`console.warn` +
   `testInfo.attach()` into the already-uploaded `playwright-report`) with **no throwing `expect()`**.
   Phase 41's job is the mechanical flip of collector → `expect()`. This honors "warning-grade now"
   without either red-walling the gate or shipping a green-but-empty gate that proves nothing.
4. **axe and keyboard-e2e are complementary, not redundant.** axe-core validates roles/names/contrast/
   ARIA (→ A11Y-02) but tests **no** keyboard operability or focus order/restore; keyboard-driving
   validates operability/trap/restore/focus-order (→ A11Y-01); source-scan validates structural
   presence. Every A11Y surface has exactly one named primary owner (see the coverage map, D-07).
5. **Every fix respects the locked system.** Contrast fixes route through the brand token SSOT
   (`brandbook/tokens.json` → `tokens.css`, re-greening `token_contrast_guard_test.exs`), **never**
   page-local color (that would reintroduce the raw-value drift `ds06_drift_guard_test.exs` guards to
   zero). Focus fixes add no attr/slot. Motion guards allow-list the two documented exceptions.

Cross-cutting invariants: no locked-vocabulary change; no new Hex runtime dep; no public-macro/
`.scoria-root` change; new guards are **warning-grade** this phase; keep `ds06_drift_guard_test.exs`
and `token_contrast_guard_test.exs` green; no fabricated data.

### Area 1 — Proof stance (Criteria 1–5 · all four requirements)

- **D-01:** **Prove-and-fix to green, with a scope-boundary escape valve.** Phase 40 fixes every defect
  its harness surfaces EXCEPT defects whose only fix crosses a locked out-of-scope boundary (a new/
  changed primitive **vocabulary**, a public macro/`.scoria-root` change, a new **runtime** dependency,
  an architecture/approval-semantics rewrite). Those are recorded into a **running gap register** the
  moment they're found (with viewport/AT/repro + the exact boundary they'd cross). Rationale: the
  roadmap phrases Phase 40 criteria as truth-claims about the product, and Phase 41's criteria are all
  proof-and-lock (tests/docs/screenshots/gap register) with **no remediation budget** — so deferring
  fixes would hand 41 work it isn't scoped to do. Immediate precedent: Phase 39 fixed every in-scope
  defect inline and deferred only *hardening*.
- **D-02:** **Draw the defer line by scope, not size.** A tedious-but-mechanical focus-restore fix is
  in-scope; a trivial-looking fix that needs a new primitive is out. The discriminator is the
  `REQUIREMENTS.md` out-of-scope list, not story points. ⚠ **A flood of structural defects is a signal,
  not a workload** — 36–39 banked accessibility-by-construction, so if proof surfaces *many* defects
  needing primitive changes, something upstream regressed → **escalate/replan**, don't absorb it into 40
  or dump it on 41.
- **D-03:** **Lock each 40 fix warning-grade** (a warning-grade guard or a focused proof assertion that
  proves *that specific fix*), not with a hard ratchet — hardening is Phase 41's job (don't front-run
  it). **Start** the gap register as a working artifact in 40; Phase 41 owns the final polished register
  that separates fixed from explicitly-deferred.

### Area 2 — WCAG 2.2 AA proof tooling (A11Y-02 · Criterion 3)

- **D-04 (revised · CI two-bucket rule):** See Proof Spine #3. Hard-fail = fix-and-assert atomic;
  warning-grade = non-throwing collectors (`console.warn` + `testInfo.attach`). **Explicitly ban
  `test.fail()` and `expect.soft` as the warning mechanism** — `test.fail()` inverts (fails once the fix
  lands) and `expect.soft` still fails the test at end; neither is report-only. Do **not** stand up a
  separate non-gating CI job — the non-throwing-collector pattern needs zero workflow changes.
- **D-05:** **Both axe-core AND source-scan guards** (the complementary split, Proof Spine #4). Add
  `@axe-core/playwright` as a **`priv/dev/package.json` devDependency**, **exact-pinned + lockfile-
  committed** (matching the existing `playwright: "1.60.0"` discipline; pin transitive `axe-core` too so
  a floating release can't flip CI). Never shipped: `priv/dev` is excluded from Hex `package.files`.
  It is the **only** new dependency across all four areas and it is dev-only.
- **D-06 (revised · report-only baseline first):** New `priv/dev/e2e/a11y_axe.spec.mjs` scans with tags
  `['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa']` (**not** `best-practice` — that pulls non-AA
  opinions + the classic lab false-positives `heading-order`/`region`/`landmark-*`/`duplicate-id`).
  **First run = report-only baseline capture** (violation count + rule breakdown attached to the
  report), NOT assert-zero — the dev lab is a specimen gallery rendering muted/ghost/disabled/danger
  tone variants + ugly-data fixtures simultaneously, so `color-contrast` (wcag2aa) is near-certain to
  fire on intentionally-muted/disabled specimens. **Ratchet to `assert-zero` only on a curated allow-
  list of seeded real pages** after inspecting the baseline; keep the full-lab scan report-only through
  Phase 40. `target-size` (2.5.8) stays report-only (noisiest new rule; would fight the dense-table
  design intent). Any genuine contrast hit is fixed via the token SSOT (D-01/Spine #5), never page-local.
- **D-07 (coverage map — so nothing falls through):**
  | A11Y intent | axe (e2e) | keyboard-e2e (D-11) | source-scan (mix test) |
  |---|---|---|---|
  | 1.4.3 contrast / 1.4.11 non-text | ✅ computed (**both themes**) | — | ✅ token luminance (confirmatory) |
  | 4.1.2 name/role/value (icon buttons) | ✅ computed name | — | ✅ presence ratchet |
  | ARIA misuse / invalid attrs | ✅ | — | ⚠ string presence only |
  | 1.3.1 labels/landmarks/table headers | ✅ | — | ✅ native-semantics presence |
  | status not color-only (brand §7/§9) | ⚠ partial | — | ✅ **primary owner** |
  | 2.1.1 keyboard / 2.1.2 no trap | ❌ | ✅ **primary owner** | — |
  | 2.4.3 order / 2.4.7 visible / restore | ❌ | ✅ **primary owner** | ⚠ `autofocus`/`phx-` presence |
  | 2.4.11 focus not obscured (2.2) | ❌ | ✅ (D-11, owns it) | — |
  | 2.5.8 target size (2.2) | ⚠ report-only | ✅ can measure boxes | — |
  | 4.1.3 status messages (toasts) | ✅ role present | ✅ announced-on-action | ✅ presence |
- **D-08:** **Browserless ExUnit source-scan guards** (async, sub-second, gate every PR) assert: (a)
  native-semantics presence (`<details>`/`role=`/`<dialog>`); (b) accessible-name on every icon-only
  button (`aria-label`/visually-hidden text); (c) no color-only status (every badge carries text/icon,
  brand §7/§9 — this guard is the **primary owner** of that invariant). `token_contrast_guard_test.exs`
  stays (it already computes WCAG luminance from `02-tokens.css` in pure Elixir — axe's contrast check
  is confirmatory, not sole).
- **D-09 (revised · dual-theme):** Contrast/axe coverage **must exercise both `data-theme=dark` and
  `data-theme=light`** (toggle via the existing theme mechanism) — `color-contrast` results differ per
  theme, so scanning one leaves half the surface unproven. Applies to both the axe e2e scan and the
  understanding behind `token_contrast_guard_test.exs`.

### Area 3 — Keyboard / focus proof (A11Y-01 · Criteria 1–2 · RISK-OVERLAY-FOCUS)

- **D-10 (revised · the scope line + the real fix):** **Bundled fix — give `drawer/1` and `modal/1`
  real focus trap + restore.** Verified gap: the command palette + mobile nav already implement
  `trapFocus`/`focusableElements` + `restoreFocus` in `assets/js/scoria.js`, but the server-rendered
  `modal/1` (`ui.ex:708`) has only `autofocus` on its X + `phx-key="Escape"`, and the **`drawer/1`
  (`ui.ex:761`) has `role="dialog" aria-modal="true"` but NO autofocus, NO trap, NO restore** — a
  keyboard user who opens the highest-stakes surface (the D-12 approval decision drawer, the "$10k
  refund" chain) keeps focus on the trigger *behind* the scrim. **This fix is in-scope internal a11y
  wiring, NOT a locked-vocabulary change: it adds ZERO attrs and ZERO slots.** Implement via
  **`Phoenix.Component.focus_wrap/1`** (core Phoenix — **no new Hex dep**) + `JS.push_focus`/
  `focus_first` on open / `pop_focus` on close for restore; OR reuse the existing `scoria.js`
  `trapFocus`/`focusableElements` helpers via a private hook attached to the existing required `id`.
  Prefer `focus_wrap` for idiom; use the private hook if restore-on-DOM-patch (D-13) needs it. One
  focus-trap implementation, not two.
- **D-11:** **Deep browser keyboard-driving on the overlay risk surfaces, contract elsewhere.** Extend
  the existing e2e lane (the pattern already proven in `command_palette.spec.mjs`):
  | Surface | Assertions |
  |---|---|
  | **Drawer** (approval decision) | tab-in (focus inside on open) · **trap** (Tab/Shift+Tab wrap, never lands on background) · **Esc** closes · **restore-to-trigger** (`activeElement === opener`) · **SC 2.4.11** focused primary action not covered by the `position:sticky;bottom:0` action footer (rect non-overlap) |
  | **Modal** (two-step confirm) | tab-in · trap · Esc · restore-to-trigger |
  | **Command palette + shortcuts overlay** | already covered — keep; frame the restore-to-opener assertion as the A11Y-01 proof |
  | **Mobile nav drawer** | one flow: open · trap · Esc · restore · `aria-expanded` toggles |
  **Calmer surfaces get browserless contract assertions** (source-scan / LiveViewTest): tables (scroll
  viewport `tabindex="0"` reachable, sort/filter are real `<button>`/`<a>`), disclosures (native
  `<details>/<summary>`, never a JS-toggled `<div>`), copy controls (`<button>` + `aria-label` +
  `aria-live` node), forms (`<label for>`, sr-only "(required)", icon+text errors not color-alone),
  overlay structural semantics (`role="dialog"`, `aria-modal`, `aria-labelledby`, `phx-key="Escape"`),
  focus visibility (no `outline:none` without a token-ring replacement).
- **D-12 (the browserless-vs-browser line):** LiveViewTest renders markup with **no** real browser — no
  `activeElement`, no tab order, no geometry. **Structure/semantics → browserless; behavior/geometry/
  focus → Playwright.** Focus-into/trap/Esc-actually-closes/restore/order/2.4.11 are ALL Playwright-only;
  role/aria/`phx-key`/native-`<details>`/label-association/`tabindex` presence are browserless.
- **D-13 (revised · new — live-patch focus survival · relates to D-14/D-27 of Phase 39):** The approval
  drawer is a **live PubSub surface** — an unrelated broadcast can `phx-update` it while open and a naive
  `focus_wrap` does not guarantee focus survives the patch (focus can drop to `<body>` mid-review). Add
  a **warning-grade** assertion: focus inside the drawer → trigger a simulated live patch → re-assert
  focus is still inside. If `focus_wrap` alone doesn't hold it, the private restore hook (keyed on the
  existing `id`, plus stable per-approval DOM ids per Phase-39 D-14) handles it. Phase 41 hardens.

### Area 4 — Responsive proof (RESP-01 · Criterion 5 · RISK-RESPONSIVE-SCAN)

- **D-14:** **Assertions gate + screenshot contact-sheet as human evidence.** New
  `priv/dev/e2e/responsive_scan.spec.mjs` reusing `VIEWPORT_WIDTHS = [320,375,768,1024,1440,1920]` +
  `waitForReady`. **Generalize the existing seed** — `lab.spec.mjs` already six-width-scans the *lab
  shell* and `phase16_parity.spec.mjs` already asserts no-page-h-overflow at 375; extend to the real
  primary pages. **Screenshots never gate** (font-AA/timing flaky): widen `priv/dev/shots.mjs` from its
  current 2 viewports to the 6-width matrix, render via `contact_sheet.mjs` = human-reviewable evidence
  + the Phase-41 screenshot baseline. Assertions gate; screenshots inform.
- **D-15 (tiered pages × widths — antidote to combinatorial blowup):** **Cheap doc-overflow check at
  all 6 widths** on ~4 representative primary pages that between them exercise every locked primitive at
  worst case (approvals/review-queue = dense table + sticky action bar + `:mobile_summary`; incidents =
  page-split grid + list; a workflow/detail = page-split + evidence + drawer; the lab shell, already
  wired). **Expensive per-element checks only at 320, 375, 768** (the narrow end + the breakpoint edge,
  where failures concentrate).
- **D-16 (assertion catalog):** (1) **no document h-overflow** — `document.documentElement.scrollWidth
  <= innerWidth + 1` (1px tolerance; the robust idiom already in use); (2) **no essential element
  clipped off-viewport** — `rect.right <= innerWidth+1 && rect.left >= -1` over a **curated selector
  set** (interactive controls, primary headings, action bars — **NOT `*`**, which trips on the
  off-canvas drawer `translateX(-100%)` and intentional `text-overflow:ellipsis`); (3) **table overflow
  contained not leaked** — at 320/375 the `.scoria-table__viewport` MAY have inner `scrollWidth>
  clientWidth` while assertion (1) still passes (that pairing *is* the "scroll is trapped in the
  container, not the document" proof); (4) **`:mobile_summary` swap correctness** — below 768 the mobile
  summaries visible + `.scoria-table__viewport` hidden for `--has-summary` tables, inverse ≥768; (5)
  **no non-modal fixed/floating region covering nav/primary controls** — bounding-box non-intersection
  of `.scoria-toast-region` (`position:fixed`) with nav (`.scoria-mobile-topbar` <768 / `.scoria-sidebar`
  ≥768); **excludes** the command palette (full-screen modal), mobile-nav drawer, and scrims (by design),
  **and excludes the sticky approval footer** (that is `position:sticky;bottom:0`, not fixed — its focus
  occlusion is D-11's SC 2.4.11, see D-17); (6) **min 24px target** (WCAG 2.5.8) at ≤375 — a regression
  floor (the lib already targets 44px on mobile chrome); (7) **no trapped scroll** — any `overflow:auto|
  scroll` container with `scrollWidth>clientWidth` must be keyboard-focusable (the table viewport's
  `tabindex="0"` already satisfies this — the assertion confirms existing behavior).
- **D-17 (revised · SC 2.4.11 boundary — no dup, no gap):** **D-11 owns dynamic focus occlusion** (after
  Tab, the focused control is not covered by the sticky approval footer). **D-16(5) owns static occlusion**
  of primary controls by fixed/floating toast regions and **explicitly excludes** the sticky footer
  (delegated to D-11) and the by-design overlays. The shared primitive is bounding-box intersection —
  factor a `boxesIntersect(a,b)` helper into `priv/dev/e2e/lib/` (next to `ready.mjs`) that both specs call.
- **D-18 (responsive table strategy to prove against):** the library already ships both modes; prove each
  in its intended role. **`:mobile_summary` object-stack is the recommended default for primary operator
  tables** (approvals, review queue) — column-priority stacking beats horizontal scroll for scan-ability
  and structurally cannot produce "squished columns." **Honest scroll-container** (`overflow-x:auto`,
  `tabindex="0"`) is the acceptable fallback for wide diagnostic tables where every column matters
  (proven not-trapped by D-16 (3)+(7)). "Keeps honest overflow at all widths" when `:mobile_summary` is
  absent (`ui.ex:1238`) is the correct honesty default — prove it's *contained*, don't pretend it's gone.

### Area 5 — Motion proof (MOTION-01 · Criterion 4)

- **D-19 (revised · MOTION-01 is substantially satisfied; the proof must be precise):** Motion is
  already tokenized (`--scoria-dur-*`/`--scoria-ease-*` + named keyframes in `assets/css/05-motion.css`)
  with an authoritative `@media (prefers-reduced-motion: reduce)` kill switch (`05-motion.css:71`). The
  proof is a **source-scan guard + an e2e reduced-motion assertion**, written precisely to avoid two
  real false-REDs the red-team found:
  - **Guard (warning-grade ExUnit source-scan):** (i) no `transition: all` / `transition-property: all`
    (grep confirms **zero** today — already green); (ii) every `transition`/`animation` uses
    `--scoria-dur-*` + `--scoria-ease-*` **EXCEPT the allow-listed** `scoria-skeleton-pulse 1.5s
    ease-in-out infinite` at `04-components.css:1610` (the sole non-tokenized decl — the documented D-20
    opacity-only skeleton exception); (iii) `@keyframes` animate only **transform/opacity/border-color**
    — `border-color` is the documented D-21 exception (`scoria-approval-pulse`, `05-motion.css:35`); note
    *transitions* legitimately animate paint props (`background-color`/`box-shadow`/`filter` at
    `04-components.css:1012,1277`) — the transform/opacity restriction is a **keyframe** rule, not a
    transition rule; (iv) no new `@keyframes` outside `05-motion.css`.
  - **e2e reduced-motion proof:** `emulateMedia({ reducedMotion: 'reduce' })` → assert
    `getComputedStyle(el).animationDuration`/`transitionDuration` collapse (the kill switch forces
    `0.001ms !important` + `animation-iteration-count:1`, which provably tames even the `infinite`
    skeleton at line 1610). Genuinely provable — keep it.

### Non-goals (recorded so they aren't re-litigated)

- **D-20:** `prefers-contrast` / `forced-colors` (Windows High Contrast) is an **explicit non-goal** —
  not in A11Y-01/02. Name it in the gap register as considered-and-deferred, not a defect.

### Claude's Discretion

Downstream agents choose: `focus_wrap` vs the reuse-`scoria.js`-hook path for D-10 (both satisfy "no new
Hex dep, no attr/slot"); exact new spec/guard file names and test-file placement; the precise curated
selector sets for D-16 (2) and the curated axe real-page allow-list for D-06; which of the ~4 primary
pages anchor D-15; the `boxesIntersect` helper's exact signature; whether the D-13 live-patch survival
needs the private restore hook or `focus_wrap` alone holds — as long as **D-01..D-20, the Proof Spine,
and the cross-cutting invariants hold**. Prefer boring, minimal additions. Do not expand the tone/size/
state vocabularies locked in Phases 36–39, and do not front-run Phase 41's hardening.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase & Milestone Scope
- `.planning/ROADMAP.md` — Phase 40 goal + 5 success criteria (positively phrased = truth-claims, D-01);
  Phase 41 = proof-and-lock (docs/screenshots/gap register, **no remediation budget**).
- `.planning/REQUIREMENTS.md` — A11Y-01, A11Y-02, MOTION-01, RESP-01 wording; the out-of-scope list that
  is the D-02 defer-line discriminator.
- `.planning/PROJECT.md` — v3.3 intent ("under-adopted, not under-built"; an adopter mounting Scoria
  expects it already accessible/responsive — the DX case for prove-and-fix).
- `.planning/STATE.md` — current phase position and deferred items.
- `.planning/phases/39-component-groups-and-operator-flows/39-CONTEXT.md` — locked page flows; the
  sticky-bottom approval action bar (SC 2.4.11 surface); the live PubSub drawer + D-14/D-27 (D-13 focus
  survival); warning-grade-now / harden-in-41 invariant; the explicit hand-off of A11Y/MOTION/RESP proof
  to Phase 40.
- `.planning/phases/38-foundations-and-primitive-controls/38-CONTEXT.md` — D-15 uniform token-bound focus
  ring; reduced-motion-safe loading; the locked primitive vocabulary this phase must not change.
- `.planning/phases/36-baseline-and-inventory/36-INVENTORY.md` + `36-inventory.json` — risk register
  (`RISK-OVERLAY-FOCUS`, `RISK-RESPONSIVE-SCAN` = Phase 40).

### Brand & Token Source of Truth
- `brandbook/brand-book.md` — **canonical** voice/UI (newer than `prompts/`; wins on conflict). §2 states,
  §7/§9 status-not-color-only, §12 motion (restrained/tokenized/reduced-motion), focus/keyboard expectations.
- `brandbook/tokens.json` / `brandbook/tokens.css` — semantic token SSOT; **the only sanctioned path for
  any contrast fix** (D-01/Spine #5).

### Runtime UI, Motion, JS (the surface Phase 40 proves + fixes)
- `lib/scoria_web/ui.ex` — `modal/1` (~708, has only `autofocus`+Escape) and `drawer/1` (~761, no trap/
  restore/autofocus) — the D-10 fix target; `table/1` (~1199) `:mobile_summary` (~1235) + `.scoria-table__
  viewport` `tabindex="0"` (~1273); `badge/1`, `field/1`, `raw_evidence/1` (`<details>`), copy controls.
- `assets/js/scoria.js` — `CommandPalette`/mobile-nav `trapFocus`/`focusableElements`/`restoreFocus`
  (the proven pattern to reuse/mirror onto drawer/modal); `Dismissable` (~138, Escape-only); the
  `data-scoria-ready="true"` sentinel (~759); `data-theme` dark/light/system cycling (~112, D-09).
- `assets/css/05-motion.css` — tokenized keyframes + reduced-motion kill switch (~71); `scoria-approval-
  pulse` border-color D-21 exception (~35).
- `assets/css/04-components.css` — sticky approval action bar `position:sticky;bottom:0` (~851/855, SC
  2.4.11 subject); `.scoria-toast-region` `position:fixed` (D-16(5)); `:mobile_summary` swap rules
  (~1747); `.scoria-table__viewport` overflow-x (~1684); the raw `scoria-skeleton-pulse 1.5s ease-in-out
  infinite` at **1610** (the sole non-tokenized motion decl — D-19 allow-list); transitions animating
  paint props at 1012/1277 (D-19 keyframe-vs-transition split).
- `lib/scoria_web/live/` — the primary page LiveViews to enumerate for D-15 (approvals_live,
  review_queue_live, incidents_live, workflow_live, dataset_live, connectors_live, prompt_live,
  eval_spec_live, orchestrator_live Home, coming_soon_live).

### Proof Harness & CI (reuse — do not rebuild)
- `lib/mix/tasks/scoria.ui.e2e.ex` — the `mix scoria.ui.e2e --base-url ...` task; seeds approvals (and
  exports seeded demo ids as env to Playwright) unless `--no-seed-approvals` (D-06 determinism note).
- `priv/dev/e2e/playwright.config.mjs` (chromium, 1.60) · `priv/dev/e2e/lib/ready.mjs` (`waitForReady`,
  `data-scoria-ready`) · `priv/dev/e2e/lab.spec.mjs` (six-width scan seed, `VIEWPORT_WIDTHS`) ·
  `priv/dev/e2e/phase16_parity.spec.mjs` (375 no-h-overflow assertion to generalize) ·
  `priv/dev/e2e/command_palette.spec.mjs` (proven keyboard-flow pattern to extend to drawer/modal).
- `priv/dev/package.json` — where `@axe-core/playwright` gets pinned (D-05); `priv/dev` is **excluded
  from Hex `package.files`** (`mix.exs` ~160 — verified).
- `priv/dev/shots.mjs` (widen 2→6 viewports, D-14) · `priv/dev/contact_sheet.mjs` (render evidence).
- `.github/workflows/ci.yml` — the `e2e` job (~30) runs `mix scoria.ui.e2e` (~116); `ci-gate`
  `needs: [verify, e2e]` **hard-fails if e2e ≠ success** (~130-144) → the D-04 two-bucket rule exists
  because this gate is real; `always()` upload of `playwright-report` (~122) = where non-throwing
  collectors surface.
- `test/scoria_web/token_contrast_guard_test.exs` (browserless WCAG luminance; keep green, exercise both
  themes) · `test/scoria_web/ds06_drift_guard_test.exs` (raw-palette zero; keep green) ·
  `ui_drift_guard_test.exs` / `ui_component_test.exs` (the source-scan guard idiom to model D-08/D-19 on).

### External Precedent
- `https://www.w3.org/TR/WCAG22/` — SC 2.4.11 focus-not-obscured (D-11/D-17), 2.5.8 target size (D-16(6),
  report-only D-06), 2.4.3 order, 2.1.2 no-keyboard-trap (good-trap-with-Esc vs bad-trap).
- `Phoenix.Component.focus_wrap/1` + `Phoenix.LiveView.JS.push_focus/focus_first/pop_focus` (HexDocs) —
  the idiomatic no-new-dep overlay focus fix (D-10).
- `@axe-core/playwright` — catches ~30–57% of WCAG (contrast/name/role/ARIA); necessary-but-insufficient,
  pair with keyboard e2e (the universal cross-ecosystem lesson: GOV.UK, React-Spectrum, Radix, Carbon,
  jest-axe). LiveDashboard/Oban Web/Backpex ship no a11y test lane — Scoria running axe on a lab
  (Storybook analog) + real pages is *ahead* of the Phoenix idiom.
- GOV.UK responsive-tables guidance (stack/scroll-with-affordance, avoid squeeze) — validates D-18
  `:mobile_summary`-first; Carbon/Spectrum column-priority tables.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **The whole proof harness already exists** — `mix scoria.ui.e2e` + Playwright 1.60 + `waitForReady`/
  `data-scoria-ready` + `VIEWPORT_WIDTHS` + a required CI gate. Phase 40 adds spec files, not a toolchain.
- **The keyboard-flow pattern is proven** in `command_palette.spec.mjs` (open/trap/Esc/restore) — extend
  it to drawer/modal (D-11).
- **The responsive assertion is proven** in `phase16_parity.spec.mjs` (375 no-h-overflow) — generalize to
  6 widths × primary pages (D-14/D-16).
- **The focus-trap implementation already exists** in `scoria.js` (CommandPalette/mobile-nav) — reuse for
  the drawer/modal fix instead of writing a second one (D-10).
- **Motion is already tokenized + reduced-motion-safe** (`05-motion.css`) — MOTION-01 is prove + a precise
  guard, not build (D-19).
- **`table/1` already ships both responsive modes** (`:mobile_summary` stack + `overflow-x:auto` scroll
  container with `tabindex=0`) — the strategy to prove, not invent (D-18).
- **Contrast is already computed browserlessly** by `token_contrast_guard_test.exs` — axe is confirmatory.

### Established Patterns
- Two-lane proof: browserless ExUnit source-scan guards (fast, gate every PR) + browser e2e (computed
  truths). Warning-grade this phase; Phase 41 hardens.
- Token-first CSS via `.scoria-root`; raw-palette drift is a guarded zero (DS-06) — stays zero; contrast
  fixes go through the token SSOT.
- The e2e lane is a **hard-fail required CI gate** → new work is fix-and-assert-atomic (hard) or
  non-throwing collector (warning-grade). Never `test.fail()`/`expect.soft` for warnings.
- Small composable `attr`/`slot` function components — the D-10 focus fix adds neither attr nor slot.

### Integration Points
- Fix `drawer/1` + `modal/1` focus (trap+restore) in `ui.ex` (+ maybe `scoria.js`) via `focus_wrap`/JS
  focus helpers or the existing hook — no attr/slot, no new Hex dep.
- Add `@axe-core/playwright` (pinned) to `priv/dev/package.json`; new specs `a11y_axe.spec.mjs`,
  `responsive_scan.spec.mjs`, and drawer/modal keyboard specs in `priv/dev/e2e/`; shared `boxesIntersect`
  in `priv/dev/e2e/lib/`.
- Extend browserless guards alongside `token_contrast_guard_test.exs`/`ds06_drift_guard_test.exs` for a11y
  structural presence (D-08) + the motion source-scan (D-19).
- Widen `priv/dev/shots.mjs` to 6 viewports for evidence; render via `contact_sheet.mjs`.
- Start the running gap register (D-03) that Phase 41 finalizes.

</code_context>

<specifics>
## Specific Ideas

- **The one gap that matters most:** `drawer/1` (the $10k-refund approval decision surface) has NO focus
  trap, NO restore, NO autofocus while `modal/1` has only `autofocus`+Escape — the command palette already
  does it right. Bringing drawer/modal up to the palette's standard is the load-bearing Phase-40 fix (D-10),
  and it's the highest-stakes keyboard surface in the product.
- **The single most load-bearing mechanism** is the CI two-bucket rule (D-04): fix-and-assert-atomic for
  hard gates, non-throwing collectors for warnings — because the e2e lane is a real required gate.
- **axe first-run is report-only** (D-06) — the lab is a specimen gallery; muted/disabled specimens will
  fire `color-contrast`; ratchet to zero only on curated seeded real pages.
- **Two motion false-REDs to avoid** (D-19): the raw `1.5s ease-in-out infinite` skeleton at
  `04-components.css:1610` (allow-list, D-20 exception) and `border-color` in `scoria-approval-pulse`
  (D-21 exception); keyframes = transform/opacity/border-color, transitions may animate paint props.
- **Both themes** for contrast (D-09); **exclude the sticky footer** from the static-occlusion check and
  give it to D-11's 2.4.11 (D-17); **live-patch focus survival** on the drawer is a real, missed target (D-13).
- **`prefers-contrast`/`forced-colors`** is an explicit non-goal (D-20), recorded so it isn't chased.

</specifics>

<deferred>
## Deferred Ideas

- Hardened/blocking regression guards (flip warning-grade collectors → `expect()`), maintainer
  accessibility/responsive docs, screenshot proof, and the **final** gap register — **Phase 41** (`PROOF-01/02/03`).
- Screenshot-diff CI as a blocking pixel gate (`VISUAL-CI-01`), PhoenixStorybook adoption (`STORYBOOK-01`)
  — deferred/later. Phase 40 screenshots are human evidence only.
- `prefers-contrast` / `forced-colors` (Windows High Contrast) support — explicit non-goal (D-20); revisit
  only if a real requirement appears.
- Named tab-stop / SR label on the `table/1` `tabindex=0` scroll container (minor SR nit) — Phase 41, do
  not expand scope now.
- Any a11y/responsive fix that would require changing a locked primitive's vocabulary, the public macro,
  `.scoria-root`, or a new runtime dep — **register into the gap register, do not fix in 40** (D-01/D-02).

### Reviewed Todos (not folded)
- `ci-policy-job-cache-key-mislabel.md` (WR-01, CI cache-key mislabel) — matched on generic keywords
  ("status", "phase"); a CI-policy concern, not accessibility/motion/responsive. Not folded.
- `docker-dx-fleet-hardening.md` (multi-lib local Docker DX) — dev-environment concern, unrelated to this
  phase's proof scope. Not folded.
- `2026-06-20-add-approval-decision-history.md` — already delivered by Phase 39 (FLOW-04 decision history);
  not a Phase-40 concern. Not folded.

</deferred>

---

*Phase: 40-Accessibility, Motion, And Responsive Proof*
*Context gathered: 2026-07-03 (research-backed + red-team-hardened same day)*
