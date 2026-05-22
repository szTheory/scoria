# Phase 38: Replay-Safe Execution & Tool Modes - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 20
**Analogs found:** 20 / 20

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `priv/repo/migrations/*_add_replay_safe_execution_truth.exs` | migration | transform | `priv/repo/migrations/20260518000100_enrich_remote_approval_truth.exs` | exact |
| `lib/scoria/workflows/run.ex` | model | CRUD | `lib/scoria/workflows/run.ex` | exact |
| `lib/scoria/observe/approval.ex` | model | CRUD | `lib/scoria/observe/approval.ex` | exact |
| `lib/scoria/workflows/checkpoint.ex` | model | CRUD | `lib/scoria/workflows/checkpoint.ex` | exact |
| `lib/scoria/workflows/event.ex` | model | event-driven | `lib/scoria/workflows/event.ex` | exact |
| `lib/scoria/sre/audit_outbox_event.ex` | model | event-driven | `lib/scoria/sre/audit_outbox_event.ex` | exact |
| `lib/scoria/workflows/replay_disposition.ex` | utility | request-response | `lib/scoria/connectors/invocation.ex` | data-flow-match |
| `lib/scoria/workflows.ex` | service | CRUD | `lib/scoria/workflows.ex` | exact |
| `lib/scoria/workflows/runtime.ex` | service | request-response | `lib/scoria/workflows/runtime.ex` | exact |
| `lib/scoria/connectors/invocation.ex` | service | request-response | `lib/scoria/connectors/invocation.ex` | exact |
| `lib/scoria/mcp/executor.ex` | service | request-response | `lib/scoria/mcp/executor.ex` | exact |
| `lib/scoria/workflows/remote_approval_projection.ex` | service | CRUD | `lib/scoria/workflows/remote_approval_projection.ex` | exact |
| `lib/scoria/runtime/run_summary.ex` | model | transform | `lib/scoria/runtime/run_summary.ex` | exact |
| `lib/scoria/runtime/run_detail.ex` | model | transform | `lib/scoria/runtime/run_detail.ex` | exact |
| `test/scoria/workflows/replay_branch_test.exs` | test | request-response | `test/scoria/workflows/replay_branch_test.exs` | exact |
| `test/scoria/workflows_test.exs` | test | CRUD | `test/scoria/workflows_test.exs` | exact |
| `test/scoria/connectors/invocation_test.exs` | test | request-response | `test/scoria/connectors/invocation_test.exs` | exact |
| `test/scoria/workflows/integration_test.exs` | test | event-driven | `test/scoria/workflows/integration_test.exs` | exact |
| `test/scoria/runtime_view_test.exs` | test | transform | `test/scoria/runtime_view_test.exs` | exact |
| `test/scoria/workflows/replay_disposition_test.exs` | test | request-response | `test/scoria/connectors/invocation_test.exs` | role-match |

## Pattern Assignments

### `priv/repo/migrations/*_add_replay_safe_execution_truth.exs` (migration, transform)

**Analog:** `priv/repo/migrations/20260518000100_enrich_remote_approval_truth.exs`

**Migration structure** ([priv/repo/migrations/20260518000100_enrich_remote_approval_truth.exs](/Users/jon/projects/scoria/priv/repo/migrations/20260518000100_enrich_remote_approval_truth.exs:4), lines 4-49):
```elixir
def change do
  alter table(:ai_approvals) do
    add_if_not_exists(:blocker_kind, :string)
    add_if_not_exists(:replay_allowed, :boolean, default: false, null: false)
  end

  create_if_not_exists(index(:ai_approvals, [:status, :inserted_at]))
  create_if_not_exists(index(:ai_approvals, [:workflow_run_id, :status]))
end
```

**Secondary analog for reversible `up/down` style** ([priv/repo/migrations/20260523000100_add_replay_lineage_to_workflow_runs.exs](/Users/jon/projects/scoria/priv/repo/migrations/20260523000100_add_replay_lineage_to_workflow_runs.exs:4), lines 4-29):
```elixir
def up do
  alter table(:ai_workflow_runs) do
    add_if_not_exists(:source_run_id, :binary_id)
    add_if_not_exists(:execution_mode, :string)
    add_if_not_exists(:replay_overrides, :map, default: %{}, null: false)
  end

  create_if_not_exists(index(:ai_workflow_runs, [:execution_mode]))
end
```

