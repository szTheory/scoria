# Phase 5: Durable Agent Workflows & Handoffs - Research

**Researched:** 2026-05-11 [VERIFIED: current session date]
**Domain:** Durable Ecto-backed workflow orchestration for Phoenix/LiveView agent runs [VERIFIED: .planning/MILESTONES.md] [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]
**Confidence:** MEDIUM [VERIFIED: synthesis of repo-local evidence plus official docs]

<user_constraints>
## User Constraints (from CONTEXT.md)

The following content is copied from `05-CONTEXT.md` and is the controlling scope for this phase. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]

### Locked Decisions

#### Checkpointing model

Use a **hybrid semantic checkpoint model**.

Persist durable state at stable transitions:
- `run_started`
- after a model turn resolves to a stable next action
- before `waiting_*` / approval pauses
- after a side-effecting tool or subagent step completes
- at terminal states

Do not checkpoint:
- streaming tokens
- LiveView socket state
- PubSub frames
- raw GenServer memory

Why:
- `every-step` checkpointing is too expensive and too easy to overfit into Temporal-scale runtime complexity.
- `manual-only` checkpoints are too footgun-prone.
- `HITL-only` durability is not enough for real crash recovery.

#### Handoff contract

Use a **root-owned run with bounded delegated steps**.

Scoria should own the durable lifecycle, approvals, cancellation, budgets, and traceability. Delegation should be modeled as bounded child steps, not literal ownership transfer.

Recommended structure:
- stable `role_id` for developer-facing roles like `researcher`, `critic`, `executor`
- capability filters for selection, not as the primary orchestration contract
- typed step envelopes for results/errors/approvals
- explicit `handoff_input` and `step_result` schemas
- projected context slices, not transcript dumping

Do not move by default:
- full transcript history
- secrets
- provider session internals
- LiveView UI state
- PIDs / ETS refs / monitors

#### Recovery UX

The primary operator recovery flow is:
- exact resume
- retry failed step

Secondary later:
- fork from checkpoint

Do not ship in-place state editing for current runs in phase 5.

Why:
- exact resume plus retry keeps the trust model simple
- in-place mutation is high-risk and hard to audit
- forking is valuable, but it is a debug/eval workflow, not the default recovery path

#### Visualizer shape

Use a **trace-first tree** as the primary view.

Add:
- inline lifecycle badges like `running`, `paused`, `waiting_for_approval`, `retrying`, `completed`
- compact handoff markers
- a right-side detail panel for checkpoint metadata and failure reasons
- a per-run timeline as the secondary drilldown

Do not make the primary UI graph-first.

Why:
- Scoria already has a flat trace tree pattern that is LiveView-friendly
- graph-first UIs are harder to keep calm, streamable, and legible
- timeline is important, but it should be a drilldown, not the default mental model

#### Jido scope

Keep Jido as an **optional adapter**, not the center of the public API.

Scoria should define its own durable workflow nouns and checkpoint model, then map Jido into that model where useful.

Do not make Scoria Jido-first.

Why:
- preserves framework-agnostic reach
- avoids semantic lock-in
- keeps the product centered on AI ops/control plane, not another workflow DSL
- still gives Jido users a clean bridge into Scoria observability and durability

### Claude's Discretion

None provided in `05-CONTEXT.md`. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)

These are intentionally not phase-5 defaults:
- full workflow graph authoring as the primary UX
- in-place editing of live run state
- telemetry-only Jido integration with no durability layer
- generic capability-driven orchestration without stable role IDs
</user_constraints>

## Project Constraints (repo-local)

- Do not integrate Ash; Scoria is standard Phoenix and Ecto only. [VERIFIED: GEMINI.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WF-01 | Persist durable workflow truth for runs, steps, checkpoints, events, and approvals in Ecto. [VERIFIED: .planning/MILESTONES.md] [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] | `Standard Stack`, `Architecture Patterns`, and `Security Domain` define schema, transaction, and locking patterns. [VERIFIED: this document] |
| WF-02 | Support resumable and retryable step execution with exact resume and retry-failed-step as the default operator flows. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] | `Architecture Patterns`, `Don't Hand-Roll`, and `Validation Architecture` define lease, retry, and recovery boundaries. [VERIFIED: this document] |
| WF-03 | Model handoffs as bounded delegated steps under a root-owned run using stable `role_id`s and typed envelopes. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] | `Summary`, `Architecture Patterns`, and `Common Pitfalls` define the handoff contract. [VERIFIED: this document] |
| WF-04 | Make operator approvals durable pauses backed by persisted state rather than PubSub or socket memory. [VERIFIED: .planning/MILESTONES.md] [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] | `Standard Stack`, `Architecture Patterns`, and `Security Domain` map approval writes, resume semantics, and optimistic locking. [VERIFIED: this document] |
| WF-05 | Provide a trace-first LiveView workflow visualizer with lifecycle badges, checkpoint details, and timeline drilldown. [VERIFIED: .planning/MILESTONES.md] [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] | `Architecture Patterns` and `Validation Architecture` define the projection and testing shape. [VERIFIED: this document] |
| WF-06 | Keep any Jido integration optional and adapter-scoped rather than central to the public API. [VERIFIED: .planning/MILESTONES.md] [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] | `Standard Stack` and `Architecture Patterns` isolate Jido behind adapter boundaries. [VERIFIED: this document] |
| WF-07 | Preserve a minimal install and router integration story consistent with the existing dashboard approach. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] [VERIFIED: lib/mix/tasks/scoria.install.ex] [VERIFIED: lib/scoria_web/router.ex] | `Recommended Project Structure`, `Open Questions`, and `Validation Architecture` cover the phase-5 install/mount path. [VERIFIED: this document] |
</phase_requirements>

