# Phase 15: Adoption Surface, Docs, and Example Flow - Pattern Map

**Mapped:** 2026-05-15
**Files analyzed:** 16
**Analogs found:** 8 / 8 anticipated files

## Planning Patterns

### PLAN.md structure

Use the neighboring Keystone execute plans directly for Phase 15 plan authoring.

**Frontmatter pattern** from `13-04-PLAN.md` lines 1-34 and `14-03-PLAN.md` lines 1-38:

```md
---
phase: 15-adoption-surface-docs-and-example-flow
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - README.md
requirements:
  - ADOP-01
must_haves:
  truths:
    - "..."
  artifacts:
    - path: "..."
      provides: "..."
  key_links:
    - from: "..."
      to: "..."
      via: "..."
      pattern: "..."
---
```

**Body section order** from `13-04-PLAN.md` lines 36-134 and `14-03-PLAN.md` lines 40-151:

```md
<objective>...</objective>
<execution_context>...</execution_context>
<context>...</context>
<tasks>...</tasks>
<threat_model>...</threat_model>
<verification>...</verification>
<success_criteria>...</success_criteria>
<output>...</output>
```

### Phase 15 plan granularity

Copy the roadmap split from [ROADMAP.md](/Users/jon/projects/scoria/.planning/ROADMAP.md:66). Phase 15 is already defined as three narrow plans:

- `15-01`: README and public module alignment
- `15-02`: end-to-end Phoenix integration example
- `15-03`: operator-facing verification story and closeout

Each plan should keep the same neighboring pattern:

- 1-2 tasks only
- one narrow seam per task
- explicit `files_modified`
- a targeted verification lane
- a short `done` condition tied to `ADOP-*`

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `README.md` | doc | request-response | `lib/scoria.ex` + `test/scoria/runtime_integration_test.exs` + `lib/mix/tasks/scoria.install.ex` | composite |
| `lib/scoria.ex` | provider | request-response | `lib/scoria.ex` | exact |
| `lib/scoria/runtime.ex` | service | request-response | `lib/scoria/runtime.ex` | exact |
| `docs/phoenix_runtime_quickstart.md` or equivalent new guide | doc | request-response | `test/scoria/runtime_integration_test.exs` + `lib/scoria/identity.ex` + `lib/scoria/runtime.ex` | composite |
| `docs/operator-verification.md` or equivalent README verification section | doc | batch | `lib/mix/tasks/scoria.install.ex` + `test/mix/tasks/scoria.install_test.exs` + `test/mix/tasks/scoria.install_route_smoke_test.exs` | composite |
| `.planning/phases/15-adoption-surface-docs-and-example-flow/15-01-PLAN.md` | config | request-response | `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-04-PLAN.md` | exact-structure |
| `.planning/phases/15-adoption-surface-docs-and-example-flow/15-02-PLAN.md` | config | request-response | `.planning/phases/13-public-runtime-api-and-session-lifecycle/13-04-PLAN.md` | role+flow |
| `.planning/phases/15-adoption-surface-docs-and-example-flow/15-03-PLAN.md` | config | batch | `.planning/phases/14-policy-defaults-and-install-ergonomics/14-03-PLAN.md` | exact-structure |

## Pattern Assignments

### `README.md` (doc, request-response)

**Primary analogs:** `lib/scoria.ex`, `test/scoria/runtime_integration_test.exs`, `lib/mix/tasks/scoria.install.ex`

The README opening should copy the public-facade ordering from `Scoria`, then teach one concrete flow from the runtime integration test, then end the quickstart with the installer’s default-lane verification language.

**Public-surface-first API vocabulary** from [lib/scoria.ex](/Users/jon/projects/scoria/lib/scoria.ex:8), lines 8-46:

```elixir
@doc """
Normalizes caller-supplied identity into the canonical runtime envelope.
"""
def identity(attrs \\ %{}), do: Scoria.Identity.normalize(attrs)

@doc """
Starts a run through the canonical public runtime facade.
"""
def start_run(identity, opts \\ []), do: Runtime.start_run(identity, opts)

@doc """
Resumes a run by exact durable `run_id`.
"""
def resume_run(run_id, opts \\ []), do: Runtime.resume_run(run_id, opts)

@doc """
Returns the stable public summary for a run.
"""
def get_run(run_id), do: Runtime.get_run(run_id)

@doc """
Lists runs that share the same host-owned `session_id`.
"""
def list_runs_for_session(session_id), do: Runtime.list_runs_for_session(session_id)
```

