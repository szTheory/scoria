---
phase: 40-accessibility-motion-and-responsive-proof
plan: 04
subsystem: testing
tags: [playwright, axe-core, a11y, wcag, contrast, css, design-tokens]

# Dependency graph
requires:
  - phase: 40-accessibility-motion-and-responsive-proof
    provides: "Plan 01's shared priv/dev/e2e/lib/axe.mjs (fixed WCAG tag list + target-size rule override) and priv/dev/e2e/lib/ready.mjs"
provides:
  - "priv/dev/e2e/a11y_axe.spec.mjs — Tier 1 report-only axe baseline across all 7 dev-lab sections (both themes) + Tier 2 curated assert-zero on all 7 seeded real pages (both themes)"
  - "Token-SSOT fix: --scoria-text-subtle repointed off --scoria-pumice-500 to clear the WCAG AA 4.5:1 body-text floor in both themes"
  - "token_contrast_guard_test.exs extended with the --scoria-text-subtle pair (panel + app backgrounds) so this defect cannot silently regress"
affects: [41-proof-hardening-and-docs]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "D-06 two-tier axe proof: report-only full-lab baseline (never asserted, human-curated) feeds a curated assert-zero scan on a human-confirmed real-page allow-list — the same shared axe.mjs config drives both tiers so the tag list/target-size override cannot drift between them."
    - "Contrast defects are fixed by repointing the SEMANTIC token alias to the nearest existing PRIMITIVE ramp step that clears the floor, never by inventing a new primitive or touching page-local color (D-01/Spine #5)."
    - "target-size (2.5.8) is a WCAG 2.2 AA tag member but is deliberately excluded from every assert-zero check (both tiers) through Phase 40, per D-06 — filtered out of the curated block's assertion, still attached to the report for visibility."

key-files:
  created:
    - priv/dev/e2e/a11y_axe.spec.mjs
  modified:
    - brandbook/tokens.json
    - brandbook/tokens.css
    - assets/css/02-tokens.css
    - priv/static/scoria/app.css
    - test/scoria_web/token_contrast_guard_test.exs

key-decisions:
  - "Checkpoint-approved allow-list: ALL 7 seeded real operator pages (Home /, Workflows /workflows, Approvals /approvals, Incidents /incidents, Review Queue /reviews, Datasets /datasets, Connectors /connectors) — not a subset. All 14 (7 pages x 2 themes) curated cases assert zero non-target-size violations."
  - "The one genuine defect the Task 1 baseline surfaced — --scoria-text-subtle (aliased to --scoria-pumice-500) failing the 4.5:1 AA body-text floor against the dark sidebar/panel bg (4.29:1), the light sidebar/panel bg (4.06:1), and the light breadcrumb-separator/app bg (3.91:1) — was fixed via the token SSOT, not page-local color."
  - "Chose per-theme repoints to the nearest EXISTING neutral-ramp step rather than inventing a new pumice-600 primitive (out of D-01 scope — new primitive vocabulary is a locked boundary): dark theme text-subtle -> --scoria-muted-warm (8.44:1, same value dark text-muted already uses); light theme text-subtle -> --scoria-graphite-700 (11.43:1, same value light text-muted already uses). The pumice-500 primitive itself is untouched (still backs --scoria-span-redacted in both themes)."
  - "Added the --scoria-text-subtle pair to token_contrast_guard_test.exs against BOTH --scoria-surface-panel and --scoria-surface-app (covers the sidebar/panel and breadcrumb/app-background cases in one guard, both themes) so the defect is now floor-guarded and cannot silently regress via a future token edit."
  - "No 40-GAP-REGISTER.md entries added: the curated assert-zero scan came back completely clean on all 7 real pages in both themes after the single token fix — no out-of-scope-boundary finding surfaced."

requirements-completed: [A11Y-02]

coverage:
  - id: D1
    description: "Report-only axe baseline (WCAG 2.2 AA tags) across all 7 dev-lab sections, both themes, with target-size proven to run but not asserted"
    requirement: "A11Y-02"
    verification:
      - kind: e2e
        ref: "priv/dev/e2e/a11y_axe.spec.mjs — 14 report-only tests (Tier 1), run live via npx playwright test a11y_axe.spec.mjs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Genuine contrast defect (--scoria-text-subtle on pumice-500) fixed via the token SSOT in both themes, re-greening token_contrast_guard_test.exs with a new guarded pair"
    requirement: "A11Y-02"
    verification:
      - kind: unit
        ref: "test/scoria_web/token_contrast_guard_test.exs — 2 tests (dark + light theme), mix test test/scoria_web/token_contrast_guard_test.exs test/scoria_web/ds06_drift_guard_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Curated assert-zero axe scan on all 7 checkpoint-confirmed seeded real pages, both themes, zero non-target-size violations"
    requirement: "A11Y-02"
    verification:
      - kind: e2e
        ref: "priv/dev/e2e/a11y_axe.spec.mjs — 14 curated assert-zero tests (Tier 2), run live via npx playwright test a11y_axe.spec.mjs -g \"curated assert-zero\""
        status: pass
    human_judgment: false

