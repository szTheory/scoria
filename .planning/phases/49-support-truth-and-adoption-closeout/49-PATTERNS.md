# Phase 49: Support truth and adoption closeout - Pattern Map

**Mapped:** 2026-05-26
**Files analyzed:** 18
**Analogs found:** 18 / 18

Files below come from `49-CONTEXT.md` plus current repo drift in `git status --short`. This phase is a coordinated docs/task/test truth pass, so most targets are exact-file analogs rather than new structures.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `README.md` | utility | transform | `README.md` | exact |
| `docs/adoption_lanes.md` | utility | transform | `docs/adoption_lanes.md` | exact |
| `docs/operator_verification.md` | utility | transform | `docs/operator_verification.md` | exact |
| `docs/bounded_handoffs.md` | utility | transform | `docs/bounded_handoffs.md` | exact |
| `docs/semantic_fast_path.md` | utility | transform | `docs/semantic_fast_path.md` | exact |
| `.planning/METHODOLOGY.md` | utility | transform | `.planning/METHODOLOGY.md` | exact |
| `lib/mix/tasks/scoria.install.ex` | utility | file-I/O | `lib/mix/tasks/scoria.install.ex` | exact |
| `lib/mix/tasks/scoria.release_preview.ex` | utility | batch | `lib/mix/tasks/scoria.release_preview.ex` | exact |
| `lib/mix/tasks/test.adoption.ex` | utility | batch | `lib/mix/tasks/test.adoption.ex` | exact |
| `lib/mix/tasks/test.semantic_fast_path.ex` | utility | request-response | `lib/mix/tasks/test.semantic_fast_path.ex` | exact |
| `lib/mix/tasks/scoria.test.knowledge.ex` | utility | batch | `lib/mix/tasks/scoria.test.knowledge.ex` | exact |
| `mix.exs` | config | transform | `mix.exs` | exact |
| `test/scoria/adoption_surface_test.exs` | test | transform | `test/scoria/adoption_surface_test.exs` | exact |
| `test/mix/tasks/test.adoption_test.exs` | test | batch | `test/mix/tasks/test.adoption_test.exs` | exact |
| `test/mix/tasks/test.semantic_fast_path_test.exs` | test | batch | `test/mix/tasks/test.semantic_fast_path_test.exs` | exact |
| `test/mix/tasks/scoria.test_knowledge_test.exs` | test | batch | `test/mix/tasks/scoria.test_knowledge_test.exs` | exact |
| `test/mix/tasks/scoria.install_test.exs` | test | file-I/O | `test/mix/tasks/scoria.install_test.exs` | exact |
| `test/mix/tasks/scoria.release_preview_test.exs` | test | batch | `test/mix/tasks/scoria.release_preview_test.exs` | exact |

## Pattern Assignments

### `README.md` (utility, transform)

**Analog:** `README.md`

**Public lane inventory pattern** ([README.md](/Users/jon/projects/scoria/README.md:10)):
```markdown
Scoria is shipped through `v2.1 Tenant-scoped semantic fast path`. The current public shape is intentionally narrow:

- a default runtime lane for durable Phoenix-hosted runs
- a bounded handoff lane for narrow same-run delegation
- a semantic fast path for explicitly safe read-only work
- an optional knowledge lane for pgvector-backed retrieval and grounding
```

**Verification hierarchy pattern** ([README.md](/Users/jon/projects/scoria/README.md:163)):
```markdown
## Verification

Default Phoenix lane:

```bash
mix ecto.migrate
mix test
```

Then prove the core lane with one real run from your app...
```

**Optional-lane caveat pattern** ([README.md](/Users/jon/projects/scoria/README.md:174)):
```markdown
Optional knowledge lane:

```bash
mix scoria.pgvector.bootstrap
mix scoria.test.knowledge
```

The knowledge lane does not require `pgvector`, knowledge tables, retrieval, grounding, or `mix scoria.test.knowledge` to prove the core runtime...
```

