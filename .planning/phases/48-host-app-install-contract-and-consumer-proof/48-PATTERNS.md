# Phase 48: Host-app install contract and consumer proof - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 9
**Analogs found:** 8 / 9

New files below are inferred from the recommended structure in `48-RESEARCH.md` lines 171-187.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mix/tasks/scoria.install.ex` | utility | file-I/O | `lib/mix/tasks/scoria.install.ex` | exact |
| `test/mix/tasks/scoria.install_test.exs` | test | file-I/O | `test/mix/tasks/scoria.install_test.exs` | exact |
| `test/mix/tasks/scoria.install_route_smoke_test.exs` | test | request-response | `test/mix/tasks/scoria.install_route_smoke_test.exs` | exact |
| `lib/mix/tasks/test.adoption.ex` | utility | batch | `lib/mix/tasks/test.adoption.ex` | exact |
| `test/mix/tasks/test.adoption_test.exs` | test | batch | `test/mix/tasks/test.adoption_test.exs` | exact |
| `test/scoria/host_app_consumer_proof_test.exs` | test | request-response | `test/scoria/runtime_integration_test.exs` | role-match |
| `test/support/scoria/host_app_proof/generator.ex` | utility | file-I/O | `test/scoria/package_surface_test.exs` | flow-match |
| `test/support/scoria/host_app_proof/runner.ex` | utility | batch | `lib/mix/tasks/scoria.release_preview.ex` | flow-match |
| `test/support/scoria/host_app_proof/overlay/*` | config | file-I/O | none | no-analog |

## Pattern Assignments

### `lib/mix/tasks/scoria.install.ex` (utility, file-I/O)

**Analog:** `lib/mix/tasks/scoria.install.ex`

**Discovery + entrypoint pattern** (lines 17-32):
```elixir
def run(_args) do
  router_paths = Path.wildcard("lib/*_web/router.ex")
  tailwind_paths = ["assets/tailwind.config.js", "tailwind.config.js"]
  config_paths = ["config/runtime.exs", "config/config.exs"]

  router_path = List.first(router_paths)
  tailwind_path = Enum.find(tailwind_paths, &File.exists?/1)
  config_path = Enum.find(config_paths, &File.exists?/1)

  if router_path do
    do_run(router_path, tailwind_path, config_path)
    print_next_steps(config_path, tailwind_path)
  else
    Mix.shell().error("Could not find router.ex")
  end
end
```

**Idempotent file mutation pattern** (lines 46-67, 72-90, 147-152):
```elixir
content =
  if content =~ "import ScoriaWeb.Router" do
    content
  else
    Regex.replace(~r/(defmodule .*?\.Router do\n)/, content, "\\1  import ScoriaWeb.Router\n")
  end

content =
  if content =~ "scoria_dashboard" do
    content
  else
    Regex.replace(
      ~r/(scope\s+"\/".*?do\s+.*?pipe_through(?:\s+|\()\:browser\)?\n)/s,
      content,
      "\\1    scoria_dashboard \"/scoria\"\n"
    )
  end

unless content =~ "config :scoria, Scoria.Runtime" do
  File.write!(path, String.trim_trailing(content) <> @runtime_config_snippet <> "\n")
end
```

**Migration copy pattern** (lines 92-105):
```elixir
destination_dir = Path.join([project_root, "priv", "repo", "migrations"])
File.mkdir_p!(destination_dir)

@source_core_migrations
|> Path.join("*.exs")
|> Path.wildcard()
|> Enum.each(fn source_path ->
  destination_path = Path.join(destination_dir, Path.basename(source_path))

  unless File.exists?(destination_path) do
    File.cp!(source_path, destination_path)
  end
end)
```

**User-facing reporting pattern** (lines 155-179):
```elixir
Mix.shell().info("Scoria installed for the default Phoenix lane.")
Mix.shell().info("Copied Scoria core migrations into priv/repo/migrations.")

if config_path do
  Mix.shell().info("Updated #{config_path} with baseline runtime defaults.")
end

if is_nil(tailwind_path) do
  Mix.shell().info("Tailwind config not found; skipped Scoria component content injection.")
end
```

Use this file as the primary source for installer hardening. Keep the regex-patch style, explicit path discovery, and idempotent `if ... =~` guards.

---

### `test/mix/tasks/scoria.install_test.exs` (test, file-I/O)

**Analog:** `test/mix/tasks/scoria.install_test.exs`

**Scratch host setup pattern** (lines 6-52):
```elixir
setup do
  File.mkdir_p!(@tmp_dir)
  File.mkdir_p!(Path.join([@tmp_dir, "lib", "dummy_host_web"]))
  File.mkdir_p!(Path.join(@tmp_dir, "config"))
  File.mkdir_p!(Path.join([@tmp_dir, "priv", "repo", "migrations"]))

  router_path = Path.join([@tmp_dir, "lib", "dummy_host_web", "router.ex"])
  tailwind_path = Path.join(@tmp_dir, "tailwind.config.js")
  config_path = Path.join(@tmp_dir, "config/runtime.exs")

  File.write!(router_path, router_content)
  File.write!(tailwind_path, tailwind_content)
  File.write!(config_path, "import Config\n")

  on_exit(fn -> File.rm_rf!(@tmp_dir) end)

  {:ok, router_path: router_path, tailwind_path: tailwind_path, config_path: config_path}
end
```

**Idempotency assertion pattern** (lines 55-85):
```elixir
Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path, config_path)
Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path, config_path)

updated_router = File.read!(router_path)
assert updated_router =~ "import ScoriaWeb.Router"
assert updated_router =~ "scoria_dashboard \"/scoria\""
assert length(String.split(updated_router, "scoria_dashboard")) == 2

updated_tailwind = File.read!(tailwind_path)
assert updated_tailwind =~ "\"../deps/scoria/lib/**/*.*ex\""
assert length(String.split(updated_tailwind, "../deps/scoria/lib/**/*.*ex")) == 2
```

**Optional-surface coverage pattern** (lines 87-111):
```elixir
test "mix scoria.install keeps the default lane installable when tailwind is absent", %{
  router_path: router_path,
  config_path: config_path
} do
  Mix.Tasks.Scoria.Install.do_run(router_path, nil, config_path)

  assert File.read!(router_path) =~ "scoria_dashboard \"/scoria\""
  assert File.read!(config_path) =~ "config :scoria, Scoria.Runtime"
