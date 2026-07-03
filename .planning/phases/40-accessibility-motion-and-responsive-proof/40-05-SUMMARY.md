---
phase: 40-accessibility-motion-and-responsive-proof
plan: 05
subsystem: testing
tags: [playwright, e2e, responsive, reduced-motion, wcag, css]

# Dependency graph
requires:
  - phase: 40-accessibility-motion-and-responsive-proof
    provides: "Plan 01's shared priv/dev/e2e/lib/boxes_intersect.mjs bounding-box intersection primitive"
provides:
  - "priv/dev/e2e/responsive_scan.spec.mjs — D-16(1)-(7) tiered assertion catalog across 4 anchor pages (Home, Workflows, Approvals, Incidents)"
  - "priv/dev/e2e/reduced_motion.spec.mjs — MOTION-01 duration-collapse proof incl. the infinite skeleton and the D-21 approval-pulse"
  - "priv/dev/e2e/lib/instant_duration.mjs — shared isInstantDuration predicate, factored out of phase16_parity.spec.mjs"
  - "priv/dev/shots.mjs widened to the 6-width matrix (320/375/768/1024/1440/1920) for contact-sheet human evidence"
  - "one in-scope CSS fix: .scoria-button--sm now floors min-height at --scoria-space-5 (24px, WCAG 2.5.8)"
affects: [41-proof-hardening-and-docs]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "D-04 two-bucket rule applied literally: every new-surface assertion was run live against a real dev server before being written as a throwing expect(); the one defect found (24px target floor) was fixed in the same commit rather than deferred."
    - "DOM-injection of shipped-but-currently-unreachable-via-UI CSS classes (.scoria-skeleton, .scoria-attention) to deterministically exercise a real cascade rule without racing a flaky async-loading state."

key-files:
  created:
    - priv/dev/e2e/responsive_scan.spec.mjs
    - priv/dev/e2e/reduced_motion.spec.mjs
    - priv/dev/e2e/lib/instant_duration.mjs
  modified:
    - priv/dev/e2e/phase16_parity.spec.mjs
    - priv/dev/shots.mjs
    - assets/css/04-components.css
    - priv/static/scoria/app.css

key-decisions:
  - "Anchor set for the D-15 ~4-page responsive scan: Home + Workflows (the phase16_parity baseline, generalized to 6 widths) plus Approvals (dense table + mobile_summary + sticky footer + toast region) and Incidents (page-split grid + list) — a workflow-detail page was considered but left out (Claude's Discretion) since its grid-split primitive is already exercised by Incidents and its drawer-occlusion risk is drawer_focus.spec.mjs's job, not D-16's."
  - "Every responsive_scan.spec.mjs and reduced_motion.spec.mjs assertion is a throwing expect() (not a warning-grade collector): each check was run live against a real dev server while authoring the spec, and every anchor page/surface came back clean except one (see below), so per D-04 this is fix-and-assert-atomic, not new-and-uncertain."
  - "Fixed the one defect the proof surfaced: .scoria-button--sm rendered ~22px tall (12px font-size + 4px top/bottom padding + 1px border, no min-height) — below the WCAG 2.5.8 24px floor. Floored min-height at the existing --scoria-space-5 (24px) token; no vocabulary change, no new sizing primitive."
  - "The D-20 skeleton and D-21 approval-pulse motion specimens are DOM-injected into the live .scoria-root subtree for reduced_motion.spec.mjs rather than driven through a live async-loading race or a dead .scoria-attention callsite — this exercises the real shipped CSS cascade deterministically."

requirements-completed: [RESP-01, MOTION-01]