**Canonical quickstart flow** from [runtime_integration_test.exs](/Users/jon/projects/scoria/test/scoria/runtime_integration_test.exs:111), lines 111-157:

```elixir
identity = %{
  actor_id: "public-actor",
  tenant_id: "public-tenant",
  session_id: "shared-session"
}

{:ok, started} =
  Scoria.start_run(identity,
    root_role_id: "executor",
    initial_step: %{sequence: 1, kind: "approval", role_id: "executor", status: "queued"},
    handlers: %{"approval" => {Handlers, :wait_for_approval}}
  )

assert {:ok, resumed} =
         Scoria.resume_run(started.run_id, handlers: %{"approval" => {Handlers, :succeed}})

{:ok, next_run} = Scoria.start_run(identity, root_role_id: "executor")

assert next_run.session_id == started.session_id
assert next_run.run_id != started.run_id

grouped = Scoria.list_runs_for_session("shared-session")
```

**Default verification lane messaging** from [scoria.install.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.install.ex:92), lines 92-108:

```elixir
Mix.shell().info("Scoria installed for the default Phoenix lane.")

Mix.shell().info("""
Next steps:
  mix ecto.migrate
  mix test
  visit /scoria

Optional knowledge lane:
  mix scoria.pgvector.bootstrap
  mix scoria.test.knowledge
""")
```

**Planner guidance**

- Open with `Scoria` the module, not the dashboard, traces, or knowledge.
- Use one obvious quickstart sequence: install, normalize identity, `start_run/2`, store `run_id`, inspect status, `resume_run/2`, open `/scoria/workflows/:run_id`.
- Keep capability buckets below the quickstart.
- Reuse the installer’s exact “default lane” vs “optional knowledge lane” split.

**Anti-pattern to avoid**

Do not copy the current README opening in [README.md](/Users/jon/projects/scoria/README.md:8), lines 8-40, as the primary structure. It currently leads with feature inventory and dashboard framing before the public runtime story.

### `docs/phoenix_runtime_quickstart.md` or equivalent new guide (doc, request-response)

**Primary analogs:** `lib/scoria/identity.ex`, `lib/scoria/runtime.ex`, `test/scoria/runtime_integration_test.exs`

This guide should read like a prose expansion of the existing integration test, not a new architecture story.

**Identity normalization boundary** from [lib/scoria/identity.ex](/Users/jon/projects/scoria/lib/scoria/identity.ex:31), lines 31-70:

```elixir
def new(attrs \\ %{}), do: normalize(attrs)
def from_conn_assigns(assigns), do: normalize(%{assigns: assigns})
def from_session(session), do: normalize(%{session: session})
def from_mount(attrs), do: normalize(%{mount: attrs})

def normalize(attrs) do
  attrs = normalize_map(attrs)
  ...
  %__MODULE__{
    actor_id: ...,
    tenant_id: ...,
    session_id: ...,
    metadata: metadata
  }
end
```

**Lifecycle and inspection layer** from [lib/scoria/runtime.ex](/Users/jon/projects/scoria/lib/scoria/runtime.ex:14), lines 14-33 and 54-80:

```elixir
@doc """
Starts a new run from canonical identity plus explicit runtime options.
"""
def start_run(identity, opts \\ []) do
  with {:ok, %{workflow_attrs: workflow_attrs, dispatch_opts: dispatch_opts}} <-
         Params.start(identity, opts),
       {:ok, run} <- Workflows.create_run(workflow_attrs),
       {:ok, _count} <- maybe_dispatch(run.id, dispatch_opts) do
    {:ok, get_run!(run.id)}
  end
end

@doc """
Returns the curated detailed public view for a run.
"""
def get_run_detail(run_id) do
  {:ok, get_run_detail!(run_id)}
rescue
  NoResultsError -> {:error, :not_found}
end

@doc """
Lists runs that share the same host-owned `session_id`.
"""
def list_runs_for_session(session_id) do
  ...
end
```

**Controller/session/run_id flow** from [runtime_integration_test.exs](/Users/jon/projects/scoria/test/scoria/runtime_integration_test.exs:159), lines 159-203:

```elixir
{:ok, started} =
  Scoria.start_run(
    %{actor_id: "live-actor", tenant_id: "live-tenant", session_id: "live-session"},
    root_role_id: "executor",
    initial_step: %{sequence: 1, kind: "approval", role_id: "executor", status: "queued"},
    handlers: %{"approval" => {Handlers, :wait_for_approval}}
  )

{:ok, view, _html} = live(conn, "/scoria/workflows/#{started.run_id}")

assert render(view) =~ started.run_id
assert render(view) =~ "waiting_for_approval"

{:ok, _summary} =
  Scoria.resume_run(started.run_id, handlers: %{"approval" => {Handlers, :succeed}})

assert render(view) =~ "completed"
```

