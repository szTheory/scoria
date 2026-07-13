# Phase 53 Deferred Items

Out-of-scope discoveries logged during plan execution, per the executor's scope
boundary rule (only auto-fix issues directly caused by the current task's changes).

## Plan 53-01

- **`test/scoria/warning_inventory/capture_parity_test.exs` — full-suite-only flake
  (SEED-004 class).** `mix test --warnings-as-errors` (full suite) reported
  `1 failure`: `Scoria.WarningInventory.CaptureParityTest` "optimized compile-only
  capture catches high-signal unclassified warning (injected)" — the test spawns a
  subprocess `mix test --only __ratchet_compile_only__` against a temp fixture file
  and asserts a specific warning appears in the subprocess output; under full-suite
  parallel load the subprocess run reported `0 tests, 0 failures (1269 excluded)` /
  "The --only option was given to `mix test` but no test was executed" instead of
  compiling the fixture. Re-ran in isolation (`mix test
  test/scoria/warning_inventory/capture_parity_test.exs`) immediately after: **2
  tests, 0 failures** — confirms this is a pre-existing test-isolation/subprocess
  race, not caused by Plan 53-01's `lib/scoria/application.ex` or
  `test/scoria/application_test.exs` changes. Matches the documented SEED-004
  test-code determinism debt (STATE.md: "async `IntegrationCase`, remove
  `Process.sleep`, raise shard count") and a prior observed instance of the same
  class ("50-11: one duplicate push-triggered CI run hit an unrelated flaky
  `eventually()` timeout (SEED-004 class)"). Not fixed — out of scope for this
  plan's files.

## Plan 53-04

- **Recurrence of the same `capture_parity_test.exs` full-suite-only flake.**
  `mix test --warnings-as-errors` (full suite, 3 doctests + 1233 tests) reported
  exactly 1 failure in the identical `Scoria.WarningInventory.CaptureParityTest`
  "optimized compile-only capture catches high-signal unclassified warning
  (injected)" test — same subprocess-race symptom logged under Plan 53-01 above.
  Re-ran in isolation (`mix test test/scoria/warning_inventory/capture_parity_test.exs`)
  immediately after: 2 tests, 0 failures. Confirms this is unrelated to Plan
  53-04's files (`lib/scoria/observe/bounds.ex`, `lib/scoria/observe/telemetry.ex`,
  `config/config.exs`, `test/scoria/observe/bounds_test.exs`,
  `test/scoria_web/live/orchestrator_live_test.exs`). Not fixed — out of scope,
  same SEED-004 class debt.

## Plan 53-07

- **Recurrence of the same `capture_parity_test.exs` full-suite-only flake.**
  `mix test --warnings-as-errors` (full suite, 3 doctests + 1276 tests) reported
  exactly 1 failure in the identical `Scoria.WarningInventory.CaptureParityTest`
  "optimized compile-only capture catches high-signal unclassified warning
  (injected)" test on a re-run; a prior full-suite run (same worktree, same
  base) reported 2 failures, with the second failure not reproducing on
  re-run. Re-ran `test/scoria/warning_inventory/capture_parity_test.exs` in
  isolation immediately after the 1-failure full-suite run: 2 tests, 0
  failures. Confirms this is unrelated to Plan 53-07's files
  (`lib/scoria/observe/guardrail.ex`, `lib/scoria/runtime.ex`,
  `test/scoria/observe/guardrail_test.exs`) — `test/scoria/observe/` (181
  tests) and `test/scoria/runtime/` (26 tests) both pass 0 failures in
  isolation, and `lib/scoria/runtime/release_gate.ex`,
  `lib/scoria/connectors/auth.ex`, and
  `lib/scoria/workflows/remote_approval_projection.ex` all show an empty
  `git diff`. Not fixed — out of scope, same SEED-004 class debt.
