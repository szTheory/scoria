# Phase 51: Default-lane verifier hardening and support-truth re-closeout - Pattern Map

**Mapped:** 2026-05-26
**Files analyzed:** 13
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/test.adoption.ex` | task/config | request-response | `lib/mix/tasks/test.adoption.ex` | exact-existing |
| `test/mix/tasks/test.adoption_test.exs` | test | request-response | `test/mix/tasks/test.adoption_test.exs` | exact-existing |
| `test/scoria/host_app_consumer_proof_test.exs` | test | request-response | `test/scoria/host_app_consumer_proof_test.exs` | exact-existing |
| `test/support/scoria/host_app_proof/runner.ex` | utility | batch | `test/support/scoria/host_app_proof/runner.ex` | exact-existing |
| `test/support/scoria/host_app_proof/generator.ex` | utility | file-I/O | `test/support/scoria/host_app_proof/generator.ex` | exact-existing |
| `test/support/scoria/host_app_proof/overlay/test/host_route_smoke_test.exs` | test | request-response | `test/support/scoria/host_app_proof/overlay/test/host_route_smoke_test.exs` | exact-existing |
| `test/support/scoria/host_app_proof/overlay/test/host_runtime_smoke_test.exs` | test | request-response | `test/support/scoria/host_app_proof/overlay/test/host_runtime_smoke_test.exs` | exact-existing |
| `README.md` | config | request-response | `README.md` | exact-existing |
| `docs/operator_verification.md` | config | request-response | `docs/operator_verification.md` | exact-existing |
| `docs/adoption_lanes.md` | config | request-response | `docs/adoption_lanes.md` | exact-existing |
| `lib/mix/tasks/scoria.install.ex` | task/config | file-I/O | `lib/mix/tasks/scoria.install.ex` | exact-existing |
| `test/scoria/adoption_surface_test.exs` | test | transform | `test/scoria/adoption_surface_test.exs` | exact-existing |
| `.planning/phases/49-support-truth-and-adoption-closeout/49-VERIFICATION.md` | config | transform | `.planning/phases/50-release-preview-ci-truth-and-phase-47-verification/50-VERIFICATION.md` | exact-role |

## Pattern Assignments

### `lib/mix/tasks/test.adoption.ex` (task/config, request-response)

**Analog:** `lib/mix/tasks/test.adoption.ex`

**Imports/task wrapper pattern** (lines 1-4, 30-37):
```elixir
defmodule Mix.Tasks.Scoria.Test.Adoption do
  use Mix.Task

  @shortdoc "Runs the adoption-focused default verification lane"
```

```elixir
defmodule Mix.Tasks.Test.Adoption do
  use Mix.Task

  @shortdoc "Compatibility wrapper for the explicit Scoria adoption verification lane"

  @impl Mix.Task
  def run(args), do: Mix.Tasks.Scoria.Test.Adoption.run(args)
end
```

**Core lane-file-list pattern** (lines 5-18):
```elixir
@adoption_test_files [
  "test/scoria_test.exs",
  "test/scoria/identity_doctest_test.exs",
  "test/scoria/adoption_surface_test.exs",
  "test/scoria/handoff_example_source_test.exs",
  "test/scoria/phoenix_example_source_test.exs",
  "test/scoria/semantic_fast_path_example_source_test.exs",
  "test/scoria/runtime_integration_test.exs",
  "test/scoria/runtime_test.exs",
  "test/scoria/host_app_consumer_proof_test.exs",
  "test/mix/tasks/scoria.install_test.exs",
  "test/mix/tasks/scoria.install_route_smoke_test.exs",
  "test/scoria/bootstrap/migration_lane_compatibility_test.exs"
]
```

**Execution pattern** (lines 22-27):
```elixir
@impl Mix.Task
def run(args) do
  Mix.Task.run("loadpaths")
  Mix.Task.reenable("test")
  Mix.Task.run("test", args ++ @adoption_test_files)
