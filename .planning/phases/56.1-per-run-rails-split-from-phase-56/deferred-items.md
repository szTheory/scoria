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

## Plan 04

Full-suite `mix test --warnings-as-errors` run during plan-04 closeout (2026-07-28) surfaced
1 pre-existing failure, unrelated to any file this plan modified
(`lib/scoria/workflows/run.ex`, `lib/scoria/workflows/rails.ex`, `lib/scoria/workflows/runtime.ex`,
`test/scoria/workflows_test.exs`, `test/scoria/workflows/rails_test.exs`,
`test/scoria/workflows/runtime_test.exs`):

1. **`test/scoria_web/live/orchestrator_live_test.exs:356`** ("SEC-01: the operator dashboard
   still hydrates traces with Bounds ON (D-06c-1, plan 53-04) a real span emitted through the
   full pipeline (Bounds live) still renders on mount") — a full-suite ordering flake in the
   observe/buffer async-flush pipeline, unrelated to workflows/rails. Verified passing in
   isolation (`mix test test/scoria_web/live/orchestrator_live_test.exs` -> 13 tests, 0 failures)
   immediately after the full-suite run failed it. SEED-004-class, out of this plan's file scope.

Left untouched per the SCOPE BOUNDARY rule. The scoped verification lane
(`mix test test/scoria/workflows/rails_test.exs test/scoria/workflows_test.exs
test/scoria/workflows/runtime_test.exs --warnings-as-errors`) is green (81/81).

## Plan 06

`MIX_ENV=dev mix docs --warnings-as-errors` (the mechanism behind `mix scoria.release_preview`,
not required by this plan's own `<verification>` block, which only requires plain `mix docs` to
build without a missing-extra error) was already RED before this plan touched any file, from 4
warnings across files this plan never modified:

1. **`lib/scoria/knowledge.ex:161`** (`Scoria.Knowledge.set_source_trust/3`) — "reference to a
   filtered module", reported twice (once per doc format pass).
2. **`lib/scoria/mcp/tool.ex:28`** (`Scoria.MCP.Tool` module doc) — "reference to a filtered
   module".
3. **`README.md`** and **`guides/reference/glossary.md`** both reference a
   `guides/capabilities/trace-observability.md` file that does not exist in this repo.

Verified pre-existing via `git log --oneline -- lib/scoria/knowledge.ex lib/scoria/mcp/tool.ex
README.md guides/reference/glossary.md`: the most recent commits touching any of these four
files are from phases 55/56, not 56.1. Left untouched per the SCOPE BOUNDARY rule.

This plan's own new/edited docs (`guides/capabilities/per-run-rails.md` and the three mirrored
footgun notes) introduced 9 additional filtered-module warnings of the same class (internal
modules like `Scoria.Runtime.Rails`, `Scoria.MCP.Router`, `Scoria.MCP.Executor.execute/4`,
`Scoria.SRE.BudgetEngine`, `Scoria.Runtime.Params`, `Scoria.Workflows.Run`,
`Scoria.Application.start/2` are deliberately excluded from `docs_public_modules/0`, so ExDoc
cannot autolink prose that names them). These ARE this plan's own scope (Rule 1 — directly
caused by this plan's own new guide content), so they were fixed by adding the specific terms to
`mix.exs`'s pre-existing `docs_code_autolink_skips/0` allowlist (the established pattern for
exactly this situation) rather than left as new debt. `MIX_ENV=dev mix docs --warnings-as-errors`
now surfaces only the 4 pre-existing, out-of-scope warnings above — zero new warnings from this
plan's own content.
