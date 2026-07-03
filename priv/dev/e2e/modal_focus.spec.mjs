// priv/dev/e2e/modal_focus.spec.mjs
//
// Phase 40 D-10/D-11 — release-workbench decision modal keyboard-driving
// proof. Before this plan, ui.ex's modal/1 only had `autofocus` on its close
// button + phx-key="Escape" — no real trap, and no restore-on-close.
//
// Fix-and-assert ATOMIC (D-04 two-bucket rule): the ui.ex focus_wrap/
// push_focus/pop_focus fix landed in Task 1 of THIS SAME PLAN, so every
// assertion below is throwing. No warning-grade collector here (D-13's
// live-patch risk is drawer-specific, per 40-CONTEXT.md — the release
// workbench's approve/reject modals are not a live PubSub surface the same
// way the approval drawer is).
//
// Lane: auto-discovered by `mix scoria.ui.e2e` via testMatch '**/*.spec.mjs'.
// Deep-links to the seeded draft prompt's release workbench via
// SCORIA_E2E_PROMPT_RELEASE_ID (resolved by lib/mix/tasks/scoria.ui.e2e.ex
// from the dev_seed.exs sentinel entity_id "00000000-...0001"/version 1,
// which always has a pending "prompt_release" approval, per the same
// deterministic-object-id idiom as SCORIA_E2E_REPLAY_RUN_ID).

import { test, expect } from '@playwright/test';
import { waitForReady } from './lib/ready.mjs';

const BASE = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:4799/scoria';
const PROMPT_RELEASE_ID = process.env.SCORIA_E2E_PROMPT_RELEASE_ID || '';

// Mirrors drawer_focus.spec.mjs's aria-hidden-aware focusable-element scan
// (the same focus_wrap sentinels — `#{id}-focus-start`/`-end` — exist here).
const FOCUSABLE_SELECTOR =
  'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), summary, [tabindex]:not([tabindex="-1"])';

function scopedFocusableSelector(containerSelector) {
  return FOCUSABLE_SELECTOR.split(',')
    .map((clause) => `${containerSelector} ${clause.trim()}`)
    .join(', ');
}

async function focusableIdsIn(page, containerSelector) {
  return page.$$eval(scopedFocusableSelector(containerSelector), (els) =>
    els
      .filter((el) => el.getAttribute('aria-hidden') !== 'true' && el.offsetParent !== null)
      .map((el, i) => {
        if (!el.id) {
          el.id = `e2e-focusable-${i}-${Math.random().toString(36).slice(2)}`;
        }
        return el.id;
      })
  );
}

async function activeElementId(page) {
  return page.evaluate(() => document.activeElement && document.activeElement.id);
}

// Mirrors drawer_focus.spec.mjs's poll-not-single-shot hardening: the
// FocusWrap client hook's wrap-around redirect is synchronous but can lose a
// race to a bare post-keypress read under heavy parallel CPU contention.
async function expectActiveElementId(page, expectedId, message) {
  await expect
    .poll(() => activeElementId(page), { message, timeout: 2000 })
    .toBe(expectedId);
}

async function focusIsInside(page, containerId) {
  return page.evaluate((id) => {
    const container = document.getElementById(id);
    return !!container && container.contains(document.activeElement);
  }, containerId);
}

// Opens the "Reject Release" confirm modal on the release workbench — a
// reachable, deterministically-seeded modal surface (the promote-modal on
// workflow_live/show.ex needs a non-empty promotion_snapshot the seeded demo
// replay step may or may not carry; this modal only needs a pending
// prompt_release approval, which dev_seed.exs always creates for the
// sentinel draft template).
async function openRejectModal(page) {
  test.skip(!PROMPT_RELEASE_ID, 'SCORIA_E2E_PROMPT_RELEASE_ID not resolved (DB unavailable to mix scoria.ui.e2e)');

  await page.goto(`${BASE}/prompts/${PROMPT_RELEASE_ID}/release`);
  await waitForReady(page);

  const opener = page.getByRole('button', { name: 'Reject Release' });
  await expect(opener, 'expected the seeded draft prompt release to offer Reject Release').toBeVisible({
    timeout: 15000,
  });
  await opener.click();

  const modal = page.locator('#reject-release-modal');
  await expect(modal).toBeVisible();
  return { opener, modal };
}

test.describe('Phase 40 — release-workbench decision modal focus trap + restore (A11Y-01, D-10/D-11)', () => {
  test('tab-in: focus moves inside the modal on open (never left on the trigger behind the scrim)', async ({
    page,
  }) => {
    await openRejectModal(page);

    expect(
      await focusIsInside(page, 'reject-release-modal'),
      'expected focus to move inside the modal on open (JS.focus_first() via phx-mounted)'
    ).toBe(true);
  });

  test('trap: Tab from the last focusable wraps to the first, Shift+Tab from the first wraps to the last, and focus never lands on the background', async ({
    page,
  }) => {
    await openRejectModal(page);

    const focusableIds = await focusableIdsIn(page, '#reject-release-modal-focus');
    expect(
      focusableIds.length,
      'expected at least 2 real focusable elements inside the modal content'
    ).toBeGreaterThan(1);

    const firstId = focusableIds[0];
    const lastId = focusableIds[focusableIds.length - 1];

    // focus_first() already landed on the first focusable element on open.
    await expectActiveElementId(page, firstId, 'expected focus_first() to land on the first focusable element on open');

    await page.keyboard.press('Shift+Tab');
    await expectActiveElementId(
      page,
      lastId,
      'Shift+Tab from the first focusable element should wrap to the last, never past the modal into the background'
    );
    expect(await focusIsInside(page, 'reject-release-modal')).toBe(true);

    await page.keyboard.press('Tab');
    await expectActiveElementId(
      page,
      firstId,
      'Tab from the last focusable element should wrap back to the first, never past the modal into the background'
    );
    expect(await focusIsInside(page, 'reject-release-modal')).toBe(true);
  });

  test('Esc closes the modal and restores focus to the opening trigger', async ({ page }) => {
    const { opener, modal } = await openRejectModal(page);

    await page.keyboard.press('Escape');
    await expect(modal).toBeHidden();
    await expect(
      opener,
      'expected focus to restore to the opening trigger on close (JS.push_focus() at the opener + phx-remove={JS.pop_focus()} on the modal shell)'
    ).toBeFocused();
  });
});