Use `add_if_not_exists` and `create_if_not_exists` consistently. If Phase 38 needs enum cleanup plus backfill logic, prefer `up/down` over bare `change`.

---

### `lib/scoria/workflows/run.ex` (model, CRUD)

**Analog:** `lib/scoria/workflows/run.ex`

**Schema + bounded enum pattern** ([lib/scoria/workflows/run.ex](/Users/jon/projects/scoria/lib/scoria/workflows/run.ex:5), lines 5-23):
```elixir
@statuses ~w(running waiting_for_approval paused retrying failed completed cancelled)
@execution_modes ~w(live replay historical_stubbed)

schema "ai_workflow_runs" do
  field(:source_run_id, :binary_id)
  field(:source_checkpoint_id, :binary_id)
  field(:execution_mode, :string, default: "live")
  field(:replay_overrides, :map, default: %{})
  field(:lock_version, :integer, default: 1)
end
```

**Changeset pattern** ([lib/scoria/workflows/run.ex](/Users/jon/projects/scoria/lib/scoria/workflows/run.ex:38), lines 38-63):
```elixir
def changeset(run, attrs) do
  run
  |> cast(attrs, [:source_run_id, :source_checkpoint_id, :execution_mode, :replay_overrides])
  |> validate_required([:root_role_id, :status])
  |> validate_inclusion(:status, @statuses)
  |> validate_inclusion(:execution_mode, @execution_modes)
  |> optimistic_lock(:lock_version)
end
```

Phase 38 should follow this exact shape when replacing the transitional run-wide enum with run-intent-only values.

---

### `lib/scoria/observe/approval.ex` (model, CRUD)

**Analog:** `lib/scoria/observe/approval.ex`

**Approval evidence field pattern** ([lib/scoria/observe/approval.ex](/Users/jon/projects/scoria/lib/scoria/observe/approval.ex:9), lines 9-35):
```elixir
schema "ai_approvals" do
  field(:tool_name, :string)
  field(:arguments, :map, default: %{})
  field(:status, :string, default: "pending")
  field(:blocker_kind, :string)
  field(:grant_status, :string)
  field(:grant_subject_ref, :string)
  field(:policy_outcome, :string)
  field(:missing_scopes, {:array, :string}, default: [])
  field(:requested_scopes, {:array, :string}, default: [])
  field(:replay_allowed, :boolean, default: false)
  field(:blocker_workflow_event_id, :binary_id)
  field(:blocker_audit_outbox_event_id, :binary_id)
  field(:audit_outbox_event_id, :binary_id)
end
```

**Changeset pattern** ([lib/scoria/observe/approval.ex](/Users/jon/projects/scoria/lib/scoria/observe/approval.ex:40), lines 40-72):
```elixir
def changeset(approval, attrs) do
  approval
  |> cast(attrs, [:tool_name, :arguments, :status, :blocker_kind, :grant_status,
                  :grant_subject_ref, :policy_outcome, :missing_scopes, :requested_scopes,
                  :replay_allowed, :blocker_workflow_event_id, :blocker_audit_outbox_event_id,
                  :audit_outbox_event_id, :workflow_run_id, :step_id, :checkpoint_id, :lock_version])
  |> validate_required([:tool_name, :status])
  |> validate_inclusion(:status, @statuses)
  |> optimistic_lock(:lock_version)
end
```

Add replay-specific scope/disposition/source fields here, not in opaque metadata.

---

### `lib/scoria/workflows/checkpoint.ex` and `lib/scoria/workflows/event.ex` (model, CRUD/event-driven)

**Analogs:** `lib/scoria/workflows/checkpoint.ex`, `lib/scoria/workflows/event.ex`

**Checkpoint schema pattern** ([lib/scoria/workflows/checkpoint.ex](/Users/jon/projects/scoria/lib/scoria/workflows/checkpoint.ex:7), lines 7-36):
```elixir
schema "ai_workflow_checkpoints" do
  field(:sequence, :integer)
  field(:transition, :string)
  field(:status, :string)
  field(:snapshot, :map, default: %{})
  field(:cursor, :map)
  field(:metadata, :map, default: %{})
end
```

**Event schema pattern** ([lib/scoria/workflows/event.ex](/Users/jon/projects/scoria/lib/scoria/workflows/event.ex:7), lines 7-25):
```elixir
schema "ai_workflow_events" do
  field(:sequence, :integer)
  field(:event_type, :string)
  field(:payload, :map, default: %{})
  field(:compacted_at, :utc_datetime_usec)
end
```