**Planner guidance**

- Show `Scoria.identity/1` as the edge adapter from `conn.assigns` and host session storage into canonical identity.
- Teach `session_id` as host-owned continuity and `run_id` as exact execution handle.
- Show one approval pause and one explicit `resume_run/2`.
- Link `/scoria/workflows/:run_id` as operator evidence for the same run, not as the business-system record.

### `lib/scoria.ex` public moduledoc and API references (provider, request-response)

**Primary analog:** `lib/scoria.ex`

If Phase 15 updates public module docs, keep them thin and facade-first.

**Exact public surface ordering** from [lib/scoria.ex](/Users/jon/projects/scoria/lib/scoria.ex:1), lines 1-46:

```elixir
defmodule Scoria do
  @moduledoc """
  Public helpers for Scoria host-app integration.
  """

  alias Scoria.Runtime

  def identity(attrs \\ %{}), do: Scoria.Identity.normalize(attrs)
  def start_run(identity, opts \\ []), do: Runtime.start_run(identity, opts)
  def resume_run(run_id, opts \\ []), do: Runtime.resume_run(run_id, opts)
  def get_run(run_id), do: Runtime.get_run(run_id)
  def get_run_detail(run_id), do: Runtime.get_run_detail(run_id)
  def list_runs_for_session(session_id), do: Runtime.list_runs_for_session(session_id)
end
```

**Planner guidance**

- `Scoria` stays the README and HexDocs happy path.
- Do not give `Scoria.Runtime` equal visual weight in the first module overview.
- Introduce `Scoria.Identity` immediately after `Scoria`, then `Scoria.Runtime` as deeper lifecycle detail.

### `docs/operator-verification.md` or equivalent README verification section (doc, batch)

**Primary analogs:** `lib/mix/tasks/scoria.install.ex`, `test/mix/tasks/scoria.install_test.exs`, `test/mix/tasks/scoria.install_route_smoke_test.exs`, `test/scoria/runtime_integration_test.exs`

The verification story should copy the repo’s existing “boring core lane first, optional knowledge lane later” contract and then add one real runtime proof.

**Installer contract** from [install_test.exs](/Users/jon/projects/scoria/test/mix/tasks/scoria.install_test.exs:53), lines 53-84:

```elixir
Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path, config_path)
Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path, config_path)

assert updated_router =~ "scoria_dashboard \"/scoria\""
assert updated_tailwind =~ "\"../deps/scoria/lib/**/*.*ex\""
assert updated_config =~ "config :scoria, Scoria.Runtime"
assert updated_config =~ "provider: \"openai\""
```

**Operator route proof** from [install_route_smoke_test.exs](/Users/jon/projects/scoria/test/mix/tasks/scoria.install_route_smoke_test.exs:48), lines 48-60:

```elixir
Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path)
Code.compile_string(File.read!(router_path))

assert Phoenix.Router.route_info(DummyHostInstall.Router, "GET", "/scoria", nil).plug ==
         Phoenix.LiveView.Plug

assert Phoenix.Router.route_info(DummyHostInstall.Router, "GET", "/scoria/workflows/123", nil).plug ==
         Phoenix.LiveView.Plug
```

**Runtime proof pattern** from [runtime_integration_test.exs](/Users/jon/projects/scoria/test/scoria/runtime_integration_test.exs:118), lines 118-156:

```elixir
{:ok, started} = Scoria.start_run(identity, ...)

assert {:ok, resumed} =
         Scoria.resume_run(started.run_id, handlers: %{"approval" => {Handlers, :succeed}})

{:ok, next_run} = Scoria.start_run(identity, root_role_id: "executor")

assert next_run.session_id == started.session_id
assert next_run.run_id != started.run_id

grouped = Scoria.list_runs_for_session("shared-session")
```

**Planner guidance**

- Verification docs should be a two-step story:
- `mix scoria.install`, `mix ecto.migrate`, `mix test`
- then one real `Scoria.start_run/2` plus status readback plus `/scoria/workflows/:run_id`
- Keep `pgvector`, retrieval, grounding, and `mix scoria.test.knowledge` explicitly labeled optional.
- Tie operator evidence to the same `run_id` the host app stores.

### `15-01-PLAN.md`, `15-02-PLAN.md`, `15-03-PLAN.md` (config, request-response/batch)

