# Phase 37: Replay Lineage & Branch Model - Research

**Researched:** 2026-05-22
**Domain:** Durable workflow replay lineage on the existing Phoenix/Ecto runtime [VERIFIED: .planning/ROADMAP.md] [VERIFIED: lib/scoria/workflows.ex]
**Confidence:** MEDIUM

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RPLY-01 | Operator can branch a new replay run from a durable source run and chosen checkpoint without mutating original run history. [VERIFIED: .planning/REQUIREMENTS.md] | Add explicit replay lineage columns on `ai_workflow_runs`, create a workflow-owned branch API that seeds a new run from a persisted checkpoint, and expose lineage through `Runtime.RunDetail` plus the workflow and trace explorer surfaces. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: lib/scoria/runtime/run_detail.ex] [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] |
</phase_requirements>

## Summary

Scoria already has the correct execution substrate for Phase 37: `Scoria.Workflows` owns durable run/step/checkpoint/event truth, `Scoria.Workflows.Runtime` executes one bounded step at a time, and `Scoria.Workflows.Reconciler` dispatches runnable steps for a run. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: lib/scoria/workflows/runtime.ex] [VERIFIED: lib/scoria/workflows/reconciler.ex] The safest plan is to add replay lineage as explicit run-level schema, then create replay branches by inserting a brand-new run plus seeded step/checkpoint rows that the existing runtime can execute. [VERIFIED: priv/repo/migrations/20260511000100_create_workflow_tables.exs] [ASSUMED]

The current public run surfaces are close but incomplete for lineage. `Runtime.RunSummary` only exposes lifecycle identifiers, `Runtime.RunDetail` omits snapshot/event payload details and any lineage fields, and `WorkflowLive.Show` renders the selected step and latest checkpoint without any source-run or source-checkpoint context. [VERIFIED: lib/scoria/runtime/run_summary.ex] [VERIFIED: lib/scoria/runtime/run_detail.ex] [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] The trace explorer already carries `workflow_run_id` on trace actions and joins incident/budget evidence by `trace_id` or `workflow_run_id`, so replay lineage can stay queryable there by extending workflow-owned run detail queries instead of inventing a separate trace lineage store. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex]

**Primary recommendation:** Add explicit self-referential replay lineage fields to `ai_workflow_runs`, introduce a `Workflows.create_replay_run/2`-style transaction that seeds a new run from existing checkpoint truth, and expose lineage through the existing `Runtime`, `WorkflowLive`, and trace explorer read paths. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: lib/scoria/runtime.ex] [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] [ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Persist replay branch truth | Database / Storage [VERIFIED: priv/repo/migrations/20260511000100_create_workflow_tables.exs] | API / Backend [VERIFIED: lib/scoria/workflows.ex] | Replay lineage must be durable queryable truth on workflow rows, not ephemeral LiveView state. [VERIFIED: lib/scoria/workflows.ex] |
| Create replay run from source checkpoint | API / Backend [VERIFIED: lib/scoria/workflows.ex] | Database / Storage [VERIFIED: lib/scoria/workflows/checkpoint.ex] | Branch creation is a transactional workflow mutation that should write run, step, checkpoint, and event rows atomically. [VERIFIED: lib/scoria/workflows.ex] |
| Execute replay branch | API / Backend [VERIFIED: lib/scoria/workflows/runtime.ex] | Frontend Server (SSR) [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] | Existing runtime and reconciler already own step dispatch and lifecycle transitions; UI should only trigger or observe them. [VERIFIED: lib/scoria/workflows/runtime.ex] [VERIFIED: lib/scoria/workflows/reconciler.ex] |
| Show lineage in run detail | Frontend Server (SSR) [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] | API / Backend [VERIFIED: lib/scoria/runtime/run_detail.ex] | LiveView should render workflow-owned projections, not recompute lineage in the browser. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] |
| Show lineage in trace explorer | Frontend Server (SSR) [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] | API / Backend [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] | The explorer already pivots from `trace_id` and `workflow_run_id`; lineage should be a run-backed lookup added to that surface. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `1.19.x` via `~> 1.19` project requirement. [VERIFIED: mix.exs] | Language/runtime for the workflow and LiveView stack. [VERIFIED: mix.exs] | The repo already standardizes all runtime and tests on Elixir. [VERIFIED: mix.exs] |
| `ecto_sql` | `3.13.5`. [VERIFIED: mix.lock] | Durable run, step, checkpoint, and event persistence. [VERIFIED: lib/scoria/workflows/run.ex] [VERIFIED: lib/scoria/workflows/checkpoint.ex] | Existing workflow truth and migrations are Ecto-backed already. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: priv/repo/migrations/20260511000100_create_workflow_tables.exs] |
| `postgrex` | `0.22.1`. [VERIFIED: mix.lock] | PostgreSQL adapter for workflow truth. [VERIFIED: mix.lock] | All workflow tables and indexes assume PostgreSQL-backed Ecto persistence. [VERIFIED: priv/repo/migrations/20260511000100_create_workflow_tables.exs] |
| Phoenix LiveView | `1.1.30`. [VERIFIED: mix.lock] | Workflow detail and operator trace explorer surfaces. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] | Replay lineage needs to land in the same operator surfaces Scoria already owns. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] |
| Oban | `2.22.1`. [VERIFIED: mix.lock] | Existing async work infrastructure already in the repo. [VERIFIED: mix.lock] | No evidence shows Phase 37 needs a new worker class, but reuse of current async/runtime seams should stay inside the existing stack. [VERIFIED: lib/scoria/workflows/reconciler.ex] [ASSUMED] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix | `~> 1.7` declared dependency. [VERIFIED: mix.exs] | Route-mounted workflow and dashboard surfaces. [VERIFIED: test/scoria_web/live/workflow_live_test.exs] | Use for LiveView route wiring and controller/session boundaries only. [VERIFIED: test/scoria_web/live/workflow_live_test.exs] |
| `phoenix_ecto` | `4.7.0`. [VERIFIED: mix.lock] | Repo-backed Phoenix integration. [VERIFIED: mix.lock] | Use where LiveView or runtime surfaces need repo-backed workflow reads. [VERIFIED: lib/scoria/runtime.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Explicit replay lineage columns on `ai_workflow_runs`. [VERIFIED: lib/scoria/workflows/run.ex] | Store lineage only inside `metadata` or event payloads. [VERIFIED: lib/scoria/workflows/run.ex] [VERIFIED: lib/scoria/workflows/event.ex] | Metadata-only lineage would not be indexable or easy to join from public run detail and trace explorer surfaces. [VERIFIED: lib/scoria/runtime/run_summary.ex] [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] |
| Existing `Workflows.Runtime` + `Reconciler`. [VERIFIED: lib/scoria/workflows/runtime.ex] [VERIFIED: lib/scoria/workflows/reconciler.ex] | A dedicated replay executor or ad hoc LiveView-driven replay path. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] | A second engine would fork lifecycle semantics away from `claim_step`, `complete_step`, `fail_step`, `resume_run`, and existing tests. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: test/scoria/workflows/integration_test.exs] |

