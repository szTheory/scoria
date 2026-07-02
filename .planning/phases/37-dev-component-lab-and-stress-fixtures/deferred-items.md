# Phase 37 — Deferred Items

Out-of-scope discoveries found during plan execution, not caused by the current
plan's file changes (per GSD scope-boundary rule — logged, not fixed).

## From 37-01 full-suite verification (`SCORIA_DB_PORT=55432 mix test --warnings-as-errors`)

Run on 2026-07-02 after Task 3 (`dev/lab/**`, `test/scoria_web/dev_lab_boundary_test.exs`,
`test/scoria_web/ds06_drift_guard_test.exs`): **3 doctests, 801 tests, 3 failures (15 excluded)**.
None of the 3 failures reference `dev/lab/`, `dev_lab_boundary_test.exs`, or
`ds06_drift_guard_test.exs` — all three are pre-existing/unrelated to this plan's
changes.

1. **`Scoria.CiPolicyContractTest` — "planning ledgers reflect shipped hex
   consumer and connector milestones"** (`test/scoria/ci_policy_contract_test.exs:686`)
   Asserts `.planning/ROADMAP.md` still contains `"v2.15"`; the roadmap now
   reflects `v3.3`. Already a documented residual failure from Phase 36 — see
   `.planning/phases/36-baseline-and-inventory/36-VERIFICATION.md` line 107.

2. **`Scoria.SupportCopilotGalleryTest` — "support copilot gallery proves
   advisory adoption journey"** (`test/scoria/support_copilot_gallery_test.exs:8`)
   Nested nested-project nested `mix test` run in `examples/support_copilot`
   fails with a `Postgrex.Protocol` connection-ownership error
   (`DBConnection.ConnectionError: owner ... exited`) during
   `OrchestratorProducerTest`. Looks like a DB-connection-pool timing flake in
   the advisory gallery lane (`mix scoria.test.support_copilot`), not a code
   defect introduced by this plan.

3. **`Scoria.WarningInventory.CaptureParityTest` — "optimized compile-only
   capture catches high-signal unclassified warning (injected)"**
   (`test/scoria/warning_inventory/capture_parity_test.exs:53`)
   A nested compile-only `mix test --only __ratchet_compile_only__` self-test
   expects an injected warning to show up in offenders and finds none
   (`0 tests, 0 failures (819 excluded)` / `"--only" option was given but no
   test was executed`). Looks like a nested-invocation/test-selection timing
   issue in the warning-inventory tooling's own self-test, unrelated to
   `dev/lab/`.

**Action:** Not fixed here (out of this plan's scope per the deviation-rule
boundary). Re-run before Phase 37's `/gsd-verify-work` to confirm these are
still isolated to pre-existing/tooling flakes and not newly introduced by
later plans (37-02 through 37-06) in this phase.
