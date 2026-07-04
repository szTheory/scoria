---
phase: 41-proof-docs-and-regression-guardrails
plan: 04
subsystem: testing
tags: [playwright, screenshot-harness, e2e, toast, focus-restore]

# Dependency graph
requires:
  - phase: 40-accessibility-motion-and-responsive-proof
    provides: "drawer/1 + modal/1 focus trap + restore contract; toast/1 auto-hide via JS.hide(time:); RESP-01 6-width viewport matrix"
  - phase: 37-dev-component-lab-and-stress-fixtures
    provides: "DevLab.Sections.Overlays' RISK-TOAST-LEGIBILITY static toast fixture at /scoria/_lab/overlays"
provides:
  - "priv/dev/shots.mjs / contact_sheet.mjs SCREENS coverage for /_lab/overlays (toast legibility + component-lab overlay states)"
  - "A freshMountPerCapture capture strategy pattern for any future screen with a client-side auto-hide/auto-expire affordance"
  - "The D-04 D-13 drawer live-patch collector flipped from report-only to a throwing e2e assertion"
affects: [41-05-milestone-close, future-e2e-harness-work]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "freshMountPerCapture SCREENS flag: re-navigate + re-await the ready sentinel before EVERY theme x viewport capture (not once per screen) to beat a client-side auto-hide timer, paired with a non-throwing DOM-count sanity warning (never asserted as a gate)."

key-files:
  created:
    - .planning/phases/41-proof-docs-and-regression-guardrails/deferred-items.md
  modified:
    - priv/dev/shots.mjs
    - priv/dev/contact_sheet.mjs
    - priv/shots/contact_sheet_index.md
    - priv/dev/e2e/drawer_focus.spec.mjs

key-decisions:
  - "lab_overlays screen path is '/_lab/overlays' (not '/scoria/_lab/overlays') because shots.mjs's baseUrl already includes the /scoria prefix — confirmed against dev/dev_router.ex's scope \"/scoria/_lab\"."
  - "The Phase 41 contact-sheet update is an additive addendum section in contact_sheet_index.md rather than a rewrite of the historical v3.0 (2026-06-04 -> 2026-06-13) before/after record, since that record documents a different milestone's diff."
  - "D-13 drawer live-patch collector flipped to a throwing expect() after mix scoria.ui.e2e observed zero warnings across a real run (D-04 VERIFY-THEN-DEFER)."
  - "6 pre-existing e2e failures observed during the Task 3 verification run (command_palette, drawer_focus CR-01, modal_focus, phase16_parity x3) are out of this plan's file scope — logged to deferred-items.md, not fixed (SCOPE BOUNDARY)."

patterns-established:
  - "freshMountPerCapture: a per-screen SCREENS flag for beating client-side auto-hide/auto-expire timers in a multi-shot capture loop, paired with a non-throwing DOM-presence sanity warning."

requirements-completed: [PROOF-01]

coverage:
  - id: D1
    description: "shots.mjs and contact_sheet.mjs SCREENS arrays both include a lab_overlays entry targeting /_lab/overlays"
    requirement: "PROOF-01"
    verification:
      - kind: other
        ref: "node --check priv/dev/shots.mjs && node --check priv/dev/contact_sheet.mjs && grep -c lab_overlays priv/dev/shots.mjs priv/dev/contact_sheet.mjs"
        status: pass
    human_judgment: false
  - id: D2
    description: "The toast-legibility capture re-navigates before every theme x viewport shot and reliably captures the auto-hiding toast (zero sanity warnings across a real mix scoria.ui.shots run)"
    requirement: "PROOF-01"
    verification:
      - kind: automated_ui
        ref: "mix scoria.ui.shots (2026-07-04 run) — lab_overlays 12/12 captures, 0 toast-sanity warnings"
    human_judgment: true
    rationale: "Toast legibility (contrast, layout, overlap with the stacked overlay probe) is a visual judgment call; automated capture only proves the toast is present in the DOM, not that it reads well. Sampled 3 of the 12 PNGs visually during this plan; full eyeball is Plan 05's evidence-manifest scope per D-13."
  - id: D3
    description: "Committed contact_sheet_index.md manifest documents the lab_overlays screen and the 2026-07-04 run status"
    requirement: "PROOF-01"
    verification:
      - kind: other
        ref: "grep -c lab_overlays priv/shots/contact_sheet_index.md"
        status: pass
    human_judgment: false
  - id: D4
    description: "D-04 D-13 collector disposition resolved (flipped to a throwing expect(), not deferred, since mix scoria.ui.e2e ran and observed zero warnings)"
    requirement: "PROOF-01"
    verification:
      - kind: e2e
        ref: "priv/dev/e2e/drawer_focus.spec.mjs — 'D-13: focus survives an unrelated live PubSub patch while the drawer stays open' (isolated re-run, chromium)"
        status: pass
    human_judgment: false

