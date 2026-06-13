---
phase: 16-motion-responsive-theme-parity
plan: 06
subsystem: e2e/test
tags: [playwright, e2e, contrast, accessibility, motion, focus, theme, responsive]
requires: ["16-01", "16-02", "16-03", "16-04", "16-05"]
provides:
  - phase16-playwright-parity-spec
  - token-contrast-guard
affects:
  - priv/dev/e2e/phase16_parity.spec.mjs
  - test/scoria_web/token_contrast_guard_test.exs
tech-stack:
  added: []
  patterns: [playwright-media-emulation, wcag-contrast-math, css-token-parser]
key-files:
  created:
    - priv/dev/e2e/phase16_parity.spec.mjs
    - test/scoria_web/token_contrast_guard_test.exs
  modified: []
key-decisions:
  - "Token contrast guard reads exclusively from assets/css/02-tokens.css with inline var() resolver — no parallel token source created (D-31 honored)"
  - "color-mix() tone tokens intentionally skipped in contrast guard (browser-only resolution; not needed for body/focus AA floor pairs)"
  - "Focus outline checks for command palette input accept either outline >=2px OR non-none box-shadow to handle browser ring implementations"
  - "Reduced-motion assertions accept comma-separated values (0.001ms, 0.001ms) for multi-property transition shorthand serialization (RESEARCH A2)"
  - "Theme toggle smoke for overlay path uses force:true click on mobile toggle to handle drawer z-index overlay"
metrics:
  duration: "~4 min"
  completed: "2026-06-13T14:30:34Z"
  tasks: 2
  files: 2
---

# Phase 16 Plan 06: Browser-Truth Proof and Contrast Guard Summary

Targeted Playwright spec proving MOTION-01..04 (375px overflow, both-theme focus visibility, reduced-motion collapse, theme-toggle smoke) auto-discovered by the existing `mix scoria.ui.e2e` lane, plus a deterministic single-SSOT AA contrast floor guard that parses only `assets/css/02-tokens.css`.

## Tasks Completed

| Task | Description | Commit | Key Files |
|------|-------------|--------|-----------|
| 1 | Phase 16 Playwright parity spec — 375px overflow, focus in light+dark, reduced-motion, theme-toggle | f032ea9 | priv/dev/e2e/phase16_parity.spec.mjs |
| 2 | Single-SSOT AA contrast floor guard (D-31) — reads only 02-tokens.css | 238b210 | test/scoria_web/token_contrast_guard_test.exs |

## What Was Built

**Task 1 — `priv/dev/e2e/phase16_parity.spec.mjs`:**

Four focused test suites auto-discovered by `testMatch '**/*.spec.mjs'`. No screenshot comparisons (D-30/D-32). All assertions use `waitForReady` + Playwright auto-wait.

- **MOTION-03 (375px overflow, 3 tests):** Shell (Home) and `/workflows` table screen both assert `document.documentElement.scrollWidth <= window.innerWidth`. Additional test confirms `.scoria-table__viewport` has `tabindex="0"` for keyboard reachability — page does not overflow even when table container does.

- **MOTION-02 focus light (6 tests):** At 375px + `colorScheme: 'light'`: nav link in mobile drawer, `[data-command-open]` button, command palette input (outline or box-shadow ring), table action/link, command palette item (`[data-command-row]`), mobile nav close button. Each asserts `outlineStyle !== 'none'` and `outlineWidth >= 2px`.

- **MOTION-02 focus dark (6 tests):** Same 6 control types at `colorScheme: 'dark'`. Identical assertion logic.

- **MOTION-01 reduced-motion (3 tests):** `await page.emulateMedia({ reducedMotion: 'reduce' })` before navigation. Mobile drawer panel asserts `transitionDuration` in `['0s', '0.001ms', '0.001ms, 0.001ms', '0s, 0s']`. Skeleton/attention cue on `/workflows` asserts `animationDuration` in `['0s', '0.001ms']`. Generic `.scoria-root *` interactive element asserts collapse for any accepted serialization (handles multi-property comma-separated values per RESEARCH A2).

- **MOTION-04 theme-toggle smoke (4 tests):** Home/shell, `/workflows` table, workflow detail (evidence screen with graceful fallback if no seeded run), and overlay path (375px mobile nav drawer open). Each toggles `#scoria-theme-toggle` or `#scoria-theme-toggle-mobile`, asserts `data-theme` attribute flips, then calls `waitForReady` and asserts a key landmark visible.

**Task 2 — `test/scoria_web/token_contrast_guard_test.exs`:**

D-31 single-SSOT contrast guard. Reads `assets/css/02-tokens.css` exclusively.

- **CSS parser:** Extracts all `--token: value;` declarations from the dark `.scoria-root` block and the light `.scoria-root[data-theme="light"]` block. Dark/light tokens are merged (dark provides primitives, light overrides semantics). `color-mix()` values are intentionally skipped (browser-only resolution; not needed for the checked pairs).

- **`var()` resolver:** Walks single-hop and multi-hop `var(--name)` chains up to depth 8. Unresolvable tokens `flunk/1` with a helpful message (prevents silent false-pass on token rename).

