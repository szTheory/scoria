# Phase 4: Evaluation Flywheel - Pattern Map

**Mapped:** 2024-05-10
**Files analyzed:** 8
**Analogs found:** 7 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria_eval/datasets/dataset.ex` | schema | storage | `lib/scoria/repo/trace.ex` | exact |
| `lib/scoria_eval/datasets/item.ex` | schema | storage | `lib/scoria/repo/span.ex` | exact |
| `lib/scoria_eval/eval_specs/eval_spec.ex` | schema | storage | `lib/scoria/observe/approval.ex` | role-match |
| `lib/scoria_eval/runs/eval_run.ex` | schema | storage | `lib/scoria/observe/approval.ex` | role-match |
| `lib/scoria_web/live/dataset_live/promote_component.ex` | component | request-response | `lib/scoria_web/components/trace_tree_component.ex` | exact |
| `lib/scoria_web/live/eval_spec_live/index.ex` | liveview | request-response | `lib/scoria_web/live/orchestrator_live.ex` | exact |
| `lib/mix/tasks/scoria.eval.ex` | mix task | command-line | `lib/mix/tasks/scoria.install.ex` | exact |
| `test/support/eval_case.ex` | test support | test | No Analog Found | N/A |

## Pattern Assignments

### Ecto Schemas (`lib/scoria_eval/**/*.ex`)

**Analog:** `lib/scoria/repo/trace.ex` and `lib/scoria/repo/span.ex`

**Imports pattern** (`lib/scoria/repo/trace.ex` lines 1-3):
```elixir
defmodule Scoria.Repo.Trace do
  use Ecto.Schema
  import Ecto.Changeset
```

**Core Schema Pattern** (`lib/scoria/repo/trace.ex` lines 5-13):
```elixir
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_traces" do
    field(:session_id, :string)
    field(:attributes, :map, default: %{})

    has_many(:spans, Scoria.Repo.Span)

    timestamps(type: :utc_datetime_usec)
  end
```

**Validation/Changeset Pattern** (`lib/scoria/repo/span.ex` lines 20-31):
```elixir
  def changeset(span, attrs) do
    span
    |> cast(attrs, [
      :trace_id,
      :parent_id,
      :name,
      :span_kind,
      :status_code,
      :start_time,
      :end_time,
      :attributes
    ])
    |> validate_required([:trace_id, :name, :start_time])
  end
```

---

### LiveView Components (`lib/scoria_web/live/dataset_live/promote_component.ex`)

**Analog:** `lib/scoria_web/components/trace_tree_component.ex`

**Core Pattern** (`lib/scoria_web/components/trace_tree_component.ex` lines 1-13):
```elixir
defmodule ScoriaWeb.TraceTreeComponent do
  use Phoenix.LiveComponent

  def mount(socket) do
    {:ok, assign(socket, active_span_id: nil)}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
```

**Event Handling / Async Pattern** (`lib/scoria_web/components/trace_tree_component.ex` lines 10-21):
```elixir
  def handle_event("load_metadata", %{"span_id" => span_id}, socket) do
    socket =
      socket
      |> assign(:active_span_id, span_id)
      |> assign_async(:active_metadata, fn ->
        Process.sleep(100)
        {:ok, %{active_metadata: "Deep trace metadata loaded lazily for span #{span_id}."}}
      end)

    {:noreply, socket}
  end
```

---

### LiveViews (`lib/scoria_web/live/eval_spec_live/index.ex`)

**Analog:** `lib/scoria_web/live/orchestrator_live.ex`

**Core Pattern** (`lib/scoria_web/live/orchestrator_live.ex` lines 1-17):
```elixir
defmodule ScoriaWeb.OrchestratorLive do
  use Phoenix.LiveView

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

---

### Mix Tasks (`lib/mix/tasks/scoria.eval.ex`)

**Analog:** `lib/mix/tasks/scoria.install.ex`

**Core Pattern** (`lib/mix/tasks/scoria.install.ex` lines 1-14):
```elixir
defmodule Mix.Tasks.Scoria.Install do
  use Mix.Task

  @shortdoc "Installs Scoria dashboard into a Phoenix application"

  def run(_args) do
    # Implementation
  end
```

## Shared Patterns

### DB Foreign Key & Primary Key defaults
**Source:** `lib/scoria/repo/span.ex`
**Apply to:** All Ecto schemas in `scoria_eval`
```elixir
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
```

### Async Test Setup
**Source:** `test/scoria/observe/approval_test.exs`
**Apply to:** All test cases
```elixir
  use ExUnit.Case, async: true
```

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `test/support/eval_case.ex` | test support | test | Standard ExUnit macros like `DataCase` or `ConnCase` are missing from this specific application's `test/support/` structure. Planner should follow standard Elixir/ExUnit Macro conventions (e.g. `__using__` macro for injecting test setup). |

## Metadata

**Analog search scope:** `lib/**/*.ex`, `test/**/*.exs`
**Files scanned:** 40
**Pattern extraction date:** 2024-05-10