**Installation:** No new dependency is warranted for Phase 37; reuse the current Phoenix/Ecto/LiveView workflow stack. [VERIFIED: mix.exs] [ASSUMED]

**Version verification:** Versions above were read from `mix.exs` and `mix.lock` in this workspace on 2026-05-22. [VERIFIED: mix.exs] [VERIFIED: mix.lock]

## Architecture Patterns

### System Architecture Diagram

```text
Operator chooses source run + checkpoint in UI
  -> Workflow-owned replay branch command (`Scoria.Workflows`)
  -> Ecto.Multi validates source run/checkpoint pair
  -> insert new replay run row with lineage columns
  -> insert seeded replay step(s) + replay-created checkpoint/event
  -> dispatch new run through existing `Reconciler`
  -> `Runtime.execute_step/2` executes seeded step under current lifecycle rules
  -> run/checkpoint/event truth updates
  -> `Runtime.RunDetail` / `WorkflowLive.Show` / trace explorer query lineage by replay run id
```

### Recommended Project Structure

```text
lib/scoria/
├── workflows.ex                    # replay-branch write API and lineage read helpers
├── workflows/run.ex                # explicit lineage schema fields + self associations
├── runtime.ex                      # public branch/detail entrypoints if needed
├── runtime/run_summary.ex          # stable summary lineage fields
└── runtime/run_detail.ex           # public detail lineage payload

lib/scoria_web/
├── live/workflow_live/show.ex      # render replay provenance on run detail page
├── components/workflow_tree_component.ex
├── components/workflow_detail_panel_component.ex
└── live/orchestrator_live.ex       # trace explorer lineage lookup/badges/deep links

priv/repo/migrations/
└── *_add_replay_lineage_to_workflow_runs.exs
```

### Likely Files / Modules To Change

| File | Why it is likely in scope |
|------|---------------------------|
| `priv/repo/migrations/*_add_replay_lineage_to_workflow_runs.exs` | `ai_workflow_runs` currently has no replay lineage columns beyond generic `metadata`; explicit queryable fields need a migration. [VERIFIED: priv/repo/migrations/20260511000100_create_workflow_tables.exs] [VERIFIED: lib/scoria/workflows/run.ex] |
| `lib/scoria/workflows/run.ex` | Run schema needs replay lineage fields and likely self-referential associations for source run / child replays. [VERIFIED: lib/scoria/workflows/run.ex] [ASSUMED] |
| `lib/scoria/workflows.ex` | Branch creation, lineage validation, checkpoint/source loading, and run-level read helpers belong in the workflow context. [VERIFIED: lib/scoria/workflows.ex] |
| `lib/scoria/runtime.ex` | Public runtime APIs currently expose start, resume, summary, and detail only; a replay-branch entrypoint likely belongs here if Phase 37 exposes public creation APIs. [VERIFIED: lib/scoria/runtime.ex] [ASSUMED] |
| `lib/scoria/runtime/run_summary.ex` | Summary currently lacks source run, source checkpoint, execution mode, and replay-child hints. [VERIFIED: lib/scoria/runtime/run_summary.ex] |
| `lib/scoria/runtime/run_detail.ex` | Detail DTO currently omits lineage and rich checkpoint/event payloads needed for replay provenance. [VERIFIED: lib/scoria/runtime/run_detail.ex] |
| `lib/scoria_web/live/workflow_live/show.ex` | Run detail UI currently renders status, steps, checkpoints, and events, but no replay provenance. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] |
| `lib/scoria_web/components/workflow_tree_component.ex` | Tree rows may need replay badges or source markers on the new run. [VERIFIED: lib/scoria_web/components/workflow_tree_component.ex] [ASSUMED] |
| `lib/scoria_web/components/workflow_detail_panel_component.ex` | The detail panel is the current slot for selected-step checkpoint data and is the cleanest place to show source checkpoint, overrides, and execution mode. [VERIFIED: lib/scoria_web/components/workflow_detail_panel_component.ex] |
| `lib/scoria_web/live/orchestrator_live.ex` | Trace explorer already pivots on `workflow_run_id`; replay lineage should be added here through workflow-owned lookup or badges. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] |
| `test/scoria/workflows_test.exs` | Existing durability tests should expand to cover replay branch writes and source/run integrity rules. [VERIFIED: test/scoria/workflows_test.exs] |
| `test/scoria/workflows/integration_test.exs` | Existing resume/retry integration tests are the closest analog for “new run from stored state, then execute through the same engine.” [VERIFIED: test/scoria/workflows/integration_test.exs] |
| `test/scoria/runtime_view_test.exs` | Public summary/detail DTO coverage belongs here. [VERIFIED: test/scoria/runtime_view_test.exs] |
| `test/scoria_web/live/workflow_live_test.exs` | Workflow run LiveView lineage rendering belongs here. [VERIFIED: test/scoria_web/live/workflow_live_test.exs] |
| `test/scoria_web/live/orchestrator_live_test.exs` | Trace explorer lineage actions and badges belong here. [VERIFIED: test/scoria_web/live/orchestrator_live_test.exs] |

