# Phase 7: Seismograph - Pattern Map

**Mapped:** 2026-05-11
**Files analyzed:** 27
**Analogs found:** 24 / 27

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scoria/sre.ex` | context | request-response | `lib/scoria/workflows.ex` | exact |
| `lib/scoria/sre/budget_policy.ex` | schema | CRUD | `lib/scoria/workflows/run.ex` | role-match |
| `lib/scoria/sre/budget_reservation.ex` | schema | request-response | `lib/scoria/workflows/checkpoint.ex` | role-match |
| `lib/scoria/sre/breaker_trip.ex` | schema | event-driven | `lib/scoria/workflows/event.ex` | exact |
| `lib/scoria/sre/alert_policy.ex` | schema | CRUD | `lib/scoria/observe/approval.ex` | role-match |
| `lib/scoria/sre/alert_event.ex` | schema | event-driven | `lib/scoria/workflows/event.ex` | exact |
| `lib/scoria/sre/incident.ex` | schema | CRUD | `lib/scoria/workflows/run.ex` | role-match |
| `lib/scoria/sre/incident_event.ex` | schema | event-driven | `lib/scoria/workflows/checkpoint.ex` | role-match |
| `lib/scoria/sre/notification_delivery.ex` | schema | request-response | `lib/scoria/observe/approval.ex` | role-match |
| `lib/scoria/sre/audit_outbox_event.ex` | schema | event-driven | `lib/scoria/workflows/event.ex` | exact |
| `lib/scoria/sre/audit_sink.ex` | behavior | integration | `lib/scoria/observe/adapters/jido.ex` | partial |
| `lib/scoria/sre/alert_sink.ex` | behavior | integration | `lib/scoria/observe/adapters/req_llm.ex` | partial |
| `lib/scoria/sre/budget_engine.ex` | service | request-response | `lib/scoria/eval.ex` | partial |
| `lib/scoria/sre/breaker_registry.ex` | service | event-driven | `lib/scoria/mcp/executor.ex` | role-match |
| `lib/scoria/sre/telemetry.ex` | telemetry bridge | pub-sub | `lib/scoria/observe/telemetry.ex` | exact |
| `lib/scoria/sre/incident_manager.ex` | service | event-driven | `lib/scoria/workflows.ex` | partial |
| `lib/scoria/sre/relay.ex` | runtime/orchestration | event-driven | `lib/scoria/workflows/runtime.ex` | role-match |
| `lib/scoria/sre/adapters/threadline.ex` | helper/adapter | integration | `lib/scoria/observe/adapters/req_llm.ex` | role-match |
| `lib/scoria/sre/adapters/chimeway.ex` | helper/adapter | integration | `lib/scoria/observe/adapters/req_llm.ex` | role-match |
| `lib/scoria/sre/adapters/mailglass.ex` | helper/adapter | integration | `lib/scoria/observe/adapters/req_llm.ex` | role-match |
| `lib/scoria/sre/adapters/parapet.ex` | helper/adapter | event-driven | `lib/scoria/observe/adapters/req_llm.ex` | role-match |
| `lib/scoria/workflows.ex` | context | event-driven | `lib/scoria/workflows.ex` | exact |
| `lib/scoria/workflows/runtime.ex` | runtime/orchestration | event-driven | `lib/scoria/workflows/runtime.ex` | exact |
| `lib/scoria/mcp/executor.ex` | integration boundary | request-response | `lib/scoria/mcp/executor.ex` | exact |
| `lib/scoria/observe/redactor.ex` | utility | transform | `lib/scoria/observe/redactor.ex` | exact |
| `lib/scoria/observe/telemetry.ex` | telemetry bridge analog | pub-sub | `lib/scoria/observe/telemetry.ex` | exact |
| `lib/scoria/application.ex` | supervisor root | process supervision | `lib/scoria/application.ex` | exact |
| `lib/scoria_web/live/orchestrator_live.ex` | liveview | projection | `lib/scoria_web/live/orchestrator_live.ex` | exact |
| `lib/scoria_web/components/incident_evidence_component.ex` | component | projection | `lib/scoria_web/components/citation_evidence_component.ex` | role-match |
| `priv/repo/migrations/20260511170000_create_sre_tables.exs` | migration | storage | `priv/repo/migrations/20260511000100_create_workflow_tables.exs` | exact |
| `test/scoria/sre_test.exs` | test | CRUD | `test/scoria/workflows_test.exs` | exact |
| `test/scoria/sre/budget_engine_test.exs` | test | request-response | `test/scoria/mcp/executor_test.exs` | role-match |
| `test/scoria/sre/telemetry_test.exs` | test | event-driven | `test/scoria/observe/telemetry_test.exs` | exact |
| `test/scoria/sre/audit_outbox_test.exs` | test | event-driven | `test/scoria/workflows/runtime_test.exs` | role-match |
| `test/scoria/sre/incident_test.exs` | test | event-driven | `test/scoria/workflows/runtime_test.exs` | role-match |
| `test/scoria/sre/relay_test.exs` | test | runtime/orchestration | `test/scoria/workflows/runtime_test.exs` | role-match |
| `test/scoria/mcp/executor_test.exs` | test | request-response | `test/scoria/mcp/executor_test.exs` | exact |
| `test/scoria_web/live/orchestrator_live_test.exs` | test | projection | `test/scoria_web/live/orchestrator_live_test.exs` | exact |
| `test/scoria_web/live/orchestrator_live_sre_test.exs` | test | projection | `test/scoria_web/live/orchestrator_live_test.exs` | role-match |

## Pattern Assignments

### `lib/scoria/sre.ex` and workflow-SRE writes

**Analogs:** `lib/scoria/workflows.ex`, `lib/scoria/eval.ex`

**Imports / context ownership** (`lib/scoria/workflows.ex` lines 6-11):
```elixir
import Ecto.Query, warn: false

