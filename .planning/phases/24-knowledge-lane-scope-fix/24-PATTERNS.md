# Phase 24: Knowledge Lane Scope Fix - Pattern Map

**Mapped:** 2026-06-15
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/scoria.test.knowledge.ex` | mix-task | request-response (task composition) | `lib/mix/tasks/test.adoption.ex` | exact |
| `test/test_helper.exs` | config/bootstrap | event-driven (after_suite hook) | itself — existing env-gate pattern on lines 11–22 | self-analog |
| `test/scoria/knowledge_lane_contract_test.exs` | test (contract) | batch (file-set inspection) | `test/mix/tasks/test.adoption_test.exs` | exact |

---

## Pattern Assignments

### `lib/mix/tasks/scoria.test.knowledge.ex` (mix-task, task composition)

**Analog:** `lib/mix/tasks/test.adoption.ex`

**Current file state** (`lib/mix/tasks/scoria.test.knowledge.ex`, lines 1–31):
```elixir
defmodule Mix.Tasks.Scoria.Test.Knowledge do
  use Mix.Task

  @shortdoc "Runs the canonical optional knowledge verification lane"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("loadpaths")
    Mix.Task.reenable("scoria.pgvector.bootstrap")
    Mix.Task.reenable("app.start")
    System.put_env("SCORIA_TEST_INCLUDE_KNOWLEDGE", "true")   # line 11 — keep unchanged

    Mix.Task.run("scoria.pgvector.bootstrap")

    Scoria.TestSupport.Migrations.migrate_core!()
    Scoria.TestSupport.Migrations.migrate_knowledge!()

    Mix.Task.reenable("test")
    Mix.Task.run("test", args)   # line 19 — BUG: no tag filter
  end
end
```

**Accessor pattern to copy from analog** (`lib/mix/tasks/test.adoption.ex`, lines 5–21):
```elixir
# compile-time module attribute — evaluated once, exposed as public function
@adoption_test_files [
  "test/scoria_test.exs",
  ...
]

def adoption_test_files, do: @adoption_test_files
```

**D-01 change — line 19 fix:**
```elixir
# BEFORE:
Mix.Task.run("test", args)

# AFTER:
Mix.Task.run("test", ["--only", "knowledge" | args])
```

**D-03 addition — module attribute + accessor (place after `@shortdoc`, before `@impl`):**
```elixir
@knowledge_test_files (
  Path.wildcard("test/scoria/knowledge_test.exs") ++
  Path.wildcard("test/scoria/knowledge/**/*_test.exs")
) |> Enum.sort()

def knowledge_test_files, do: @knowledge_test_files
```

**Key difference from adoption analog:** Adoption uses a static list literal (`@adoption_test_files [...]`); knowledge uses `Path.wildcard` at compile time so future `use Scoria.KnowledgeCase` files are auto-discovered. The `|> Enum.sort()` call ensures a deterministic sort for the ratchet assertion in the contract test.

**Wrapper module** (lines 23–30 of the current file) — unchanged, copy as-is:
```elixir
defmodule Mix.Tasks.Test.Knowledge do
  use Mix.Task

  @shortdoc "Compatibility wrapper for the canonical optional knowledge verification lane"

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Scoria.Test.Knowledge.run(args)
end
```

---

### `test/test_helper.exs` (config/bootstrap, event-driven hook)

**Self-analog:** The existing env-gate idiom already in the file (lines 11–22) is the pattern to match for D-02.

**Existing env-gate pattern** (`test/test_helper.exs`, lines 11–22):
```elixir
excluded_tags =
  []
  |> then(fn tags ->
    if System.get_env("SCORIA_TEST_INCLUDE_KNOWLEDGE") == "true", do: tags, else: [{:knowledge, true} | tags]
  end)
  |> then(fn tags ->
    if System.get_env("SCORIA_TEST_INCLUDE_REGISTRY") == "true",
      do: tags,
      else: [{:registry_proof, true}, {:registry_upgrade, true} | tags]
  end)

ExUnit.start(exclude: excluded_tags)   # line 22 — after_suite block goes AFTER this line
```

**D-02 addition — place immediately after `ExUnit.start(exclude: excluded_tags)` on line 22:**
```elixir
if System.get_env("SCORIA_TEST_INCLUDE_KNOWLEDGE") == "true" do
  ExUnit.after_suite(fn %{total: total} ->
    if total == 0 do
      IO.puts(:stderr, "[knowledge lane] after_suite: 0 tests executed — possible tag loss")
      exit({:shutdown, 1})
    end
  end)
end
```

**Critical constraints:**
- Gate string `"SCORIA_TEST_INCLUDE_KNOWLEDGE"` must match line 14 exactly — same env var, same `== "true"` comparison
- Block MUST come after `ExUnit.start/1` — `after_suite/1` reads from app env initialized by `start/1`; placing it before raises `ArgumentError`
- Use `exit({:shutdown, 1})` — mirrors ExUnit's own failure mechanism
- Assert `total > 0` NOT a numeric threshold — threshold rots; D-03 contract test handles the ratchet

---

### `test/scoria/knowledge_lane_contract_test.exs` (test/contract, batch file-set inspection)

**Primary analog:** `test/mix/tasks/test.adoption_test.exs`
**Secondary analog:** `test/scoria/verification_lanes_test.exs` and `test/scoria/ci_policy_contract_test.exs` for module header and `async: true` convention.

**Module header + async pattern** (all sibling contract tests use this — e.g., `test/mix/tasks/test.adoption_test.exs` line 1–3, `test/scoria/verification_lanes_test.exs` line 1–3):
```elixir
defmodule Scoria.KnowledgeLaneContractTest do
  use ExUnit.Case, async: true

  alias Scoria.VerificationLanes
