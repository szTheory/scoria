# Phase 16: Motion + responsive + theme parity - Research

**Researched:** 2026-06-13  
**Domain:** Phoenix LiveView dashboard CSS/JS polish, responsive layout, motion accessibility, and theme contrast  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Mobile Shell Contract
- **D-01:** Below `md` (`<768px`), the dashboard shell becomes a single-column content layout. The current fixed `248px` sidebar grid must not remain visible at mobile width.
- **D-02:** Use a compact sticky mobile topbar with brand/current page context, a `Menu` control, command palette access, and theme toggle access. Command palette is additive, not the only navigation path.
- **D-03:** The `Menu` control opens an accessible off-canvas nav drawer that renders the existing `DashboardNav` Operate / Improve / Configure groups and active state. Do not create a separate mobile nav SSOT.
- **D-04:** The mobile nav drawer needs scrim click, Escape dismiss, focus containment/restore, scrollable nav content, and reduced-motion-safe open/close behavior. Animate opacity/transform only; never animate width, left/right layout, or grid columns.
- **D-05:** Mobile global breadcrumbs should be compact. Object-specific identity, origin, and provenance remain in `object_header` / page content rather than consuming the entire topbar.
- **D-06:** Do not use horizontal nav, bottom nav, or command-palette-only navigation in Phase 16. Those patterns hide too much of Scoria's IA, split navigation truth, or overfit a dedicated mobile responder app that Scoria is not building in this milestone.

### Responsive Tables and Evidence Surfaces
- **D-07:** Centralize table responsiveness in `ScoriaWeb.UI.table/1` and scoped component CSS. The default table rendering should include a real overflow viewport so wide tables remain usable at 375px.
- **D-08:** Add opt-in mobile row summary behavior to `<.table>` for scan-heavy tables where a compact mobile summary is materially better than horizontal scroll alone. Summaries should expose the object label, status, key scalar/time, and primary action without hiding critical state.
- **D-09:** Preserve real table semantics on desktop. Do not globally convert all tables into cards or block-layout pseudo-tables.
- **D-10:** Use mobile summaries for Runs, Review Queue, Connectors, Dataset Builder, and similar scan surfaces where the user is choosing an object to inspect. Keep dense comparison/detail surfaces honest: overflow table, stacked evidence sections, or object-detail stack depending on the existing component.
- **D-11:** Workflow trace/evidence mobile layout should stack the trace/span list first and selected evidence below it. It should not become a table-card clone or invent a separate mobile-only trace application.
- **D-12:** Replace unsupported responsive utility usage (`sm:grid-cols-*`, arbitrary `lg:grid-cols-[...]`, arbitrary `xl:grid-cols-[...]`) with scoped Scoria component classes or add explicit supported utilities only when they are general and token-bound.
- **D-13:** Sticky table headers, action columns, and row selection must work inside the chosen scroll container. Selection and status must include text/structure (`aria-selected`, `aria-current`, badges, or labels), never color alone.
- **D-14:** Per-screen custom mobile forks are allowed only for true object inspectors when the shared component cannot express the layout. They are not the default for shared tables.

### Motion Contract
- **D-15:** Adopt a "strict interactions, allowlisted state indicators" motion contract. User-triggered interaction motion is capped at 200ms and uses transform and/or opacity only.
- **D-16:** `assets/css/05-motion.css` is the only home for keyframes and named motion primitives. New one-off keyframes in LiveViews/components are out of bounds.
- **D-17:** Modal opening uses `scoria-pop`: opacity plus small Y/scale, 150ms. Scrim fades at 100ms. Reduced motion removes scale/slide or makes the transition effectively instant.
- **D-18:** Drawer opening uses an edge-origin slide/fade at 200ms max. It may be renamed or split into `scoria-slide-inline-end`, but it must not animate width, left/right, or layout.
- **D-19:** Command palette and toast motion should be opacity-only fade at roughly 100-120ms. Existing JS may delay `hidden` long enough for the fade, but it must not own choreography beyond keyboard/focus behavior.
- **D-20:** Skeleton animation is an allowlisted loading-state exception only: opacity pulse, no shimmer, no transform, no layout motion, static under `prefers-reduced-motion`, and replaced when async content resolves.
- **D-21:** Approval/attention pulse is an allowlisted finite state-indicator exception only: approval-required or similar urgent operator attention, maximum two cycles, always paired with visible explanatory text, and static under reduced motion. If a motion guard is strict, prefer outline/opacity/filter over border-color animation.
- **D-22:** Hover and active affordances may use instantaneous or short color/border/shadow changes, plus a tiny active button press if retained. Do not use row translate, bounce, spring, fire/sparkle/lava effects, infinite attention loops, route/page-load cascades, shimmer loaders, or `transition: all`.