alias Ecto.Multi
alias Scoria.Observe.Approval
alias Scoria.Repo
alias Scoria.Workflows.{Checkpoint, Event, Handoff, Run, Step}
```

**Transactional context write pattern** (`lib/scoria/eval.ex` lines 27-48):
```elixir
Ecto.Multi.new()
|> Ecto.Multi.insert(:dataset, Dataset.changeset(%Dataset{}, attrs_with_defaults))
|> Ecto.Multi.run(:items, fn repo, %{dataset: dataset} ->
  # dependent writes
end)
|> Repo.transaction()
|> case do
  {:ok, %{dataset: dataset}} -> {:ok, dataset}
  {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
end
```

**Run/event/checkpoint co-write pattern** (`lib/scoria/workflows.ex` lines 81-117):
```elixir
multi =
  Multi.new()
  |> Multi.insert(:run, Run.changeset(%Run{}, Map.merge(%{status: "running", started_at: now}, run_attrs)))
  |> Multi.run(:checkpoint, fn repo, changes ->
    {:ok, insert_checkpoint(repo, changes.run.id, changes[:initial_step] && changes.initial_step.id, %{...})}
  end)
  |> Multi.run(:event, fn repo, changes ->
    {:ok, insert_event(repo, changes.run.id, changes[:initial_step] && changes.initial_step.id, %{...})}
  end)
```

**Phase 7 application:** keep SRE state in an owning context module, not scattered inside LiveView or executor modules. Budget reservation, actual-usage reconciliation, breaker trip history, and audit-outbox writes should happen in the same `Ecto.Multi` boundary as the workflow truth they protect.

---

### SRE schemas: `budget_policy.ex`, `budget_reservation.ex`, `breaker_trip.ex`

**Analogs:** `lib/scoria/workflows/run.ex`, `lib/scoria/workflows/checkpoint.ex`, `lib/scoria/workflows/event.ex`, `lib/scoria/observe/approval.ex`

**Schema / binary-id convention** (`lib/scoria/workflows/run.ex` lines 5-29):
```elixir
@statuses ~w(running waiting_for_approval paused retrying failed completed cancelled)

@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id
schema "ai_workflow_runs" do
  field :session_id, :string
  field :root_role_id, :string
  field :status, :string, default: "running"
  field :lock_version, :integer, default: 1
  field :metadata, :map, default: %{}

  timestamps(type: :utc_datetime_usec)
end
```

**Append-only event payload pattern** (`lib/scoria/workflows/event.ex` lines 7-25):
```elixir
schema "ai_workflow_events" do
  field :sequence, :integer
  field :event_type, :string
  field :payload, :map, default: %{}

  belongs_to :run, Scoria.Workflows.Run
  belongs_to :step, Scoria.Workflows.Step
end
```

**Checkpoint snapshot pattern** (`lib/scoria/workflows/checkpoint.ex` lines 7-28):
```elixir
schema "ai_workflow_checkpoints" do
  field :sequence, :integer
  field :transition, :string
  field :status, :string
  field :snapshot, :map, default: %{}
  field :cursor, :map
  field :metadata, :map, default: %{}
end
```

**Enum + optimistic lock pattern** (`lib/scoria/observe/approval.ex` lines 5-24):
```elixir
@statuses ~w(pending approved rejected)

approval
|> cast(attrs, [:tool_name, :arguments, :status, :session_id, :run_id, :workflow_run_id, :step_id, :checkpoint_id, :lock_version])
|> validate_required([:tool_name, :status])
|> validate_inclusion(:status, @statuses)
|> optimistic_lock(:lock_version)
```

**Phase 7 application:**
- `budget_policy.ex` should look like a versioned, lockable root record similar to `Run`, with small explicit status/threshold fields and a `metadata` map for future policy detail.
- `budget_reservation.ex` should behave more like a checkpoint row than a mutable balance sheet: append clear reservation/reconciliation snapshots with typed status and references back to workflow run, step, provider/tool, and policy.
- `breaker_trip.ex` should stay append-only like `Event`, storing `event_type`, trip reason, breaker key, scope, and minimal evidence references rather than raw request bodies.

---

### `lib/scoria/workflows.ex`, `lib/scoria/workflows/runtime.ex`, `lib/scoria/mcp/executor.ex`

**Analogs:** same files

**Runnable-step query and ordered replay** (`lib/scoria/workflows.ex` lines 69-75):
```elixir
Step
|> join(:inner, [s], r in assoc(s, :run))
|> where([s, r], s.status in ["queued", "retrying"] and r.status in ["running", "retrying"])
|> order_by([s, _r], asc: s.run_id, asc: s.sequence)
|> Repo.all()
```

**Durable wait-state transition** (`lib/scoria/workflows.ex` lines 252-303):
```elixir
updated_run =
  repo.update!(Run.changeset(run, %{status: "waiting_for_approval", current_step_id: step.id}))

checkpoint =
  insert_checkpoint(repo, run.id, step.id, %{
    transition: "waiting_for_approval",
    status: "waiting_for_approval",
    snapshot: %{reason: Map.get(attrs, :reason) || Map.get(attrs, "reason")},
    metadata: %{}
  })

approval =
  %Approval{}
  |> Approval.changeset(approval_attrs)
  |> repo.insert!()
```

**Supervised runtime boundary** (`lib/scoria/workflows/runtime.ex` lines 10-45):
```elixir
with {:ok, _claimed} <- Workflows.claim_step(step_id) do
  step = Workflows.get_step!(step_id)
  run = Workflows.get_run!(step.run_id)
  timeout = Keyword.get(opts, :timeout, @default_timeout)

  task =
    Task.Supervisor.async_nolink(Scoria.Workflow.TaskSupervisor, fn ->
      invoke_handler(handler, step, run)
    end)

  case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
    {:ok, {:ok, result}} -> Workflows.complete_step(step.id, normalize_payload(result))
    nil -> Workflows.fail_step(step.id, %{"reason" => "timeout"})
    {:exit, reason} -> Workflows.fail_step(step.id, %{"reason" => inspect(reason)})
  end
end
```

**Executor telemetry envelope** (`lib/scoria/mcp/executor.ex` lines 10-37):
```elixir
context = context || %{}
metadata = Map.merge(context, %{tool: tool_module, args: args})

:telemetry.execute([:scoria, :tool, :started], %{system_time: System.system_time()}, metadata)

case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
  {:ok, result} ->
    :telemetry.execute([:scoria, :tool, :completed], %{duration: duration}, metadata)
    result

  nil ->
    :telemetry.execute([:scoria, :tool, :timeout], %{duration: duration}, metadata)
    {:error, :timeout}
end
```

**Phase 7 application:**
- Budget reservation should happen before paid or side-effecting work enters `Task.Supervisor`.
- Actual usage reconciliation, breaker trip recording, and audit-outbox insertion should happen after result classification but before the transition is considered complete.
- Keep `MCP.Executor` as the external-effect boundary. Add policy context and redacted audit metadata there rather than pushing spend/breaker logic into tools.

---

### Audit export: `audit_outbox_event.ex`, `audit_sink.ex`, `redactor.ex`, `telemetry.ex`, `parapet.ex`

**Analogs:** `lib/scoria/observe/redactor.ex`, `lib/scoria/observe/telemetry.ex`, `lib/scoria/observe/adapters/jido.ex`, `lib/scoria/observe/adapters/req_llm.ex`

**Redaction boundary** (`lib/scoria/observe/redactor.ex` lines 8-36):
```elixir
def redact(data) do
  config = Application.get_env(:scoria, __MODULE__, [])

  case Keyword.get(config, :mfa) do
    {mod, fun, args} -> apply(mod, fun, [data | args])
    nil -> do_redact(data, build_deny_list(config))
  end
end
```

**Telemetry bridge pattern** (`lib/scoria/observe/telemetry.ex` lines 5-21):
```elixir
@events [
  [:scoria, :observe, :span, :stop]
]

def attach(buffer_name \\ Buffer) do
  :telemetry.attach_many(
    "scoria-observe-telemetry",
    @events,
    &__MODULE__.handle_event/4,
    %{buffer_name: buffer_name}
  )
end
```

**Narrow adapter / helper pattern** (`lib/scoria/observe/adapters/jido.ex` lines 2-25):
```elixir
def attach do
  :telemetry.attach_many(
    "scoria-observe-jido",
    [[:jido, :action, :stop]],
    &__MODULE__.handle_event/4,
    nil
  )
end

:telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)
```

**Alternative adapter example** (`lib/scoria/observe/adapters/req_llm.ex` lines 11-25):
```elixir
span = %{
  name: "req_llm_request",
  span_kind: "LLM",
  trace_id: metadata[:trace_id] || Ecto.UUID.generate(),
  attributes: %{
    "llm.model_name" => metadata[:model],
    "llm.token_count" => measurements[:total_tokens],
    "req.url" => metadata[:url]
  }
}
```

**Phase 7 application:**
- `audit_outbox_event.ex` should be a durable Ecto row, not a telemetry-only record.
- `audit_sink.ex` should be a narrow behavior or MFA seam, with a no-op default and first-party adapters layered on top, matching the existing lightweight adapter posture.
- `parapet.ex` should stay small and telemetry-oriented like the observe adapters: transform internal events into a stable external envelope rather than owning durable state.
- Redact at the export boundary. Store references, hashes, policy classes, trace ids, and workflow ids instead of raw arguments.

---

### Alerts and incidents: `alert_policy.ex`, `alert_event.ex`, `incident.ex`, `incident_event.ex`, `notification_delivery.ex`, `alerts.ex`

**Analogs:** `lib/scoria/observe/approval.ex`, `lib/scoria/workflows/run.ex`, `lib/scoria/workflows/event.ex`, `lib/scoria/workflows.ex`

**Mutable root record pattern** (`lib/scoria/workflows/run.ex` lines 31-49):
```elixir
run
|> cast(attrs, [
  :session_id,
  :root_role_id,
  :status,
  :current_step_id,
  :latest_checkpoint_id,
  :lock_version,
  :metadata,
  :error_envelope
])
|> validate_required([:root_role_id, :status])
|> validate_inclusion(:status, @statuses)
|> optimistic_lock(:lock_version)
```

**Append-only event recording** (`lib/scoria/workflows.ex` lines 154-164):
```elixir
def append_event(run_id, step_id, attrs) do
  case Repo.transaction(fn repo -> insert_event(repo, run_id, step_id, attrs) end) do
    {:ok, event} ->
      broadcast(run_id, {:workflow_updated, run_id})
      {:ok, event}

    {:error, value} ->
      {:error, value}
  end