end
```

### `test/mix/tasks/test.adoption_test.exs` (test, request-response)

**Analog:** `test/mix/tasks/test.adoption_test.exs`

**Discoverability assertion pattern** (lines 4-33):
```elixir
test "the adoption lane is discoverable and targets the bounded default-suite subset" do
  Mix.Task.load_all()

  expected_files = [
    "test/scoria_test.exs",
    "test/scoria/identity_doctest_test.exs",
    "test/scoria/adoption_surface_test.exs",
    "test/scoria/handoff_example_source_test.exs",
    "test/scoria/phoenix_example_source_test.exs",
    "test/scoria/semantic_fast_path_example_source_test.exs",
    "test/scoria/runtime_integration_test.exs",
    "test/scoria/runtime_test.exs",
    "test/scoria/host_app_consumer_proof_test.exs",
    "test/mix/tasks/scoria.install_test.exs",
    "test/mix/tasks/scoria.install_route_smoke_test.exs",
    "test/scoria/bootstrap/migration_lane_compatibility_test.exs"
  ]

  assert Code.ensure_loaded?(Mix.Tasks.Scoria.Test.Adoption)
  assert function_exported?(Mix.Tasks.Scoria.Test.Adoption, :run, 1)
  assert function_exported?(Mix.Tasks.Scoria.Test.Adoption, :adoption_test_files, 0)
  assert function_exported?(Mix.Tasks.Test.Adoption, :run, 1)
  assert Mix.Tasks.Scoria.Test.Adoption.adoption_test_files() == expected_files
  refute "test/scoria/knowledge_test.exs" in expected_files
  refute "test/scoria/runtime/semantic_fast_path_test.exs" in expected_files
  assert Mix.Task.get("scoria.test.adoption")
  assert Mix.Task.get("test.adoption")
end
```

### `test/scoria/host_app_consumer_proof_test.exs` (test, request-response)

**Analog:** `test/scoria/host_app_consumer_proof_test.exs`

**Host-proof orchestration pattern** (lines 1-23):
```elixir
defmodule Scoria.HostAppConsumerProofTest do
  use ExUnit.Case, async: false

  alias Scoria.TestSupport.HostAppProof.Generator
  alias Scoria.TestSupport.HostAppProof.Runner

  test "generated Phoenix host proves the bounded Scoria adoption path" do
    host = Generator.create_host!(cleanup: &on_exit/1)
    mix_exs = File.read!(Path.join(host.root, "mix.exs"))

    assert mix_exs =~ "{:scoria, path: "

    proof = Runner.run_full_proof!(host)

    assert proof.steps == [
             :deps_get,
             :scoria_install,
             :ecto_create,
             :ecto_migrate,
             :route_smoke,
             :runtime_smoke
           ]
  end
end
```

Use this file itself as the timeout-placement analog: scoped `@tag timeout` or `@moduletag timeout` belongs here rather than in suite-global config.

### `test/support/scoria/host_app_proof/runner.ex` (utility, batch)

**Analog:** `test/support/scoria/host_app_proof/runner.ex`

**Step wrapper pattern** (lines 4-15):
```elixir
def deps_get!(host), do: run_mix!(host, :deps_get, ["deps.get"])
def scoria_install!(host), do: run_mix!(host, :scoria_install, ["scoria.install"])
def ecto_create!(host), do: run_mix!(host, :ecto_create, ["ecto.create"])
def ecto_migrate!(host), do: run_mix!(host, :ecto_migrate, ["ecto.migrate"])

def route_smoke!(host) do
  run_mix!(host, :route_smoke, ["test", host.route_smoke_test, "--trace"])
end

def runtime_smoke!(host) do
  run_mix!(host, :runtime_smoke, ["test", host.runtime_smoke_test, "--trace"])
end
```

**Ordered proof composition pattern** (lines 17-40):
```elixir
def run_full_proof!(host) do
  run_steps(host, [
    &deps_get!/1,
    &scoria_install!/1,
    &ecto_create!/1,
    &ecto_migrate!/1,
    &route_smoke!/1,
    &runtime_smoke!/1
  ])
end

defp run_steps(host, steps) do
  results = Enum.map(steps, & &1.(host))
  %{results: results, steps: Enum.map(results, & &1.step)}
