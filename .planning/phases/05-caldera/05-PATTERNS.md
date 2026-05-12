# Phase 5: Durable Agent Workflows & Handoffs - Pattern Map

**Mapped:** 2026-05-11
**Files analyzed:** 18
**Analogs found:** 15 / 18

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria/workflows.ex` | service | CRUD | `lib/scoria/eval.ex` | exact |
| `lib/scoria/workflows/run.ex` | schema | CRUD | `lib/scoria/eval/dataset.ex` | role-match |
| `lib/scoria/workflows/step.ex` | schema | CRUD | `lib/scoria/repo/span.ex` | exact |
| `lib/scoria/workflows/checkpoint.ex` | schema | storage | `lib/scoria/repo/span_event.ex` | role-match |
| `lib/scoria/workflows/handoff.ex` | schema | request-response | `lib/scoria/observe/approval.ex` | role-match |
| `lib/scoria/workflows/event.ex` | schema | event-driven | `lib/scoria/repo/span_event.ex` | exact |
| `lib/scoria/workflows/runtime.ex` | runtime/orchestration | event-driven | `lib/scoria/mcp/executor.ex` | role-match |
| `lib/scoria/workflows/supervisor.ex` | runtime/orchestration | event-driven | `lib/scoria/application.ex` | role-match |
| `lib/scoria/workflows/resume.ex` | runtime/orchestration | request-response | `lib/scoria/eval.ex` | partial |
| `lib/scoria_web/live/workflow_live/show.ex` | liveview | request-response | `lib/scoria_web/live/orchestrator_live.ex` | exact |
| `lib/scoria_web/components/workflow_tree_component.ex` | component | request-response | `lib/scoria_web/components/trace_tree_component.ex` | exact |
| `lib/scoria_web/components/workflow_detail_panel_component.ex` | component | request-response | `lib/scoria_web/live/dataset_live/promote_component.ex` | role-match |
| `lib/scoria_web/router.ex` | router | request-response | `lib/scoria_web/router.ex` | exact |
| `priv/repo/migrations/*_create_workflow_tables.exs` | migration | storage | `priv/repo/migrations/20260510174619_create_eval_tables.exs` | exact |
| `lib/mix/tasks/scoria.install.ex` | mix task | file-I/O | `lib/mix/tasks/scoria.install.ex` | exact |
| `test/scoria/workflows_test.exs` | test | CRUD | `test/scoria/eval_test.exs` | exact |
| `test/scoria/workflows/runtime_test.exs` | test | event-driven | `test/scoria/mcp/executor_test.exs` | exact |
| `test/scoria_web/live/workflow_live_test.exs` | test | request-response | `test/scoria_web/live/orchestrator_live_test.exs` | exact |
| `test/scoria_web/components/workflow_tree_component_test.exs` | test | request-response | `test/scoria_web/components/trace_tree_component_test.exs` | exact |
| `test/support/workflow_case.ex` | test support | test | `test/support/eval_case.ex` | exact |

## Pattern Assignments

### `lib/scoria/workflows.ex` (service, CRUD)

**Analog:** `lib/scoria/eval.ex`

**Imports and alias pattern** (`lib/scoria/eval.ex` lines 6-11):
```elixir
import Ecto.Query, warn: false
alias Scoria.Repo

alias Scoria.Eval.Dataset
alias Scoria.Eval.DatasetItem
alias Scoria.Eval.EvalSpec
```

**Transactional write pattern** (`lib/scoria/eval.ex` lines 27-48):
```elixir
Ecto.Multi.new()
|> Ecto.Multi.insert(:dataset, Dataset.changeset(%Dataset{}, attrs_with_defaults))
|> Ecto.Multi.run(:items, fn repo, %{dataset: dataset} ->
  items_results =
    Enum.map(items, fn item_attrs ->
      item_attrs_with_fk = Map.put(item_attrs, :dataset_id, dataset.id)
      %DatasetItem{}
      |> DatasetItem.changeset(item_attrs_with_fk)
      |> repo.insert()
    end)

  case Enum.find(items_results, fn {status, _} -> status == :error end) do
    nil -> {:ok, Enum.map(items_results, fn {:ok, item} -> item end)}
    {:error, changeset} -> {:error, changeset}
  end
end)
|> Repo.transaction()
|> case do
  {:ok, %{dataset: dataset}} -> {:ok, dataset}
  {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
end
```

**Immutable versioning pattern** (`lib/scoria/eval.ex` lines 56-100):
```elixir
new_version = old_dataset.version + 1
old_dataset_changeset = Ecto.Changeset.change(old_dataset, is_current: false)

Ecto.Multi.new()
|> Ecto.Multi.update(:deprecate_old, old_dataset_changeset)
|> Ecto.Multi.insert(:new_dataset, Dataset.changeset(%Dataset{}, new_attrs))
|> Repo.transaction()
```

**Phase 5 application:** use a single context module to own run creation, checkpoint persistence, step completion, approval-state projection, and resume/retry entrypoints. Wrap atomic `run` + `step` + `checkpoint` + `event` writes in `Ecto.Multi`.

---

### Schemas: `lib/scoria/workflows/run.ex`, `step.ex`, `checkpoint.ex`, `handoff.ex`, `event.ex`

**Analogs:** `lib/scoria/eval/dataset.ex`, `lib/scoria/repo/span.ex`, `lib/scoria/repo/span_event.ex`, `lib/scoria/observe/approval.ex`

**Primary key / timestamp convention** (`lib/scoria/eval/dataset.ex` lines 5-16):
```elixir
@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id
schema "ai_datasets" do
  field :entity_id, :binary_id
  field :version, :integer, default: 1
  field :is_current, :boolean, default: true

  timestamps(type: :utc_datetime_usec)
end
```

**Relational workflow-step pattern** (`lib/scoria/repo/span.ex` lines 7-20):
```elixir
schema "ai_spans" do
  field(:name, :string)
  field(:span_kind, :string)
  field(:status_code, :string)
  field(:start_time, :utc_datetime_usec)
  field(:end_time, :utc_datetime_usec)
  field(:attributes, :map, default: %{})
  field(:parent_id, :binary_id)

  belongs_to(:trace, Scoria.Repo.Trace)
  has_many(:events, Scoria.Repo.SpanEvent)
end
```

**Event/checkpoint map payload pattern** (`lib/scoria/repo/span_event.ex` lines 7-20):
```elixir
schema "ai_span_events" do
  field(:name, :string)
  field(:time, :utc_datetime_usec)
  field(:attributes, :map, default: %{})

  belongs_to(:span, Scoria.Repo.Span)
end
```

**Enum validation pattern** (`lib/scoria/observe/approval.ex` lines 17-22):
```elixir
approval
|> cast(attrs, [:tool_name, :arguments, :status, :session_id, :run_id])
|> validate_required([:tool_name, :status])
|> validate_inclusion(:status, ["pending", "approved", "rejected"])
```

**Versioned changeset pattern for root records** (`lib/scoria/eval/dataset.ex` lines 20-25):
```elixir
dataset
|> cast(attrs, [:entity_id, :version, :is_current, :name, :description])
|> validate_required([:entity_id, :version, :is_current, :name])
|> unique_constraint([:entity_id, :version])
```

**Phase 5 application:**
- `run.ex` should follow the versioned-root schema shape from `Dataset` and `EvalSpec` if operator-facing mutation needs exact resume history.
- `step.ex` should follow `Span`: parent/child linkage, status fields, timestamps, and a generic map payload for projected inputs/results.
- `event.ex` and `checkpoint.ex` should follow `SpanEvent`: append-only event rows with map payloads and explicit event/checkpoint time columns.
- `handoff.ex` should follow `Approval`: string status field, map payloads, and simple inclusion validation for typed handoff lifecycle states.

**No direct analog:** Phase 5 explicitly calls for `optimistic_lock` on mutable operator-facing records. There is no current schema using it. Follow standard Ecto convention by adding a `:lock_version` integer column and `optimistic_lock/3` in the changeset for records like `run` if operators can retry/cancel concurrently.

---

### Runtime / Orchestration: `lib/scoria/workflows/runtime.ex`, `supervisor.ex`, `resume.ex`

**Analogs:** `lib/scoria/mcp/executor.ex`, `lib/scoria/application.ex`

**Task isolation pattern** (`lib/scoria/mcp/executor.ex` lines 10-37):
```elixir
context = context || %{}
metadata = Map.merge(context, %{tool: tool_module, args: args})

:telemetry.execute([:scoria, :tool, :started], %{system_time: System.system_time()}, metadata)

task = Task.Supervisor.async_nolink(Scoria.MCP.TaskSupervisor, fn ->
  tool_module.execute(args, context)
end)

case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
  {:ok, result} -> result
  nil -> {:error, :timeout}
  {:exit, reason} -> {:error, :execution_failed}
end
```

**Failure telemetry pattern** (`lib/scoria/mcp/executor.ex` lines 28-36):
```elixir
nil ->
  duration = System.monotonic_time() - start_time
  :telemetry.execute([:scoria, :tool, :timeout], %{duration: duration}, metadata)
  {:error, :timeout}

{:exit, reason} ->
  duration = System.monotonic_time() - start_time
  :telemetry.execute([:scoria, :tool, :failed], %{duration: duration}, Map.put(metadata, :reason, reason))
  {:error, :execution_failed}
```

**Supervisor child registration pattern** (`lib/scoria/application.ex` lines 9-17):
```elixir
children = [
  {Task.Supervisor, name: Scoria.MCP.TaskSupervisor}
]

opts = [strategy: :one_for_one, name: Scoria.Supervisor]
Supervisor.start_link(children, opts)
```

**Phase 5 application:**
- `runtime.ex` should execute bounded delegated steps under a named `Task.Supervisor`, not in LiveView or transient process state.
- Emit explicit lifecycle telemetry or durable events at `run_started`, stable action resolution, before wait states, after side effects, and terminal completion, matching the Phase 5 checkpoint model.
- `resume.ex` should be a thin context-facing orchestrator entrypoint, not a second source of truth. Read persisted `run`/`step`/`checkpoint` state, decide the next action, then hand execution back to the supervised runtime.
- `supervisor.ex` should be added only if the current single-child `Scoria.Application` needs to grow beyond one `Task.Supervisor`; otherwise modify `lib/scoria/application.ex` in place following the existing child-spec list style.

**No direct analog:** there is no current repo example for a durable workflow process that reconstructs state from Ecto after crash/restart. Follow the `MCP.Executor` isolation shape plus the context-owned `Ecto.Multi` writes from `Scoria.Eval`; do not invent a GenServer-owned source of truth.

---

### LiveView Visualizer: `lib/scoria_web/live/workflow_live/show.ex`

**Analog:** `lib/scoria_web/live/orchestrator_live.ex`

**PubSub subscription + assign boot pattern** (`lib/scoria_web/live/orchestrator_live.ex` lines 4-19):
```elixir
def mount(_params, session, socket) do
  if connected?(socket) do
    tenant_id = session["tenant_id"] || "default"
    Phoenix.PubSub.subscribe(Scoria.PubSub, "scoria:runs:#{tenant_id}")
  end

  socket =
    socket
    |> assign(:page_title, "Scoria Dashboard")
    |> assign(:token_buffer, [])
    |> assign(:timer_ref, nil)
    |> assign(:token_text, "")
    |> assign(:active_approval, nil)
    |> stream(:traces, [])

  {:ok, socket}
end
```

**Incremental UI update pattern** (`lib/scoria_web/live/orchestrator_live.ex` lines 22-24):
```elixir
def handle_info({:new_trace, trace}, socket) do
  {:noreply, stream_insert(socket, :traces, trace)}
end
```

**Async drilldown loading pattern** (`lib/scoria_web/live/orchestrator_live.ex` lines 70-75):
```elixir
{:noreply,
 assign_async(socket, :trace_metadata, fn ->
   {:ok, %{trace_metadata: %{id: trace_id, deep_data: "loaded lazily"}}}
 end)}
```

**Form/edit-state pattern for persisted records** (`lib/scoria_web/live/eval_spec_live/index.ex` lines 17-23, 47-57):
```elixir
spec = Eval.get_eval_spec!(id)
changeset = EvalSpec.changeset(spec, %{})

socket
|> assign(:edit_spec, spec)
|> assign(:form, to_form(changeset))
```

```elixir
case Eval.update_eval_spec(spec, parsed_params) do
  {:ok, _new_spec} ->
    {:noreply,
     socket
     |> assign(:edit_spec, nil)
     |> assign(:form, nil)
     |> assign(:eval_specs, Eval.list_eval_specs())}

  {:error, %Ecto.Changeset{} = changeset} ->
    {:noreply, assign(socket, :form, to_form(changeset))}
end
```

**Phase 5 application:** the workflow visualizer should stay a projection layer over persisted workflow state. Subscribe for visibility, but load detail panels, timeline drilldowns, resume/retry state, and checkpoint metadata from the database-backed context.

---

### Components: `lib/scoria_web/components/workflow_tree_component.ex`, `workflow_detail_panel_component.ex`

**Analogs:** `lib/scoria_web/components/trace_tree_component.ex`, `lib/scoria_web/live/dataset_live/promote_component.ex`

**LiveComponent lifecycle pattern** (`lib/scoria_web/components/trace_tree_component.ex` lines 4-10):
```elixir
def mount(socket) do
  {:ok, assign(socket, active_span_id: nil)}
end

def update(assigns, socket) do
  {:ok, assign(socket, assigns)}
end
```

**Flat tree rendering pattern** (`lib/scoria_web/components/trace_tree_component.ex` lines 26-39):
```elixir
<div id={@id} class="trace-tree">
  <%= for span <- @spans do %>
    <div
      class="trace-row pl-[calc(var(--indent-level)*1.5rem)] flex flex-col py-1 border-b"
      style={"--indent-level: #{Map.get(span, :depth, 0)}"}
    >
      <div
        class="trace-span-name font-mono text-sm cursor-pointer hover:bg-gray-100 p-1"
        phx-click="load_metadata"
        phx-value-span_id={Map.get(span, :id, span.name)}
        phx-target={@myself}
      >
```

**Async metadata panel pattern** (`lib/scoria_web/components/trace_tree_component.ex` lines 12-21, 40-53):
```elixir
socket =
  socket
  |> assign(:active_span_id, span_id)
  |> assign_async(:active_metadata, fn ->
    {:ok, %{active_metadata: "Deep trace metadata loaded lazily for span #{span_id}."}}
  end)
```

**Simple form component pattern** (`lib/scoria_web/live/dataset_live/promote_component.ex` lines 33-53):
```elixir
def update(assigns, socket) do
  {:ok,
   socket
   |> assign(assigns)
   |> assign(:form, to_form(%{"name" => ""}))}
end

case Eval.promote_trace_to_dataset(trace, dataset_attrs) do
  {:ok, _dataset} ->
    send(self(), {:trace_promoted, name})
    {:noreply, socket}
```

**Phase 5 application:**
- Keep the primary workflow tree flat and indent-driven like the trace tree; do not switch to nested recursive DOM as the default view.
- Use a separate detail-panel component for checkpoint metadata, failure reasons, and handoff envelopes if that keeps the tree renderer simpler.
- If operator actions like resume/retry/cancel appear in the detail panel, follow the `PromoteComponent` form/event shape and delegate persistence to `Scoria.Workflows`.

---

### Router and install surface: `lib/scoria_web/router.ex`, `lib/mix/tasks/scoria.install.ex`

**Analogs:** `lib/scoria_web/router.ex`, `lib/mix/tasks/scoria.install.ex`

**Router macro pattern** (`lib/scoria_web/router.ex` lines 7-17):
```elixir
defmacro scoria_dashboard(path, _opts \\ []) do
  quote bind_quoted: binding() do
    scope path, alias: false, as: false do
      import Phoenix.LiveView.Router, only: [live: 3, live: 4, live_session: 2, live_session: 3]

      live_session :scoria_dashboard do
        live "/", ScoriaWeb.OrchestratorLive, :index
      end
    end
  end
end
```

**Installer mutation pattern** (`lib/mix/tasks/scoria.install.ex` lines 23-26, 28-48):
```elixir
def do_run(router_path, tailwind_path) do
  inject_router(router_path)
  inject_tailwind(tailwind_path)
end
```

```elixir
content =
  if content =~ "scoria_dashboard" do
    content
  else
    Regex.replace(~r/(scope \"\\/\".*? do.*?pipe_through :browser\\n)/s, content, "\\1    scoria_dashboard \\\"/scoria\\\"\\n")
  end
```

**Phase 5 application:** if the workflow visualizer extends the mounted dashboard rather than adding a second installable surface, keep the same router macro and install-task conventions. If a second LiveView route is added under the dashboard, extend the existing macro rather than introducing a new integration mechanism.

---

### Migrations: `priv/repo/migrations/*_create_workflow_tables.exs`

**Analogs:** `priv/repo/migrations/20260510015813_create_ai_observability_tables.exs`, `priv/repo/migrations/20260510160812_create_ai_approvals.exs`, `priv/repo/migrations/20260510174619_create_eval_tables.exs`

**Binary-id table pattern** (`priv/repo/migrations/20260510015813_create_ai_observability_tables.exs` lines 5-10):
```elixir
create table(:ai_traces, primary_key: false) do
  add :id, :binary_id, primary_key: true
  add :session_id, :string
  add :attributes, :map, default: %{}

  timestamps(type: :utc_datetime_usec)
end
```

**Reference and index pattern** (`priv/repo/migrations/20260510174619_create_eval_tables.exs` lines 19-29):
```elixir
create table(:ai_dataset_items, primary_key: false) do
  add :id, :binary_id, primary_key: true
  add :dataset_id, references(:ai_datasets, on_delete: :delete_all, type: :binary_id), null: false
  add :input, :map, null: false

  timestamps(type: :utc_datetime_usec)
end

create index(:ai_dataset_items, [:dataset_id])
```

**Map-indexing pattern** (`priv/repo/migrations/20260510015813_create_ai_observability_tables.exs` lines 13-15, 49-52):
```elixir
create index(:ai_traces, [:session_id])
create index(:ai_traces, [:attributes], using: "GIN")
```

```elixir
create index(:ai_span_events, [:span_id])
create index(:ai_span_events, [:name])
create index(:ai_span_events, [:time])
create index(:ai_span_events, [:attributes], using: "GIN")
```

**Phase 5 application:**
- Use one migration for tightly coupled workflow tables unless the scope clearly splits into operator records versus append-only event history.
- Root records like `runs` should get unique/index coverage similar to versioned eval tables.
- Append-only `events`/`checkpoints` with map payloads should follow the observability-table GIN-index convention when planner expects filtering by payload fields.

**No direct analog:** there is no existing migration with `lock_version`, partial indexes, or uniqueness rules for “only one current active checkpoint per step”. Follow standard Ecto/Postgres conventions for those constraints if Phase 5 needs them.

---

### Tests: context, runtime, LiveView, component, mix task, support

**Analogs:** `test/scoria/eval_test.exs`, `test/scoria/mcp/executor_test.exs`, `test/scoria_web/live/orchestrator_live_test.exs`, `test/scoria_web/components/trace_tree_component_test.exs`, `test/support/eval_case.ex`, `test/mix/tasks/scoria.install_test.exs`

**Sandboxed context test pattern** (`test/scoria/eval_test.exs` lines 9-13):
```elixir
setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
  Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
  :ok
end
```

**Runtime event/assertion pattern** (`test/scoria/mcp/executor_test.exs` lines 37-63, 65-104):
```elixir
handler_id = "executor-test-#{System.unique_integer()}"
:telemetry.attach_many(handler_id, events, handler, nil)

on_exit(fn ->
  :telemetry.detach(handler_id)
end)
```

```elixir
assert {:error, :timeout} = Executor.execute(DummyTool, %{"action" => "timeout"}, context, 100)
assert_receive {:telemetry_event, ^ref, [:scoria, :tool, :timeout], _measurements, metadata}
```

**LiveView endpoint harness pattern** (`test/scoria_web/live/orchestrator_live_test.exs` lines 1-45):
```elixir
defmodule ScoriaWeb.OrchestratorLiveTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria
  plug Plug.Session,
    store: :cookie,
    key: "_scoria_key",
    signing_salt: "scoria_salt"
  plug ScoriaWeb.OrchestratorLiveTest.Router
end
```

```elixir
setup do
  start_supervised!(ScoriaWeb.OrchestratorLiveTest.Endpoint)
  :ok
end
```

**Component DOM-shape assertion pattern** (`test/scoria_web/components/trace_tree_component_test.exs` lines 15-29):
```elixir
html = render_component(ScoriaWeb.TraceTreeComponent, assigns)

assert html =~ ~s(class="trace-row )
[{_, _, children}] = Floki.parse_fragment!(html)
assert Enum.count(children, fn
  {"div", attrs, _} ->
    Enum.any?(attrs, fn {k, v} -> k == "class" and String.contains?(v, "trace-row") end)
  _ -> false
end) == 2
```

**CaseTemplate support pattern** (`test/support/eval_case.ex` lines 7-24):
```elixir
use ExUnit.CaseTemplate

using do
  quote do
    import Scoria.EvalCase
    import Tribunal
  end
end

setup tags do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
```

**Mix task file-I/O test pattern** (`test/mix/tasks/scoria.install_test.exs` lines 7-65):
```elixir
router_path = Path.join(@tmp_dir, "router.ex")
tailwind_path = Path.join(@tmp_dir, "tailwind.config.js")

File.write!(router_path, router_content)
File.write!(tailwind_path, tailwind_content)

Mix.Tasks.Scoria.Install.do_run(router_path, tailwind_path)
```

**Phase 5 application:**
- `test/scoria/workflows_test.exs` should verify root-run creation, immutable retry/fork semantics if added later, checkpoint persistence, and step/handoff/event writes through the public context API.
- `test/scoria/workflows/runtime_test.exs` should assert supervised execution behavior, timeout/crash isolation, and emitted lifecycle events around resume/retry boundaries.
- `test/scoria_web/live/workflow_live_test.exs` should reuse the endpoint harness from `OrchestratorLiveTest` and assert rendered lifecycle badges, detail-panel loading, and operator actions like resume/retry.
- `test/scoria_web/components/workflow_tree_component_test.exs` should keep DOM assertions flat-tree oriented like `TraceTreeComponentTest`.
- `test/support/workflow_case.ex` should copy `EvalCase` unless Phase 5 needs extra helpers for workflow fixtures or telemetry capture.

## Shared Patterns

### Ecto schema defaults
**Sources:** `lib/scoria/eval/dataset.ex` lines 5-16, `lib/scoria/repo/span.ex` lines 5-20
**Apply to:** all Phase 5 schemas
```elixir
@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id
timestamps(type: :utc_datetime_usec)
```

### Atomic durable writes
**Source:** `lib/scoria/eval.ex` lines 27-48, 71-99
**Apply to:** run start, checkpoint creation, step completion, retry, resume bookkeeping
```elixir
Ecto.Multi.new()
|> Ecto.Multi.insert(...)
|> Ecto.Multi.update(...)
|> Ecto.Multi.run(...)
|> Repo.transaction()
```

### Status validation
**Sources:** `lib/scoria/observe/approval.ex` lines 17-22, `lib/scoria/eval/eval_run.ex` lines 20-27
**Apply to:** `run`, `step`, `handoff`
```elixir
|> validate_inclusion(:status, [...])
|> foreign_key_constraint(...)
```

### LiveView as projection, not truth
**Source:** `lib/scoria_web/live/orchestrator_live.ex` lines 4-19, 70-75
**Apply to:** workflow visualizer and detail panel
```elixir
Phoenix.PubSub.subscribe(...)
assign_async(socket, :trace_metadata, fn -> ... end)
```

### Supervised isolated execution
**Source:** `lib/scoria/mcp/executor.ex` lines 18-36
**Apply to:** delegated workflow steps and resumes
```elixir
task = Task.Supervisor.async_nolink(...)
case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
```

## No Analog Found

Files or concerns with no close in-repo analog:

| File / Concern | Role | Data Flow | Convention To Follow Instead |
|----------------|------|-----------|-------------------------------|
| `lib/scoria/workflows/checkpoint.ex` lock management | schema | storage | Use standard Ecto `optimistic_lock/3` with `:lock_version`; no current schema demonstrates it. |
| `lib/scoria/workflows/resume.ex` exact crash recovery | runtime/orchestration | request-response | Reconstruct next action from Ecto state in the context layer; do not follow PubSub or LiveView state as truth. |
| Workflow timeline/detail drilldown persistence | liveview/component | request-response | Follow `assign_async` loading from `OrchestratorLive`, but source data from durable tables rather than in-memory assigns. |

## Metadata

**Analog search scope:** `lib/**/*.ex`, `priv/repo/migrations/*.exs`, `test/**/*.exs`
**Files scanned:** 35
**Pattern extraction date:** 2026-05-11