# Metrics
duration: 25min
completed: 2026-07-04
status: complete
---

# Phase 41 Plan 04: Toast Legibility & Component-Lab Screenshot Coverage + D-04 D-13 Collector Disposition Summary

**Closed the two real screenshot-matrix gaps (D-14) by adding a toast-timing-safe `/_lab/overlays` capture to both screenshot scripts, regenerated the committed contact-sheet manifest against a real local run, and flipped the D-04 D-13 drawer live-patch collector to a throwing assertion after verifying it never warns.**

## Performance

- **Duration:** 25 min
- **Completed:** 2026-07-04
- **Tasks:** 3/3 completed
- **Files modified:** 4 (2 created: deferred-items.md is a planning artifact, not counted toward files_modified)

## Accomplishments

- `priv/dev/shots.mjs` and `priv/dev/contact_sheet.mjs` now capture `/_lab/overlays` — the real `RISK-TOAST-LEGIBILITY` static toast fixture (`dev/lab/sections/overlays.ex:91-94`), not the badge-only `states.ex` section.
- A `freshMountPerCapture` capture strategy beats `toast/1`'s default 4000ms `phx-mounted` auto-hide by re-navigating and re-awaiting the ready sentinel before every one of the 12 theme×viewport shots, so every capture lands inside a fresh window (D-15) — with a non-throwing `.scoria-toast` count sanity warning (Pitfall 4) that never fires as a gate.
- Ran the real harness (`mix scoria.ui.shots`) against a local `mix phx.server` dev instance: `lab_overlays` captured cleanly across both themes × all 6 RESP-01 viewport widths with **zero toast-sanity warnings**. Manually eyeballed 3 of the 12 PNGs (`populated_dark_w1440`, `populated_light_w1440`, `populated_dark_w320`) — both the `warn` and `fail` tone toasts are clearly legible (icon + text + dismiss control) in both themes, at both desktop and narrow-mobile width, over the stacked drawer/modal overlay probe.
- Regenerated `priv/shots/contact_sheet.html` (gitignored) and appended a "Phase 41 Update" section to the committed `priv/shots/contact_sheet_index.md` documenting the new screen, the run status, the sanity-check result, and an honest note about the expected 0-paired diff vs. the 2026-06-13 baseline (Phase 40 widened `VIEWPORTS` naming — not a regression).
- Resolved the D-04 VERIFY-THEN-DEFER decision for `drawer_focus.spec.mjs`'s sole report-only D-13 collector: ran `mix scoria.ui.e2e` (159 passed, 6 unrelated pre-existing failures, 3 skipped), observed the D-13 test pass with **zero warnings/attachments**, and flipped it from `console.warn` + `testInfo.attach` to a throwing `expect()` — a free lock, zero product code changed.

## Task Commits

1. **Task 1: Add /_lab/overlays to SCREENS with a toast-timing-safe capture (D-14/D-15)** - `2d914ecc` (feat)
2. **Task 2: Regenerate the dated contact sheet + update the committed manifest (env-gated)** - `8c66c23a` (docs)
3. **Task 3: D-04 VERIFY-THEN-DEFER — decide the drawer_focus.spec.mjs D-13 collector's disposition** - `0c7412ed` (test)

