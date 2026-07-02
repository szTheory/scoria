# Phase 38 — Deferred Items

Out-of-scope discoveries found during plan execution, not caused by the current
plan's file changes (per GSD scope-boundary rule — logged, not fixed).

## From 38-01 Task 3 full `mix scoria.ui.e2e` run (`priv/dev/e2e/*.spec.mjs`)

Run on 2026-07-02 after extending `priv/dev/e2e/lab.spec.mjs`'s dense-approvals +
toast-overlay block with the opaque-alpha assertion: **all 18 `lab.spec.mjs`
tests pass** (including the new toast-opacity assertion, in both light and dark
themes). Across the FULL Playwright run (all `priv/dev/e2e/*.spec.mjs` files),
4 pre-existing failures were observed, none in `lab.spec.mjs` and none
referencing `.scoria-toast`, `.scoria-flash`, `--scoria-toast-*-bg`,
`02-tokens.css`, or `04-components.css` (this plan's only files):

1. **`ia_orientation.spec.mjs:44` — "Incident ingress → Open run → return chip
   + run egress verbs"** — times out waiting for
   `button[phx-click="select_incident"]` filtered to text "Refund tool
   returned an error" to become visible. Unrelated to toast/flash background
   tokens; looks like a seed-data/incident-fixture timing issue in an
   unrelated IA spec.

2. **`phase16_parity.spec.mjs:506/529/547` — "MOTION-04: theme-toggle smoke"
   (Home/shell, Workflows table, Workflow detail)** — all three time out
   (30s) clicking `#scoria-theme-toggle, #scoria-theme-toggle-mobile`
   ("element is not visible"). This targets the app-shell `ThemeToggle`
   button on real dashboard pages (`/`, `/workflows`, `/workflows/:id`), not
   the dev Component Lab route this plan touches (which has no theme-toggle
   affordance at all — see `lab.spec.mjs`'s D-14 theme-coverage block
   comment). Looks like a pre-existing responsive-visibility timing issue in
   an unrelated Phase 16 motion spec, not a regression from the toast/flash
   opacity token change.

A fifth failure (`command_palette.spec.mjs:76`) observed on one run of the
full suite did not reproduce on a subsequent run of the same file — flaky,
not attributable to this plan's changes.

**Action:** Not fixed here (out of this plan's scope per the deviation-rule
boundary — none of these specs, selectors, or fixtures were touched by Task
1/2/3's files: `assets/css/02-tokens.css`, `assets/css/04-components.css`,
`test/scoria_web/toast_opacity_guard_test.exs`, `priv/dev/e2e/lab.spec.mjs`).
Re-run before `/gsd-verify-work` to confirm these stay isolated to
pre-existing/unrelated specs and are not newly introduced by later 38-0x
plans.