## Summary

Phase 5 should add a small durable workflow layer on top of Scoria's current Phoenix/Ecto foundations rather than introducing a generic workflow engine. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] [VERIFIED: lib/scoria/repo.ex] [VERIFIED: lib/scoria/application.ex] [VERIFIED: lib/scoria_web/live/orchestrator_live.ex]

The current repo already has the base primitives needed for that layer: Postgres-backed Ecto schemas and migrations, durable approval records, PubSub-driven operator projection, `Task.Supervisor`-based isolated execution, and a thin Jido observability adapter. [VERIFIED: lib/scoria/repo.ex] [VERIFIED: priv/repo/migrations/20260510015813_create_ai_observability_tables.exs] [VERIFIED: priv/repo/migrations/20260510160812_create_ai_approvals.exs] [VERIFIED: lib/scoria/mcp/executor.ex] [VERIFIED: lib/scoria/observe/adapters/jido.ex]

**Primary recommendation:** keep workflow truth in new Ecto tables (`run`, `step`, `checkpoint`, `event`, `handoff`), project all operator UI from persisted rows, wrap each transition in `Ecto.Multi`, guard mutable operator-facing rows with `optimistic_lock`, and use Oban only as a durable wakeup/retry dispatcher if Phase 5 wants crash-safe resume without hand-rolling a scheduler. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html#optimistic_lock/3] [CITED: https://hexdocs.pm/oban/Oban.html] [CITED: https://hexdocs.pm/oban/Oban.Worker.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Workflow truth (`run`, `step`, `checkpoint`, `event`, `handoff`) | Database / Storage | API / Backend | The phase context explicitly makes Ecto the source of truth and rejects PubSub or GenServer memory as workflow truth. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] |
| Step orchestration and retry dispatch | API / Backend | Database / Storage | OTP tasks are execution mechanisms, while durable status and retry decisions are persisted and reloaded from the database. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] [VERIFIED: lib/scoria/mcp/executor.ex] |
| Operator approvals | API / Backend | Frontend Server (SSR) | Approvals already exist as Ecto records and LiveView should project their persisted status rather than own the state in the socket. [VERIFIED: lib/scoria/observe/approval.ex] [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] |
| Run visualizer and timeline | Frontend Server (SSR) | Browser / Client | The repo already uses LiveView streams and async assignment for operator UX, and the phase context requires a trace-first LiveView-friendly view. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Delegated handoff boundaries | API / Backend | Database / Storage | Handoffs are a contract problem, not a UI problem: the root run owns lifecycle while delegated work is represented as bounded child steps and persisted envelopes. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] |
| PubSub notifications | Frontend Server (SSR) | API / Backend | PubSub should only invalidate or refresh projections after the database commit, never become the authoritative state channel. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto | 3.13.6 (published 2026-05-05) | Durable schemas, changesets, optimistic concurrency | The repo already uses `Ecto.Repo`, schemas, migrations, and `Ecto.Multi`; `optimistic_lock/3` is the correct built-in control for mutable operator-facing rows. [VERIFIED: lib/scoria/repo.ex] [VERIFIED: lib/scoria/eval.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html#optimistic_lock/3] [VERIFIED: mix hex.info ecto] |
| Ecto SQL | 3.13.5 (published 2026-03-03) | Transactions and migrations | Current observability, approval, and eval layers already use Ecto SQL migrations, making it the natural base for workflow tables and transactional checkpoint writes. [VERIFIED: priv/repo/migrations/20260510015813_create_ai_observability_tables.exs] [VERIFIED: priv/repo/migrations/20260510160812_create_ai_approvals.exs] [VERIFIED: priv/repo/migrations/20260510174619_create_eval_tables.exs] [VERIFIED: mix hex.info ecto_sql] |
| Postgrex / PostgreSQL | Postgrex 0.22.1 (published 2026-05-05) | Backing store for durable state | `Scoria.Repo` is configured for Postgres, and the existing migrations already lean on Postgres features such as GIN indexes on `:map` columns. [VERIFIED: lib/scoria/repo.ex] [VERIFIED: priv/repo/migrations/20260510015813_create_ai_observability_tables.exs] [VERIFIED: mix hex.info postgrex] |
| Phoenix | 1.8.7 (published 2026-05-06) | Router integration and host embedding | The current `scoria_dashboard` macro and install task already assume embedded Phoenix router integration. [VERIFIED: lib/scoria_web/router.ex] [VERIFIED: lib/mix/tasks/scoria.install.ex] [VERIFIED: mix hex.info phoenix] |
| Phoenix LiveView | 1.1.30 (published 2026-05-05) | Operator UI projection | The existing operator UI already uses streams and `assign_async`, which are the right projection mechanisms for a trace-first run view. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] [VERIFIED: mix hex.info phoenix_live_view] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix PubSub | 2.2.0 (published 2025-10-22) | Visibility and invalidation after commits | Use PubSub only to fan out "run changed" notifications after durable writes; do not use it as workflow truth. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] [VERIFIED: mix hex.info phoenix_pubsub] |
| OTP `Task.Supervisor` | Elixir/OTP built-in | Isolated execution of a single step attempt | Keep using supervised tasks as the in-process execution primitive for model/tool work once a step has been durably claimed. [VERIFIED: lib/scoria/application.ex] [VERIFIED: lib/scoria/mcp/executor.ex] [CITED: https://hexdocs.pm/elixir/Task.Supervisor.html] |
| Oban | 2.22.1 (published 2026-04-30) | Durable wakeups, retries, and resume dispatch | Add this if Phase 5 wants crash-safe wakeups and retry scheduling without hand-rolling polling, backoff, leasing, and test helpers. Keep Oban responsible for execution attempts, not workflow truth. [CITED: https://hexdocs.pm/oban/Oban.html] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] [VERIFIED: mix hex.info oban] |
| Jido | 2.2.0 (published 2026-03-29) | Optional adapter target | Add only for the adapter boundary; the phase context explicitly rejects a Jido-first public API, and the current repo only has a telemetry adapter stub. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] [VERIFIED: lib/scoria/observe/adapters/jido.ex] [VERIFIED: mix hex.info jido] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Oban-backed wakeups | Custom startup reconciler + `Task.Supervisor` only | Fewer dependencies, but it forces Scoria to hand-roll retry timing, execution leasing, duplicate suppression, and test helpers that Oban already solves. [VERIFIED: lib/scoria/application.ex] [VERIFIED: lib/scoria/mcp/executor.ex] [CITED: https://hexdocs.pm/oban/Oban.html] |
| Typed `ai_handoffs` table | Store handoff metadata only inside `step.attributes` | Slightly fewer tables, but worse queryability for "who delegated what to which role" and weaker operator detail panels. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] |
| Trace-first tree + timeline drilldown | Graph-first primary visualizer | Graph-first is possible, but it contradicts the locked UX decision and is harder to keep calm and streamable in LiveView. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] |

