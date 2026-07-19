# Phase 53B Deferred Items

Out-of-scope discoveries logged during plan execution, per the executor's scope
boundary rule (only auto-fix issues directly caused by the current task's changes).

## Plan 53B-05

- **Recurrence of the known `capture_parity_test.exs` full-suite-only flake
  (SEED-004 class).** `mix test --warnings-as-errors` (full suite, 3 doctests +
  1312 tests) reported exactly 1 failure: `Scoria.WarningInventory.CaptureParityTest`
  "optimized compile-only capture catches high-signal unclassified warning
  (injected)" — the same subprocess-race symptom already logged repeatedly under
  Phase 53 (`53-structured-child-spans-write-time-bound/deferred-items.md`, Plans
  53-01/53-04/53-07). Re-ran in isolation immediately after
  (`mix test test/scoria/warning_inventory/capture_parity_test.exs`): **2 tests, 0
  failures**. Confirms this is unrelated to Plan 53B-05's file
  (`test/scoria/observe/event_emit_test.exs`, the only file this plan touches — `git
  diff --stat` shows zero `lib/` changes). Not fixed — out of scope, same SEED-004
  test-code-determinism debt (STATE.md: "async `IntegrationCase`, remove
  `Process.sleep`, raise shard count").
