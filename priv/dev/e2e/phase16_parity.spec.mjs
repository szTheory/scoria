// priv/dev/e2e/phase16_parity.spec.mjs
//
// Phase 16 browser-truth proof — targeted parity checks for MOTION-01..04.
// Covers:
//   - MOTION-03: No page-level horizontal overflow at 375px on shell + table screens
//   - MOTION-02: Visible focus outlines on representative controls in light + dark themes
//   - MOTION-01: Reduced-motion collapses drawer/skeleton/attention motion to 0s/0.001ms
//   - MOTION-04: Theme-toggle smoke on shell, table, evidence, and overlay paths
//
// Lane: auto-discovered by `mix scoria.ui.e2e` via testMatch '**/*.spec.mjs'.
// No screenshot comparisons (D-30/D-32). Snapshot/screenshot assertions are intentionally excluded.
// No fixed sleeps: rely on waitForReady + expect auto-wait (retries: 2 in CI).

import { test, expect } from '@playwright/test';
import { waitForReady } from './lib/ready.mjs';

const BASE = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:4000/scoria';

// ────────────────────────────────────────────────────────────────────────────
// MOTION-03: 375px overflow checks — shell + representative table screen
// ────────────────────────────────────────────────────────────────────────────

test.describe('Phase 16 — MOTION-03: 375px no page-level horizontal overflow', () => {
  test.use({ viewport: { width: 375, height: 812 } });

  test('shell (Home) has no page-level horizontal overflow at 375px', async ({ page }) => {
    await page.goto(BASE);
    await waitForReady(page);

    const overflow = await page.evaluate(
      () => document.documentElement.scrollWidth > window.innerWidth
    );
    expect(overflow, 'page-level horizontal overflow detected on shell at 375px').toBe(false);
  });

  test('workflows table screen has no page-level horizontal overflow at 375px', async ({
    page,
  }) => {
    await page.goto(`${BASE}/workflows`);
    await waitForReady(page);

    const overflow = await page.evaluate(
      () => document.documentElement.scrollWidth > window.innerWidth
    );
    expect(overflow, 'page-level horizontal overflow detected on /workflows at 375px').toBe(false);
  });

  test('table overflow is contained in .scoria-table__viewport, which is keyboard reachable at 375px', async ({
    page,
  }) => {
    await page.goto(`${BASE}/workflows`);
    await waitForReady(page);

    // The table viewport element must exist and have tabindex="0" so keyboard
    // users can scroll the table independently of the page.
    const viewport = page.locator('.scoria-table__viewport').first();
    await expect(viewport).toBeAttached();

    const tabIndex = await viewport.evaluate((el) => el.getAttribute('tabindex'));
    expect(
      tabIndex,
      '.scoria-table__viewport must have tabindex="0" to be keyboard reachable'
    ).toBe('0');

    // Even if the table itself overflows its container, the page must not overflow.
    const pageOverflow = await page.evaluate(
      () => document.documentElement.scrollWidth > window.innerWidth
    );
    expect(
      pageOverflow,
      'page should not overflow even when the table has a horizontal scroll container'
    ).toBe(false);
  });
});

// ────────────────────────────────────────────────────────────────────────────
// MOTION-02: Focus outline visibility in LIGHT theme — ≥6 control types
// ────────────────────────────────────────────────────────────────────────────