Phase 38 should extend the durable checkpoint/event payload surfaces directly, since existing patterns already treat `snapshot`, `metadata`, and `payload` as persisted evidence containers.

---

### `lib/scoria/sre/audit_outbox_event.ex` (model, event-driven)

**Analog:** `lib/scoria/sre/audit_outbox_event.ex`

**Audit row pattern** ([lib/scoria/sre/audit_outbox_event.ex](/Users/jon/projects/scoria/lib/scoria/sre/audit_outbox_event.ex:9), lines 9-24):
```elixir
schema "ai_audit_outbox_events" do
  field(:tenant_id, :string)
  field(:event_type, :string)
  field(:policy_class, :string)
  field(:dedupe_key, :string)
  field(:payload_hash, :string)
  field(:workflow_run_id, :binary_id)
  field(:step_id, :binary_id)
  field(:trace_id, :string)
  field(:redacted_refs, :map, default: %{})
  field(:metadata, :map, default: %{})
end
```

**Validation + dedupe pattern** ([lib/scoria/sre/audit_outbox_event.ex](/Users/jon/projects/scoria/lib/scoria/sre/audit_outbox_event.ex:29), lines 29-66):
```elixir
def changeset(audit_event, attrs) do
  audit_event
  |> cast(attrs, [:tenant_id, :event_type, :policy_class, :dedupe_key, :payload_hash,
                  :workflow_run_id, :step_id, :trace_id, :redacted_refs, :metadata])
  |> validate_required([:tenant_id, :event_type, :policy_class, :sink_status,
                        :dedupe_key, :payload_hash, :pending_at, :attempt_count])
  |> unique_constraint(:dedupe_key, name: :ai_audit_outbox_events_tenant_id_dedupe_key_index)
end
```

Use this for replay-live idempotency and durable `replay_disposition` evidence.

---

### `lib/scoria/workflows/replay_disposition.ex` (utility, request-response)

**Analog:** `lib/scoria/connectors/invocation.ex`

**Gate-before-execute pattern** ([lib/scoria/connectors/invocation.ex](/Users/jon/projects/scoria/lib/scoria/connectors/invocation.ex:14), lines 14-35):
```elixir
def invoke(tool_module, local_tool_or_id, args, context, timeout \\ 5000) do
  local_tool = load_local_tool!(local_tool_or_id)
  context = Map.new(context || %{})

  with :ok <- ensure_tool_available(local_tool),
       :ok <- ensure_policy_allows(local_tool, context),
       {:ok, grant} <- ensure_grant(local_tool, context, args),
       :ok <- ensure_remote_approval(local_tool, grant, context, args) do
    Executor.execute(tool_module, args, execution_context, timeout)
  else
    {:error, envelope} -> {:error, envelope}
  end
end
```

**Blocked envelope pattern** ([lib/scoria/connectors/invocation.ex](/Users/jon/projects/scoria/lib/scoria/connectors/invocation.ex:115), lines 115-155):
```elixir
{:error,
 %{
   status: :scope_escalation_required,
   reason_code: "scope_escalation_required",
   connector_id: connector.id,
   local_tool_id: local_tool.id,
   missing_scopes: missing_scopes,
   approval_id: evidence.approval && evidence.approval.id,
   audit_outbox_event_id: evidence.audit_outbox_event.id,
   workflow_event_id: evidence.workflow_event_id
 }}
```

Build the new resolver to return a typed decision plus evidence payload in this style: explicit branch result, no implicit fallback.

---

### `lib/scoria/workflows.ex` (service, CRUD)

**Analog:** `lib/scoria/workflows.ex`

**Replay branch transaction pattern** ([lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:150), lines 150-219):
```elixir
def create_replay_branch(source_run_id, source_checkpoint_id, attrs \\ %{}) do
  Repo.transaction(fn repo ->
    source_run = repo.get!(Run, source_run_id)
    source_checkpoint = repo.get!(Checkpoint, source_checkpoint_id)

    if source_checkpoint.run_id != source_run.id do
      Repo.rollback(:checkpoint_run_mismatch)
    end

    branch_run =
      %Run{}
      |> Run.changeset(%{
        source_run_id: source_run.id,
        source_checkpoint_id: source_checkpoint.id,
        execution_mode: execution_mode,
        replay_overrides: replay_overrides
      })
      |> repo.insert!()
  end)
end
```