end
```

**Approval-style status validation** (`lib/scoria/observe/approval.ex` lines 17-24):
```elixir
|> validate_required([:tool_name, :status])
|> validate_inclusion(:status, @statuses)
|> optimistic_lock(:lock_version)
```

**Phase 7 application:**
- `incident.ex` should be the mutable dedupe root keyed by stable incident key and current status.
- `incident_event.ex` and `alert_event.ex` should be append-only history rows with typed reason codes and evidence references.
- `notification_delivery.ex` should follow the small explicit status style from `Approval`, with a delivery-attempt lifecycle and redacted payload summary.
- `alerts.ex` should own the dedupe/open-or-append transaction the same way `Workflows` owns durable run transitions.

---

### Operator surface: `lib/scoria_web/live/orchestrator_live.ex` and `incident_evidence_component.ex`

**Analogs:** `lib/scoria_web/live/orchestrator_live.ex`, `lib/scoria_web/live/workflow_live/show.ex`, `lib/scoria_web/components/citation_evidence_component.ex`, `lib/scoria_web/components/workflow_detail_panel_component.ex`, `lib/scoria_web/components/trace_tree_component.ex`

**Mount / subscription / stream boot** (`lib/scoria_web/live/orchestrator_live.ex` lines 6-23):
```elixir
def mount(_params, session, socket) do
  if connected?(socket) do
    tenant_id = session["tenant_id"] || "default"
    Phoenix.PubSub.subscribe(Scoria.PubSub, "scoria:runs:#{tenant_id}")
  end

  socket =
    socket
    |> assign(:page_title, "Scoria Dashboard")
    |> assign(:active_approval, nil)
    |> stream(:traces, [])

  {:ok, socket}