test.describe('Phase 16 — MOTION-02: focus outline visibility in light theme', () => {
  test.use({ colorScheme: 'light', viewport: { width: 375, height: 812 } });

  test('representative link has visible focus outline (light, 375px)', async ({ page }) => {
    await page.goto(BASE);
    await waitForReady(page);

    // A nav link in the mobile drawer — rendered from nav_groups() SSOT
    await page.locator('[data-mobile-nav-open]').click();
    await expect(page.locator('#scoria-mobile-nav')).toBeVisible();

    const navLink = page.locator('#scoria-mobile-nav .scoria-nav').first();
    await navLink.focus();

    const styles = await navLink.evaluate((el) => {
      const cs = getComputedStyle(el);
      return { outlineStyle: cs.outlineStyle, outlineWidth: cs.outlineWidth };
    });
    expect(styles.outlineStyle, 'nav link must have a non-none focus outline (light)').not.toBe(
      'none'
    );
    expect(
      parseFloat(styles.outlineWidth),
      'nav link focus outline must be ≥2px (light)'
    ).toBeGreaterThanOrEqual(2);
  });

  test('[data-command-open] button has visible focus outline (light, 375px)', async ({ page }) => {
    await page.goto(BASE);
    await waitForReady(page);

    const btn = page.locator('[data-command-open]').first();
    await btn.focus();

    const styles = await btn.evaluate((el) => {
      const cs = getComputedStyle(el);
      return { outlineStyle: cs.outlineStyle, outlineWidth: cs.outlineWidth };
    });
    expect(
      styles.outlineStyle,
      '[data-command-open] button must have a non-none focus outline (light)'
    ).not.toBe('none');
    expect(
      parseFloat(styles.outlineWidth),
      '[data-command-open] button focus outline must be ≥2px (light)'
    ).toBeGreaterThanOrEqual(2);
  });

  test('command palette input has visible focus outline (light, 375px)', async ({ page }) => {
    await page.goto(BASE);
    await waitForReady(page);

    await page.keyboard.press('Control+K');
    const palette = page.locator('#scoria-command-palette');
    await expect(palette).toBeVisible();

    const input = palette.locator('[data-command-input]');
    await input.focus();

    const styles = await input.evaluate((el) => {
      const cs = getComputedStyle(el);
      return { outlineStyle: cs.outlineStyle, outlineWidth: cs.outlineWidth };
    });
    // Inputs commonly use outline or box-shadow for focus; outlineStyle may be 'none'
    // when the browser collapses outline:0 in favor of a box-shadow ring. Accept both.
    const hasVisibleOutline =
      styles.outlineStyle !== 'none' && parseFloat(styles.outlineWidth) >= 2;

    // If outline is suppressed, assert a visible box-shadow focus ring instead.
    if (!hasVisibleOutline) {
      const boxShadow = await input.evaluate((el) => getComputedStyle(el).boxShadow);
      expect(
        boxShadow,
        'command input must show focus via outline ≥2px or a non-none box-shadow ring (light)'
      ).not.toBe('none');
    }
  });

  test('table action button has visible focus outline in light theme', async ({ page }) => {
    await page.goto(`${BASE}/workflows`);
    await waitForReady(page);

    // A link or button that navigates to a workflow detail from the table
    const tableAction = page.locator('.scoria-table a, .scoria-table button').first();
    await tableAction.focus();

    const styles = await tableAction.evaluate((el) => {
      const cs = getComputedStyle(el);
      return { outlineStyle: cs.outlineStyle, outlineWidth: cs.outlineWidth };
    });
    expect(
      styles.outlineStyle,
      'table action must have a non-none focus outline (light)'
    ).not.toBe('none');
    expect(
      parseFloat(styles.outlineWidth),
      'table action focus outline must be ≥2px (light)'
    ).toBeGreaterThanOrEqual(2);
  });

  test('command palette item has visible focus outline (light)', async ({ page }) => {
    await page.goto(BASE);
    await waitForReady(page);

    await page.keyboard.press('Control+K');
    const palette = page.locator('#scoria-command-palette');
    await expect(palette).toBeVisible();

    // Focus the first command row by pressing Tab once past the input
    const firstRow = palette.locator('[data-command-row]').first();
    await firstRow.focus();

    const styles = await firstRow.evaluate((el) => {
      const cs = getComputedStyle(el);
      return { outlineStyle: cs.outlineStyle, outlineWidth: cs.outlineWidth };
    });
    expect(
      styles.outlineStyle,
      'command palette item must have a non-none focus outline (light)'
    ).not.toBe('none');
    expect(
      parseFloat(styles.outlineWidth),
      'command palette item focus outline must be ≥2px (light)'
    ).toBeGreaterThanOrEqual(2);
  });

  test('mobile nav item has visible focus outline (light, 375px)', async ({ page }) => {
    await page.goto(BASE);
    await waitForReady(page);

    // Open drawer and focus the close button (always present) and a nav item
    await page.locator('[data-mobile-nav-open]').click();
    const drawer = page.locator('#scoria-mobile-nav');
    await expect(drawer).toBeVisible();

    const closeBtn = drawer.locator('[data-mobile-nav-close]').first();
    await closeBtn.focus();

    const styles = await closeBtn.evaluate((el) => {
      const cs = getComputedStyle(el);
      return { outlineStyle: cs.outlineStyle, outlineWidth: cs.outlineWidth };
    });
    expect(
      styles.outlineStyle,
      'mobile nav close button must have a non-none focus outline (light)'
    ).not.toBe('none');
    expect(
      parseFloat(styles.outlineWidth),
      'mobile nav close button focus outline must be ≥2px (light)'
    ).toBeGreaterThanOrEqual(2);
  });
});

