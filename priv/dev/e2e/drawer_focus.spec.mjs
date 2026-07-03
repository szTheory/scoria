// priv/dev/e2e/drawer_focus.spec.mjs
//
// Phase 40 D-10/D-11 — approval decision drawer keyboard-driving proof. The
// drawer is the $10k-refund approval decision surface: the highest-stakes
// keyboard surface in the product. Before this plan it rendered
// role="dialog" aria-modal="true" but had NO focus trap, NO autofocus, and
// NO restore-on-close — a keyboard user closing it (or tabbing past its
// last control) landed on the trigger behind the scrim or on <body>.
//
// Fix-and-assert ATOMIC (D-04 two-bucket rule): the ui.ex focus_wrap/
// push_focus/pop_focus fix landed in Task 1 of THIS SAME PLAN, so every
// assertion below is a THROWING expect() — except the D-13 live-patch
// survival check, which is an explicitly non-throwing WARNING-GRADE
// collector (console.warn + testInfo.attach, never expect()/test.fail()/
// expect.soft — those are banned as the warning mechanism per D-04).
//
// Lane: auto-discovered by `mix scoria.ui.e2e` via testMatch '**/*.spec.mjs'.
// Seeded by mix scoria.ui.e2e's ensure_pending_approval_fixtures! (floor of
// 10 pending approvals for the SupportJourney tenant) before Playwright runs.

import { test, expect } from '@playwright/test';
import { waitForReady } from './lib/ready.mjs';
import { boxesIntersect } from './lib/boxes_intersect.mjs';

const BASE = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:4799/scoria';
const DRAWER_ID = 'approval-detail-drawer';
const DRAWER_WRAP_ID = `${DRAWER_ID}-focus`;

// Real interactive elements only — deliberately mirrors ARIA.isFocusable's
// aria-hidden exclusion (phoenix_live_view/assets/js/phoenix_live_view/
// aria.js) so the two aria-hidden focus_wrap sentinel divs
// (`#{id}-start`/`#{id}-end`, the wrap-around markers the FocusWrap client
// hook uses internally) are never mistaken for real tab stops.
const FOCUSABLE_SELECTOR =
  'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), summary, [tabindex]:not([tabindex="-1"])';

// Scopes EVERY comma-separated clause of FOCUSABLE_SELECTOR to
// containerSelector — string-concatenating a container prefix onto only the
// FIRST clause of a comma list leaves the rest unscoped (global) selectors,
// which would silently match unrelated elements elsewhere on the page (e.g.
// the ⌘K command-palette opener button).
function scopedFocusableSelector(containerSelector) {
  return FOCUSABLE_SELECTOR.split(',')
    .map((clause) => `${containerSelector} ${clause.trim()}`)
    .join(', ');
}

