# Phase 54: Executable proof and closeout truth - Pattern Map

**Mapped:** 2026-05-27  
**Inputs read:** `54-CONTEXT.md`, `54-RESEARCH.md`  
**Files analyzed for analogs:** 14

## File Classification

| Planned file | Role | Data flow | Closest analog(s) | Reuse quality |
|---|---|---|---|---|
| `lib/mix/tasks/scoria.test.runtime_to_handoff.ex` | lane-task implementation | command -> bounded test files | `lib/mix/tasks/test.adoption.ex` | strong |
| `lib/mix/tasks/test.runtime_to_handoff.ex` | compatibility wrapper | command alias -> implementation task | `lib/mix/tasks/test.adoption.ex` | strong |
| `mix.exs` | CLI env mapping | command name -> `MIX_ENV=test` | `mix.exs` `preferred_envs` | exact |
| `test/mix/tasks/test.runtime_to_handoff_test.exs` | discoverability contract test | task module -> expected file list + registry | `test/mix/tasks/test.adoption_test.exs`, `test/mix/tasks/test.semantic_fast_path_test.exs` | strong |
| `README.md` | top-level command contract docs | canonical command string -> adopter guidance | `README.md` + docs drift tests | strong |
| `docs/operator_verification.md` | closeout truth + lane hierarchy docs | proof chain command order -> maintainer guidance | `docs/operator_verification.md` | exact |
| `docs/adoption_lanes.md` | lane boundary docs | lane wording -> escalation guidance | `docs/adoption_lanes.md` | exact |
| `docs/phoenix_runtime_example.md` | runtime escalation docs | example flow -> lane command references | `docs/phoenix_runtime_example.md` | exact |
| `docs/bounded_handoffs.md` | bounded handoff docs | safety wording -> canonical verifier refs | `docs/bounded_handoffs.md` | exact |
| `test/scoria/adoption_surface_test.exs` | docs drift/assert-refute matrix | file content -> command truth assertions | `test/scoria/adoption_surface_test.exs` | exact |
| `test/support/scoria/adoption_example.ex` | shared command/source fragments | fragment literals -> docs source tests | `test/support/scoria/adoption_example.ex` | exact |
| `.github/workflows/ci.yml` | CI lane sequence | pipeline steps -> canonical closeout chain | `.github/workflows/ci.yml` | exact |
| `test/scoria/runtime_test.exs` (likely extension) | negative contract proof | runtime handoff API -> safety/non-prereq behavior | `test/scoria/runtime_test.exs` | strong |
| `.planning/phases/54-executable-proof-and-closeout-truth/54-VERIFICATION.md` | closeout evidence ledger | command outputs -> auditable truth | `.planning/phases/53-operator-evidence-and-lane-guidance/53-VERIFICATION.md` | strong |

## Reusable Patterns and Concrete Analogs

### 1) Named bounded lane task + wrapper

**Apply to:** `lib/mix/tasks/scoria.test.runtime_to_handoff.ex`, `lib/mix/tasks/test.runtime_to_handoff.ex`

**Analog excerpt (`lib/mix/tasks/test.adoption.ex`):**

```elixir
defmodule Mix.Tasks.Scoria.Test.Adoption do
  use Mix.Task

  @adoption_test_files [
    "test/scoria_test.exs",
    "test/scoria/adoption_surface_test.exs",
    "test/scoria/runtime_integration_test.exs",
    "test/scoria/runtime_test.exs"
  ]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("loadpaths")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args ++ @adoption_test_files)
  end
end

defmodule Mix.Tasks.Test.Adoption do
  use Mix.Task
  @impl Mix.Task
  def run(args), do: Mix.Tasks.Scoria.Test.Adoption.run(args)
end
```

**Why reusable**
- Already defines Scoria's lane contract shape: explicit bounded list, no broad `mix test`.
- Wrapper naming (`Mix.Tasks.Test.*`) preserves short adopter-facing command while keeping implementation namespaced.
- `loadpaths -> reenable("test") -> run("test", args ++ files)` is stable and repeated across lanes.

### 2) Optional-lane prerequisite isolation (negative by construction)

**Apply to:** `lib/mix/tasks/scoria.test.runtime_to_handoff.ex`, `test/scoria/runtime_test.exs` assertions

**Analog excerpt (`lib/mix/tasks/scoria.test.semantic_fast_path.ex` vs `lib/mix/tasks/scoria.test.knowledge.ex`):**

```elixir
# semantic lane: intentionally pulls knowledge migration setup
Mix.Task.run("app.start")
Migrations.migrate_knowledge!()
Mix.Task.run("test", args ++ @semantic_fast_path_test_files)
```

```elixir
# knowledge lane: explicitly enables optional lane behavior
System.put_env("SCORIA_TEST_INCLUDE_KNOWLEDGE", "true")
Mix.Task.run("scoria.pgvector.bootstrap")
Scoria.TestSupport.Migrations.migrate_knowledge!()
Mix.Task.run("test", args)
```

**Analog excerpt (`test/test_helper.exs`):**

```elixir
ExUnit.start(
  exclude:
    if(System.get_env("SCORIA_TEST_INCLUDE_KNOWLEDGE") == "true", do: [], else: [knowledge: true])
)
```

**Why reusable**
- Gives explicit "what not to do" boundaries for the new canonical runtime-to-handoff lane.
- The new lane should follow adoption-task minimalism and avoid any knowledge/bootstrap setup calls.
- Existing env-gated knowledge behavior makes prerequisite independence testable with negative assertions.