**Approval transaction + evidence fanout pattern** ([lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:387), lines 387-473):
```elixir
def mark_waiting_for_approval(run_id, step_id, attrs) do
  Repo.transaction(fn repo ->
    updated_run =
      repo.update!(Run.changeset(run, %{status: "waiting_for_approval", current_step_id: step.id}))

    checkpoint = insert_checkpoint(repo, run.id, step.id, %{transition: "waiting_for_approval"})
    insert_event(repo, run.id, step.id, %{event_type: "waiting_for_approval"})

    approval =
      %Approval{}
      |> Approval.changeset(approval_attrs)
      |> repo.insert!()

    audit_outbox_event = SRE.insert_audit_outbox_event(repo, %{event_type: "approval.requested"})

    approval
    |> Approval.changeset(%{audit_outbox_event_id: audit_outbox_event.id})
    |> repo.update!()
  end)
end
```

**Remote approval default pattern to replace** ([lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:489), lines 489-495):
```elixir
def request_remote_approval(run_id, step_id, attrs) do
  attrs =
    attrs
    |> Map.new()
    |> Map.put_new(:replay_allowed, true)

  mark_waiting_for_approval(run_id, step_id, attrs)
end
```

**Approval resolution audit pattern** ([lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:681), lines 681-731):
```elixir
def approve(approval_id, status, attrs) when status in ["approved", "rejected", "expired"] do
  Repo.transaction(fn repo ->
    updated_approval =
      approval
      |> Approval.changeset(update_attrs)
      |> repo.update!()

    audit_outbox_event =
      SRE.insert_audit_outbox_event(repo, %{
        event_type: "approval.#{status}",
        policy_class: "approval",
        approval_id: updated_approval.id
      })
  end)
end
```

This is the strongest analog for Phase 38 writes: one transaction updates run/step/checkpoint/event/approval/audit truth together.

---

### `lib/scoria/workflows/runtime.ex` (service, request-response)

**Analog:** `lib/scoria/workflows/runtime.ex`

**Outcome dispatch pattern** ([lib/scoria/workflows/runtime.ex](/Users/jon/projects/scoria/lib/scoria/workflows/runtime.ex:15), lines 15-55):
```elixir
def execute_step(step_id, opts \\ []) do
  with {:ok, _claimed} <- Workflows.claim_step(step_id) do
    case BreakerRegistry.run(breaker_context, fn ->
           execute_handler(handler, step, run, timeout)
         end) do
      {:ok, {:completed, result, duration_ms}} ->
        Workflows.complete_step(step.id, attach_budget_evidence(normalize_payload(result), reservation_context))

      {:ok, {:waiting_for_approval, approval_attrs, duration_ms}} ->
        Workflows.mark_waiting_for_approval(run.id, step.id, Map.new(approval_attrs))
    end
  end
end
```

Use this shape to insert replay resolution before effectful branches, while keeping the existing runtime seam intact.

---

### `lib/scoria/connectors/invocation.ex` (service, request-response)

**Analog:** `lib/scoria/connectors/invocation.ex`

**Local policy + grant gate** ([lib/scoria/connectors/invocation.ex](/Users/jon/projects/scoria/lib/scoria/connectors/invocation.ex:50), lines 50-112):
```elixir
defp ensure_policy_allows(local_tool, context) do
  denied_ids = MapSet.new(List.wrap(Map.get(context, :denied_local_tool_ids, [])))
  allowed_ids = List.wrap(Map.get(context, :allowed_local_tool_ids, []))
  policy_allow = Map.get(context, :policy_allow, true)

  cond do
    not policy_allow -> {:error, %{status: :policy_denied, ...}}
    true -> :ok
  end
end
```

**Approval-sensitive block pattern** ([lib/scoria/connectors/invocation.ex](/Users/jon/projects/scoria/lib/scoria/connectors/invocation.ex:158), lines 158-199):
```elixir
defp ensure_remote_approval(local_tool, grant, context, args) do
  if requires_remote_approval?(local_tool) and not approved_remote_action?(local_tool, context) do
    blocked_remote_execution(local_tool, grant, context, args)
  else
    :ok
  end
end

defp blocked_remote_execution(local_tool, grant, context, args) do
  {:ok, approval} =
    Scoria.Workflows.request_remote_approval(run_id, step_id, %{
      blocker_kind: blocker_kind,
      grant_status: grant.status,
      grant_subject_ref: grant.subject_ref,
      requested_scopes: local_tool.required_scopes || [],
      replay_allowed: true
    })
end
```

