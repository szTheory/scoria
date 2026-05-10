# Phase 3: LiveView Operator UX - Pattern Map

**Mapped:** 2026-05-15
**Files analyzed:** 5
**Analogs found:** 3 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria/observe/approval.ex` | model | CRUD | `lib/scoria/repo/trace.ex` | exact |
| `lib/scoria_web/router.ex` | route | request-response | `lib/scoria/mcp/router.ex` | role-match |
| `lib/scoria_web/live/orchestrator_live.ex` | controller | event-driven | `lib/scoria/observe/buffer.ex` | partial |
| `lib/scoria_web/components/trace_tree_component.ex`| component | UI | None | no-match |
| `lib/mix/tasks/scoria.install.ex` | utility | one-off | None | no-match |

## Pattern Assignments

### `lib/scoria/observe/approval.ex` (model, CRUD)

**Analog:** `lib/scoria/repo/trace.ex`

**Imports pattern** (lines 1-3):
```elixir
defmodule Scoria.Repo.Trace do
  use Ecto.Schema
  import Ecto.Changeset
```

**Core schema pattern** (lines 5-15):
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

**Changeset pattern** (lines 17-21):
```elixir
  def changeset(trace, attrs) do
    trace
    |> cast(attrs, [:session_id, :attributes])
  end
```

---

### `lib/scoria_web/live/orchestrator_live.ex` (controller, event-driven)

**Analog:** `lib/scoria/observe/buffer.ex` (partial match for buffering/timer)

**Token Buffering / Coalescing pattern** (lines 40-47):
```elixir
  @impl true
  def handle_info(:flush, state) do
    flush_spans(state.spans)
    state = %{state | spans: []}
    state = schedule_flush(state)
    {:noreply, state}
  end
```

**Timer Scheduling pattern** (lines 53-57):
```elixir
  defp schedule_flush(state) do
    if state.timer, do: Process.cancel_timer(state.timer)
    timer = Process.send_after(self(), :flush, state.flush_interval)
    %{state | timer: timer}
  end
```

---

### `lib/scoria_web/router.ex` (route, request-response)

**Analog:** `lib/scoria/mcp/router.ex`

**Router Structure pattern** (lines 1-7):
```elixir
defmodule Scoria.MCP.Router do
  @moduledoc """
  Plug router for handling incoming MCP (Model Context Protocol) JSON-RPC 2.0 requests.
  """

  use Plug.Router
```

---

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/scoria_web/components/trace_tree_component.ex` | component | lazy UI | No Phoenix LiveComponents or UI code exists in the current project root. |
| `lib/mix/tasks/scoria.install.ex` | utility | one-off | No Mix tasks exist in the project for generating files or migrations. |

## Metadata

**Analog search scope:** `lib/**/*.ex`
**Files scanned:** 5 expected files
**Pattern extraction date:** 2026-05-15