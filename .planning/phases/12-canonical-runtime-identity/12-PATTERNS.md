# Phase 12: Canonical Runtime Identity - Pattern Map

**Mapped:** 2026-05-13
**Files analyzed:** 17
**Analogs found:** 17 / 17

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scoria/identity.ex` | utility | transform | `lib/scoria/sre/telemetry_identity.ex` | role-match |
| `lib/scoria.ex` | utility | request-response | `lib/scoria_web/router.ex` | partial |
| `lib/scoria/workflows/run.ex` | model | CRUD | `lib/scoria/workflows/run.ex` | exact |
| `lib/scoria/workflows.ex` | service | CRUD | `lib/scoria/workflows.ex` | exact |
| `lib/scoria/workflows/runtime.ex` | service | request-response | `lib/scoria/workflows/runtime.ex` | exact |
| `lib/scoria/observe/approval.ex` | model | CRUD | `lib/scoria/observe/approval.ex` | exact |
| `lib/scoria/mcp/executor.ex` | service | request-response | `lib/scoria/mcp/executor.ex` | exact |
| `lib/scoria/mcp/router.ex` | middleware | request-response | `lib/scoria/mcp/router.ex` | exact |
| `lib/scoria/sre/telemetry_identity.ex` | utility | transform | `lib/scoria/sre/telemetry_identity.ex` | exact |
| `priv/repo/migrations/*_add_identity_to_workflow_runs.exs` | migration | CRUD | `priv/repo/migrations/20260511000100_create_workflow_tables.exs` | role-match |
| `priv/repo/migrations/*_add_identity_to_ai_approvals.exs` | migration | CRUD | `priv/repo/migrations/20260511000200_link_approvals_to_workflows.exs` | role-match |
| `test/scoria/identity_test.exs` | test | transform | `test/scoria/sre/telemetry_test.exs` | role-match |
| `test/scoria/workflows_test.exs` | test | CRUD | `test/scoria/workflows_test.exs` | exact |
| `test/scoria/workflows/runtime_test.exs` | test | request-response | `test/scoria/workflows/runtime_test.exs` | exact |
| `test/scoria/workflows/integration_test.exs` | test | request-response | `test/scoria/workflows/integration_test.exs` | exact |
| `test/scoria/sre/audit_outbox_test.exs` | test | event-driven | `test/scoria/sre/audit_outbox_test.exs` | exact |
| `test/scoria/mcp/executor_telemetry_test.exs` | test | request-response | `test/scoria/mcp/executor_telemetry_test.exs` | exact |

## Pattern Assignments

### `lib/scoria/identity.ex` (utility, transform)

**Analog:** `lib/scoria/sre/telemetry_identity.ex`

**Imports / module shape** ([lib/scoria/sre/telemetry_identity.ex:1](/Users/jon/projects/scoria/lib/scoria/sre/telemetry_identity.ex:1))
```elixir
defmodule Scoria.SRE.TelemetryIdentity do
  @moduledoc """
  Builds the canonical low-cardinality SRE identity contract.
  """
```

**Normalization pattern** ([lib/scoria/sre/telemetry_identity.ex:23](/Users/jon/projects/scoria/lib/scoria/sre/telemetry_identity.ex:23), [lib/scoria/sre/telemetry_identity.ex:89](/Users/jon/projects/scoria/lib/scoria/sre/telemetry_identity.ex:89))
```elixir
def labels(attrs) do
  attrs = normalize(attrs)

  @label_keys
  |> Enum.reduce(%{identity_key: build_identity_key(attrs)}, fn key, acc ->
    put_if_present(acc, key, Map.get(attrs, key))
  end)
end

defp normalize(attrs) do
  attrs
  |> Map.new()
  |> Map.put_new_lazy(:run_id, fn -> Map.get(attrs, :workflow_run_id) end)
  |> Map.put_new(:tenant_id, "system")
  |> Map.put_new(:subject_kind, "workflow")
  |> Map.put_new(:policy_key, "policy")
  |> Map.put_new(:reason_code, "unknown")
  |> Map.put_new(:window_bucket, "global")
end
```

**What to copy**
- Keep the module boring and map-driven.
- Normalize atom and string keyed inputs immediately.
- Use helper functions for `put_new` / fallback rules instead of spreading fallback chains through callers.

### `lib/scoria.ex` (utility, request-response)

**Analog:** `lib/scoria_web/router.ex`

**Public API posture** ([lib/scoria_web/router.ex:1](/Users/jon/projects/scoria/lib/scoria_web/router.ex:1))
```elixir
defmodule ScoriaWeb.Router do
  @moduledoc """
  Provides the scoria_dashboard macro to mount the Scoria LiveView dashboard
  in a host Phoenix application.
  """

  defmacro scoria_dashboard(path, _opts \\ []) do
```

**What to copy**
- Replace the placeholder `Scoria` module with a small, explicit host-facing API.
- Keep the top-level public entrypoint thin, like `ScoriaWeb.Router`; delegate real work to the identity module.

### `lib/scoria/workflows/run.ex` (model, CRUD)

**Analog:** `lib/scoria/workflows/run.ex`

**Schema pattern** ([lib/scoria/workflows/run.ex:1](/Users/jon/projects/scoria/lib/scoria/workflows/run.ex:1))
```elixir
defmodule Scoria.Workflows.Run do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_workflow_runs" do
    field :session_id, :string
    field :root_role_id, :string
    field :status, :string, default: "running"
    field :metadata, :map, default: %{}
```

**Validation pattern** ([lib/scoria/workflows/run.ex:31](/Users/jon/projects/scoria/lib/scoria/workflows/run.ex:31))
```elixir
def changeset(run, attrs) do
  run
  |> cast(attrs, [
    :session_id,
    :root_role_id,
    :status,
    :current_step_id,
    :latest_checkpoint_id,
    :lock_version,
    :metadata,
    :error_envelope,
    :started_at,
    :completed_at,
    :last_heartbeat_at
  ])
  |> validate_required([:root_role_id, :status])
  |> validate_inclusion(:status, @statuses)
  |> optimistic_lock(:lock_version)
end
```

**What to copy**
- Add `actor_id` and `tenant_id` as first-class fields beside `session_id`.
- Keep `metadata` secondary and leave optimistic locking in place.

### `lib/scoria/workflows.ex` (service, CRUD)

**Analog:** `lib/scoria/workflows.ex`

**Imports / aliases** ([lib/scoria/workflows.ex:1](/Users/jon/projects/scoria/lib/scoria/workflows.ex:1))
```elixir
import Ecto.Query, warn: false

alias Ecto.Multi
alias Scoria.Observe.Approval
alias Scoria.Repo
alias Scoria.SRE
alias Scoria.SRE.AuditOutboxEvent
alias Scoria.Workflows.{Checkpoint, Event, Handoff, Run, Step}
```

**Root transaction pattern** ([lib/scoria/workflows.ex:79](/Users/jon/projects/scoria/lib/scoria/workflows.ex:79))
```elixir
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
       %{
         transition: "run_started",
         status: changes.run.status,
         snapshot: %{root_role_id: changes.run.root_role_id, metadata: changes.run.metadata},
         metadata: %{}
       }
     )}
  end)
```

**Approval persistence + audit pattern** ([lib/scoria/workflows.ex:276](/Users/jon/projects/scoria/lib/scoria/workflows.ex:276))
```elixir
approval_attrs =
  attrs
  |> Map.new()
  |> Map.merge(%{
    workflow_run_id: run.id,
    step_id: step.id,
    checkpoint_id: checkpoint.id,
    status: "pending",
    run_id: run.id
  })

approval =
  %Approval{}
  |> Approval.changeset(approval_attrs)
  |> repo.insert!()

audit_outbox_event =
  SRE.insert_audit_outbox_event(repo, %{
    tenant_id: Map.get(attrs, :tenant_id) || Map.get(attrs, "tenant_id") || "system",
    event_type: "approval.requested",
    policy_class: "approval",
    actor_ref: Map.get(attrs, :actor_id) || Map.get(attrs, "actor_id"),
    workflow_run_id: run.id,
    step_id: step.id,
    trace_id: Map.get(attrs, :trace_id) || Map.get(attrs, "trace_id")
  })
```

**Approval decision fallback pattern to remove** ([lib/scoria/workflows.ex:545](/Users/jon/projects/scoria/lib/scoria/workflows.ex:545), [lib/scoria/workflows.ex:655](/Users/jon/projects/scoria/lib/scoria/workflows.ex:655))
```elixir
updated_approval =
  approval
  |> Approval.changeset(Map.merge(Map.new(attrs), %{status: status}))
  |> repo.update!()

%{
  tenant_id:
    attr_value(attrs, :tenant_id) || (request_event && request_event.tenant_id) || "system",
  actor_id:
    attr_value(attrs, :actor_id) || (request_event && request_event.actor_ref) ||
      approval.session_id,
  trace_id: attr_value(attrs, :trace_id) || (request_event && request_event.trace_id),
  request_event: request_event
}
```

**What to copy**
- Normalize identity once before `create_run/1` writes the run row.
- Keep all truth changes, checkpoint/event writes, approval writes, and audit writes inside one transaction.
- Move fallback logic to the identity normalization edge; remove `approval.session_id` as actor fallback.

### `lib/scoria/workflows/runtime.ex` (service, request-response)

**Analog:** `lib/scoria/workflows/runtime.ex`

**Execution seam pattern** ([lib/scoria/workflows/runtime.ex:14](/Users/jon/projects/scoria/lib/scoria/workflows/runtime.ex:14))
```elixir
with {:ok, _claimed} <- Workflows.claim_step(step_id) do
  step = Workflows.get_step!(step_id)
  run = Workflows.get_run!(step.run_id)
  timeout = Keyword.get(opts, :timeout, @default_timeout)
  handler = resolve_handler(step, opts)
  budget_context = Keyword.get(opts, :budget_context, %{})
  breaker_context = build_breaker_context(step, run, Keyword.get(opts, :breaker_context, %{}))
```

**Budget context pattern** ([lib/scoria/workflows/runtime.ex:98](/Users/jon/projects/scoria/lib/scoria/workflows/runtime.ex:98))
```elixir
BudgetEngine.reserve_step(%{
  tenant_id: Map.get(budget_context, :tenant_id),
  actor_id: Map.get(budget_context, :actor_id),
  run_id: run.id,
  step_id: step.id,
  trace_id: Map.get(budget_context, :trace_id),
  integration_kind: Map.get(budget_context, :integration_kind, "workflow"),
  metadata:
    budget_context
    |> Map.get(:metadata, %{})
    |> Map.put_new("workflow_step_count", step.sequence)
})
```

**Telemetry projection pattern** ([lib/scoria/workflows/runtime.ex:255](/Users/jon/projects/scoria/lib/scoria/workflows/runtime.ex:255))
```elixir
attrs =
  base_runtime_attrs(step, run, budget_context, outcome)
  |> Map.put(:duration_ms, duration_ms)
  |> Map.put(:success, outcome in ["completed", "waiting_for_approval", "handoff"])

Telemetry.emit_latency(attrs)
Telemetry.emit_tool_reliability(attrs)
maybe_emit_budget(attrs, budget_context, outcome, result)
```

**What to copy**
- Split immutable root identity from transient execution context here.
- Build execution attrs from persisted run identity first, then overlay trace/provider/tool metadata.

### `lib/scoria/observe/approval.ex` (model, CRUD)

**Analog:** `lib/scoria/observe/approval.ex`

**Schema / validation pattern** ([lib/scoria/observe/approval.ex:1](/Users/jon/projects/scoria/lib/scoria/observe/approval.ex:1))
```elixir
defmodule Scoria.Observe.Approval do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_approvals" do
    field(:tool_name, :string)
    field(:arguments, :map, default: %{})
    field(:status, :string, default: "pending")
    field(:session_id, :string)
    field(:run_id, :string)
```

```elixir
approval
|> cast(attrs, [:tool_name, :arguments, :status, :session_id, :run_id, :workflow_run_id, :step_id, :checkpoint_id, :lock_version])
|> validate_required([:tool_name, :status])
|> validate_inclusion(:status, @statuses)
|> optimistic_lock(:lock_version)
```

**What to copy**
- Add `actor_id` and `tenant_id` to the same flat schema and cast list.
- Preserve the current lightweight changeset style.

### `lib/scoria/mcp/executor.ex` (service, request-response)

**Analog:** `lib/scoria/mcp/executor.ex`

**Execution pipeline** ([lib/scoria/mcp/executor.ex:15](/Users/jon/projects/scoria/lib/scoria/mcp/executor.ex:15))
```elixir
with {:ok, access_context} <- maybe_capture_sensitive_mcp_access(tool_module, args, context),
     {:ok, reservation_context} <- reserve_budget(tool_module, args, access_context),
     {:ok, execution_context} <- ensure_policy_sensitive_invocation(tool_module, args, access_context, reservation_context) do
  metadata =
    access_context
    |> Map.merge(%{tool: tool_module, args: args})
    |> attach_budget_metadata(execution_context)
    |> Map.put_new(:tool_ref, inspect(tool_module))
```

**Audit + policy-sensitive pattern** ([lib/scoria/mcp/executor.ex:162](/Users/jon/projects/scoria/lib/scoria/mcp/executor.ex:162), [lib/scoria/mcp/executor.ex:223](/Users/jon/projects/scoria/lib/scoria/mcp/executor.ex:223))
```elixir
with {:ok, audit_outbox_event} <-
       SRE.create_audit_outbox_event(%{
         tenant_id: Map.get(context, :tenant_id),
         actor_id: Map.get(context, :actor_id),
         workflow_run_id: Map.get(context, :run_id),
         step_id: Map.get(context, :step_id),
         trace_id: Map.get(context, :trace_id),
         event_type: "mcp.access.#{decision}",
         policy_class: "sensitive_mcp_access"
       }) do
```

```elixir
%{
  tenant_id: Map.get(context, :tenant_id),
  actor_id: Map.get(context, :actor_id),
  workflow_run_id: Map.get(context, :run_id),
  step_id: Map.get(context, :step_id),
  trace_id: Map.get(context, :trace_id),
  event_type: "tool.invocation",
  policy_class: "policy_sensitive"
}
```

**Telemetry attrs pattern** ([lib/scoria/mcp/executor.ex:245](/Users/jon/projects/scoria/lib/scoria/mcp/executor.ex:245), [lib/scoria/mcp/executor.ex:287](/Users/jon/projects/scoria/lib/scoria/mcp/executor.ex:287))
```elixir
attrs =
  base_attrs(tool_module, context, outcome)
  |> Map.put(:duration_ms, System.convert_time_unit(duration_native, :native, :millisecond))
  |> Map.put(:success, outcome == "completed")

%{
  tenant_id: Map.get(context, :tenant_id, "system"),
  subject_kind: "mcp_tool",
  policy_key: Map.get(context, :policy_key, inspect(tool_module)),
  reason_code: outcome,
  trace_id: Map.get(context, :trace_id),
  run_id: Map.get(context, :run_id)
}
```

**What to copy**
- Keep MCP execution context map-based, but feed canonical identity into it from the run or normalized edge helper.
- Preserve separate audit, breaker, budget, and telemetry steps.

### `lib/scoria/mcp/router.ex` (middleware, request-response)

**Analog:** `lib/scoria/mcp/router.ex`

**Plug boundary pattern** ([lib/scoria/mcp/router.ex:19](/Users/jon/projects/scoria/lib/scoria/mcp/router.ex:19))
```elixir
def call(conn, opts) do
  conn = assign(conn, :mcp_tools, Keyword.get(opts, :tools, %{}))
  super(conn, opts)
end

post "/" do
  actor = conn.assigns[:current_actor]
  tools = conn.assigns[:mcp_tools]
```

**Validation + error pattern** ([lib/scoria/mcp/router.ex:28](/Users/jon/projects/scoria/lib/scoria/mcp/router.ex:28), [lib/scoria/mcp/router.ex:69](/Users/jon/projects/scoria/lib/scoria/mcp/router.ex:69))
```elixir
case Protocol.parse(conn.body_params) do
  {:ok, request} ->
    case Map.fetch(tools, request.method) do
      {:ok, tool_module} ->
        params = request.params || %{}
        case Validator.validate_args(tool_module, params) do
```

```elixir
defp send_error(conn, id, code, message, data \\ nil) do
  response = Protocol.format_error(id, code, message, data)
  send_json(conn, 200, response)
end
```

**What to copy**
- Keep Plug-specific extraction at this edge only.
- Replace direct `current_actor` pass-through with a helper that converts conn/session assigns into canonical identity.

### `lib/scoria/sre/telemetry_identity.ex` (utility, transform)

**Analog:** `lib/scoria/sre/telemetry_identity.ex`

**Label/ref split** ([lib/scoria/sre/telemetry_identity.ex:6](/Users/jon/projects/scoria/lib/scoria/sre/telemetry_identity.ex:6))
```elixir
@label_keys [
  :tenant_id,
  :subject_kind,
  :policy_key,
  :reason_code,
  :window_bucket,
  :provider,
  :model,
  :tool_name,
  :integration_kind,
  :breaker_key,
  :state,
  :severity
]

@ref_keys [:trace_id, :run_id, :workflow_run_id, :scorer_version, :baseline_version]
```

**Low-cardinality projector pattern** ([lib/scoria/sre/telemetry_identity.ex:40](/Users/jon/projects/scoria/lib/scoria/sre/telemetry_identity.ex:40))
```elixir
def runtime_metadata(attrs) do
  attrs
  |> normalize()
  |> build_metadata(false)
end
```

**What to copy**
- Add canonical identity as source input, not as extra telemetry labels.
- Keep actor and session out of label sets; only project them as refs or evidence if needed.

### `priv/repo/migrations/*_add_identity_to_workflow_runs.exs` (migration, CRUD)

**Analog:** `priv/repo/migrations/20260511000100_create_workflow_tables.exs`

**Migration style** ([priv/repo/migrations/20260511000100_create_workflow_tables.exs:1](/Users/jon/projects/scoria/priv/repo/migrations/20260511000100_create_workflow_tables.exs:1))
```elixir
defmodule Scoria.Repo.Migrations.CreateWorkflowTables do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:ai_workflow_runs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :session_id, :string
      add :root_role_id, :string, null: false
```

```elixir
create_if_not_exists index(:ai_workflow_runs, [:session_id])
create_if_not_exists index(:ai_workflow_runs, [:status])
```

**What to copy**
- Use `alter table(...)` in the same concise style.
- Add first-class columns and explicit indexes for operator filtering.

### `priv/repo/migrations/*_add_identity_to_ai_approvals.exs` (migration, CRUD)

**Analog:** `priv/repo/migrations/20260511000200_link_approvals_to_workflows.exs`

**Alter-table pattern** ([priv/repo/migrations/20260511000200_link_approvals_to_workflows.exs:1](/Users/jon/projects/scoria/priv/repo/migrations/20260511000200_link_approvals_to_workflows.exs:1))
```elixir
defmodule Scoria.Repo.Migrations.LinkApprovalsToWorkflows do
  use Ecto.Migration

  def change do
    alter table(:ai_approvals) do
      add_if_not_exists :workflow_run_id, references(:ai_workflow_runs, on_delete: :delete_all, type: :binary_id)
      add_if_not_exists :step_id, references(:ai_workflow_steps, on_delete: :nilify_all, type: :binary_id)
      add_if_not_exists :checkpoint_id, references(:ai_workflow_checkpoints, on_delete: :nilify_all, type: :binary_id)
      add_if_not_exists :lock_version, :integer, null: false, default: 1
    end
```

```elixir
create_if_not_exists index(:ai_approvals, [:workflow_run_id])
create_if_not_exists index(:ai_approvals, [:step_id])
create_if_not_exists index(:ai_approvals, [:checkpoint_id])
```

**What to copy**
- Extend the existing approvals table incrementally.
- Keep migration operations additive and indexed.

### `test/scoria/identity_test.exs` (test, transform)

**Analog:** `test/scoria/sre/telemetry_test.exs`

**Map normalization assertion style** ([test/scoria/sre/telemetry_test.exs:99](/Users/jon/projects/scoria/test/scoria/sre/telemetry_test.exs:99))
```elixir
attrs = %{
  tenant_id: "tenant-1",
  subject_kind: "mcp_tool",
  policy_key: "tool:refund_customer",
  reason_code: "timeout",
  trace_id: "trace-tool",
  run_id: "run-tool"
}

assert TelemetryIdentity.labels(attrs) == %{...}
assert TelemetryIdentity.refs(attrs) == %{...}
```

**What to copy**
- Use direct map-equality assertions for normalization behavior.
- Assert that non-canonical keys do not leak into the output shape.

### `test/scoria/workflows_test.exs` (test, CRUD)

**Analog:** `test/scoria/workflows_test.exs`

**Sandbox + alias pattern** ([test/scoria/workflows_test.exs:1](/Users/jon/projects/scoria/test/scoria/workflows_test.exs:1))
```elixir
use ExUnit.Case
import Ecto.Query

alias Scoria.Repo
alias Scoria.Workflows
alias Scoria.Workflows.{Checkpoint, Event, Handoff, Run, Step}

setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
  :ok
end
```

**Transactional persistence assertions** ([test/scoria/workflows_test.exs:40](/Users/jon/projects/scoria/test/scoria/workflows_test.exs:40))
```elixir
assert {:ok, run} =
         Workflows.create_run(%{
           root_role_id: "executor",
           session_id: "sess-1",
           metadata: %{"goal" => "ship"}
         })

checkpoints = Repo.all(Ecto.assoc(run, :checkpoints))
events = Repo.all(Ecto.assoc(run, :events))

assert run.status == "running"
assert run.latest_checkpoint_id == hd(checkpoints).id
```

**What to copy**
- Extend this file for run-schema and create-run identity persistence assertions.

### `test/scoria/workflows/runtime_test.exs` (test, request-response)

**Analog:** `test/scoria/workflows/runtime_test.exs`

**Handler-fixture pattern** ([test/scoria/workflows/runtime_test.exs:11](/Users/jon/projects/scoria/test/scoria/workflows/runtime_test.exs:11))
```elixir
defmodule Handlers do
  def wait_for_approval(_step, run) do
    {:waiting_for_approval,
     %{
       tool_name: "approve_publish",
       arguments: %{"target" => "prod"},
       reason: "Requires approval",
       actor_id: "operator-runtime",
       tenant_id: "tenant-runtime",
       trace_id: "trace-#{run.id}"
     }}
  end
end
```

**Budget / side-effect assertions** ([test/scoria/workflows/runtime_test.exs:131](/Users/jon/projects/scoria/test/scoria/workflows/runtime_test.exs:131))
```elixir
assert {:ok, failed_step} =
         Runtime.execute_step(
           step.id,
           handler: {Handlers, :succeed_and_notify, [self()]},
           budget_context: %{
             tenant_id: "tenant-budget-trip",
             actor_id: "actor-1",
             trace_id: "trace-runtime-trip"
           }
         )

refute_receive {:side_effect_ran, ^step_id}
```

**What to copy**
- Add tests proving runtime inherits canonical run identity, while keeping transient execution fields separate.

### `test/scoria/workflows/integration_test.exs` (test, request-response)

**Analog:** `test/scoria/workflows/integration_test.exs`

**Endpoint / router harness** ([test/scoria/workflows/integration_test.exs:1](/Users/jon/projects/scoria/test/scoria/workflows/integration_test.exs:1))
```elixir
defmodule Scoria.WorkflowsIntegrationTest.Router do
  use Phoenix.Router
  import ScoriaWeb.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
  end
```

**Session-backed integration pattern** ([test/scoria/workflows/integration_test.exs:157](/Users/jon/projects/scoria/test/scoria/workflows/integration_test.exs:157))
```elixir
conn =
  build_conn()
  |> Plug.Test.init_test_session(%{
    "actor_id" => "operator-integration",
    "tenant_id" => "tenant-integration"
  })
  |> Plug.Conn.put_private(:phoenix_endpoint, Scoria.WorkflowsIntegrationTest.Endpoint)
```

**What to copy**
- Use this file for end-to-end proof that Plug/LiveView/session adapters normalize into the same durable identity.

### `test/scoria/sre/audit_outbox_test.exs` (test, event-driven)

**Analog:** `test/scoria/sre/audit_outbox_test.exs`

**Audit durability assertions** ([test/scoria/sre/audit_outbox_test.exs:18](/Users/jon/projects/scoria/test/scoria/sre/audit_outbox_test.exs:18))
```elixir
assert {:ok, approval} =
         Workflows.mark_waiting_for_approval(run.id, step.id, %{
           tool_name: "dangerous_tool",
           arguments: %{"token" => "top-secret", "target" => "prod"},
           reason: "Need operator approval",
           actor_id: "operator-1",
           trace_id: "trace-approval-request",
           tenant_id: "tenant-approval"
         })

audit_event =
  Repo.get_by!(AuditOutboxEvent, workflow_run_id: run.id, event_type: "approval.requested")
```

**Rollback pattern** ([test/scoria/sre/audit_outbox_test.exs:54](/Users/jon/projects/scoria/test/scoria/sre/audit_outbox_test.exs:54))
```elixir
assert {:error, changeset} =
         Workflows.mark_waiting_for_approval(run.id, step.id, %{..., dedupe_key: duplicate_key})

assert Workflows.get_run!(run.id).status == "running"
assert Workflows.get_step!(step.id).status == "running"
assert Repo.aggregate(from(a in Approval, where: a.workflow_run_id == ^run.id), :count) == 0
```

**What to copy**
- Extend these tests to assert approval-request and approval-decision rows use canonical actor, tenant, and session lineage.

### `test/scoria/mcp/executor_telemetry_test.exs` (test, request-response)

**Analog:** `test/scoria/mcp/executor_telemetry_test.exs`

**Telemetry capture harness** ([test/scoria/mcp/executor_telemetry_test.exs:33](/Users/jon/projects/scoria/test/scoria/mcp/executor_telemetry_test.exs:33))
```elixir
events = [
  [:scoria, :sre, :runtime, :latency],
  [:scoria, :sre, :runtime, :cost],
  [:scoria, :sre, :runtime, :budget_burn],
  [:scoria, :sre, :runtime, :tool_reliability],
  [:scoria, :sre, :runtime, :breaker_state]
]
```

**Canonical metadata assertion style** ([test/scoria/mcp/executor_telemetry_test.exs:67](/Users/jon/projects/scoria/test/scoria/mcp/executor_telemetry_test.exs:67))
```elixir
assert {:ok, %{result: "success"}} =
         Executor.execute(DummyTool, %{"action" => "success"}, %{
           tenant_id: "tenant-mcp",
           trace_id: "trace-mcp",
           run_id: run_id,
           estimated_units: 5,
           integration_kind: "remote_mcp",
           tool_name: "dummy_tool",
           provider: "openai",
           model: "gpt-5"
         })

assert metadata.run_id == run_id
```

**What to copy**
- Extend this file to prove telemetry sources tenant/run refs from canonical identity while staying low-cardinality.

## Shared Patterns

### Durable Transaction Boundary
**Source:** [lib/scoria/workflows.ex:79](/Users/jon/projects/scoria/lib/scoria/workflows.ex:79), [lib/scoria/workflows.ex:276](/Users/jon/projects/scoria/lib/scoria/workflows.ex:276)
**Apply to:** `lib/scoria/workflows.ex` root identity stamping and approval propagation
```elixir
Multi.new()
|> Multi.insert(...)
|> Multi.run(:checkpoint, fn repo, changes -> ... end)
|> Multi.run(:event, fn repo, changes -> ... end)
|> Repo.transaction()
```

### Schema + Changeset Style
**Source:** [lib/scoria/workflows/run.ex:1](/Users/jon/projects/scoria/lib/scoria/workflows/run.ex:1), [lib/scoria/observe/approval.ex:1](/Users/jon/projects/scoria/lib/scoria/observe/approval.ex:1)
**Apply to:** `Run`, `Approval`, and any new identity-backed Ecto row changes
```elixir
use Ecto.Schema
import Ecto.Changeset

@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id
...
|> cast(attrs, [...])
|> validate_required([...])
|> optimistic_lock(:lock_version)
```

### Audit Outbox Attribution
**Source:** [lib/scoria/workflows.ex:329](/Users/jon/projects/scoria/lib/scoria/workflows.ex:329), [lib/scoria/mcp/executor.ex:162](/Users/jon/projects/scoria/lib/scoria/mcp/executor.ex:162)
**Apply to:** approval request/decision, MCP access, policy-sensitive tool invocation
```elixir
SRE.insert_audit_outbox_event(repo, %{
  tenant_id: ...,
  actor_ref: ...,
  workflow_run_id: ...,
  step_id: ...,
  trace_id: ...
})
```

### Telemetry Identity Projection
**Source:** [lib/scoria/sre/telemetry_identity.ex:23](/Users/jon/projects/scoria/lib/scoria/sre/telemetry_identity.ex:23), [lib/scoria/sre/telemetry.ex:11](/Users/jon/projects/scoria/lib/scoria/sre/telemetry.ex:11)
**Apply to:** runtime telemetry, MCP telemetry, identity helper tests
```elixir
TelemetryIdentity.runtime_metadata(attrs)
TelemetryIdentity.labels(attrs)
TelemetryIdentity.refs(attrs)
```

### Edge Adapter Pattern
**Source:** [lib/scoria/mcp/router.ex:24](/Users/jon/projects/scoria/lib/scoria/mcp/router.ex:24), [lib/scoria_web/live/orchestrator_live.ex:22](/Users/jon/projects/scoria/lib/scoria_web/live/orchestrator_live.ex:22)
**Apply to:** Plug/LiveView/session-facing identity helpers
```elixir
actor = conn.assigns[:current_actor]
tenant_id = session["tenant_id"] || "default"
session["actor_id"] || session["user_id"] || session["session_id"] || "operator"
```

Use these only as input extraction examples. Do not preserve their fallback chains as durable runtime truth.

### ExUnit DB Harness
**Source:** [test/scoria/workflows_test.exs:1](/Users/jon/projects/scoria/test/scoria/workflows_test.exs:1), [test/scoria/workflows/integration_test.exs:69](/Users/jon/projects/scoria/test/scoria/workflows/integration_test.exs:69)
**Apply to:** all new identity-related DB and integration tests
```elixir
:ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
```

## No Analog Found

None. Every likely Phase 12 file has at least a usable role-match analog in the current codebase.

## Metadata

**Analog search scope:** `lib/`, `test/`, `priv/repo/migrations/`
**Files scanned:** 21
**Pattern extraction date:** 2026-05-13

## PATTERN MAPPING COMPLETE

**Phase:** 12 - Canonical Runtime Identity
**Files classified:** 17
**Analogs found:** 17 / 17

### Coverage
- Files with exact analog: 10
- Files with role-match analog: 6
- Files with partial analog: 1
- Files with no analog: 0

### Key Patterns Identified
- Workflow truth changes are grouped in `Ecto.Multi` or `Repo.transaction` blocks with checkpoint/event writes in the same durable boundary.
- Identity-related schemas use flat Ecto fields plus lightweight changesets with optimistic locking.
- Audit and telemetry seams already centralize attribution; Phase 12 should change their identity source, not invent new projection mechanisms.

### File Created
`/Users/jon/projects/scoria/.planning/phases/12-canonical-runtime-identity/12-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Planner can now reference analog patterns in plan actions.