coverage:
  - id: D1
    description: "responsive_scan.spec.mjs implements the full D-16(1)-(7) tiered assertion catalog across Home/Workflows/Approvals/Incidents"
    requirement: "RESP-01"
    verification:
      - kind: e2e
        ref: "priv/dev/e2e/responsive_scan.spec.mjs — 58 tests, run live via npx playwright test responsive_scan.spec.mjs"
        status: pass
    human_judgment: false
  - id: D2
    description: "reduced_motion.spec.mjs proves animationDuration/transitionDuration collapse under prefers-reduced-motion, including the infinite skeleton and the D-21 approval-pulse"
    requirement: "MOTION-01"
    verification:
      - kind: e2e
        ref: "priv/dev/e2e/reduced_motion.spec.mjs — 5 tests, run live via npx playwright test reduced_motion.spec.mjs"
        status: pass
      - kind: e2e
        ref: "priv/dev/e2e/phase16_parity.spec.mjs — 18/18 non-MOTION-04 tests green after the isInstantDuration extraction (behavior-preserving)"
        status: pass
    human_judgment: false
  - id: D3
    description: "shots.mjs widened to the 6-width matrix; contact_sheet.mjs renders the captures as human evidence with no pixel-diff gate"
    verification:
      - kind: other
        ref: "node -e assertion confirming all 6 widths present in shots.mjs; live capture run produced 156 paired PNGs, rendered cleanly via contact_sheet.mjs"
        status: pass
    human_judgment: false

# Metrics
duration: 40min
completed: 2026-07-03
status: complete
---

# Phase 40 Plan 05: Responsive & Reduced-Motion Proof Summary

**RESP-01 proven across 6 widths on 4 anchor pages (Home/Workflows/Approvals/Incidents) via a new tiered D-16(1)-(7) Playwright catalog, MOTION-01 proven via a dedicated reduced_motion.spec.mjs (incl. the infinite skeleton), and shots.mjs widened to the 6-width matrix — with one real 24px WCAG 2.5.8 target-size defect found and fixed along the way.**

## Performance

- **Duration:** ~40 min
- **Completed:** 2026-07-03
- **Tasks:** 3
- **Files modified:** 7 (3 created, 4 modified)

## Accomplishments

- `priv/dev/e2e/responsive_scan.spec.mjs` (58 tests): generalizes the proven `phase16_parity.spec.mjs` 375px no-h-overflow seed (Home + `/workflows`) to all 6 widths, and adds Approvals + Incidents as the two not-yet-e2e-scanned primary surfaces named in 40-CONTEXT.md D-15. Implements the full tiered catalog: doc overflow (all 6 widths), essential-element clipping (320/375/768), table-overflow-contained + keyboard-reachable, `:mobile_summary` swap correctness, toast-region-vs-nav static occlusion (via the shared `boxesIntersect`), and the 24px target floor.
- `priv/dev/e2e/reduced_motion.spec.mjs` (5 tests) + `priv/dev/e2e/lib/instant_duration.mjs`: proves `animationDuration`/`transitionDuration` collapse under `emulateMedia({reducedMotion:'reduce'})` on the mobile nav drawer, command palette, the D-20 infinite skeleton pulse, the D-21 approval-pulse border-color cue, and a generic interactive control. `phase16_parity.spec.mjs` now imports the extracted helper with no behavior change (confirmed 18/18 non-MOTION-04 tests still green).
- `priv/dev/shots.mjs`: `VIEWPORTS` widened from 2 entries to the 6-width matrix; verified end-to-end with a live capture run (156 paired PNGs) rendered cleanly through the unmodified `contact_sheet.mjs`.
- Fixed a real WCAG 2.5.8 defect found while authoring the proof: `.scoria-button--sm` rendered ~22px tall on mobile — floored at the existing `--scoria-space-5` (24px) token.

## Task Commits

1. **Task 1: responsive_scan.spec.mjs — tiered D-16 catalog across ~4 primary pages** - `72bc8574` (feat)
2. **Task 2: reduced_motion.spec.mjs + instant_duration.mjs extraction** - `0116e39d` (feat)
3. **Task 3: widen shots.mjs to the 6-width matrix** - `3cfb0799` (feat)

_Note: all three tasks were single-commit (no TDD red/green split — plan type is `execute`, not `tdd`)._

## Files Created/Modified

