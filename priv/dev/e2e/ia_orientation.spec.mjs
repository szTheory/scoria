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

    // Select the seeded IA incident (linked to both a run and a trace).
    const incident = page
      .locator('button[phx-click="select_incident"]')
      .filter({ hasText: 'Refund tool returned an error' })
      .first();
    await expect(incident).toBeVisible({ timeout: 15000 });
    await incident.click();

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
