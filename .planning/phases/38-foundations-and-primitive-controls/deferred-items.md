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

## From 38-02 full `SCORIA_DB_PORT=55432 MIX_ENV=test mix test --warnings-as-errors` run

Run on 2026-07-02 after Task 1/2/3's edits to `lib/scoria_web/ui.ex`,
`assets/css/04-components.css`, and `test/scoria_web/ui_component_test.exs`.
`ui_component_test.exs` (all 4 new describe blocks) and
`ds06_drift_guard_test.exs` are fully green (105/105). Across the FULL suite
(3 doctests, 810 tests), 3 pre-existing failures were observed, none
referencing `signal_strip`, `.scoria-signal`, `.scoria-id`, `raw_evidence`,
`overview_stats`, `button`/`icon_button` size scale, or `:focus-visible`
(this plan's only surface):

1. **`test/scoria/ci_policy_contract_test.exs:686` — "planning ledgers
   reflect shipped hex consumer and connector milestones"** — asserts
   `ROADMAP.md` contains the string `"v2.15"` but the current roadmap is the
   v3.3 Design System Stress Test milestone. Pre-existing drift between a
   stale hardcoded version-string assertion and the live roadmap; unrelated
   to any file this plan touches.

2. **`test/scoria/warning_inventory/capture_parity_test.exs:53` — "optimized
   compile-only capture catches high-signal unclassified warning
   (injected)"** — the injected `@_parity_unused_attr` warning fixture did
   not surface in the compile-only ratchet's offender list on this run
   (`Offenders found: []`). Looks like environment/timing-sensitive ratchet
   scaffolding, unrelated to `ui.ex`/`04-components.css`.

3. **`test/scoria/support_copilot_gallery_test.exs:8` →
   `examples/support_copilot/test/support_copilot_web/orchestrator_producer_test.exs:58`
   — "approvals page shows approval from producer path on
   /scoria/approvals"** — asserts the rendered approvals page HTML contains
   the string `"Approval inbox"`. That literal string does not appear
   anywhere in `lib/scoria_web/` — this looks like a pre-existing content gap
   in the approvals page copy (or a stale expectation in the consumer
   example test), not something introduced by this plan's `signal_strip`
   deletion, `raw_evidence`/`.scoria-id` a11y edits, or new guard tests.

**Action:** Not fixed here (out of this plan's scope per the deviation-rule
boundary — none of these three failures reference this plan's declared files
`lib/scoria_web/ui.ex`, `assets/css/04-components.css`,
`test/scoria_web/ui_component_test.exs`). Flagged for `/gsd-verify-work` /
`/gsd-audit-uat` triage.
