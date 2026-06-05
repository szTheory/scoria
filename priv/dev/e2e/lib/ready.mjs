/**
 * priv/dev/e2e/lib/ready.mjs — shared dashboard-readiness sentinel.
 *
 * Single source of the `data-scoria-ready="true"` gating contract used by BOTH
 * the screenshot harness (priv/dev/shots.mjs) and the e2e assertion specs
 * (priv/dev/e2e/*.spec.mjs). The attribute is set by phx:page-loading-stop in
 * assets/js/scoria.js. Dev-only — never shipped to Hex (priv/dev is excluded
 * from mix.exs package files).
 */

/**
 * Waits for data-scoria-ready="true" on <html>.
 * Throws with the missing-sentinel error copy on timeout.
 *
 * Default 15s (not 5s): the FIRST LiveView connect on a cold CI dev server
 * (fresh BEAM, first WS handshake + asset eval) routinely exceeds 5s, which
 * flaked the first spec in the serial toast block. Warm loads resolve in well
 * under a second; the generous ceiling only affects the cold first navigation.
 */
export async function waitForReady(page, timeoutMs = 15000) {
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
