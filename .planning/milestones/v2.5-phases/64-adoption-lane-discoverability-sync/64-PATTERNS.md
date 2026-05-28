# Phase 64 — Pattern Map

**Phase:** 64 — Adoption Lane Discoverability Sync  
**Generated:** 2026-05-27

## Role Classification

| File | Role | Action |
|------|------|--------|
| `lib/mix/tasks/test.adoption.ex` | Lane SSOT (`@adoption_test_files`) | Read-only reference |
| `test/mix/tasks/test.adoption_test.exs` | Discoverability contract test | **Modify** `expected_files` |
| `test/mix/tasks/test.semantic_fast_path_test.exs` | Analog pattern | Read-only |
| `test/scoria/verification_lanes_test.exs` | Closeout order guard | Verify only |

## Analog: Semantic fast-path discoverability (read-only)

```elixir
assert Mix.Tasks.Scoria.Test.SemanticFastPath.semantic_fast_path_test_files() ==
         expected_files
```

Same shape as adoption: hard-coded `expected_files` must equal module `*_test_files/0`.

## Analog: Adoption lane SSOT (do not edit in this phase)

```elixir
# lib/mix/tasks/test.adoption.ex — authoritative list
@adoption_test_files [
  # ...
  "test/scoria/install/planner_test.exs",
  "test/scoria/install/report_test.exs",
  "test/scoria/install/mode_equivalence_test.exs",
  "test/scoria/bootstrap/migration_lane_compatibility_test.exs"
]
```

## Target change (test mirror)

Insert after `planner_test.exs` in `test/mix/tasks/test.adoption_test.exs`:

```elixir
"test/scoria/install/report_test.exs",
"test/scoria/install/mode_equivalence_test.exs",
```

## PATTERN MAPPING COMPLETE