# Metrics
duration: ~25min (this session; Task 1 + checkpoint approval occurred in a prior session)
completed: 2026-07-03
status: complete
---

# Phase 40 Plan 04: axe-core WCAG 2.2 AA Computed-Truth Proof Summary

**Two-tier axe-core proof (A11Y-02): report-only full-lab baseline across all 7 dev-lab sections in both themes surfaced one genuine contrast defect, which was fixed at the token SSOT (repointing --scoria-text-subtle off pumice-500); the curated assert-zero scan then passed clean on all 7 seeded real pages in both themes (14/14).**

## Performance

- **Duration:** ~25 min this session (Task 2 + token fix + guard extension); Task 1 (report-only baseline) and the human-verify checkpoint were completed/approved in a prior session
- **Completed:** 2026-07-03
- **Tasks:** 2 (both `type="auto"`, separated by a `checkpoint:human-verify` gate)
- **Files modified:** 6 (1 created, 5 modified — including 1 regenerated build artifact)

## Accomplishments

- `priv/dev/e2e/a11y_axe.spec.mjs` Tier 1 (Task 1, prior session): report-only axe baseline across all 7 `dev/lab/lab_live.ex` sections (Foundations, Primitives, Groups, States, Viewports, Overlays, Fixtures), both themes — 14 tests, non-throwing, per-rule breakdown attached to the Playwright report; confirms the shared `target-size` rule override actually runs.
- Checkpoint approved with two decisions: the assert-zero allow-list is ALL 7 seeded real pages (not a subset), and the one genuine contrast hit gets the "proper fix" — repointing the semantic token, not the primitive.
- Fixed the genuine defect: `--scoria-text-subtle` (previously `var(--scoria-pumice-500)` in both themes) measured 4.29:1 (dark sidebar/panel), 4.06:1 (light sidebar/panel), and 3.91:1 (light breadcrumb-separator/app) — all below the WCAG AA 4.5:1 body-text floor. Repointed per-theme to the nearest existing neutral-ramp step: dark -> `--scoria-muted-warm` (8.44:1), light -> `--scoria-graphite-700` (11.43:1). Propagated `brandbook/tokens.json` -> `brandbook/tokens.css` -> `assets/css/02-tokens.css` per the token-SSOT flow; `node brandbook/tools/check-consistency.mjs` confirms all sources still agree.
- Extended `test/scoria_web/token_contrast_guard_test.exs`'s `@checked_pairs` with `--scoria-text-subtle` against both `--scoria-surface-panel` and `--scoria-surface-app` (both themes) so this pair is now floor-guarded.
- `priv/dev/e2e/a11y_axe.spec.mjs` Tier 2 (Task 2, this session): curated `test.describe` block scanning all 7 checkpoint-confirmed real pages (Home, Workflows, Approvals, Incidents, Review Queue, Datasets, Connectors) in both themes, asserting zero non-`target-size` violations (throwing `expect`). `target-size` stays report-only through Phase 40 per D-06 — filtered out of the assertion but still attached to the report. All 14 cases pass live against `make dev`.

## Task Commits

1. **Task 1: a11y_axe.spec.mjs — report-only baseline, full lab, both themes** - `dcdd5ba0` (feat) — prior session
2. **Fix: repoint --scoria-text-subtle off pumice-500 + guard test extension** - `43bdadfd` (fix) — token-SSOT fix surfaced by the checkpoint decision, committed as its own atomic unit ahead of Task 2's curated scan
3. **Task 2: curated axe assert-zero scan on all 7 seeded real pages** - `088e85d4` (feat)

_Note: all commits are single-commit (no TDD red/green split — plan type is `execute`, not `tdd`). The token fix is its own commit rather than folded into Task 2, since it is a distinct unit of work (contrast remediation) that the curated scan then depends on to pass._

## Files Created/Modified

