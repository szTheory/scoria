/**
 * priv/dev/shots.mjs — Scoria dashboard screenshot capture script
 *
 * Playwright state-matrix harness. Captures every dashboard screen across the
 * combination of data presence, theme, and viewport. Gated on data-scoria-ready.
 *
 * Usage (via mix scoria.ui.shots — do NOT invoke directly in most cases):
 *   node priv/dev/shots.mjs --base-url http://localhost:4799/scoria \
 *     --tenant-empty empty-tenant --tenant-seeded acme-corp \
 *     --out-dir priv/shots/2026-06-04 [--release-id <uuid>]
 *
 * Prerequisites:
 *   npm install -g playwright && npx playwright install chromium
 */

import { chromium } from 'playwright';
import { mkdir } from 'fs/promises';
import { existsSync } from 'fs';
import { join } from 'path';
import { waitForReady } from './e2e/lib/ready.mjs';

// ---------------------------------------------------------------------------
// Arg parsing
// ---------------------------------------------------------------------------

function parseArgs(argv) {
  const args = argv.slice(2);
  const result = {
    baseUrl: 'http://localhost:4799/scoria',
    tenantEmpty: 'empty-tenant',
    tenantSeeded: 'acme-corp',
    outDir: null,
    releaseId: null,
  };

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--base-url':
        result.baseUrl = args[++i];
        break;
      case '--tenant-empty':
        result.tenantEmpty = args[++i];
        break;
      case '--tenant-seeded':
        result.tenantSeeded = args[++i];
        break;
      case '--out-dir':
        result.outDir = args[++i];
        break;
      case '--release-id':
        result.releaseId = args[++i];
        break;
      default:
        console.error(`Unknown argument: ${args[i]}`);
        process.exit(1);
    }
  }

  if (!result.outDir) {
    console.error('Error: --out-dir is required');
    process.exit(1);
  }

  return result;
}

// ---------------------------------------------------------------------------
// Sentinel gating — shared single source with the e2e lane (priv/dev/e2e/lib/ready.mjs).
// waitForReady() blocks until data-scoria-ready="true" is set on <html> by
// phx:page-loading-stop in assets/js/scoria.js.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Theme toggle (CSS-only — no sentinel re-wait needed per RESEARCH Pitfall 1)
// ---------------------------------------------------------------------------

async function setTheme(page, theme) {
  await page.evaluate((t) => {
    document.documentElement.setAttribute('data-theme', t);
  }, theme);
  // CSS-only change — no LiveView round-trip. Brief repaint wait.
  await page.waitForTimeout(100);
}

// ---------------------------------------------------------------------------
// Hardcoded screen manifest
// per <interfaces> block and RESEARCH §"Overlay Capture: Per-Screen Event Inventory"
// ---------------------------------------------------------------------------

const SCREENS = [
  {
    name: 'live_ops',
    path: '/',
    tenantScoped: true,
    overlays: [],
  },
  {
    name: 'approvals',
    path: '/approvals',
    tenantScoped: true,
    overlays: [
      {
        state: 'modal',
        // The inbox row trigger is an <article phx-click="select_approval">, not a
        // <button> — match any element so the overlay click resolves. (The inbox also
        // auto-seeds the first pending approval into the modal on mount, so the base
        // populated screenshot already shows this state.)
        selector: '[phx-click="select_approval"]',
      },
    ],
  },
  {
    name: 'workflows',
    path: '/workflows',
    tenantScoped: false,
    overlays: [],
  },
  {
    name: 'incidents',
    path: '/incidents',
    tenantScoped: true,
    overlays: [],
  },
  {
    name: 'connectors',
    path: '/connectors',
    tenantScoped: true,
    overlays: [
      {
        state: 'connector_drawer',
        selector: 'button[phx-click="open_connector_drawer"]',
      },
      {
        state: 'runtime_drawer',
        selector: 'button[phx-click="open_runtime_drawer"]',
      },
    ],
  },
  {
    name: 'reviews',
    path: '/reviews',
    tenantScoped: false,
    overlays: [],
  },
  {
    name: 'eval_specs',
    path: '/eval_specs',
    tenantScoped: false,
    overlays: [],
  },
  {
    name: 'prompts',
    path: '/prompts',
    tenantScoped: false,
    overlays: [],
  },
  {
    name: 'prompt_release',
    // Navigation handled specially below (follow first release link or use --release-id)
    path: '/prompts',
    tenantScoped: false,
    overlays: [
      {
        state: 'approve_modal',
        // open_approve has no payload — click the button directly
        selector: 'button[phx-click="open_approve"]',
      },
    ],
  },
  {
    // Phase 41 D-14/D-15: the real RISK-TOAST-LEGIBILITY static toast fixture
    // lives at dev/lab/sections/overlays.ex:91-94 (NOT states.ex, which is
    // badges only). freshMountPerCapture beats toast/1's default 4000ms
    // phx-mounted auto-hide (lib/scoria_web/ui.ex) by re-navigating before
    // every theme×viewport capture below, so each shot lands inside a fresh
    // window instead of racing a timer that started at the top of the loop.
    name: 'lab_overlays',
    path: '/_lab/overlays',
    tenantScoped: false,
    overlays: [],
    freshMountPerCapture: true,
  },
];

