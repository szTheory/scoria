# Phase 40: Accessibility, Motion, And Responsive Proof - Research

**Researched:** 2026-07-03
**Domain:** WCAG 2.2 AA proof tooling (axe-core/Playwright), LiveView focus management (`focus_wrap`/`JS` focus ops), tokenized CSS motion, responsive assertion harness
**Confidence:** HIGH (nearly every claim below is anchor-verified against the current tree or the exact pinned dependency source, not inferred)

## Summary

CONTEXT.md's decisions (D-01..D-21) are locked and are **not** re-derived here. This research's
job was narrower and mechanical: verify every cited file:line anchor against the current repo,
confirm the "already-green" claims that new guards must not break, and pin `@axe-core/playwright`
precisely. Verification found the CONTEXT.md anchors to be **exceptionally accurate** — every
cited line number checked out within 0-3 lines, and all "sole non-tokenized exception" claims were
independently re-derived by grep, not just trusted. Two things were found that CONTEXT.md did not
call out and that materially affect implementation:

1. **`target-size` (2.5.8) is `enabled: false` by default inside axe-core 4.12.1.** D-06 assumes it
   fires (report-only) as "noisiest new rule" — it will not fire at all unless the axe run config
   explicitly re-enables it (`rules: { 'target-size': { enabled: true } }`) alongside the tag list.
   Without that override, D-06's target-size clause is a silent no-op.
2. **The D-10 focus-trap fix touches more files than "ui.ex (+ maybe scoria.js)".** `<.drawer>`/
   `<.modal>` open-triggers (the `phx-click` that flips `@show`/an assign) live in the *calling*
   LiveViews/components (`approval_inbox_component.ex`, `dataset_live/index.ex`,
   `connectors_live/index.ex` ×2, `workflow_live/show.ex`, `prompt_live/release_workbench_live.ex`
   ×2), not in `ui.ex`. `JS.push_focus()` must run at the **opener** click (to capture the trigger
   before focus moves), while `JS.pop_focus()` can be centralized in `ui.ex`'s internal `on_dismiss`
   wiring. `focus_wrap/1` also renders its own `id={@id}` wrapper div — nest it as
   `<.focus_wrap id={"#{@id}-focus"}>` inside the existing `role="dialog"` element, do not reuse the
   outer shell's `@id` verbatim (collision).

