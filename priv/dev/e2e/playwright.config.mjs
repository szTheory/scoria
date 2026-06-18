// priv/dev/e2e/playwright.config.mjs
//
// Playwright @playwright/test config for the Scoria dashboard e2e assertion lane.
// Dev-only — never shipped to Hex (priv/dev is excluded from mix.exs package files).
//
// Run via `mix scoria.ui.e2e` (which shells out to `npx playwright test` from
// priv/dev). The dev dashboard must already be serving via make dev with seed
// data applied. Base URL is taken from PLAYWRIGHT_BASE_URL.

import { defineConfig, devices } from '@playwright/test';

const baseURL = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:4799/scoria';

export default defineConfig({
  // testDir is '.' so spec files live alongside this config (priv/dev/e2e/*.spec.mjs).
  testDir: '.',
  testMatch: '**/*.spec.mjs',
  // CI is the only place a flake can block a merge; retry there, fail fast locally.
  retries: process.env.CI ? 2 : 0,
  // No fixed sleeps in specs — rely on expect auto-wait + the readiness sentinel.
  use: {
    baseURL,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  reporter: [['list'], ['html', { outputFolder: 'playwright-report', open: 'never' }]],
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
});
