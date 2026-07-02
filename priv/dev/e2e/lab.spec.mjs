// priv/dev/e2e/lab.spec.mjs
//
// Phase 37 browser-truth proof for the dev-only Component Lab (D-33/LAB-02).
// Covers: route load + the D-07 IA nav rail, theme coverage (data-theme on
// .scoria-root), the Foundations "Reduced motion" signal, a six-width
// (D-13) viewport scan of the lab shell, the Overlays IA section's
// drawer/modal focus + inert-dismiss probe (RISK-OVERLAY-FOCUS), the dense
// approvals table stacked with a toast overlay (RISK-TOAST-LEGIBILITY
// stress fixture only — the fix stays Phase 38 scope), and the raw-evidence
// "Copy fixture payload" control.
//
// Lane: auto-discovered by `mix scoria.ui.e2e` via testMatch '**/*.spec.mjs'
// (playwright.config.mjs) — this file is picked up by the REQUIRED e2e CI
// gate the moment it lands (37-RESEARCH.md Pitfall 2). Every assertion below
// reflects what dev/lab/lab_live.ex and dev/lab/sections/*.ex (Plans 01-05)
// actually ship; nothing here is aspirational.
//
// No fixed sleeps: rely on waitForReady + expect auto-wait (retries: 2 in CI).

import { test, expect } from '@playwright/test';
import { waitForReady } from './lib/ready.mjs';

const DASHBOARD_BASE = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:4799/scoria';
const LAB_BASE = `${DASHBOARD_BASE}/_lab`;

// D-07 IA — exact order and exact labels (dev/lab/lab_live.ex @sections).
// This is the same source-of-truth list both the nav rail and the route
// allowlist derive from (37-05-SUMMARY.md "Pattern: single-source IA list").
const SECTIONS = ['Foundations', 'Primitives', 'Groups', 'States', 'Viewports', 'Overlays', 'Fixtures'];

// D-13 proof-target widths (dev/lab/sections/viewports.ex @widths) — the
// same six widths that section renders as simulator frames; here they drive
// the REAL browser viewport against the lab shell itself (the manual/visual
// simulator frames are the complement this Playwright scan already targets
// per that module's own moduledoc).
const VIEWPORT_WIDTHS = [320, 375, 768, 1024, 1440, 1920];

// ────────────────────────────────────────────────────────────────────────────
// Route load + D-07 IA nav + D-27 copy
// ────────────────────────────────────────────────────────────────────────────

test.describe('Component Lab — route load and D-07 IA nav', () => {
  test('loads /scoria/_lab and shows all seven D-07 nav sections in order', async ({ page }) => {
    await page.goto(LAB_BASE);
    await waitForReady(page);

    await expect(page.locator('.scoria-lab-shell')).toBeVisible();

    const navItems = page.locator('.scoria-lab-nav__item');
    await expect(navItems).toHaveCount(SECTIONS.length);
    const labels = (await navItems.allTextContents()).map((label) => label.trim());
    expect(labels).toEqual(SECTIONS);
  });

  test('D-27 page title, subtitle, and header commands render with the right destinations', async ({
    page,
  }) => {
    await page.goto(LAB_BASE);
    await waitForReady(page);

    await expect(page.getByRole('heading', { name: 'Component Lab', exact: true })).toBeVisible();
    await expect(
      page.getByText(
        'Inspect Scoria primitives, groups, fixtures, themes, and stress states before changing shared UI.'
      )
    ).toBeVisible();

    // Both header commands are patch links (37-05 Decision: <.link patch=...>
    // styled as scoria-button, not <.button>) — assert the D-27 exact labels
    // and their Plan 05 destinations.
    await expect(page.getByRole('link', { name: 'Run lab proof' })).toHaveAttribute(
      'href',
      '/scoria/_lab/states'
    );
    await expect(page.getByRole('link', { name: 'Open fixture matrix' })).toHaveAttribute(
      'href',
      '/scoria/_lab/fixtures'
    );
  });
});

// ────────────────────────────────────────────────────────────────────────────
// Theme coverage (D-14)
//
// DevLab.LabLive mounts with `layout: {ScoriaWeb.Layouts, :root}` directly
// (37-05) — there is no app-shell topbar on this route, so there is no
// #scoria-theme-toggle control to click here (that control lives only in
// app.html.heex, the operator dashboard shell wrapping scoria_dashboard/2
// pages). Theme coverage instead proves the actual shared mechanism every
// /scoria/_lab page depends on: root.html.heex's pre-paint script resolves
// the persisted "scoria-theme" localStorage key — the SAME key the real
// ThemeToggle hook writes on click — into data-theme on <html
// class="scoria-root"> before first paint. This is real, shipped,
// browser-observable behavior, not a fabricated toggle affordance.
// ────────────────────────────────────────────────────────────────────────────