Phase 38 should reuse this seam and replace `replay_allowed: true` with explicit replay disposition and replay-scoped authority.

---

### `lib/scoria/mcp/executor.ex` (service, request-response)

**Analog:** `lib/scoria/mcp/executor.ex`

**Seam wrapper pattern** ([lib/scoria/mcp/executor.ex](/Users/jon/projects/scoria/lib/scoria/mcp/executor.ex:15), lines 15-30):
```elixir
def execute(tool_module, args, context, timeout \\ 5000) do
  context = canonical_context(context || %{})

  with {:ok, access_context} <- maybe_capture_sensitive_mcp_access(tool_module, args, context),
       {:ok, reservation_context} <- reserve_budget(tool_module, args, access_context),
       {:ok, execution_context} <-
         ensure_policy_sensitive_invocation(tool_module, args, access_context, reservation_context) do
    metadata =
      access_context
      |> Map.merge(%{tool: tool_module, args: args})
      |> attach_budget_metadata(execution_context)
  end
end
```

**Audit creation pattern** ([lib/scoria/mcp/executor.ex](/Users/jon/projects/scoria/lib/scoria/mcp/executor.ex:204), lines 204-255):
```elixir
with {:ok, audit_outbox_event} <-
       SRE.create_audit_outbox_event(%{
         workflow_run_id: Map.get(context, :run_id),
         step_id: Map.get(context, :step_id),
         trace_id: Map.get(context, :trace_id),
         event_type: "mcp.access.#{decision}",
         policy_class: "sensitive_mcp_access",
         metadata: %{"integration_kind" => Map.get(context, :integration_kind, "remote_mcp")}
       }) do
  case decision do
    "denied" -> {:error, %{status: :access_denied, audit_outbox_event_id: audit_outbox_event.id}}
    _ -> {:ok, context}
  end
end
```

This is the best analog for replay-safe MCP handling: resolve, persist audit truth, then either block or continue.

---

### `lib/scoria/workflows/remote_approval_projection.ex` (service, CRUD)

**Analog:** `lib/scoria/workflows/remote_approval_projection.ex`

**Projection read model pattern** ([lib/scoria/workflows/remote_approval_projection.ex](/Users/jon/projects/scoria/lib/scoria/workflows/remote_approval_projection.ex:27), lines 27-75):
```elixir
def get_approval_lineage!(approval_id) do
  approval = Approval |> Repo.get!(approval_id)
  blocker_event = approval.blocker_workflow_event_id && Repo.get(Event, approval.blocker_workflow_event_id)
  request_audit = approval.audit_outbox_event_id && Repo.get(AuditOutboxEvent, approval.audit_outbox_event_id)

  %{
    approval_id: approval.id,
    blocker_kind: approval.blocker_kind,
    requested_scopes: approval.requested_scopes || [],
    replay_allowed: approval.replay_allowed,
    blocker_workflow_event_id: approval.blocker_workflow_event_id,
    audit_outbox_event_id: approval.audit_outbox_event_id,
    blocker_event_payload: blocker_event && blocker_event.payload
  }
end
```

Extend this projection with replay disposition/source lineage instead of leaving operator surfaces to infer from raw metadata.

---

### `lib/scoria/runtime/run_summary.ex` and `lib/scoria/runtime/run_detail.ex` (model, transform)

**Analogs:** `lib/scoria/runtime/run_summary.ex`, `lib/scoria/runtime/run_detail.ex`

**Run summary projection pattern** ([lib/scoria/runtime/run_summary.ex](/Users/jon/projects/scoria/lib/scoria/runtime/run_summary.ex:61), lines 61-78):
```elixir
def from_run(%Run{} = run) do
  %__MODULE__{
    run_id: run.id,
    source_run_id: run.source_run_id,
    source_checkpoint_id: run.source_checkpoint_id,
    execution_mode: run.execution_mode || "live",
    awaiting_approval: run.status == "waiting_for_approval"
  }
end
```