end
```

**Async evidence drilldown** (`lib/scoria_web/live/orchestrator_live.ex` lines 74-95):
```elixir
def handle_event("load_metadata", %{"id" => trace_id}, socket) do
  {:noreply,
   assign_async(socket, :trace_metadata, fn ->
     {:ok, %{trace_metadata: %{id: trace_id, deep_data: "loaded lazily"}}}
   end)}
end

def handle_event("load_retrieval_evidence", %{"id" => trace_id}, socket) do
  {:noreply,
   assign_async(socket, :retrieval_evidence, fn ->
     {:ok, %{retrieval_evidence: sample_evidence(trace_id)}}
   end)}
end
```

**Trace-first detail panel** (`lib/scoria_web/live/workflow_live/show.ex` lines 68-99):
```elixir
run = Workflows.get_run_tree!(run_id)
steps = decorate_steps(run.steps)
selected_step_id = socket.assigns[:selected_step_id] || default_step_id(steps)

socket
|> assign(:run, run)
|> assign(:steps, steps)
|> assign(:events, run.events)
|> assign_selection(selected_step_id)
```

**Evidence-side-by-side component pattern** (`lib/scoria_web/components/citation_evidence_component.ex` lines 7-56):
```elixir
<section class="rounded-xl border border-stone-200 bg-stone-50 p-4 shadow-sm">
  <div class="mb-3 flex items-center justify-between">
    <div>
      <p class="text-xs uppercase tracking-[0.24em] text-stone-500">retrieval evidence</p>
      <h3 class="text-lg font-semibold text-stone-900">side-by-side citation review</h3>
    </div>
  </div>