### Pattern 1: Workflow-Owned Replay Branch Transaction

**What:** Create replay branches through one `Scoria.Workflows` transaction that validates the source run/checkpoint pair, inserts a brand-new run row, seeds replay step/checkpoint/event truth, and only then dispatches the new run. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: lib/scoria/workflows/reconciler.ex] [ASSUMED]

**When to use:** Use whenever an operator starts replay from a chosen checkpoint. Do not let LiveView, traces, or incident surfaces write branch rows directly. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] [VERIFIED: lib/scoria_web/live/orchestrator_live.ex]

**Example:**

```elixir
# Source pattern: lib/scoria/workflows.ex create_run/1 + mark_waiting_for_approval/3
def create_replay_run(source_run_id, source_checkpoint_id, attrs) do
  Repo.transaction(fn repo ->
    source_run = repo.get!(Run, source_run_id)
    source_checkpoint = repo.get!(Checkpoint, source_checkpoint_id)

    # Validate that the checkpoint belongs to the chosen source run.
    if source_checkpoint.run_id != source_run.id, do: Repo.rollback(:checkpoint_mismatch)

    # Insert a fresh run row with explicit replay lineage.
    replay_run =
      %Run{}
      |> Run.changeset(%{
        root_role_id: source_run.root_role_id,
        actor_id: source_run.actor_id,
        tenant_id: source_run.tenant_id,
        session_id: source_run.session_id,
        status: "running",
        source_run_id: source_run.id,
        source_checkpoint_id: source_checkpoint.id,
        execution_mode: "replay",
        override_metadata: Map.get(attrs, :override_metadata, %{})
      })
      |> repo.insert!()

    # Seed a replay step/checkpoint compatible with the existing runtime.
    # Exact step cloning strategy still needs implementation confirmation.
  end)
end
```

### Pattern 2: Public DTOs Must Carry Lineage Explicitly

**What:** Add replay lineage to `Runtime.RunSummary` and `Runtime.RunDetail` instead of forcing every caller to preload raw workflow structs. [VERIFIED: lib/scoria/runtime/run_summary.ex] [VERIFIED: lib/scoria/runtime/run_detail.ex]

**When to use:** Use for the workflow run page, any public API surface, and trace explorer deep links. [VERIFIED: lib/scoria/runtime.ex] [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] [VERIFIED: lib/scoria_web/live/orchestrator_live.ex]

**Example:**

```elixir
# Source pattern: lib/scoria/runtime/run_summary.ex
defstruct [
  :run_id,
  :session_id,
  :status,
  :actor_id,
  :tenant_id,
  :current_step_id,
  :latest_checkpoint_id,
  :source_run_id,
  :source_checkpoint_id,
  :execution_mode,
  :awaiting_approval,
  :started_at,
  :completed_at
]
```

### Pattern 3: Trace Explorer Should Query Lineage Through `workflow_run_id`

**What:** Keep the trace explorer run-centric. It already passes `workflow_run_id` into trace actions and filters incident/budget evidence by `trace_id` or `workflow_run_id`. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex]

**When to use:** Use when rendering replay badges, deep links to source runs, or lazy lineage drawers from the trace surface. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] [ASSUMED]

**Example:**

```elixir
# Source pattern: lib/scoria_web/live/orchestrator_live.ex
defp evidence_filter(trace_id, run_id) do
  if is_binary(run_id) and run_id != "" do
    dynamic([row], row.trace_id == ^trace_id or field(row, :workflow_run_id) == ^run_id)
  else
    dynamic([row], row.trace_id == ^trace_id)
  end
end
```

### Durable Schema / Lineage Fields Needed

