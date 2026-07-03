// priv/dev/e2e/ia_orientation.spec.mjs
//
// Phase-13 orientation-spine (IA) walkthrough — real-browser assertion lane.
//
// This is the integration seam the ExUnit LiveView suite cannot reach: those
// tests use inline per-test routers and self-built fixtures, so they never
// exercise the dev_router tenant-default plug or priv/repo/dev_seed.exs. This
// spec drives the SEEDED demo data through the real LiveView socket at the
// BARE base URL (no ?tenant=), so it guards:
//   * the dev_router session tenant default (bare URL shows demo-tenant data),
//   * dev_seed.exs block (g) producing every IA state, and
//   * the end-to-end ingress/egress click-path operators actually use.
// It would have caught the "empty dashboard / wrong tenant" regression.

import { test, expect } from '@playwright/test';
import { waitForReady } from './lib/ready.mjs';

const BASE = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:4799/scoria';
const REPLAY_RUN_ID = process.env.SCORIA_E2E_REPLAY_RUN_ID || '';

async function goto(page, path = '') {
  await page.goto(`${BASE}${path}`);
  await waitForReady(page);
}

test.describe('Phase 13 — orientation spine (IA) seeded walkthrough', () => {
  test('Home shows seeded attention cards + populated trace stream at the bare URL', async ({
    page,
  }) => {
    await goto(page);

    // Attention cards render only from nonzero tenant-scoped counts. Their presence
    // at the bare URL proves the tenant default + seed are both working (the exact
    // regression the user hit, where Home showed the all-clear copy instead).
    const attention = page.locator('#home-attention');
    await expect(attention.getByText('Review approvals')).toBeVisible({ timeout: 15000 });
    await expect(attention).not.toContainText('Nothing needs attention');

    // Trace stream hydrated from seeded spans (vs the day-zero empty state).
    await expect(page.locator('#traces-empty')).toHaveCount(0, { timeout: 15000 });
    await expect(page.locator('#traces-list')).toBeVisible();
  });

  test('Incident ingress → Open run → return chip + run egress verbs', async ({ page }) => {
    await goto(page, '/incidents');

    // Select the seeded IA incident (linked to both a run and a trace). Phase 39
    // (D-07/D-10) routes incident selection through a real <a href> link to
    // /incidents/:id (incidents_live/show.ex) instead of an inline
    // phx-click="select_incident" panel-reveal — follow the link and wait for
    // the resulting navigation to settle before asserting the detail page.
    const incident = page
      .locator('a.scoria-selectable-card')
      .filter({ hasText: 'Refund tool returned an error' })
      .first();
    await expect(incident).toBeVisible({ timeout: 15000 });
    await incident.click();
    await waitForReady(page);

    // Ingress affordances (Test 9).
    const openRun = page.getByRole('link', { name: 'Open run', exact: true });
    await expect(openRun).toBeVisible();
    await expect(page.getByText('Open trace at failing span', { exact: true })).toBeVisible();

    // Follow Open run → destination run page (Test 7 + Test 11a).
    await openRun.click();
    await page.waitForURL(/\/workflows\/[a-f0-9-]+/);
    await waitForReady(page);

    // Return-context chip back to the origin incident (Test 7).
    await expect(page.locator('.scoria-object-header__origin')).toContainText('Back to incident');

    // Quality-loop egress verbs on the run page (Test 11a) — this run is the
    // seeded demo run, so all four are backed by real records. Role-agnostic:
    // "Promote in Dataset Builder" is a modal-opening button, the rest are links.
    for (const verb of ['Replay run', 'Promote in Dataset Builder', 'Open incident', 'Open prompt']) {
      await expect(page.getByText(verb, { exact: true }).first()).toBeVisible();
    }
  });

  test('Eval workbench → Open prompt release → prompt-release eval/baseline links', async ({
    page,
  }) => {
    await goto(page, '/eval_specs');

    // Eval result egress (Test 11d).
    const openPromptRelease = page
      .getByRole('link', { name: 'Open prompt release', exact: true })
      .first();
    await expect(openPromptRelease).toBeVisible({ timeout: 15000 });
    await expect(page.getByText('Open regressed runs', { exact: true }).first()).toBeVisible();

    // Follow into the release workbench → eval/baseline links (Test 11b).
    await openPromptRelease.click();
    await page.waitForURL(/\/prompts\/[a-f0-9-]+\/release/);
    await waitForReady(page);
    await expect(page.getByText('View eval results', { exact: true })).toBeVisible();
    await expect(page.getByText('View baseline runs', { exact: true })).toBeVisible();
  });

  test('Review queue ingress renders Open run + promote verb', async ({ page }) => {
    await goto(page, '/reviews');

    await expect(page.getByRole('link', { name: 'Open run', exact: true }).first()).toBeVisible({
      timeout: 15000,
    });
    await expect(page.getByText('Promote in Dataset Builder').first()).toBeVisible();
  });

  test('Replay run renders the provenance strip', async ({ page }) => {
    test.skip(
      REPLAY_RUN_ID === '',
      'SCORIA_E2E_REPLAY_RUN_ID not provided (run via `mix scoria.ui.e2e` against the seeded dev DB)'
    );

    await goto(page, `/workflows/${REPLAY_RUN_ID}`);

    // Replay provenance strip (Test 8) — only renders for execution_mode "replay".
    await expect(page.getByText('Replay branch').first()).toBeVisible({ timeout: 15000 });
    await expect(page.getByText('Replayed from run').first()).toBeVisible();
  });
});