Use README as the primary prose analog for calm lane ordering, short proof blocks, and explicit “optional later” caveats.

---

### `docs/adoption_lanes.md` (utility, transform)

**Analog:** `docs/adoption_lanes.md`

**Lane-by-lane doc structure** ([docs/adoption_lanes.md](/Users/jon/projects/scoria/docs/adoption_lanes.md:7)):
```markdown
## The Four Lanes

### 1. Default runtime lane
...
### 2. Bounded handoff lane
...
### 3. Semantic fast-path lane
...
### 4. Optional knowledge lane
```

**Default proof block pattern** ([docs/adoption_lanes.md](/Users/jon/projects/scoria/docs/adoption_lanes.md:33)):
```markdown
Proof lane:

```bash
mix scoria.install
mix ecto.migrate
mix test.adoption
```
```

**Optional-lane separation pattern** ([docs/adoption_lanes.md](/Users/jon/projects/scoria/docs/adoption_lanes.md:94)):
```markdown
### 4. Optional knowledge lane
...
```bash
mix scoria.pgvector.bootstrap
mix scoria.test.knowledge
```

This lane is explicitly optional.
```

Copy this document’s heading rhythm and “add this only after...” posture for any lane-order rewrite.

---

### `docs/operator_verification.md` (utility, transform)

**Analog:** `docs/operator_verification.md`

**Default-lane success checklist pattern** ([docs/operator_verification.md](/Users/jon/projects/scoria/docs/operator_verification.md:5)):
```markdown
## What core success means

You have proven the default lane when all of these are true:

- `mix scoria.install` has wired the dashboard...
- `mix ecto.migrate` and `mix test` pass for the host app
- one real run starts through `Scoria.start_run/2`
```

**Canonical bounded verifier wording** ([docs/operator_verification.md](/Users/jon/projects/scoria/docs/operator_verification.md:17)):
```markdown
## Step 1: Install preflight
...
mix scoria.install
mix ecto.migrate
mix test
...
Use `mix test.adoption` as the canonical default-lane verifier when you want one bounded proof...
```

**Maintainer closeout hierarchy** ([docs/operator_verification.md](/Users/jon/projects/scoria/docs/operator_verification.md:135)):
```markdown
## Maintainer release-preview lane
...
- `mix test.adoption` proves the canonical default runtime adoption boundary
- `mix test.semantic_fast_path` proves the bounded semantic troubleshooting lane
- `mix scoria.test.knowledge` proves the optional knowledge lane
```

This is the main analog for Phase 49’s four-tier support hierarchy.

---

### `docs/bounded_handoffs.md` (utility, transform)

**Analog:** `docs/bounded_handoffs.md`

**“Same lane, additive capability” pattern** ([docs/bounded_handoffs.md](/Users/jon/projects/scoria/docs/bounded_handoffs.md:3)):
```markdown
Start with the normal runtime lane first: `identity -> start -> inspect -> resume`. Bounded handoffs extend that same runtime-first story instead of creating a second quickstart.
```

**Narrow contract pattern** ([docs/bounded_handoffs.md](/Users/jon/projects/scoria/docs/bounded_handoffs.md:15)):
```markdown
Use `Scoria.start_handoff_run/3` when you already know:

- `root_role_id`
- the delegated role argument
- `delegated_kind`
- `handoff_input`
- `projected_context`
```

**No-new-proof-lane closeout pattern** ([docs/bounded_handoffs.md](/Users/jon/projects/scoria/docs/bounded_handoffs.md:107)):
```markdown
## Remaining adoption gap

No remaining adopter-facing gap is required for the runtime-first bounded handoff lane...
```

Use this doc as the analog whenever wording needs to keep handoffs inside the default runtime story, not as a fourth public verifier.

---

### `docs/semantic_fast_path.md` (utility, transform)

**Analog:** `docs/semantic_fast_path.md`