| Field | Place | Why |
|------|-------|-----|
| `source_run_id` | `ai_workflow_runs` nullable FK to `ai_workflow_runs`. [ASSUMED] | The phase requirement explicitly needs the source run persisted as durable truth, and child replay lookup should not depend on metadata scanning. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: lib/scoria/workflows/run.ex] |
| `source_checkpoint_id` | `ai_workflow_runs` nullable FK to `ai_workflow_checkpoints`. [ASSUMED] | Replay branches are rooted in exact checkpoint truth; the run row needs an immutable pointer to that source checkpoint. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: lib/scoria/workflows/checkpoint.ex] |
| `execution_mode` | `ai_workflow_runs` string or enum-like string column with default live mode. [ASSUMED] | Success criteria require execution mode as durable truth, and Phase 38 will need to branch behavior on this field. [VERIFIED: .planning/ROADMAP.md] |
| `override_metadata` | `ai_workflow_runs` map column. [ASSUMED] | Overrides must remain durable and queryable without overloading generic run metadata. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: lib/scoria/workflows/run.ex] |
| Index on `source_run_id` | migration. [ASSUMED] | Needed for “list replay children for this run” and workflow detail lineage lookups. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] |
| Index on `source_checkpoint_id` | migration. [ASSUMED] | Needed for direct “which replay started from this checkpoint” lookup and diagnostics. [VERIFIED: .planning/ROADMAP.md] |
| Tenant-scoped lineage index, likely `[:tenant_id, :source_run_id]` | migration. [ASSUMED] | The repo already indexes tenant-scoped workflow reads; replay lineage should preserve that pattern. [VERIFIED: priv/repo/migrations/20260513000100_add_canonical_identity_to_workflow_runs.exs] |

### How Replay Should Reuse Workflow Runtime / Checkpoint Truth

1. Load the source run and source checkpoint from durable tables, not from LiveView params or trace payloads. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: lib/scoria/workflows/checkpoint.ex]
2. Validate `source_checkpoint.run_id == source_run.id` inside the write transaction before inserting the replay run. [VERIFIED: lib/scoria/workflows/checkpoint.ex] [ASSUMED]
3. Insert a fresh replay run row rather than mutating `current_step_id`, `latest_checkpoint_id`, or any checkpoint rows on the source run. [VERIFIED: lib/scoria/workflows/run.ex] [VERIFIED: lib/scoria/workflows.ex]
4. Seed the replay run with new step/checkpoint/event rows that are compatible with `claim_step/1`, `Runtime.execute_step/2`, and `Reconciler.dispatch_run/2`. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: lib/scoria/workflows/runtime.ex] [VERIFIED: lib/scoria/workflows/reconciler.ex] [ASSUMED]
5. Dispatch the replay run through `Reconciler.dispatch_run/2` or the public `Runtime` boundary after the transaction commits. [VERIFIED: lib/scoria/workflows/reconciler.ex] [VERIFIED: lib/scoria/runtime.ex] [ASSUMED]
6. Keep the source checkpoint snapshot and cursor as canonical historical truth; Phase 37 should reference them by ID and only copy the minimum seed state needed for the new run to execute. [VERIFIED: lib/scoria/workflows/checkpoint.ex] [ASSUMED]

### Read-Model / Query Implications

| Surface | Current behavior | Phase 37 implication |
|---------|------------------|----------------------|
| `Runtime.RunSummary` | Exposes `run_id`, `session_id`, `status`, `current_step_id`, and `latest_checkpoint_id`, but no replay lineage. [VERIFIED: lib/scoria/runtime/run_summary.ex] | Add lineage summary fields so public callers can identify replay branches without loading raw workflow structs. [ASSUMED] |
| `Runtime.RunDetail` | Emits curated steps/checkpoints/events/approvals/handoffs, but checkpoint/event items omit snapshot/payload lineage data and there is no source-run section. [VERIFIED: lib/scoria/runtime/run_detail.ex] | Add top-level lineage block plus any minimal checkpoint/event refs needed for provenance rendering. [ASSUMED] |
| `WorkflowLive.Show` | Reloads the run tree from workflow truth on PubSub updates and shows selected-step checkpoint metadata. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] | Keep the same reload pattern; add a replay provenance panel driven by workflow-owned lineage data. [ASSUMED] |
| `WorkflowDetailPanelComponent` | Shows checkpoint snapshot and failure reason only. [VERIFIED: lib/scoria_web/components/workflow_detail_panel_component.ex] | Extend this component or add a sibling panel for source checkpoint, overrides, and execution mode. [ASSUMED] |
| `OrchestratorLive` trace explorer | Trace actions already carry `trace.id` and sometimes `trace[:workflow_run_id]`; evidence queries filter on `trace_id` or `workflow_run_id`. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] | Add replay lineage lookup via `workflow_run_id`, not a new trace-only lineage table. The trace payload may optionally carry cached badges, but the truth should still come from the run query. [ASSUMED] |

### Anti-Patterns to Avoid

