// priv/dev/e2e/responsive_scan.spec.mjs
//
// Phase 40 D-14..D-18 — RESP-01 responsive proof. Generalizes the proven
// phase16_parity.spec.mjs 375px no-h-overflow assertion (Home + /workflows)
// to the full VIEWPORT_WIDTHS matrix (320/375/768/1024/1440/1920, reused from
// lab.spec.mjs) across a ~4-page anchor set (D-15) chosen to exercise every
// locked responsive primitive at its worst case:
//
//   - Home (`/`)       — shell baseline, the exact phase16_parity seed
//   - Workflows (`/workflows`) — the other phase16_parity seed; dense table
//     WITH `:mobile_summary` (ui.ex:1264)
//   - Approvals (`/approvals`) — dense table + `:mobile_summary` + the sticky
//     `position:sticky;bottom:0` approval-actions footer + the toast region
//   - Incidents (`/incidents`) — `.scoria-page-split--xl-reverse` grid split
//     (04-components.css:1813, "Covers incidents_live/index content grid")
//
// A workflow-detail page (`.scoria-page-split` + evidence-split + the
// approval drawer) was considered per 40-CONTEXT.md D-15's example list but
// deliberately left out of this ~4-page anchor set (Claude's Discretion,
// D-15): its grid-split primitive is the same family already exercised by
// Incidents (`.scoria-page-split` vs `.scoria-page-split--xl-reverse`), and
// its drawer's focus-occlusion risk is drawer_focus.spec.mjs's SC 2.4.11
// assertion (D-11), not a D-16 concern.
//
// Every assertion below was run live against a real `make dev`-equivalent
// server while authoring this spec and found clean on Home/Workflows/
// Approvals/Incidents, WITH ONE EXCEPTION (D-16(6), the 24px target floor —
// `.scoria-button--sm` rendered ~22px tall; fixed in
// assets/css/04-components.css by flooring `min-height` at the existing
// `--scoria-space-5` (24px) token, no vocabulary change). Per the D-04
// two-bucket rule, every assertion in this file is therefore a THROWING
// `expect()` (fix-and-assert atomic) — this spec introduces no non-throwing
// collectors because it surfaced no unfixed, out-of-scope defect.
//
// Lane: auto-discovered by `mix scoria.ui.e2e` via testMatch '**/*.spec.mjs'.
// No fixed sleeps: rely on waitForReady + expect auto-wait (retries: 2 in CI).

import { test, expect } from '@playwright/test';
import { waitForReady } from './lib/ready.mjs';
import { boxesIntersect } from './lib/boxes_intersect.mjs';

const BASE = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:4799/scoria';

// Reused from lab.spec.mjs (dev/lab/sections/viewports.ex @widths) — the same
// six widths RESP-01 proves against everywhere in this harness.
const VIEWPORT_WIDTHS = [320, 375, 768, 1024, 1440, 1920];

// D-15: cheap doc-overflow check runs at all 6 widths; expensive per-element
// checks (D-16(2)/(6)) run only at the narrow end + the breakpoint edge,
// where failures concentrate.
const NARROW_WIDTHS = [320, 375, 768];

// D-16(6): "at ≤375" — the mobile target-size floor only applies below the md
// breakpoint (above it, pointer precision is assumed and the design system's
// own 44px mobile-chrome floor already covers touch targets more generously).
const TARGET_FLOOR_WIDTHS = [320, 375];

const PAGES = [
  { name: 'Home (shell)', path: '/' },
  {
    name: 'Workflows (table + mobile_summary)',
    path: '/workflows',
    hasTable: true,
    hasMobileSummary: true,
  },
  {
    name: 'Approvals (dense table + sticky footer + mobile_summary + toast region)',
    path: '/approvals',
    hasTable: true,
    hasMobileSummary: true,
    hasToastRegion: true,
  },
  { name: 'Incidents (page-split grid + list)', path: '/incidents' },
];

// D-16(2) curated selector: interactive controls, primary headings, action
// bars — deliberately NOT `*`. Two exclusions matter:
//   1. `.closest('.scoria-table__viewport')` — a table's own horizontal
//      scroll container legitimately extends content past the fold; THAT is
//      the D-16(3) "contained, not leaked" proof, not a D-16(2) clipping bug.
//   2. Every clause here targets shell/page-header-level chrome only, so a
//      closed off-canvas drawer's `translateX(-100%)` content (which stays
//      `offsetParent !== null`, just visually shifted) is never a candidate
//      in the first place — it was never matched by any clause below.
const ESSENTIAL_SELECTOR = [
  '.scoria-pagehead__title',
  '.scoria-pagehead .scoria-button',
  '.scoria-pagehead .scoria-link',
  '.scoria-mobile-topbar [data-command-open]',
  '.scoria-mobile-topbar [data-mobile-nav-open]',
  '.scoria-mobile-topbar [data-theme-toggle]',
  '#scoria-command-open',
  '#scoria-theme-toggle',
  '.scoria-page-section__actions .scoria-button',
  'main.scoria-main .scoria-mobile-summary__action .scoria-button',
].join(', ');

