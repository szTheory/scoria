# Phase 13: Public Runtime API and Session Lifecycle - Pattern Map

**Mapped:** 2026-05-14
**Scope:** Phase 13 public runtime API, session lifecycle, inspection, plan authoring
**Primary analogs:** 8

## Planning Patterns

### PLAN.md structure

Use the Phase 12 plan shape directly for Phase 13 plan authoring.

**Frontmatter pattern** from `12-01-PLAN.md` lines 1-53:
```md
---
phase: 12-canonical-runtime-identity
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/scoria.ex
  - lib/scoria/identity.ex
...
requirements:
  - IDEN-01
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

**Body section order** from `12-01-PLAN.md` lines 55-169:
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

### PLAN granularity

Roadmap splits Phase 13 into four narrow plans, not one large execution doc. Copy that granularity from `.planning/ROADMAP.md` lines 37-50:
```md
- [ ] 13-01: Top-Level `Scoria` Runtime API Surface
- [ ] 13-02: Start and Resume Run Contracts
- [ ] 13-03: Run Inspection and Host-App References
- [ ] 13-04: Session Continuity Verification
```

Task granularity in each plan should stay at 1-2 tasks, each with:
- one concrete seam
- one explicit file set
- one targeted verification lane
- a short `done` condition

Analog: `12-02-PLAN.md` lines 103-127 and `12-03-PLAN.md` lines 99-123.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scoria.ex` | provider | request-response | `lib/scoria.ex` | exact |
| `lib/scoria/runtime.ex` | service | request-response | `lib/scoria/workflows/resume.ex` + `lib/scoria/workflows.ex` | composite |
| `lib/scoria/runtime/run_summary.ex` or equivalent curated public view module | utility | transform | `lib/scoria_web/live/workflow_live/show.ex` + `lib/scoria/workflows/run.ex` | composite |
| `lib/scoria/runtime/run_detail.ex` or equivalent advanced inspection view | utility | transform | `lib/scoria_web/live/workflow_live/show.ex` + `lib/scoria/workflows.ex` | composite |
| `test/scoria/runtime_test.exs` | test | request-response | `test/scoria/workflows_test.exs` | role-match |
| `test/scoria/runtime/session_lifecycle_test.exs` | test | request-response | `test/scoria/workflows/integration_test.exs` | exact |
| `test/scoria_test.exs` or top-level facade coverage | test | request-response | `test/scoria/identity_test.exs` style plus `test/scoria/workflows_test.exs` assertions | partial |
| `13-01-PLAN.md` through `13-04-PLAN.md` | config | request-response | Phase 12 plan docs | exact |

## Pattern Assignments

### `lib/scoria.ex` top-level happy-path facade

**Analog:** `lib/scoria.ex`

**Minimal facade pattern** (lines 1-9):
```elixir
defmodule Scoria do
  @moduledoc """
  Public helpers for Scoria host-app integration.
  """

  @doc """
  Normalizes caller-supplied identity into the canonical runtime envelope.
  """
  def identity(attrs \\ %{}), do: Scoria.Identity.normalize(attrs)
end
```

**Apply to Phase 13**
- Keep `Scoria` small and obvious.
- Add `start_run/2`, `resume_run/2`, and inspection helpers here as thin public wrappers.
- Do not move durable workflow logic into `Scoria`; delegate to `Scoria.Runtime` or existing substrate modules.

**Layering rule source:** `13-CONTEXT.md` lines 18-28 and 127-130.

### `lib/scoria/runtime.ex` public runtime layer

**Analog:** `lib/scoria/workflows/resume.ex`

**Thin orchestration wrapper pattern** (lines 1-27):
```elixir
defmodule Scoria.Workflows.Resume do
  @moduledoc """
  Thin recovery entrypoints that reconstruct the next action from durable workflow state.
  """

  alias Scoria.Workflows
  alias Scoria.Workflows.Reconciler

  def resume_run(run_id, opts \\ []) do
    with {:ok, _step} <- Workflows.resume_run(run_id),
         {:ok, _count} <- Reconciler.dispatch_run(run_id, opts) do
      {:ok, Workflows.get_run!(run_id)}
    end
  end
end
```