end
```

Extend this test file for mutation reporting, duplicate prevention, and truthful skip messaging.

---

### `test/mix/tasks/scoria.install_route_smoke_test.exs` (test, request-response)

**Analog:** `test/mix/tasks/scoria.install_route_smoke_test.exs`

**Compile mutated router and inspect metadata** (lines 48-60):
```elixir
Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path)
Code.compile_string(File.read!(router_path))

assert Phoenix.Router.route_info(DummyHostInstall.Router, "GET", "/scoria", nil).plug ==
         Phoenix.LiveView.Plug

assert Phoenix.Router.route_info(DummyHostInstall.Router, "GET", "/scoria/workflows/123", nil).plug ==
         Phoenix.LiveView.Plug
```

**Secondary router-macro analog:** `test/scoria_web/router_test.exs` lines 5-25
```elixir
defmodule DummyRouter do
  use Phoenix.Router
  import ScoriaWeb.Router

  scope "/" do
    pipe_through :browser
    scoria_dashboard("/scoria")
  end
end
```

Keep route smoke narrow: compile, query `Phoenix.Router.route_info/4`, assert plug resolution only.

---

### `lib/mix/tasks/test.adoption.ex` (utility, batch)

**Analog:** `lib/mix/tasks/test.adoption.ex`

**Bounded lane file-list pattern** (lines 5-17):
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
  "test/mix/tasks/scoria.install_test.exs",
  "test/mix/tasks/scoria.install_route_smoke_test.exs",
  "test/scoria/bootstrap/migration_lane_compatibility_test.exs"
]
```

**Task wrapper pattern** (lines 21-35):
```elixir
def run(args) do
  Mix.Task.run("loadpaths")
  Mix.Task.reenable("test")
  Mix.Task.run("test", args ++ @adoption_test_files)
end

defmodule Mix.Tasks.Test.Adoption do
  use Mix.Task
  def run(args), do: Mix.Tasks.Scoria.Test.Adoption.run(args)
end
```

**Supporting lane analog:** `lib/mix/tasks/scoria.test.semantic_fast_path.ex` lines 20-27
```elixir
def run(args) do
  Mix.Task.run("loadpaths")
  Mix.Task.run("app.start")
  Migrations.migrate_knowledge!()
  Mix.Task.reenable("test")
  Mix.Task.run("test", args ++ @semantic_fast_path_test_files)
end
```

Add the generated-host proof file to `@adoption_test_files`; do not introduce a second public verifier.

---

### `test/mix/tasks/test.adoption_test.exs` (test, batch)

**Analog:** `test/mix/tasks/test.adoption_test.exs`