// ---------------------------------------------------------------------------
// Viewport configurations
// ---------------------------------------------------------------------------

// Phase 40 D-14: widened from the original 2 entries (desktop/mobile) to the
// same 6-width RESP-01 responsive_scan.spec.mjs asserts against
// (VIEWPORT_WIDTHS, priv/dev/e2e/lab.spec.mjs) — screenshots are human
// evidence only, never a gate (D-14), but they should cover the identical
// widths the e2e assertions prove so a maintainer eyeballing the contact
// sheet sees the same breakpoints the harness already checked. Heights are
// representative-device values per width, not asserted against.
const VIEWPORTS = [
  { name: 'w320', width: 320, height: 812 },
  { name: 'w375', width: 375, height: 812 },
  { name: 'w768', width: 768, height: 1024 },
  { name: 'w1024', width: 1024, height: 900 },
  { name: 'w1440', width: 1440, height: 900 },
  { name: 'w1920', width: 1920, height: 1080 },
];

const THEMES = ['dark', 'light'];

// ---------------------------------------------------------------------------
// Main capture loop
// ---------------------------------------------------------------------------

async function captureScreen(page, screen, args) {
  const { baseUrl, tenantEmpty, tenantSeeded, outDir } = args;
  const screenDir = join(outDir, screen.name);
  await mkdir(screenDir, { recursive: true });

  // Determine data-presence states to capture
  const presences = screen.tenantScoped
    ? ['empty', 'populated']
    : ['populated'];

  for (const presence of presences) {
    const tenant = presence === 'empty' ? tenantEmpty : tenantSeeded;

    // Build URL with tenant query param
    let screenPath = screen.path;
    if (screen.name === 'prompt_release') {
      // prompt_release handled separately below
      screenPath = screen.path;
    }

    const separator = screenPath.includes('?') ? '&' : '?';
    const url = screen.tenantScoped
      ? `${baseUrl}${screenPath}${separator}tenant=${tenant}`
      : `${baseUrl}${screenPath}`;

    console.log(`  → ${screen.name} (${presence})`);

    // Navigate to screen
    await page.goto(url);
    await waitForReady(page);

    // For prompt_release (populated only): navigate to the release workbench
    let onReleasePage = false;
    if (screen.name === 'prompt_release' && presence === 'populated') {
      onReleasePage = await navigateToRelease(page, args, baseUrl);
    }

    // Capture baseline across theme × viewport
    for (const theme of THEMES) {
      if (!screen.freshMountPerCapture) {
        await setTheme(page, theme);
      }
      for (const vp of VIEWPORTS) {
        if (screen.freshMountPerCapture) {
          // D-15: re-navigate before EVERY capture (not just once per screen)
          // so a transient toast's phx-mounted auto-hide timer (default
          // 4000ms — see toast/1 in lib/scoria_web/ui.ex) resets to "now" for
          // each shot. Without this, later theme×viewport combinations in
          // this loop would race the timer started at the top of the screen
          // and could land on an already-hidden toast. Do NOT assert exact
          // timing — re-navigating resets the clock instead of racing it.
          await page.goto(url);
          await waitForReady(page);
          await setTheme(page, theme);
          // Pitfall 4 sanity check: warn (do not fail) if the toast isn't in
          // the DOM, surfacing a silent-empty-shot flake during authoring
          // instead of shipping an unnoticed empty capture.
          const toastCount = await page.locator('.scoria-toast').count();
          if (toastCount === 0) {
            console.log(`  ! WARNING: ${screen.name} (${presence}) ${theme}/${vp.name}: no .scoria-toast found in DOM — capture may be empty`);
          }
        }
        await page.setViewportSize({ width: vp.width, height: vp.height });
        const filename = `${presence}_${theme}_${vp.name}`;
        const filepath = join(screenDir, `${filename}.png`);
        await page.screenshot({ path: filepath, fullPage: false });
        console.log(`  ✓ ${filename}.png`);
      }
    }

    // Capture overlay states (populated state only — empty has no records to open)
    if (presence === 'populated' && screen.overlays.length > 0) {
      for (const overlay of screen.overlays) {
        // Re-navigate + re-await sentinel before each overlay (overlays may close between captures)
        if (!onReleasePage || overlay !== screen.overlays[0]) {
          // Re-navigate to reset state for subsequent overlays
          if (screen.name === 'prompt_release') {
            await page.goto(url);
            await waitForReady(page);
            onReleasePage = await navigateToRelease(page, args, baseUrl);
          } else {
            const navUrl = screen.tenantScoped
              ? `${baseUrl}${screenPath}${separator}tenant=${tenant}`
              : `${baseUrl}${screenPath}`;
            await page.goto(navUrl);
            await waitForReady(page);
          }
        }

        console.log(`  → ${screen.name} (${overlay.state})`);

        // Click the overlay trigger using Playwright idiomatic click
        // The first matching selector in the rendered list supplies a real seeded record id
        const triggerEl = await page.$(overlay.selector);
        if (!triggerEl) {
          console.log(`  ! ${overlay.state}: selector "${overlay.selector}" not found — skipping overlay`);
          continue;
        }

        await triggerEl.click();
        // Re-await sentinel after overlay opens (assigns-driven overlay triggers a LiveView diff)
        await waitForReady(page);

        // Capture overlay across theme × viewport
        for (const theme of THEMES) {
          await setTheme(page, theme);
          for (const vp of VIEWPORTS) {
            await page.setViewportSize({ width: vp.width, height: vp.height });
            const filename = `${overlay.state}_${theme}_${vp.name}`;
            const filepath = join(screenDir, `${filename}.png`);
            await page.screenshot({ path: filepath, fullPage: false });
            console.log(`  ✓ ${filename}.png`);
          }
        }
      }
    }
  }
}

/**
 * Navigates from the prompts list to the release workbench.
 * Uses --release-id if provided, otherwise follows the first release link.
 * Returns true if navigation succeeded.
 */
async function navigateToRelease(page, args, baseUrl) {
  const { releaseId } = args;

  if (releaseId) {
    await page.goto(`${baseUrl}/prompts/${releaseId}/release`);
    await waitForReady(page);
    return true;
  }

  // Follow the first release link on the prompts list page
  const releaseLink = await page.$('a[href*="/release"]');
  if (!releaseLink) {
    console.log('  ! prompt_release: no release link found on /prompts — skipping prompt_release screen');
    return false;
  }

  await releaseLink.click();
  await waitForReady(page);
  return true;
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

const args = parseArgs(process.argv);

let browser;
try {
  browser = await chromium.launch();
} catch (e) {
  console.error(
    'Error: Playwright/Chromium not installed.\n' +
    'Run: npm install -g playwright && npx playwright install chromium'
  );
  process.exit(1);
}

try {
  const context = await browser.newContext();
  const page = await context.newPage();

  for (const screen of SCREENS) {
    await captureScreen(page, screen, args);
  }
} finally {
  await browser.close();
}