**Durable substrate call pattern** from `lib/scoria/workflows.ex` lines 501-556:
```elixir
def resume_run(run_id) do
  run = get_run_tree!(run_id)

  case {run.status, List.last(run.checkpoints), latest_pending_approval(run.approvals)} do
    {"waiting_for_approval", _checkpoint, %Approval{status: "approved"} = approval} ->
      Repo.transaction(fn repo ->
        ...
        updated_run =
          run
          |> Run.changeset(%{
            status: "running",
            latest_checkpoint_id: checkpoint.id,
            current_step_id: resumed_step.id
          })
          |> repo.update!()

        {updated_run, resumed_step}
      end)
    {"failed", checkpoint, _approval} when not is_nil(checkpoint) ->
      ...
    _ ->
      {:error, :not_resumable}
  end
end
```

**Apply to Phase 13**
- `Scoria.Runtime.resume_run/2` should wrap exact durable resume seams, not invent new resume truth.
- Keep public runtime orchestration in `with` chains returning `{:ok, value}` / `{:error, reason}`.
- `run_id` stays the only exact resume input; `session_id` helpers must delegate to lookup, never resume directly.

**Public contract rule source:** `13-CONTEXT.md` lines 24-41 and 116-131.

### Start-run public entrypoint

**Analog:** `lib/scoria/workflows.ex`

**Durable create pattern** (lines 80-137):
```elixir
def create_run(attrs \\ %{}) do
  now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
  attrs = Map.new(attrs)
  initial_step = Map.get(attrs, :initial_step) || Map.get(attrs, "initial_step")
  run_attrs = Map.drop(attrs, [:initial_step, "initial_step"])
  identity = Identity.normalize(run_attrs)
  run_attrs = run_attrs_with_identity(run_attrs, identity)
  identity_snapshot = Identity.to_map(identity)

  multi =
    Multi.new()
    |> Multi.insert(
      :run,
      Run.changeset(%Run{}, Map.merge(%{status: "running", started_at: now}, run_attrs))
    )
    |> maybe_insert_initial_step(initial_step, now)
    |> Multi.run(:checkpoint, fn repo, changes ->
      {:ok, insert_checkpoint(repo, changes.run.id, ..., %{transition: "run_started", ...})}
    end)
    |> Multi.run(:event, fn repo, changes ->
      {:ok, insert_event(repo, changes.run.id, ..., %{event_type: "run_started", ...})}
    end)
    |> Multi.update(:run_with_checkpoint, fn changes ->
      Run.changeset(changes.run, %{..., latest_checkpoint_id: changes.checkpoint.id})
    end)

  multi
  |> Repo.transaction()
  |> case do
    {:ok, %{run_with_checkpoint: run}} ->
      broadcast(run.id, {:workflow_updated, run.id})
      {:ok, run}
    {:error, _op, value, _changes} ->
      {:error, value}
  end
end
```

**Input normalization pattern** from `lib/scoria/identity.ex` lines 31-87:
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

**Apply to Phase 13**
- Public `start_run/2` should separate `identity`, runtime options, and initial payload before passing a composed attrs map to the substrate.
- Reuse `Scoria.Identity` as the only input normalization seam.
- Preserve one durable write path built on `Workflows.create_run/1`; do not duplicate transaction logic in the public layer.

### Curated public run summary/detail modules

**Analog:** `lib/scoria/workflows/run.ex`

**Durable truth fields** (lines 9-53):
```elixir
schema "ai_workflow_runs" do
  field :actor_id, :string
  field :tenant_id, :string
  field :session_id, :string
  field :root_role_id, :string
  field :status, :string, default: "running"
  field :current_step_id, :binary_id
  field :latest_checkpoint_id, :binary_id
  field :started_at, :utc_datetime_usec
  field :completed_at, :utc_datetime_usec
  ...
end
```

