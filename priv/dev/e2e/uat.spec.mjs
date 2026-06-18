// priv/dev/e2e/uat.spec.mjs
//
// Phase-12 design-system UAT — real-browser assertion lane. Covers the truths a
// server-rendered LiveViewTest (Floki, no JS engine) CANNOT reach: client-side
// JS execution (JS.hide), CSS layout, and async re-render in a live browser.
// The server-renderable halves of these truths are already asserted in
// test/scoria_web/live/{approvals,workflow}_live_test.exs — this lane is the
// complement, not a duplicate.
//
// Prerequisites (owned by `mix scoria.ui.e2e` caller / CI):
//   make dev           # serves the dashboard at PLAYWRIGHT_BASE_URL
//
// Fixture note: mix scoria.ui.e2e tops up 5 pending approvals for tenant
// "acme-corp" before Playwright starts (via mark_waiting_for_approval on a
// non-queued step). Each approval decision is destructive, so the toast specs run
// serially with no retries.

import { test, expect } from '@playwright/test';
import { waitForReady } from './lib/ready.mjs';

const BASE = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:4799/scoria';
const SEEDED_TENANT = 'acme-corp';

// Opens the decision-confirm modal for a pending approval in the seeded inbox,
// leaving the modal's `phx-click="${decision}"` confirm button visible for the
// caller to click. Drives the shipped approvals flow:
//   inbox row (select_approval) → detail drawer (open_decision_modal) → modal.
// The inbox auto-seeds the first pending approval into the detail drawer on mount
// (maybe_seed_active_approval), and the drawer's `.scoria-scrim` overlays the
// inbox table — so we reach the decision through the already-open drawer rather
// than re-clicking the now-obscured inbox row. If the drawer is not auto-open
// (no pending approval matched focus), we open it from the first inbox row.
async function openDecisionModal(page, decision) {
  await page.goto(`${BASE}/approvals?tenant=${SEEDED_TENANT}`);
  await waitForReady(page);

  const drawerDecision = page.locator(
    `#approval-detail-drawer button[phx-click="open_decision_modal"][phx-value-decision="${decision}"]`
  );

  if ((await drawerDecision.count()) === 0) {
    const trigger = page.locator('button[phx-click="select_approval"]').first();
    await expect(
      trigger,
      'expected a seeded pending approval in the inbox (mix dev.setup applies dev_seed.exs)'
    ).toBeVisible();
    await trigger.click();
  }

  await expect(
    drawerDecision,
    'expected the approval detail drawer to offer the decision action'
  ).toBeVisible();
  await drawerDecision.click();

  await expect(page.locator(`button[phx-click="${decision}"]`)).toBeVisible();
}