test.describe('Component Lab — theme coverage (D-14)', () => {
  test('explicit light/dark theme mode resolves to data-theme on .scoria-root', async ({ page }) => {
    await page.goto(LAB_BASE);
    await waitForReady(page);

    await page.evaluate(() => localStorage.setItem('scoria-theme', 'light'));
    await page.reload();
    await waitForReady(page);
    await expect(page.locator('html.scoria-root')).toHaveAttribute('data-theme', 'light');

    await page.evaluate(() => localStorage.setItem('scoria-theme', 'dark'));
    await page.reload();
    await waitForReady(page);
    await expect(page.locator('html.scoria-root')).toHaveAttribute('data-theme', 'dark');
  });

  test('"system" theme mode follows prefers-color-scheme on .scoria-root', async ({ page }) => {
    await page.goto(LAB_BASE);
    await waitForReady(page);
    await page.evaluate(() => localStorage.setItem('scoria-theme', 'system'));

    await page.emulateMedia({ colorScheme: 'light' });
    await page.reload();
    await waitForReady(page);
    await expect(page.locator('html.scoria-root')).toHaveAttribute('data-theme', 'light');

    await page.emulateMedia({ colorScheme: 'dark' });
    await page.reload();
    await waitForReady(page);
    await expect(page.locator('html.scoria-root')).toHaveAttribute('data-theme', 'dark');
  });
});

// ────────────────────────────────────────────────────────────────────────────
// Reduced motion (D-14, Foundations "Reduced motion" signal)
// ────────────────────────────────────────────────────────────────────────────

test.describe('Component Lab — reduced motion (D-14, Foundations)', () => {
  test('prefers-reduced-motion: reduce flips the Foundations "Reduced motion" signal on', async ({
    page,
  }) => {
    // Emulate before navigation so the media query is active when the
    // page's CSS is evaluated for the first time (phase16_parity pattern).
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.goto(`${LAB_BASE}/foundations`);
    await waitForReady(page);

    const signal = page.locator('[data-lab-motion-signal="true"]');
    await expect(signal).toBeVisible();
    await expect(signal.locator('.scoria-lab-motion-on')).toBeVisible();
    await expect(signal.locator('.scoria-lab-motion-off')).toBeHidden();
  });

  test('no reduced-motion preference leaves the "Reduced motion" signal in its off state', async ({
    page,
  }) => {
    await page.goto(`${LAB_BASE}/foundations`);
    await waitForReady(page);

    const signal = page.locator('[data-lab-motion-signal="true"]');
    await expect(signal.locator('.scoria-lab-motion-off')).toBeVisible();
    await expect(signal.locator('.scoria-lab-motion-on')).toBeHidden();
  });
});

// ────────────────────────────────────────────────────────────────────────────
// Six-width viewport scan of the lab shell (D-13, RISK-RESPONSIVE-SCAN)
// ────────────────────────────────────────────────────────────────────────────

test.describe('Component Lab — six-width viewport scan of the lab shell (D-13)', () => {
  for (const width of VIEWPORT_WIDTHS) {
    test(`lab shell renders with no page-level horizontal overflow at ${width}px`, async ({
      page,
    }) => {
      await page.setViewportSize({ width, height: 900 });
      await page.goto(LAB_BASE);
      await waitForReady(page);

      await expect(page.locator('.scoria-lab-shell')).toBeVisible();

      const overflow = await page.evaluate(
        () => document.documentElement.scrollWidth > window.innerWidth
      );
      expect(overflow, `lab shell overflows the page at ${width}px`).toBe(false);
    });
  }
});

// ────────────────────────────────────────────────────────────────────────────
// Overlays IA: focus + inert-dismiss probe (D-10 probe 3, RISK-OVERLAY-FOCUS)
// ────────────────────────────────────────────────────────────────────────────