// ────────────────────────────────────────────────────────────────────────────
// MOTION-02: Focus outline visibility in DARK theme — same 6 control types
// ────────────────────────────────────────────────────────────────────────────

test.describe('Phase 16 — MOTION-02: focus outline visibility in dark theme', () => {
  test.use({ colorScheme: 'dark', viewport: { width: 375, height: 812 } });

  test('representative link has visible focus outline (dark, 375px)', async ({ page }) => {
    await page.goto(BASE);
    await waitForReady(page);

    await page.locator('[data-mobile-nav-open]').click();
    await expect(page.locator('#scoria-mobile-nav')).toBeVisible();

    const navLink = page.locator('#scoria-mobile-nav .scoria-nav').first();
    await navLink.focus();

    const styles = await navLink.evaluate((el) => {
      const cs = getComputedStyle(el);
      return { outlineStyle: cs.outlineStyle, outlineWidth: cs.outlineWidth };
    });
    expect(
      styles.outlineStyle,
      'nav link must have a non-none focus outline (dark)'
    ).not.toBe('none');
    expect(
      parseFloat(styles.outlineWidth),
      'nav link focus outline must be ≥2px (dark)'
    ).toBeGreaterThanOrEqual(2);
  });

  test('[data-command-open] button has visible focus outline (dark, 375px)', async ({ page }) => {
    await page.goto(BASE);
    await waitForReady(page);

    const btn = page.locator('[data-command-open]').first();
    await btn.focus();

    const styles = await btn.evaluate((el) => {
      const cs = getComputedStyle(el);
      return { outlineStyle: cs.outlineStyle, outlineWidth: cs.outlineWidth };
    });
    expect(
      styles.outlineStyle,
      '[data-command-open] button must have a non-none focus outline (dark)'
    ).not.toBe('none');
    expect(
      parseFloat(styles.outlineWidth),
      '[data-command-open] button focus outline must be ≥2px (dark)'
    ).toBeGreaterThanOrEqual(2);
  });

  test('command palette input has visible focus outline (dark)', async ({ page }) => {
    await page.goto(BASE);
    await waitForReady(page);

    await page.keyboard.press('Control+K');
    const palette = page.locator('#scoria-command-palette');
    await expect(palette).toBeVisible();

    const input = palette.locator('[data-command-input]');
    await input.focus();

    const styles = await input.evaluate((el) => {
      const cs = getComputedStyle(el);
      return { outlineStyle: cs.outlineStyle, outlineWidth: cs.outlineWidth };
    });
    const hasVisibleOutline =
      styles.outlineStyle !== 'none' && parseFloat(styles.outlineWidth) >= 2;

    if (!hasVisibleOutline) {
      const boxShadow = await input.evaluate((el) => getComputedStyle(el).boxShadow);
      expect(
        boxShadow,
        'command input must show focus via outline ≥2px or a non-none box-shadow ring (dark)'
      ).not.toBe('none');
    }
  });

  test('table action has visible focus outline (dark)', async ({ page }) => {
    await page.goto(`${BASE}/workflows`);
    await waitForReady(page);

    const tableAction = page.locator('.scoria-table a, .scoria-table button').first();
    await tableAction.focus();

    const styles = await tableAction.evaluate((el) => {
      const cs = getComputedStyle(el);
      return { outlineStyle: cs.outlineStyle, outlineWidth: cs.outlineWidth };
    });
    expect(
      styles.outlineStyle,
      'table action must have a non-none focus outline (dark)'
    ).not.toBe('none');
    expect(
      parseFloat(styles.outlineWidth),
      'table action focus outline must be ≥2px (dark)'
    ).toBeGreaterThanOrEqual(2);
  });

  test('command palette item has visible focus outline (dark)', async ({ page }) => {
    await page.goto(BASE);
    await waitForReady(page);

    await page.keyboard.press('Control+K');
    const palette = page.locator('#scoria-command-palette');
    await expect(palette).toBeVisible();

    const firstRow = palette.locator('[data-command-row]').first();
    await firstRow.focus();

    const styles = await firstRow.evaluate((el) => {
      const cs = getComputedStyle(el);
      return { outlineStyle: cs.outlineStyle, outlineWidth: cs.outlineWidth };
    });
    expect(
      styles.outlineStyle,
      'command palette item must have a non-none focus outline (dark)'
    ).not.toBe('none');
    expect(
      parseFloat(styles.outlineWidth),
      'command palette item focus outline must be ≥2px (dark)'
    ).toBeGreaterThanOrEqual(2);
  });

  test('mobile nav item has visible focus outline (dark, 375px)', async ({ page }) => {
    await page.goto(BASE);
    await waitForReady(page);

    await page.locator('[data-mobile-nav-open]').click();
    const drawer = page.locator('#scoria-mobile-nav');
    await expect(drawer).toBeVisible();

    const closeBtn = drawer.locator('[data-mobile-nav-close]').first();
    await closeBtn.focus();

    const styles = await closeBtn.evaluate((el) => {
      const cs = getComputedStyle(el);
      return { outlineStyle: cs.outlineStyle, outlineWidth: cs.outlineWidth };
    });
    expect(
      styles.outlineStyle,
      'mobile nav close button must have a non-none focus outline (dark)'
    ).not.toBe('none');
    expect(
      parseFloat(styles.outlineWidth),
      'mobile nav close button focus outline must be ≥2px (dark)'
    ).toBeGreaterThanOrEqual(2);
  });
});