**Installation:** the minimum phase can ship on existing Phoenix/Ecto dependencies; the recommended durable dispatcher adds `{:oban, "~> 2.22"}`, and the adapter path adds `{:jido, "~> 2.2", optional: true}` only if the adapter is implemented now. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] [VERIFIED: mix hex.info oban] [VERIFIED: mix hex.info jido]

```elixir
# mix.exs
defp deps do
  [
    {:oban, "~> 2.22"},
    {:jido, "~> 2.2", optional: true}
  ]
end
```

## Architecture Patterns

### System Architecture Diagram

```text
[LiveView Operator UI]
        |
        | resume / retry / approve
        v
[Workflow Context / API Layer] -----> [Ecto.Multi Transition Writer]
        |                                      |
        | PubSub invalidate after commit       | writes
        v                                      v
[Phoenix PubSub]                         [ai_runs / ai_run_steps / ai_run_checkpoints /
                                                ai_run_events / ai_handoffs / ai_approvals]
                                                |
                                                | wakeup or retry dispatch
                                                v
                                         [Oban Job or Startup Reconciler]
                                                |
                                                | claim step + execute attempt
                                                v
                                         [Task.Supervisor Step Attempt]
                                                |
                                                | model/tool/handoff result
                                                v
                                         [Ecto.Multi checkpoint + event write]
```

### Recommended Project Structure

```text
lib/
├── scoria/
│   ├── workflows/
│   │   ├── run.ex                  # ai_runs schema
│   │   ├── step.ex                 # ai_run_steps schema
│   │   ├── checkpoint.ex           # ai_run_checkpoints schema
│   │   ├── event.ex                # ai_run_events schema
│   │   ├── handoff.ex              # ai_handoffs schema
│   │   ├── context.ex              # create/resume/retry/approve API
│   │   ├── transitions.ex          # Ecto.Multi state transitions
│   │   ├── dispatcher.ex           # enqueue/reconcile executable steps
│   │   └── adapters/
│   │       └── jido.ex             # optional mapping boundary
│   └── observe/
│       └── approval.ex             # extend existing approval schema rather than replace it
├── scoria_web/
│   ├── live/
│   │   └── run_live/
│   │       ├── index.ex            # run list / status badges
│   │       └── show.ex             # trace-first tree + detail panel + timeline
│   └── components/
│       └── workflow_tree_component.ex
└── mix/
    └── tasks/
        └── scoria.install.ex       # extend install story only if routes/assets need updates
```

### Recommended Schema Shape

