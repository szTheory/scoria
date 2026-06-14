// priv/dev/e2e/command_palette.spec.mjs
//
// Phase-13 command palette UAT — real-browser assertion lane. Covers keyboard,
// focus, local filtering, localStorage recents, and g-chord navigation that
// server-rendered LiveView tests cannot observe.

import { test, expect } from '@playwright/test';
import { waitForReady } from './lib/ready.mjs';

const BASE = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:4000/scoria';
const RECENTS_KEY = 'scoria:recents:/scoria';

async function openHome(page) {
  await page.goto(BASE);
  await waitForReady(page);
}

async function openPaletteWithKeyboard(page) {
  await page.keyboard.press('Control+K');
  const palette = page.locator('#scoria-command-palette');
  await expect(palette).toBeVisible();
  await expect(palette).toHaveAttribute('data-state', 'open');
  await expect(palette.locator('[data-command-input]')).toBeFocused();
  return palette;
}

async function openPaletteWithButton(page) {
  // Two openers exist in the DOM (mobile topbar + desktop topbar); only one is
  // visible per viewport. Scope to the visible one so strict mode resolves to a
  // single element at the default desktop viewport.
  const opener = page.locator('[data-command-open]').filter({ visible: true }).first();
  await opener.click();
  const palette = page.locator('#scoria-command-palette');
  await expect(palette).toBeVisible();
  await expect(palette).toHaveAttribute('data-state', 'open');
  await expect(palette.locator('[data-command-input]')).toBeFocused();
  return { opener, palette };
}

function commandRow(palette, label) {
  return palette.locator('[data-command-row]').filter({ hasText: label }).first();
}

function pathPattern(path) {
  return new RegExp(`${path.replaceAll('/', '\\/')}(?:$|[?#])`);
}

test.describe('Phase 13 — command palette (IA-04/IA-06)', () => {
  test('Ctrl+K opens, local filtering hides unrelated rows, Escape closes, and focus restores', async ({
    page,
  }) => {
    await openHome(page);

    const keyboardPalette = await openPaletteWithKeyboard(page);
    await page.keyboard.type('runs');

    await expect(commandRow(keyboardPalette, 'Runs')).toBeVisible();
    await expect(commandRow(keyboardPalette, 'Home')).toBeHidden();
    await expect(commandRow(keyboardPalette, 'Approvals')).toBeHidden();

    await keyboardPalette.locator('[data-command-input]').fill('');
    await page.keyboard.press('Shift+Tab');
    await expect(commandRow(keyboardPalette, 'Copy current page URL')).toBeFocused();

    await page.keyboard.press('Escape');
    await expect(keyboardPalette).toHaveAttribute('data-state', 'closed');
    await expect(keyboardPalette).toBeHidden();

    const { opener, palette } = await openPaletteWithButton(page);
    await page.keyboard.press('Escape');
    await expect(palette).toHaveAttribute('data-state', 'closed');
    await expect(palette).toBeHidden();
    await expect(opener).toBeFocused();
  });

  test('keyboard shortcuts overlay opens, closes, traps focus, and ignores editable fields', async ({
    page,
  }) => {
    await openHome(page);

    const shortcuts = page.locator('#scoria-shortcuts');
    await page.keyboard.press('?');
    await expect(shortcuts).toBeVisible();
    await expect(shortcuts).toHaveAttribute('data-state', 'open');
    await expect(page.getByRole('heading', { name: 'Keyboard shortcuts' })).toBeVisible();

    await page.keyboard.press('Tab');
    const close = shortcuts.getByRole('button', { name: 'Close keyboard shortcuts' });
    await expect(close).toBeFocused();
    await page.keyboard.press('Tab');
    await expect(close).toBeFocused();

    await page.keyboard.press('Escape');
    await expect(shortcuts).toHaveAttribute('data-state', 'closed');
    await expect(shortcuts).toBeHidden();

    const palette = await openPaletteWithKeyboard(page);
    await page.keyboard.press('?');
    await expect(shortcuts).toBeHidden();
    await expect(palette.locator('[data-command-input]')).toBeFocused();
  });

  test('g-chords navigate to the locked dashboard destinations', async ({ page }) => {
    await openHome(page);

    for (const [keys, path] of [
      [['g', 'h'], '/scoria/'],
      [['g', 'a'], '/scoria/approvals'],
      [['g', 'r'], '/scoria/workflows'],
      [['g', 'i'], '/scoria/incidents'],
      [['g', 'c'], '/scoria/connectors'],
      [['g', 'q'], '/scoria/reviews'],
      [['g', 'e'], '/scoria/eval_specs'],
      [['g', 'p'], '/scoria/prompts'],
    ]) {
      await page.evaluate(() => document.activeElement?.blur());
      await page.keyboard.press(keys[0]);
      await page.keyboard.press(keys[1]);
      await expect(page).toHaveURL(pathPattern(path));
      await waitForReady(page);
    }
  });

  test('recent objects use the scoped localStorage key, cap stored rows at 8, and show 5', async ({
    page,
  }) => {
    await openHome(page);
    await page.evaluate((key) => {
      const recents = Array.from({ length: 8 }, (_, index) => ({
        kind: 'Run',
        id: `seed-${index}`,
        label: `Seed Run ${index}`,
        path: `/scoria/workflows/seed-${index}`,
      }));
      localStorage.setItem(key, JSON.stringify(recents));
    }, RECENTS_KEY);

    const palette = await openPaletteWithKeyboard(page);
    const recentSection = palette
      .locator('[data-command-section]')
      .filter({ hasText: 'Recent' });
    const recentVisibleRows = await recentSection.evaluate((section) => {
      return Array.from(section.querySelectorAll('[data-command-row]')).filter((row) => !row.hidden)
        .length;
    });
    expect(recentVisibleRows).toBe(5);

    await page.keyboard.press('Escape');
    await expect(palette).toHaveAttribute('data-state', 'closed');
    await expect(palette).toBeHidden();

    await page.evaluate((key) => {
      const recents = Array.from({ length: 9 }, (_, index) => ({
        kind: 'Prompt',
        id: `overflow-${index}`,
        label: `Overflow Prompt ${index}`,
        path: `/scoria/prompts/overflow-${index}`,
      }));
      localStorage.setItem(key, JSON.stringify(recents));
    }, RECENTS_KEY);

    await page.goto(`${BASE}/workflows`);
    await waitForReady(page);
    const firstRun = page.locator('a[href*="/workflows/"]').first();
    await expect(firstRun, 'expected at least one seeded workflow run on /workflows').toBeVisible({
      timeout: 15000,
    });
    await firstRun.click();
    await waitForReady(page);
    await expect(page.locator('.scoria-object-header')).toBeVisible();

    const stored = await page.evaluate((key) => JSON.parse(localStorage.getItem(key)), RECENTS_KEY);
    expect(stored).toHaveLength(8);
    expect(stored[0].kind).toBe('Run');
    expect(stored[0].path).toContain('/scoria/workflows/');
  });
});