**Curated detail block pattern** ([lib/scoria/runtime/run_detail.ex](/Users/jon/projects/scoria/lib/scoria/runtime/run_detail.ex:30), lines 30-39 and 100-109):
```elixir
def from_run_tree(%Run{} = run) do
  %__MODULE__{
    summary: RunSummary.from_run(run),
    checkpoints: Enum.map(run.checkpoints, &checkpoint_item/1),
    events: Enum.map(run.events, &event_item/1),
    approvals: Enum.map(run.approvals, &approval_item/1),
    replay_lineage: replay_lineage_item(run)
  }
end

defp replay_lineage_item(%Run{} = run) do
  %{source_run_id: run.source_run_id, source_checkpoint_id: run.source_checkpoint_id,
    execution_mode: execution_mode, replay_overrides: run.replay_overrides || %{}}
end
```

Phase 38 should follow this “curated DTO block” approach for seam-level replay facts.

---

### Test files

#### `test/scoria/workflows/replay_branch_test.exs`

**Analog:** `test/scoria/workflows/replay_branch_test.exs`

**Replay lineage assertions** ([test/scoria/workflows/replay_branch_test.exs](/Users/jon/projects/scoria/test/scoria/workflows/replay_branch_test.exs:45), lines 45-76):
```elixir
assert {:ok, branch_run} =
         Workflows.create_replay_branch(source_run.id, source_checkpoint.id, %{
           replay_overrides: %{"reason" => "operator replay"},
           execution_mode: "replay"
         })

assert branch_run.source_run_id == source_run.id
assert branch_run.source_checkpoint_id == source_checkpoint.id
assert branch_run.execution_mode == "replay"
assert replay_checkpoint.transition == "replay_started"
assert replay_event.event_type == "replay_started"
```

Use this pattern for new replay-safe execution assertions.

#### `test/scoria/workflows_test.exs`

**Analog:** `test/scoria/workflows_test.exs`

**Approval persistence assertions** ([test/scoria/workflows_test.exs](/Users/jon/projects/scoria/test/scoria/workflows_test.exs:134), lines 134-159):
```elixir
assert {:ok, approval} =
         Workflows.mark_waiting_for_approval(run.id, step.id, %{tool_name: "dangerous_tool"})

assert updated_run.status == "waiting_for_approval"
assert updated_step.status == "waiting_for_approval"
assert approval.workflow_run_id == run.id
assert approval.step_id == step.id
```

**Remote approval lineage assertions** ([test/scoria/workflows_test.exs](/Users/jon/projects/scoria/test/scoria/workflows_test.exs:211), lines 211-247):
```elixir
assert {:ok, approval} =
         Workflows.request_remote_approval(run.id, step.id, %{blocker_kind: "remote_write", replay_allowed: true})

assert approval.blocker_kind == "remote_write"
assert approval.audit_outbox_event_id
lineage = Workflows.get_remote_approval_lineage!(approval.id)
assert lineage.blocker_kind == "remote_write"
```

Replace these assertions with replay disposition / replay scope assertions once fields exist.

#### `test/scoria/connectors/invocation_test.exs`

**Analog:** `test/scoria/connectors/invocation_test.exs`

**Blocked-before-outbound pattern** ([test/scoria/connectors/invocation_test.exs](/Users/jon/projects/scoria/test/scoria/connectors/invocation_test.exs:88), lines 88-117):
```elixir
assert {:error, envelope} = Invocation.invoke(RemoteTool, local_tool.id, %{"token" => "secret"}, %{run_id: run.id, step_id: step.id})
assert envelope.status == :auth_required
assert envelope.approval_id
refute_receive {:tool_executed, _, _}
```

**High-risk write gate pattern** ([test/scoria/connectors/invocation_test.exs](/Users/jon/projects/scoria/test/scoria/connectors/invocation_test.exs:192), lines 192-217):
```elixir
assert {:error, envelope} = Invocation.invoke(RemoteTool, local_tool.id, %{"title" => "Rotate secret"}, %{run_id: run.id, step_id: step.id})
assert envelope.status == :waiting_for_approval
assert approval.blocker_kind == "remote_write"
assert Workflows.get_run!(run.id).status == "waiting_for_approval"
```

These are the best test analogs for `historical_stub` vs `blocked` vs `execute_live`.

#### `test/scoria/workflows/integration_test.exs`

**Analog:** `test/scoria/workflows/integration_test.exs`

Use the existing integration pattern that proves persisted side-effect boundaries are not replayed implicitly. Keep tests end-to-end through `Runtime.execute_step/2`, `Workflows.approve/3`, and resume/retry flows.

#### `test/scoria/runtime_view_test.exs`

**Analog:** `test/scoria/runtime_view_test.exs`

