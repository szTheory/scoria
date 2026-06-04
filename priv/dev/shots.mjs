/**
 * priv/dev/shots.mjs — Scoria dashboard screenshot capture script
 *
 * Playwright state-matrix harness. Captures every dashboard screen across the
 * combination of data presence, theme, and viewport. Gated on data-scoria-ready.
 *
 * Usage (via mix scoria.ui.shots — do NOT invoke directly in most cases):
 *   node priv/dev/shots.mjs --base-url http://localhost:4000/scoria \
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

// ---------------------------------------------------------------------------
// Arg parsing
// ---------------------------------------------------------------------------

function parseArgs(argv) {
  const args = argv.slice(2);
  const result = {
    baseUrl: 'http://localhost:4000/scoria',
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
// Sentinel gating
// ---------------------------------------------------------------------------

/**
 * Waits for data-scoria-ready="true" on <html>.
 * Set by phx:page-loading-stop in assets/js/scoria.js line 84.
 * Throws with the UI-SPEC missing-sentinel error copy on timeout.
 */
async function waitForReady(page, timeoutMs = 5000) {
  try {
    await page.waitForFunction(
      () => document.documentElement.getAttribute('data-scoria-ready') === 'true',
      { timeout: timeoutMs }
    );
  } catch {
    throw new Error(
      `Error: data-scoria-ready not set on <html> after ${timeoutMs}ms. Is the dev server running?`
    );
  }
}

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
        // Click the first visible button with phx-click="select_approval" (idiomatic Playwright)
        // Seeded pending approval supplies a real id via phx-value-id attribute on the button
        selector: 'button[phx-click="select_approval"]',
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
];

// ---------------------------------------------------------------------------
// Viewport configurations
// ---------------------------------------------------------------------------

const VIEWPORTS = [
  { name: 'desktop', width: 1280, height: 900 },
  { name: 'mobile', width: 375, height: 812 },
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
      await setTheme(page, theme);
      for (const vp of VIEWPORTS) {
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
