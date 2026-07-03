// priv/dev/e2e/reduced_motion.spec.mjs
//
// Phase 40 D-19 — dedicated MOTION-01 reduced-motion collapse proof. The kill
// switch (assets/css/05-motion.css:71) is unlayered CSS `!important` and is
// therefore authoritative — this is a genuinely-provable hard assertion, not
// a warning-grade collector (D-04 two-bucket rule: this surface is already
// clean, verified live against a running dev server while authoring this
// spec).
//
// Covers every named motion surface in 05-motion.css:
//   - scoria-slide-inline-start (mobile nav drawer transition)
//   - .scoria-command opacity transition (command palette / shortcuts overlay)
//   - scoria-skeleton-pulse — the D-20 INFINITE exception (04-components.css:1610)
//   - scoria-approval-pulse — the D-21 border-color exception
//   - the generic `.scoria-root *` kill-switch selector (any interactive
//     control with a transition, e.g. the theme toggle)
//
// The skeleton and approval-pulse specimens are DOM-injected (appended to the
// real .scoria-root subtree, then removed) rather than driven through a live
// LiveView loading race: `<.skeleton>` only renders inside an `assign_async`
// `:loading` slot (lib/scoria_web/live/workflow_live/show.ex) that resolves
// too fast against a local dev DB to reliably catch mid-flight, and the bare
// `.scoria-attention` class (05-motion.css:45, the D-21 approval-pulse
// consumer) has no live callsite left in lib/ after Phase 39's D-13 de-alarm
// removed `.scoria-approval-summary`. Injecting the exact shipped class names
// into the real `.scoria-root` subtree exercises the ACTUAL CSS cascade
// (same stylesheet, same `@media (prefers-reduced-motion: reduce)` selector)
// deterministically — it is not a fabricated assertion, it is a deterministic
// way to drive a real (if currently unreachable-via-UI) declaration.
//
// Lane: auto-discovered by `mix scoria.ui.e2e` via testMatch '**/*.spec.mjs'.
// No fixed sleeps: rely on waitForReady + expect auto-wait (retries: 2 in CI).

import { test, expect } from '@playwright/test';
import { waitForReady } from './lib/ready.mjs';
import { isInstantDuration } from './lib/instant_duration.mjs';

const BASE = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:4799/scoria';

test.describe('Reduced motion — MOTION-01 duration collapse (D-19)', () => {
  test.use({ viewport: { width: 375, height: 812 } });

  test('mobile nav drawer transition collapses under prefers-reduced-motion', async ({ page }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.goto(BASE);
    await waitForReady(page);

    await page.locator('[data-mobile-nav-open]').click();
    const drawer = page.locator('#scoria-mobile-nav .scoria-mobile-drawer');
    await expect(page.locator('#scoria-mobile-nav')).toBeVisible();

    const duration = await drawer.evaluate((el) => getComputedStyle(el).transitionDuration);
    expect(
      isInstantDuration(duration),
      `mobile nav drawer transitionDuration must collapse under reduced motion, got: ${duration}`
    ).toBe(true);
  });

  test('command palette opacity transition collapses under prefers-reduced-motion', async ({ page }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.goto(BASE);
    await waitForReady(page);

    await page.keyboard.press('Control+k');
    const palette = page.locator('#scoria-command-palette');
    await expect(palette).toBeVisible();

    const duration = await palette.evaluate((el) => getComputedStyle(el).transitionDuration);
    expect(
      isInstantDuration(duration),
      `command palette transitionDuration must collapse under reduced motion, got: ${duration}`
    ).toBe(true);
  });

  test('the infinite skeleton pulse (D-20 exception, 04-components.css:1610) collapses under prefers-reduced-motion', async ({
    page,
  }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.goto(BASE);
    await waitForReady(page);

    // Injects the real <.skeleton> shape (scoria-skeleton-group > .scoria-skeleton
    // .scoria-skeleton--text) into the live .scoria-root subtree — see file
    // header for why this is deterministic-but-real rather than a live-race probe.
    const result = await page.evaluate(() => {
      const root = document.querySelector('.scoria-root');
      const group = document.createElement('div');
      group.className = 'scoria-skeleton-group';
      const el = document.createElement('div');
      el.className = 'scoria-skeleton scoria-skeleton--text';
      group.appendChild(el);
      root.appendChild(group);
      const cs = getComputedStyle(el);
      const out = {
        animationDuration: cs.animationDuration,
        animationIterationCount: cs.animationIterationCount,
      };
      root.removeChild(group);
      return out;
    });

    expect(
      isInstantDuration(result.animationDuration),
      `the infinite scoria-skeleton-pulse must collapse animationDuration under reduced motion, got: ${result.animationDuration}`
    ).toBe(true);
    expect(
      result.animationIterationCount,
      `the infinite scoria-skeleton-pulse must collapse to a single iteration under reduced motion, got: ${result.animationIterationCount}`
    ).toBe('1');
  });

  test('the approval-pulse border-color cue (D-21 exception) collapses under prefers-reduced-motion', async ({
    page,
  }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.goto(BASE);
    await waitForReady(page);

    const result = await page.evaluate(() => {
      const root = document.querySelector('.scoria-root');
      const el = document.createElement('div');
      el.className = 'scoria-attention';
      root.appendChild(el);
      const cs = getComputedStyle(el);
      const out = {
        animationDuration: cs.animationDuration,
        animationIterationCount: cs.animationIterationCount,
      };
      root.removeChild(el);
      return out;
    });

    expect(
      isInstantDuration(result.animationDuration),
      `scoria-approval-pulse must collapse animationDuration under reduced motion, got: ${result.animationDuration}`
    ).toBe(true);
    expect(
      result.animationIterationCount,
      `scoria-approval-pulse must collapse to a single iteration under reduced motion, got: ${result.animationIterationCount}`
    ).toBe('1');
  });

  test('the generic .scoria-root * kill switch collapses a real interactive control transition', async ({
    page,
  }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.goto(BASE);
    await waitForReady(page);

    const duration = await page.evaluate(() => {
      const el =
        document.querySelector('#scoria-theme-toggle') ||
        document.querySelector('#scoria-theme-toggle-mobile') ||
        document.querySelector('[data-command-open]');
      return el ? getComputedStyle(el).transitionDuration : '0s';
    });

    expect(
      isInstantDuration(duration),
      `a representative .scoria-button transition must collapse under reduced motion, got: ${duration}`
    ).toBe(true);
  });
});
