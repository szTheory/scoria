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