**Optional troubleshooting lane framing** ([docs/semantic_fast_path.md](/Users/jon/projects/scoria/docs/semantic_fast_path.md:1)):
```markdown
Use it only after the default runtime lane already works in your Phoenix app. The semantic fast path is an optimization layer...
```

**Bounded proof command pattern** ([docs/semantic_fast_path.md](/Users/jon/projects/scoria/docs/semantic_fast_path.md:99)):
```markdown
## Verification

Use the bounded semantic proof lane when validating this feature:

```bash
SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path
```
```

**Command-family separation** ([docs/semantic_fast_path.md](/Users/jon/projects/scoria/docs/semantic_fast_path.md:107)):
```markdown
This is the canonical `v2.1` troubleshooting lane. Use `mix test.adoption` for the broader public runtime adoption story, and use `mix scoria.test.knowledge` only when you are intentionally validating the optional knowledge lane.
```

Keep this doc’s explicit “only after default lane” posture.

---

### `.planning/METHODOLOGY.md` (utility, transform)

**Analog:** `.planning/METHODOLOGY.md`

**Decision-defaults pattern** ([.planning/METHODOLOGY.md](/Users/jon/projects/scoria/.planning/METHODOLOGY.md:3)):
```markdown
## Decisive Defaults
...
Bias toward:
- one obvious Phoenix/Ecto/Oban path
- durable truth over clever projection-only state
- explicit identity and policy propagation
- boring embedded-library ergonomics over hosted-platform flexibility
```

**Research-first escalation pattern** ([.planning/METHODOLOGY.md](/Users/jon/projects/scoria/.planning/METHODOLOGY.md:18)):
```markdown
Before asking the user to choose among implementation directions:
- read the relevant phase artifacts, prior CONTEXT/RESEARCH files, and prompt-corpus materials under `prompts/`
- inspect current code and task surfaces...
- compare serious alternatives against idiomatic Phoenix/Plug/Ecto/LiveView library conventions...
```

If Phase 49 touches planning posture, copy this heading + bullet format directly.

---

### `lib/mix/tasks/scoria.install.ex` (utility, file-I/O)

**Analog:** `lib/mix/tasks/scoria.install.ex`

**Optional-later-lanes inventory pattern** ([lib/mix/tasks/scoria.install.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.install.ex:20)):
```elixir
@optional_later_lanes [
  "mix test.adoption",
  ~s(SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix test.semantic_fast_path),
  "mix scoria.pgvector.bootstrap",
  "mix scoria.test.knowledge"
]
```

**Status map + summary pattern** ([lib/mix/tasks/scoria.install.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.install.ex:44)):
```elixir
%{
  router: router_status,
  tailwind: tailwind_status,
  migrations: migration_status,
  runtime_config: config_status,
  optional_later_lanes: @optional_later_lanes
}
```

**User-facing output pattern** ([lib/mix/tasks/scoria.install.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.install.ex:200)):
```elixir
Mix.shell().info("Scoria installed for the default Phoenix lane.")
...
Mix.shell().info("Optional later lanes:")

Enum.each(statuses.optional_later_lanes, fn line ->
  Mix.shell().info("  - #{line}")
end)
```

Any installer copy change should stay inside this compact three-bucket summary model.

---

### `lib/mix/tasks/scoria.release_preview.ex` (utility, batch)

**Analog:** `lib/mix/tasks/scoria.release_preview.ex`

**Required package inventory pattern** ([lib/mix/tasks/scoria.release_preview.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.release_preview.ex:4)):
```elixir
@required_package_paths [
  "README.md",
  "LICENSE",
  "mix.exs",
  "lib/scoria.ex",
  ...
  "docs/operator_verification.md"
]
```

**Bounded closeout task flow** ([lib/mix/tasks/scoria.release_preview.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.release_preview.ex:23)):
```elixir
Mix.Task.run("loadpaths")
...
Mix.Task.reenable("docs")
Mix.Task.run("docs")
...
System.cmd("mix", ["hex.build", "--unpack", "--output", output_dir], ...)
```