async function docOverflow(page) {
  return page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth + 1);
}

async function essentialClipped(page, innerWidth) {
  return page.$$eval(
    ESSENTIAL_SELECTOR,
    (els, width) =>
      els
        .filter((el) => el.offsetParent !== null && !el.closest('.scoria-table__viewport'))
        .map((el) => el.getBoundingClientRect())
        .filter((r) => !(r.right <= width + 1 && r.left >= -1))
        .map((r) => ({ left: Math.round(r.left), right: Math.round(r.right) })),
    innerWidth
  );
}

// WCAG 2.5.8 (2.2) minimum target size: 24x24 CSS px. 1px tolerance matches
// the idiom already used elsewhere in this harness (boxesIntersect, the
// phase16_parity overflow check).
const TARGET_SELECTOR = 'a, button, [role="button"], input, select, textarea';

async function undersizedTargets(page) {
  return page.$$eval(TARGET_SELECTOR, (els) =>
    els
      .filter((el) => el.offsetParent !== null && !el.disabled)
      .map((el) => {
        const r = el.getBoundingClientRect();
        return { tag: el.tagName, cls: el.className, w: Math.round(r.width), h: Math.round(r.height) };
      })
      .filter((r) => r.w > 0 && r.h > 0 && Math.min(r.w, r.h) < 23)
  );
}

// ────────────────────────────────────────────────────────────────────────────
// D-16(1): no document-level horizontal overflow, all 6 widths, all anchor pages
// ────────────────────────────────────────────────────────────────────────────

test.describe('Responsive scan — D-16(1) no document horizontal overflow', () => {
  for (const p of PAGES) {
    for (const width of VIEWPORT_WIDTHS) {
      test(`${p.name}: no page-level horizontal overflow at ${width}px`, async ({ page }) => {
        await page.setViewportSize({ width, height: 900 });
        await page.goto(`${BASE}${p.path}`);
        await waitForReady(page);

        expect(
          await docOverflow(page),
          `${p.path} document overflows the viewport at ${width}px`
        ).toBe(false);
      });
    }
  }
});

// ────────────────────────────────────────────────────────────────────────────
// D-16(2): no essential element clipped off-viewport (320/375/768 only)
// ────────────────────────────────────────────────────────────────────────────

test.describe('Responsive scan — D-16(2) essential controls stay within the viewport', () => {
  for (const p of PAGES) {
    for (const width of NARROW_WIDTHS) {
      test(`${p.name}: no essential element clipped off-viewport at ${width}px`, async ({ page }) => {
        await page.setViewportSize({ width, height: 900 });
        await page.goto(`${BASE}${p.path}`);
        await waitForReady(page);

        const clipped = await essentialClipped(page, width);
        expect(
          clipped,
          `${p.path} @ ${width}px has essential elements clipped off-viewport: ${JSON.stringify(clipped)}`
        ).toEqual([]);
      });
    }
  }
});

// ────────────────────────────────────────────────────────────────────────────
// D-16(3)+(7): table overflow contained (not leaked to the page) and, when a
// table viewport genuinely scrolls, it stays keyboard-reachable (tabindex=0)
// ────────────────────────────────────────────────────────────────────────────

test.describe('Responsive scan — D-16(3)+(7) table overflow contained, scroll container keyboard-reachable', () => {
  for (const p of PAGES.filter((pg) => pg.hasTable)) {
    for (const width of NARROW_WIDTHS) {
      test(`${p.name}: .scoria-table__viewport overflow (if visible) is keyboard-reachable at ${width}px`, async ({
        page,
      }) => {
        await page.setViewportSize({ width, height: 900 });
        await page.goto(`${BASE}${p.path}`);
        await waitForReady(page);

        const viewport = page.locator('.scoria-table__viewport').first();
        if ((await viewport.count()) === 0) return;

        const info = await viewport.evaluate((el) => ({
          visible: getComputedStyle(el).display !== 'none' && el.offsetParent !== null,
          scrollWidth: el.scrollWidth,
          clientWidth: el.clientWidth,
          tabindex: el.getAttribute('tabindex'),
        }));

        // Below 768 on a `:mobile_summary` table the viewport is intentionally
        // display:none (D-16(4) owns that swap) — nothing to check here.
        if (!info.visible) return;

        // D-16(3): the table's OWN horizontal scroll (if any) may exceed its
        // client width — that is the honest-scroll-container contract
        // (D-18) — as long as the containing page (D-16(1), asserted
        // separately at every width) never overflows because of it.
        // D-16(7): any container that DOES scroll horizontally must stay
        // keyboard-focusable — the shipped tabindex="0" contract.
        expect(
          info.tabindex,
          `${p.path} .scoria-table__viewport must stay tabindex="0" at ${width}px so a trapped inner scroll (scrollWidth=${info.scrollWidth} clientWidth=${info.clientWidth}) is still keyboard-reachable`
        ).toBe('0');
      });
    }
  }
});