- `priv/dev/e2e/responsive_scan.spec.mjs` - new D-16(1)-(7) tiered responsive catalog across 4 anchor pages
- `priv/dev/e2e/reduced_motion.spec.mjs` - new dedicated MOTION-01 reduced-motion duration-collapse proof
- `priv/dev/e2e/lib/instant_duration.mjs` - new shared `isInstantDuration` predicate
- `priv/dev/e2e/phase16_parity.spec.mjs` - imports the extracted `isInstantDuration` helper (no behavior change)
- `priv/dev/shots.mjs` - `VIEWPORTS` widened from 2 entries to the 6-width matrix
- `assets/css/04-components.css` - `.scoria-button--sm` floors `min-height` at `--scoria-space-5` (24px)
- `priv/static/scoria/app.css` - regenerated via `mix scoria.assets.build` to pick up the CSS fix

## Decisions Made

- Chose Home + Workflows + Approvals + Incidents as the ~4-page D-15 anchor set (see `key-decisions` in frontmatter for the full rationale on why workflow-detail was left out).
- Ran every new assertion live against a real dev server while authoring the specs; since every surface came back clean (bar the one 24px defect, fixed inline), every assertion in both new spec files ships as a throwing `expect()` per the D-04 fix-and-assert-atomic branch of the two-bucket rule — no non-throwing collectors were needed in this plan.
- DOM-injected the `.scoria-skeleton`/`.scoria-attention` specimens for `reduced_motion.spec.mjs` rather than chasing a live async-loading race or a dead callsite, to keep the proof deterministic while still exercising the real shipped CSS.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `.scoria-button--sm` rendered below the WCAG 2.5.8 24px target-size floor**
- **Found during:** Task 1 (`responsive_scan.spec.mjs` D-16(6) authoring — live-verified against a real dev server)
- **Issue:** `.scoria-button--sm` (12px font-size, `line-height:1`, `--scoria-space-1` top/bottom padding, 1px border) computed to ~22px tall on mobile — below the WCAG 2.5.8 (2.2) 24×24 CSS px minimum. Affected several `<a>`/`<button>` controls on `/approvals` and `/incidents` at 320/375px.
- **Fix:** Added `min-height: var(--scoria-space-5)` (the existing 24px spacing token) to `.scoria-button--sm` in `assets/css/04-components.css`; rebuilt via `mix scoria.assets.build`.
- **Files modified:** `assets/css/04-components.css`, `priv/static/scoria/app.css`
- **Verification:** Re-ran the live probe post-fix — 0 undersized targets across all 4 anchor pages at 320/375px; `responsive_scan.spec.mjs`'s D-16(6) block passes.
- **Committed in:** `72bc8574` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug/WCAG compliance floor).
**Impact on plan:** Necessary for the D-16(6) assertion to be true (and therefore hard-assertable); no scope creep — pure CSS sizing fix via an existing design token, no vocabulary change.

## Issues Encountered

- The full parallel `mix scoria.ui.e2e`-equivalent run (`npx playwright test --workers=1`, 139 tests) surfaces 3 **pre-existing** failures in `phase16_parity.spec.mjs`'s `MOTION-04: theme-toggle smoke` block (`.first()` resolving to the hidden `#scoria-theme-toggle-mobile` at desktop viewport). This is unrelated to this plan's changes — confirmed by reproducing the identical failure with this plan's CSS diff stashed out — and was already logged in `40-GAP-REGISTER.md`/`deferred-items.md` by Plan 40-03. Not re-logged; not fixed here (out of `files_modified` scope for this plan).
- All 129 other tests in the full suite passed (7 intentionally skipped `uat.spec.mjs` pending-fixture placeholders), confirming no regression from this plan's CSS change or the `phase16_parity.spec.mjs` import edit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- RESP-01 and MOTION-01 are proven and locked for Phase 41 to harden (flip any future warning-grade collectors → `expect()`, if Phase 41's own work adds new surfaces).
- `priv/dev/shots.mjs`'s 6-width captures are ready to seed Phase 41's screenshot baseline.
- No blockers. `deferred-items.md`'s two pre-existing e2e-harness issues (MOTION-04 selector-visibility bug, cross-spec-file approval-pool race) remain open for whoever picks them up — neither blocks this plan's requirements.

---
*Phase: 40-accessibility-motion-and-responsive-proof*
*Completed: 2026-07-03*

## Self-Check: PASSED

All created/modified files confirmed present on disk; all three task commit hashes (`72bc8574`, `0116e39d`, `3cfb0799`) confirmed in `git log`.