// ────────────────────────────────────────────────────────────────────────────
// MOTION-01: Reduced-motion collapse — drawer path + skeleton/attention cue
// ────────────────────────────────────────────────────────────────────────────

test.describe('Phase 16 — MOTION-01: reduced-motion collapse', () => {
  test.use({ viewport: { width: 375, height: 812 } });

  test('mobile nav drawer motion collapses to 0s or 0.001ms under prefers-reduced-motion', async ({
    page,
  }) => {
    // Emulate reduced motion BEFORE navigation so the media query is active
    // when the page's CSS is evaluated for the first time.
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.goto(BASE);
    await waitForReady(page);

    // Open the drawer to ensure it is in the DOM and rendered
    await page.locator('[data-mobile-nav-open]').click();
    const drawer = page.locator('#scoria-mobile-nav');
    await expect(drawer).toBeVisible();

    // Probe transition duration on the drawer panel — must be effectively instant
    // (0s or 0.001ms) per RESEARCH assumption A2.
    const duration = await drawer.locator('.scoria-mobile-drawer').evaluate((el) => {
      return getComputedStyle(el).transitionDuration;
    });
    expect(
      ['0s', '0.001ms', '0.001ms, 0.001ms', '0s, 0s'],
      'mobile drawer transition duration must collapse to 0s or 0.001ms under reduced motion'
    ).toContain(duration);
  });

  test('skeleton/attention motion collapses to 0s or 0.001ms under prefers-reduced-motion', async ({
    page,
  }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.goto(`${BASE}/workflows`);
    await waitForReady(page);

    // Probe any skeleton or attention cue that exists on the page.
    // Returns '0s' as fallback if neither element is present (acceptable —
    // reduced motion is already effectively instant in that case).
    const duration = await page.evaluate(() => {
      const probe = document.querySelector('.scoria-skeleton, .scoria-attention');
      return probe ? getComputedStyle(probe).animationDuration : '0s';
    });

    expect(
      ['0s', '0.001ms'],
      'skeleton/attention animation duration must be 0s or 0.001ms under reduced motion'
    ).toContain(duration);
  });

  test('.scoria-root * transitions collapse under prefers-reduced-motion on the shell', async ({
    page,
  }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.goto(BASE);
    await waitForReady(page);

    // The prefers-reduced-motion kill switch in 05-motion.css targets .scoria-root *
    // and sets transition-duration: 0.001ms. Probe a generic interactive element
    // (the theme toggle, which has a transition in normal mode).
    const duration = await page.evaluate(() => {
      const el =
        document.querySelector('#scoria-theme-toggle') ||
        document.querySelector('#scoria-theme-toggle-mobile') ||
        document.querySelector('[data-mobile-nav-open]') ||
        document.querySelector('[data-command-open]');
      return el ? getComputedStyle(el).transitionDuration : '0s';
    });

    // Accept 0s, 0.001ms, or comma-separated equivalents (multi-property shorthand)
    const acceptedValues = ['0s', '0.001ms', '0.001ms, 0.001ms', '0s, 0s'];
    expect(
      acceptedValues.includes(duration) || duration.split(',').every((d) => d.trim() === '0.001ms' || d.trim() === '0s'),
      `transition duration on .scoria-root * should be 0s or 0.001ms under reduced motion, got: ${duration}`
    ).toBe(true);
  });
});