**Operator projection pattern** from `lib/scoria_web/live/workflow_live/show.ex` lines 68-79:
```elixir
defp load_run(socket, run_id) do
  run = Workflows.get_run_tree!(run_id)
  steps = decorate_steps(run.steps)
  selected_step_id = socket.assigns[:selected_step_id] || default_step_id(steps)

  socket
  |> assign(:page_title, "Workflow Run")
  |> assign(:run, run)
  |> assign(:steps, steps)
  |> assign(:events, run.events)
  |> assign_selection(selected_step_id)
end
```

**UI field emphasis** from `lib/scoria_web/live/workflow_live/show.ex` lines 32-40:
```heex
<h1 class="text-3xl font-semibold">Workflow Run</h1>
<p class="text-sm text-stone-600">Run <span class="font-mono"><%= @run.id %></span></p>
...
<span class="workflow-run-status"><%= @run.status %></span>
```

**Apply to Phase 13**
- Build public inspection views as curated transforms from durable truth, not raw `%Scoria.Workflows.Run{}` exposure.
- Summary should pull directly from durable fields already present on `Run`.
- Detail views may compose `get_run_tree!/1`, but the public return shape must stay schema-independent.
- Include operator-facing references such as run id and approval-wait status, but keep checkpoints/events as advanced detail, not default API surface.

**No exact code analog exists** for a public view-model module. Use the `Run` schema for source fields and the LiveView module as evidence of which fields matter operationally.

### Session lookup and continuity helpers

**Analog:** `lib/scoria/workflows.ex`

**List/query style** (lines 28-46):
```elixir
def list_run_steps(run_id) do
  Step
  |> where([step], step.run_id == ^run_id)
  |> order_by([step], asc: step.sequence)
  |> Repo.all()
end

def list_run_events(run_id) do
  Event
  |> where([event], event.run_id == ^run_id)
  |> order_by([event], asc: event.sequence)
  |> Repo.all()
end
```

**Apply to Phase 13**
- If Phase 13 adds `list_runs_by_session/1` or similar helpers, use explicit Ecto query functions with stable ordering.
- Keep `session_id` helpers in query/list territory only.
- Do not make any session helper polymorphic with resume behavior.

### Public runtime tests

**Unit/persistence analog:** `test/scoria/workflows_test.exs`

**Transactional truth assertions** (lines 38-64):
```elixir
test "create_run/1 writes the root run plus its initial checkpoint and event atomically" do
  assert {:ok, run} =
           Workflows.create_run(%{
             root_role_id: "executor",
             actor: %{id: "actor-1"},
             tenant_id: "tenant-1",
             session_id: "sess-1",
             metadata: %{"goal" => "ship", "actor_id" => "ignored-as-metadata"}
           })

  ...
  assert run.actor_id == "actor-1"
  assert run.session_id == "sess-1"
  assert hd(checkpoints).snapshot["identity"]["actor_id"] == "actor-1"
end
```

**Integration analog:** `test/scoria/workflows/integration_test.exs`

**End-to-end resume path** (lines 80-125):
```elixir
test "a run that pauses for approval can be resumed exactly from stored state" do
  {:ok, run} = Workflows.create_run(%{..., session_id: "run-session"})
  {:ok, approval} = Runtime.execute_step(step.id, handler: {Handlers, :wait_for_approval})
  assert Workflows.get_run!(run.id).status == "waiting_for_approval"

  {:ok, _approval} = Workflows.approve(approval.id, "approved", %{...})
  {:ok, _run} = Resume.resume_run(run.id, handlers: %{"approval" => {Handlers, :succeed}})
  Process.sleep(20)

  assert Workflows.get_run!(run.id).status == "completed"
  assert approved_event.redacted_refs["session_id"] == "run-session"
end
```

**Operator-state analog** (lines 154-184):
```elixir
test "operator-visible LiveView state matches the durable recovery path" do
  ...
  {:ok, view, _html} = live(conn, "/scoria/workflows/#{run.id}")
  ...
  assert render(view) =~ "waiting_for_approval"
  ...
  assert render(view) =~ "completed"
  assert render(view) =~ "step_completed"
end
```