**Curated DTO assertion pattern** ([test/scoria/runtime_view_test.exs](/Users/jon/projects/scoria/test/scoria/runtime_view_test.exs:111), lines 111-125):
```elixir
assert {:ok, %RunSummary{} = summary} = Runtime.get_run(replay_run.id)
assert {:ok, %RunDetail{} = detail} = Runtime.get_run_detail(replay_run.id)

assert summary.execution_mode == "replay"
assert detail.replay_lineage.source_run_id == source_run.id
assert detail.replay_lineage.replay_overrides == %{"reason" => "operator replay"}
```

Add replay disposition/operator evidence assertions here rather than in LiveView-only tests first.

## Shared Patterns

### Transactional durable truth
**Source:** [lib/scoria/workflows.ex](/Users/jon/projects/scoria/lib/scoria/workflows.ex:391)
**Apply to:** `Workflows`, approval writes, replay evidence fanout
```elixir
Repo.transaction(fn repo ->
  checkpoint = insert_checkpoint(repo, run.id, step.id, %{transition: "waiting_for_approval"})
  insert_event(repo, run.id, step.id, %{event_type: "waiting_for_approval"})
  approval = %Approval{} |> Approval.changeset(approval_attrs) |> repo.insert!()
  audit_outbox_event = SRE.insert_audit_outbox_event(repo, %{event_type: "approval.requested"})
  approval |> Approval.changeset(%{audit_outbox_event_id: audit_outbox_event.id}) |> repo.update!()
end)
```

### Fail-closed seam gating
**Source:** [lib/scoria/connectors/invocation.ex](/Users/jon/projects/scoria/lib/scoria/connectors/invocation.ex:18)
**Apply to:** replay disposition resolver, connector/MCP seams
```elixir
with :ok <- ensure_tool_available(local_tool),
     :ok <- ensure_policy_allows(local_tool, context),
     {:ok, grant} <- ensure_grant(local_tool, context, args),
     :ok <- ensure_remote_approval(local_tool, grant, context, args) do
  Executor.execute(tool_module, args, execution_context, timeout)
else
  {:error, envelope} -> {:error, envelope}
end
```

### Audit-first evidence for sensitive seams
**Source:** [lib/scoria/mcp/executor.ex](/Users/jon/projects/scoria/lib/scoria/mcp/executor.ex:209)
**Apply to:** replay-live execution, blocked replay, historical stub evidence
```elixir
with {:ok, audit_outbox_event} <-
       SRE.create_audit_outbox_event(%{
         workflow_run_id: Map.get(context, :run_id),
         step_id: Map.get(context, :step_id),
         trace_id: Map.get(context, :trace_id),
         event_type: "mcp.access.#{decision}",
         policy_class: "sensitive_mcp_access"
       }) do
  ...
end
```

### Curated projection blocks, not raw metadata inference
**Source:** [lib/scoria/runtime/run_detail.ex](/Users/jon/projects/scoria/lib/scoria/runtime/run_detail.ex:30)
**Apply to:** `RunSummary`, `RunDetail`, remote approval projection
```elixir
%__MODULE__{
  summary: RunSummary.from_run(run),
  checkpoints: Enum.map(run.checkpoints, &checkpoint_item/1),
  events: Enum.map(run.events, &event_item/1),
  approvals: Enum.map(run.approvals, &approval_item/1),
  replay_lineage: replay_lineage_item(run)
}
```

### Optimistic locking on durable authority rows
**Source:** [lib/scoria/workflows/run.ex](/Users/jon/projects/scoria/lib/scoria/workflows/run.ex:62), [lib/scoria/observe/approval.ex](/Users/jon/projects/scoria/lib/scoria/observe/approval.ex:72)
**Apply to:** run intent rows, replay approval authority rows
```elixir
|> optimistic_lock(:lock_version)
```

## No Analog Found

None. The codebase already has strong analogs for migrations, durable evidence rows, seam gating, DTO projection, and test posture. The only new concept is the shared replay-disposition resolver module, but its control flow should copy the existing connector invocation gate and MCP audit patterns.

## Metadata

**Analog search scope:** `lib/scoria/workflows`, `lib/scoria/connectors`, `lib/scoria/mcp`, `lib/scoria/runtime`, `lib/scoria/sre`, `priv/repo/migrations`, `test/scoria`
**Files scanned:** 20
**Pattern extraction date:** 2026-05-23