### Focus, Status, and Theme Parity
- **D-23:** Preserve and audit the scoped global `:focus-visible` rule, but ensure every interactive element still exposes a visible focus state in both dark and light themes after component-specific backgrounds and overflow containers are applied.
- **D-24:** Status is never communicated by color alone. Badges, selected rows, highlighted approvals, table sort state, traces, and evidence outcomes need visible text, icons, ARIA state, or structural indicators in addition to tone colors.
- **D-25:** Keep the semantic token model. Do not touch `assets/css/02-tokens.css` for cosmetic preference. Token changes are reserved for WCAG/accessibility defects or genuine coherence breaks.
- **D-26:** Full light/dark parity means both themes are first-class surfaces. Fix component/state-specific contrast or focus issues at the semantic component layer before per-screen overrides.
- **D-27:** Do not reintroduce raw palette classes. DS-06 stays a ratchet and `ui.ex` remains zero raw-palette.

### Verification and Proof Level
- **D-28:** Add targeted Phase 16 parity smoke checks under the existing `mix scoria.ui.e2e` Playwright lane rather than waiting entirely for Phase 17.
- **D-29:** The targeted browser checks should cover: no horizontal page overflow at 375px on the shell and key table screens, visible focus styles on representative links/buttons/inputs, reduced-motion behavior for known animated primitives, and light/dark theme-toggle smoke on high-risk screens.
- **D-30:** Use Playwright viewport/media emulation and computed-style checks where LiveViewTest cannot see browser truth. Keep assertions stable and selector-light; avoid screenshot comparisons in CI.
- **D-31:** Add a deterministic token contrast guard only if it can reuse `assets/css/02-tokens.css` and brandbook-approved pairings without creating a parallel token source. The guard is a floor, not a replacement for visual review.
- **D-32:** Do not add full visual-regression screenshot baselines, full axe/all-screen/theme/viewport CI, or broad screenshot critique expansion in Phase 16. Phase 17 owns final screenshot/contact-sheet proof and docs. Axe can be considered later when Scoria is ready for a standing browser-a11y lane.

### Cross-Screen Polish Rules
- **D-33:** Phase 16 should prefer design-system fixes that pay dividends across all screens: shell, table, drawer/modal, command palette, notebook/evidence primitives, form controls, focus states, and responsive utility coverage.
- **D-34:** Keep LiveView and Phoenix library ergonomics boring: CSS-first, component-owned, mount-prefix-safe, no new JS framework, no new CSS architecture, no global reset outside `.scoria-root`.
- **D-35:** All new UI copy follows Scoria brand voice: calm, exact, useful. Prefer operator evidence verbs and plain consequence copy. Avoid hype, magic language, hidden chain-of-thought language, or decorative motion copy.