**Plan metadata:** (this commit, docs: complete plan)

## Files Created/Modified

- `priv/dev/shots.mjs` - Added `lab_overlays` SCREENS entry (`freshMountPerCapture: true`) + a re-navigate-per-capture branch in `captureScreen`'s base-state loop + a `.scoria-toast` count sanity warning.
- `priv/dev/contact_sheet.mjs` - Mirrored the name-only `lab_overlays` SCREENS entry.
- `priv/shots/contact_sheet_index.md` - Appended a "Phase 41 Update (2026-07-04)" section documenting the new screen, capture strategy, run status, and the honest 0-paired-diff note vs. the 2026-06-13 baseline.
- `priv/dev/e2e/drawer_focus.spec.mjs` - Flipped the D-13 live-PubSub focus-survival collector from `console.warn`+`testInfo.attach` to a throwing `expect()`; updated the file-header and test-level comments to reflect the flip.
- `.planning/phases/41-proof-docs-and-regression-guardrails/deferred-items.md` (created) - Logged 6 pre-existing, out-of-scope `mix scoria.ui.e2e` failures observed during Task 3's verification run.

## Decisions Made

- `lab_overlays`'s `path` is `/_lab/overlays` (not `/scoria/_lab/overlays`) — `shots.mjs`'s default `--base-url` already ends in `/scoria`, confirmed against `dev/dev_router.ex`'s `scope "/scoria/_lab"`.
- The contact-sheet manifest update is an **additive addendum**, not a rewrite of the historical v3.0 (2026-06-04 → 2026-06-13) before/after record — that section documents a different milestone's diff and stays intact as historical truth.
- D-13's collector is **flipped**, not deferred: `mix scoria.ui.e2e` ran successfully and the collector passed with zero warnings, satisfying D-04's VERIFY-THEN-DEFER "never flip blind" rule by actually verifying first.
- The 6 unrelated e2e failures surfaced by running the full lane are out of this plan's `files_modified` scope (command_palette, drawer_focus's *different* CR-01 test, modal_focus, phase16_parity ×3) — logged to `deferred-items.md`, not fixed, per the SCOPE BOUNDARY rule.

## Deviations from Plan

None (Rules 1-3) — plan executed as written, including its explicit contingency branches (env-availability check for Tasks 2 and 3, both of which found the environment available and ran the real harness rather than falling back to MANUAL-CAPTURE-PENDING or deferred-env-unavailable).

## Issues Encountered

- The dev server was not already running when Task 2 began; started it via `mix dev.setup` (DB was already migrated/seeded from a prior session) + `PORT=4799 mix phx.server` in the background, confirmed `200` on `/scoria` and toast markup present at `/scoria/_lab/overlays` before running the harness. Stopped the server after Task 3 completed.
- `mix scoria.ui.e2e`'s full run surfaced 6 unrelated pre-existing failures (see Deferred Items above) — none block this plan's D-13 disposition decision, which only depends on `drawer_focus.spec.mjs`'s D-13 test itself (passed cleanly).

## Deferred Items

See `.planning/phases/41-proof-docs-and-regression-guardrails/deferred-items.md` for the 6 pre-existing e2e failures observed during Task 3's environment verification (command_palette, drawer_focus CR-01, modal_focus, phase16_parity ×3) — out of this plan's scope, candidate for a future e2e-harness flake/regression sweep.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 05 (milestone close / evidence manifest) can cite `priv/shots/contact_sheet_index.md` directly — it now enumerates `lab_overlays` and the 2026-07-04 run status (harness ran, zero toast-sanity warnings, manually spot-checked legible). The D-04 D-13 gap-register line item is resolved as "flipped," not "deferred" — Plan 05's Section B gap register should reflect that this item is now CLOSED, not an open deferred item.

---
*Phase: 41-proof-docs-and-regression-guardrails*
*Completed: 2026-07-04*

## Self-Check: PASSED

All modified files and all 3 task commits (`2d914ecc`, `8c66c23a`, `0c7412ed`) verified present on disk / in git history.