```

**File-set assertion pattern from analog** (`test/mix/tasks/test.adoption_test.exs`, lines 5–50):
```elixir
test "the adoption lane is discoverable and targets the bounded default-suite subset" do
  Mix.Task.load_all()

  expected_files = [
    "test/scoria_test.exs",
    ...
  ]

  assert Code.ensure_loaded?(Mix.Tasks.Scoria.Test.Adoption)
  assert function_exported?(Mix.Tasks.Scoria.Test.Adoption, :run, 1)
  assert function_exported?(Mix.Tasks.Scoria.Test.Adoption, :adoption_test_files, 0)
  assert function_exported?(Mix.Tasks.Test.Adoption, :run, 1)
  assert Mix.Tasks.Scoria.Test.Adoption.adoption_test_files() == expected_files
  assert VerificationLanes.command(:adoption) == "mix test.adoption"
  ...
end
```

**D-03 file — full shape to implement** (derived from adoption analog + KnowledgeCase choke-point assertion):

```elixir
defmodule Scoria.KnowledgeLaneContractTest do
  use ExUnit.Case, async: true

  alias Scoria.VerificationLanes

  @expected_files [
    "test/scoria/knowledge/citation_formatter_test.exs",
    "test/scoria/knowledge/grounding_test.exs",
    "test/scoria/knowledge/pgvector_test.exs",
    "test/scoria/knowledge/retrieval_test.exs",
    "test/scoria/knowledge/scrypath_test.exs",
    "test/scoria/knowledge_test.exs"
  ]

  test "knowledge lane file set is stable and every file uses Scoria.KnowledgeCase" do
    Mix.Task.load_all()

    assert function_exported?(Mix.Tasks.Scoria.Test.Knowledge, :knowledge_test_files, 0)

    actual = Mix.Tasks.Scoria.Test.Knowledge.knowledge_test_files()
    assert actual == @expected_files,
           "Knowledge file set changed — update @expected_files if intentional"

    for path <- actual do
      content = File.read!(path)
      assert content =~ "use Scoria.KnowledgeCase",
             "#{path} must use Scoria.KnowledgeCase to carry the :knowledge tag"
    end
  end

  test "knowledge lane command is discoverable and prerequisites reference pgvector" do
    assert VerificationLanes.command(:knowledge) == "mix test.knowledge"
    assert "mix scoria.pgvector.bootstrap" in VerificationLanes.prerequisites(:knowledge)
  end
end
```

**`@expected_files` ordering:** The list is sorted (alphabetical within the `knowledge/` subdirectory, then `knowledge_test.exs` last because `knowledge/` < `knowledge_test.exs` lexicographically). This matches what `Path.wildcard(...) |> Enum.sort()` produces — verified in RESEARCH.md Mechanic 4.

**Why `function_exported?` not `Code.ensure_loaded?`:** The adoption test uses `Code.ensure_loaded?(Mix.Tasks.Scoria.Test.Adoption)` AND `function_exported?(..., :adoption_test_files, 0)`. For the knowledge contract test, `function_exported?` alone is sufficient since `Mix.Task.load_all()` forces loading; prefer the leaner form matching the critical assertion.

**`async: true` rationale:** Test uses only `File.read!` and module reflection — no DB, no Ecto sandbox, no app state. Matches all sibling contract tests (`adoption_test.exs`, `ci_policy_contract_test.exs`, `verification_lanes_test.exs`). No `@moduletag` or `use Scoria.KnowledgeCase` — this file must NOT carry the `:knowledge` tag or it would falsely add itself to the knowledge lane file set and break the ratchet.

---

## Shared Patterns

### Env-Gate Convention
**Source:** `test/test_helper.exs` lines 13–14 and lines 17–18
**Apply to:** D-02 `after_suite` block
```elixir
if System.get_env("SCORIA_TEST_INCLUDE_KNOWLEDGE") == "true", do: tags, else: ...
```
The `== "true"` string comparison (not truthy check) is the established idiom throughout the file. D-02's gate must use identical form.

### `Mix.Task.load_all()` Before Module Assertions
**Source:** `test/mix/tasks/test.adoption_test.exs` line 6
**Apply to:** Both tests in `knowledge_lane_contract_test.exs` that call module functions
```elixir
Mix.Task.load_all()
```
Required so `Mix.Tasks.Scoria.Test.Knowledge` is compiled and loaded before `function_exported?` or direct function calls.

### `VerificationLanes.command/1` Lane String Pin
**Source:** `test/mix/tasks/test.adoption_test.exs` line 29
**Apply to:** Second test in `knowledge_lane_contract_test.exs`
```elixir
assert VerificationLanes.command(:adoption) == "mix test.adoption"
# mirrors to:
assert VerificationLanes.command(:knowledge) == "mix test.knowledge"
```
Note: `VerificationLanes.command/1` returns the bare command (no `--warnings-as-errors`); `ci_command/1` adds the WAE flag. The YAML contract string `"mix test.knowledge --warnings-as-errors"` is asserted in `ci_policy_contract_test.exs` and `verification_lanes_test.exs` — those files are NOT touched by this phase.

---

## No Analog Found

All three files have strong analogs. No entries.

---

## Metadata

**Analog search scope:** `lib/mix/tasks/`, `test/mix/tasks/`, `test/scoria/`, `test/test_helper.exs`, `test/support/`
**Files read:** 8 (`test.adoption.ex`, `test.adoption_test.exs`, `scoria.test.knowledge.ex`, `test_helper.exs`, `knowledge_case.exs`, `ci_policy_contract_test.exs`, `verification_lanes_test.exs`)
**Pattern extraction date:** 2026-06-15
