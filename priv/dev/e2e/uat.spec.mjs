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
//   mix dev.setup      # creates + migrates the dev DB and applies dev_seed.exs
//   mix phx.server     # serves the dashboard at PLAYWRIGHT_BASE_URL
//
// Seed note: dev_seed.exs creates exactly ONE pending approval for tenant
// "acme-corp". Approving it consumes it, so only one toast decision can run
// deterministically per seeded DB (see the manual-dismiss fixme below).

import { test, expect } from '@playwright/test';
import { waitForReady } from './lib/ready.mjs';

const BASE = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:4000/scoria';
const SEEDED_TENANT = 'acme-corp';

// Opens the approval modal for the first pending approval in the seeded inbox,
// mirroring the selector the screenshot harness uses (priv/dev/shots.mjs).
//
// dev_seed.exs seeds an approval *run*; the dev Reconciler converts it into an
// inbox-visible pending remote approval a few seconds after boot. Poll (reload)
// until the row appears rather than racing the reconciler — the waitForTimeout is
// a reconciler poll interval, not a fixed test delay.
async function openApprovalModal(page) {
  const trigger = page.locator('button[phx-click="select_approval"]').first();

  for (let attempt = 0; attempt < 12; attempt++) {
    await page.goto(`${BASE}/approvals?tenant=${SEEDED_TENANT}`);
    await waitForReady(page);
    if ((await trigger.count()) > 0) break;
    await page.waitForTimeout(3000);
  }

  await expect(
    trigger,
    'expected a seeded pending approval to reach the inbox (dev_seed + Reconciler)'
  ).toBeVisible();
  await trigger.click();
  await expect(page.locator('button[phx-click="approve"]')).toBeVisible();
}

test.describe('Phase 12 — toast (DS-05)', () => {
  // UAT-2 browser truth: the toast is driven by a server @toasts assign and
  // auto-dismisses via phx-mounted={JS.hide(... time: duration_ms)}. LiveViewTest
  // (approvals_live_test.exs) already proves the toast HTML + tone-by-decision +
  // the phx-mounted attribute + the dismiss control render; this would prove the
  // JS actually fires and the toast goes away unattended in a real browser.
  //
  // Pending: the approvals inbox is not deterministically reachable in the running
  // dev app — the tenant-scoped inbox does not surface the dev_seed pending
  // approval (the page renders "No pending approvals" for ?tenant=acme-corp even
  // though Workflows.list_pending_remote_approvals/1 returns rows), so there is no
  // select_approval row to drive. This is the same approvals-overlay reachability
  // gap Phase 11's screenshot harness hit (11-HUMAN-UAT.md: approve_modal skipped).
  // Activate once a seed/route reliably surfaces an inbox approval for the e2e.
  test.fixme('approval toast renders and auto-dismisses — needs a reachable inbox approval', async ({ page }) => {
    await openApprovalModal(page);
    await page.locator('button[phx-click="approve"]').click();

    const toast = page.locator('#toast-region .scoria-toast');
    await expect(toast).toBeVisible();
    await expect(toast).toContainText('Approval granted.');
    // Unattended: no click — the phx-mounted JS.hide must remove it on its own.
    await expect(toast).toBeHidden({ timeout: 7000 });
  });

  // Manual dismiss is real, wired behavior (phx-click JS.hide on the × button).
  // Blocked by the same reachable-inbox-approval gap as the auto-dismiss spec
  // above. Activate alongside it.
  test.fixme(
    'manual dismiss (×) button hides the toast — needs a reachable inbox approval',
    async ({ page }) => {
      await openApprovalModal(page);
      await page.locator('button[phx-click="reject"]').click();
      const toast = page.locator('#toast-region .scoria-toast');
      await expect(toast).toBeVisible();
      await page.locator('#toast-region [aria-label="Dismiss"]').first().click();
      await expect(toast).toBeHidden({ timeout: 2000 });
    }
  );

  // CR-01 (12-VERIFICATION.md): .scoria-toast position:fixed inside a fixed
  // .scoria-toast-region collapses fixed children to zero height, so a second
  // toast stacks at the same coordinates as the first. Fix lands in Phase 15
  // (high-traffic screens consume <.toast> at scale) — flip to active in the
  // same commit as the CSS fix.
  test.fixme('CR-01: multiple toasts stack without overlapping — fix in Phase 15', async () => {});
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
    ).toBeVisible();
    await firstRun.click();
    await waitForReady(page);

    await expect(page.getByRole('heading', { name: 'Workflow Run' })).toBeVisible();
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