**Failure formatting pattern** ([lib/mix/tasks/scoria.release_preview.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.release_preview.ex:47)):
```elixir
case missing_required_paths(unpack_root) do
  [] ->
    Mix.shell().info("==> Release preview passed")

  missing ->
    Mix.raise("""
    release preview is missing required package paths:
    #{Enum.map_join(missing, "\n", &"* #{&1}")}
    """)
end
```

Use this task as the analog for any milestone-closeout inventory truth.

---

### `lib/mix/tasks/test.adoption.ex` (utility, batch)

**Analog:** `lib/mix/tasks/test.adoption.ex`

**Canonical lane subset pattern** ([lib/mix/tasks/test.adoption.ex](/Users/jon/projects/scoria/lib/mix/tasks/test.adoption.ex:4)):
```elixir
@adoption_test_files [
  "test/scoria_test.exs",
  "test/scoria/identity_doctest_test.exs",
  "test/scoria/adoption_surface_test.exs",
  ...
  "test/scoria/bootstrap/migration_lane_compatibility_test.exs"
]
```

**Entrypoint pattern** ([lib/mix/tasks/test.adoption.ex](/Users/jon/projects/scoria/lib/mix/tasks/test.adoption.ex:22)):
```elixir
def run(args) do
  Mix.Task.run("loadpaths")
  Mix.Task.reenable("test")
  Mix.Task.run("test", args ++ @adoption_test_files)
end
```

**Compatibility-wrapper pattern** ([lib/mix/tasks/test.adoption.ex](/Users/jon/projects/scoria/lib/mix/tasks/test.adoption.ex:30)):
```elixir
defmodule Mix.Tasks.Test.Adoption do
  use Mix.Task

  @shortdoc "Compatibility wrapper for the explicit Scoria adoption verification lane"

  def run(args), do: Mix.Tasks.Scoria.Test.Adoption.run(args)
end
```

Copy this file’s “implementation task + public wrapper in one file” pattern for lane naming changes.

---

### `lib/mix/tasks/test.semantic_fast_path.ex` (utility, request-response)

**Analog:** `lib/mix/tasks/test.semantic_fast_path.ex`

**Thin public wrapper pattern** ([lib/mix/tasks/test.semantic_fast_path.ex](/Users/jon/projects/scoria/lib/mix/tasks/test.semantic_fast_path.ex:1)):
```elixir
defmodule Mix.Tasks.Test.SemanticFastPath do
  use Mix.Task

  @shortdoc "Compatibility wrapper for the explicit Scoria semantic fast-path verification lane"

  def run(args), do: Mix.Tasks.Scoria.Test.SemanticFastPath.run(args)
end
```

If Phase 49 changes wording only, keep this file thin and redirect all real behavior to the namespaced implementation task.

---

### `lib/mix/tasks/scoria.test.knowledge.ex` (utility, batch)

**Analog:** `lib/mix/tasks/scoria.test.knowledge.ex`

**Knowledge-lane setup pattern** ([lib/mix/tasks/scoria.test.knowledge.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.test.knowledge.ex:1)):
```elixir
defmodule Mix.Tasks.Scoria.Test.Knowledge do
  use Mix.Task

  @shortdoc "Runs the explicit knowledge/full verification lane"

  def run(args) do
    Mix.Task.run("loadpaths")
    Mix.Task.reenable("scoria.pgvector.bootstrap")
    Mix.Task.reenable("app.start")
    System.put_env("SCORIA_TEST_INCLUDE_KNOWLEDGE", "true")
```

**Canonical public alias already exists** ([lib/mix/tasks/scoria.test.knowledge.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.test.knowledge.ex:23)):
```elixir
defmodule Mix.Tasks.Test.Knowledge do
  use Mix.Task

  @shortdoc "Compatibility wrapper for the explicit Scoria knowledge verification lane"

  def run(args), do: Mix.Tasks.Scoria.Test.Knowledge.run(args)
end
```