async function focusableIdsIn(page, containerSelector) {
  return page.$$eval(scopedFocusableSelector(containerSelector), (els) =>
    els
      // Exclude the aria-hidden focus_wrap sentinels AND anything not
      // actually in the real Tab order right now — e.g. the content of a
      // closed <details> (raw_evidence/identifiers default to collapsed),
      // whose children match the selector but are natively un-tabbable
      // while hidden. `offsetParent === null` is the standard "not
      // rendered/visible" check (also true for closed <details> children).
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

async function focusIsInside(page, containerId) {
  return page.evaluate((id) => {
    const container = document.getElementById(id);
    return !!container && container.contains(document.activeElement);
  }, containerId);
}

// Opens the approval detail drawer from the first VISIBLE "Inspect approval"
// opener (two exist per row — desktop table action + mobile_summary action —
// only one is visible per viewport, mirroring command_palette.spec.mjs's
// openPaletteWithButton pattern).
async function openApprovalDrawer(page) {
  await page.goto(`${BASE}/approvals`);
  await waitForReady(page);

  const opener = page.getByRole('button', { name: 'Inspect approval' }).filter({ visible: true }).first();
  await expect(
    opener,
    'expected at least one seeded pending approval row (mix scoria.ui.e2e tops up fixtures)'
  ).toBeVisible({ timeout: 15000 });
  await opener.click();

  const drawer = page.locator(`#${DRAWER_ID}`);
  await expect(drawer).toBeVisible();
  return { opener, drawer };
}

test.describe('Phase 40 — approval decision drawer focus trap + restore (A11Y-01, D-10/D-11)', () => {
  test('tab-in: focus moves inside the drawer on open (never left on the trigger behind the scrim)', async ({
    page,
  }) => {
    await openApprovalDrawer(page);

    expect(
      await focusIsInside(page, DRAWER_ID),
      'expected focus to move inside the drawer on open (JS.focus_first() via phx-mounted)'
    ).toBe(true);
  });

  test('trap: Tab from the last focusable wraps to the first, Shift+Tab from the first wraps to the last, and focus never lands on the background', async ({
    page,
  }) => {
    await openApprovalDrawer(page);

    const focusableIds = await focusableIdsIn(page, `#${DRAWER_WRAP_ID}`);
    expect(
      focusableIds.length,
      'expected at least 2 real focusable elements inside the drawer content'
    ).toBeGreaterThan(1);

    const firstId = focusableIds[0];
    const lastId = focusableIds[focusableIds.length - 1];

    // focus_first() already landed on the first focusable element on open.
    expect(await activeElementId(page)).toBe(firstId);

    await page.keyboard.press('Shift+Tab');
    expect(
      await activeElementId(page),
      'Shift+Tab from the first focusable element should wrap to the last, never past the drawer into the background'
    ).toBe(lastId);
    expect(await focusIsInside(page, DRAWER_ID)).toBe(true);

    await page.keyboard.press('Tab');
    expect(
      await activeElementId(page),
      'Tab from the last focusable element should wrap back to the first, never past the drawer into the background'
    ).toBe(firstId);
    expect(await focusIsInside(page, DRAWER_ID)).toBe(true);
  });

  test('Esc closes the drawer and restores focus to the opening trigger', async ({ page }) => {
    const { opener, drawer } = await openApprovalDrawer(page);

    await page.keyboard.press('Escape');
    await expect(drawer).toBeHidden();
    await expect(
      opener,
      'expected focus to restore to the opening trigger on close (JS.push_focus() at the opener + phx-remove={JS.pop_focus()} on the drawer shell)'
    ).toBeFocused();
  });

  test('SC 2.4.11: a focused control reachable after the sticky approval-actions footer is not covered by it', async ({
    page,
  }) => {
    await openApprovalDrawer(page);

    // The raw-evidence disclosure is always rendered for an open approval
    // (unconditional on @active_approval, unlike the "View run details" link
    // which needs a workflow_run_id) and sits AFTER the
    // position:sticky;bottom:0 .scoria-approval-actions footer in DOM/scroll
    // order — a deterministic target that exercises the exact occlusion risk
    // D-11/D-17 assign to this spec (D-16(5) explicitly excludes the sticky
    // footer from its own static-occlusion check and delegates this pairing
    // here). It defaults collapsed, so open it first (a real keyboard user
    // tabs to the <summary> and presses Enter/click before reaching the
    // copy control inside).
    const summary = page.locator('.scoria-raw-evidence__summary');
    await expect(summary, 'expected the raw-evidence disclosure to be reachable').toBeVisible();
    await summary.click();

    const copyButton = page.locator('[data-raw-evidence-copy]');
    await expect(copyButton, 'expected the raw-evidence copy control to be reachable once expanded').toBeVisible();
    await copyButton.focus();
    await expect(copyButton).toBeFocused();

    const footer = page.locator('.scoria-approval-actions');

    if ((await footer.count()) > 0) {
      const copyRect = await copyButton.evaluate((el) => el.getBoundingClientRect().toJSON());
      const footerRect = await footer.first().evaluate((el) => el.getBoundingClientRect().toJSON());

      expect(
        boxesIntersect(copyRect, footerRect),
        'expected the focused control to NOT be covered by the sticky bottom approval-actions footer (SC 2.4.11)'
      ).toBe(false);
    }
  });

  // D-13 (warning-grade, non-throwing collector — D-04 two-bucket rule): the
  // approval drawer is a live PubSub surface. An unrelated broadcast can
  // phx-update it while open; a naive focus_wrap does not guarantee focus
  // survives that patch. This test drives a REAL unrelated broadcast (a
  // decision recorded on a DIFFERENT pending approval, from a second
  // browser tab) and checks whether focus is still inside THIS drawer
  // afterward — but it only warns (never throws) since the fix for this
  // specific risk has not landed and D-04 bans expect()/test.fail()/
  // expect.soft as the warning mechanism.
  test('D-13 (warning-grade collector): focus survives an unrelated live PubSub patch while the drawer stays open', async ({
    page,
    context,
  }, testInfo) => {
    await openApprovalDrawer(page);
    const beforeId = await activeElementId(page);

    const secondPage = await context.newPage();
    try {
      await secondPage.goto(`${BASE}/approvals`);
      await waitForReady(secondPage);

      const openers = secondPage.getByRole('button', { name: 'Inspect approval' }).filter({ visible: true });
      const openerCount = await openers.count();

      if (openerCount > 1) {
        // A DIFFERENT approval than the one open in `page` (row 0) — an
        // "unrelated" decision from this tenant's perspective.
        await openers.nth(1).click();
        const secondDrawer = secondPage.locator(`#${DRAWER_ID}`);
        await expect(secondDrawer).toBeVisible();

        const denyButton = secondDrawer.getByRole('button', { name: 'Deny request' });
        if ((await denyButton.count()) > 0) {
          await denyButton.click();
          const decisionModal = secondPage.locator('#approval-decision-modal');
          await expect(decisionModal).toBeVisible();
          await decisionModal.getByRole('button', { name: 'Deny request' }).click();
          // Give the PubSub broadcast + reload_inbox() re-render a moment to
          // land on page 1's socket before re-checking its focus state.
          await page.waitForTimeout(500);
        }
      }
    } finally {
      await secondPage.close();
    }

    const afterId = await activeElementId(page);
    const stillInside = await focusIsInside(page, DRAWER_ID);

    if (!stillInside || beforeId !== afterId) {
      const message =
        'D-13 WARNING (non-blocking, does not fail the run): focus did not survive an unrelated ' +
        `live patch on the approval drawer (before="${beforeId}" after="${afterId}" ` +
        `stillInside=${stillInside}). focus_wrap alone may not hold focus through this patch path ` +
        '— Phase 41 should consider hardening with a private restore hook keyed on the drawer id.';
      console.warn(message);
      await testInfo.attach('d13-live-patch-focus-warning', { body: message, contentType: 'text/plain' });
    }
  });
});