// ────────────────────────────────────────────────────────────────────────────
// D-16(4): `:mobile_summary` swap correctness
// ────────────────────────────────────────────────────────────────────────────

test.describe('Responsive scan — D-16(4) :mobile_summary swap correctness', () => {
  for (const p of PAGES.filter((pg) => pg.hasMobileSummary)) {
    test(`${p.name}: summaries render below 768px, the table viewport renders at/above 768px`, async ({
      page,
    }) => {
      async function swapState() {
        return page.evaluate(() => {
          const summaries = document.querySelector('.scoria-table__mobile-summaries');
          const viewport = document.querySelector('.scoria-table__viewport');
          return {
            summaryDisplay: summaries ? getComputedStyle(summaries).display : null,
            viewportDisplay: viewport ? getComputedStyle(viewport).display : null,
          };
        });
      }

      await page.setViewportSize({ width: 375, height: 900 });
      await page.goto(`${BASE}${p.path}`);
      await waitForReady(page);
      let state = await swapState();
      expect(state.summaryDisplay, `${p.path}: mobile summaries must render below 768px`).not.toBe(
        'none'
      );
      expect(state.viewportDisplay, `${p.path}: table viewport must be hidden below 768px`).toBe(
        'none'
      );

      await page.setViewportSize({ width: 1024, height: 900 });
      await page.goto(`${BASE}${p.path}`);
      await waitForReady(page);
      state = await swapState();
      expect(state.summaryDisplay, `${p.path}: mobile summaries must be hidden at >=768px`).toBe(
        'none'
      );
      expect(
        state.viewportDisplay,
        `${p.path}: table viewport must render at >=768px`
      ).not.toBe('none');
    });
  }
});

// ────────────────────────────────────────────────────────────────────────────
// D-16(5): no non-modal fixed/floating region covering nav (static occlusion)
//
// D-17: this block owns STATIC occlusion between a fixed/floating region and
// nav. It excludes: the sticky (not fixed) approval-actions footer, whose
// focus occlusion is drawer_focus.spec.mjs's dynamic SC 2.4.11 assertion
// (D-11); and the command palette / mobile-nav drawer / scrims, which are
// by-design full-viewport overlays, not the "floating region over nav" class
// of defect this check targets.
// ────────────────────────────────────────────────────────────────────────────

test.describe('Responsive scan — D-16(5) toast region never covers nav (D-17 static occlusion)', () => {
  for (const p of PAGES.filter((pg) => pg.hasToastRegion)) {
    for (const width of VIEWPORT_WIDTHS) {
      test(`${p.name}: .scoria-toast-region does not overlap nav at ${width}px`, async ({ page }) => {
        await page.setViewportSize({ width, height: 900 });
        await page.goto(`${BASE}${p.path}`);
        await waitForReady(page);

        const region = page.locator('.scoria-toast-region');
        if ((await region.count()) === 0) return;

        // Nav is the mobile topbar below 768px, the sidebar at/above it.
        const navSelector = width < 768 ? '.scoria-mobile-topbar' : '.scoria-sidebar';
        const nav = page.locator(navSelector);
        if ((await nav.count()) === 0) return;

        const regionRect = await region.evaluate((el) => el.getBoundingClientRect().toJSON());
        const navRect = await nav.evaluate((el) => el.getBoundingClientRect().toJSON());

        expect(
          boxesIntersect(regionRect, navRect),
          `${p.path}: .scoria-toast-region overlaps ${navSelector} at ${width}px`
        ).toBe(false);
      });
    }
  }
});

// ────────────────────────────────────────────────────────────────────────────
// D-16(6): minimum 24px target size floor (WCAG 2.5.8, ≤375px)
// ────────────────────────────────────────────────────────────────────────────

test.describe('Responsive scan — D-16(6) minimum 24px target size floor', () => {
  for (const p of PAGES) {
    for (const width of TARGET_FLOOR_WIDTHS) {
      test(`${p.name}: interactive targets are >=24px at ${width}px`, async ({ page }) => {
        await page.setViewportSize({ width, height: 900 });
        await page.goto(`${BASE}${p.path}`);
        await waitForReady(page);

        const undersized = await undersizedTargets(page);
        expect(
          undersized,
          `${p.path} @ ${width}px has targets under the 24px WCAG 2.5.8 floor: ${JSON.stringify(undersized)}`
        ).toEqual([]);
      });
    }
  }
});
