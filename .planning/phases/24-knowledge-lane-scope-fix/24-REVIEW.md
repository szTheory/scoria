---
phase: 24-knowledge-lane-scope-fix
reviewed: 2026-06-15T21:05:49Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - lib/mix/tasks/scoria.test.knowledge.ex
  - test/test_helper.exs
  - test/scoria/knowledge_lane_contract_test.exs
findings:
  critical: 0
  warning: 4
  info: 4
  total: 8
status: issues_found
---

# Phase 24: Code Review Report

**Reviewed:** 2026-06-15T21:05:49Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Reviewed the knowledge-lane scope fix: the `mix test.knowledge` task (now scoping to `--only knowledge`, exposing a `knowledge_test_files/0` accessor, and ordering migrations), the `test_helper.exs` exclude-tag logic plus the after_suite zero-test guard, and the new lane-contract test.

No critical security or data-loss defects were found. The migration-ordering concern (migrations run before `app.start`) is actually safe because `scoria.pgvector.bootstrap` itself calls `Mix.Task.run("app.start")` before the migration calls execute. However, that safety is *implicit and undocumented*, and several real robustness/maintainability defects exist: the after_suite guard can misfire and abort an entire suite under common conditions, the hardcoded contract list duplicates the production glob (the very brittleness the test claims to prevent), and a vendored fixture copy of the task has silently diverged.

## Warnings

### WR-01: after_suite zero-test guard hard-aborts on any run that excludes knowledge tests while the env var is set

**File:** `test/test_helper.exs:27-34`
**Issue:** The guard fires whenever `SCORIA_TEST_INCLUDE_KNOWLEDGE=true` and `total == 0`. `total` in the `after_suite` map is the count of tests that *ran*, which is reduced by any `--only`/`--exclude`/file/line filtering applied to that invocation. Because the env var is process-global and is set via `System.put_env` (WR-04), any developer who exports it in their shell — or any tool that invokes a filtered run after it is set — will get the whole suite aborted with `exit({:shutdown, 1})` even though nothing is broken. Example: `SCORIA_TEST_INCLUDE_KNOWLEDGE=true mix test test/scoria/some_other_test.exs:10` where that line matches no test ⇒ `total == 0` ⇒ false-positive "possible tag loss" and a non-zero exit. The guard is meant to detect *tag loss inside the knowledge lane*, but it keys off a coarse global signal rather than the actual lane invocation.
**Fix:** Gate the guard on a signal that uniquely identifies the canonical lane run, not merely the env var. Simplest: set a distinct sentinel only in the task (e.g. `SCORIA_KNOWLEDGE_LANE_ACTIVE=1`) and check it here; or check that no positional/`--only`/`--exclude` filters narrowing the run were passed. At minimum, only treat `total == 0` as fatal when the lane was invoked with exactly `--only knowledge` and no additional filters:
```elixir
# task sets a dedicated marker; helper trusts only that
if System.get_env("SCORIA_KNOWLEDGE_LANE_ACTIVE") == "1" do
  ExUnit.after_suite(fn %{total: total} ->
    if total == 0 do
      IO.puts(:stderr, "[knowledge lane] after_suite: 0 tests executed — possible tag loss")
      exit({:shutdown, 1})
    end
  end)
end
```

### WR-02: Contract test duplicates the production glob as a hardcoded list, defeating its own stated purpose

**File:** `test/scoria/knowledge_lane_contract_test.exs:6-13, 20-23`
**Issue:** `@expected_files` is a hand-maintained copy of what `knowledge_test_files/0` already computes via `Path.wildcard`. The test asserts `actual == @expected_files`, so the only thing it verifies is that someone remembered to edit two places in lockstep. The accessor it guards is a *compile-time* module attribute (`@knowledge_test_files`, lines 6-9 of the task) — `Path.wildcard` runs at compile time, so a freshly added knowledge test file will not appear in `actual` until the task module is recompiled. In a stale-build scenario the test can fail (or pass spuriously) for reasons unrelated to whether the lane is correctly scoped. The test claims to protect against "file set changed" drift but cannot distinguish an intentional addition from a recompilation gap, and forces a manual edit on every legitimate change.
**Fix:** Assert the *invariant* rather than a frozen snapshot. Verify that the accessor returns exactly the files under the knowledge directories that `use Scoria.KnowledgeCase`, computed independently in the test, and that the count is non-zero:
```elixir
expected =
  (Path.wildcard("test/scoria/knowledge_test.exs") ++
     Path.wildcard("test/scoria/knowledge/**/*_test.exs"))
  |> Enum.sort()

assert expected != []
assert Mix.Tasks.Scoria.Test.Knowledge.knowledge_test_files() == expected
```
If a frozen list is intentionally desired as a ratchet, document that the manual update is required and explain why a recomputed invariant is insufficient.

### WR-03: Vendored fixture copy of the task has silently diverged from the production task