// Phase 39 (component-groups-and-operator-flows) — automated flow proof
// replacing a manual UAT checkpoint per the project's shift-left preference
// (MEMORY: prefer ExUnit + `mix scoria.ui.e2e` over manual UAT). Covers the
// browser-only truths the D-05/D-11/D-26 source-scan guards and LiveViewTest
// suite cannot reach: real rendered DOM structure, drawer overlay behavior,
// and full navigation round-trips.
test.describe('Phase 39 — page-outline header (FLOW-01, D-05)', () => {
  // Every primary index/list page (page_header/1). Object/detail pages
  // (/workflows/:id, /incidents/:id, /prompts/:id/release) use object_header/1,
  // which renders no <h1> at all (D-03) — intentionally excluded here.
  const PRIMARY_PAGES = [
    '',
    '/incidents',
    '/connectors',
    '/datasets',
    '/eval_specs',
    '/reviews',
    '/approvals',
    '/workflows',
    '/prompts',
  ];

  for (const path of PRIMARY_PAGES) {
    test(`${path || '/'} shows exactly one page-outline header`, async ({ page }) => {
      await goto(page, path);
      await expect(page.locator('h1')).toHaveCount(1);
    });
  }
});

test.describe('Phase 39 — approval drawer decision-first (FLOW-03, D-12..D-16)', () => {
  test('drawer opens decision-first: decision + actions render together, no uppercase warn banner', async ({
    page,
  }) => {
    await goto(page, '/approvals');

    const trigger = page.getByRole('button', { name: 'Inspect approval' }).filter({ visible: true }).first();
    await expect(
      trigger,
      'expected a seeded pending approval in the inbox (mix scoria.ui.e2e tops up fixtures)'
    ).toBeVisible({ timeout: 15000 });
    await trigger.click();

    const drawer = page.locator('#approval-detail-drawer');
    await expect(drawer).toBeVisible();

    // Decision-first: the decision section (status + Approve/Deny) renders
    // right away, with actions immediately adjacent to the consequence copy —
    // not buried behind a details disclosure or a wall of evidence (D-16).
    const decision = drawer.locator('.scoria-approval-decision');
    await expect(decision).toBeVisible();
    await expect(decision.locator('[aria-label="Approval actions"] button')).toHaveCount(2);

    // D-13: the uppercase letter-spaced alarm banner class was deleted outright.
    await expect(page.locator('.scoria-approval-summary__label')).toHaveCount(0);
  });
});