</section>
```

**Detail panel evidence rendering** (`lib/scoria_web/components/workflow_detail_panel_component.ex` lines 7-38):
```elixir
<aside id="workflow-detail-panel" class="rounded-2xl border border-stone-200 bg-white p-4 shadow-sm">
  <%= if @step do %>
    <dl class="mt-4 space-y-2 text-sm">
      <div :if={@checkpoint}>
        <dt class="font-medium text-stone-600">Checkpoint</dt>
        <dd class="workflow-checkpoint-metadata whitespace-pre-wrap font-mono text-xs"><%= inspect(@checkpoint.snapshot) %></dd>
      </div>
    </dl>
  <% end %>
</aside>
```

**Phase 7 application:**
- Keep incidents, budgets, and approval/breaker evidence inside the existing trace-first dashboard rather than creating a new control-plane app.
- Use `assign_async/3` for incident evidence and budget drilldown so the initial mount stays light.
- Reuse the current pattern of “select item, then inspect checkpoint/evidence” rather than introducing detached modal workflows for everything.

---

### Migrations and tests

**Analogs:** `priv/repo/migrations/20260511000100_create_workflow_tables.exs`, `priv/repo/migrations/20260510015813_create_ai_observability_tables.exs`, `test/scoria/workflows/runtime_test.exs`, `test/scoria/mcp/executor_test.exs`, `test/scoria_web/live/orchestrator_live_test.exs`

**Migration table/index style** (`priv/repo/migrations/20260511000100_create_workflow_tables.exs` lines 5-24, 69-82):
```elixir
create table(:ai_workflow_runs, primary_key: false) do
  add :id, :binary_id, primary_key: true
  add :status, :string, null: false, default: "running"
  add :metadata, :map, null: false, default: %{}

  timestamps(type: :utc_datetime_usec)
end

create index(:ai_workflow_runs, [:session_id])
create index(:ai_workflow_runs, [:status])
```

**GIN / evidence lookup pattern** (`priv/repo/migrations/20260510015813_create_ai_observability_tables.exs` lines 13-15, 37, 52):
```elixir
create index(:ai_traces, [:attributes], using: "GIN")
create index(:ai_spans, [:attributes], using: "GIN")
create index(:ai_span_events, [:attributes], using: "GIN")
```

**Runtime durability tests** (`test/scoria/workflows/runtime_test.exs` lines 24-61, 64-121):
```elixir
test "timeout or crash paths emit durable failure transitions" do
  assert {:ok, failed_step} = Runtime.execute_step(timeout_step.id, handler: {Handlers, :timeout}, timeout: 10)
  assert failed_step.status == "failed"
  assert Workflows.get_run!(timeout_run.id).status == "failed"