| Table | Required Columns | Notes |
|-------|------------------|-------|
| `ai_runs` | `id`, `session_id`, `root_role_id`, `status`, `current_step_id`, `latest_checkpoint_id`, `lock_version`, `last_heartbeat_at`, `error`, `metadata`, timestamps | The top-level durable owner of lifecycle, cancellation, and operator-visible status. `lock_version` is required because operators can resume, retry, or approve from the UI. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html#optimistic_lock/3] |
| `ai_run_steps` | `id`, `run_id`, `parent_step_id`, `sequence`, `kind`, `role_id`, `status`, `attempt`, `retry_count`, `idempotency_key`, `handoff_input`, `projected_context`, `result_envelope`, `error_envelope`, `started_at`, `completed_at`, timestamps | This is the unit of execution and retry. Store projected context and typed envelopes here; do not dump raw transcript or session internals. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] |
| `ai_run_checkpoints` | `id`, `run_id`, `step_id`, `sequence`, `transition`, `status`, `snapshot`, `cursor`, `metadata`, timestamps | Keep checkpoints append-only and write only at semantic boundaries defined in the locked decisions. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] |
| `ai_run_events` | `id`, `run_id`, `step_id`, `sequence`, `event_type`, `payload`, timestamps | Use this for operator timeline drilldown and audit-style playback, not as the only recovery source. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] |
| `ai_handoffs` | `id`, `run_id`, `step_id`, `delegated_role_id`, `capability_tags`, `handoff_input`, `result_summary`, `status`, timestamps | Separate table keeps delegated-step queries and UI markers cheap while preserving root-run ownership. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] |
| `ai_approvals` | existing fields plus `step_id`, `checkpoint_id`, `decision_by`, `decision_reason`, `lock_version` | Extend the current approval table instead of replacing it, because it already exists and is used by the LiveView approval flow. [VERIFIED: lib/scoria/observe/approval.ex] [VERIFIED: priv/repo/migrations/20260510160812_create_ai_approvals.exs] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html#optimistic_lock/3] |

### Pattern 1: Transactional Checkpoint Transition
**What:** Persist state transition, event append, and next-dispatch intent in one database transaction. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
**When to use:** Run creation, post-tool completion, pre-approval pause, retry transition, terminal completion. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]
**Example:**
```elixir
# Source: Ecto.Multi docs + repo-local Eval transaction style
Ecto.Multi.new()
|> Ecto.Multi.update(:run, run_changeset)
|> Ecto.Multi.update(:step, step_changeset)
|> Ecto.Multi.insert(:checkpoint, checkpoint_changeset)
|> Ecto.Multi.insert(:event, event_changeset)
|> Ecto.Multi.run(:dispatch, fn _repo, %{step: step} ->
  enqueue_next_attempt(step)
end)
|> Repo.transaction()
```

### Pattern 2: Root-Owned Delegated Handoff
**What:** Represent delegation as a `kind: "handoff"` step with explicit `delegated_role_id`, `handoff_input`, and typed result envelope, while keeping the root run authoritative. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]
**When to use:** Researcher/critic/executor delegation, bounded subagent work, approval-returning specialist steps. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]
**Example:**
```elixir
# Source: phase-5 locked handoff contract
%Step{
  run_id: run.id,
  parent_step_id: parent.id,
  kind: "handoff",
  role_id: "researcher",
  status: "running",
  handoff_input: %{goal: goal, context_slice: context_slice},
  projected_context: context_slice
}
```

### Pattern 3: Resume/Retry Dispatcher Boundary
**What:** Separate durable eligibility (`status`, `retry_at`, `waiting_for_approval`) from actual process execution, then dispatch executable steps through a narrow runner boundary. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] [VERIFIED: lib/scoria/application.ex]
**When to use:** On app boot, after approval decisions, after a failed step becomes retryable, and after a stable model/tool completion unlocks the next step. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]
**Example:**
```elixir
# Source: Oban docs for durable dispatch + Task.Supervisor docs for isolated execution
def perform(%Oban.Job{args: %{"step_id" => step_id}}) do
  with {:ok, step} <- Workflows.claim_step(step_id),
       {:ok, result} <- Task.Supervisor.async_nolink(Scoria.MCP.TaskSupervisor, fn ->
         Workflows.execute_step(step)
       end) |> Task.await(:infinity) do
    Workflows.complete_step(step, result)
  else
    {:error, reason} -> Workflows.fail_step(step_id, reason)
  end
end
```

### Pattern 4: LiveView as Projection Layer
**What:** Load persisted runs and steps into streams, then use PubSub only to trigger refreshes or inserts after commits. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] [VERIFIED: lib/scoria_web/live/orchestrator_live.ex]
**When to use:** Run list, run detail tree, approval queue, retry state badge updates, detail panel lazy-load. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]
**Example:**
```elixir
# Source: Phoenix.LiveView docs + existing OrchestratorLive pattern
def mount(%{"id" => run_id}, _session, socket) do
  if connected?(socket), do: Phoenix.PubSub.subscribe(Scoria.PubSub, "scoria:run:#{run_id}")

  {:ok,
   socket
   |> assign(:run_id, run_id)
   |> assign(:active_checkpoint, nil)
   |> stream(:steps, Workflows.list_steps(run_id))}
end
```