**File:** `test/fixtures/hex_consumer/scoria-0.1.0-unpack/lib/mix/tasks/scoria.test.knowledge.ex` (vs `lib/mix/tasks/scoria.test.knowledge.ex`)
**Issue:** The hex-consumer fixture ships an older copy of this task that runs `Mix.Task.run("test", args)` with no `--only knowledge` scoping and no `knowledge_test_files/0` accessor. The contract test only inspects the production module, so this divergence is invisible to CI. If any fixture-driven test exercises the packaged task, it will exhibit the pre-fix (unscoped) behavior — the exact bug this phase set out to fix — while the suite reports green. This is a correctness-of-shipped-artifact risk masked by incomplete coverage.
**Fix:** Determine whether the fixture is meant to mirror the published package. If yes, regenerate/sync it so the packaged task matches the fixed source, and add a check that the fixture copy is byte-identical to (or generated from) the canonical task. If the fixture is an intentionally pinned historical snapshot, add a comment documenting that and confirm no test relies on its knowledge-lane behavior.

### WR-04: `System.put_env` mutates process-global state with no restoration, leaking across invocations

**File:** `lib/mix/tasks/scoria.test.knowledge.ex:18`
**Issue:** `System.put_env("SCORIA_TEST_INCLUDE_KNOWLEDGE", "true")` sets a global env var for the lifetime of the OS process and is never reset. Within a single `mix` invocation this is fine, but it is fragile in any context where Mix tasks are chained in one BEAM (e.g. an umbrella alias or a composite `mix do test.knowledge, test`): the second task inherits the flag, un-excludes `:knowledge`, and — combined with WR-01 — can trigger the after_suite abort or run knowledge tests unintentionally. There is no `try/after` to restore the prior value.
**Fix:** Prefer passing the include signal through the test invocation rather than mutating global state, or capture and restore:
```elixir
prev = System.get_env("SCORIA_TEST_INCLUDE_KNOWLEDGE")
System.put_env("SCORIA_TEST_INCLUDE_KNOWLEDGE", "true")
try do
  # ... run test ...
after
  case prev do
    nil -> System.delete_env("SCORIA_TEST_INCLUDE_KNOWLEDGE")
    v -> System.put_env("SCORIA_TEST_INCLUDE_KNOWLEDGE", v)
  end
end
```

## Info

### IN-01: Implicit dependency on `app.start` ordering is undocumented

**File:** `lib/mix/tasks/scoria.test.knowledge.ex:20-23`
**Issue:** `migrate_core!/0` and `migrate_knowledge!/0` use `Scoria.Repo`/`Ecto.Migrator`, which require the `:scoria` app and Repo to be running. They are called *before* the `test` task (line 26) starts the app. This only works because `scoria.pgvector.bootstrap` (line 20) internally calls `Mix.Task.run("app.start")`. If the bootstrap step is ever reordered, made conditional, or stops starting the app, migrations will crash with a confusing Repo-not-started error.
**Fix:** Add a comment noting the dependency, or make it explicit with `Mix.Task.run("app.start")` immediately before the migration calls (it is reenabled at line 17, so an explicit call is cheap and self-documenting).

### IN-02: `Mix.Task.reenable("app.start")` is dead/unused in this task

**File:** `lib/mix/tasks/scoria.test.knowledge.ex:17`
**Issue:** `app.start` is reenabled but never directly invoked by this task; it is run as a side effect of `scoria.pgvector.bootstrap` (line 20) and again by `test` (line 26). The reenable here is defensive but its purpose is non-obvious and reads as dead code.
**Fix:** Either remove the line or add a one-line comment explaining it guards against a prior `app.start` invocation having consumed the task in the same `mix` session.

### IN-03: `--only knowledge` is prepended ahead of user args, which can surprise filter composition

**File:** `lib/mix/tasks/scoria.test.knowledge.ex:26`
**Issue:** `["--only", "knowledge" | args]` always injects `--only knowledge` first. ExUnit ORs multiple `--only` filters, so `mix test.knowledge --only slow` runs knowledge OR slow tests rather than the intersection a user might expect. This is not a bug for the canonical no-arg invocation but is a mild footgun for pass-through usage.
**Fix:** Document in `@shortdoc`/moduledoc that the lane forces `--only knowledge` and that user-supplied `--only` is additive, or detect a user-supplied `--only` and skip the injection.

### IN-04: Lane-contract test asserts list membership without asserting prerequisites are non-empty / well-formed

**File:** `test/scoria/knowledge_lane_contract_test.exs:34-36`
**Issue:** The second test checks the command string and that `"mix scoria.pgvector.bootstrap"` is a member of `prerequisites(:knowledge)`, but does not guard against the list being malformed or the lane id being absent (a wrong id would raise a `Map.fetch!` KeyError rather than a clear assertion failure). Minor robustness gap in an otherwise reasonable contract test.
**Fix:** Optionally assert `VerificationLanes.prerequisites(:knowledge)` is a non-empty list and that `:knowledge in VerificationLanes.ids()` for a clearer failure message if the lane is renamed/removed.

---

_Reviewed: 2026-06-15T21:05:49Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