- `priv/dev/e2e/a11y_axe.spec.mjs` - new file; Tier 1 report-only full-lab baseline (Task 1) + Tier 2 curated assert-zero on 7 real pages (Task 2)
- `brandbook/tokens.json` - `semantic.dark.text-subtle` and `semantic.light.text-subtle` hex values updated to match the CSS repoint (docs SSOT; not covered by `check-consistency.mjs`'s primitive-only check, kept in sync manually)
- `brandbook/tokens.css` - `--scoria-text-subtle` repointed per-theme (dark -> `--scoria-muted-warm`, light -> `--scoria-graphite-700`) with inline rationale comment
- `assets/css/02-tokens.css` - same repoint as `tokens.css` (dashboard runtime SSOT)
- `priv/static/scoria/app.css` - regenerated by the running dev server's asset watcher to pick up the CSS token change
- `test/scoria_web/token_contrast_guard_test.exs` - added `--scoria-text-subtle` vs `--scoria-surface-panel` and vs `--scoria-surface-app` to `@checked_pairs`

## Decisions Made

See `key-decisions` in frontmatter for the full rationale on the allow-list scope and the per-theme token repoint choice.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug, per approved checkpoint decision] `--scoria-text-subtle` failed the WCAG AA 4.5:1 contrast floor in both themes**
- **Found during:** Task 1's report-only axe baseline, curated during the `checkpoint:human-verify` gate
- **Issue:** `--scoria-text-subtle` aliased `var(--scoria-pumice-500)` in both the dark and light semantic blocks. Measured contrast: 4.29:1 against the dark sidebar/panel background, 4.06:1 against the light sidebar/panel background, and 3.91:1 against the light breadcrumb-separator/app background — all below the 4.5:1 AA body-text floor.
- **Fix:** Repointed the semantic alias per-theme to the nearest existing neutral-ramp step clearing the floor: dark theme -> `--scoria-muted-warm` (8.44:1), light theme -> `--scoria-graphite-700` (11.43:1). Propagated `tokens.json` -> `tokens.css` -> `02-tokens.css`. The `--scoria-pumice-500` primitive itself was left untouched (still used by `--scoria-span-redacted`).
- **Files modified:** `brandbook/tokens.json`, `brandbook/tokens.css`, `assets/css/02-tokens.css`, `priv/static/scoria/app.css`, `test/scoria_web/token_contrast_guard_test.exs`
- **Verification:** Computed WCAG 2.1 contrast ratios directly (dark: 8.44:1 and 8.82:1; light: 11.43:1 and 11.86:1 — all >= 4.5:1); `mix test test/scoria_web/token_contrast_guard_test.exs test/scoria_web/ds06_drift_guard_test.exs` green (6 tests, 0 failures); `node brandbook/tools/check-consistency.mjs` confirms all 4 token sources still agree; the Task 2 curated axe scan then passed zero-violations live on all 7 real pages, both themes.
- **Committed in:** `43bdadfd`

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug/WCAG compliance floor), pre-authorized by the approved checkpoint decision rather than discovered independently.
**Impact on plan:** Necessary for the Task 2 curated assert-zero scan to be true (and therefore hard-assertable); no scope creep — the fix stayed entirely within the token SSOT, as required by D-01/Spine #5.

## Issues Encountered

None beyond the contrast defect above (already documented as a deviation).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- A11Y-02's computed-contrast/name/role/ARIA proof is complete and locked: report-only full-lab baseline (both themes) + curated assert-zero on all 7 real pages (both themes), both live-verified against a real dev server.
- `40-GAP-REGISTER.md` unchanged — no out-of-scope-boundary finding surfaced by this plan (the curated scan came back fully clean after the single token fix).
- `target-size` (2.5.8) remains report-only through Phase 40 in both tiers per D-06; Phase 41 owns any decision to ratchet it to assert-zero.
- No blockers for Phase 41.

---
*Phase: 40-accessibility-motion-and-responsive-proof*
*Completed: 2026-07-03*

## Self-Check: PASSED

All 7 created/modified files confirmed present on disk (`priv/dev/e2e/a11y_axe.spec.mjs`, `brandbook/tokens.json`, `brandbook/tokens.css`, `assets/css/02-tokens.css`, `priv/static/scoria/app.css`, `test/scoria_web/token_contrast_guard_test.exs`, this SUMMARY.md); all three commit hashes (`dcdd5ba0`, `43bdadfd`, `088e85d4`) confirmed in `git log`.
