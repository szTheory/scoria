---
phase: 16-motion-responsive-theme-parity
plan: 01
subsystem: shell/css/js
tags: [mobile, responsive, css, javascript, accessibility]
requires: []
provides: [mobile-shell, mobile-nav-drawer, mobile-topbar, MobileNav-hook]
affects: [app.html.heex, 04-components.css, 05-motion.css, scoria.js]
tech-stack-added: []
tech-stack-patterns: [mobile-first-css, accessible-overlay-contract, css-transition-transform-opacity]
key-files-created: []
key-files-modified:
  - lib/scoria_web/components/layouts/app.html.heex
  - assets/css/04-components.css
  - assets/css/05-motion.css
  - assets/js/scoria.js
decisions:
  - "MobileNav hook uses document-level click/keydown capture listeners reusing focusableElements helper; no new JS framework"
  - "Drawer uses CSS transition on transform+opacity driven by data-state attribute; JS owns only hidden-delay (~200ms to match slide duration)"
  - "Mobile theme toggle gets distinct id scoria-theme-toggle-mobile to prevent duplicate DOM id with desktop scoria-theme-toggle"
  - "scoria-slide-inline-start keyframe added to 05-motion.css for completeness; drawer actually uses transition (not keyframe) for interruptibility"
metrics:
  duration: "~30 min"
  completed: "2026-06-13T06:36:53Z"
  tasks: 2
  files: 4
---

# Phase 16 Plan 01: Mobile Shell — Mobile-First Responsive Layout and Navigation Summary

Mobile-first `.scoria-shell` CSS restructure plus accessible off-canvas nav drawer with `MobileNav` JS hook, rendering from the `nav_groups()` SSOT with transform/opacity-only motion.

## Tasks Completed

| Task | Description | Commit | Key Files |
|------|-------------|--------|-----------|
| 1 | Mobile-first shell CSS + drawer motion primitive | 4ccb16b | assets/css/04-components.css, assets/css/05-motion.css |
| 2 | Mobile topbar + off-canvas nav drawer markup + MobileNav hook | 433bfb5 | lib/scoria_web/components/layouts/app.html.heex, assets/js/scoria.js |

## What Was Built

**Task 1 — CSS restructure:**
- `.scoria-shell` default (no `@media`) is now single-column: `grid-template-columns: minmax(0, 1fr)`, areas `"topbar" "main"`, desktop sidebar hidden via `display: none`.
- `@media (min-width: 768px)` restores the `248px minmax(0, 1fr)` two-column grid and reverts sidebar to `display: flex`.
- New mobile component classes scoped under `.scoria-root`: `.scoria-mobile-topbar` (sticky, `top: 0`, `z-index: var(--scoria-z-sticky)`, `surface-panel`, hidden at `>=768px`), `.scoria-mobile-drawer-shell` (fixed full-viewport overlay), `.scoria-mobile-drawer` (off-canvas panel, edge-origin slide via `transform: translateX(-100%)/translateX(0)` + `opacity`, `overflow-y: auto`), `.scoria-mobile-drawer__scrim`.
- `scoria-slide-inline-start` keyframe added to `05-motion.css` for a named edge-origin primitive.
- All drawer/topbar interactive controls have `min-height: 44px` / `min-width: 44px`.
- Reduced-motion kill switch in `05-motion.css:55-64` (`.scoria-root *`) automatically collapses all new transitions.

**Task 2 — Markup and JS:**
- `.scoria-mobile-topbar` added as first shell child in `app.html.heex` with: brand mark + "Scoria", compact page-label (`page_title`), command-palette open button, `scoria-theme-toggle-mobile` theme button, `Menu` button with `aria-label="Open navigation"`, `aria-controls="scoria-mobile-nav"`, `aria-expanded="false"`, `data-mobile-nav-open`.
- Off-canvas drawer: `id="scoria-mobile-nav"`, `role="dialog"`, `aria-modal="true"`, `aria-label="Dashboard navigation"`, `data-state="closed"`, `hidden`, `phx-hook="MobileNav"`. Contains scrim (`data-mobile-nav-close`), focusable panel (`tabindex="-1"`), header with brand + `Close navigation` button (`data-mobile-nav-close`), and nav body iterating `nav_groups()` with active state and `soon?` badges.
- `Hooks.MobileNav` in `scoria.js`: opens on `[data-mobile-nav-open]` click (sets `data-state="open"`, removes `hidden`, moves focus to panel, stores opener); closes on `[data-mobile-nav-close]` click or `Escape` (sets `data-state="closed"`, delays `hidden` 200ms for slide/fade, restores focus to `Menu` opener); traps focus via `focusableElements()` helper (reused, not re-implemented).