test.describe('Phase 39 — Pending|Decided scope + decided receipt + deep-link (FLOW-04, D-09/D-17/D-19)', () => {
  test('Pending|Decided scope toggles via the URL', async ({ page }) => {
    await goto(page, '/approvals');
    await expect(page).not.toHaveURL(/scope=decided/);

    await page.getByRole('tab', { name: 'Decided', exact: true }).click();
    await expect(page).toHaveURL(/scope=decided/);
    await expect(page.getByRole('tab', { name: 'Decided', exact: true })).toHaveAttribute(
      'aria-selected',
      'true'
    );

    await page.getByRole('tab', { name: 'Pending', exact: true }).click();
    await expect(page).not.toHaveURL(/scope=decided/);
  });

  // Destructive: records a real approval decision to reach the Decided scope,
  // reusing the uat.spec.mjs top-up pattern (mix scoria.ui.e2e keeps ≥5 pending
  // approval fixtures topped up before this spec runs). Serial + no retries —
  // a retry would try to re-decide an approval that is no longer pending.
  test.describe('decided receipt + deep-link', () => {
    test.describe.configure({ mode: 'serial', retries: 0 });

    test('deciding a pending approval, then reopening it from Decided shows a read-only receipt with no decision buttons, and the ?approval=<id> deep-link reopens it directly', async ({
      page,
    }) => {
      await goto(page, '/approvals');

      const trigger = page.getByRole('button', { name: 'Inspect approval' }).filter({ visible: true }).first();
      await expect(
        trigger,
        'expected a seeded pending approval in the inbox (mix scoria.ui.e2e tops up fixtures)'
      ).toBeVisible({ timeout: 15000 });
      await trigger.click();

      const drawerApprove = page.locator(
        '#approval-detail-drawer button[phx-value-decision="approve"]'
      );
      await expect(drawerApprove).toBeVisible();
      await drawerApprove.click();
      await page.locator('button[phx-click="approve"]').click();

      // Wait for the toast confirming the write landed before navigating away,
      // so the audit event + inbox reload have settled.
      await expect(page.locator('#toast-region .scoria-toast')).toContainText(
        'Approval granted.'
      );

      await goto(page, '/approvals?scope=decided');
      const decidedRow = page.getByRole('button', { name: 'View decision' }).filter({ visible: true }).first();
      await expect(
        decidedRow,
        'expected the just-decided approval to appear in the Decided scope'
      ).toBeVisible({ timeout: 15000 });
      await decidedRow.click();

      // D-09: selection is a deep-linkable URL param, not a socket-only assign.
      await page.waitForURL(/[?&]approval=[a-f0-9-]+/);
      const approvalId = new URL(page.url()).searchParams.get('approval');
      expect(approvalId).toBeTruthy();

      const drawer = page.locator('#approval-detail-drawer');
      await expect(drawer).toBeVisible();

      // D-19/D-27 read-only receipt: no Approve/Deny buttons and no pending
      // action container render once an approval is decided.
      await expect(
        drawer.locator('button[phx-click="approve"], button[phx-click="reject"]')
      ).toHaveCount(0);
      await expect(drawer.locator('[aria-label="Approval actions"]')).toHaveCount(0);

      // Reload the bare deep-link URL directly (no click interaction) — the
      // drawer must reopen on its own, proving the selection survives
      // reconnect/direct navigation (D-09).
      await goto(page, `/approvals?scope=decided&approval=${approvalId}`);
      await expect(page.locator('#approval-detail-drawer')).toBeVisible();
      await expect(
        page
          .locator('#approval-detail-drawer')
          .locator('button[phx-click="approve"], button[phx-click="reject"]')
      ).toHaveCount(0);
    });
  });
});
