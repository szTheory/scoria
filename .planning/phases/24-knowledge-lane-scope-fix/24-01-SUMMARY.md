---
phase: 24-knowledge-lane-scope-fix
plan: 01
subsystem: test-toolchain
tags: [knowledge-lane, mix-task, exunit, ci-velocity, contract-test]

dependency_graph:
  requires: []
  provides:
    - "mix test.knowledge --only knowledge scoping (D-01)"
    - "knowledge_test_files/0 accessor on Mix.Tasks.Scoria.Test.Knowledge"
    - "ExUnit.after_suite Layer 2 zero-test guard (D-02)"
    - "Scoria.KnowledgeLaneContractTest file-set ratchet + use KnowledgeCase choke-point (D-03)"
  affects:
    - lib/mix/tasks/scoria.test.knowledge.ex
    - test/test_helper.exs
    - test/scoria/knowledge_lane_contract_test.exs

tech_stack:
  added: []
  patterns:
    - "env-gated ExUnit.after_suite/1 zero-test guard after ExUnit.start/1"
    - "Path.wildcard compile-time module attribute for derived file-set accessor"
    - "contract test asserting derived file set == expected sorted set + use KnowledgeCase"

key_files:
  created:
    - test/scoria/knowledge_lane_contract_test.exs
  modified:
    - lib/mix/tasks/scoria.test.knowledge.ex
    - test/test_helper.exs

decisions:
  - "D-01: prepend [\"--only\", \"knowledge\"] in Mix.Task.run call (filter first, args appended)"
  - "D-02: Layer 2 after_suite guard gated on SCORIA_TEST_INCLUDE_KNOWLEDGE==true asserting total > 0"
  - "D-03: Path.wildcard derived accessor knowledge_test_files/0; contract test pins sorted file set == 6 known paths and each carries use Scoria.KnowledgeCase"
  - "CI YAML contract string and VerificationLanes command records intentionally untouched (SC#2/SC#4)"

metrics:
  duration: "~10 min"
  completed: "2026-06-15T21:01:11Z"
  tasks_completed: 2
  files_changed: 3
---

# Phase 24 Plan 01: Knowledge Lane Scope Fix Summary

**One-liner:** Scoped the CI knowledge lane to `--only knowledge` via Mix task arg injection, backed by an env-gated `after_suite` zero-test guard and a file-set ratchet contract test with `use Scoria.KnowledgeCase` choke-point enforcement.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Scope mix test invocation, add accessor, arm Layer 2 guard | `dcbb535` | `lib/mix/tasks/scoria.test.knowledge.ex`, `test/test_helper.exs` |
| 2 | Add derived-file-set coverage contract test (D-03) | `a4dd664` | `test/scoria/knowledge_lane_contract_test.exs` |

## What Was Built

**Task 1 — Three changes across two files (D-01, D-02, D-03 accessor):**

1. **D-01 (`scoria.test.knowledge.ex` line 19):** Changed `Mix.Task.run("test", args)` to `Mix.Task.run("test", ["--only", "knowledge" | args])`. Filter first, caller args appended. `SCORIA_TEST_INCLUDE_KNOWLEDGE=true` at line 11 kept unchanged (required to prevent `test_helper.exs:14` pre-excluding `{:knowledge, true}` before `--only` can include it).

2. **D-03 accessor (`scoria.test.knowledge.ex`):** Added `@knowledge_test_files` module attribute derived via `Path.wildcard("test/scoria/knowledge_test.exs") ++ Path.wildcard("test/scoria/knowledge/**/*_test.exs") |> Enum.sort()` plus public `knowledge_test_files/0`. Placed after `@shortdoc`, before `@impl Mix.Task` — mirrors adoption analog placement. Derived at compile time, not hardcoded.

3. **D-02 Layer 2 (`test_helper.exs`):** Added env-gated `ExUnit.after_suite/1` block immediately after `ExUnit.start(exclude: excluded_tags)`. Only arms when `SCORIA_TEST_INCLUDE_KNOWLEDGE == "true"`. Asserts `total > 0`, exits via `exit({:shutdown, 1})` on zero tests. Gate prevents false-trips on normal `mix test` or the policy job's `--no-start` run.

**Task 2 — New contract test file:**

`test/scoria/knowledge_lane_contract_test.exs` (`Scoria.KnowledgeLaneContractTest`, `use ExUnit.Case, async: true`) with two tests:
- **Test 1 (file-set ratchet + choke point):** Calls `Mix.Task.load_all()`, asserts `function_exported?/3` for `knowledge_test_files/0`, asserts `knowledge_test_files() == @expected_files` (the 6 sorted paths), and for each path asserts `content =~ "use Scoria.KnowledgeCase"`.
- **Test 2 (lane-shape pin):** Asserts `VerificationLanes.command(:knowledge) == "mix test.knowledge"` and `"mix scoria.pgvector.bootstrap" in VerificationLanes.prerequisites(:knowledge)`.

File does NOT `use Scoria.KnowledgeCase` and carries no `@tag :knowledge` / `@moduletag :knowledge` — it would otherwise add itself to the derived file set and break its own ratchet.

## Verification Results

| Check | Command | Result |
|-------|---------|--------|
| SC#1 (compile) | `mix compile --warnings-as-errors` | PASS |
| SC#1 proxy (contract test) | `mix test test/scoria/knowledge_lane_contract_test.exs` | 2 tests, 0 failures |
| SC#2 (CI YAML unchanged) | `git diff --quiet -- .github/workflows/ci-verify.yml` | PASS — exit 0 |
| SC#3 (scoped run >0 tests) | `SCORIA_TEST_INCLUDE_KNOWLEDGE=true mix test --only knowledge` | 13 tests, 0 failures (732 excluded) |
| SC#4 (contract tests green) | `mix test test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` | 42 tests, 0 failures |

## Deviations from Plan

None — plan executed exactly as written. The three interlocking decisions (D-01, D-02, D-03) were implemented per the locked CONTEXT.md decisions and PATTERNS.md literal forms.

## Known Stubs

None.

## Threat Flags

None — test-infrastructure-only change. No new trust boundaries introduced.

## Self-Check: PASSED

- `lib/mix/tasks/scoria.test.knowledge.ex` — exists, modified
- `test/test_helper.exs` — exists, modified
- `test/scoria/knowledge_lane_contract_test.exs` — exists, created
- `dcbb535` — confirmed in git log
- `a4dd664` — confirmed in git log