- **Second replay engine:** Do not create a special replay executor outside `Workflows.Runtime` and `Reconciler`; it would fork lifecycle truth from existing `complete_step`, `fail_step`, `retry_step`, and `resume_run` paths. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: lib/scoria/workflows/runtime.ex] [VERIFIED: lib/scoria/workflows/reconciler.ex]
- **Metadata-only lineage:** Do not hide `source_run_id`, `source_checkpoint_id`, or execution mode inside generic maps if the UI and public DTOs must query them repeatedly. [VERIFIED: lib/scoria/workflows/run.ex] [VERIFIED: lib/scoria/runtime/run_detail.ex]
- **Mutating source run history:** Do not repoint `latest_checkpoint_id`, overwrite source checkpoints, or reuse source step rows inside the original run. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: lib/scoria/workflows/run.ex]
- **LiveView-owned replay state:** Do not let the workflow page or orchestrator page invent temporary replay lineage or branch state in assigns. Existing patterns reload from durable truth on PubSub messages. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] [VERIFIED: lib/scoria_web/live/orchestrator_live.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Replay execution flow | A separate replay runner. [VERIFIED: lib/scoria/workflows/runtime.ex] | `Workflows.Runtime.execute_step/2` plus `Reconciler.dispatch_run/2`. [VERIFIED: lib/scoria/workflows/runtime.ex] [VERIFIED: lib/scoria/workflows/reconciler.ex] | Existing runtime already owns claim, timeout, approval, failure, and completion semantics. [VERIFIED: lib/scoria/workflows/runtime.ex] |
| Run detail projection | Raw preloaded structs returned directly to callers. [VERIFIED: lib/scoria/runtime/run_detail.ex] | Extend `Runtime.RunSummary` and `Runtime.RunDetail`. [VERIFIED: lib/scoria/runtime/run_summary.ex] [VERIFIED: lib/scoria/runtime/run_detail.ex] | The repo already treats these DTOs as the curated public surface. [VERIFIED: lib/scoria/runtime.ex] [VERIFIED: test/scoria/runtime_view_test.exs] |
| Trace lineage query | A new trace-lineage persistence table. [VERIFIED: lib/scoria/repo/trace.ex] [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] | Run-backed lineage lookups keyed by `workflow_run_id`. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] [ASSUMED] | The trace explorer already pivots on run ids for evidence joins. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] |

**Key insight:** Phase 37 is primarily a durable run-lineage and projection problem, not a new orchestration-engine problem. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: lib/scoria/workflows/runtime.ex]

## Common Pitfalls

### Pitfall 1: Cross-run pointer leakage when cloning steps

**What goes wrong:** Copying `parent_step_id`, `completed_at`, `result_envelope`, `error_envelope`, `attempt`, or `retry_count` from the source step into the replay run makes the new branch look partially executed or points back into the source run’s graph. [VERIFIED: lib/scoria/workflows/step.ex] [ASSUMED]

**Why it happens:** Current step rows carry execution-state fields and cross-row parent pointers that are valid only inside one run. [VERIFIED: lib/scoria/workflows/step.ex]

**How to avoid:** Seed fresh replay step rows with reset runtime state and either nil `parent_step_id` or a new in-run mapping. [VERIFIED: lib/scoria/workflows/step.ex] [ASSUMED]

**Warning signs:** Replay runs mount with completed/failed steps before dispatch, or foreign-key errors appear when inserting replay steps. [VERIFIED: lib/scoria/workflows/step.ex] [ASSUMED]

### Pitfall 2: Checkpoint mismatch between `source_run_id` and `source_checkpoint_id`

**What goes wrong:** A replay run can point at a checkpoint that belongs to a different run if the branch API trusts inputs independently. [VERIFIED: lib/scoria/workflows/checkpoint.ex] [ASSUMED]

**Why it happens:** The checkpoint schema has a `run_id` FK, but a run-level `source_checkpoint_id` column alone cannot enforce “belongs to `source_run_id`” without application validation. [VERIFIED: lib/scoria/workflows/checkpoint.ex] [ASSUMED]

**How to avoid:** Validate the pair inside the branch transaction before any inserts. [ASSUMED]

**Warning signs:** Workflow detail shows a source checkpoint sequence or snapshot that does not exist under the declared source run. [ASSUMED]

### Pitfall 3: Public lineage without tenant scoping

**What goes wrong:** Replay deep links can expose cross-tenant runs if queries continue to use raw run ids without tenant filters. [VERIFIED: lib/scoria/runtime.ex] [VERIFIED: lib/scoria_web/live/workflow_live/show.ex]

**Why it happens:** `Runtime.get_run!/1`, `Runtime.get_run_detail!/1`, and `WorkflowLive.Show.mount/3` currently load by run id only. [VERIFIED: lib/scoria/runtime.ex] [VERIFIED: lib/scoria_web/live/workflow_live/show.ex]

**How to avoid:** Add tenant-scoped lineage query helpers for operator/public surfaces or make tenant validation explicit in the calling surface. [ASSUMED]

**Warning signs:** A replay child or source-run link can be followed without matching the caller’s tenant/session context. [ASSUMED]

### Pitfall 4: Reusing source idempotency keys or unsafe override payloads

**What goes wrong:** Replay can collide with external dedupe behavior or preserve override data that later phases should treat as replay-only policy. [VERIFIED: lib/scoria/workflows/step.ex] [VERIFIED: .planning/ROADMAP.md] [ASSUMED]

**Why it happens:** Step rows already carry `idempotency_key`, and Phase 38 will introduce replay-safe tool/result modes. [VERIFIED: lib/scoria/workflows/step.ex] [VERIFIED: .planning/ROADMAP.md]

**How to avoid:** Either clear or namespace copied idempotency keys and keep override metadata explicit on the run. [ASSUMED]

**Warning signs:** Replay emits live-side dedupe collisions or operators cannot tell which overrides were applied to a replay run. [ASSUMED]

## Code Examples

Verified patterns from current repo:

### Transactional run creation with checkpoint and event