Planner note: no new `lib/mix/tasks/test.knowledge.ex` file is needed unless the team explicitly wants to split the wrapper out; the public alias is already present here.

---

### `mix.exs` (config, transform)

**Analog:** `mix.exs`

**Preferred-env alias pattern** ([mix.exs](/Users/jon/projects/scoria/mix.exs:22)):
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

**Publish-surface package/docs inventory** ([mix.exs](/Users/jon/projects/scoria/mix.exs:78)):
```elixir
extras: [
  "README.md",
  "docs/adoption_lanes.md",
  "docs/phoenix_runtime_example.md",
  "docs/bounded_handoffs.md",
  "docs/semantic_fast_path.md",
  "docs/operator_verification.md"
]
```

Keep all public verifier aliases discoverable here whenever command naming changes.

---

### `test/scoria/adoption_surface_test.exs` (test, transform)

**Analog:** `test/scoria/adoption_surface_test.exs`

**Doc truth-assertion pattern** ([test/scoria/adoption_surface_test.exs](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs:14)):
```elixir
content = File.read!(@readme)

assert content =~ "Scoria is shipped through `v2.1 Tenant-scoped semantic fast path`"
...
assert content =~ "Optional knowledge lane"
...
refute content =~ "Scoria is shipped through `v1.9 Crucible`"
```

**Lane-order assertions** ([test/scoria/adoption_surface_test.exs](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs:42)):
```elixir
content = File.read!(@lane_guide)

assert content =~ "mix test.adoption"
assert content =~ "mix test.semantic_fast_path"
assert content =~ "mix scoria.test.knowledge"
assert content =~ "This lane is explicitly optional."
```

**Operator-guide support-truth assertions** ([test/scoria/adoption_surface_test.exs](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs:139)):
```elixir
assert content =~ "mix scoria.install"
assert content =~ "mix ecto.migrate"
assert content =~ "mix test"
assert content =~ "mix test.adoption"
...
assert content =~ "broader repo-health context"
```

This is the main anti-drift seam for Phase 49. Extend this file before adding new targeted doc tests elsewhere.

---

### `test/mix/tasks/test.adoption_test.exs` (test, batch)

**Analog:** `test/mix/tasks/test.adoption_test.exs`

**Discoverability contract pattern** ([test/mix/tasks/test.adoption_test.exs](/Users/jon/projects/scoria/test/mix/tasks/test.adoption_test.exs:4)):
```elixir
Mix.Task.load_all()
...
assert Code.ensure_loaded?(Mix.Tasks.Scoria.Test.Adoption)
assert function_exported?(Mix.Tasks.Scoria.Test.Adoption, :adoption_test_files, 0)
assert function_exported?(Mix.Tasks.Test.Adoption, :run, 1)
assert Mix.Task.get("scoria.test.adoption")
assert Mix.Task.get("test.adoption")
```

**Bounded-subset assertion pattern** ([test/mix/tasks/test.adoption_test.exs](/Users/jon/projects/scoria/test/mix/tasks/test.adoption_test.exs:7)):
```elixir
expected_files = [
  ...
  "test/scoria/host_app_consumer_proof_test.exs",
  ...
]

refute Enum.any?(expected_files, &String.contains?(&1, "semantic_cache"))
refute "test/scoria/knowledge_test.exs" in expected_files
```

Use this test to lock the default-lane subset anytime `@adoption_test_files` changes.

---

### `test/mix/tasks/test.semantic_fast_path_test.exs` (test, batch)

**Analog:** `test/mix/tasks/test.semantic_fast_path_test.exs`

