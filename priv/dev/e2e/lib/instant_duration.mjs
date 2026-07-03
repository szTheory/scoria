/**
 * priv/dev/e2e/lib/instant_duration.mjs — shared "effectively instant CSS
 * duration" predicate (Phase 40 D-19, factored out of phase16_parity.spec.mjs
 * where it was originally proven).
 *
 * The reduced-motion kill switch (assets/css/05-motion.css:71) forces
 * `animation-duration`/`transition-duration` to `0.001ms !important`. Chromium's
 * getComputedStyle serializes 0.001ms as the scientific-notation string
 * "1e-06s" rather than echoing the source literal — a naive `=== '0s'` string
 * comparison would false-pass on a BROKEN kill switch that left the real
 * duration untouched (e.g. a typo'd selector) as long as the property
 * happened to read some other falsy-looking value, and would false-FAIL on
 * the correct, tamed value Chromium actually reports (research
 * Don't-Hand-Roll; T-40-10 spoofing mitigation). Multi-property shorthand
 * values are comma-separated (e.g. two transitions on one element) — every
 * clause must independently collapse.
 *
 * Dev-only — never shipped to Hex (priv/dev is excluded from mix.exs
 * package.files).
 */

const INSTANT_DURATIONS = ['0s', '0.001ms', '1e-06s'];

/**
 * @param {string} value a raw `getComputedStyle(el).animationDuration` /
 *   `.transitionDuration` string, possibly comma-separated shorthand.
 * @returns {boolean} true only if EVERY comma-separated clause is one of the
 *   known "effectively instant" serializations.
 */
export function isInstantDuration(value) {
  return value
    .split(',')
    .every((d) => INSTANT_DURATIONS.includes(d.trim()));
}
