// priv/dev/e2e/a11y_axe.spec.mjs
//
// Phase 40 A11Y-02 — axe-core WCAG 2.2 AA computed-truth proof. This is
// axe's slice of the D-07 coverage map: computed contrast/name/role/ARIA
// that neither the browserless source-scan (`token_contrast_guard_test.exs`)
// nor the keyboard-e2e specs (drawer_focus.spec.mjs, modal_focus.spec.mjs)
// can prove, because those require a real rendering engine.
//
// Two-tier proof (D-06):
//
//   1. REPORT-ONLY full-lab baseline (this file's first describe block) —
//      every dev lab section (dev/lab/lab_live.ex `@sections`), BOTH themes
//      (D-09 — color-contrast differs per theme, scanning one leaves half
//      the surface unproven). The lab is a specimen gallery that
//      intentionally renders muted/ghost/disabled/danger-tone variants
//      simultaneously — `color-contrast` is near-certain to fire on those
//      BY DESIGN. Asserting zero here would red-wall the required e2e gate
//      (D-04) on noise, not a real defect. Instead: collect violation count
//      + per-rule breakdown and attach it to the playwright-report via
//      `testInfo.attach()` (+ a `console.warn` summary for local runs),
//      and let a human curate which findings are genuine before Task 2's
//      curated assert-zero scan is written.
//
//   2. CURATED assert-zero on a human-confirmed allow-list of seeded REAL
//      pages (Task 2, added after the checkpoint) — throwing `expect`.
//
// Both tiers import the shared `buildAxeScan`/`runAxeScan` helper
// (./lib/axe.mjs, Plan 01) so the WCAG tag list and the `target-size` rule
// override can never drift between the two call sites (D-06/D-17).
//
// Lane: auto-discovered by `mix scoria.ui.e2e` via testMatch '**/*.spec.mjs'
// (playwright.config.mjs) the moment this file lands — every assertion in
// the full-lab block below is deliberately non-throwing so this does not
// red-wall the required e2e CI gate (D-04's report-only bucket).
//
// No fixed sleeps: rely on waitForReady + expect auto-wait (retries: 2 in CI).

import { test, expect } from '@playwright/test';
import { waitForReady } from './lib/ready.mjs';
import { runAxeScan } from './lib/axe.mjs';

const DASHBOARD_BASE = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:4799/scoria';
const LAB_BASE = `${DASHBOARD_BASE}/_lab`;

// D-09: both themes, every scan in this file.
const THEMES = ['dark', 'light'];

// dev/lab/lab_live.ex `@sections` (D-07 IA) — the full dev lab is all seven
// sections, not just the bare `/scoria/_lab` (Foundations) index. This is
// the same slug list the nav rail / route allowlist derive from; scanning
// every slug is what makes this a genuine "full lab" baseline rather than
// only its first section.
const LAB_SECTIONS = [
  'foundations',
  'primitives',
  'groups',
  'states',
  'viewports',
  'overlays',
  'fixtures',
];

/**
 * Sets the persisted theme mode via the real `scoria-theme` localStorage key
 * (the same key `assets/js/scoria.js`'s ThemeToggle hook writes) and reloads
 * so `root.html.heex`'s pre-paint script resolves it into `data-theme` on
 * `<html class="scoria-root">` before axe runs — the exact mechanism
 * `lab.spec.mjs`'s D-14 theme-coverage block already proves.
 *
 * @param {import('@playwright/test').Page} page
 * @param {'dark'|'light'} theme
 */
async function setTheme(page, theme) {
  await page.evaluate((t) => localStorage.setItem('scoria-theme', t), theme);
  await page.reload();
  await waitForReady(page);
  await expect(page.locator('html.scoria-root')).toHaveAttribute('data-theme', theme);
}

/**
 * Builds a report-only breakdown from a raw axe-core AxeResults object.
 *
 * Deliberately includes every result bucket (not just `violations`) so the
 * `target-size` rule's presence can be confirmed regardless of whether it
 * fired a violation on this particular page/theme (Pitfall 1 —
 * `target-size` is `enabled: false` by default in axe-core; the shared
 * `axe.mjs` helper's `rules` override re-enables it, and this breakdown is
 * how that override's effect becomes observable in the report).
 *
 * @param {import('axe-core').AxeResults} results
 */
function summarizeResults(results) {
  const shape = (rule) => ({ id: rule.id, impact: rule.impact ?? null, nodes: rule.nodes.length });

  const allRuleIds = new Set([
    ...results.violations.map((r) => r.id),
    ...results.passes.map((r) => r.id),
    ...results.incomplete.map((r) => r.id),
    ...results.inapplicable.map((r) => r.id),
  ]);

  return {
    violationCount: results.violations.length,
    violations: results.violations.map(shape),
    incomplete: results.incomplete.map(shape),
    targetSizeRuleRan: allRuleIds.has('target-size'),
  };
}

// ────────────────────────────────────────────────────────────────────────────
// Tier 1 — REPORT-ONLY full-lab baseline, every section, both themes (D-06/D-09)
// ────────────────────────────────────────────────────────────────────────────

test.describe('axe-core WCAG 2.2 AA — full dev lab report-only baseline (D-06)', () => {
  for (const theme of THEMES) {
    for (const section of LAB_SECTIONS) {
      test(`report-only baseline: /_lab/${section} in ${theme} theme`, async ({ page }, testInfo) => {
        await page.goto(`${LAB_BASE}/${section}`);
        await waitForReady(page);
        await setTheme(page, theme);

        const results = await runAxeScan(page);
        const summary = summarizeResults(results);

        await testInfo.attach(`axe-baseline-${section}-${theme}.json`, {
          body: JSON.stringify(summary, null, 2),
          contentType: 'application/json',
        });

        const ruleList = summary.violations.map((r) => `${r.id}(${r.nodes})`).join(', ') || 'none';
        console.warn(
          `[axe baseline] /_lab/${section} (${theme}): ${summary.violationCount} violation rule(s) — ${ruleList}`
        );

        // REPORT-ONLY (D-06): no `expect(violations).toEqual([])` here — the
        // lab's muted/ghost/disabled/danger-tone specimens fire
        // `color-contrast` by design, and a bare assert-zero on the full lab
        // would red-wall the required e2e gate (D-04) on expected noise.
        //
        // The one assertion this test DOES make is deliberately narrow: it
        // confirms the `target-size` rule actually executed (proving the
        // shared `axe.mjs` override works), not that the lab has zero
        // target-size violations — `target-size` results stay unasserted in
        // `summary.violations` and remain report-only through Phase 40.
        expect(
          summary.targetSizeRuleRan,
          'target-size (2.5.8) must run under the rules override even though its results stay report-only'
        ).toBe(true);
      });
    }
  }
});