**Public-wrapper + implementation-task assertions** ([test/mix/tasks/test.semantic_fast_path_test.exs](/Users/jon/projects/scoria/test/mix/tasks/test.semantic_fast_path_test.exs:4)):
```elixir
assert Code.ensure_loaded?(Mix.Tasks.Scoria.Test.SemanticFastPath)
assert function_exported?(Mix.Tasks.Scoria.Test.SemanticFastPath, :semantic_fast_path_test_files, 0)
assert function_exported?(Mix.Tasks.Test.SemanticFastPath, :run, 1)
assert Mix.Task.get("scoria.test.semantic_fast_path")
assert Mix.Task.get("test.semantic_fast_path")
```

**Lane-boundary guard pattern** ([test/mix/tasks/test.semantic_fast_path_test.exs](/Users/jon/projects/scoria/test/mix/tasks/test.semantic_fast_path_test.exs:7)):
```elixir
expected_files = [
  "test/scoria/runtime/semantic_fast_path_test.exs",
  ...
]

refute "test/scoria/adoption_surface_test.exs" in expected_files
```

Reuse this style to keep semantic troubleshooting separate from adoption truth tests.

---

### `test/mix/tasks/scoria.test_knowledge_test.exs` (test, batch)

**Analog:** `test/mix/tasks/scoria.test_knowledge_test.exs`

**Alias-support contract** ([test/mix/tasks/scoria.test_knowledge_test.exs](/Users/jon/projects/scoria/test/mix/tasks/scoria.test_knowledge_test.exs:4)):
```elixir
assert Code.ensure_loaded?(Mix.Tasks.Scoria.Test.Knowledge)
assert function_exported?(Mix.Tasks.Scoria.Test.Knowledge, :run, 1)
assert function_exported?(Mix.Tasks.Test.Knowledge, :run, 1)
assert Mix.Task.get("scoria.test.knowledge")
assert Mix.Task.get("test.knowledge")
```

This is the exact guard for “canonical public name changes, compatibility alias remains.”

---

### `test/mix/tasks/scoria.install_test.exs` (test, file-I/O)

**Analog:** `test/mix/tasks/scoria.install_test.exs`

**Installer shell-capture pattern** ([test/mix/tasks/scoria.install_test.exs](/Users/jon/projects/scoria/test/mix/tasks/scoria.install_test.exs:57)):
```elixir
output = capture_install_run(%{
  router_path: router_path,
  tailwind_path: tailwind_path,
  config_path: config_path
})

assert output =~ "Installed:"
assert output =~ "Skipped intentionally:"
assert output =~ "Optional later lanes:"
```

**Optional-lane inventory assertions** ([test/mix/tasks/scoria.install_test.exs](/Users/jon/projects/scoria/test/mix/tasks/scoria.install_test.exs:75)):
```elixir
assert output =~ "mix test.adoption"
assert output =~
         ~s(SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix test.semantic_fast_path)
assert output =~ "mix scoria.pgvector.bootstrap"
assert output =~ "mix scoria.test.knowledge"
```

**Idempotency pattern** ([test/mix/tasks/scoria.install_test.exs](/Users/jon/projects/scoria/test/mix/tasks/scoria.install_test.exs:85)):
```elixir
assert output =~ "Router import and /scoria dashboard mount already present."
assert output =~ "Scoria core migrations already present in priv/repo/migrations."
assert output =~ "Baseline Scoria runtime defaults already present."
```

Use this test as the concrete analog for installer message rewrites.

---

### `test/mix/tasks/scoria.release_preview_test.exs` (test, batch)

**Analog:** `test/mix/tasks/scoria.release_preview_test.exs`

**Required-inventory lock pattern** ([test/mix/tasks/scoria.release_preview_test.exs](/Users/jon/projects/scoria/test/mix/tasks/scoria.release_preview_test.exs:4)):
```elixir
expected_required_paths = [
  "README.md",
  "LICENSE",
  "mix.exs",
  "lib/scoria.ex",
  ...
  "docs/operator_verification.md"
]
...
assert Mix.Tasks.Scoria.ReleasePreview.required_package_paths() == expected_required_paths
```