**Apply to Phase 13**
- Split tests the same way the repo already does: unit/persistence, integration/recovery, operator-facing inspection.
- Assert exact `run_id` resume behavior and same-session/new-run behavior separately.
- Keep assertions on durable truth first, then operator/public projection shape second.

## Shared Patterns

### Public layering

**Source:** `lib/scoria.ex` lines 1-9, `lib/scoria/workflows/resume.ex` lines 1-27, `13-CONTEXT.md` lines 18-28

Use a two-layer public shape:
- `Scoria` is the obvious facade for normal Phoenix callers.
- `Scoria.Runtime` can hold fuller runtime contracts.
- `Scoria.Workflows` remains the substrate and should not become the taught happy path again.

### Canonical identity

**Source:** `lib/scoria/identity.ex` lines 31-87

Apply to all public start helpers:
```elixir
def new(attrs \\ %{}), do: normalize(attrs)
def from_conn_assigns(assigns), do: normalize(%{assigns: assigns})
def from_session(session), do: normalize(%{session: session})
def from_mount(attrs), do: normalize(%{mount: attrs})
```

Identity must normalize immediately and then travel as runtime nouns, not framework state.

### Durable truth before projection

**Source:** `lib/scoria/workflows.ex` lines 80-137 and 501-556

Pattern:
- write or transition durable state first
- emit checkpoints/events inside the same transaction
- broadcast after commit
- return `{:ok, run_or_step}` or `{:error, reason}`

Public runtime APIs should wrap this seam, not bypass it.

### Verification lanes

**Source:** `12-01-PLAN.md` lines 114-117 and 154-158; `12-02-PLAN.md` lines 111-125 and 152-156; `12-03-PLAN.md` lines 107-121 and 147-150

Verification style to copy:
- every task gets a narrow automated lane
- the phase doc also lists combined verification commands
- DB-backed tests pin `SCORIA_DB_PORT=55432 MIX_ENV=test`

Expected Phase 13 lane split:
- facade and input-contract tests
- run start/resume contract tests
- inspection/session continuity integration tests

### Threat model style

**Source:** `12-01-PLAN.md` lines 134-152, `12-02-PLAN.md` lines 131-149, `12-03-PLAN.md` lines 127-145

Copy this exact style:
- `## Trust Boundaries` table first
- `## STRIDE Threat Register` table second
- threat IDs scoped per plan, e.g. `T-13-01-01`
- each row names a concrete component and one mitigation sentence

Phase 13-specific trust boundaries should likely include:
- host app public API caller → `Scoria` / `Scoria.Runtime`
- public runtime layer → workflow substrate
- public inspection transform → host-app-facing summary/detail contract
- session lookup helper → exact run resume boundary

## No Exact Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/scoria/runtime.ex` | service | request-response | No current public runtime layer exists; use `Scoria.Workflows.Resume` wrapper style plus `Scoria.Workflows` substrate seams. |
| `lib/scoria/runtime/run_summary.ex` | utility | transform | No current curated public run view-model module exists; use `Run` schema fields and `WorkflowLive.Show` projection emphasis. |
| `lib/scoria/runtime/run_detail.ex` | utility | transform | Operator page exists, but no schema-independent public detail contract exists yet. |

## Metadata

**Analog search scope:** `.planning/phases/12-canonical-runtime-identity`, `.planning/ROADMAP.md`, `lib/scoria*.ex`, `lib/scoria_web/live`, `test/scoria/workflows*`
**Files read:** 13 requested + supporting analogs
**Key repo conclusions:**
- Phase docs are narrow, tasked, and verification-heavy.
- Top-level public modules in this repo stay intentionally thin.
- Durable workflow truth already exists for create, inspect, and exact resume; Phase 13 should wrap and curate it, not replace it.
- Session semantics must stay explicit: `session_id` groups continuity, `run_id` owns exact lifecycle truth.