test.describe('Phase 12 — toast (DS-05)', () => {
  // Each decision consumes a seeded approval, so run serially and never retry
  // (a retry would re-consume approvals it no longer has).
  test.describe.configure({ mode: 'serial', retries: 0 });

  // UAT-2 browser truth: the toast is driven by a server @toasts assign and
  // auto-dismisses via phx-mounted={JS.hide(... time: duration_ms)}. LiveViewTest
  // (approvals_live_test.exs) proves the toast HTML + tone-by-decision + the
  // phx-mounted attribute + the dismiss control render; this proves the JS actually
  // fires and the toast goes away unattended in a real browser.
  test('approval toast renders and auto-dismisses', async ({ page }) => {
    await openDecisionModal(page, 'approve');
    await page.locator('button[phx-click="approve"]').click();

    const toast = page.locator('#toast-region .scoria-toast');
    await expect(toast).toBeVisible();
    await expect(toast).toContainText('Approval granted.');
    // Unattended: no click — the phx-mounted JS.hide must remove it on its own.
    await expect(toast).toBeHidden({ timeout: 7000 });
  });

  // Manual dismiss: the × button (phx-click JS.hide) removes the toast immediately.
  test('manual dismiss (×) button hides the toast', async ({ page }) => {
    await openDecisionModal(page, 'reject');
    await page.locator('button[phx-click="reject"]').click();
    const toast = page.locator('#toast-region .scoria-toast');
    await expect(toast).toBeVisible();
    await page.locator('#toast-region [aria-label="Dismiss"]').first().click();
    await expect(toast).toBeHidden({ timeout: 2000 });
  });

  // CR-01 (12-VERIFICATION.md, now fixed): .scoria-toast was position:fixed inside
  // the fixed .scoria-toast-region, so every toast pinned to the same bottom-right
  // corner and overlapped. The fix removes position:fixed from the toast — the
  // region (flex column) owns stacking, so toasts flow and never collapse onto each
  // other. Asserting the computed position is not "fixed" verifies the fix
  // race-free (no dependence on two toasts being visible within the 4s window).
  test('CR-01: a toast is not position:fixed (region owns stacking)', async ({ page }) => {
    await openDecisionModal(page, 'approve');
    await page.locator('button[phx-click="approve"]').click();

    const toast = page.locator('#toast-region .scoria-toast').first();
    await expect(toast).toBeVisible();
    const position = await toast.evaluate((el) => getComputedStyle(el).position);
    expect(position, 'CR-01: toast must not be position:fixed').not.toBe('fixed');
  });
});

test.describe('Phase 12 — skeleton (DS-05)', () => {
  // UAT-4 browser truth: the loading skeleton is replaced when the async assign
  // resolves in a live browser. toHaveCount(0) auto-waits for replacement, so it
  // captures the resolution without racing the (sub-second) appearance — the
  // appearance half is asserted server-side in workflow_live_test.exs.
  test('workflow detail resolves its loading skeleton', async ({ page }) => {
    await page.goto(`${BASE}/workflows`);
    await waitForReady(page);

    const firstRun = page.locator('a[href*="/workflows/"]').first();
    await expect(
      firstRun,
      'expected at least one seeded workflow run on /workflows'
    ).toBeVisible({ timeout: 15000 });
    await firstRun.click();
    await waitForReady(page);

    const objectHeader = page.locator('.scoria-object-header');
    await expect(objectHeader).toBeVisible();
    await expect(objectHeader.getByText('Run', { exact: true })).toBeVisible();
    await expect(page.locator('.scoria-skeleton')).toHaveCount(0);
    await expect(page.getByText('Failed to load memories.')).toHaveCount(0);
  });
});

test.describe('Phase 12 — overlays & notebook (DS-02/DS-04, pending)', () => {
  // The notebook tab-switch re-render is browser-only, but the only live consumer
  // (RemoteInvocationEvidenceComponent on the workflow detail page) is gated on
  // SRE.remote_invocation_evidence/1, which is currently a stub returning
  // %{approvals: []} — so the notebook never renders in the running app yet. The
  // notebook adapter itself is proven at the component level in
  // test/scoria_web/ui_component_test.exs. Activate when real evidence is wired.
  test.fixme('notebook tab switch re-renders the active panel — needs wired evidence data', async () => {});

  // WR-03 (12-VERIFICATION.md): .scoria-drawer has no position/z-index/width, so it
  // renders inline in document flow instead of as a floating side panel. The ui.ex
  // drawer/1 is also not yet wired into a reachable screen. Fix + screen wiring land
  // in Phase 14/15 — flip to active alongside the CSS fix.
  test.fixme('WR-03: drawer renders as a floating side panel — fix in Phase 14/15', async () => {});

  // Escape-dismiss is implemented on ui.ex modal/1 + drawer/1 (phx-window-keydown),
  // but those components are not yet wired into a reachable dashboard screen (the
  // current approvals modal is bespoke markup without keyboard dismiss). Activate
  // when a screen adopts the <.modal>/<.drawer> shells.
  test.fixme('Escape key dismisses an open ui.ex overlay — needs a screen using <.modal>/<.drawer>', async () => {});
});