Use this file whenever docs/package inventory changes under `mix scoria.release_preview`.

## Shared Patterns

### Canonical command hierarchy
**Source:** [docs/operator_verification.md](/Users/jon/projects/scoria/docs/operator_verification.md:135), [README.md](/Users/jon/projects/scoria/README.md:163), [lib/mix/tasks/scoria.install.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.install.ex:20)
**Apply to:** `README.md`, `docs/adoption_lanes.md`, `docs/operator_verification.md`, `lib/mix/tasks/scoria.install.ex`, `test/scoria/adoption_surface_test.exs`
```text
closeout: mix scoria.release_preview -> mix test.adoption
default adoption: mix scoria.install -> mix ecto.migrate -> mix test.adoption
optional troubleshooting: mix test.semantic_fast_path
optional knowledge: mix scoria.pgvector.bootstrap -> mix scoria.test.knowledge / mix test.knowledge
repo-health context only: mix test
```

### Compatibility alias pattern
**Source:** [lib/mix/tasks/test.adoption.ex](/Users/jon/projects/scoria/lib/mix/tasks/test.adoption.ex:30), [lib/mix/tasks/test.semantic_fast_path.ex](/Users/jon/projects/scoria/lib/mix/tasks/test.semantic_fast_path.ex:1), [lib/mix/tasks/scoria.test.knowledge.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.test.knowledge.ex:23), [mix.exs](/Users/jon/projects/scoria/mix.exs:22)
**Apply to:** `lib/mix/tasks/*`, `mix.exs`, task discoverability tests
```elixir
defmodule Mix.Tasks.Test.Adoption do
  use Mix.Task
  def run(args), do: Mix.Tasks.Scoria.Test.Adoption.run(args)
end
```

Planner note: keep one promoted public command per lane in docs, but preserve both task registrations and `preferred_envs`.

### Adoption-surface truth tests
**Source:** [test/scoria/adoption_surface_test.exs](/Users/jon/projects/scoria/test/scoria/adoption_surface_test.exs:14)
**Apply to:** all adopter-facing docs and command-family copy
```elixir
content = File.read!(@operator_guide)
assert content =~ "mix test.adoption"
assert content =~ "broader repo-health context"
refute content =~ "..."
```

### Installer summary contract
**Source:** [lib/mix/tasks/scoria.install.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.install.ex:200), [test/mix/tasks/scoria.install_test.exs](/Users/jon/projects/scoria/test/mix/tasks/scoria.install_test.exs:69)
**Apply to:** `lib/mix/tasks/scoria.install.ex`, `test/mix/tasks/scoria.install_test.exs`
```text
Installed:
Skipped intentionally:
Optional later lanes:
```

### Release-preview inventory contract
**Source:** [lib/mix/tasks/scoria.release_preview.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.release_preview.ex:4), [test/mix/tasks/scoria.release_preview_test.exs](/Users/jon/projects/scoria/test/mix/tasks/scoria.release_preview_test.exs:7)
**Apply to:** `lib/mix/tasks/scoria.release_preview.ex`, `test/mix/tasks/scoria.release_preview_test.exs`, `mix.exs`
```elixir
@required_package_paths [...]
assert Mix.Tasks.Scoria.ReleasePreview.required_package_paths() == expected_required_paths
```

## No Analog Found

None. Every likely Phase 49 file already has an exact in-repo analog because this phase is a drift/alignment pass over existing docs, tasks, and tests.

## Metadata

**Analog search scope:** `README.md`, `docs/`, `lib/mix/tasks/`, `mix.exs`, `test/scoria/`, `test/mix/tasks/`, `.planning/METHODOLOGY.md`, `.planning/phases/48-host-app-install-contract-and-consumer-proof/`
**Files scanned:** 20+
**Pattern extraction date:** 2026-05-26
