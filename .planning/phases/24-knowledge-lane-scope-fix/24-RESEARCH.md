# Phase 24: Knowledge Lane Scope Fix — Research

**Researched:** 2026-06-15
**Domain:** ExUnit tag filtering mechanics / Mix task composition / CI contract tests
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01 — Selection mechanism: `--only knowledge`, hardcoded in the task**
- Change `scoria.test.knowledge.ex:19` from `Mix.Task.run("test", args)` to
  `Mix.Task.run("test", ["--only", "knowledge" | args])`.
- Filter first, `args` appended — lets callers pass `--seed`, `--max-failures`, `file:line`
  without fighting the tag filter.
- Keep `SCORIA_TEST_INCLUDE_KNOWLEDGE=true` (line 11) — STILL REQUIRED.
- Tag-based, not explicit file list. Auto-includes future `use Scoria.KnowledgeCase` files.

**D-02 — Zero-test safety net: both layers**
- Layer 1 (built-in): D-01 arms ExUnit's built-in guard — empty `--only` exits non-zero.
  Fires because `Mix.Task.recursing?()` is false (non-umbrella).
- Layer 2 (belt-and-suspenders): env-gated `ExUnit.after_suite/1` in `test_helper.exs`
  asserting `total > 0`, only armed when `SCORIA_TEST_INCLUDE_KNOWLEDGE == "true"`.
  Exit via `exit({:shutdown, 1})`. Covers partial-loss that Layer 1 misses.