```elixir
# Source: lib/scoria/workflows.ex
multi =
  Multi.new()
  |> Multi.insert(
    :run,
    Run.changeset(%Run{}, Map.merge(%{status: "running", started_at: now}, run_attrs))
  )
  |> maybe_insert_initial_step(initial_step, now)
  |> Multi.run(:checkpoint, fn repo, changes ->
    {:ok,
     insert_checkpoint(
       repo,
       changes.run.id,
       changes[:initial_step] && changes.initial_step.id,
       %{transition: "run_started", status: changes.run.status, snapshot: %{}, metadata: %{}}
     )}
  end)
  |> Multi.run(:event, fn repo, changes ->
    {:ok,
     insert_event(repo, changes.run.id, changes[:initial_step] && changes.initial_step.id, %{
       event_type: "run_started",
       payload: %{status: changes.run.status}
     })}
  end)
```

### Existing runtime reuse boundary

```elixir
# Source: lib/scoria/workflows/resume.ex
def resume_run(run_id, opts \\ []) do
  with {:ok, _step} <- Workflows.resume_run(run_id),
       {:ok, _count} <- Reconciler.dispatch_run(run_id, opts) do
    {:ok, Workflows.get_run!(run_id)}
  end
end
```

### Workflow LiveView reloads from durable truth