end
```

**Error/reporting and env pattern** (lines 43-73):
```elixir
defp run_mix!(host, step, args) do
  IO.puts("HOST STEP #{step}: mix #{Enum.join(args, " ")}")

  {output, status} =
    System.cmd("mix", args,
      cd: host.root,
      env: host_env(),
      stderr_to_stdout: true
    )

  if status != 0 do
    raise """
    host proof step failed: #{step}
    command: mix #{Enum.join(args, " ")}
    host: #{host.root}

    #{output}
    """
  end

  %{step: step, output: output}
end
```

```elixir
defp host_env do
  [
    {"MIX_ENV", "test"},
    {"SCORIA_DB_HOST", System.get_env("SCORIA_DB_HOST", "localhost")},
    {"SCORIA_DB_PORT", System.get_env("SCORIA_DB_PORT", "5432")},
    {"SCORIA_DB_USERNAME", System.get_env("SCORIA_DB_USERNAME", "postgres")},
    {"SCORIA_DB_PASSWORD", System.get_env("SCORIA_DB_PASSWORD", "postgres")}
  ]
end
```

Planner note: optimize by batching commands here, but keep explicit step names and fail-open output reporting.

### `test/support/scoria/host_app_proof/generator.ex` (utility, file-I/O)

**Analog:** `test/support/scoria/host_app_proof/generator.ex`

**Fresh-host generation pattern** (lines 8-47):
```elixir
def create_host!(opts \\ []) do
  suffix = System.unique_integer([:positive]) |> Integer.to_string()
  app_name = "scoria_host_proof_#{suffix}"
  working_root = Path.join(System.tmp_dir!(), "scoria-host-proof-#{suffix}")
  host_root = Path.join(working_root, app_name)
  repo_root = repo_root()

  run!(
    File.cwd!(),
    [
      "phx.new",
      host_root,
      "--app",
      app_name,
      "--module",
      @host_module,
      "--database",
      "postgres",
      "--no-assets",
      "--no-dashboard",
      "--no-mailer",
      "--no-gettext",
      "--no-install",
      "--no-agents-md"
    ]
  )

  register_cleanup(opts, working_root)
  patch_mix_exs!(host_root, repo_root)
  patch_test_config!(host_root, app_name)
  copy_overlay!(host_root)

  %{
    app_name: app_name,
    db_name: "#{app_name}_test",
    root: host_root,
    repo_root: repo_root,
    route_smoke_test: @route_smoke_test,
    runtime_smoke_test: @runtime_smoke_test
  }
end
```

**Overlay-copy pattern** (lines 50-58):
```elixir
def copy_overlay!(host_root) do
  source_root = Path.join([repo_root(), "test", "support", "scoria", "host_app_proof", "overlay", "test"])
  destination_root = Path.join(host_root, "test")
  File.mkdir_p!(destination_root)

  for source <- Path.wildcard(Path.join(source_root, "*.exs")) do
    File.cp!(source, Path.join(destination_root, Path.basename(source)))
  end