end
```

**Telemetry/executor test harness** (`test/scoria/mcp/executor_test.exs` lines 37-60, 76-104):
```elixir
handler_id = "executor-test-#{System.unique_integer()}"
:telemetry.attach_many(handler_id, events, handler, nil)

on_exit(fn ->
  :telemetry.detach(handler_id)
end)
```

**LiveView interaction tests** (`test/scoria_web/live/orchestrator_live_test.exs` lines 57-109, 129-189):
```elixir
send(view.pid, {:new_trace, trace})
render_click(view, "load_retrieval_evidence", %{"id" => "trace-evidence"})
assert render(view) =~ "freshness"

send(view.pid, {:hitl_request, approval})
render_click(view, "approve", %{})
```

**Phase 7 application:**
- Keep migration layout additive and explicit. Prefer a focused Phase 7 migration over scattered one-column migrations.
- Write runtime tests around persistence guarantees first: reserve, reconcile, trip, open incident, append incident event, emit redacted outbox.
- LiveView tests should assert deep links, lazy evidence loading, and operator actions on the existing dashboard route.

## Shared Patterns

### Durable truth before projection
**Sources:** `lib/scoria/workflows.ex` lines 81-117 and 252-303, `lib/scoria/workflows/runtime.ex` lines 10-45

Apply to budget enforcement, breaker trips, alert creation, and incident open/append flows. Persist the fact first, then broadcast or emit telemetry.

### Small explicit status vocabularies
**Sources:** `lib/scoria/workflows/run.ex` lines 5-6, `lib/scoria/observe/approval.ex` lines 5-6

Use `@statuses` lists and `validate_inclusion/3` for policy, incident, delivery, and outbox lifecycle records. Avoid opaque boolean fields.

### Redaction at export boundaries
**Sources:** `lib/scoria/observe/redactor.ex` lines 8-36, `test/scoria/observe/redactor_test.exs` lines 35-52

Every audit and notification envelope should pass through the existing redaction seam or an equivalent MFA override. Do not persist or emit raw sensitive tool arguments by default.

### Thin optional adapters
**Sources:** `lib/scoria/observe/adapters/jido.ex` lines 2-25, `lib/scoria/observe/adapters/req_llm.ex` lines 2-25

Optional Threadline, Chimeway, Mailglass, or Parapet integrations should stay as narrow adapter/helper modules attached to telemetry or behavior callbacks, not new hard dependencies in core contexts.

## No Close Analog Analysis

| File | Why no close analog exists | Planning consequence |
|---|---|---|
| `lib/scoria/sre/audit_sink.ex` | Repo has telemetry adapters, but no current behavior for durable export delivery with retries and result contracts. | Define the callback contract explicitly in the plan, including `:ok` / `{:error, reason}` semantics and redacted payload shape. |
| `lib/scoria/sre/incident_manager.ex` | Repo has durable workflow transitions, but no current incident dedupe/router context. | Spell out the open-or-append transaction, stable incident key strategy, and pager-vs-review routing rules. |
| `lib/scoria/sre/budget_reservation.ex` | Repo has checkpoints/events, but no ledger-like budget reservation model with reserve/reconcile lifecycle. | Keep the schema explicit and test the state machine directly instead of assuming an existing finance pattern. |

## Key Reuse Notes

- Reuse `Scoria.Workflows` as the model for Phase 7 atomicity: local truth change, checkpoint/event append, then projection.
- Reuse `Scoria.MCP.Executor` as the only place external-effect tool governance should wrap execution.
- Reuse `Scoria.Observe.Redactor` for both audit export and notification payload shaping.
- Reuse `ScoriaWeb.OrchestratorLive` and `WorkflowLive.Show` for a calm operator UX built around evidence drilldown instead of separate admin pages.
- Reuse workflow-style append-only event history for incidents, circuit trips, and audit outbox rows. Avoid mutable “last known state only” tables where investigation needs chronology.

## Metadata

**Analog search scope:** `lib/**/*.ex`, `priv/repo/migrations/*.exs`, `test/**/*.exs`, `.planning/phases/05-caldera/`, `.planning/phases/06-corpus/`
**Files scanned:** 40+
**Pattern extraction date:** 2026-05-11