```elixir
# Source: lib/scoria_web/live/workflow_live/show.ex
def handle_info({:workflow_updated, run_id}, socket), do: {:noreply, load_run(socket, run_id)}

defp load_run(socket, run_id) do
  run = Workflows.get_run_tree!(run_id)
  ...
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| UI-owned or in-memory workflow continuity. [ASSUMED] | Durable run/checkpoint/event truth in `Scoria.Workflows`. [VERIFIED: .planning/STATE.md] [VERIFIED: lib/scoria/workflows.ex] | Introduced in Phase 5. [VERIFIED: .planning/STATE.md] | Replay should compound existing durable workflow truth rather than replace it. [VERIFIED: .planning/STATE.md] |
| Ad hoc recovery paths. [ASSUMED] | Resume/retry flow reconstructed from stored workflow state and dispatched by the reconciler. [VERIFIED: lib/scoria/workflows/resume.ex] [VERIFIED: test/scoria/workflows/integration_test.exs] | Already present by 2026-05-22 in current code. [VERIFIED: lib/scoria/workflows/resume.ex] | Replay branch creation should look like another workflow-owned recovery entrypoint. [ASSUMED] |

**Deprecated/outdated:**

- A second replay engine is not aligned with the current workflow substrate and would duplicate lifecycle logic already covered in `Scoria.Workflows` tests. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: test/scoria/workflows_test.exs]

## Recommended Plan Decomposition

1. **Persistence foundation:** Add replay lineage fields and indexes on `ai_workflow_runs`, update `Run` schema/changeset and public DTOs, and add persistence tests for valid lineage and checkpoint mismatch rejection. [VERIFIED: lib/scoria/workflows/run.ex] [VERIFIED: lib/scoria/runtime/run_summary.ex] [VERIFIED: lib/scoria/runtime/run_detail.ex] [ASSUMED]
2. **Branch creation seam:** Implement a workflow-owned replay branch API that creates a new run from source checkpoint truth, seeds replay-compatible step/checkpoint/event rows, and dispatches through the existing runtime boundary. [VERIFIED: lib/scoria/workflows.ex] [VERIFIED: lib/scoria/workflows/runtime.ex] [VERIFIED: lib/scoria/workflows/reconciler.ex] [ASSUMED]
3. **Read-side exposure:** Extend workflow run detail and trace explorer surfaces to show source run, source checkpoint, override metadata, execution mode, and replay children without introducing new mutable UI truth. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] [ASSUMED]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `execution_mode` should be a dedicated run column rather than only `metadata`. | Durable Schema / Lineage Fields Needed | Medium; planner may need a migration revision if the project prefers metadata-only storage despite weaker queryability. |
| A2 | The replay branch API should seed a fresh step from the source checkpoint’s associated step and dispatch it through the existing runtime. | Workflow-Owned Replay Branch Transaction; How Replay Should Reuse Workflow Runtime / Checkpoint Truth | High; if checkpoint semantics actually require resuming the next step or a different cursor-driven reconstruction, task decomposition will shift. |
| A3 | Trace explorer lineage should be loaded via `workflow_run_id` lookup rather than a new persisted trace-lineage table. | Pattern 3; Read-Model / Query Implications | Low; even if a helper projection is added later, the durable truth can still remain run-backed. |
| A4 | Tenant-scoped lineage query helpers should be added or validated as part of this phase’s read-side work. | Common Pitfalls; Security Domain | Medium; if access control is handled elsewhere, the planner can reduce scope, but the risk should remain visible. |

## Open Questions

1. **What exact step should a replay branch execute first?**
   - What we know: The source checkpoint belongs to one persisted step, and the current runtime executes one queued step at a time. [VERIFIED: lib/scoria/workflows/checkpoint.ex] [VERIFIED: lib/scoria/workflows/runtime.ex]
   - What's unclear: Whether replay should re-queue the checkpoint’s own step, synthesize the next step from cursor state, or support both based on checkpoint transition type. [ASSUMED]
   - Recommendation: Resolve this in plan tasks before implementation starts; it is the highest-risk assumption in Phase 37. [ASSUMED]

2. **How much lineage should the public DTO expose in Phase 37?**
   - What we know: `RunSummary` and `RunDetail` are the public runtime surfaces today. [VERIFIED: lib/scoria/runtime.ex]
   - What's unclear: Whether the requirement needs only direct parent/source lineage or also child replay lists and ancestry chains. [ASSUMED]
   - Recommendation: Start with direct source refs plus immediate child replay summaries; recursive ancestry can stay out unless the discuss phase or planner locks it in. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Build and tests. [VERIFIED: mix.exs] | ✓ [VERIFIED: local shell] | `1.19.5`. [VERIFIED: local shell] | — |
| Erlang/OTP | Elixir runtime. [VERIFIED: local shell] | ✓ [VERIFIED: local shell] | `28`. [VERIFIED: local shell] | — |
| Mix | Build and tests. [VERIFIED: mix.exs] | ✓ [VERIFIED: local shell] | Present; `mix --version` output was truncated by stdout pipe termination, but Mix executed. [VERIFIED: local shell] | — |
| PostgreSQL CLI | Manual DB inspection if needed. [VERIFIED: local shell] | ✓ [VERIFIED: local shell] | `14.17`. [VERIFIED: local shell] | Repo tests can still run through configured Ecto test DB without direct `psql` usage. [ASSUMED] |

**Missing dependencies with no fallback:** None found during this research pass. [VERIFIED: local shell]

**Missing dependencies with fallback:** None found during this research pass. [VERIFIED: local shell]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Mix. [VERIFIED: test/scoria/workflows_test.exs] [VERIFIED: test/scoria/runtime_view_test.exs] |
| Config file | No standalone `pytest`/`jest` config; test lanes are Mix/ExUnit-based in repo structure. [VERIFIED: mix.exs] [VERIFIED: repo grep] |
| Quick run command | `mix test test/scoria/workflows_test.exs test/scoria/runtime_view_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/orchestrator_live_test.exs -x` [VERIFIED: repo file layout] |
| Full suite command | `mix test` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RPLY-01 | Branch creation persists `source_run_id`, `source_checkpoint_id`, override metadata, and execution mode without mutating source history. [VERIFIED: .planning/ROADMAP.md] | unit + persistence | `mix test test/scoria/workflows_test.exs -x` [VERIFIED: repo file layout] | ✅ |
| RPLY-01 | Replay branches dispatch through the existing runtime boundary instead of a second engine. [VERIFIED: .planning/ROADMAP.md] | integration | `mix test test/scoria/workflows/integration_test.exs -x` [VERIFIED: repo file layout] | ✅ |
| RPLY-01 | Public run detail exposes lineage on stable DTOs. [VERIFIED: .planning/ROADMAP.md] | unit | `mix test test/scoria/runtime_view_test.exs -x` [VERIFIED: repo file layout] | ✅ |
| RPLY-01 | Workflow run LiveView and trace explorer show lineage/deep-link context. [VERIFIED: .planning/ROADMAP.md] | LiveView integration | `mix test test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/orchestrator_live_test.exs -x` [VERIFIED: repo file layout] | ✅ |

### Sampling Rate

- **Per task commit:** `mix test test/scoria/workflows_test.exs test/scoria/runtime_view_test.exs -x` [VERIFIED: repo file layout]
- **Per wave merge:** `mix test test/scoria/workflows/integration_test.exs test/scoria_web/live/workflow_live_test.exs test/scoria_web/live/orchestrator_live_test.exs -x` [VERIFIED: repo file layout]
- **Phase gate:** `mix test` [VERIFIED: mix.exs]

### Wave 0 Gaps

- [ ] Add replay-branch persistence cases to [test/scoria/workflows_test.exs](/Users/jon/projects/scoria/test/scoria/workflows_test.exs:1) for source checkpoint validation, run immutability, and explicit lineage fields. [VERIFIED: test/scoria/workflows_test.exs]
- [ ] Add DTO lineage assertions to [test/scoria/runtime_view_test.exs](/Users/jon/projects/scoria/test/scoria/runtime_view_test.exs:1). [VERIFIED: test/scoria/runtime_view_test.exs]
- [ ] Add workflow page lineage rendering cases to [test/scoria_web/live/workflow_live_test.exs](/Users/jon/projects/scoria/test/scoria_web/live/workflow_live_test.exs:1). [VERIFIED: test/scoria_web/live/workflow_live_test.exs]
- [ ] Add trace explorer lineage/deep-link cases to [test/scoria_web/live/orchestrator_live_test.exs](/Users/jon/projects/scoria/test/scoria_web/live/orchestrator_live_test.exs:1). [VERIFIED: test/scoria_web/live/orchestrator_live_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no. [ASSUMED] | Existing host/session plumbing remains unchanged in this phase. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] |
| V3 Session Management | yes. [VERIFIED: lib/scoria/runtime.ex] | Replay lineage should keep `session_id` continuity on the new run while preserving the source run as immutable history. [VERIFIED: lib/scoria/workflows/run.ex] [ASSUMED] |
| V4 Access Control | yes. [VERIFIED: lib/scoria/runtime.ex] [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] | Use tenant-scoped query helpers or explicit tenant validation on lineage reads; current raw `get_run!`/`get_run_detail!` paths do not enforce tenant scoping. [VERIFIED: lib/scoria/runtime.ex] [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] [ASSUMED] |
| V5 Input Validation | yes. [VERIFIED: lib/scoria/workflows/run.ex] [VERIFIED: lib/scoria/workflows/checkpoint.ex] | Validate source run/checkpoint pairing and execution mode through Ecto changesets plus transaction-level guards. [VERIFIED: lib/scoria/workflows/run.ex] [VERIFIED: lib/scoria/workflows/checkpoint.ex] [ASSUMED] |
| V6 Cryptography | no. [ASSUMED] | No new crypto primitive is required in the current scope. [VERIFIED: .planning/ROADMAP.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Replay branch reads another tenant’s source run by id. [VERIFIED: lib/scoria/runtime.ex] [ASSUMED] | Information Disclosure | Tenant-scoped workflow lineage queries and LiveView/session validation before rendering deep links. [ASSUMED] |
| Replay branch points at an unrelated checkpoint and creates false provenance. [VERIFIED: lib/scoria/workflows/checkpoint.ex] [ASSUMED] | Tampering | Validate `source_checkpoint.run_id == source_run.id` inside the branch transaction. [ASSUMED] |
| Replay run accidentally preserves old idempotency or side-effect context. [VERIFIED: lib/scoria/workflows/step.ex] [ASSUMED] | Tampering | Reset execution-state fields on seeded steps and keep future replay-safe mode enforcement centralized in the runtime boundary. [VERIFIED: lib/scoria/workflows/runtime.ex] [ASSUMED] |

## Sources

### Primary (HIGH confidence)

- `.planning/ROADMAP.md` - Phase 37 goal and success criteria. [VERIFIED: .planning/ROADMAP.md]
- `.planning/REQUIREMENTS.md` - `RPLY-01` requirement text. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/STATE.md` - Milestone/project decisions around durable workflow truth and `v1.9 Crucible`. [VERIFIED: .planning/STATE.md]
- `lib/scoria/workflows.ex` - existing workflow lifecycle, checkpoint/event writes, approval/resume/retry seams. [VERIFIED: lib/scoria/workflows.ex]
- `lib/scoria/workflows/runtime.ex` - current execution engine boundary. [VERIFIED: lib/scoria/workflows/runtime.ex]
- `lib/scoria/workflows/reconciler.ex` - current dispatch boundary. [VERIFIED: lib/scoria/workflows/reconciler.ex]
- `lib/scoria/workflows/run.ex` - run schema shape. [VERIFIED: lib/scoria/workflows/run.ex]
- `lib/scoria/workflows/checkpoint.ex` - checkpoint schema shape. [VERIFIED: lib/scoria/workflows/checkpoint.ex]
- `lib/scoria/runtime.ex`, `lib/scoria/runtime/run_summary.ex`, `lib/scoria/runtime/run_detail.ex` - public runtime read surfaces. [VERIFIED: lib/scoria/runtime.ex] [VERIFIED: lib/scoria/runtime/run_summary.ex] [VERIFIED: lib/scoria/runtime/run_detail.ex]
- `lib/scoria_web/live/workflow_live/show.ex`, `lib/scoria_web/components/workflow_tree_component.ex`, `lib/scoria_web/components/workflow_detail_panel_component.ex` - workflow run UI seams. [VERIFIED: lib/scoria_web/live/workflow_live/show.ex] [VERIFIED: lib/scoria_web/components/workflow_tree_component.ex] [VERIFIED: lib/scoria_web/components/workflow_detail_panel_component.ex]
- `lib/scoria_web/live/orchestrator_live.ex` - trace explorer and evidence query shape. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex]
- `test/scoria/workflows_test.exs`, `test/scoria/workflows/integration_test.exs`, `test/scoria/runtime_view_test.exs`, `test/scoria_web/live/workflow_live_test.exs` - current verification seams. [VERIFIED: test/scoria/workflows_test.exs] [VERIFIED: test/scoria/workflows/integration_test.exs] [VERIFIED: test/scoria/runtime_view_test.exs] [VERIFIED: test/scoria_web/live/workflow_live_test.exs]

