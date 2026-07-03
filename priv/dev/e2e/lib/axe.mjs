/**
 * priv/dev/e2e/lib/axe.mjs — shared axe-core scan configuration (D-06/D-17).
 *
 * Single source of the axe run configuration used by EVERY axe scan this
 * phase (full-lab report-only baseline AND the curated real-page
 * assert-zero allow-list, Open Question #2 in 40-RESEARCH.md). Centralizing
 * this prevents the tag list or the `target-size` rule override from
 * drifting between the two call sites.
 *
 * Dev-only — never shipped to Hex (priv/dev is excluded from mix.exs
 * package.files).
 */

import AxeBuilder from '@axe-core/playwright';

/**
 * The five locked WCAG tags (D-06). Deliberately EXCLUDES `best-practice` —
 * it pulls in non-AA opinions and the classic axe lab false-positives
 * (`region`, `heading-order`, `landmark-one-main`; see 40-RESEARCH.md
 * Pitfall 5 for why `duplicate-id` is excluded for a different reason).
 */
export const WCAG_TAGS = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'];

/**
 * axe-core 4.12.1 ships `target-size` (SC 2.5.8) with `enabled: false` by
 * default — the tag list alone does NOT re-enable a rule whose static
 * definition is disabled (40-RESEARCH.md Pitfall 1). Without this explicit
 * override, D-06's target-size clause is a silent no-op forever. Kept
 * report-only by every caller (D-06) — this only makes the rule RUN, it
 * does not assert on its results.
 */
const RULE_OVERRIDES = {
  'target-size': { enabled: true },
};

/**
 * Builds an AxeBuilder scan against `page` using the fixed Phase 40 config.
 *
 * IMPORTANT: `.options()` performs a wholesale replace of AxeBuilder's
 * internal option object, while `.withTags()` merges `runOnly` onto whatever
 * is already there — so `.options()` MUST be called before `.withTags()`, or
 * the tag filter is silently dropped. This ordering is deliberate; do not
 * reorder these two calls in any caller (there is only one caller: this
 * function).
 *
 * @param {import('@playwright/test').Page} page
 * @returns {AxeBuilder}
 */
export function buildAxeScan(page) {
  return new AxeBuilder({ page }).options({ rules: RULE_OVERRIDES }).withTags(WCAG_TAGS);
}

/**
 * Convenience wrapper: builds the scan and runs `.analyze()`.
 *
 * @param {import('@playwright/test').Page} page
 * @returns {Promise<import('axe-core').AxeResults>}
 */
export async function runAxeScan(page) {
  return buildAxeScan(page).analyze();
}