### 3) Preferred env registration for discoverable commands

**Apply to:** `mix.exs`

**Analog excerpt (`mix.exs`):**

```elixir
def cli do
  [
    preferred_envs: [
      "scoria.test.adoption": :test,
      "test.adoption": :test,
      "scoria.test.semantic_fast_path": :test,
      "test.semantic_fast_path": :test,
      "scoria.test.knowledge": :test,
      "test.knowledge": :test
    ]
  ]
end
```

**Why reusable**
- Phase 54 needs the exact same dual registration pattern for both command spellings.
- Prevents accidental `MIX_ENV=dev`/`prod` invocation drift for test-lane commands.

### 4) Task discoverability and bounded file-list test

**Apply to:** `test/mix/tasks/test.runtime_to_handoff_test.exs`

**Analog excerpt (`test/mix/tasks/test.adoption_test.exs`):**

```elixir
Mix.Task.load_all()

assert Code.ensure_loaded?(Mix.Tasks.Scoria.Test.Adoption)
assert function_exported?(Mix.Tasks.Scoria.Test.Adoption, :adoption_test_files, 0)
assert function_exported?(Mix.Tasks.Test.Adoption, :run, 1)
assert Mix.Tasks.Scoria.Test.Adoption.adoption_test_files() == expected_files
assert Mix.Task.get("scoria.test.adoption")
assert Mix.Task.get("test.adoption")
```

**Why reusable**
- Captures both API shape and registry-level discoverability in one fast test.
- Supports Phase 54 requirement that lane stays bounded and intentional, not a hidden broad-suite alias.

### 5) Docs drift matrix (assert canonical command, refute ambiguous synonyms)

**Apply to:** `test/scoria/adoption_surface_test.exs`, plus downstream docs updates

**Analog excerpt (`test/scoria/adoption_surface_test.exs`):**

```elixir
for content <- [readme, lane_guide, operator_guide, phoenix_example, handoff_guide] do
  refute content =~ "runtime-to-handoff proof"
  refute content =~ "mix test.runtime_to_handoff"
  refute content =~ "mix test.handoff"
end
```

```elixir
assert content =~ "mix scoria.release_preview\nmix test.adoption"
refute content =~ "MIX_ENV=test mix scoria.release_preview"
```

**Why reusable**
- Phase 53 already established the exact string-level matrix to migrate in Phase 54 (refute -> assert for the shipped command).
- Keeps command truth lightweight and explicit without snapshot tooling.
- Same file already protects lane-boundary wording, so command alignment belongs here.

### 6) Shared fragment source-of-truth for docs alignment

**Apply to:** `test/support/scoria/adoption_example.ex` (add canonical runtime-to-handoff fragments)

**Analog excerpt (`test/support/scoria/adoption_example.ex`):**

```elixir
def doc_fragments do
  [
    "identity -> start -> inspect -> resume",
    "Scoria.start_handoff_run/3",
    "Scoria.get_run_detail/1",
    "/scoria/workflows/:run_id"
  ]
end
```

**Analog excerpt (`test/scoria/phoenix_example_source_test.exs`):**

```elixir
for fragment <- AdoptionExample.doc_fragments() do
  assert content =~ fragment
end
```

**Why reusable**
- Central fragment lists prevent command drift across multiple docs pages.
- Source tests already consume this helper, so Phase 54 can add command fragments once and validate many surfaces.

### 7) Closeout chain pattern across docs + CI

**Apply to:** `docs/operator_verification.md`, `.github/workflows/ci.yml`

**Analog excerpt (`docs/operator_verification.md`):**

```markdown
For repository closeout, the canonical proof chain is exactly:
- mix scoria.release_preview
- mix test.adoption
```

**Analog excerpt (`.github/workflows/ci.yml`):**

```yaml
- name: Run release preview lane
  run: MIX_ENV=dev mix scoria.release_preview

- name: Run adoption closure lane
  run: mix test.adoption

- name: Run tests
  run: mix test

- name: Run knowledge lane
  run: mix test.knowledge
```

**Why reusable**
- Existing CI/doc pairing already encodes canonical order semantics; Phase 54 only inserts runtime-to-handoff lane without collapsing boundaries.
- Preserves distinction between user-facing command contract and CI-specific env wrappers.

### 8) Verification ledger structure for auditable closeout truth

**Apply to:** `.planning/phases/54-executable-proof-and-closeout-truth/54-VERIFICATION.md`

**Analog excerpt (`.planning/phases/53-operator-evidence-and-lane-guidance/53-VERIFICATION.md`):**

```markdown
---
phase: 53-operator-evidence-and-lane-guidance
verified: 2026-05-27T08:05:49Z
status: passed
score: 8/8 must-haves verified
---
```

```markdown
## Verification Commands

- `MIX_ENV=test mix test ...` (pass)
```

**Why reusable**
- Provides required ledger semantics for Phase 54 exception protocol (blocked command, compensating checks, owner, expiry, rerun).
- Keeps closeout evidence auditable and aligned to command-contract truth rather than narrative-only claims.

## Notes for Phase 54 Planner

- `mix test.runtime_to_handoff` should be the only adopter-facing runtime-to-handoff proof command string across required support surfaces.
- Keep `mix test.adoption` as default-lane canonical verifier; do not merge file lists between lanes.
- Add negative-contract assertions that runtime-to-handoff lane does not trigger optional knowledge/semantic setup.
- Insert runtime-to-handoff lane into CI closeout sequence before broad `mix test` to fail fast on command-contract drift.