### Secondary (MEDIUM confidence)

- `.planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-PATTERNS.md` - workflow-owned durable truth / UI-second analogs. [VERIFIED: .planning/phases/21-remote-approval-flow-and-operator-evidence-ux/21-PATTERNS.md]
- `.planning/phases/33-distributed-evaluation-fan-out/33-RESEARCH.md` and `33-PATTERNS.md` - recent Scoria planning style for parent/child durable truth and plan decomposition. [VERIFIED: .planning/phases/33-distributed-evaluation-fan-out/33-RESEARCH.md] [VERIFIED: .planning/phases/33-distributed-evaluation-fan-out/33-PATTERNS.md]
- `mix.exs` and `mix.lock` - project stack versions. [VERIFIED: mix.exs] [VERIFIED: mix.lock]

### Tertiary (LOW confidence)

- None. All unverified design recommendations are marked `[ASSUMED]`. [VERIFIED: this document]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - the phase reuses the already-installed Phoenix/Ecto/LiveView workflow stack and versions were read locally. [VERIFIED: mix.exs] [VERIFIED: mix.lock]
- Architecture: MEDIUM - the runtime/reconciler reuse path is strongly supported by current code, but the exact step-seeding rule for “branch from checkpoint” is still an implementation assumption. [VERIFIED: lib/scoria/workflows/runtime.ex] [VERIFIED: lib/scoria/workflows/reconciler.ex] [ASSUMED]
- Pitfalls: MEDIUM - most pitfalls are directly visible from current schemas and public read paths, but some replay-specific failure modes depend on the final branch API contract. [VERIFIED: lib/scoria/workflows/step.ex] [VERIFIED: lib/scoria/runtime.ex] [ASSUMED]

**Research date:** 2026-05-22
**Valid until:** 2026-06-21 for repo-local architecture; revisit sooner if Phase 37 scope changes during discuss/plan. [ASSUMED]