### Anti-Patterns to Avoid
- **Snapshotting process memory:** Do not serialize GenServer state, socket assigns, or token buffers as checkpoints; the locked checkpoint model explicitly rejects that. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]
- **Approval by PubSub only:** Do not treat a broadcast as an approval record; approvals must be rows with durable status transitions. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] [VERIFIED: lib/scoria/observe/approval.ex]
- **Transcript dumping for handoffs:** Do not pass whole transcripts, secrets, or provider session internals into delegated steps. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]
- **Oban-as-workflow-engine:** If Oban is added, do not store the workflow graph in `Oban.Job.args`; keep workflow truth in Scoria tables and use jobs only to wake or retry steps. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] [CITED: https://hexdocs.pm/oban/Oban.html]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Retry timing and wakeup scheduling | Custom polling loop or bespoke timer registry | Oban queueing with retry/backoff, or a single explicit startup reconciler if Oban is declined | Durable retries and crash-safe wakeups are deceptively complex once restarts, duplicate delivery, and testability matter. [CITED: https://hexdocs.pm/oban/Oban.html] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| Concurrency control for operator actions | Ad hoc "check then update" status mutations | `optimistic_lock/3` on `ai_runs` and `ai_approvals` | Operator resume/retry/approve actions are exactly the kind of concurrent mutation optimistic locking is designed to guard. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html#optimistic_lock/3] |
| Multi-record transition writes | Sequential `Repo.update` / `Repo.insert` calls | `Ecto.Multi` + single transaction | This phase needs atomic run/step/checkpoint/event updates or the UI and recovery logic will observe torn state. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] [VERIFIED: lib/scoria/eval.ex] |
| Run visualizer state management | Client-owned graph cache | LiveView streams over persisted rows | The repo already uses LiveView streams and async assigns successfully, and the phase context makes LiveView a projection layer. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] |

**Key insight:** the only "engine" Phase 5 needs is a durable transition log around Scoria's own nouns; once truth is in Ecto, dispatch and UI can stay thin. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] [VERIFIED: lib/scoria/eval.ex]

## Common Pitfalls

### Pitfall 1: Duplicate Side Effects on Retry
**What goes wrong:** A failed or timed-out tool step is retried and performs the side effect twice. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]
**Why it happens:** The workflow marks failure after a tool call but does not persist an idempotency key or post-tool checkpoint. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]
**How to avoid:** Give side-effecting steps an `idempotency_key`, checkpoint immediately after completion, and retry from the next durable boundary rather than replaying ambiguous partial work. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]
**Warning signs:** Tool spans succeeded in traces, but the step remains `running` or `failed` with no terminal checkpoint. [VERIFIED: priv/repo/migrations/20260510015813_create_ai_observability_tables.exs]

### Pitfall 2: Torn Run State from Non-Atomic Writes
**What goes wrong:** UI shows `completed`, but the latest checkpoint or event row is missing. [VERIFIED: phase-5 durability requirements]
**Why it happens:** Run, step, checkpoint, and event rows are written in separate calls instead of one transaction. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
**How to avoid:** Wrap every state transition in one `Ecto.Multi` and broadcast PubSub only after commit. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]
**Warning signs:** Inconsistent counts between `ai_run_checkpoints` and status transitions in the timeline. [ASSUMED]

### Pitfall 3: LiveView Reading Ephemeral State Instead of the Database
**What goes wrong:** A reconnect or deploy loses operator context because the page depended on socket memory or PubSub payload history. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]
**Why it happens:** The implementation treats LiveView as the owner of workflow state rather than a projection layer. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]
**How to avoid:** Reconstruct all run views from persisted rows on mount, and use PubSub only as a refresh trigger. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] [VERIFIED: lib/scoria_web/live/orchestrator_live.ex]
**Warning signs:** Refreshing the page clears badges, approvals, or timeline entries that were visible moments earlier. [ASSUMED]