end
```

**Patch-and-fail pattern** (lines 60-67, 132-145):
```elixir
defp patch_mix_exs!(host_root, repo_root) do
  mix_exs = Path.join(host_root, "mix.exs")
  content = File.read!(mix_exs)

  patched =
    Regex.replace(~r/(defp deps do\s*\n\s*\[)/, content, "\\1\n      {:scoria, path: #{inspect(repo_root)}},")

  File.write!(mix_exs, patched)
end
```

```elixir
defp run!(cwd, args) do
  {output, status} =
    System.cmd("mix", args,
      cd: cwd,
      stderr_to_stdout: true
    )

  if status != 0 do
    raise """
    host generation command failed: mix #{Enum.join(args, " ")}

    #{output}
    """
  end
end
```

### `test/support/scoria/host_app_proof/overlay/test/host_route_smoke_test.exs` (test, request-response)

**Analog:** `test/support/scoria/host_app_proof/overlay/test/host_route_smoke_test.exs`

**Minimal route-proof pattern** (lines 1-15):
```elixir
defmodule HostRouteSmokeTest do
  use ExUnit.Case, async: false

  test "installed scoria routes resolve through Phoenix router metadata" do
    assert Phoenix.Router.route_info(ScoriaHostProofWeb.Router, "GET", "/scoria", nil).plug ==
             Phoenix.LiveView.Plug

    assert Phoenix.Router.route_info(
             ScoriaHostProofWeb.Router,
             "GET",
             "/scoria/workflows/123",
             nil
           ).plug == Phoenix.LiveView.Plug
  end
end
```

### `test/support/scoria/host_app_proof/overlay/test/host_runtime_smoke_test.exs` (test, request-response)

**Analog:** `test/support/scoria/host_app_proof/overlay/test/host_runtime_smoke_test.exs`

**ConnCase + shared sandbox pattern** (lines 1-28):
```elixir
defmodule HostRuntimeSmokeTest do
  use ScoriaHostProofWeb.ConnCase, async: false

  alias Ecto.Adapters.SQL.Sandbox

  import Phoenix.LiveViewTest

  defmodule Handlers do
    def wait_for_approval(_step, run) do
      {:waiting_for_approval,
       %{
         tool_name: "publish",
         arguments: %{"env" => "prod"},
         reason: "Need approval",
         actor_id: "operator-host-proof",
         tenant_id: "tenant-host-proof",
         trace_id: "trace-#{run.id}"
       }}
    end
  end

  setup do
    :ok = Sandbox.checkout(Scoria.Repo)
    Sandbox.mode(Scoria.Repo, {:shared, self()})
    Application.put_env(:scoria, :workflow_runtime_handlers, %{"approval" => {Handlers, :wait_for_approval}})
    start_supervised!(Scoria.Workflows.Reconciler)
    :ok
  end
```

**Durable run/readback/operator-evidence smoke pattern** (lines 30-63):
```elixir
test "host proves one durable run, readback, and operator evidence", %{conn: conn} do
  identity = %{actor_id: "host-actor", tenant_id: "host-tenant", session_id: "host-session"}

  {:ok, started} =
    Scoria.start_run(identity,
      root_role_id: "executor",
      initial_step: %{sequence: 1, kind: "approval", role_id: "executor", status: "queued"},
      handlers: %{"approval" => {Handlers, :wait_for_approval}}
    )

  wait_for(fn ->
    case Scoria.get_run(started.run_id) do
      {:ok, summary} -> summary.status == "waiting_for_approval"
      _ -> false
    end
  end)

  {:ok, summary} = Scoria.get_run(started.run_id)
  grouped = Scoria.list_runs_for_session(identity.session_id)
  {:ok, view, _html} = live(operator_conn, "/scoria/workflows/#{started.run_id}")

  assert summary.run_id == started.run_id
  assert summary.session_id == identity.session_id
  assert Enum.any?(grouped, &(&1.run_id == started.run_id))
  assert render(view) =~ started.run_id
  assert render(view) =~ "waiting_for_approval"
end
```

### `README.md` (config, request-response)

**Analog:** `README.md`

**Lane-ordering pattern** (lines 165-192):
```markdown
Default Phoenix lane:

```bash
mix scoria.install
mix ecto.migrate
mix test.adoption
```

Then inspect `/scoria` and `/scoria/workflows/:run_id` for operator evidence from one real run in your app.
```

```markdown
Optional knowledge lane:

```bash
mix scoria.pgvector.bootstrap
mix test.knowledge
```

For the bounded semantic lane:

```bash
SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path
```
```

Use README changes only if lane ordering or canonical verifier wording needs to move in lockstep with operator docs and installer output.

### `docs/operator_verification.md` (config, request-response)

**Analog:** `docs/operator_verification.md`

**Canonical default-lane proof pattern** (lines 17-35):
```markdown
## Step 1: Install preflight

Run the installer and the boring baseline commands first:

```bash
mix scoria.install
mix ecto.migrate
mix test.adoption
```

What this proves:

- the dashboard routes mount at `/scoria`
- the Scoria-owned core tables are available through copied host-app migrations
- baseline runtime defaults are present
- the app passes the bounded default-lane adoption verifier
```

**Maintainer closeout chain pattern** (lines 151-165):
```markdown
## Maintainer closeout

For repository closeout, the canonical proof chain is exactly:

```bash
mix scoria.release_preview
mix test.adoption
```

Use `mix scoria.release_preview` as the canonical maintainer proof for docs-build and package-inventory truth before publish-facing changes merge.
Use `mix test.adoption` as the canonical default-lane verifier for the install, fresh-host install/migrate/route/runtime proof, docs, and migration-lane guards that make up the bounded acceptance harness.
```

### `docs/adoption_lanes.md` (config, request-response)

**Analog:** `docs/adoption_lanes.md`

**Single-command-per-lane pattern** (lines 33-39, 90-117):
```markdown
Proof lane:

```bash
mix scoria.install
mix ecto.migrate
mix test.adoption
```
```

```markdown
Proof lane:

```bash
SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path
```

Proof lane:

```bash
mix scoria.pgvector.bootstrap
mix test.knowledge
```
```

### `lib/mix/tasks/scoria.install.ex` (task/config, file-I/O)

**Analog:** `lib/mix/tasks/scoria.install.ex`

**Optional-lane inventory pattern** (lines 20-25):
```elixir
@optional_later_lanes [
  "mix test.adoption",
  ~s(SCORIA_DB_PORT="${SCORIA_DB_PORT:-5432}" SCORIA_DB_PASSWORD="${SCORIA_DB_PASSWORD:-postgres}" MIX_ENV=test mix test.semantic_fast_path),
  "mix scoria.pgvector.bootstrap",
  "mix test.knowledge"
]
```

**Summary-printing pattern** (lines 200-223):
```elixir
defp print_summary(statuses) do
  Mix.shell().info("Scoria installed for the default Phoenix lane.")
  Mix.shell().info("Default lane verifier: mix test.adoption")
  Mix.shell().info("")
  Mix.shell().info("Installed:")
  ...
  Mix.shell().info("Optional later lanes:")

  Enum.each(statuses.optional_later_lanes, fn line ->
    Mix.shell().info("  - #{line}")
  end)
end
```

### `test/scoria/adoption_surface_test.exs` (test, transform)

**Analog:** `test/scoria/adoption_surface_test.exs`

**README/lane-guide assertion pattern** (lines 14-64):
```elixir
test "README documents the shipped lane model and canonical lane hierarchy" do
  content = File.read!(@readme)
  assert content =~ "mix scoria.install"
  assert content =~ "mix ecto.migrate"
  assert content =~ "mix test.adoption"
  assert content =~ "SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path"
  assert content =~ "mix test.knowledge"
  refute content =~ "mix scoria.test.knowledge"
end
```

```elixir
test "lane selection guide documents the adoption order and optional boundaries" do
  content = File.read!(@lane_guide)
  assert content =~ "mix test.adoption"
  assert content =~ "mix test.semantic_fast_path"
  assert content =~ "mix test.knowledge"
  assert content =~ "This lane is explicitly optional."
end
```

**Operator-guide drift-guard pattern** (lines 150-186):
```elixir
test "operator verification guide documents the four-tier support hierarchy" do
  content = File.read!(@operator_guide)

  assert content =~ "mix scoria.release_preview"
  assert content =~ "mix scoria.install"
  assert content =~ "mix ecto.migrate"
  assert content =~ "mix test"
  assert content =~ "mix test.adoption"
  assert content =~ "mix test.semantic_fast_path"
  assert content =~ "mix test.knowledge"
  assert content =~ "canonical default-lane verifier"
  assert content =~ "fresh-host install/migrate/route/runtime smoke"
  assert content =~ "repository closeout, the canonical proof chain is exactly"
  refute content =~ "MIX_ENV=test mix scoria.release_preview"
  refute content =~ "mix scoria.test.knowledge"
end
```

### `.planning/phases/49-support-truth-and-adoption-closeout/49-VERIFICATION.md` (config, transform)

**Analog:** `.planning/phases/50-release-preview-ci-truth-and-phase-47-verification/50-VERIFICATION.md`

**Frontmatter/report header pattern** (lines 1-15):
```markdown
---
phase: 50-release-preview-ci-truth-and-phase-47-verification
verified: 2026-05-26T13:29:22Z
status: passed
score: 8/8 must-haves verified
overrides_applied: 0
---

# Phase 50: Release-preview CI Truth And Phase 47 Verification Report
```

**Observable-truth ledger pattern** (lines 16-31):
```markdown
## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | ... | ✓ VERIFIED | ... |
| 2 | ... | ✓ VERIFIED | ... |
```

**Behavioral spot-check pattern** (lines 64-77):
```markdown
### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| ... | `MIX_ENV=dev mix scoria.release_preview` | Passed. ... | ✓ PASS |
| ... | `MIX_ENV=test mix test ... --trace` | Passed with `5 tests, 0 failures`. | ✓ PASS |
```

For Phase 49, copy this structure but swap the behavioral section to the locked closeout chain:
`mix scoria.release_preview`
`mix test.adoption`

## Shared Patterns

### Canonical Lane Naming
**Sources:** `lib/mix/tasks/test.adoption.ex` lines 4-27; `docs/operator_verification.md` lines 17-35, 151-165; `docs/adoption_lanes.md` lines 33-39, 90-117
**Apply to:** `README.md`, `docs/operator_verification.md`, `docs/adoption_lanes.md`, `lib/mix/tasks/scoria.install.ex`, `test/mix/tasks/test.adoption_test.exs`, `test/scoria/adoption_surface_test.exs`

```elixir
@shortdoc "Runs the adoption-focused default verification lane"
Mix.Task.run("test", args ++ @adoption_test_files)
```

```markdown
mix scoria.install
mix ecto.migrate
mix test.adoption
```

Rule: one named canonical verifier per lane; default lane remains `mix test.adoption`.

### Scoped Timeout, Not Global Timeout
**Sources:** `test/scoria/host_app_consumer_proof_test.exs` lines 1-23; `test/support/scoria/host_app_proof/runner.ex` lines 43-73
**Apply to:** `test/scoria/host_app_consumer_proof_test.exs`

```elixir
use ExUnit.Case, async: false

test "generated Phoenix host proves the bounded Scoria adoption path" do
  host = Generator.create_host!(cleanup: &on_exit/1)
  proof = Runner.run_full_proof!(host)
  ...
end
```

Rule: put the explicit budget on the host-proof test/module only; do not widen ExUnit defaults suite-wide.

### Fresh-Host Proof Composition
**Sources:** `test/support/scoria/host_app_proof/generator.ex` lines 8-47; `test/support/scoria/host_app_proof/runner.ex` lines 17-40; `test/support/scoria/host_app_proof/overlay/test/host_route_smoke_test.exs` lines 1-15; `test/support/scoria/host_app_proof/overlay/test/host_runtime_smoke_test.exs` lines 30-63
**Apply to:** host-proof generator, runner, overlay smoke tests, and `test/scoria/host_app_consumer_proof_test.exs`

```elixir
%{
  app_name: app_name,
  db_name: "#{app_name}_test",
  root: host_root,
  route_smoke_test: @route_smoke_test,
  runtime_smoke_test: @runtime_smoke_test
}
```

```elixir
%{results: results, steps: Enum.map(results, & &1.step)}
```

Rule: preserve one fresh generated host, public install/create/migrate commands, route visibility, and one durable run/readback/operator-evidence smoke.

### Source-Truth Drift Guards
**Sources:** `test/scoria/adoption_surface_test.exs` lines 14-64, 150-186; `test/mix/tasks/scoria.install_test.exs` lines 57-117
**Apply to:** all README/docs/installer wording changes

```elixir
assert content =~ "mix test.adoption"
assert content =~ "mix test.semantic_fast_path"
assert content =~ "mix test.knowledge"
refute content =~ "mix scoria.test.knowledge"
```

```elixir
assert output =~ "Default lane verifier: mix test.adoption"
assert output =~ "Optional later lanes:"
```

Rule: change public wording and its assertions together.

### Verification Artifact Shape
**Source:** `.planning/phases/50-release-preview-ci-truth-and-phase-47-verification/50-VERIFICATION.md` lines 1-77
**Apply to:** `.planning/phases/49-support-truth-and-adoption-closeout/49-VERIFICATION.md`

```markdown
## Goal Achievement
### Observable Truths
### Behavioral Spot-Checks
### Requirements Coverage
```

Rule: verification files are executable evidence ledgers, not prose summaries.

## No Analog Found

None.

## Metadata

**Analog search scope:** `lib/mix/tasks`, `test/mix/tasks`, `test/scoria`, `test/support/scoria/host_app_proof`, `docs`, `.planning/phases/50-release-preview-ci-truth-and-phase-47-verification`
**Files scanned:** 15
**Pattern extraction date:** 2026-05-26