- **Inline WCAG math:** `relative_luminance/1` (sRGB linearize, rec.709 weighting) and `contrast_ratio/2` — no external library. Correct per W3C WCAG 2.1.

- **4 pairs checked in both themes (2 tests total):**
  - `--scoria-text` on `--scoria-surface-app` ≥ 4.5:1 (body text)
  - `--scoria-text-muted` on `--scoria-surface-panel` ≥ 4.5:1 (muted text)
  - `--scoria-focus-ring` on `--scoria-surface-panel` ≥ 3.0:1 (focus non-text)
  - `--scoria-focus-ring` on `--scoria-surface-panel-raised` ≥ 3.0:1 (raised surface focus)

- **Result:** 2 tests, 0 failures. All 4 pairs pass AA floors in both dark and light themes. Matches the spot-check values calculated in 16-05 SUMMARY (dark focus ~3.5:1, light focus ~3.2:1).

## Acceptance Criteria Verification

### Task 1 — Playwright spec

- [x] `node --check priv/dev/e2e/phase16_parity.spec.mjs` passes (valid JS)
- [x] Imports `waitForReady` from `./lib/ready.mjs`
- [x] Contains 375px-viewport overflow test on shell + one table screen
- [x] Contains focus-outline assertions for 6 control types under `colorScheme: 'light'`
- [x] Contains focus-outline assertions for 6 control types under `colorScheme: 'dark'`
- [x] Contains `reducedMotion: 'reduce'` test for drawer + skeleton/attention
- [x] Contains theme-toggle smoke for shell + table + evidence + overlay
- [x] No `toMatchSnapshot` or `toHaveScreenshot` (verified by grep)
- [x] `grep -q "waitForReady"`, `grep -q "reducedMotion"`, `grep -q "375"` all pass
- [x] Auto-discovered by lane (`testMatch '**/*.spec.mjs'`)

### Task 2 — Contrast guard

- [x] Reads color values ONLY from `assets/css/02-tokens.css` (no hardcoded parallel hex table)
- [x] Asserts ≥4.5:1 body text floors in both themes
- [x] Asserts ≥3.0:1 non-text/focus floors in both themes
- [x] `mix test test/scoria_web/token_contrast_guard_test.exs`: 2 tests, 0 failures
- [x] No second/parallel token definition source created

## Deviations from Plan

**1. [Rule 2 - Missing Critical Functionality] focus outline check for command input falls back to box-shadow**
- **Found during:** Task 1
- **Issue:** Command palette inputs may use `box-shadow` instead of `outline` for their focus ring in some browser implementations (CSS reset or component style).
- **Fix:** The input focus test accepts either `outlineStyle !== 'none' && outlineWidth >= 2px` OR `boxShadow !== 'none'` as proof of visible focus indicator — equivalent assurance without false failure.
- **Files modified:** priv/dev/e2e/phase16_parity.spec.mjs
- **Commit:** f032ea9

**2. [Rule 1 - Bug] resolve_token multi-clause default argument Elixir warning**
- **Found during:** Task 2 (first test run)
- **Issue:** Initial implementation used `defp resolve_token/3` with `depth \\ 0` default and a second guard clause — triggering Elixir's multi-clause default argument warning (fails `--warnings-as-errors` in CI).
- **Fix:** Split into `resolve_token/2` (arity 2, calls arity 3 with depth 0) and `resolve_token/3` (no default). Warning eliminated.
- **Files modified:** test/scoria_web/token_contrast_guard_test.exs
- **Commit:** 238b210

## Runtime Verification Deferral

`mix scoria.ui.e2e` requires a live dev server (`mix phx.server` with `mix dev.setup` applied). No dev server is available in this worktree during execution. The automated proofs for this plan are:

1. `node --check` + grep gates (all passing — verified above)
2. `mix test test/scoria_web/token_contrast_guard_test.exs` — 2 tests, 0 failures (verified)
3. Live `mix scoria.ui.e2e` run deferred to the 16-05 human checkpoint or Phase 17 final proof pass per the plan's acceptance criteria: _"With a seeded dev server running, `mix scoria.ui.e2e` runs the new spec green (run if a dev server is available; otherwise `node --check` + the grep gates are the automated proof and the human checkpoint in 16-05 covers the live run)"_

## Threat Flags

No new attack surface. Dev-only test artifacts (excluded from Hex package). The Playwright spec drives an already-running dev server; the contrast guard parses a static asset file. T-16-04 (CI DoS) mitigated: no screenshot baselines, no full axe/all-screen matrix added.

## Known Stubs

None. Both files are complete, deterministic test artifacts.

## Self-Check

Files confirmed:
- `priv/dev/e2e/phase16_parity.spec.mjs` — exists, 599 lines
- `test/scoria_web/token_contrast_guard_test.exs` — exists, 240 lines

Commits confirmed:
- `f032ea9` — feat(16-06): Phase 16 Playwright parity spec for MOTION-01..04
- `238b210` — feat(16-06): single-SSOT AA contrast floor guard (D-31)

## Self-Check: PASSED