### Pitfall 4: Async Test Failures from Missing Sandbox Sharing
**What goes wrong:** Workflow worker tests or LiveView tests fail intermittently with DB ownership errors. [VERIFIED: current test setup patterns]
**Why it happens:** The repo currently uses `Ecto.Adapters.SQL.Sandbox` with shared mode for non-async cases, and spawned processes need explicit ownership handling. [VERIFIED: test/test_helper.exs] [VERIFIED: test/support/eval_case.ex]
**How to avoid:** Add a `WorkflowCase` that centralizes sandbox checkout and, if Oban is adopted, Oban test mode setup. [VERIFIED: test/support/eval_case.ex] [CITED: https://hexdocs.pm/oban/testing.html]
**Warning signs:** Failing tests mention sandbox checkout, DBConnection ownership, or jobs executing outside the test process. [ASSUMED]

## Code Examples

Verified patterns from official sources and repo-local analogs:

### Atomic Transition Write
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Ecto.Multi.new()
|> Ecto.Multi.insert(:checkpoint, checkpoint_changeset)
|> Ecto.Multi.update(:run, run_changeset)
|> Repo.transaction()
```

### Optimistic Lock for Operator-Facing Mutation
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Changeset.html#optimistic_lock/3
run
|> Ecto.Changeset.change(status: "retrying")
|> Ecto.Changeset.optimistic_lock(:lock_version)
```

### LiveView Stream Projection
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
socket
|> stream(:steps, steps)
|> assign_async(:details, fn -> {:ok, %{details: load_details(run_id)}} end)
```

### Oban Enqueue Inside a Transaction
```elixir
# Source: https://hexdocs.pm/oban/Oban.html
Ecto.Multi.new()
|> Ecto.Multi.insert(:step, step_changeset)
|> Oban.insert(:job, StepWorker.new(%{step_id: step_id}))
|> Repo.transaction()
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| In-memory agent loop state | Semantic checkpoints at stable transitions | Current phase requirement for v1.1 Caldera. [VERIFIED: .planning/MILESTONES.md] [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] | Survives deploys, restarts, and long approval pauses without needing process resurrection. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] |
| Ownership-transfer handoffs | Root-owned run with bounded delegated steps | Current phase locked decision. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] | Keeps approvals, cancellation, budgets, and traceability in one durable authority. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] |
| Graph-first workflow UI | Trace-first tree with timeline drilldown | Current phase locked decision. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] | Fits existing Scoria operator UX patterns and LiveView streaming constraints better. [VERIFIED: lib/scoria_web/live/orchestrator_live.ex] [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] |

**Deprecated/outdated:**
- PubSub-only pause or resume state is not acceptable for Phase 5 durability, because the phase context explicitly limits PubSub to visibility rather than truth. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]
- A Jido-first public API is out of scope for Phase 5, because the locked decision keeps Jido optional and adapter-scoped. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Inconsistent checkpoint counts will be a practical operator warning sign worth exposing in the UI. [ASSUMED] | Common Pitfalls | Low; it affects observability polish, not the core workflow contract. |
| A2 | Refreshing the page after relying on socket-owned state would visibly clear badges or timeline data. [ASSUMED] | Common Pitfalls | Low; it describes expected failure symptoms rather than the core design. |
| A3 | Sandbox ownership and out-of-process job execution will be a likely test failure mode once workflow workers are added. [ASSUMED] | Common Pitfalls | Medium; it affects Wave 0 test planning and helper design. |

## Open Questions (RESOLVED)