**D-03 — Coverage-preservation proof (SC#3): derived file-set contract test**
- New `test/scoria/knowledge_lane_contract_test.exs` mirroring the `adoption_test_files/0`
  precedent.
- Expose `knowledge_test_files/0` derived via `Path.wildcard` over the two known locations.
- Assert sorted set == the 6 known files (ratchet).
- Assert each file `=~ "use Scoria.KnowledgeCase"` (single-choke-point enforcement).

### Claude's Discretion
- Exact placement/wording of `after_suite` guard and contract-test file name.
- Whether to add optional grep-guard CI step vs. folding single-choke-point enforcement
  entirely into the D-03 contract test.

### Deferred Ideas (OUT OF SCOPE)
- `--partitions` zero-shard guarding (Phase 26).
- No scope creep beyond the phase boundary.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| KNOW-01 | The knowledge verification lane runs only knowledge-tagged tests (e.g. `--only knowledge`), not the full suite, while preserving the same warnings-as-errors bar and the `mix test.knowledge --warnings-as-errors` contract string. | D-01 mechanism confirmed mechanically valid in Elixir 1.19.5; Layer 1 and Layer 2 guards verified against live ExUnit API; D-03 wildcard pattern returns correct 6 files. |
</phase_requirements>

---

## Summary

Phase 24 is a tight, mechanical fix with three interlocking changes. Every decision was pre-locked after two research rounds; this round's job is to verify the mechanics those decisions depend on against the live codebase and current ExUnit/Mix API, and to surface planning landmines.

**The bug is confirmed.** `lib/mix/tasks/scoria.test.knowledge.ex:19` runs `Mix.Task.run("test", args)` — a bare delegation that passes no tag filter. The task sets `SCORIA_TEST_INCLUDE_KNOWLEDGE=true` at line 11, which un-excludes `:knowledge` from the `test_helper.exs:14` guard, and the whole suite plus knowledge tests runs. The fix is a one-character-level change: prepend `["--only", "knowledge"]` to `args`.

All three ExUnit/Mix mechanics check out against the live API (Elixir 1.19.5-otp-27): `--only` hardcoding arms the built-in Layer 1 guard with the documented exact error string; `ExUnit.after_suite/1` exists with the `suite_result` map containing `total`; `Mix.Task.recursing?()` is false in this non-umbrella project so Layer 1's `System.at_exit` path fires; and the `Path.wildcard` patterns for D-03 return exactly the 6 expected files (verified by running them).

**Primary recommendation:** Implement D-01 + D-02 + D-03 as a single atomic commit. The changes touch 4 files: `scoria.test.knowledge.ex` (1-line arg change), `test_helper.exs` (after_suite block), `scoria.test.knowledge.ex` again to add `knowledge_test_files/0`, and a new `test/scoria/knowledge_lane_contract_test.exs`. The CI YAML and VerificationLanes contract string remain untouched.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Tag-based test selection (`--only knowledge`) | Mix task (knowledge task internals) | ExUnit runner | The filter arg is injected at the Mix task layer; ExUnit runner processes it |
| Pre-exclusion guard (`SCORIA_TEST_INCLUDE_KNOWLEDGE`) | test_helper.exs | — | Must remain in test bootstrap so ExUnit.start receives the corrected exclude list |
| Zero-test Layer 1 guard (built-in `--only` empty fail) | Mix task runner (`mix test` internals) | — | Automatic; armed by the D-01 arg injection |
| Zero-test Layer 2 guard (`after_suite total > 0`) | test_helper.exs | — | Belt-and-suspenders hook registered in test bootstrap; env-gated so normal `mix test` is unaffected |
| Coverage-preservation proof (D-03 contract test) | test/scoria/ (ExUnit contract tests) | scoria.test.knowledge.ex (exposes `knowledge_test_files/0`) | Same tier as `ci_policy_contract_test` and `verification_lanes_test` |
| CI contract string (`mix test.knowledge --warnings-as-errors`) | `.github/workflows/ci-verify.yml:188` | — | Intentionally untouched by D-01; filter is injected INSIDE the task, never in YAML |

---

## Standard Stack

No new external packages are introduced. This phase works entirely within:

| Component | Version | Role |
|-----------|---------|------|
| Elixir | 1.19.5-otp-27 (`.tool-versions`) | Runtime |
| ExUnit | (stdlib; same as Elixir) | Test framework |
| Mix | (stdlib; same as Elixir) | Task runner |

**No `npm install`, `mix deps.get`, or package changes needed.** [VERIFIED: local .tool-versions + `elixir --version`]

---

## Package Legitimacy Audit

Not applicable — no external packages are installed in this phase.

---

## Architecture Patterns

### System Architecture Diagram

```
mix test.knowledge --warnings-as-errors (ci-verify.yml:188, UNCHANGED)
         |
         v
Mix.Tasks.Scoria.Test.Knowledge.run/1
         |
         +-- System.put_env("SCORIA_TEST_INCLUDE_KNOWLEDGE", "true")   [line 11, unchanged]
         |
         +-- scoria.pgvector.bootstrap
         +-- migrate_core! / migrate_knowledge!
         |
         v
Mix.Task.run("test", ["--only", "knowledge" | args])        [line 19, CHANGED]
         |
         v
mix test --only knowledge [--warnings-as-errors ...]
         |
         v
test_helper.exs boots
   +-- SCORIA_TEST_INCLUDE_KNOWLEDGE=true → skip {:knowledge, true} pre-exclusion [line 14]
   +-- ExUnit.start(exclude: [{:registry_proof, true}, {:registry_upgrade, true}])
   +-- after_suite guard armed (SCORIA_TEST_INCLUDE_KNOWLEDGE=true) [NEW Layer 2]
         |
         v
ExUnit runner processes --only knowledge
   → exclude: [:test | existing_excludes]
   → include: [knowledge: true]
   → includes evaluated before excludes
         |
         v
Only 6 knowledge-tagged files run (via @moduletag :knowledge in KnowledgeCase)
         |
         v
after_suite callback fires
   → assert total > 0 or exit({:shutdown, 1})
```

### Recommended Project Structure (changed files only)

```
lib/mix/tasks/
└── scoria.test.knowledge.ex    # CHANGE: line 19 arg injection + add knowledge_test_files/0

test/
├── test_helper.exs             # CHANGE: add env-gated after_suite block
└── scoria/
    └── knowledge_lane_contract_test.exs  # NEW (D-03)
```

---

## Key Mechanics Verified

### Mechanic 1: `--only knowledge` include/exclude ordering

**Claim:** When `--only knowledge` is used, Mix.Tasks.Test produces `include: [knowledge: true]` and appends `:test` to the exclude list. Includes are evaluated before excludes.

**Verified against:** Official Mix.Tasks.Test source (GitHub `main`): [CITED: github.com/elixir-lang/elixir/blob/main/lib/mix/lib/mix/tasks/test.ex]

```elixir
# From Mix.Tasks.Test source (verified)
case only ++ name_patterns do
  [] -> opts
  filters ->
    opts
    |> Keyword.update(:include, filters, &(filters ++ &1))
    |> Keyword.update(:exclude, [:test], &[:test | &1])
end
```

**Why `SCORIA_TEST_INCLUDE_KNOWLEDGE=true` is still required (non-obvious):** Without this env, `test_helper.exs:14` passes `exclude: [{:knowledge, true}]` to `ExUnit.start/1`. ExUnit resolves filters at test-load time: an existing excludes entry `{:knowledge, true}` would still pre-exclude `:knowledge` tests before `--only` can include them. Setting the env empties that slot so the exclude list handed to `ExUnit.start` omits `{:knowledge, true}`, leaving `--only knowledge` free to include them via `include: [knowledge: true]`. [VERIFIED: test_helper.exs:14 read directly]

**Issue #3940 relevance assessment:** The 2015 bug was triggered by bare atoms in `exclude` (`ExUnit.start(exclude: :this)`). The current `test_helper.exs` uses keyword tuple form (`{:knowledge, true}`), which is the normalized shape. This is a **different code path** and the bug has been irrelevant since at least Elixir 1.2. No action required. [CITED: github.com/elixir-lang/elixir/issues/3940 + local code verification]

### Mechanic 2: Layer 1 empty `--only` fail guard

**Claim:** When `--only knowledge` is passed and zero tests execute, Mix exits non-zero automatically.

**Exact error message** (from Mix.Tasks.Test source): [CITED: mix.hexdocs.pm/Mix.Tasks.Test.html]

```
The --only option was given to "mix test" but no test was executed
```

**Exit path:** The `nothing_executed/3` function calls `raise_or_error_at_exit/3`. Without `--raise` flag, it uses `System.at_exit/1` to schedule exit code 1. When `Mix.Task.recursing?()` is **true** (umbrella projects only), it logs but does not exit. Since Scoria is NOT an umbrella project, `recursing?()` always returns false here, so the exit fires. [CITED: mix.hexdocs.pm/Mix.Task.html, github.com/elixir-lang/elixir/blob/main/lib/mix/lib/mix/tasks/test.ex]

**Important:** This guard fires only on TOTAL tag loss (all 6 files lose the tag). It does NOT fire on partial loss (e.g., 5-of-6 files still tagged). This is why Layer 2 is needed.

### Mechanic 3: Layer 2 `ExUnit.after_suite/1` guard

**API verified against Elixir 1.19.5:** [CITED: ex-unit.hexdocs.pm/1.19.5/ExUnit.html]

```elixir
@spec after_suite((suite_result() -> any())) :: :ok

@type suite_result :: %{
  excluded: non_neg_integer,
  failures: non_neg_integer,
  skipped: non_neg_integer,
  total: non_neg_integer
}
```

`ExUnit.after_suite/1` exists and takes a 1-arity function. Multiple callbacks execute in reverse registration order (last registered runs first). [VERIFIED: `mix run -e 'ExUnit.after_suite(:ok)'` confirmed the function clause and signature live]

**Implementation pattern for `test_helper.exs`:**

```elixir
# Place AFTER ExUnit.start call (after line 22 in current test_helper.exs)
if System.get_env("SCORIA_TEST_INCLUDE_KNOWLEDGE") == "true" do
  ExUnit.after_suite(fn %{total: total} ->
    if total == 0 do
      IO.puts(:stderr, "[knowledge lane] after_suite guard: 0 tests executed — tag loss detected")
      exit({:shutdown, 1})
    end
  end)
end
```

**Env gate is mandatory:** Without the gate, this hook would fire on every normal `mix test` run and fail when the suite genuinely produces zero knowledge tests (e.g., during the policy job's `--no-start` run). [VERIFIED: test_helper.exs pattern with SCORIA_TEST_INCLUDE_KNOWLEDGE]

**`exit({:shutdown, 1})` is correct:** This mirrors ExUnit's own mechanism for aborting with a non-zero exit code and is the idiomatic Erlang/Elixir way to exit with a specific code from an OTP application. Using `System.stop/1` would also work but `exit({:shutdown, 1})` is shorter and already used by ExUnit itself.

**Placement caveat:** `ExUnit.after_suite/1` must be called **after** `ExUnit.start/1` — after_suite registration is stored in the application env set up by start. Calling it before would require separate ensure_started logic. In `test_helper.exs`, place the block after the `ExUnit.start(exclude: excluded_tags)` call on line 22. [VERIFIED: ExUnit.after_suite source via hexdocs confirms it calls `Application.fetch_env!(:ex_unit, :after_suite)`]

### Mechanic 4: D-03 contract test — `knowledge_test_files/0` via Path.wildcard

**Wildcard patterns verified live** (run from project root):

```elixir
Path.wildcard("test/scoria/knowledge_test.exs") ++
Path.wildcard("test/scoria/knowledge/**/*_test.exs")
```

Result (verified):
```
["test/scoria/knowledge/citation_formatter_test.exs",
 "test/scoria/knowledge/grounding_test.exs",
 "test/scoria/knowledge/pgvector_test.exs",
 "test/scoria/knowledge/retrieval_test.exs",
 "test/scoria/knowledge/scrypath_test.exs",
 "test/scoria/knowledge_test.exs"]
```

[VERIFIED: `elixir -e 'IO.inspect(Path.wildcard(...))` run in project root]

**All 6 files confirmed to use `Scoria.KnowledgeCase`:** [VERIFIED: grep in test/]
```
test/scoria/knowledge_test.exs:2:                use Scoria.KnowledgeCase, async: false
test/scoria/knowledge/citation_formatter_test.exs:2:  use Scoria.KnowledgeCase, async: false
test/scoria/knowledge/grounding_test.exs:2:          use Scoria.KnowledgeCase, async: false
test/scoria/knowledge/pgvector_test.exs:2:           use Scoria.KnowledgeCase, async: false
test/scoria/knowledge/retrieval_test.exs:2:          use Scoria.KnowledgeCase, async: false
test/scoria/knowledge/scrypath_test.exs:2:           use Scoria.KnowledgeCase, async: false
```

**No other files use `@moduletag :knowledge` or `@tag :knowledge` directly** (confirmed: only `test/support/knowledge_case.exs:10` carries the tag, and it's in `using do` so it's applied only to files that `use Scoria.KnowledgeCase`). [VERIFIED: grep across test/]

**`knowledge_test_files/0` must live in `scoria.test.knowledge.ex`** — same location as `adoption_test_files/0` lives in `test.adoption.ex`. The contract test then calls the function via the module. This is important: the wildcard runs at compile time (or definition time), not at test runtime, matching the precedent.

**Alternative: compile-time module attribute** (matching adoption precedent exactly):

```elixir
@knowledge_test_files (
  Path.wildcard("test/scoria/knowledge_test.exs") ++
  Path.wildcard("test/scoria/knowledge/**/*_test.exs")
  |> Enum.sort()
)
def knowledge_test_files, do: @knowledge_test_files
```

This is the cleanest form: evaluated once at compile time, exposed as a public function, sortable.

### Mechanic 5: Arg ordering — `["--only", "knowledge" | args]`

**Pattern:** Filter first, caller args appended. This is correct because:

1. ExUnit's own `--only` parsing appends to existing includes, so order in the arg list doesn't matter for the tag filter itself.
2. Caller-passed paths (e.g., `test/scoria/knowledge_test.exs:42`) are additional file selectors and are compatible with `--only` (they narrow further).
3. `--seed N` and `--max-failures N` are flag args not in conflict with `--only`.
4. **Potential concern:** If a caller passes `--only some_other_tag`, two `--only` flags exist. ExUnit's `parse_filters/2` uses `Keyword.get_values/2` for `:only` and accumulates them, so both filters would be in the include list — effectively AND logic is not applied, this becomes OR. In practice this is fine: the knowledge task is run as `mix test.knowledge`, not with user-provided `--only`, and even if someone did pass `--only knowledge` again, it would just be a no-op duplicate. [ASSUMED: based on reading ExUnit filter parsing behavior; actual multi-`--only` OR behavior not explicitly verified against source]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Empty test run detection | Custom process to count test file matches | ExUnit's built-in `--only` guard (Layer 1) + `after_suite` hook (Layer 2) | ExUnit's guard already handles this; after_suite is the official extension point |
| File set discovery for coverage proof | Hardcoded list in the contract test | `Path.wildcard/1` in `knowledge_test_files/0` | Hardcoded list = instant stale on rename; wildcard = self-updating ratchet |
| Tag scope enforcement | Checking files at CI/script level | `use Scoria.KnowledgeCase` assertion in contract test | Single code-path check that also catches widening (stray `@tag :knowledge` elsewhere) |
| Arg injection | Shell script wrapper | Prepend in `Mix.Task.run/2` call | Mix task is already the right boundary; shell wrapper would bypass Mix.Task.reenable |

---

## Common Pitfalls

### Pitfall 1: Placing `after_suite` before `ExUnit.start`

**What goes wrong:** `Application.fetch_env!(:ex_unit, :after_suite)` raises because `:ex_unit` hasn't initialized the `:after_suite` key yet.

**Why it happens:** `after_suite/1` reads from application env that `ExUnit.start/1` sets up.

**How to avoid:** Always place the `after_suite` registration block AFTER `ExUnit.start(exclude: excluded_tags)` on line 22 of `test_helper.exs`.

**Warning signs:** `** (ArgumentError) could not fetch application environment...` on test startup.

### Pitfall 2: Omitting the env gate on the `after_suite` block

**What goes wrong:** Normal `mix test` (without `SCORIA_TEST_INCLUDE_KNOWLEDGE=true`) fails because `total` counts non-knowledge tests, not because the hook is wrong — actually the hook would pass if total > 0. BUT: the policy job's lane-contract step runs `mix test --no-start` with `SCORIA_LANE_CONTRACT_ONLY=true`, which skips `Application.ensure_all_started(:scoria)`, so if `total` happens to be 0 (only 3 contract files run), the hook would fire false-positive.

**Correct gate:** `if System.get_env("SCORIA_TEST_INCLUDE_KNOWLEDGE") == "true"` — mirrors the exact same guard used on line 14.

**Warning signs:** Policy job `mix test --no-start test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs` fails with a non-zero exit related to 0 knowledge tests.

### Pitfall 3: Removing `SCORIA_TEST_INCLUDE_KNOWLEDGE=true` from `scoria.test.knowledge.ex:11`

**What goes wrong:** `test_helper.exs:14` pre-excludes `{:knowledge, true}` at `ExUnit.start` before `--only` can re-include those tags. All 6 knowledge files match the `include: [knowledge: true]` from `--only`, but the pre-exclusion wins, so 0 tests run. Layer 1 guard fires (correctly) and fails the lane — but now both the fix and the guard are fighting each other.

**How to avoid:** KEEP line 11 (`System.put_env("SCORIA_TEST_INCLUDE_KNOWLEDGE", "true")`) exactly as is. Do not touch it.

**Warning signs:** Knowledge lane exits with "The --only option was given to mix test but no test was executed" even when knowledge test files exist.

### Pitfall 4: Using a hardcoded count threshold in `after_suite` Layer 2

**What goes wrong:** Threshold rots — too low → false-green when tests disappear; too high → false-red when tests are refactored into fewer test cases.

**How to avoid:** Assert `total > 0`, not `total >= 13` (or whatever today's count is). The D-03 contract test provides the coverage-count ratchet via the file-set assertion.

**Warning signs:** CI fails for the wrong reason after a refactor; or CI passes when a knowledge test is silently deleted.

### Pitfall 5: Placing `knowledge_test_files/0` in the contract test file rather than the mix task

**What goes wrong:** Contract test contains the list it is supposed to validate — it can never fail, defeating the purpose.

**How to avoid:** `knowledge_test_files/0` must be in `Mix.Tasks.Scoria.Test.Knowledge` (the production module), exposed as a public function, and called from the contract test. This matches the `adoption_test_files/0` precedent exactly.

**Warning signs:** Contract test imports or defines its own expected list inline rather than calling `Mix.Tasks.Scoria.Test.Knowledge.knowledge_test_files()`.

### Pitfall 6: Confusing `ci_command` vs `command` for knowledge lane contract test assertions

**What goes wrong:** `VerificationLanes.ci_command(:knowledge)` returns `"mix test.knowledge"` (no WAE), but `ci-verify.yml:188` is `run: mix test.knowledge --warnings-as-errors`. The verification_lanes_test asserts the YAML contains `"mix test.knowledge --warnings-as-errors"` directly (not via `ci_command`). If a planner task accidentally adds `--only knowledge` to `ci_command`, the contract test at `verification_lanes_test.exs:90` would fail.

**How to avoid:** The `--only knowledge` injection is internal to the task — never surface it in `VerificationLanes.command/ci_command` or in `ci-verify.yml`. The YAML contract string stays `mix test.knowledge --warnings-as-errors` exactly as it is.

---

## Code Examples

### D-01: One-line fix in `scoria.test.knowledge.ex`

```elixir
# BEFORE (lib/mix/tasks/scoria.test.knowledge.ex:19):
Mix.Task.run("test", args)

# AFTER:
Mix.Task.run("test", ["--only", "knowledge" | args])
```

### D-02: `after_suite` block in `test_helper.exs`

Place immediately after the `ExUnit.start(exclude: excluded_tags)` call (current line 22):

```elixir
# Layer 2 zero-test guard: fires only when SCORIA_TEST_INCLUDE_KNOWLEDGE=true
# (i.e., only during mix test.knowledge runs). Default mix test never trips this.
if System.get_env("SCORIA_TEST_INCLUDE_KNOWLEDGE") == "true" do
  ExUnit.after_suite(fn %{total: total} ->
    if total == 0 do
      IO.puts(:stderr, "[knowledge lane] after_suite: 0 tests executed — possible tag loss")
      exit({:shutdown, 1})
    end
  end)
end
```

### D-03: `knowledge_test_files/0` addition to `scoria.test.knowledge.ex`

```elixir
defmodule Mix.Tasks.Scoria.Test.Knowledge do
  use Mix.Task

  @shortdoc "Runs the canonical optional knowledge verification lane"

  @knowledge_test_files (
    Path.wildcard("test/scoria/knowledge_test.exs") ++
    Path.wildcard("test/scoria/knowledge/**/*_test.exs")
  ) |> Enum.sort()

  def knowledge_test_files, do: @knowledge_test_files

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("loadpaths")
    Mix.Task.reenable("scoria.pgvector.bootstrap")
    Mix.Task.reenable("app.start")
    System.put_env("SCORIA_TEST_INCLUDE_KNOWLEDGE", "true")

    Mix.Task.run("scoria.pgvector.bootstrap")

    Scoria.TestSupport.Migrations.migrate_core!()
    Scoria.TestSupport.Migrations.migrate_knowledge!()

    Mix.Task.reenable("test")
    Mix.Task.run("test", ["--only", "knowledge" | args])
  end
end
```

### D-03: New `test/scoria/knowledge_lane_contract_test.exs`

Model: mirrors `test/mix/tasks/test.adoption_test.exs` + `test/scoria/ci_policy_contract_test.exs`

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

**Note on `async: true`:** The test only uses `File.read!` and module reflection — no DB, no app start, no shared state. `async: true` matches the sibling contract tests (`adoption_test.exs`, `ci_policy_contract_test.exs`, `verification_lanes_test.exs`).

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Bare `Mix.Task.run("test", args)` — runs full suite + knowledge tests | `Mix.Task.run("test", ["--only", "knowledge" | args])` — scopes to tag | Phase 24 (this phase) | ~22 min reclaimed from CI wall-clock |
| No zero-test guard | Layer 1 (built-in) + Layer 2 (`after_suite`) | Phase 24 | Prevents silent false-green from tag loss |
| No coverage-preservation proof | `knowledge_lane_contract_test.exs` ratchet | Phase 24 | Makes SC#3 automatable and loud |

---

## Codebase Contract Verification

### Files This Phase Touches

| File | Change | Risk to Existing Tests |
|------|--------|----------------------|
| `lib/mix/tasks/scoria.test.knowledge.ex` | Line 19: prepend `["--only", "knowledge"]`; add `@knowledge_test_files` + `knowledge_test_files/0` | Zero — the existing `scoria.test_knowledge_test.exs` checks discoverability/arity only; does not assert on `run/1` arg behavior |
| `test/test_helper.exs` | Add `after_suite` block after line 22 | Zero to normal `mix test`; only fires when `SCORIA_TEST_INCLUDE_KNOWLEDGE=true` |
| `test/scoria/knowledge_lane_contract_test.exs` | NEW file | Additive; `async: true`; no DB needed; passes in normal `mix test` |

### Contract Tests That Must Stay Green (SC#4)

All of these are confirmed to be unaffected by D-01/D-02/D-03:

| Contract Test | What It Asserts | Why Safe |
|---------------|-----------------|----------|
| `verification_lanes_test.exs:90` | `ci_workflow =~ "mix test.knowledge --warnings-as-errors"` | YAML line 188 is unchanged; D-01 injects `--only` inside the task, not in YAML |
| `ci_policy_contract_test.exs` tests 202, 216, 229 | `index_of(test_section, "mix test.knowledge --warnings-as-errors")` byte-order assertions | Same — YAML unchanged |
| `verification_lanes_test.exs` lane shape | `VerificationLanes.all()` shape + `command(:knowledge) == "mix test.knowledge"` | `VerificationLanes.ex` is not touched |
| `scoria.test_knowledge_test.exs` | Module discoverability, `run/1` exported | Satisfied — module still exists; adding `knowledge_test_files/0` is additive |

### CI YAML: Exact String That Must Not Change

```yaml
# .github/workflows/ci-verify.yml:187-188
- name: Run knowledge lane
  run: mix test.knowledge --warnings-as-errors
```

This string is asserted in 4 places in contract tests. It is not touched by this phase.

---

## Open Questions (RESOLVED)

1. **Optional: pin `mix test.knowledge` in `scoria.test_knowledge_test.exs`**
   - What we know: The existing test does not assert `VerificationLanes.command(:knowledge)`. The adoption test does.
   - What's unclear: Is adding `assert VerificationLanes.command(:knowledge) == "mix test.knowledge"` to the existing `scoria.test_knowledge_test.exs` desirable, or does D-03's new contract test cover this sufficiently?
   - Recommendation: D-03 `knowledge_lane_contract_test.exs` already asserts this. Planner may choose to also add it to `scoria.test_knowledge_test.exs` for symmetry with `test.adoption_test.exs` (which asserts `VerificationLanes.command(:adoption)`), but this is cosmetic.

2. **`--only` with caller-provided `--only some_other_tag`**
   - What we know: ExUnit accumulates multiple `:only` flags via `Keyword.get_values`. Effect would be OR of the two sets.
   - What's unclear: Exact behavior not verified in source for multi-`--only` scenario.
   - Recommendation: Not a practical concern since `mix test.knowledge` is never called with a user `--only` in CI. Flag as [ASSUMED] and note in code comment if desired.

3. **Layer 2 guard and `--partitions` (Phase 26 forward-look)**
   - Already deferred. D-02's Layer 2 `after_suite total > 0` provides forward coverage. Phase 26 must verify the guard still arms under a sharded knowledge lane.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All changes | Yes | 1.19.5-otp-27 | — |
| ExUnit.after_suite/1 | D-02 Layer 2 | Yes | stdlib (1.19.5) | — |
| Path.wildcard/1 | D-03 file discovery | Yes | stdlib | — |
| pgvector extension | knowledge lane itself (pre-existing) | Setup by existing task | — | — |

No missing dependencies. All mechanics are stdlib Elixir/Mix.

---

## Validation Architecture

> `workflow.nyquist_validation` is not set to `false` in `.planning/config.json` (key is absent). Validation section is included.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (stdlib, Elixir 1.19.5) |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `mix test test/scoria/knowledge_lane_contract_test.exs` |
| Full suite command | `mix test --warnings-as-errors` |
| Knowledge lane command | `mix test.knowledge --warnings-as-errors` |

### Success Criteria → Test Map

| SC# | Behavior | Test Type | Automated Command | File Exists? |
|-----|----------|-----------|-------------------|-------------|
| SC#1 | Knowledge lane runs only the 6 knowledge-tagged files | automated | `mix test.knowledge --warnings-as-errors` (check log line count vs full suite) | N/A (CI log inspection) |
| SC#1 (proxy) | `knowledge_test_files/0` returns exactly 6 files | unit/contract | `mix test test/scoria/knowledge_lane_contract_test.exs` | No — Wave 0 gap |
| SC#2 | CI YAML contract string `mix test.knowledge --warnings-as-errors` unchanged | contract | `mix test test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` | Yes |
| SC#3 | Every knowledge-tagged test still runs (no silent exclusion) | contract | `mix test test/scoria/knowledge_lane_contract_test.exs` + `mix test.knowledge --warnings-as-errors` | No — Wave 0 gap |
| SC#4 | `ci_policy_contract_test` + `verification_lanes_test` green | contract | `mix test test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` | Yes |

### Wave 0 Gaps

- [ ] `test/scoria/knowledge_lane_contract_test.exs` — covers SC#1 proxy + SC#3 (D-03; this is a deliverable, not a pre-existing gap to fill)
- [ ] Layer 2 `after_suite` block in `test/test_helper.exs` — covers SC#3 runtime guard (D-02; also a deliverable)

*(The "gaps" for this phase ARE the deliverables — there is no pre-existing test infrastructure to augment; we create it.)*

---

## Security Domain

> `security_enforcement` is not set to `false` in `.planning/config.json`. Section is included.

This phase makes no changes to authentication, authorization, session management, input validation, cryptography, or data access. The changes are:
1. A mix task arg modification (internal to the test toolchain)
2. A test helper hook
3. A new test file

**Applicable ASVS categories:** None. This is a CI/test-infrastructure-only change.

**STRIDE:** No threat surface change. The fix scopes test execution; no production code paths are touched.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Multi-`--only` flags (caller passes `--only some_other_tag` AND task prepends `--only knowledge`) produce OR union of the two sets via `Keyword.get_values` accumulation | Mechanic 5 / Arg ordering | Low — `mix test.knowledge` is never called with user `--only` in CI or documented usage; even if AND logic applied, the knowledge tests would still run |

---

## Sources

### Primary (HIGH confidence)

- Elixir stdlib ExUnit (1.19.5) — `ExUnit.after_suite/1` signature, `suite_result` type keys (`total`, `failures`, `skipped`, `excluded`) confirmed at: [ex-unit.hexdocs.pm/1.19.5/ExUnit.html](https://ex-unit.hexdocs.pm/1.19.5/ExUnit.html)
- Mix.Tasks.Test source (GitHub `main`) — `--only` filter merging logic, `nothing_executed` exact error message string, `System.at_exit` exit path, `Mix.Task.recursing?()` umbrella gate: [github.com/elixir-lang/elixir/blob/main/lib/mix/lib/mix/tasks/test.ex](https://github.com/elixir-lang/elixir/blob/main/lib/mix/lib/mix/tasks/test.ex)
- ExUnit source (GitHub `main`) — `after_suite/1` implementation: [github.com/elixir-lang/elixir/blob/main/lib/ex_unit/lib/ex_unit.ex](https://github.com/elixir-lang/elixir/blob/main/lib/ex_unit/lib/ex_unit.ex)
- Mix.Task documentation — `recursing?/0` semantics: [mix.hexdocs.pm/Mix.Task.html](https://mix.hexdocs.pm/Mix.Task.html)
- Live codebase reads: `lib/mix/tasks/scoria.test.knowledge.ex`, `test/test_helper.exs`, `test/support/knowledge_case.exs`, all 6 knowledge test files, `test/mix/tasks/test.adoption_test.exs`, `lib/mix/tasks/test.adoption.ex`, `lib/scoria/verification_lanes.ex`, `test/scoria/verification_lanes_test.exs`, `test/scoria/ci_policy_contract_test.exs`, `.github/workflows/ci-verify.yml`
- Live `Path.wildcard` verification: patterns confirmed to return exactly 6 files (run via `elixir -e` in project root)
- Live `grep` for `use Scoria.KnowledgeCase` — confirmed exactly 6 files
- Live `grep` for `@moduletag :knowledge` / `@tag :knowledge` — confirmed no direct tag usage outside `knowledge_case.exs`

### Secondary (MEDIUM confidence)

- Mix.Tasks.Test documentation — `--only` empty-run guarantee confirmed: [mix.hexdocs.pm/Mix.Tasks.Test.html](https://mix.hexdocs.pm/Mix.Tasks.Test.html)
- Issue #3940 (elixir-lang/elixir) — bare-atom exclude bug; assessed as irrelevant to current codebase (keyword tuple form used): [github.com/elixir-lang/elixir/issues/3940](https://github.com/elixir-lang/elixir/issues/3940)

### Tertiary (LOW confidence)

- Multi-`--only` OR accumulation behavior (A1) — inferred from `Keyword.get_values` pattern in filter parsing; not verified against a live multi-`--only` run

---

## Metadata

**Confidence breakdown:**
- D-01 mechanism (arg injection + env guard): HIGH — exact source code read + live codebase verification
- D-02 Layer 1 (built-in guard): HIGH — official docs + source + `recursing?` confirmed non-umbrella
- D-02 Layer 2 (`after_suite` API): HIGH — live `mix run` confirmed function exists + hexdocs `suite_result` type
- D-03 wildcard patterns: HIGH — live `elixir -e` run returned correct 6 files
- D-03 precedent (adoption pattern): HIGH — source read directly
- Contract test safety (SC#4 will stay green): HIGH — traced every assertion against YAML lines and VerificationLanes module; neither is touched

**Research date:** 2026-06-15
**Valid until:** 2026-07-15 (30 days; ExUnit/Mix API is stable; short validity because phase should execute immediately)