**Primary recommendation:** Implement D-10 via `Phoenix.Component.focus_wrap/1` (verified present
in the exact pinned `phoenix_live_view` 1.1.30) wrapping the panel body inside `modal/1`/`drawer/1`,
with `phx-click={JS.push(@on_dismiss) |> JS.pop_focus()}`/`phx-window-keydown={...}` added
*internally* to the components (zero attr/slot change), and add `JS.push_focus()` to each external
opener call site. Pin `@axe-core/playwright@4.12.1` exact + pin transitive `axe-core` to `4.12.1`
(not the package's own `~4.12.1` range) via an npm `overrides` entry, and explicitly enable
`target-size` in the axe run options if D-06's report-only intent is to actually surface anything.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
The Proof Spine (5 points) + D-01 through D-21 in `.planning/phases/40-accessibility-motion-and-responsive-proof/40-CONTEXT.md` are locked. Highlights this research leans on directly:

- **D-01/D-02/D-03:** Prove-and-fix to green with a scope-boundary escape valve; defer line is
  scope (locked-vocabulary/macro/`.scoria-root`/new runtime dep), never effort/size; lock each fix
  warning-grade this phase, Phase 41 hardens.
- **D-04 (CI two-bucket rule):** hard-fail checks ship fix-and-assert atomically; warning-grade
  checks are non-throwing collectors (`console.warn` + `testInfo.attach()`); never `test.fail()`/
  `expect.soft` as the warning mechanism; no new CI job.
- **D-05:** `@axe-core/playwright` as the **only** new dependency, dev-only, exact-pinned +
  lockfile-committed, pin transitive `axe-core` too.
- **D-06 (report-only baseline first):** tags `['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa']`
  (not `best-practice`); first run is report-only baseline capture, not assert-zero; ratchet to
  assert-zero only on a curated allow-list of seeded real pages; `target-size` stays report-only.
- **D-07 (coverage map):** axe / keyboard-e2e / source-scan each have exactly one named primary
  owner per A11Y intent — see table in CONTEXT.md.
- **D-08:** browserless ExUnit source-scan guards for native-semantics presence, icon-button
  accessible names, no color-only status (primary owner of that invariant).
- **D-09 (dual-theme):** contrast/axe coverage must exercise both `data-theme=dark` and `light`.
- **D-10 (the scope line + real fix):** give `drawer/1`/`modal/1` real focus trap + restore via
  `Phoenix.Component.focus_wrap/1` + `JS.push_focus`/`focus_first`/`pop_focus`, OR the existing
  `scoria.js` `trapFocus`/`focusableElements` helpers via a private hook. Adds zero attrs/slots.
- **D-11:** deep browser keyboard-driving on drawer/modal/command-palette/mobile-nav; browserless
  contract assertions elsewhere (tables, disclosures, copy controls, forms, overlay structure).
- **D-12:** browserless-vs-browser line — structure/semantics → browserless; behavior/geometry/
  focus → Playwright.
- **D-13 (live-patch focus survival):** the approval drawer is a live PubSub surface; assert focus
  survives a simulated live patch while the drawer is open (warning-grade).
- **D-14:** `responsive_scan.spec.mjs` reusing `VIEWPORT_WIDTHS`; generalize `lab.spec.mjs`/
  `phase16_parity.spec.mjs`; widen `shots.mjs` 2→6 viewports; assertions gate, screenshots inform.
- **D-15 (tiered pages × widths):** cheap doc-overflow check at all 6 widths on ~4 representative
  primary pages; expensive per-element checks only at 320/375/768.
- **D-16 (assertion catalog):** (1) no document h-overflow; (2) no essential element clipped
  off-viewport (curated selector set, not `*`); (3) table overflow contained not leaked; (4)
  `:mobile_summary` swap correctness; (5) no non-modal fixed region covering nav (excludes sticky
  approval footer, command palette, mobile-nav drawer, scrims); (6) min 24px target at ≤375; (7) no
  trapped scroll.
- **D-17 (SC 2.4.11 boundary):** D-11 owns dynamic focus occlusion (sticky footer); D-16(5) owns
  static occlusion (fixed/floating regions), explicitly excluding the sticky footer. Shared
  `boxesIntersect(a,b)` helper in `priv/dev/e2e/lib/`.
- **D-18:** `:mobile_summary` object-stack is the recommended default; honest scroll-container is
  the acceptable fallback for wide diagnostic tables (proven contained, not gone).
- **D-19 (motion proof precision):** source-scan guard for (i) no `transition: all`; (ii)
  tokenized durations/eases except the allow-listed `scoria-skeleton-pulse` (and see this research's
  correction — `scoria-approval-pulse`'s duration is *also* non-tokenized, see Anchors table); (iii)
  keyframes animate only transform/opacity/border-color; (iv) no new `@keyframes` outside
  `05-motion.css`. e2e reduced-motion collapse assertion.
- **D-20:** `prefers-contrast`/`forced-colors` explicit non-goal.

### Claude's Discretion
Downstream agents choose: `focus_wrap` vs. the reuse-`scoria.js`-hook path for D-10 (this research
finds `focus_wrap` structurally favored — see Pitfalls); exact new spec/guard file names and test
placement; curated selector sets for D-16(2) and the curated axe allow-list for D-06; which ~4
primary pages anchor D-15; the `boxesIntersect` signature; whether D-13 needs the private restore
hook or `focus_wrap` alone holds.

### Deferred Ideas (OUT OF SCOPE)
Hardened/blocking guards, maintainer docs, screenshot proof, final gap register → Phase 41.
Screenshot-diff CI (`VISUAL-CI-01`), PhoenixStorybook (`STORYBOOK-01`) → later.
`prefers-contrast`/`forced-colors` → explicit non-goal.
Named tab-stop/SR label on `table/1`'s `tabindex=0` scroll container → Phase 41.
Any fix requiring a locked-vocabulary/macro/`.scoria-root`/new-runtime-dep change → gap register,
not fixed in 40.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| A11Y-01 | Keyboard-only users can complete navigation, search/command palette, table/list scan, drawer/modal decisions, copy controls, disclosures, and form flows with visible focus and predictable focus restoration. | D-10 fix verified feasible with the pinned `phoenix_live_view` 1.1.30 (`focus_wrap/1`, `JS.push_focus/focus_first/pop_focus` all present, confirmed by reading the vendored source at the exact pinned version). D-11 keyboard-e2e pattern already proven in `command_palette.spec.mjs` (open/filter/Esc/restore, trap-focus-in-shortcuts-overlay) — extend directly. Opener fan-out mapped below (Pitfall 2). |
| A11Y-02 | Dialogs, drawers, tabs/disclosures, icon buttons, status, forms, empty states, toasts, and tables/lists meet WCAG 2.2 AA intent using native semantics or correct ARIA. | `@axe-core/playwright` verified on npm registry (dequelabs org, 5.1M weekly downloads, created 2021, official axe-core maintainer) — see Dependency-Pin Guidance. `token_contrast_guard_test.exs` already covers both dark+light (D-09 partially pre-satisfied for that guard). `target-size` default-disabled finding directly affects D-06 implementation (see Summary/Pitfalls). |
| MOTION-01 | Motion is restrained, tokenized, useful, transform/opacity-based where possible, and respects `prefers-reduced-motion`. | Re-derived (not just trusted) via grep: zero `transition: all`/`transition-property: all` in `assets/css/`; the only two non-tokenized `animation` declarations are `scoria-skeleton-pulse` (1.5s, `04-components.css:1610`) and `scoria-approval-pulse`'s **duration** (600ms, `05-motion.css:46`) — CONTEXT.md's D-19(ii) named only the former; both need to be in the guard's allow-list (see Anchors table). All 6 `@keyframes` confirmed transform/opacity/border-color only. |
| RESP-01 | Primary dashboard pages remain usable at 320, 375, 768, 1024, 1440, and wide desktop widths without squished tables, trapped scrolling, clipped content, or floating elements covering navigation. | `VIEWPORT_WIDTHS = [320,375,768,1024,1440,1920]` confirmed exact in `lab.spec.mjs:36`; `phase16_parity.spec.mjs` confirmed to already implement the no-h-overflow pattern at 375px on 2 pages — the exact seed to generalize. `:mobile_summary` swap breakpoint confirmed at `max-width: 767px` / `min-width: 768px` (`04-components.css:1747/1757`). |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Focus trap/restore (drawer, modal) | Frontend Server (LiveView/SSR) | Browser/Client (Phoenix's built-in `Phoenix.FocusWrap` JS hook, auto-registered regardless of Scoria's custom `hooks: Hooks` object) | `focus_wrap/1` is a `Phoenix.Component` — the fix is authored server-side in `ui.ex`; the client-side trap behavior ships inside the `phoenix_live_view.js` bundle itself (not `scoria.js`), confirmed via `live_socket.js:358` (`name.startsWith("Phoenix.")` resolves from the framework's internal hook table independent of the app's `hooks:` option). |
| WCAG scan (axe-core) | Browser/Client (Playwright, real Chromium) | — | Contrast/ARIA/name-role-value require a real rendering engine; LiveViewTest (Floki) cannot compute these. |
| Contrast computation (fallback/confirmatory) | Frontend Server (pure Elixir, `token_contrast_guard_test.exs`) | — | Computes WCAG luminance directly from `02-tokens.css` text, no browser needed — confirmatory to axe, not dependent on it. |
| Motion tokenization + reduced-motion collapse | CDN/Static (CSS, `assets/css/05-motion.css`) | Browser/Client (Playwright asserts computed style) | The kill switch is pure CSS (`@media (prefers-reduced-motion)`), unlayered so it always wins; proof of collapse requires `getComputedStyle` in a real browser. |
| Responsive layout (viewport widths, table swap) | CDN/Static (CSS media queries) | Browser/Client (Playwright measures `scrollWidth`/`getBoundingClientRect`) | Breakpoints and stacking are pure CSS; only real-browser geometry can prove no overflow/clipping. |
| Table structural semantics (`tabindex=0`, native controls) | Frontend Server (LiveView markup) | Browser/Client (Playwright confirms actual keyboard reachability) | Presence is server-rendered; actual `Tab`-reachability requires a live DOM. |

## Anchors Verified / Corrected

All anchors below were opened and grep-confirmed against the current tree (not assumed). Everything
listed as "Confirmed" matched within 0-3 lines of the CONTEXT.md citation — treat those line numbers
as reliable. Two items are flagged `CORRECTED`/`ADDENDUM` because they materially change what a
guard implementation must account for.

| Path:Line (cited) | Claim | Status |
|---|---|---|
| `lib/scoria_web/ui.ex:708` | `modal/1` def — only `autofocus` on the X + `phx-key="Escape"`, no trap/restore | **Confirmed exact.** `def modal(assigns) do` is line 708; `<.icon_button autofocus ...>` at 724-734; dismiss via `phx-window-keydown={@on_dismiss} phx-key="Escape"` at 710. |
| `lib/scoria_web/ui.ex:761` | `drawer/1` def — `role="dialog" aria-modal="true"`, NO autofocus/trap/restore | **Confirmed exact.** `def drawer(assigns) do` is line 761; `role="dialog" aria-modal="true"` at 773-774; no `autofocus` anywhere in the function. |
| `lib/scoria_web/ui.ex:1199` (table section) / `:mobile_summary` ~1235 / viewport `tabindex="0"` ~1273 | table/1 region | **Partially corrected.** The "DS-01: `<.table>`" section *comment* header is at line 1222, not 1199 (off by 23 — 1199 is inside the *previous* `evidence_action_row/1`/`evidence_empty/1` functions). `def table(assigns) do` itself is at **line 1256**. `slot(:mobile_summary, ...)` confirmed exact at **1235**. `.scoria-table__viewport tabindex="0"` confirmed exact at **1273**. Use `ui.ex:1256` (not 1199) as the `table/1` def anchor. |
| `assets/js/scoria.js` — `trapFocus`/`focusableElements`/`restoreFocus` on CommandPalette + mobile-nav | Reuse-candidate helpers | **Confirmed present**, no line drift claimed by CONTEXT (none given). `focusableElements` at 187; `trapFocus` at 579; `restoreFocus` field first set at 218 (CommandPalette), 602 (MobileNav, "Reuses focusableElements and trapFocus helpers from CommandPalette" comment at 595-596). |
| `assets/js/scoria.js:759` — `data-scoria-ready` sentinel | **Confirmed exact.** `document.documentElement.setAttribute("data-scoria-ready", "true");` is line 759. |
| `assets/js/scoria.js:112` — `data-theme` cycling | **Confirmed close** (113-114): `document.documentElement.setAttribute("data-theme-mode", mode)` / `setAttribute("data-theme", themeResolve(mode))` at 113-114. |
| `assets/css/05-motion.css:71` — reduced-motion kill switch | **Confirmed exact.** `@media (prefers-reduced-motion: reduce)` opens at line 71; collapse values are `animation-duration: 0.001ms !important; animation-iteration-count: 1 !important; transition-duration: 0.001ms !important; scroll-behavior: auto !important;` (74-78). |
| `assets/css/05-motion.css:35` — `scoria-approval-pulse` border-color exception | **Confirmed exact.** `@keyframes scoria-approval-pulse { 0%, 100% { border-color: ... } 50% { border-color: ... } }` at 35-38. |
| `assets/css/04-components.css:851/855` — sticky approval action bar | **Confirmed exact.** Comment block starts 851 ("D-12: sticky-BOTTOM action footer"); `.scoria-approval-actions { position: sticky; bottom: 0; ... }` at 854-856. |
| `.scoria-toast-region` `position:fixed` | **Confirmed**, at line **1641** (not cited with a line number in CONTEXT.md — noting for precision). |
| `04-components.css` `:mobile_summary` swap ~1747 | **Confirmed exact.** `@media (max-width: 767px) { .scoria-table-shell--has-summary .scoria-table__viewport { display: none; } ... }` opens exactly at line 1747. |
| `.scoria-table__viewport` overflow-x ~1684 | **Confirmed exact.** `.scoria-table__viewport { overflow-x: auto; overflow-clip-margin: 4px; }` at 1684-1687. |
| `04-components.css:1610` — raw `scoria-skeleton-pulse 1.5s ease-in-out infinite` | **Confirmed exact.** `animation: scoria-skeleton-pulse 1.5s ease-in-out infinite;` is line 1610 — verified as the **only** `04-components.css` `animation:` decl using a raw (non-`var()`) duration+easing pair; all three others in that file (887, 910, 934) use `var(--scoria-dur-*) var(--scoria-ease-*)`. |
| `04-components.css:1012,1277` — transitions animating paint props | **Confirmed exact** both. Line 1012-1016: `background-color`/`border-color`/`box-shadow`/`transform`, all `var(--scoria-dur-fast) var(--scoria-ease-out)`. Line 1277-1280: `opacity`/`transform`/`filter`, same tokens. Both are **fully tokenized** (this is the D-19 "transitions may animate paint props" clause — confirmed correct, and confirmed these two are tokenized so they need no allow-list entry). |
| `05-motion.css:46` — `.scoria-attention { animation: scoria-approval-pulse 600ms var(--scoria-ease-in-out) 2; }` | **ADDENDUM — not cited in CONTEXT.md, found via independent re-derivation.** This is a **second** non-tokenized `animation` declaration: the duration `600ms` has no matching `--scoria-dur-*` token (fast=100ms/mid=150ms/slow=200ms, confirmed from `02-tokens.css:99-101` — none is 600ms). The easing IS tokenized (`var(--scoria-ease-in-out)`). D-19(ii)'s guard must allow-list this decl too, not just the skeleton-pulse — otherwise it is a **false-RED the moment the guard ships** (a guard asserting "every animation uses `--scoria-dur-*`" would immediately fail on code that predates Phase 40 and is explicitly sanctioned by D-21). Recommend the guard allow-list by **animation-name** (`scoria-skeleton-pulse`, `scoria-approval-pulse`) rather than by literal duration string, so it structurally can't miss a variant. |
| `priv/dev/e2e/playwright.config.mjs` — chromium, 1.60 | **Confirmed.** `package.json` pins `"playwright": "1.60.0"` and `"@playwright/test": "1.60.0"`; config `projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }]`. |
| `priv/dev/e2e/lib/ready.mjs` — `waitForReady` | **Confirmed exact** — default timeout 15000ms, polls `data-scoria-ready === 'true'` on `<html>`. |
| `lab.spec.mjs` `VIEWPORT_WIDTHS` | **Confirmed exact**, line 36: `[320, 375, 768, 1024, 1440, 1920]`. |
| `phase16_parity.spec.mjs` — 375 no-h-overflow | **Confirmed** — already asserts on shell (Home) and `/workflows` at 375px, plus a third test confirming the table-viewport-may-overflow-while-page-doesn't pairing (D-16(3) is *already proven* on one page — the seed to generalize per D-14/D-15). |
| `command_palette.spec.mjs` — keyboard-flow pattern | **Confirmed** — `openHome`/`openPaletteWithKeyboard`/`openPaletteWithButton` helpers, Esc-closes-and-restores-to-opener assertion (`await expect(opener).toBeFocused()`), and a second test proving the shortcuts overlay traps focus (`Tab` from Close button lands back on Close, single focusable). This is the exact pattern D-11 extends to drawer/modal. |
| `priv/dev/package.json` — axe pin location | **Confirmed.** Currently `dependencies: { playwright: "1.60.0" }`, `devDependencies: { "@playwright/test": "1.60.0" }`; no `@axe-core/playwright` present today (grep-confirmed absent). `package-lock.json` **is** git-tracked (confirmed via `git ls-files`), so the lockfile-commit discipline D-05 references is real and already in place. |
| `priv/dev/shots.mjs` — 2 viewports today | **Confirmed exact.** `VIEWPORTS = [{ name: 'desktop', width: 1280, height: 900 }, { name: 'mobile', width: 375, height: 812 }]` at lines 176-178. |
| `priv/dev/contact_sheet.mjs` | **Confirmed** — reads dated PNG capture dirs, emits an HTML before/after grid, "No Playwright dependency — plain Node.js fs/path only" (moduledoc). |
| `.github/workflows/ci.yml` — e2e job + ci-gate hard-fail | **Confirmed, line numbers accurate to within 3.** `e2e:` job header at 30; `mix scoria.ui.e2e --base-url ...` step at 116; `ci-gate` job `needs: [verify, e2e]` at 130, hard-fail logic (`if [[ "$E2E" != "success" ]]; then exit 1; fi`) at 143-145; `if: always()` on the Playwright-report upload step at 119, `name: playwright-report` at 122. |
| `test/scoria_web/token_contrast_guard_test.exs` | **Confirmed and stronger than cited** — this guard **already** runs its assertion set against both `:dark` (default) and `:light` themes via two `describe` blocks (`load_tokens(:dark)`/`load_tokens(:light)`), i.e. D-09's dual-theme requirement is **already satisfied** for this specific guard; D-09's remaining work is exclusively the axe e2e side. |
| `test/scoria_web/ds06_drift_guard_test.exs` / `ui_drift_guard_test.exs` | **Confirmed** as the source-scan idiom to model D-08/D-19 on — `ui_drift_guard_test.exs` is a clean single-assertion example: `Path.wildcard` + per-file `Regex.match?` + collect offenders + one `assert offenders == []`. Directly reusable structure for D-19's guard. |
| `mix.exs:160` — `priv/dev` excluded from `package.files` | **Confirmed exact.** Comment "priv/dev intentionally excluded..." begins at line 160 inside the `files:` list (144-169). |
| `lib/mix/tasks/scoria.ui.e2e.ex` — `--base-url`/seed/`--no-seed-approvals` | **Confirmed** — `@switches [base_url: :string, url: :string, seed_approvals: :boolean]`; defaults `seed_approvals` true via `Keyword.get(opts, :seed_approvals, true)`. |
| `lib/scoria_web/live/` primary pages for D-15 | **Confirmed full enumeration**: `approvals_live/index.ex`, `review_queue_live.ex` (flat file, not a dir), `incidents_live/index.ex`, `workflow_live/index.ex` (+ `workflow_live/show.ex` detail), `dataset_live/index.ex`, `connectors_live/index.ex`, `prompt_live/index.ex` (+ `prompt_live/release_workbench_live.ex`), `eval_spec_live/index.ex`, `orchestrator_live.ex` (Home), `coming_soon_live.ex`. All match CONTEXT.md's list; one extra page (`release_workbench_live.ex`) exists but wasn't named — not required for D-15's "~4 representative" set. |

## Already-Green Confirmations

Independently re-derived (not trusted from CONTEXT.md) via direct grep/read against the current tree — these must stay green after any Phase 40 guard lands:

1. **Zero `transition: all` / `transition-property: all`** anywhere in `assets/css/` — grep returns zero matches. (D-19(i))
2. **Every `transition:` declaration in `04-components.css` (8 total, lines 106/128/238/650/967/1012/1243/1277) uses `var(--scoria-dur-*) var(--scoria-ease-*)`** for both duration and easing — zero raw literals in any `transition`. (Supports D-19(ii)'s transition half.)
3. **Only two `animation:` declarations use raw (non-token) values**: `scoria-skeleton-pulse 1.5s ease-in-out infinite` (`04-components.css:1610`) and `scoria-approval-pulse 600ms var(--scoria-ease-in-out) 2` (`05-motion.css:46`, duration only — see Anchors ADDENDUM above). Every other `animation:` decl (`04-components.css:887/910/934`, `05-motion.css:46`'s easing) is fully tokenized.
4. **All 6 `@keyframes` in `05-motion.css`** (`scoria-fade`, `scoria-pop`, `scoria-slide`, `scoria-slide-inline-start`, `scoria-approval-pulse`, `scoria-skeleton-pulse`) animate **only** `opacity`/`transform`/`border-color` — no other property appears in any keyframe body. (D-19(iii))
5. **No `@keyframes` exist outside `05-motion.css`** — `grep -rn "@keyframes" assets/css/` returns matches only in that one file. (D-19(iv))
6. **`token_contrast_guard_test.exs` already asserts both dark and light themes** (two `describe` blocks, `load_tokens(:dark)`/`load_tokens(:light)`) — D-09's dual-theme intent is pre-satisfied for the browserless side.
7. **`Phoenix.Component.focus_wrap/1`, `Phoenix.LiveView.JS.focus_first/1,2`, `push_focus/1,2`, `pop_focus/0,1`** all exist in `phoenix_live_view` **1.1.30** (the exact version pinned in `mix.lock`), verified by reading the vendored source of that exact version from a sibling project's `deps/` cache (`phoenix_component.ex:3173`, `js.ex:1018-1061`). D-10's "no new Hex dep" claim is fully verified, not assumed.
8. **`@axe-core/playwright` is confirmed absent** from `priv/dev/package.json` today (grep-confirmed) — D-05 is additive, not a version bump.
9. **`priv/dev/package-lock.json` is git-tracked** (`git ls-files` confirms) — the "exact-pinned + lockfile-committed" discipline D-05 references already exists as a practiced pattern in this repo, it is not a new process to establish.

## Dependency-Pin Guidance: `@axe-core/playwright`

Verified directly against the npm registry (`npm view`) and against Deque's own downloads API — **VERIFIED, not assumed**:

| Field | Value |
|---|---|
| Latest version | `4.12.1` (published 2026-06-23) |
| Peer dependency | `playwright-core: >= 1.0.0` — compatible with the pinned `playwright@1.60.0` |
| Bundled `axe-core` dependency | `"axe-core": "~4.12.1"` — a **tilde range**, meaning `npm install` alone would allow silent patch-level drift (e.g. to a hypothetical `4.12.2`) even with `@axe-core/playwright` exact-pinned. D-05 says "pin transitive `axe-core` too so a floating release can't flip CI" — this requires an explicit npm `overrides` entry, not just pinning the parent package. |
| Repository | `github.com/dequelabs/axe-core-npm` (Deque Systems — the axe-core maintainer's own org; this is as close to "official source" as an npm package gets) |
| Package age | Created 2021-06-02 (~5 years old) |
| Weekly downloads | 5,103,622 (2026-06-26 to 2026-07-02) |
| `postinstall`/`prepare` script risk | Has a `prepare` script (`npx playwright install && npm run build`) — this only executes when installed as a **git dependency** or in the package's own dev loop, not when installed as a normal registry tarball dependency (the published tarball already ships built `dist/`). No `postinstall` script exists. Low risk. |
| Verdict | **OK** — legitimate, official, high-signal package. Not `[ASSUMED]`: discovered via `npm view`/registry inspection (a tool call against the authoritative registry), not via WebSearch or training-data recall of a package name. |

**Recommended `priv/dev/package.json` change:**
```json
{
  "devDependencies": {
    "@playwright/test": "1.60.0",
    "@axe-core/playwright": "4.12.1"
  },
  "overrides": {
    "axe-core": "4.12.1"
  }
}
```
The `overrides` block is what actually satisfies D-05's "pin transitive `axe-core` too" — pinning only `@axe-core/playwright` leaves `axe-core` on a `~4.12.1` range inside its own `node_modules` unless overridden. Run `npm --prefix priv/dev install` after the edit so `package-lock.json` (git-tracked) reflects the pin, matching the existing `playwright`/`@playwright/test` discipline.

**`gsd-tools query package-legitimacy check` was not available in the installed toolchain version** (`Unknown command: package-legitimacy` — the local `gsd-tools.cjs` predates that seam). The verdict above was produced manually per the protocol's fallback path: direct `npm view` (version/peerDeps/dependencies/scripts/repository/time.created) + the public npm downloads API (`api.npmjs.org/downloads/point/last-week/...`) + repository-org identity check. This satisfies Steps 1-3 of the Package Legitimacy Gate without the seam command.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Focus trap for `modal`/`drawer` | A second hand-written trap parallel to `scoria.js`'s `trapFocus` | `Phoenix.Component.focus_wrap/1` (core Phoenix, verified present at the pinned version) | One focus-trap implementation per D-10; `focus_wrap`'s client behavior ships in the LiveView JS bundle itself and needs zero `scoria.js` changes (see Architectural Responsibility Map). |
| WCAG contrast/ARIA/name-role-value scanning | A custom DOM-walking a11y checker | `@axe-core/playwright` (verified OK, official Deque package) | axe-core is the industry-standard engine; hand-rolling would re-derive years of WCAG rule logic with worse coverage. |
| Bounding-box occlusion checks (D-16(5), D-11 SC 2.4.11) | Two separate ad-hoc geometry checks | One shared `boxesIntersect(a,b)` helper in `priv/dev/e2e/lib/` (D-17) | Both specs need the identical primitive; a single helper prevents subtle divergence in the intersection math. |
| Reduced-motion collapse detection | A hardcoded `'0s'` string comparison | The `isInstantDuration` pattern already proven in `phase16_parity.spec.mjs` (accepts `'0s'`, `'0.001ms'`, and Chromium's `'1e-06s'` serialization, comma-split for shorthand) | Chromium serializes `0.001ms` as scientific notation; a naive string equality check silently false-passes/fails depending on which form is returned. |

**Key insight:** every piece of proof infrastructure this phase needs already has a working, tested precedent in this repo (`command_palette.spec.mjs` for keyboard flows, `phase16_parity.spec.mjs` for reduced-motion + overflow, `ui_drift_guard_test.exs`/`ds06_drift_guard_test.exs` for source-scan guards). The job is extension, not invention.

## Common Pitfalls

### Pitfall 1: `target-size` axe rule is disabled by default
**What goes wrong:** D-06 assumes `target-size` (2.5.8) fires report-only against the lab/real pages once the tag list includes `wcag22aa`. It does not fire at all.
**Why it happens:** Verified by extracting the rule definition directly from the installed `axe-core@4.12.1` bundle: `{ id: 'target-size', enabled: false, tags: ['cat.sensory-and-visual-cues', 'wcag22aa', 'wcag258'], ... }`. axe-core's tag-based rule selection (`runOnly: { type: 'tag', values: [...] }`) does **not** implicitly re-enable a rule whose static definition has `enabled: false` — that requires an explicit `rules` override.
**How to avoid:** the axe run options in the new `a11y_axe.spec.mjs` must include `rules: { 'target-size': { enabled: true } }` in addition to the tag list, or D-06's target-size clause silently produces zero signal forever.
**Warning signs:** the axe report/baseline shows zero `target-size` violations even on specimens known to have small touch targets.

### Pitfall 2: the D-10 fix touches more files than "ui.ex + maybe scoria.js"
**What goes wrong:** treating D-10 as a single-file (`ui.ex`) change under-scopes the plan; `push_focus()` must run at the **opener**, which is not colocated with `<.drawer>`/`<.modal>` in `ui.ex`.
**Why it happens:** the drawer's `@show` boolean and the modal's `@show` boolean are driven by assigns set in the calling LiveView, and in `approvals_live/index.ex` the actual row-click trigger (`phx-click={@select_event}`, `select_event="select_approval"`) lives inside a **separate** function component, `lib/scoria_web/components/approval_inbox_component.ex` — not in `approvals_live/index.ex` itself, and not in `ui.ex`. Similar fan-out exists for `dataset_live/index.ex`, `connectors_live/index.ex` (two separate drawers), `workflow_live/show.ex`, and `prompt_live/release_workbench_live.ex` (two separate modals).
**How to avoid:** scope D-10 as (a) one `ui.ex` change (add `focus_wrap` + internal `pop_focus` wiring to `on_dismiss`) plus (b) N opener-site changes (add `JS.push_focus()` to whatever `phx-click`/`patch` currently opens each drawer/modal instance) — enumerate all ~7 opener call sites before estimating the task.
**Warning signs:** after "fixing" only `ui.ex`, `activeElement` after Esc/close is `<body>` instead of the original trigger, because nothing ever called `push_focus()` to remember it.

### Pitfall 3: `focus_wrap/1`'s own `id={@id}` collides with the existing `@id` on modal/drawer's outer shell
**What goes wrong:** `focus_wrap/1` renders `<div id={@id} phx-hook="Phoenix.FocusWrap">...</div>` as its **own** wrapper. `modal/1`/`drawer/1` already put `id={@id}` on their outer shell `<div>`/(implicit) container. Passing the same `@id` to `focus_wrap` inside that shell creates a duplicate DOM id.
**How to avoid:** nest `<.focus_wrap id={"#{@id}-focus"}>` around the panel body (inside the `role="dialog"` element), not around the whole shell, and not reusing `@id` verbatim.
**Warning signs:** duplicate-id warnings in devtools console; LiveView DOM patching misbehaving on the wrong element when two nodes share an id.

### Pitfall 4: the `command_palette`/`mobile-nav` trap pattern is architecturally a poor fit for `modal`/`drawer` as-is
**What goes wrong:** naively porting `scoria.js`'s `trapFocus`/`focusableElements`/`restoreFocus` onto `modal`/`drawer` without adapting for lifecycle differences.
**Why it happens:** `CommandPalette`/`MobileNav` are permanently-mounted DOM nodes toggled via a `hidden`/`data-state` attribute (the hook never remounts). `modal/1`/`drawer/1` render conditionally with `:if={@show}` — the element is **added to and removed from the DOM** on each open/close (a full LiveView patch), which is a fundamentally different mount lifecycle than the always-present palette. A raw port of the JS-hook trap would need to reattach on every mount, whereas `focus_wrap`'s `phx-hook="Phoenix.FocusWrap"` is designed exactly for this conditional-mount pattern (it re-runs `mounted()` naturally each time LiveView re-inserts the element).
**How to avoid:** this is exactly why D-10 says "prefer `focus_wrap` for idiom" — this research's mount-lifecycle finding is independent corroboration for that preference, not just stylistic taste.

### Pitfall 5: excluding `best-practice` correctly avoids the classic false-positives, but for a subtly different reason than expected
**What goes wrong:** assuming `region`/`heading-order`/`landmark-one-main`/`duplicate-id` are all excluded purely because they're tagged `best-practice`.
**Why it happens:** `region`, `heading-order`, `landmark-one-main` ARE `best-practice`-only tagged (correctly excluded by D-06's tag list) — but `duplicate-id`/`duplicate-id-active` are actually tagged `wcag2a-obsolete`/`deprecated` **and** ship with `enabled: false` by default in axe-core 4.12.1. They would not fire even if `best-practice` were included.
**How to avoid:** no action needed — D-06's exclusion is still correct, just for a slightly different reason for `duplicate-id` specifically. Noting this so nobody "fixes" the tag list under a wrong mental model later.

## Validation Architecture

`workflow.nyquist_validation` is absent from `.planning/config.json` — treated as enabled (default). This section maps A11Y-01, A11Y-02, MOTION-01, RESP-01 to the D-07 two-lane proof model.

### Test Framework

| Property | Value |
|----------|-------|
| Framework (Lane A — browserless) | ExUnit (`mix test`), `async: true` |
| Framework (Lane B — browser) | Playwright `@playwright/test` 1.60.0, chromium project only |
| Config file | Lane A: none (plain `ExUnit.Case` modules); Lane B: `priv/dev/e2e/playwright.config.mjs` |
| Quick run command (Lane A) | `mix test test/scoria_web/` (targeted: `mix test test/scoria_web/ui_drift_guard_test.exs test/scoria_web/token_contrast_guard_test.exs`) |
| Quick run command (Lane B, local) | `mix scoria.ui.e2e --base-url http://localhost:4799/scoria` (requires `make dev` running) |
| Full suite command | `mix test` (Lane A) + the CI `e2e` job (`.github/workflows/ci.yml`, boots `mix phx.server` then runs `mix scoria.ui.e2e`) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Primary Owner (D-07) | Automated Command | File Exists? |
|--------|----------|-----------|----------------------|--------------------|--------------|
| A11Y-01 | Keyboard tab-in/trap/Esc/restore on drawer + modal | e2e (Playwright) | keyboard-e2e | `npx --prefix priv/dev playwright test drawer_focus.spec.mjs modal_focus.spec.mjs` (new files, pattern from `command_palette.spec.mjs`) | ❌ new files, Wave 0/1 |
| A11Y-01 | Focus not obscured by sticky approval footer (SC 2.4.11) | e2e (Playwright) | keyboard-e2e | same drawer spec, `boxesIntersect(focusedRect, footerRect)` assertion | ❌ new — depends on `boxesIntersect` helper (D-17) |
| A11Y-01 | Live-patch focus survival on open drawer (D-13) | e2e (Playwright), **warning-grade collector** | keyboard-e2e | same drawer spec; `console.warn` + `testInfo.attach()`, no throwing `expect()` | ❌ new |
| A11Y-01 | Tables/disclosures/copy-controls/forms structural contract | browserless (LiveViewTest / source-scan) | source-scan | `mix test test/scoria_web/` (extend `ui_component_test.exs` or a new file) | ⚠ partial — pattern exists, new assertions needed |
| A11Y-02 | Contrast/ARIA/name-role-value, both themes | e2e (Playwright, axe-core) | axe | `npx --prefix priv/dev playwright test a11y_axe.spec.mjs` (new) | ❌ new file, Wave 0/1 |
| A11Y-02 | Icon-button accessible names, no color-only status, native semantics presence | browserless (source-scan) | source-scan | `mix test test/scoria_web/` (new guard, model on `ui_drift_guard_test.exs`) | ❌ new file |
| A11Y-02 | Contrast confirmatory floor, both themes | browserless (pure Elixir luminance calc) | source-scan (confirmatory) | `mix test test/scoria_web/token_contrast_guard_test.exs` | ✅ already exists and already dual-theme |
| MOTION-01 | Tokenized durations/eases except allow-listed exceptions; keyframes transform/opacity/border-color only; no new `@keyframes` outside `05-motion.css` | browserless (source-scan) | source-scan | `mix test` (new guard file, model on `ui_drift_guard_test.exs`'s `Path.wildcard` + `Regex.match?` idiom) | ❌ new file |
| MOTION-01 | Reduced-motion collapses computed `animationDuration`/`transitionDuration` | e2e (Playwright) | axe/keyboard-e2e n/a — direct computed-style assertion | `npx --prefix priv/dev playwright test phase16_parity.spec.mjs` (extend; pattern already fully proven) | ✅ pattern exists on 2 pages, extend to more surfaces per D-13's skeleton at line 1610 |
| RESP-01 | No document h-overflow at 6 widths on ~4 representative pages | e2e (Playwright) | responsive-scan | `npx --prefix priv/dev playwright test responsive_scan.spec.mjs` (new, generalizes `phase16_parity.spec.mjs`'s proven 375px pattern) | ❌ new file, Wave 0/1 |
| RESP-01 | No essential element clipped off-viewport (curated selectors) at 320/375/768 | e2e (Playwright) | responsive-scan | same new spec | ❌ new |
| RESP-01 | Table overflow contained not leaked; `:mobile_summary` swap correctness | e2e (Playwright) | responsive-scan | same new spec — `phase16_parity.spec.mjs` already proves the "page doesn't overflow even though table viewport does" pairing on one page (373-94); generalize | ⚠ partial (1 page proven, generalize) |
| RESP-01 | No fixed/floating region covering nav (excl. sticky footer/command palette/mobile-nav/scrims) | e2e (Playwright) | responsive-scan | same new spec, `boxesIntersect` | ❌ new — depends on `boxesIntersect` helper |
| RESP-01 | 24px min target at ≤375 (regression floor, not the axe target-size rule) | e2e (Playwright) | responsive-scan | same new spec | ❌ new |

### Sampling Rate
- **Per task commit:** Lane A quick command (`mix test test/scoria_web/` or the specific new/changed guard file) — sub-second, must run every commit per D-04.
- **Per wave merge:** full Lane A (`mix test`) + full Lane B (`mix scoria.ui.e2e --base-url ...` against a locally running `make dev` server, or push to a PR and let the required `e2e` CI job run it).
- **Phase gate:** both `verify` and `e2e` CI jobs green (the existing `ci-gate` `needs: [verify, e2e]` hard-fail, `.github/workflows/ci.yml:127-146`) before `/gsd-verify-work`. **Critical per D-04:** any new Lane B assertion on a not-yet-fixed surface MUST be a non-throwing collector (`console.warn` + `testInfo.attach()`) until its fix lands in the same commit — never let a new `expect()` merge ahead of its fix, or it red-walls the required gate.

### Wave 0 Gaps
- [ ] `priv/dev/e2e/a11y_axe.spec.mjs` — covers A11Y-02 (axe scan, both themes, report-only baseline first per D-06); requires the `@axe-core/playwright` + `overrides` package.json edit above landed first.
- [ ] `priv/dev/e2e/drawer_focus.spec.mjs` + `priv/dev/e2e/modal_focus.spec.mjs` (or one combined file) — covers A11Y-01 keyboard-driving on the D-10 fix target; depends on the D-10 fix landing in the same commit/wave (fix-and-assert-atomic per D-04, since this is a hard-fail-eligible surface once fixed).
- [ ] `priv/dev/e2e/responsive_scan.spec.mjs` — covers RESP-01; can be authored independent of D-10 (motion/focus fixes are unrelated to layout).
- [ ] `priv/dev/e2e/lib/boxes_intersect.mjs` (or similar name — D-17 discretion) — shared helper both `drawer_focus.spec.mjs` (D-11 dynamic occlusion) and `responsive_scan.spec.mjs` (D-16(5) static occlusion) import.
- [ ] A new browserless motion source-scan guard (e.g. `test/scoria_web/motion_drift_guard_test.exs`) — covers MOTION-01's static assertions; model directly on `ui_drift_guard_test.exs`'s `Path.wildcard` + `Regex.match?` + collect-offenders idiom. **Must allow-list both `scoria-skeleton-pulse` and `scoria-approval-pulse` by animation-name** (see Anchors ADDENDUM/Pitfall discussion) or it will false-RED on landing day.
- [ ] A new browserless a11y source-scan guard (e.g. `test/scoria_web/a11y_structural_guard_test.exs`) — covers A11Y-02's D-08 structural assertions (icon-button names, color-only-status, native-semantics presence).
- [ ] `priv/dev/package.json` + `priv/dev/package-lock.json` edits (the `@axe-core/playwright` + `overrides` block above) — prerequisite for the axe spec.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `focus_wrap`'s client hook (`Phoenix.FocusWrap`) is auto-registered by `live_socket.js` regardless of Scoria's own custom `hooks: Hooks` object passed to `new LiveSocket(...)`. | Architectural Responsibility Map, Pitfall 4 | **Low risk** — this was verified by reading `live_socket.js:358` (`name.startsWith("Phoenix.") && Hooks[name.split(".")[1]]`) at the exact pinned `phoenix_live_view` version from a sibling project's `deps/` cache, not assumed from training data. Residual risk is only that Scoria's actual installed `deps/phoenix_live_view` (not yet directly inspected in *this* repo, since `mix deps.get` wasn't run here) could theoretically diverge from the sibling cache — extremely unlikely since `mix.lock` pins the identical `1.1.30` hash. |
| A2 | The `axe-core@4.12.1` `target-size` rule defaults to `enabled: false` — verified by extracting it directly from the downloaded `axe-core@4.12.1` npm tarball's bundled `axe.js`, not from a blog post or training-data recall. | Pitfall 1, Dependency-Pin Guidance | Low — this is a direct read of the shipped artifact at the exact version that will be installed. If Deque ships a `4.12.2` patch that changes this default before the plan lands, re-verify at install time. |
| A3 | The opener-site fan-out for D-10 (7 call sites across 5 files) is a complete enumeration. | Pitfall 2 | Medium — found via `grep -rn "<.drawer\b\|<.modal\b"`; a dynamically-constructed component call (unlikely in this codebase's style, but not exhaustively ruled out) could exist outside grep's reach. Re-grep at planning time to confirm no new call sites landed between this research and plan authoring. |

**If this table is empty:** N/A — see rows above; all are HIGH-confidence findings from direct tool verification with only narrow, explicitly-scoped residual risk.

## Open Questions

1. **Should the D-19 motion guard allow-list by animation-name or by an explicit two-entry literal list?**
   - What we know: two exceptions exist today (`scoria-skeleton-pulse`, `scoria-approval-pulse`'s duration).
   - What's unclear: whether a future Phase-41-era third exception should extend an allow-list array or require a fresh red-team pass. Not a phase-40 blocker either way.
   - Recommendation: allow-list by `@keyframes`/animation **name**, not by matching the literal duration string — more resilient to a future duration edit on either exception.

2. **Does the axe `rules: { 'target-size': { enabled: true } }` override need to also flow into the *curated real-page allow-list* scan (the eventual assert-zero surface), or only the report-only full-lab scan?**
   - What we know: D-06 says target-size stays report-only throughout Phase 40 regardless.
   - What's unclear: exact spec-file structure (one file with two `test.describe` blocks vs. two files) is Claude's Discretion; this only affects where the `rules` override needs to be threaded.
   - Recommendation: set the `rules` override once in a shared axe-run helper (e.g. `priv/dev/e2e/lib/axe.mjs`) that both the full-lab and curated-page scans import, so the override can't drift between the two.

## Sources

### Primary (HIGH confidence — direct tool verification against the current repo or the exact pinned dependency)
- `lib/scoria_web/ui.ex`, `assets/js/scoria.js`, `assets/css/05-motion.css`, `assets/css/04-components.css`, `assets/css/02-tokens.css` — read/grepped directly, current tree.
- `priv/dev/e2e/*.spec.mjs`, `priv/dev/e2e/lib/ready.mjs`, `priv/dev/e2e/playwright.config.mjs`, `priv/dev/package.json`, `priv/dev/shots.mjs`, `priv/dev/contact_sheet.mjs` — read directly, current tree.
- `.github/workflows/ci.yml`, `mix.exs`, `mix.lock`, `test/scoria_web/*_guard_test.exs` — read directly, current tree.
- `npm view @axe-core/playwright` (version/peerDependencies/dependencies/scripts/repository/time.created) — live npm registry query.
- `https://api.npmjs.org/downloads/point/last-week/@axe-core/playwright` — live npm downloads API.
- `axe-core@4.12.1` tarball (`npm pack`), `axe.js` bundle inspected directly via Node for rule `enabled`/`tags` metadata (`target-size`, `region`, `heading-order`, `landmark-one-main`, `duplicate-id`, `color-contrast`).
- `deps/phoenix_live_view` (pinned `1.1.30`, matching Scoria's own `mix.lock`) source read from a sibling project's dependency cache: `lib/phoenix_component.ex` (`focus_wrap/1`), `lib/phoenix_live_view/js.ex` (`focus_first`/`push_focus`/`pop_focus`), `assets/js/phoenix_live_view/hooks.js` (`FocusWrap` client hook), `assets/js/phoenix_live_view/live_socket.js` (framework-hook resolution independent of app-supplied `hooks:`).

### Secondary (MEDIUM confidence)
- [Axe-core 4.5: First WCAG 2.2 Support and More - Deque](https://www.deque.com/blog/axe-core-4-5-first-wcag-2-2-support-and-more/) — background on `target-size` rule origin, corroborated by direct bundle inspection (Primary).
- [axe-core rule-descriptions.md](https://github.com/dequelabs/axe-core/blob/develop/doc/rule-descriptions.md) — general rule catalog reference.

### Tertiary (LOW confidence)
- None used as a basis for any claim in this document.

## Metadata

**Confidence breakdown:**
- Anchor accuracy: HIGH — every cited path:line was opened and checked, not trusted.
- Package legitimacy (`@axe-core/playwright`): HIGH — verified via npm registry tool calls + downloads API + repo-org identity, not WebSearch/training recall of the package name.
- `focus_wrap`/`JS` API availability: HIGH — verified against the exact pinned version's source, not general Phoenix knowledge.
- Motion guard precision (the 600ms addendum): HIGH — independently re-derived via grep against `02-tokens.css`'s actual token values, not inferred.
- Validation Architecture test-type/owner mapping: HIGH — directly derived from the already-locked D-07 coverage map, cross-checked against existing spec file contents.

**Research date:** 2026-07-03
**Valid until:** ~14 days (fast-moving: pins npm package versions and CI line numbers that could shift with any commit to `ci.yml`/`04-components.css`/`05-motion.css` before the plan lands — re-verify anchors if significant time passes before planning).
