# Deferred Items — Phase 56.1

## Plan 01

Full-suite `mix test --warnings-as-errors` run during plan-01 closeout (2026-07-28) surfaced
2 pre-existing failures, neither touching any file this plan modified
(`priv/repo/migrations/20260728120000_add_rail_columns_to_ai_workflow_runs.exs`,
`lib/scoria/workflows/run.ex`, `lib/scoria/workflows/rails.ex`, `lib/scoria/workflows.ex`,
`lib/scoria/workflows/runtime.ex`, `test/scoria/workflows/rails_test.exs`,
`test/scoria/workflows_test.exs`, `test/scoria/workflows/approval_write_invariant_guard_test.exs`):

1. **`test/scoria/warning_inventory/capture_parity_test.exs:53`** — the already-acknowledged
   SEED-004-class flake documented in `.planning/STATE.md` Deferred Items
   (`2026-07-18-flaky-capture-parity-test.md`): flakes under full-suite `--seed 0` ordering,
   passes in isolation. Not a plan-01 regression.

2. **`test/scoria/observe/telemetry_test.exs:245`** ("WR-01: concurrent first-time rejections
   racing to create the rejected-warned ETS table never detach the handler") — a
   concurrency/timing-sensitive test unrelated to workflows/rails. Verified passing in isolation
   (`mix test test/scoria/observe/telemetry_test.exs` → 10 tests, 0 failures) immediately after
   the full-suite run failed it. Full-suite-ordering flake, out of this plan's file scope.

Both were left untouched per the SCOPE BOUNDARY rule (only auto-fix issues directly caused by
this plan's changes). The scoped verification lane
(`mix test test/scoria/workflows/rails_test.exs test/scoria/workflows_test.exs
test/scoria/workflows/approval_write_invariant_guard_test.exs --warnings-as-errors`) is green.