test.describe('Component Lab — Overlays IA: drawer/modal focus + dismiss probe', () => {
  test('drawer and modal specimens render genuinely open (show=true, no click needed)', async ({
    page,
  }) => {
    await page.goto(`${LAB_BASE}/overlays`);
    await waitForReady(page);

    await expect(page.locator('#lab-overlay-drawer .scoria-drawer')).toBeVisible();
    await expect(page.locator('#lab-overlay-modal .scoria-modal__panel')).toBeVisible();
  });

  test('modal close button receives autofocus on load', async ({ page }) => {
    await page.goto(`${LAB_BASE}/overlays`);
    await waitForReady(page);

    // <.modal>'s close <.icon_button> carries the native `autofocus` attribute
    // (lib/scoria_web/ui.ex) — the drawer's close button does not, so this is
    // deterministic across both specimens being present on the same page.
    const closeButton = page.locator('#lab-overlay-modal [aria-label="Close dialog"]');
    await expect(closeButton).toBeFocused();
  });

  test('dismiss click routes through the shared lab-noop-dismiss handler without crashing the LiveView', async ({
    page,
  }) => {
    await page.goto(`${LAB_BASE}/overlays`);
    await waitForReady(page);

    // dev/lab/lab_live.ex's `handle_event("lab-noop-dismiss", ...)` clause is
    // an intentional no-op (37-05-SUMMARY.md): the drawer/modal specimens
    // stay open by design (show=true is a hardcoded literal, not a toggled
    // assign) so every one of the ten D-11 state rows elsewhere in the lab
    // stays inspectable rather than being replaced by a closed overlay.
    // Without this handler clause the event would have no matching clause
    // and the LiveView process would crash (37-05/37-02/37-04 all flagged
    // this risk). Assert BOTH survive: the specimen stays visible AND the
    // page remains ready for further interaction — this is the real, shipped
    // behavior; a "the overlay closes" assertion would be false.
    //
    // Target the MODAL's close button, not the drawer's: with both
    // specimens genuinely open simultaneously, the modal's full-viewport
    // `.scoria-scrim` renders after (visually on top of) the drawer and
    // intercepts pointer events over it — a real consequence of stacking two
    // always-open D-10 overlay specimens on one page, not a bug in either
    // component's own dismiss contract. The modal's own close button sits
    // above its own scrim and is genuinely clickable.
    await page.locator('#lab-overlay-modal [aria-label="Close dialog"]').click();

    await waitForReady(page);
    await expect(page.locator('#lab-overlay-modal .scoria-modal__panel')).toBeVisible();
  });
});

// ────────────────────────────────────────────────────────────────────────────
// Dense table + toast-over-dense-UI (RISK-TOAST-LEGIBILITY stress fixture —
// surfaced here, NOT fixed; the fix is Phase 38 scope)
// ────────────────────────────────────────────────────────────────────────────

test.describe('Component Lab — dense approvals table + toast-over-dense-UI stress fixture', () => {
  test('the dense approvals table and the stacked toast region both render', async ({ page }) => {
    await page.goto(`${LAB_BASE}/overlays`);
    await waitForReady(page);

    // Scoped to the "Dense approvals with a toast overlay" stage
    // (.scoria-lab-overlay-stage) — the Overlays section also renders a
    // SECOND ApprovalInboxComponent instance lower on the page (the mobile
    // summary probe) that shares the same internal `id="approvals"` table id
    // (a known, out-of-scope limitation documented in 37-03-SUMMARY.md), so
    // class-scoping here — not #approvals — is what keeps this deterministic.
    const stage = page.locator('.scoria-lab-overlay-stage');
    await expect(stage.locator('table.scoria-table tbody tr')).toHaveCount(8);

    // Toasts auto-dismiss after their default 4000ms duration
    // (ScoriaWeb.UI.toast/1 duration_ms) — assert immediately after load,
    // well inside that window, with no intervening wait.
    const toastRegion = stage.locator('#lab-toast-region');
    await expect(toastRegion).toBeVisible();
    await expect(toastRegion.locator('.scoria-toast')).toHaveCount(2);
  });
});

// ────────────────────────────────────────────────────────────────────────────
// Copy control (raw_evidence "Copy fixture payload")
// ────────────────────────────────────────────────────────────────────────────

test.describe('Component Lab — "Copy fixture payload" copy control', () => {
  test('the copy control is present, clickable, and reflects a real click outcome', async ({
    page,
  }) => {
    // The Fixtures section (dev/lab/sections/fixtures_view.ex) also renders a
    // raw_evidence copyable="Copy fixture payload" control per scenario, with
    // no always-open drawer/modal specimen on the page — unlike Overlays,
    // where the always-open <.modal> (probes 3/6/7 share a page) legitimately
    // covers the full viewport with its scrim (real modal behavior, D-10's
    // deliberate "stays inspectable" tradeoff), making every OTHER control on
    // that page unreachable by a real pointer click for as long as it is
    // open. Fixtures is the deterministic, unblocked place to prove this
    // control.
    await page.goto(`${LAB_BASE}/fixtures`);
    await waitForReady(page);

    const copyButton = page.locator('[data-raw-evidence-copy]').first();

    // <.raw_evidence open={false}> renders a native <details>/<summary> —
    // the copy button lives inside the collapsed <details> body, so it is
    // genuinely hidden (per the browser's own details/summary behavior, not
    // a bug) until a maintainer expands the disclosure. Click the enclosing
    // <summary> first, matching real usage.
    await copyButton
      .locator('xpath=ancestor::details[1]')
      .locator('summary.scoria-raw-evidence__summary')
      .click();

    await expect(copyButton).toBeVisible();
    await copyButton.click();

    // assets/js/scoria.js's document-level click handler always toggles the
    // button's title/aria-label to either "Copied" (navigator.clipboard
    // available and write succeeded) or "Copy unavailable" (no Clipboard API
    // / permission in this browser context — common in headless CI). Both are
    // real, shipped outcomes of the same handler; asserting a bare "Copied"
    // would be flaky wherever clipboard-write permission is denied.
    await expect(copyButton).toHaveAttribute('title', /^(Copied|Copy unavailable)$/);
  });
});