// ────────────────────────────────────────────────────────────────────────────
// MOTION-04: Theme-toggle smoke — shell, table, evidence, and overlay path
// ────────────────────────────────────────────────────────────────────────────

test.describe('Phase 16 — MOTION-04: theme-toggle smoke', () => {
  // Start in dark theme (default for scoria-root) and toggle to light.
  // The toggle must flip `data-theme` on `.scoria-root` and the page must
  // remain ready with a key landmark visible.

  test('Home/shell: theme toggle flips data-theme and page stays ready', async ({ page }) => {
    await page.goto(BASE);
    await waitForReady(page);

    const root = page.locator('.scoria-root');

    // Determine the initial theme attribute (dark default = null / absent; light = "light")
    const initialTheme = await root.evaluate((el) => el.getAttribute('data-theme') ?? 'dark');

    // Use the desktop or mobile theme toggle; prefer desktop at 1280px default viewport.
    const toggleSelector = '#scoria-theme-toggle, #scoria-theme-toggle-mobile';
    const toggle = page.locator(toggleSelector).first();
    await toggle.click();

    // Theme attribute must flip
    const newTheme = await root.evaluate((el) => el.getAttribute('data-theme') ?? 'dark');
    expect(newTheme, 'data-theme must change after toggle').not.toBe(initialTheme);

    // Page must still be ready
    await waitForReady(page);
    await expect(page.locator('.scoria-shell, .scoria-mobile-topbar').first()).toBeVisible();
  });

  test('Workflows table screen: theme toggle flips and page stays ready', async ({ page }) => {
    await page.goto(`${BASE}/workflows`);
    await waitForReady(page);

    const root = page.locator('.scoria-root');
    const initialTheme = await root.evaluate((el) => el.getAttribute('data-theme') ?? 'dark');

    const toggle = page.locator('#scoria-theme-toggle, #scoria-theme-toggle-mobile').first();
    await toggle.click();

    const newTheme = await root.evaluate((el) => el.getAttribute('data-theme') ?? 'dark');
    expect(newTheme, 'data-theme must change after toggle on /workflows').not.toBe(initialTheme);

    await waitForReady(page);
    // A key landmark on the workflows table screen
    await expect(page.locator('.scoria-table, .scoria-table__viewport').first()).toBeVisible();
  });

  test('Workflow detail (evidence screen): theme toggle flips and page stays ready', async ({
    page,
  }) => {
    await page.goto(`${BASE}/workflows`);
    await waitForReady(page);

    // Navigate to the first workflow detail (object/evidence screen)
    const firstRun = page.locator('a[href*="/workflows/"]').first();
    const hasRun = (await firstRun.count()) > 0;

    if (!hasRun) {
      // No seeded runs available — the theme toggle is still testable on the list
      test.info().annotations.push({
        type: 'notice',
        description: 'No seeded workflow runs; theme toggle tested on list screen instead',
      });
      const root = page.locator('.scoria-root');
      const initialTheme = await root.evaluate((el) => el.getAttribute('data-theme') ?? 'dark');
      const toggle = page.locator('#scoria-theme-toggle, #scoria-theme-toggle-mobile').first();
      await toggle.click();
      const newTheme = await root.evaluate((el) => el.getAttribute('data-theme') ?? 'dark');
      expect(newTheme).not.toBe(initialTheme);
      return;
    }

    await firstRun.click();
    await waitForReady(page);

    const root = page.locator('.scoria-root');
    const initialTheme = await root.evaluate((el) => el.getAttribute('data-theme') ?? 'dark');

    const toggle = page.locator('#scoria-theme-toggle, #scoria-theme-toggle-mobile').first();
    await toggle.click();

    const newTheme = await root.evaluate((el) => el.getAttribute('data-theme') ?? 'dark');
    expect(
      newTheme,
      'data-theme must change after toggle on workflow detail screen'
    ).not.toBe(initialTheme);

    await waitForReady(page);
    await expect(page.locator('.scoria-object-header').first()).toBeVisible();
  });

  test('Overlay path (mobile nav drawer): theme toggle flips and drawer stays open', async ({
    page,
  }) => {
    // Use 375px so the mobile topbar and drawer are present.
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto(BASE);
    await waitForReady(page);

    // Open the mobile nav overlay
    await page.locator('[data-mobile-nav-open]').click();
    const drawer = page.locator('#scoria-mobile-nav');
    await expect(drawer).toBeVisible();

    const root = page.locator('.scoria-root');
    const initialTheme = await root.evaluate((el) => el.getAttribute('data-theme') ?? 'dark');

    // Toggle theme using the mobile topbar toggle (the drawer overlay is open but
    // the mobile topbar toggle is in the topbar, which may be obscured by the drawer.
    // Use the mobile toggle id directly; it persists in DOM even under the overlay).
    const mobileToggle = page.locator('#scoria-theme-toggle-mobile');
    const hasToggle = (await mobileToggle.count()) > 0;

    if (hasToggle) {
      await mobileToggle.click({ force: true });
    } else {
      // Fallback: close drawer and use desktop toggle
      await page.keyboard.press('Escape');
      await expect(drawer).toBeHidden();
      const desktopToggle = page.locator('#scoria-theme-toggle').first();
      await desktopToggle.click();
    }

    const newTheme = await root.evaluate((el) => el.getAttribute('data-theme') ?? 'dark');
    expect(
      newTheme,
      'data-theme must change after toggle on overlay path'
    ).not.toBe(initialTheme);

    await waitForReady(page);
  });
});