**Discoverability + exact file-list contract** (lines 4-29):
```elixir
expected_files = [
  "test/scoria_test.exs",
  "test/scoria/identity_doctest_test.exs",
  "test/scoria/adoption_surface_test.exs",
  "test/scoria/handoff_example_source_test.exs",
  "test/scoria/phoenix_example_source_test.exs",
  "test/scoria/semantic_fast_path_example_source_test.exs",
  "test/scoria/runtime_integration_test.exs",
  "test/scoria/runtime_test.exs",
  "test/mix/tasks/scoria.install_test.exs",
  "test/mix/tasks/scoria.install_route_smoke_test.exs",
  "test/scoria/bootstrap/migration_lane_compatibility_test.exs"
]

assert Mix.Tasks.Scoria.Test.Adoption.adoption_test_files() == expected_files
assert Mix.Task.get("scoria.test.adoption")
assert Mix.Task.get("test.adoption")
```

Update this exact list assertion whenever `test/scoria/host_app_consumer_proof_test.exs` is added.

---

### `test/scoria/host_app_consumer_proof_test.exs` (test, request-response)

**Primary analog:** `test/scoria/runtime_integration_test.exs`

**Host router/endpoint setup pattern** (lines 1-25):
```elixir
defmodule Scoria.RuntimeIntegrationTest.Router do
  use Phoenix.Router
  import ScoriaWeb.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
  end

  scope "/" do
    pipe_through(:browser)
    scoria_dashboard("/scoria")
  end
end
```

**Runtime smoke pattern** (lines 164-209):
```elixir
{:ok, started} =
  Scoria.start_run(
    %{actor_id: "live-actor", tenant_id: "live-tenant", session_id: "live-session"},
    root_role_id: "executor",
    initial_step: %{sequence: 1, kind: "approval", role_id: "executor", status: "queued"},
    handlers: %{"approval" => {Handlers, :wait_for_approval}}
  )

{:ok, view, _html} = live(conn, AdoptionExample.operator_route(started.run_id))
assert render(view) =~ started.run_id
assert render(view) =~ AdoptionExample.waiting_status()
```

**Host wiring + route smoke analog:** `test/mix/tasks/scoria.install_route_smoke_test.exs` lines 48-60
```elixir
Code.compile_string(File.read!(router_path))
assert Phoenix.Router.route_info(DummyHostInstall.Router, "GET", "/scoria", nil).plug ==
         Phoenix.LiveView.Plug
```

**Temp-dir shell-out analog:** `test/scoria/package_surface_test.exs` lines 59-70
```elixir
output_dir = Path.join(System.tmp_dir!(), "scoria-hex-preview-#{System.unique_integer([:positive])}")
on_exit(fn -> File.rm_rf(output_dir) end)

{output, status} =
  System.cmd("mix", ["hex.build", "--unpack", "--output", output_dir],
    cd: File.cwd!(),
    stderr_to_stdout: true
  )

assert status == 0, output
```

Build this new proof as a bounded ExUnit entrypoint: create/generate host, run install+migrate steps, prove `/scoria` wiring, then do only one durable run/readback/operator-page assertion.

---

### `test/support/scoria/host_app_proof/generator.ex` (utility, file-I/O)

**Primary analog:** `test/scoria/package_surface_test.exs`

**Temp-dir lifecycle pattern** (lines 59-61):
```elixir
output_dir = Path.join(System.tmp_dir!(), "scoria-hex-preview-#{System.unique_integer([:positive])}")
on_exit(fn -> File.rm_rf(output_dir) end)
```

**Shell generation pattern** (lines 63-69):
```elixir
{output, status} =
  System.cmd("mix", ["hex.build", "--unpack", "--output", output_dir],
    cd: File.cwd!(),
    stderr_to_stdout: true
  )

assert status == 0, output
```

**Scratch-file setup analog:** `test/mix/tasks/scoria.install_test.exs` lines 6-18, 42-52
```elixir
File.mkdir_p!(@tmp_dir)
File.mkdir_p!(Path.join([@tmp_dir, "lib", "dummy_host_web"]))
File.mkdir_p!(Path.join(@tmp_dir, "config"))

router_path = Path.join([@tmp_dir, "lib", "dummy_host_web", "router.ex"])
config_path = Path.join(@tmp_dir, "config/runtime.exs")
```

Implement this helper as a small module that returns paths and command results, not assertions. Keep cleanup and temp-path generation explicit.

---

### `test/support/scoria/host_app_proof/runner.ex` (utility, batch)

**Primary analog:** `lib/mix/tasks/scoria.release_preview.ex`

**Command orchestration + failure handling pattern** (lines 24-56):
```elixir
Mix.Task.run("loadpaths")

output_dir = release_preview_output_dir()
File.rm_rf!(output_dir)

{output, status} =
  System.cmd("mix", ["hex.build", "--unpack", "--output", output_dir],
    cd: File.cwd!(),
    stderr_to_stdout: true
  )

if status != 0 do
  Mix.raise("hex preview failed:\n#{output}")
end
```