**Primary analogs:** `13-04-PLAN.md`, `14-03-PLAN.md`

Use the same plan authoring conventions as neighboring phases.

**Task block pattern** from `13-04-PLAN.md` lines 55-95:

```md
<task type="auto">
  <name>Task 1: ...</name>
  <read_first>...</read_first>
  <files>...</files>
  <acceptance_criteria>...</acceptance_criteria>
  <action>...</action>
  <verify>
    <automated>...</automated>
  </verify>
  <done>...</done>
</task>
```

**Verification + success criteria pattern** from `14-03-PLAN.md` lines 131-151:

```md
<verification>
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test ...`
</verification>

<success_criteria>
- ...
- ...
</success_criteria>
```

**Planner guidance**

- `15-01` should mirror Phase 13’s public-surface framing: small API vocabulary, exact semantics, no workflow-substrate-first teaching.
- `15-02` should mirror the runtime integration test and focus on one controller-driven example with approval/resume.
- `15-03` should mirror Phase 14’s verification-lane discipline: installer proof first, runtime proof second, optional knowledge lane clearly separated.

## Shared Patterns

### Public-surface-first teaching

**Sources:** `lib/scoria.ex` lines 1-46, `test/scoria/runtime_test.exs` lines 15-20

```elixir
assert function_exported?(Scoria, :start_run, 2)
assert function_exported?(Scoria, :resume_run, 2)
assert function_exported?(Runtime, :start_run, 2)
assert function_exported?(Runtime, :resume_run, 2)
```

Apply to all docs openings and module overviews. Teach the verbs the public facade actually exports before discussing internals, operator UI, or advanced layers.

### Controller/session/run_id semantics

**Sources:** `lib/scoria/identity.ex` lines 31-70, `test/scoria/runtime_test.exs` lines 68-90, `test/scoria/runtime_integration_test.exs` lines 111-157

```elixir
assert Enum.map(runs, & &1.run_id) |> Enum.sort() == Enum.sort([first.run_id, second.run_id])
assert first.run_id != second.run_id

assert {:error, :invalid_run_id} = Runtime.resume_run(nil)
assert {:error, :invalid_run_id} = Runtime.resume_run("")
```

Apply anywhere Phase 15 explains continuity. The docs must repeat the same rule every time: `session_id` groups turns, `run_id` resumes one exact run.

### Operator evidence linkage

**Sources:** `test/scoria/runtime_integration_test.exs` lines 168-203, `test/mix/tasks/scoria.install_route_smoke_test.exs` lines 52-60

```elixir
{:ok, view, _html} = live(conn, "/scoria/workflows/#{started.run_id}")
assert render(view) =~ started.run_id
assert render(view) =~ "waiting_for_approval"
...
assert Phoenix.Router.route_info(DummyHostInstall.Router, "GET", "/scoria/workflows/123", nil).plug ==
         Phoenix.LiveView.Plug
```

Apply to verification docs and examples. `/scoria/workflows/:run_id` is the operator evidence page for the same durable run, not the app’s source of business truth.

### Installer and verification lane messaging

**Sources:** `lib/mix/tasks/scoria.install.ex` lines 92-108, `test/mix/tasks/scoria.install_test.exs` lines 53-84

```elixir
Next steps:
  mix ecto.migrate
  mix test
  visit /scoria

Optional knowledge lane:
  mix scoria.pgvector.bootstrap
  mix scoria.test.knowledge
```

Apply to README verification, closeout text, and any adoption guide. Keep the core lane boring and default. Mention the knowledge lane only after core success is already proven.

### Validation coverage expectations

**Sources:** `13-04-PLAN.md`, `14-03-PLAN.md`, `ROADMAP.md` lines 66-78

Neighboring phases establish the validation bar Phase 15 should preserve:

- every plan has a concrete automated lane
- verification commands are listed explicitly in the plan body
- success criteria restate the user-visible contract
- tests remain the maintainer closeout proof, but the user-facing docs must add a real runtime proof path

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Dedicated docs site page under `docs/` | doc | request-response | The repo has no existing docs tree. Use `README.md` for prose shape and the runtime/install tests for semantic truth. |
| Runnable host-app sample app under `examples/` | doc | request-response | No example app exists yet. Use `test/scoria/runtime_integration_test.exs` as the canonical behavior source. |

## Metadata

**Analog search scope:** `.planning/`, `README.md`, `lib/`, `test/`
**Files scanned:** 16
**Pattern extraction date:** 2026-05-15