1. **Should Phase 5 adopt Oban now or defer durable dispatch to a custom reconciler?**
   What we know: current repo execution is `Task.Supervisor`-based, while the phase requires crash-safe resume and retry semantics. [VERIFIED: lib/scoria/application.ex] [VERIFIED: lib/scoria/mcp/executor.ex] [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]
   What's unclear: whether the milestone wants one additional dependency in v1.1 or prefers a smaller first cut with more custom runtime code. [VERIFIED: mix.exs] [VERIFIED: .planning/MILESTONES.md]
   Recommendation: adopt Oban narrowly for wakeups and retries; if that is declined, add explicit plan tasks for startup reconciliation, retry timing, duplicate suppression, and worker test helpers. [CITED: https://hexdocs.pm/oban/Oban.html] [CITED: https://hexdocs.pm/oban/testing.html]

2. **Should `ai_approvals.run_id` stay a string or gain a binary-id workflow foreign key?**
   What we know: the current approval schema stores `run_id` as a string and has no `step_id`, `checkpoint_id`, or `lock_version`. [VERIFIED: lib/scoria/observe/approval.ex] [VERIFIED: priv/repo/migrations/20260510160812_create_ai_approvals.exs]
   What's unclear: whether backward compatibility matters for any already-created approval rows in local environments. [VERIFIED: current repo state]
   Recommendation: add `workflow_run_id`, `step_id`, `checkpoint_id`, and `lock_version` in an additive migration, keep the existing string field temporarily, and backfill forward in code during Phase 5. [VERIFIED: lib/scoria/observe/approval.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html#optimistic_lock/3]

### Resolution

These questions are resolved for planning purposes:

1. **Dispatch and resume strategy:** Phase 5 should use a repo-local startup reconciler plus supervised `Task.Supervisor` execution, not Oban, as the default dispatch path. This keeps the milestone aligned with the repo's current dependency footprint and Phase 5's "not a generic workflow engine" constraint while still enabling crash-safe exact resume by scanning persisted runnable steps on application boot and after approval/retry transitions. Oban remains a documented future upgrade path, not a phase-5 prerequisite. [VERIFIED: mix.exs] [VERIFIED: lib/scoria/application.ex] [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]

2. **Approval linkage strategy:** Phase 5 should extend `ai_approvals` additively with `workflow_run_id`, `step_id`, `checkpoint_id`, and `lock_version`, while retaining the existing string `run_id` temporarily for compatibility. Workflow durability must use the new binary-id links, and operator decisions must be guarded with optimistic locking. [VERIFIED: lib/scoria/observe/approval.ex] [VERIFIED: priv/repo/migrations/20260510160812_create_ai_approvals.exs] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html#optimistic_lock/3]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | migrations, tests, LiveView, workers | ✓ [VERIFIED: local shell] | Mix 1.19.5 / OTP 28 [VERIFIED: `mix --version`] | — |
| PostgreSQL CLI | local DB-backed development and manual workflow inspection | ✓ [VERIFIED: local shell] | `psql` 14.17 [VERIFIED: `psql --version`] | — |
| Node / npm | host-app Tailwind scanning if install flow or dashboard assets change | ✓ [VERIFIED: local shell] | Node 22.14.0 / npm 11.1.0 [VERIFIED: `node --version`; `npm --version`] | Existing inline classes reduce immediate asset pressure, but host apps still need the scan path for embedded components. [VERIFIED: lib/mix/tasks/scoria.install.ex] |

**Missing dependencies with no fallback:**
- None found in the local environment for planning purposes. [VERIFIED: local shell probes]

**Missing dependencies with fallback:**
- Oban is not currently in `mix.exs`; the fallback is a custom startup reconciler plus `Task.Supervisor`, but that increases implementation scope. [VERIFIED: mix.exs] [VERIFIED: lib/scoria/application.ex] [VERIFIED: lib/scoria/mcp/executor.ex]
- Jido is not currently in `mix.exs`; the fallback is to defer the adapter or keep mapping logic on plain maps/telemetry until the optional dependency is added. [VERIFIED: mix.exs] [VERIFIED: lib/scoria/observe/adapters/jido.ex]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix LiveViewTest + Ecto SQL Sandbox. [VERIFIED: test/test_helper.exs] [VERIFIED: test/scoria_web/live/orchestrator_live_test.exs] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/scoria/workflows_test.exs test/scoria/workflows/runtime_test.exs`. [ALIGNED: phase 5 plans] |
| Full suite command | `mix test`. [VERIFIED: current repo test layout] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WF-01 | `run`/`step`/`checkpoint`/approval transition writes are atomic and durable | unit + integration | `mix test test/scoria/workflows_test.exs test/scoria/workflows/runtime_test.exs` | ❌ Wave 0 [ALIGNED: 05-VALIDATION.md and phase 5 plans] |
| WF-02 | crashed or failed steps can be resumed exactly or retried safely | integration | `mix test test/scoria/workflows/runtime_test.exs test/scoria/workflows/integration_test.exs` | ❌ Wave 0 [ALIGNED: 05-VALIDATION.md and phase 5 plans] |
| WF-03 | handoff steps preserve root ownership and only pass projected context | unit | `mix test test/scoria/workflows/handoff_test.exs -x` | ❌ Wave 0 [VERIFIED: repo file list] |
| WF-04 | approval pauses persist, approve/reject transitions lock correctly, and resume the next step | integration + LiveView | `mix test test/scoria/workflows/approval_test.exs test/scoria_web/live/workflow_live_test.exs` | ❌ Wave 0 [ALIGNED: 05-VALIDATION.md and phase 5 plans] |
| WF-05 | trace-first visualizer renders statuses, handoff markers, checkpoint detail panel, and timeline | LiveView | `mix test test/scoria_web/live/workflow_live_test.exs test/scoria_web/components/workflow_tree_component_test.exs` | ❌ Wave 0 [ALIGNED: 05-VALIDATION.md and phase 5 plans] |
| WF-06 | optional Jido adapter maps directives into Scoria steps without becoming the public API | unit | `mix test test/scoria/workflows/jido_adapter_test.exs test/scoria/workflows/integration_test.exs` | ❌ Wave 0 [ALIGNED: 05-VALIDATION.md and phase 5 plans] |
| WF-07 | install/router integration still mounts cleanly with any new workflow pages | unit | `mix test test/mix/tasks/scoria.install_test.exs test/scoria_web/router_test.exs -x` | ✅ existing baseline, but Phase 5 coverage additions still needed. [VERIFIED: test/mix/tasks/scoria.install_test.exs] [VERIFIED: test/scoria_web/router_test.exs] |

### Sampling Rate
- **Per task commit:** run the task-targeted command from the table above, plus any directly touched LiveView or router tests. [ALIGNED: phase 5 plans]
- **Per wave merge:** `mix test`. [VERIFIED: current repo convention]
- **Phase gate:** Full suite green before `/gsd-verify-work`. [VERIFIED: GSD workflow default]

### Wave 0 Gaps
- [ ] `test/support/workflow_case.ex` to centralize sandbox setup and shared factories for runs, steps, and approvals. [VERIFIED: `test/support/workflow_case.ex` absent via repo file list]
- [ ] `test/scoria/workflows_test.exs` for `Ecto.Multi` checkpoint atomicity and workflow context APIs. [ALIGNED: 05-01-PLAN.md]
- [ ] `test/scoria/workflows/runtime_test.exs` for resume/retry and crash-recovery behavior. [ALIGNED: 05-02-PLAN.md]
- [ ] `test/scoria/workflows/handoff_test.exs` for bounded delegated-step envelopes. [VERIFIED: repo file list]
- [ ] `test/scoria/workflows/approval_test.exs` for durable approval linkage and locking. [ALIGNED: 05-02-PLAN.md]
- [ ] `test/scoria/workflows/integration_test.exs` for end-to-end resume, retry, and delegated-step recovery. [ALIGNED: 05-04-PLAN.md]
- [ ] `test/scoria_web/live/workflow_live_test.exs` for the trace-first workflow visualizer. [ALIGNED: 05-03-PLAN.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Workflow UI must stay inside the host Phoenix auth pipeline, the same way current dashboard routes mount through the host router. [VERIFIED: lib/scoria_web/router.ex] [VERIFIED: lib/mix/tasks/scoria.install.ex] |
| V3 Session Management | yes | Operator actions should continue to rely on Phoenix session handling already used by the LiveView dashboard tests and router mount. [VERIFIED: test/scoria_web/live/orchestrator_live_test.exs] [VERIFIED: lib/scoria_web/router.ex] |
| V4 Access Control | yes | Resume, retry, cancel, and approval transitions need server-side authorization gates before `Ecto.Multi` writes. [VERIFIED: phase-5 operator action scope] |
| V5 Input Validation | yes | Use `Ecto.Changeset.cast/4` and typed envelopes for `handoff_input`, approval decisions, and step results. [VERIFIED: lib/scoria/observe/approval.ex] [VERIFIED: lib/scoria/repo/span.ex] |
| V6 Cryptography | no | No new cryptographic primitive is required for this phase; use existing secret handling rules and avoid passing secrets through handoff payloads. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] |

### Known Threat Patterns for Phoenix/Ecto Workflow State

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Duplicate tool execution on retry | Tampering | Add `idempotency_key` to side-effecting steps, checkpoint after completion, and retry from a stable boundary instead of replaying ambiguous work. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] |
| Stale operator retry/approve actions | Elevation of Privilege | Guard `ai_runs` and `ai_approvals` with `lock_version` and valid status transitions. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html#optimistic_lock/3] |
| Handoff context leaking secrets or session internals | Information Disclosure | Persist projected context slices only and reject transcript/session dumping by default. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] |
| PubSub spoofing as workflow truth | Spoofing | Never mutate durable status from a broadcast alone; only projections should listen to PubSub. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/05-caldera/05-CONTEXT.md` - locked decisions, implementation constraints, deferred scope. [VERIFIED: repo-local file]
- `.planning/MILESTONES.md` - Phase 5 objectives and scope wording. [VERIFIED: repo-local file]
- `lib/scoria/application.ex` - current supervised execution primitive. [VERIFIED: repo-local file]
- `lib/scoria/mcp/executor.ex` - current isolated task execution boundary. [VERIFIED: repo-local file]
- `lib/scoria/observe/approval.ex` - current durable approval schema. [VERIFIED: repo-local file]
- `lib/scoria_web/live/orchestrator_live.ex` - current LiveView projection patterns (`stream`, `assign_async`, token buffering, approval modal). [VERIFIED: repo-local file]
- `lib/scoria_web/router.ex` and `lib/mix/tasks/scoria.install.ex` - current mount/install story. [VERIFIED: repo-local files]
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - transactional multi-write pattern. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
- `https://hexdocs.pm/ecto/Ecto.Changeset.html#optimistic_lock/3` - optimistic locking semantics. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html#optimistic_lock/3]
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html` - streams and async projection APIs. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
- `https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html` - PubSub contract. [CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html]
- `https://hexdocs.pm/elixir/Task.Supervisor.html` - supervised task execution. [CITED: https://hexdocs.pm/elixir/Task.Supervisor.html]
- `https://hexdocs.pm/oban/Oban.html`, `https://hexdocs.pm/oban/Oban.Worker.html`, `https://hexdocs.pm/oban/testing.html` - durable dispatch, retry/backoff, and test helpers. [CITED: https://hexdocs.pm/oban/Oban.html] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] [CITED: https://hexdocs.pm/oban/testing.html]
- `https://hexdocs.pm/jido` - optional adapter target documentation. [CITED: https://hexdocs.pm/jido]

### Secondary (MEDIUM confidence)
- `mix hex.info ecto`, `ecto_sql`, `phoenix`, `phoenix_live_view`, `phoenix_pubsub`, `postgrex`, `oban`, `jido` - current package versions and publish dates. [VERIFIED: local shell command output]

### Tertiary (LOW confidence)
- None. [VERIFIED: this document]

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM - repo-local foundations are verified, but recommending Oban is still a planner-facing architectural choice rather than an existing dependency. [VERIFIED: mix.exs] [VERIFIED: mix hex.info oban]
- Architecture: HIGH - the phase context gives unusually strong locked decisions around checkpointing, handoffs, recovery UX, and LiveView projection. [VERIFIED: .planning/phases/05-caldera/05-CONTEXT.md]
- Pitfalls: MEDIUM - the transactional, locking, and projection pitfalls are well supported; the exact operational warning signs are partly inferred from the design. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html#optimistic_lock/3] [ASSUMED]

**Research date:** 2026-05-11 [VERIFIED: current session date]
**Valid until:** 2026-06-10 for repo-local structure and 2026-05-18 for package version currency. [VERIFIED: repo-local files] [VERIFIED: mix hex.info outputs]

## RESEARCH COMPLETE