**Human-readable error pattern:** `lib/mix/tasks/scoria.pgvector.bootstrap.ex` lines 163-180
```elixir
case System.cmd("docker", ["compose", "-f", compose_file, "up", "-d"], stderr_to_stdout: true) do
  {output, 0} ->
    Mix.shell().info(output)

  {output, status} ->
    Mix.raise("docker compose failed (#{status}):\n#{output}")
end
```

**Migration helper pattern:** `lib/scoria/test_support/migrations.ex` lines 29-39, 46-53
```elixir
def migrate_core! do
  migrate!([@core_migrations])
end

defp migrate!(paths, opts \\ []) do
  {:ok, _, _} =
    Ecto.Migrator.with_repo(Repo, fn repo ->
      Ecto.Migrator.run(repo, paths, :up, Keyword.merge([all: true, log: false], opts))
    end)

  :ok
end
```

Keep this helper procedural and explicit: one function per step (`phx.new`, overlay, `deps.get`, `scoria.install`, `ecto.migrate`, smoke command), each returning either `{:ok, result}` or raising with captured output.

---

### `test/support/scoria/host_app_proof/overlay/*` (config, file-I/O)

**Analog:** none in repo

Use the research guidance instead of forcing a weak analog:

- Keep the overlay tiny and test-only.
- Prefer plain template files over a second checked-in sample app.
- Limit overlay contents to whatever is required for dependency wiring and one runtime smoke.

Nearest style reference for documentation fragments only: `test/support/scoria/adoption_example.ex` lines 8-21. That file shows the repo preference for small literal helpers and stable strings, but it is not a real template analog.

## Shared Patterns

### Installer mutation guards
**Source:** `lib/mix/tasks/scoria.install.ex` lines 46-67, 72-90, 147-152
**Apply to:** installer hardening and installer-output assertions
```elixir
if content =~ "scoria_dashboard" do
  content
else
  Regex.replace(..., content, ...)
end
```

### Named verification lanes
**Source:** `lib/mix/tasks/test.adoption.ex` lines 21-35; `lib/mix/tasks/scoria.test.knowledge.ex` lines 7-19
**Apply to:** any new internal proof wiring
```elixir
Mix.Task.run("loadpaths")
Mix.Task.reenable("test")
Mix.Task.run("test", args ++ @adoption_test_files)
```

### Temp-dir shell execution
**Source:** `test/scoria/package_surface_test.exs` lines 59-70; `lib/mix/tasks/scoria.release_preview.ex` lines 35-43
**Apply to:** generated-host harness helpers
```elixir
{output, status} =
  System.cmd("mix", [...], cd: File.cwd!(), stderr_to_stdout: true)

assert status == 0, output
```

### Route-resolution smoke
**Source:** `test/mix/tasks/scoria.install_route_smoke_test.exs` lines 52-60; `test/scoria_web/router_test.exs` lines 19-25
**Apply to:** generated-host proof after host compilation
```elixir
assert Phoenix.Router.route_info(DummyRouter, "GET", "/scoria/workflows/123", nil).plug ==
         Phoenix.LiveView.Plug
```

### Bounded runtime proof depth
**Source:** `test/scoria/runtime_integration_test.exs` lines 120-162, 164-209
**Apply to:** generated-host durable-run smoke
```elixir
{:ok, started} = Scoria.start_run(identity, ...)
{:ok, resumed} = Scoria.resume_run(started.run_id, ...)
grouped = Scoria.list_runs_for_session(AdoptionExample.shared_session_id())
```

For the generated host, stop earlier than this file does. Reuse its setup and assertion style, but keep only one narrow runtime check.

### Migration-lane boundary proof
**Source:** `test/scoria/bootstrap/migration_lane_compatibility_test.exs` lines 18-58; `lib/scoria/test_support/migrations.ex` lines 29-53
**Apply to:** keeping default-lane migration proof separate from optional knowledge-lane proof
```elixir
if pgvector_available?() do
  assert :ok = Migrations.migrate_knowledge!()
else
  refute table_exists?("ai_knowledge_sources")
end
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `test/support/scoria/host_app_proof/overlay/*` | config | file-I/O | Research prescribes a tiny overlay directory, but the repo has no existing template-overlay tree to copy directly. |

## Metadata

**Analog search scope:** `lib/mix/tasks`, `lib/scoria/test_support`, `lib/scoria_web`, `test/mix/tasks`, `test/scoria`, `test/scoria_web`, `test/support/scoria`
**Files scanned:** 17
**Pattern extraction date:** 2026-05-25