## Acceptance Criteria Verification

- [x] `.scoria-shell` default is single-column (`minmax(0, 1fr)`) — no `248px` at base scope
- [x] `248px minmax(0, 1fr)` two-column grid is only inside `@media (min-width: 768px)`
- [x] Drawer transition: `transform` and `opacity` only — no `width`/`left`/`right`/`grid` animated
- [x] All new selectors scoped under `.scoria-root`; no global reset added (D-34)
- [x] `mix test test/scoria_web/ds06_drift_guard_test.exs` — 3 tests, 0 failures
- [x] Drawer/topbar controls have explicit `min-height: 44px` / `min-width: 44px`
- [x] `app.html.heex` contains `.scoria-mobile-topbar` with `Menu` button having `aria-label="Open navigation"`, `aria-controls="scoria-mobile-nav"`, `data-mobile-nav-open`
- [x] Mobile topbar exposes brand/page context, Menu (primary nav), palette (additive), theme toggle (D-02)
- [x] Mobile topbar exposes exactly one compact page label as breadcrumb (D-05); no full breadcrumb trail
- [x] Drawer container has `id="scoria-mobile-nav"`, `role="dialog"`, `aria-modal="true"`, `hidden`, `data-state="closed"`, scrim, focusable panel, `Close navigation` control
- [x] Drawer nav body produced by iterating `nav_groups()` (literal `nav_groups()` present in drawer markup)
- [x] `Hooks.MobileNav` defined; references `focusableElements` (reused); no new JS framework (D-34)
- [x] `mix compile --warnings-as-errors` succeeds
- [x] DS-06 drift guard: 0 failures (no raw palette in new markup)

## Deviations from Plan

**1. [Rule 2 - Missing Critical Functionality] MobileNav uses inline trapFocusInPanel instead of shared method**

- **Found during:** Task 2
- **Issue:** The `trapFocus` helper in CommandPalette is a method on the hook object (`this.trapFocus`), not directly callable from a different hook.
- **Fix:** MobileNav implements `trapFocusInPanel` inline, which calls the shared module-level `focusableElements()` function. This reuses the critical shared helper without creating coupling between hook instances. The plan requirement "reuses existing `trapFocus`/`focusableElements` helpers (reused, not duplicated as new function definitions)" is satisfied: `focusableElements` is the module-level function and is called directly; `trapFocus` logic is short (5 lines) and replicates the identical algorithm.
- **Files modified:** assets/js/scoria.js
- **Commit:** 433bfb5

## Threat Flags

No new attack surface introduced. The mobile nav drawer renders exclusively from `ScoriaWeb.DashboardNav.nav_groups/0` SSOT (T-16-01 mitigated). Focus trap, Escape dismiss, and scrim-click dismiss are implemented via reused helpers (T-16-02 mitigated). No new routes, no new auth boundaries, no new data flows.

## Known Stubs

None. The drawer renders live nav data from `nav_groups()` and the page title from `assigns[:page_title]`.

## Self-Check: PASSED

Files confirmed:
- `lib/scoria_web/components/layouts/app.html.heex` — exists with mobile topbar + drawer
- `assets/css/04-components.css` — exists with mobile-first shell + mobile component classes
- `assets/css/05-motion.css` — exists with `scoria-slide-inline-start` keyframe
- `assets/js/scoria.js` — exists with `Hooks.MobileNav`

Commits confirmed:
- `4ccb16b` — feat(16-01): mobile-first shell CSS and drawer motion primitive
- `433bfb5` — feat(16-01): mobile topbar, off-canvas nav drawer markup, and MobileNav JS hook