### the agent's Discretion
- Exact component APIs for mobile summary slots, CSS class names, motion guard implementation, selector lists for parity smoke tests, and plan slicing are planner/executor discretion.
- The planner may decide whether mobile nav drawer uses the existing command-palette focus helper utilities or a new small hook, as long as it remains scoped to the dashboard and does not duplicate navigation data.
- The planner may choose the first representative screens for smoke coverage, but should include Home/shell, one shared-table scan screen, one object/evidence screen, and one overlay path.

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Dedicated mobile responder mode, bottom navigation, or saved mobile persona lens.
- Full command-palette object search beyond existing nav/recent/static action behavior.
- Full axe/all-screen/theme/viewport browser accessibility lane.
- CI visual regression screenshot baselines and approval workflow.
- Phase 17 final contact sheets, final audit deltas, and MAINTAINERS design-system docs.
- No todo matches were found for Phase 16, so no todos were folded or reviewed.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MOTION-01 | Interactions use restrained, brand-tied motion, <=200ms, transform/opacity-only, reduced-motion-safe, and avoid brand antipatterns. | Existing motion primitives live in `assets/css/05-motion.css`; LiveView JS defaults transition time to 200ms; W3C and MDN support reduced-motion handling. [VERIFIED: codebase grep] [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.JS.html] [CITED: https://www.w3.org/WAI/WCAG21/Understanding/animation-from-interactions] [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion] |
| MOTION-02 | Every interactive element has visible focus-visible state and status is never conveyed by color alone. | Current reset has a scoped `:focus-visible` outline; WCAG non-text/focus guidance requires visible, sufficiently contrasted state indicators; `ScoriaWeb.UI.badge/1` and toast icons already encode non-color-only status patterns. [VERIFIED: codebase grep] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html] |
| MOTION-03 | Dashboard is mobile-first; shell and tables adapt at `md / lg / xl`. | Current shell is a fixed `248px` sidebar grid; current table lacks an overflow viewport; responsive utility scan found unsupported `sm:*` and arbitrary `lg/xl:grid-cols-[...]` callsites to replace. [VERIFIED: codebase grep] [CITED: https://designsystem.digital.gov/components/table/] [CITED: https://cfpb.github.io/design-system/components/tables] |
| MOTION-04 | Every screen meets the polish bar in light and dark themes with WCAG AA contrast. | Tokens provide semantic light/dark surfaces; Playwright can emulate viewport and color scheme; W3C text contrast minimum is 4.5:1 for normal text and non-text UI cues require 3:1. [VERIFIED: codebase grep] [CITED: https://playwright.dev/docs/emulation] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html] |
</phase_requirements>

## Summary

Phase 16 should be planned as a cross-cutting design-system hardening pass, not as per-screen redesign. The highest-leverage plan is: make the shell responsive and add a mobile nav drawer from the existing `DashboardNav` SSOT; upgrade `ScoriaWeb.UI.table/1` with an overflow viewport plus opt-in mobile summaries; normalize responsive layouts that currently rely on unsupported utility syntax; and add targeted Playwright checks for browser-only truths. [VERIFIED: codebase grep]

The current code already has the right foundations: scoped CSS layers, semantic tokens, a global `.scoria-root :where(:focus-visible)` rule, shared table/drawer/modal/skeleton/toast components, a command-palette focus helper, and a dev-only Playwright lane exposed as `mix scoria.ui.e2e`. [VERIFIED: codebase grep] Phase 16 should extend those foundations instead of introducing Tailwind, a new JS framework, a visual regression stack, or a separate mobile navigation source. [VERIFIED: CONTEXT.md]

**Primary recommendation:** Plan four workstreams in this order: responsive shell/nav, shared table/mobile summary contract, motion/focus/theme CSS audit, and targeted Playwright parity smoke tests. [VERIFIED: codebase grep]

## Project Constraints (from AGENTS.md)

No root `./AGENTS.md` exists under `/Users/jon/projects/scoria`; only sibling or nested dependency/example AGENTS files were found, so there are no project-level AGENTS directives to apply for this repo root. [VERIFIED: codebase grep]

No project-local `.codex/skills/`, `.agents/skills/`, or `rules/*.md` files were found within the repository scan depth used for research. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Mobile shell and topbar | Frontend Server (SSR) | Browser / Client | Shell markup comes from `app.html.heex`; drawer open/close focus behavior needs scoped JS. [VERIFIED: codebase grep] |
| Mobile nav drawer | Frontend Server (SSR) | Browser / Client | Nav groups are rendered from `ScoriaWeb.DashboardNav`; scrim, Escape, and focus restore need browser behavior. [VERIFIED: codebase grep] |
| Shared table responsiveness | Frontend Server (SSR) | Browser / Client | `ScoriaWeb.UI.table/1` owns HTML semantics and slots; CSS owns overflow and responsive presentation. [VERIFIED: codebase grep] |
| Evidence/object mobile stacks | Frontend Server (SSR) | Browser / Client | LiveViews/components render object/evidence structure; CSS controls breakpoint layout. [VERIFIED: codebase grep] |
| Motion primitives | CDN / Static | Browser / Client | `assets/css/05-motion.css` is embedded static CSS; runtime respects media queries in the browser. [VERIFIED: codebase grep] |
| Focus and non-color status | Frontend Server (SSR) | Browser / Client | Components must emit text/ARIA/state structure; CSS must preserve visible focus and contrast. [VERIFIED: codebase grep] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html] |
| Theme parity | CDN / Static | Browser / Client | `assets/css/02-tokens.css` maps semantic tokens for themes; `ThemeToggle` updates `data-theme`. [VERIFIED: codebase grep] |
| Phase smoke proof | Dev Tooling | Browser / Client | `mix scoria.ui.e2e` runs Playwright against a running dev server and should host targeted browser truth checks. [VERIFIED: codebase grep] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | Locked `1.8.7`; latest `1.8.8` on Hex as of 2026-06-13 | Host Phoenix framework for embedded LiveView dashboard. | Existing project dependency; do not change for this phase. [VERIFIED: Hex registry] [VERIFIED: codebase grep] |
| Phoenix LiveView | Locked `1.1.30`; latest `1.2.1` on Hex as of 2026-06-13 | Server-rendered interactive UI, HEEx components, JS command helpers. | Existing project dependency; LiveView JS supports transitions with default 200ms timing. [VERIFIED: Hex registry] [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.JS.html] |
| Scoria scoped CSS layers | Local files `01-reset.css` through `06-utilities.css` | Token-first shell, component, motion, and utility styling. | This is the locked project CSS architecture; no Tailwind runtime or global reset. [VERIFIED: codebase grep] [VERIFIED: CONTEXT.md] |
| Playwright / `@playwright/test` | Locked `1.60.0`; latest `1.60.0` on npm as of 2026-06-13 | Browser truth checks for viewport, color scheme, reduced motion, computed styles, and focus. | Existing dev-only e2e lane; Playwright officially supports device/viewport and color-scheme/media emulation. [VERIFIED: npm registry] [CITED: https://playwright.dev/docs/emulation] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| ExUnit + Phoenix LiveViewTest | Project default | Component/source/server-render assertions. | Use for `ui.ex` API contracts, DS-06 guards, and markup structure that does not require a browser. [VERIFIED: codebase grep] |
| `mix scoria.ui.e2e` | Local Mix task | Runs Playwright specs under `priv/dev/e2e`. | Use for browser-only Phase 16 assertions: horizontal overflow, focus visibility, reduced motion, theme toggle. [VERIFIED: codebase grep] |
| `mix scoria.ui.shots` | Local Mix task | Screenshot matrix and critique harness. | Keep as Phase 17/final proof tooling; do not convert Phase 16 into screenshot baseline CI. [VERIFIED: CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shared `table/1` mobile summary slots | Per-screen mobile card forks | Forks make each table a separate responsive product and violate D-14 except for true object inspectors. [VERIFIED: CONTEXT.md] |
| CSS media queries + scoped component classes | Real Tailwind responsive utilities | Tailwind switch is out of scope and contradicts the locked scoped CSS architecture. [VERIFIED: REQUIREMENTS.md] |
| Targeted Playwright checks | Full visual regression/axe matrix | Full screenshot/axe matrices are deferred to later/Phase 17 and would expand CI scope beyond Phase 16. [VERIFIED: CONTEXT.md] |
| Existing `DashboardNav` SSOT | Separate mobile nav data | A second nav source would split IA truth and violate D-03. [VERIFIED: CONTEXT.md] |

**Installation:**

No new external packages should be installed for Phase 16. Use existing Mix, Phoenix LiveView, and `priv/dev` Playwright dependencies. [VERIFIED: codebase grep]

**Version verification:**

```bash
mix hex.info phoenix
mix hex.info phoenix_live_view
npm view playwright version time.modified time.created repository.url scripts.postinstall
npm view @playwright/test version time.modified time.created repository.url scripts.postinstall
```

`npm view` returned no `scripts.postinstall` for `playwright` or `@playwright/test` in this session. [VERIFIED: npm registry]

## Package Legitimacy Audit

Phase 16 should not add packages. Existing dev-only packages were audited because the validation lane depends on them. [VERIFIED: codebase grep]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `playwright` | npm | Created 2015-01-23; modified 2026-06-12 | npm downloads not returned by `npm view` | `github.com/microsoft/playwright` | slopcheck tool checked PyPI, not npm; result not applicable | Approved as existing dev dependency; no new install. [VERIFIED: npm registry] |
| `@playwright/test` | npm | Created 2020-09-24; modified 2026-06-12 | npm downloads not returned by `npm view` | `github.com/microsoft/playwright` | slopcheck incorrectly checked PyPI and reported SLOP because scoped npm package does not exist on PyPI | Approved as existing dev dependency; no new install. [VERIFIED: npm registry] |

**Packages removed due to slopcheck [SLOP] verdict:** none; the only SLOP verdict was cross-ecosystem noise for an existing npm scoped package checked against PyPI. [VERIFIED: terminal slopcheck output]  
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: terminal slopcheck output]

## Architecture Patterns

### System Architecture Diagram

```text
User request / keyboard / viewport / theme preference
  -> Phoenix LiveView route renders app shell from app.html.heex
  -> DashboardNav groups provide one nav SSOT
  -> Shared UI components emit semantic Scoria classes
  -> Embedded CSS layers apply tokens, responsive rules, motion primitives
  -> Scoped JS hooks handle theme toggle, command palette, mobile drawer focus
  -> Browser media/viewport state resolves layout, motion, focus, and theme
  -> Playwright e2e smoke checks verify browser-only behavior
```

All arrows above are internal to the embedded dashboard; no backend capability or data-model change is required for this phase. [VERIFIED: CONTEXT.md]

### Recommended Project Structure

```text
lib/scoria_web/
├── components/layouts/app.html.heex      # shell markup, mobile topbar, mobile nav drawer
├── dashboard_nav.ex                      # existing navigation SSOT
└── ui.ex                                 # shared table/mobile summary API, status/focus structure
assets/
├── css/01-reset.css                      # scoped focus-visible baseline
├── css/02-tokens.css                     # semantic token SSOT; touch only for WCAG defects
├── css/04-components.css                 # shell, table, overlay, evidence responsive rules
├── css/05-motion.css                     # only home for keyframes/primitives/reduced-motion guard
├── css/06-utilities.css                  # only general token-bound utility additions
└── js/scoria.js                          # scoped drawer/focus helpers if needed
priv/dev/e2e/
└── phase16_parity.spec.mjs               # targeted browser truth lane
test/scoria_web/
├── ui_component_test.exs                 # component API/markup contracts
├── ds06_drift_guard_test.exs             # raw palette ratchet
└── ui_drift_guard_test.exs               # status helper drift guard
```

This structure follows existing repo ownership and avoids creating a new CSS/JS architecture. [VERIFIED: codebase grep]

### Pattern 1: Mobile Shell Uses Same Nav SSOT

**What:** Render the mobile drawer from `nav_groups()` in `app.html.heex`, matching the desktop sidebar groups and active state. [VERIFIED: codebase grep]  
**When to use:** Use below `md` while hiding the fixed sidebar and keeping a compact sticky topbar. [VERIFIED: CONTEXT.md]

**Example:**

```heex
<!-- Source: existing app.html.heex + DashboardNav groups [VERIFIED: codebase grep] -->
<button type="button" data-mobile-nav-open aria-controls="scoria-mobile-nav">
  Menu
</button>

<aside id="scoria-mobile-nav" class="scoria-mobile-drawer" hidden>
  <nav aria-label="Dashboard sections">
    <div :for={group <- nav_groups()} class="scoria-navgroup">
      <p class="scoria-navgroup__label">{group.label}</p>
      <.link :for={item <- group.items} navigate={@scoria_base <> item.path} class="scoria-nav">
        <.icon name={item.icon} />
        <span>{item.label}</span>
      </.link>
    </div>
  </nav>
</aside>
```

### Pattern 2: Table Wrapper + Optional Mobile Summary

**What:** Add a table scroll viewport by default and an opt-in summary slot for scan surfaces. [VERIFIED: CONTEXT.md]  
**When to use:** Use summaries for object-selection scan tables; keep plain overflow for dense comparison/detail tables. [VERIFIED: CONTEXT.md]

**Example:**

```heex
<!-- Source: ScoriaWeb.UI.table/1 extension target [VERIFIED: codebase grep] -->
<div class="scoria-table__viewport" tabindex="0">
  <table class="scoria-table">
    ...
  </table>
</div>

<div class="scoria-table__mobile-summaries">
  <div :for={row <- @rows} class="scoria-table-summary">
    {render_slot(@mobile_summary, row)}
  </div>
</div>
```

### Pattern 3: Reduced-Motion-Safe Motion Primitives

**What:** Keep keyframes and named primitives in `05-motion.css`; keep interaction motion <=200ms and transform/opacity-only except allowlisted skeleton/attention states. [VERIFIED: CONTEXT.md]  
**When to use:** Use for modal, drawer, command palette, toast, skeleton, and finite attention cues. [VERIFIED: codebase grep]

**Example:**

```css
/* Source: MDN prefers-reduced-motion + existing 05-motion.css [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion] [VERIFIED: codebase grep] */
.scoria-mobile-drawer {
  transform: translateX(0);
  opacity: 1;
  transition:
    transform var(--scoria-dur-mid) var(--scoria-ease-out),
    opacity var(--scoria-dur-fast) var(--scoria-ease-out);
}

@media (prefers-reduced-motion: reduce) {
  .scoria-root *,
  .scoria-root *::before,
  .scoria-root *::after {
    animation-duration: 0.001ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.001ms !important;
  }
}
```

### Pattern 4: Browser-Truth Parity Checks

**What:** Use Playwright for computed layout/media/focus checks that LiveViewTest cannot observe. [VERIFIED: codebase grep]  
**When to use:** Use for 375px overflow, `prefers-reduced-motion`, theme toggle, and actual focus outlines. [VERIFIED: CONTEXT.md]

**Example:**

```javascript
// Source: Playwright emulation docs [CITED: https://playwright.dev/docs/emulation]
test.use({ viewport: { width: 375, height: 812 }, colorScheme: 'dark' });

test('dashboard has no page-level horizontal overflow at 375px', async ({ page }) => {
  await page.goto(BASE);
  await waitForReady(page);
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth);
  expect(overflow).toBe(false);
});
```

### Anti-Patterns to Avoid

- **Animating layout properties:** Width/left/right/grid animation causes layout churn and violates D-04/D-18. [VERIFIED: CONTEXT.md]
- **`transition: all`:** It is too broad to enforce transform/opacity-only interaction motion. [VERIFIED: CONTEXT.md]
- **Per-screen mobile table forks:** They duplicate layout logic and bypass the shared component contract. [VERIFIED: CONTEXT.md]
- **Color-only selected/status states:** WCAG and project requirements require visible text, structure, or ARIA state in addition to color. [VERIFIED: REQUIREMENTS.md] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html]
- **Adding raw palette classes:** DS-06 ratchet and `ui.ex` zero raw-palette assertion make this a build risk. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Navigation model | Separate mobile nav data | `ScoriaWeb.DashboardNav.groups/0` | One IA SSOT preserves active state, soon badges, routes, and command-palette consistency. [VERIFIED: codebase grep] |
| Overlay semantics | Bespoke per-screen drawers/modals | Existing drawer/modal shells and existing focus helper patterns | Shared shells already encode scrim/Escape/ARIA contracts; per-screen markup drifts. [VERIFIED: codebase grep] |
| Responsive tables | Custom card clone per table | `ScoriaWeb.UI.table/1` overflow viewport + optional summary slot | Centralized behavior makes sticky headers/actions and mobile summaries testable. [VERIFIED: CONTEXT.md] |
| Motion system | One-off keyframes in LiveViews/components | `assets/css/05-motion.css` named primitives | Centralization enforces reduced motion and brand motion rules. [VERIFIED: CONTEXT.md] |
| Contrast/token source | Parallel contrast token table | `assets/css/02-tokens.css` + brandbook-approved pairings | A second token source would drift from the semantic token SSOT. [VERIFIED: CONTEXT.md] |
| Browser simulation | Manual resize/screenshot-only verification | Existing `mix scoria.ui.e2e` Playwright lane | Playwright can assert viewport, media, color scheme, focus, and computed style. [VERIFIED: codebase grep] [CITED: https://playwright.dev/docs/emulation] |

**Key insight:** The phase is about bringing already-shared components up to the polish bar; custom one-offs would make Phase 17 proof harder and increase future design-system drift. [VERIFIED: CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Keeping Desktop Shell at Mobile Width

**What goes wrong:** The current `.scoria-shell` uses `grid-template-columns: 248px minmax(0, 1fr)`, so a 375px viewport can inherit a desktop sidebar constraint. [VERIFIED: codebase grep]  
**Why it happens:** The shell has no current `md` breakpoint override. [VERIFIED: codebase grep]  
**How to avoid:** Add mobile-first shell CSS where default is single-column and desktop sidebar appears at `md`. [VERIFIED: CONTEXT.md]  
**Warning signs:** `document.documentElement.scrollWidth > window.innerWidth` at 375px or desktop sidebar visible below 768px. [VERIFIED: CONTEXT.md]

### Pitfall 2: Unsupported Utility Syntax Looks Valid in HEEx but Has No CSS

**What goes wrong:** `sm:grid-cols-3`, `lg:grid-cols-[...]`, and `xl:grid-cols-[...]` appear in LiveViews/components but are not implemented in `06-utilities.css`. [VERIFIED: codebase grep]  
**Why it happens:** Scoria ships a scoped utility subset, not Tailwind. [VERIFIED: codebase grep]  
**How to avoid:** Replace arbitrary utilities with named component classes or add only general token-bound utilities. [VERIFIED: CONTEXT.md]  
**Warning signs:** `rg -n "sm:|grid-cols-\\[" lib/scoria_web` returns in-scope files. [VERIFIED: codebase grep]

### Pitfall 3: Responsive Tables Lose Semantics

**What goes wrong:** Turning every table into cards can remove table semantics and make comparison/detail surfaces harder to scan. [VERIFIED: CONTEXT.md]  
**Why it happens:** Card stacks are tempting on mobile but are not always the right model for structured data. [CITED: https://designsystem.digital.gov/components/table/]  
**How to avoid:** Keep desktop table semantics; use overflow for honest dense tables and opt-in summaries for scan surfaces. [VERIFIED: CONTEXT.md]  
**Warning signs:** `<table>` disappears globally or all tables get the same card treatment. [VERIFIED: CONTEXT.md]

### Pitfall 4: Focus Ring Exists Globally but Is Hidden in Context

**What goes wrong:** `.scoria-root :where(:focus-visible)` exists, but component backgrounds, overflow clipping, or low contrast can still make focus invisible. [VERIFIED: codebase grep]  
**Why it happens:** Focus indicators must be judged against adjacent colors and component-specific backgrounds, not just existence of CSS. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html]  
**How to avoid:** Browser-test representative links/buttons/inputs in dark and light themes and inspect computed outline styles and screenshots manually where needed. [VERIFIED: CONTEXT.md]  
**Warning signs:** Focus outline color matches panel/background or is clipped by an overflow container. [ASSUMED]

### Pitfall 5: Reduced Motion Guard Is Present but Exceptions Keep Moving

**What goes wrong:** Skeletons and attention pulses can keep looping or animate non-allowed properties under `prefers-reduced-motion`. [VERIFIED: codebase grep]  
**Why it happens:** Allowlisted state indicators still need explicit reduced-motion behavior. [VERIFIED: CONTEXT.md]  
**How to avoid:** Playwright-emulate `reducedMotion: 'reduce'` or `page.emulateMedia({ reducedMotion: 'reduce' })` and assert animations collapse. [CITED: https://playwright.dev/docs/api/class-page]  
**Warning signs:** `animationIterationCount` remains `infinite` or duration remains human-visible under reduced motion. [ASSUMED]

## Code Examples

### Playwright Reduced Motion Smoke

```javascript
// Source: Playwright page.emulateMedia API [CITED: https://playwright.dev/docs/api/class-page]
test('skeleton and attention motion collapse under reduced motion', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.goto(`${BASE}/workflows`);
  await waitForReady(page);

  const duration = await page.locator('.scoria-root').evaluate(() => {
    const probe = document.querySelector('.scoria-skeleton, .scoria-attention');
    return probe ? getComputedStyle(probe).animationDuration : '0s';
  });

  expect(['0s', '0.001ms']).toContain(duration);
});
```

### Focus Visible Browser Check

```javascript
// Source: WCAG focus guidance + existing Playwright lane [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html] [VERIFIED: codebase grep]
test('representative controls expose visible focus outline', async ({ page }) => {
  await page.goto(BASE);
  await waitForReady(page);
  const control = page.locator('[data-command-open]');
  await control.focus();
  const styles = await control.evaluate((el) => {
    const cs = getComputedStyle(el);
    return { outlineStyle: cs.outlineStyle, outlineWidth: cs.outlineWidth };
  });
  expect(styles.outlineStyle).not.toBe('none');
  expect(parseFloat(styles.outlineWidth)).toBeGreaterThanOrEqual(2);
});
```

### Token Contrast Guard Shape

```elixir
# Source: W3C contrast thresholds [CITED: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html]
test "semantic token text pairs meet AA floor" do
  pairs = [
    {"--scoria-text", "--scoria-surface-app", 4.5},
    {"--scoria-text-muted", "--scoria-surface-panel", 4.5},
    {"--scoria-focus-ring", "--scoria-surface-panel", 3.0}
  ]

  for {fg, bg, min_ratio} <- pairs do
    assert contrast_ratio(token(fg), token(bg)) >= min_ratio
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Desktop-first fixed sidebar | Mobile-first shell with off-canvas nav below `md` | Locked in Phase 16 CONTEXT on 2026-06-13 | Plan must start with shell CSS/JS before per-screen tweaks. [VERIFIED: CONTEXT.md] |
| Tables only as desktop tables | Overflow viewport plus opt-in mobile summaries | Locked in Phase 16 CONTEXT on 2026-06-13 | Shared `table/1` is the implementation point. [VERIFIED: CONTEXT.md] |
| Broad screenshot proof | Targeted Playwright smoke now, full screenshot/contact-sheet proof in Phase 17 | Locked in Phase 16 CONTEXT on 2026-06-13 | Keep CI assertions stable and selector-light. [VERIFIED: CONTEXT.md] |
| Raw palette utility migration | DS-06 ratchet + semantic token gateway | Completed Phase 12 | Phase 16 must not increase raw palette usage. [VERIFIED: codebase grep] |

**Deprecated/outdated:**

- Arbitrary Tailwind syntax in `class` attributes is unsupported in this project because `06-utilities.css` defines a fixed scoped utility subset. [VERIFIED: codebase grep]
- Full visual regression baselines are out of scope for Phase 16 and deferred to Phase 17/future standing lanes. [VERIFIED: CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Focus outlines may be clipped by overflow containers on some surfaces. | Common Pitfalls | Planner may under-test focused controls inside table viewports/drawers. |
| A2 | Reduced-motion computed-style checks should accept `0s` or `0.001ms` depending on browser serialization. | Code Examples | Tests could be flaky if the exact serialized value differs. |

## Open Questions

1. **Should the token contrast guard be implemented in Phase 16?**  
   - What we know: D-31 permits it only if it reuses `02-tokens.css` and brandbook pairings. [VERIFIED: CONTEXT.md]  
   - What's unclear: The exact parser/helper does not exist yet. [VERIFIED: codebase grep]  
   - Recommendation: Plan it as a small optional task after shell/table/browser checks; skip if it creates a parallel token source. [VERIFIED: CONTEXT.md]

2. **Should mobile drawer use the existing command-palette focus helpers or a new small hook?**  
   - What we know: `assets/js/scoria.js` already has `focusableElements`, restore-focus, and close-delay patterns for command/shortcuts overlays. [VERIFIED: codebase grep]  
   - What's unclear: The cleanest internal hook shape is executor discretion. [VERIFIED: CONTEXT.md]  
   - Recommendation: Reuse helper functions and add a scoped `MobileNav` hook only if markup cannot be expressed with existing helpers. [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Mix tests and app compile | yes | 1.19.5 / OTP 28 | Blocking if missing. [VERIFIED: terminal] |
| Mix | Test/e2e tasks | yes | 1.19.5 | Blocking if missing. [VERIFIED: terminal] |
| Node.js | Playwright e2e | yes | 22.14.0 | Blocking for browser checks. [VERIFIED: terminal] |
| npm / npx | `priv/dev` dependency install and Playwright runner | yes | 11.1.0 | Blocking for browser checks. [VERIFIED: terminal] |
| PostgreSQL client | Dev DB setup support | yes | psql 14.17 | Server availability still must be checked when running e2e. [VERIFIED: terminal] |
| Docker | Optional local service support | yes | 29.5.2 | Native services may be used if Docker unavailable. [VERIFIED: terminal] |
| Playwright deps | `mix scoria.ui.e2e` | yes | `priv/dev/package-lock.json` locks 1.60.0 | Run `npm --prefix priv/dev ci` if node_modules is stale. [VERIFIED: codebase grep] |

**Missing dependencies with no fallback:** none found during research. [VERIFIED: terminal]  
**Missing dependencies with fallback:** PostgreSQL server process was not probed; e2e task docs already require `mix dev.setup` and a running `mix phx.server`. [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit / Phoenix LiveViewTest plus Playwright `@playwright/test` 1.60.0. [VERIFIED: codebase grep] |
| Config file | `priv/dev/e2e/playwright.config.mjs`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/scoria_web/ui_component_test.exs test/scoria_web/ds06_drift_guard_test.exs test/scoria_web/ui_drift_guard_test.exs` |
| Full suite command | `mix test` plus `mix scoria.ui.e2e` with dev server running. [VERIFIED: codebase grep] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| MOTION-01 | Motion primitives are <=200ms, transform/opacity-only for interactions, and reduced-motion-safe. | Playwright + CSS source guard | `mix scoria.ui.e2e` | Existing lane yes; Phase 16 spec file no. [VERIFIED: codebase grep] |
| MOTION-02 | Focus-visible is visible and status has non-color indicators. | Component tests + Playwright computed style | `mix test test/scoria_web/ui_component_test.exs && mix scoria.ui.e2e` | Partial existing; new Phase 16 assertions needed. [VERIFIED: codebase grep] |
| MOTION-03 | Shell and key tables do not page-overflow at 375px; md/lg/xl layouts are intentional. | Playwright viewport checks + source grep | `mix scoria.ui.e2e` | Existing lane yes; new Phase 16 spec file needed. [VERIFIED: codebase grep] |
| MOTION-04 | Light/dark theme surfaces meet contrast floor and high-risk screens toggle cleanly. | Playwright colorScheme/theme checks + optional ExUnit token guard | `mix scoria.ui.e2e` and optional `mix test test/scoria_web/*contrast*_test.exs` | Browser lane exists; contrast guard file does not. [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** Run targeted ExUnit file(s) for touched component plus `mix test test/scoria_web/ds06_drift_guard_test.exs`. [VERIFIED: codebase grep]
- **Per wave merge:** Run `mix test test/scoria_web` plus targeted `mix scoria.ui.e2e` when shell/table/JS changes land. [VERIFIED: codebase grep]
- **Phase gate:** Full relevant ExUnit suite and `mix scoria.ui.e2e` green against seeded dev server before `$gsd-verify-work`. [VERIFIED: codebase grep]

### Wave 0 Gaps

- [ ] `priv/dev/e2e/phase16_parity.spec.mjs` — covers MOTION-01..04 targeted browser truth. [VERIFIED: codebase grep]
- [ ] Optional token contrast guard file if D-31 is accepted by planner. [VERIFIED: CONTEXT.md]
- [ ] `ScoriaWeb.UI.table/1` tests for new overflow/mobile summary API. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase does not add auth or identity behavior. [VERIFIED: CONTEXT.md] |
| V3 Session Management | no | Phase does not alter sessions. [VERIFIED: CONTEXT.md] |
| V4 Access Control | no | Phase does not add routes or backend capabilities. [VERIFIED: CONTEXT.md] |
| V5 Input Validation | yes | Preserve HEEx escaping and existing component attrs; do not introduce raw HTML or client-side route construction outside existing mount-prefix-safe patterns. [VERIFIED: codebase grep] |
| V6 Cryptography | no | Phase does not add cryptography. [VERIFIED: CONTEXT.md] |

### Known Threat Patterns for Phoenix LiveView UI/CSS Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| XSS via mobile summary slots or raw evidence | Tampering / Information Disclosure | Keep HEEx interpolation escaped; do not use `Phoenix.HTML.raw` for row summaries. [VERIFIED: codebase grep] |
| Navigation spoofing from separate mobile nav data | Spoofing | Render mobile nav from `DashboardNav` SSOT and mount-prefix-safe paths. [VERIFIED: codebase grep] |
| Hidden focus/keyboard trap failure in drawer | Denial of Service | Add Escape, scrim click, focus containment, and focus restore checks. [VERIFIED: CONTEXT.md] |
| CI execution of broad screenshot/axe infrastructure | Denial of Service | Keep Phase 16 checks targeted under existing e2e lane. [VERIFIED: CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- Local codebase scan: `mix.exs`, `mix.lock`, `lib/scoria_web/ui.ex`, `lib/scoria_web/components/layouts/app.html.heex`, `lib/scoria_web/dashboard_nav.ex`, `assets/css/*.css`, `assets/js/scoria.js`, `priv/dev/e2e/*`, `test/scoria_web/*`. [VERIFIED: codebase grep]
- `.planning/phases/16-motion-responsive-theme-parity/16-CONTEXT.md` - locked decisions, scope, deferred items. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - MOTION-01..04 requirements and scope exclusions. [VERIFIED: file read]
- `.planning/STATE.md` - milestone state and Phase 16 position. [VERIFIED: file read]
- Hex registry via `mix hex.info phoenix` and `mix hex.info phoenix_live_view`. [VERIFIED: Hex registry]
- npm registry via `npm view playwright` and `npm view @playwright/test`. [VERIFIED: npm registry]
- Phoenix LiveView JS docs - transition options and default 200ms. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.JS.html]
- Playwright docs - viewport/device/color-scheme/media emulation. [CITED: https://playwright.dev/docs/emulation]
- Playwright Page API - reduced motion emulation. [CITED: https://playwright.dev/docs/api/class-page]
- W3C WCAG Understanding docs for animation, contrast, non-text contrast, and focus appearance. [CITED: https://www.w3.org/WAI/WCAG21/Understanding/animation-from-interactions] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance.html]
- MDN `prefers-reduced-motion` docs. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion]
- USWDS and CFPB responsive table guidance. [CITED: https://designsystem.digital.gov/components/table/] [CITED: https://cfpb.github.io/design-system/components/tables]

### Secondary (MEDIUM confidence)

- `priv/shots/gap_register.md` baseline findings: mobile sidebar/table risk and focus/contrast gaps. [VERIFIED: file read]

### Tertiary (LOW confidence)

- None used as authoritative support.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - versions verified against local lockfiles plus Hex/npm registries. [VERIFIED: Hex registry] [VERIFIED: npm registry]
- Architecture: HIGH - phase boundaries and implementation seams are explicit in CONTEXT and local code. [VERIFIED: CONTEXT.md] [VERIFIED: codebase grep]
- Pitfalls: HIGH for shell/table/utility/focus risks confirmed in code; MEDIUM for exact browser serialization details until tests are written. [VERIFIED: codebase grep] [ASSUMED]

**Research date:** 2026-06-13  
**Valid until:** 2026-07-13 for local architecture; 2026-06-20 for package/docs currency because Phoenix LiveView and Playwright are actively releasing. [VERIFIED: Hex registry] [VERIFIED: npm registry]
