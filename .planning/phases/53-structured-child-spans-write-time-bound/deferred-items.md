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

## Buffer.flush/1 drops the entire batch when one span is invalid (product debt)

**Found:** Phase 53 post-merge gate, after Wave 3 (53-07) merged.
**Severity:** real production robustness defect — not a test artifact.

`Scoria.Observe.Buffer.flush/1` (`lib/scoria/observe/buffer.ex:120-160`) writes the
whole buffer in a SINGLE `Ecto.Multi` transaction (`insert_all` traces +
`insert_all` spans). A constraint violation on ONE span therefore rolls back the
entire batch — up to `max_size` (default 1000) otherwise-valid spans are silently
lost. The failure is caught and counted as `dropped_count`, so it never crashes the
Buffer; it just discards good telemetry.

**How it surfaced:** 53-07 wired G1 into `Scoria.Runtime.start_run/2`, so guardrail
spans now flow through the default pipeline into the globally-supervised Buffer. The
19 test files that call `start_run/2` park spans there and never flush; their sandbox
transactions then roll back the referenced trace rows. When `Scoria.ApplicationTest`
later called `Buffer.flush_now/0`, the batch included those orphaned foreign spans,
the transaction failed as a unit, and the test's OWN span was rolled back with it —
an intermittent (~1-in-5, seed-dependent) `Ecto.NoResultsError`.

**Fixed in-phase (test scope only):** `test/scoria/application_test.exs` now drains
the shared Buffer in `setup` so its flush batch is scoped to the span it emits.

**NOT fixed (deliberate, out of scope):** the product behavior. No Phase 53 plan
covers the write path's batch-failure semantics, and hardening it touches the same
`telemetry.ex`/Buffer path 53-04 just wired `Bounds` into. Recommended follow-up:
on batch failure, fall back to per-span (or chunked) inserts so poisoned rows are
isolated and the remaining valid spans still persist.
