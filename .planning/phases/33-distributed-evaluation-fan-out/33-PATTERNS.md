# Phase 33: Distributed Evaluation Fan-out - Pattern Map

**Mapped:** 2026-05-21
**Files analyzed:** 8 proposed files
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scoria/eval/eval_campaign.ex` | model | CRUD | `lib/scoria/connectors/capability_snapshot.ex` | role-match |
| `lib/scoria/eval/eval_campaign_target.ex` | model | CRUD | `lib/scoria/eval/score.ex` | role-match |
| `lib/scoria/eval/campaign_worker.ex` | service | request-response | `lib/scoria/compaction/summarize_worker.ex` | role+flow |
| `lib/scoria/eval/campaign_enqueuer.ex` | service | batch | `lib/scoria/workflows/batch_enqueue.ex` | exact-flow |
| `lib/scoria/eval.ex` | service | CRUD | `lib/scoria/eval.ex` | exact |
| `lib/scoria/eval/eval_run.ex` | model | CRUD | `lib/scoria/eval/eval_run.ex` | exact |
| `priv/repo/migrations/*_create_eval_campaigns*.exs` | migration | transform | `priv/repo/migrations/20260513000100_add_canonical_identity_to_workflow_runs.exs` | partial |
| `test/scoria/eval/*campaign*.exs` | test | request-response | `test/scoria/eval/eval_run_persistence_test.exs` | role+flow |

## Pattern Assignments

### `lib/scoria/eval/eval_campaign.ex` (model, CRUD)

**Analog:** `lib/scoria/connectors/capability_snapshot.ex`

**Schema shape** (`lib/scoria/connectors/capability_snapshot.ex:12-28`):
```elixir
schema "ai_connector_capability_snapshots" do
  field(:catalog, :map, default: %{})
  field(:catalog_hash, :string)
  field(:catalog_version, :string)
  field(:tool_count, :integer, default: 0)
  field(:last_refreshed_at, :utc_datetime_usec)
  field(:last_refresh_status, :string, default: "pending")
  field(:last_good_refresh_at, :utc_datetime_usec)
  field(:last_refresh_error_code, :string)
  field(:stale_at, :utc_datetime_usec)
  field(:metadata, :map, default: %{})

  belongs_to(:connector, Connector)
  timestamps(type: :utc_datetime_usec)
end
```

**Changeset guardrails** (`lib/scoria/connectors/capability_snapshot.ex:31-58`):
```elixir
snapshot
|> cast(attrs, [..., :tool_count, :last_refreshed_at, :last_refresh_status, ...])
|> validate_required([:connector_id, :catalog_hash, :catalog_version, :last_refresh_status])
|> validate_inclusion(:last_refresh_status, @refresh_statuses)
|> validate_number(:tool_count, greater_than_or_equal_to: 0)
|> foreign_key_constraint(:connector_id)
|> unique_constraint(:connector_id)
```

**Apply to Phase 33:** Use this as the parent aggregate-row pattern. `EvalCampaign` should carry durable counts and timestamps directly on the row, with strict status validation and FK constraints, instead of reconstructing truth from child runs at read time.

### `lib/scoria/eval/eval_campaign_target.ex` (model, CRUD)

**Analog:** `lib/scoria/eval/score.ex`

**Child truth row pattern** (`lib/scoria/eval/score.ex:7-20`):
```elixir
schema "ai_scores" do
  field(:scorer_kind, :string)
  field(:status, :string, default: "passed")
  field(:evidence_refs, :map, default: %{})
  field(:metadata, :map, default: %{})

  belongs_to(:eval_run, Scoria.Eval.EvalRun)
  belongs_to(:dataset_item, Scoria.Eval.DatasetItem, type: :id)
  timestamps(type: :utc_datetime_usec)
end
```

**Validation pattern** (`lib/scoria/eval/score.ex:24-48`):
```elixir
score
|> cast(attrs, [..., :eval_run_id, :dataset_item_id])
|> validate_required([:scorer_kind, :status, :score, :eval_run_id, :dataset_item_id])
|> validate_inclusion(:status, ["passed", "failed", "error"])
|> foreign_key_constraint(:eval_run_id)
|> foreign_key_constraint(:dataset_item_id)
```

**Apply to Phase 33:** Model `EvalCampaignTarget` as an explicit child row with narrow execution metadata and FK-backed lineage. Keep semantic eval contract fields off this row.

### `lib/scoria/eval/campaign_worker.ex` (service, request-response)

**Analog:** `lib/scoria/compaction/summarize_worker.ex`

**Worker contract** (`lib/scoria/compaction/summarize_worker.ex:6-13,27-47`):
```elixir
use Oban.Worker,
  queue: :compaction,
  unique: [
    period: 60,
    fields: [:worker, :args],
    keys: [:run_id],
    states: [:available, :scheduled, :executing, :retryable]
  ]

@impl Oban.Worker
def perform(%Job{args: %{"run_id" => run_id}}) do
  ...
end

def new_job(args, opts \\ []) do
  args
  |> Map.new()
  |> Map.take([:run_id, "run_id"])
  |> normalize_args()
  |> new(opts)
end
```

**Atomic finalize pattern** (`lib/scoria/compaction/summarize_worker.ex:59-81`):
```elixir
Multi.new()
|> Multi.insert(:memory, CompactedMemory.changeset(...))
|> Multi.update_all(:events, from(event in Event, where: event.id in ^event_ids),
  set: [compacted_at: compacted_at, updated_at: compacted_at]
)
|> Repo.transaction()
|> case do
  {:ok, _changes} -> :ok
  {:error, _step, reason, _changes} -> {:error, reason}
end
```

**Apply to Phase 33:** The fan-out worker should accept normalized args only, run one target shard, and finalize child truth plus campaign counters in one `Ecto.Multi`.

### `lib/scoria/eval/campaign_enqueuer.ex` (service, batch)

**Analog:** `lib/scoria/workflows/batch_enqueue.ex`

**Batch fan-out seam** (`lib/scoria/workflows/batch_enqueue.ex:17-27`):
```elixir
def enqueue_all(jobs, opts \\ []) do
  chunk_size = Keyword.get(opts, :chunk_size, @default_chunk_size)

  jobs
  |> Enum.chunk_every(chunk_size)
  |> Enum.with_index()
  |> Enum.reduce(Ecto.Multi.new(), fn {chunk, idx}, multi ->
    Oban.insert_all(multi, :"batch_#{idx}", chunk)
  end)
  |> Scoria.Repo.transaction()
end
```

**Test expectation** (`test/scoria/workflows/batch_enqueue_test.exs:28-47`): chunking is verified by inserted batches and queue-specific assertions.

**Apply to Phase 33:** Build all target jobs first, then insert them through this seam on the `:evals` queue. Do not hand-roll per-target `Oban.insert/1` loops.

### `lib/scoria/eval.ex` (service, CRUD)

**Analog:** `lib/scoria/eval.ex`

**Parent-child transaction style** (`lib/scoria/eval.ex:174-219`):
```elixir
def create_eval_run(attrs \\ %{}) do
  eval_spec = get_eval_spec!(fetch_attr!(attrs, :eval_spec_id))

  attrs_with_defaults =
    attrs
    |> put_new_attr(:dataset_id, eval_spec.dataset_id)
    |> put_new_attr(:dataset_version, eval_spec.dataset_version)
    |> put_new_attr(:eval_spec_version, eval_spec.version)
    |> put_new_attr(:status, "pending")

  %EvalRun{}
  |> EvalRun.changeset(attrs_with_defaults)
  |> Repo.insert()
end

def record_eval_scores(%EvalRun{} = eval_run, score_attrs_list) when is_list(score_attrs_list) do
  Ecto.Multi.new()
  |> Ecto.Multi.run(:scores, fn repo, _changes -> insert_scores(repo, eval_run, score_attrs_list) end)
  |> Ecto.Multi.update(:eval_run, fn %{scores: scores} ->
    aggregate_attrs = aggregate_score_attrs(eval_run, scores)
    EvalRun.changeset(eval_run, aggregate_attrs)
  end)
  |> Repo.transaction()
end
```

**Aggregate computation pattern** (`lib/scoria/eval.ex:240-261`):
```elixir
%{
  status: if(total_items > 0, do: "running", else: eval_run.status),
  total_items: total_items,
  passed_items: passed_items,
  failed_items: failed_items,
  avg_latency_ms: avg_latency_ms,
  total_cost_usd: total_cost_usd
}
```

**Apply to Phase 33:** Keep campaign orchestration in `Scoria.Eval`, not a second domain root. Create campaign parent, targets, and child `EvalRun` rows through `Ecto.Multi`, then update aggregate facts eagerly as workers complete.

### `lib/scoria/eval/eval_run.ex` (model, CRUD)

**Analog:** `lib/scoria/eval/eval_run.ex`

**Existing child execution truth** (`lib/scoria/eval/eval_run.ex:7-35`):
```elixir
schema "ai_eval_runs" do
  field(:runner_mode, Ecto.Enum, values: [:offline_replay, :live_judge, :refresh_capture])
  field(:status, :string, default: "pending")
  field(:provider, :string)
  field(:model, :string)
  field(:total_items, :integer)
  field(:passed_items, :integer)
  field(:failed_items, :integer)
  field(:avg_latency_ms, :integer)
  field(:total_cost_usd, :decimal)

  belongs_to(:dataset, Scoria.Eval.Dataset, type: :id)
  belongs_to(:eval_spec, Scoria.Eval.EvalSpec)
  has_many(:scores, Scoria.Eval.Score)
end
```

**Validation shape** (`lib/scoria/eval/eval_run.ex:39-83`):
```elixir
|> validate_required([:runner_mode, :status, :dataset_id, :dataset_version, :eval_spec_id, :eval_spec_version])
|> validate_inclusion(:status, ["pending", "running", "completed", "failed"])
|> validate_number(:total_items, greater_than_or_equal_to: 0)
|> foreign_key_constraint(:dataset_id)
|> foreign_key_constraint(:eval_spec_id)
```

**Apply to Phase 33:** Extend this row with campaign lineage and tenant identity; do not replace it. `EvalRun` remains the durable child execution truth.

### `priv/repo/migrations/*_create_eval_campaigns*.exs` (migration, transform)

**Analog:** `priv/repo/migrations/20260513000100_add_canonical_identity_to_workflow_runs.exs`

**Multi-tenant migration pattern** (`priv/repo/migrations/20260513000100_add_canonical_identity_to_workflow_runs.exs:4-13`):
```elixir
alter table(:ai_workflow_runs) do
  add_if_not_exists :actor_id, :string
  add_if_not_exists :tenant_id, :string
end

create_if_not_exists index(:ai_workflow_runs, [:actor_id])
create_if_not_exists index(:ai_workflow_runs, [:tenant_id])
create_if_not_exists index(:ai_workflow_runs, [:tenant_id, :actor_id])
```

**Apply to Phase 33:** Put `tenant_id` on every durable campaign artifact and index the tenant-scoped lookup paths explicitly. Prefer FK lineage plus tenant columns over prefix-based isolation.

### `test/scoria/eval/*campaign*.exs` (test, request-response)

**Analog:** `test/scoria/eval/eval_run_persistence_test.exs`

**Persistence test shape** (`test/scoria/eval/eval_run_persistence_test.exs:37-75`):
```elixir
assert {:ok, eval_run} = Eval.create_eval_run(%{...})
assert {:ok, eval_run, [%Score{}]} = Eval.record_eval_scores(eval_run, [%{...}])
assert {:ok, eval_run} = Eval.complete_eval_run(eval_run, %{status: "completed", ...})

persisted_run =
  EvalRun
  |> Repo.get!(eval_run.id)
  |> Repo.preload([:dataset, scores: [:dataset_item]])
```

**Durable aggregate assertions** (`test/scoria/eval/eval_run_persistence_test.exs:89-105`):
```elixir
assert persisted_run.total_items == 1
assert persisted_run.passed_items == 1
assert persisted_run.failed_items == 0
assert persisted_run.avg_latency_ms == 42
assert Decimal.equal?(persisted_run.total_cost_usd, Decimal.new("0.0004"))
```

**Apply to Phase 33:** Campaign tests should assert durable parent counts, tenant propagation, job-envelope metadata, and child `EvalRun`/`Score` lineage after worker completion.

## Shared Patterns

### Canonical identity propagation
**Sources:** `lib/scoria/identity.ex:63-104`, `lib/scoria/workflows.ex:90-97`, `lib/scoria/workflows.ex:792-798`, `lib/scoria/workflows/runtime.ex:391-406`

```elixir
identity = Identity.normalize(run_attrs)
run_attrs = run_attrs_with_identity(run_attrs, identity)

defp run_attrs_with_identity(run_attrs, identity) do
  run_attrs
  |> Map.put(:actor_id, identity.actor_id)
  |> Map.put(:tenant_id, identity.tenant_id)
  |> Map.put(:session_id, identity.session_id)
  |> Map.put(:metadata, Identity.metadata(run_attrs))
end
```

Apply this to campaign creation, target rows, `EvalRun`, and Oban args. Worker overlays should never silently replace persisted root identity.

### Immutable root identity with overlay fallback
**Sources:** `lib/scoria/workflows.ex:804-820`, `lib/scoria/workflows/runtime.ex:409-425`

```elixir
%Identity{
  root_identity
  | actor_id: root_identity.actor_id || overlay_identity.actor_id,
    tenant_id: root_identity.tenant_id || overlay_identity.tenant_id,
    session_id: root_identity.session_id || overlay_identity.session_id
}
```

Use this when a job envelope includes tenant context. The persisted campaign/run identity wins; job args only fill missing fields.

### Telemetry envelope discipline
**Sources:** `lib/scoria/sre/telemetry.ex:11-18`, `lib/scoria/sre/telemetry.ex:20-33`, `lib/scoria/sre/telemetry_identity.ex:36-57`, `lib/scoria/workflows/runtime.ex:371-388`

```elixir
:telemetry.execute(
  @runtime_prefix ++ [:tool_reliability],
  measurements,
  TelemetryIdentity.runtime_metadata(attrs)
)

%{
  actor_id: identity.actor_id,
  tenant_id: identity.tenant_id || "system",
  session_id: identity.session_id,
  subject_kind: "workflow_step",
  reason_code: outcome,
  trace_id: Map.get(budget_context, :trace_id, step.id),
  run_id: run.id,
  provider: Map.get(budget_context, :provider),
  model: Map.get(budget_context, :model)
}
```

Campaign telemetry should follow this split: low-cardinality labels in metadata, correlation refs separate, tenant/run/target identifiers always present.

### Oban job normalization and dedupe
**Sources:** `lib/scoria/connectors/discovery_job.ex:6-13`, `lib/scoria/connectors/discovery_job.ex:23-39`

```elixir
use Oban.Worker,
  queue: :connector_sync,
  unique: [
    period: {5, :minutes},
    fields: [:worker, :args],
    keys: [:connector_id, :trigger_class],
    states: [:available, :scheduled, :executing, :retryable]
  ]

def new_job(args, opts \\ []) do
  args
  |> normalize_args()
  |> new(opts)
end
```

Phase 33 workers should normalize args into a stable envelope including `campaign_id`, `target_id`, `tenant_id`, and queue hints before enqueue.

### Durable parent snapshot over child truth
**Sources:** `lib/scoria/eval.ex:205-215`, `lib/scoria/connectors/discovery.ex:46-66`, `lib/scoria/connectors/discovery.ex:92-127`

```elixir
Multi.new()
|> Multi.update(:connector, Connector.changeset(connector, connector_attrs))
|> Multi.run(:snapshot, fn repo, _changes ->
  upsert_snapshot(repo, connector.id, snapshot_attrs)
end)
|> Repo.transaction()
```

Use a single transaction to finalize shard work and update campaign counters/status snapshots. Keep parent aggregate truth cheap to read but derived from durable child evidence.

### Orchestrator-only model execution boundary
**Sources:** `lib/scoria/orchestrator.ex:9-18`, `lib/scoria/orchestrator.ex:20-50`, `test/scoria/orchestrator_test.exs:53-79`

```elixir
def generate_text(model, prompt, options \\ []) do
  execute(:generate_text, model, [model, prompt], options)
end

case result do
  {:ok, res} ->
    :telemetry.execute([:scoria, :orchestrator, :request, :stop], %{duration: duration}, metadata)
    {:ok, res}

  {:error, reason} ->
    :telemetry.execute([:scoria, :orchestrator, :request, :stop], %{duration: duration}, Map.put(metadata, :reason, reason))
    {:error, reason}
end
```

Phase 33 workers should never call provider clients directly. All target execution goes through `Scoria.Orchestrator` so fallback and telemetry remain consistent.

## No Exact Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/scoria/eval/eval_campaign.ex` + `lib/scoria/eval/eval_campaign_target.ex` together | model | CRUD | No existing eval parent-child coordinator row with eager queued/running/completed/failed counters exists yet. |
| `lib/scoria/eval/campaign_worker.ex` | service | request-response | No current worker both fans out eval shards and writes `EvalRun`/`Score` truth under a campaign parent. Combine `SummarizeWorker`, `BatchEnqueue`, `Eval`, and `Orchestrator` patterns. |

## Metadata

**Analog search scope:** `lib/scoria/eval`, `lib/scoria/workflows`, `lib/scoria/connectors`, `lib/scoria/sre`, `priv/repo/migrations`, `test/scoria`
**Files scanned closely:** 15
**Pattern extraction date:** 2026-05-21
