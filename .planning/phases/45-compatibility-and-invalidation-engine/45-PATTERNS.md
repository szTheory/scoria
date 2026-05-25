# Phase 45: Compatibility and invalidation engine - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 13
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/scoria/semantic_cache.ex` | service | CRUD | `lib/scoria/semantic_cache.ex` | exact |
| `lib/scoria/semantic_cache/lookup.ex` | service | request-response | `lib/scoria/semantic_cache.ex` | role-match |
| `lib/scoria/semantic_cache/compatibility.ex` | service | transform | `lib/scoria/semantic_cache/eligibility.ex` | role-match |
| `lib/scoria/semantic_cache/invalidation.ex` | service | batch | `lib/scoria/compaction/summarize_worker.ex` | dataflow-match |
| `lib/scoria/semantic_cache/entry.ex` | model | CRUD | `lib/scoria/semantic_cache/entry.ex` | exact |
| `lib/scoria/semantic_cache/entry_event.ex` | model | event-driven | `lib/scoria/semantic_cache/entry_event.ex` | exact |
| `lib/scoria/workflows/runtime.ex` | service | request-response | `lib/scoria/workflows/runtime.ex` | exact |
| `lib/scoria/runtime/params.ex` | utility | transform | `lib/scoria/runtime/params.ex` | exact |
| `priv/repo/migrations/*_semantic_cache_compatibility_and_invalidation.exs` | migration | batch | `priv/repo/migrations/20260525070000_create_semantic_cache_tables.exs` | role-match |
| `test/scoria/semantic_cache_test.exs` | test | CRUD | `test/scoria/semantic_cache_test.exs` | exact |
| `test/scoria/semantic_cache/eligibility_test.exs` | test | request-response | `test/scoria/semantic_cache/eligibility_test.exs` | exact |
| `test/scoria/runtime/semantic_fast_path_test.exs` | test | request-response | `test/scoria/runtime/semantic_fast_path_test.exs` | exact |
| `test/scoria/semantic_cache/invalidation_test.exs` | test | batch | `test/scoria/runtime/compacted_memory_test.exs` | dataflow-match |

## Pattern Assignments

### `lib/scoria/semantic_cache.ex` (service, CRUD)

**Analog:** `lib/scoria/semantic_cache.ex`

**Imports + aliases** (`lib/scoria/semantic_cache.ex:6-10`)
```elixir
import Ecto.Query, warn: false

alias Ecto.Multi
alias Scoria.Repo
alias Scoria.SemanticCache.{Entry, EntryEvent}
```

**Transactional entry + event write** (`lib/scoria/semantic_cache.ex:72-88`)
```elixir
Multi.new()
|> Multi.insert(:entry, Entry.changeset(%Entry{}, attrs))
|> Multi.insert(:event, fn %{entry: entry} ->
  EntryEvent.changeset(%EntryEvent{}, %{
    entry_id: entry.id,
    event_kind: "admitted",
    reason_code: Map.get(attrs, :reason_code, "admitted"),
    workflow_run_id: Map.get(attrs, :origin_run_id),
    span_id: Map.get(attrs, :origin_span_id),
    metadata: %{"scope_kind" => entry.scope_kind, "scope_reason" => entry.scope_reason}
  })
end)
|> Repo.transaction()
```

**Filter-first lookup query** (`lib/scoria/semantic_cache.ex:173-215`)
```elixir
Entry
|> where(
  [entry],
  entry.tenant_id == ^tenant_id and
    entry.lane_key == ^lane_key and
    entry.query_text == ^query_text and
    entry.status == ^@active_status and
    is_nil(entry.invalidated_at) and
    (is_nil(entry.expires_at) or entry.expires_at > ^now)
)
|> maybe_scope_filter(actor_id)
|> apply_compatibility_filters(attrs)
|> order_by([entry], desc: fragment("CASE WHEN ? = 'actor_scoped' THEN 1 ELSE 0 END", entry.scope_kind))
|> limit(1)
```

**Error return shape** (`lib/scoria/semantic_cache.ex:84-88`, `107-111`, `129-133`)
```elixir
|> Repo.transaction()
|> case do
  {:ok, %{entry: entry, event: event}} -> {:ok, %{entry: entry, event: event}}
  {:error, _op, reason, _changes} -> {:error, reason}
end
```

**Use for Phase 45:** keep `Scoria.SemanticCache` as the public facade even if lookup and invalidation logic moves into helper modules.

---

### `lib/scoria/semantic_cache/lookup.ex` (service, request-response)

**Analog:** `lib/scoria/semantic_cache.ex`

**Public contract shape** (`lib/scoria/semantic_cache.ex:45-58`)
```elixir
def lookup(attrs) when is_map(attrs) or is_list(attrs) do
  attrs = normalize_attrs(attrs)

  with :ok <- require_tenant(attrs),
       :ok <- require_lane(attrs),
       :ok <- require_query_text(attrs) do
    attrs
    |> lookup_query()
    |> Repo.one()
    |> case do
      nil -> :miss
      %Entry{} = entry -> {:hit, entry}
    end
  end
end
```

**Semantic ranking pattern** (`lib/scoria/knowledge/backends/pgvector.ex:23-30`)
```elixir
Chunk
|> maybe_filter_source(source_id)
|> order_by(
  [chunk],
  asc: cosine_distance(chunk.embedding, ^Pgvector.new(query_embedding))
)
|> limit(^limit)
|> Repo.all()
```

**Use for Phase 45:** preserve the current tagged return style, but extend it to `{:reject, reason_code, candidate}` after compatibility/staleness checks. Keep exact `query_text` first, then run pgvector ordering only on the already filtered candidate set.

---

### `lib/scoria/semantic_cache/compatibility.ex` (service, transform)

**Analog:** `lib/scoria/semantic_cache/eligibility.ex`

**Normalization pattern** (`lib/scoria/semantic_cache/eligibility.ex:8-23`)
```elixir
def evaluate(attrs) when is_map(attrs) or is_list(attrs) do
  attrs = normalize_map(attrs)
  tenant_id = present_string(attrs, :tenant_id)
  actor_id = present_string(attrs, :actor_id)
  semantic_cache = nested_map(attrs, :semantic_cache)
  prompt_policy = PromptPolicy.normalize(nested_map(attrs, :prompt_policy))

  cond do
    is_nil(present_string(semantic_cache, :lane_key)) -> {:bypass, :lane_not_registered}
    is_nil(tenant_id) -> {:bypass, :tenant_scope_missing}
    prompt_policy.approval_required -> {:bypass, :approval_required}
    truthy?(value(attrs, semantic_cache, :write_side_step_present)) -> {:bypass, :write_side_step_present}
    truthy?(value(attrs, semantic_cache, :personalized_tool)) -> {:bypass, :personalized_tool}
    true -> eligible_result(attrs, semantic_cache, tenant_id, actor_id)
  end
end
```

**Canonical prompt/policy projection** (`lib/scoria/prompt_policy.ex:88-108`)
```elixir
%__MODULE__{
  policy_key: normalize_string(canonical_value(attrs, :policy_key)),
  prompt_ref: normalize_string(canonical_value(attrs, :prompt_ref)),
  prompt_version: normalize_string(canonical_value(attrs, :prompt_version)),
  tools_allowed:
    attrs
    |> first_present([:tools_allowed])
    |> fallback(first_present(constraints, [:tools_allowed]))
    |> normalize_boolean(true),
  grounding_required:
    attrs
    |> first_present([:grounding_required])
    |> fallback(first_present(constraints, [:grounding_required]))
    |> normalize_boolean(false),
  approval_required:
    attrs
    |> first_present([:approval_required])
    |> fallback(first_present(constraints, [:approval_required]))
    |> normalize_boolean(false),
  metadata: normalize_metadata(canonical_value(attrs, :metadata))
}
```

**Durable source facts** (`lib/scoria/knowledge/source.ex:8-16`)
```elixir
schema "ai_knowledge_sources" do
  field :entity_id, :binary_id
  field :version, :integer, default: 1
  field :is_current, :boolean, default: true
  field :kind, :string
  field :uri, :string
  field :title, :string
  field :digest, :string
  field :metadata, :map, default: %{}
end
```

**Use for Phase 45:** build compatibility checks as explicit pure functions returning stable reason codes. Reuse the existing canonical-value helpers and `PromptPolicy.normalize/1` rather than comparing raw maps ad hoc.

---

### `lib/scoria/semantic_cache/invalidation.ex` (service, batch)

**Analog:** `lib/scoria/compaction/summarize_worker.ex`

**Batch transition pattern** (`lib/scoria/compaction/summarize_worker.ex:59-80`)
```elixir
Multi.new()
|> Multi.insert(
  :memory,
  CompactedMemory.changeset(%CompactedMemory{}, %{...})
)
|> Multi.update_all(
  :events,
  from(event in Event, where: event.id in ^event_ids),
  set: [compacted_at: compacted_at, updated_at: compacted_at]
)
|> Repo.transaction()
|> case do
  {:ok, _changes} -> :ok
  {:error, _step, reason, _changes} -> {:error, reason}
end
```

**Versioned transition pattern** (`lib/scoria/prompt_registry.ex:73-80`)
```elixir
Ecto.Multi.new()
|> Ecto.Multi.update(:deprecate_old, old_template_changeset)
|> Ecto.Multi.insert(:new_template, PromptTemplate.changeset(%PromptTemplate{}, new_attrs))
|> Repo.transaction()
|> case do
  {:ok, %{new_template: new_template}} -> {:ok, new_template}
  {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
end
```

**Use for Phase 45:** implement stale/invalidate fan-out as a transaction that updates matching entries and appends entry events in the same unit. Prefer `update_all` for bulk row changes and stable reason codes in event metadata.

---

### `lib/scoria/semantic_cache/entry.ex` (model, CRUD)

**Analog:** `lib/scoria/semantic_cache/entry.ex`

**Schema pattern** (`lib/scoria/semantic_cache/entry.ex:8-41`)
```elixir
@statuses ~w(active writeback_rejected invalidated expired)
@scope_kinds ~w(tenant_shared actor_scoped)

schema "ai_semantic_cache_entries" do
  field :tenant_id, :string
  field :actor_id, :string
  field :scope_kind, :string
  field :scope_reason, :string
  field :lane_key, :string
  field :lane_module, :string
  field :policy_key, :string
  field :prompt_ref, :string
  field :prompt_version, :string
  field :provider, :string
  field :model, :string
  ...
  field :status, :string, default: "active"
  field :last_hit_at, :utc_datetime_usec
  field :hit_count, :integer, default: 0
  field :expires_at, :utc_datetime_usec
  field :invalidated_at, :utc_datetime_usec
  field :metadata, :map, default: %{}
end
```

**Validation pattern** (`lib/scoria/semantic_cache/entry.ex:44-85`)
```elixir
entry
|> cast(attrs, [...])
|> validate_required([
  :tenant_id,
  :scope_kind,
  :scope_reason,
  :lane_key,
  :query_text,
  :answer_payload,
  :status
])
|> validate_inclusion(:scope_kind, @scope_kinds)
|> validate_inclusion(:status, @statuses)
|> validate_number(:hit_count, greater_than_or_equal_to: 0)
```

**Use for Phase 45:** add `stale` and any new compatibility snapshot fields here, keep the schema flat, and validate status via `@statuses` rather than free-form strings.

---

### `lib/scoria/semantic_cache/entry_event.ex` (model, event-driven)

**Analog:** `lib/scoria/semantic_cache/entry_event.ex`

**Schema + changeset pattern** (`lib/scoria/semantic_cache/entry_event.ex:8-24`)
```elixir
schema "ai_semantic_cache_entry_events" do
  field :event_kind, :string
  field :reason_code, :string
  field :metadata, :map, default: %{}

  belongs_to :entry, Scoria.SemanticCache.Entry
  belongs_to :workflow_run, Scoria.Workflows.Run
  belongs_to :span, Scoria.Repo.Span

  timestamps(type: :utc_datetime_usec)
end

def changeset(event, attrs) do
  event
  |> cast(attrs, [:entry_id, :event_kind, :reason_code, :workflow_run_id, :span_id, :metadata])
  |> validate_required([:entry_id, :event_kind, :metadata])
end
```

**Use for Phase 45:** keep invalidation/staleness provenance in `event_kind` + `reason_code` + compact metadata instead of burying explanations only in entry rows.

---

### `lib/scoria/workflows/runtime.ex` (service, request-response)

**Analog:** `lib/scoria/workflows/runtime.ex`

**Fast-path outcome shaping** (`lib/scoria/workflows/runtime.ex:40-88`)
```elixir
case Eligibility.evaluate(facts) do
  {:bypass, reason_code} ->
    {:continue, put_semantic_cache_state(workflow_attrs, %{
       "eligibility_status" => "bypass",
       "lookup_status" => "bypass",
       "lookup_reason_code" => Atom.to_string(reason_code),
       "query_text" => query_text
     })}

  {eligibility_status, attrs} when eligibility_status in [:eligible, :eligible_actor_scoped] ->
    case SemanticCache.lookup(Map.put(attrs, :query_text, query_text)) do
      {:hit, entry} -> {:hit, put_semantic_cache_state(workflow_attrs, %{...}), entry}
      :miss -> {:continue, put_semantic_cache_state(workflow_attrs, %{...})}
      {:bypass, reason_code} -> {:continue, put_semantic_cache_state(workflow_attrs, %{...})}
    end
end
```

**Writeback seam** (`lib/scoria/workflows/runtime.ex:773-820`)
```elixir
case semantic_writeback_context(run) do
  %{lookup_status: "miss", eligibility_status: status} = semantic_ctx
  when status in ["eligible", "eligible_actor_scoped"] ->
    case semantic_writeback_reason(result_envelope) do
      nil ->
        with {:ok, %{entry: entry}} <-
               SemanticCache.admit(
                 semantic_cache_entry_attrs(run, semantic_ctx, result_envelope, step, "active")
               ) do
          Map.put(result_envelope, "semantic_cache", %{
            "status" => "admitted",
            "entry_id" => entry.id,
            "origin_run_id" => run.id
          })
        else
          _ -> result_envelope
        end
```

**Runtime defaults extraction** (`lib/scoria/workflows/runtime.ex:762-770`)
```elixir
%{
  provider: Map.get(metadata, "provider"),
  model: Map.get(metadata, "model"),
  policy_key: Map.get(metadata, "policy_key"),
  prompt_ref: Map.get(metadata, "prompt_ref"),
  prompt_version: Map.get(metadata, "prompt_version"),
  prompt_policy: Map.get(metadata, "prompt_policy"),
  semantic_cache: Map.get(metadata, "semantic_cache")
}
```

**Use for Phase 45:** keep runtime as the orchestration seam only. Put lookup/invalidation logic in semantic-cache modules, then project stage-separated status and reason codes back into runtime metadata here.

---

### `lib/scoria/runtime/params.ex` (utility, transform)

**Analog:** `lib/scoria/runtime/params.ex`

**Semantic-cache metadata projection** (`lib/scoria/runtime/params.ex:120-128`, `167-177`)
```elixir
runtime_metadata =
  resolved_defaults
  |> Defaults.to_metadata()
  |> maybe_put_semantic_cache(semantic_cache)

metadata
|> maybe_put_payload(payload)
|> maybe_put_identity_metadata(identity)
|> Map.put("runtime", runtime_metadata)
```

```elixir
defp maybe_put_semantic_cache(runtime_metadata, semantic_cache) do
  Map.put(runtime_metadata, "semantic_cache", %{
    "lane" => semantic_cache.lane_module,
    "lane_key" => semantic_cache.lane_key,
    "default_scope" => Atom.to_string(semantic_cache.default_scope),
    "safe_read_only" => semantic_cache.safe_read_only,
    "metadata" => semantic_cache.metadata
  })
end
```

**Lane normalization pattern** (`lib/scoria/runtime/params.ex:213-223`)
```elixir
defp semantic_cache_config(opts, runtime) do
  case value(opts, runtime, :semantic_cache) do
    nil ->
      {:ok, nil}

    semantic_cache ->
      semantic_cache
      |> normalize_map()
      |> canonical_value(:lane)
      |> SemanticLane.describe()
  end
end
```

**Use for Phase 45:** if compatibility defaults or freshness windows need runtime metadata, extend this projection pattern rather than introducing a second config channel.

---

### `priv/repo/migrations/*_semantic_cache_compatibility_and_invalidation.exs` (migration, batch)

**Analog:** `priv/repo/migrations/20260525070000_create_semantic_cache_tables.exs`

**Table + index style** (`priv/repo/migrations/20260525070000_create_semantic_cache_tables.exs:5-41`)
```elixir
create_if_not_exists table(:ai_semantic_cache_entries, primary_key: false) do
  add :id, :binary_id, primary_key: true
  add :tenant_id, :string, null: false
  ...
  add :status, :string, null: false, default: "active"
  add :last_hit_at, :utc_datetime_usec
  add :hit_count, :integer, null: false, default: 0
  add :expires_at, :utc_datetime_usec
  add :invalidated_at, :utc_datetime_usec
  add :metadata, :map, null: false, default: %{}
end

create_if_not_exists index(:ai_semantic_cache_entries, [:tenant_id])
create_if_not_exists index(:ai_semantic_cache_entries, [:tenant_id, :lane_key])
create_if_not_exists index(:ai_semantic_cache_entries, [:tenant_id, :scope_kind, :actor_id])
create_if_not_exists index(:ai_semantic_cache_entries, [:status])
```

**Event table style** (`priv/repo/migrations/20260525070000_create_semantic_cache_tables.exs:43-58`)
```elixir
create_if_not_exists table(:ai_semantic_cache_entry_events, primary_key: false) do
  add :id, :binary_id, primary_key: true
  add :entry_id, references(:ai_semantic_cache_entries, type: :binary_id, on_delete: :delete_all),
    null: false
  add :event_kind, :string, null: false
  add :reason_code, :string
  add :workflow_run_id, references(:ai_workflow_runs, type: :binary_id, on_delete: :nilify_all)
  add :span_id, references(:ai_spans, type: :binary_id, on_delete: :nilify_all)
  add :metadata, :map, null: false, default: %{}
end
```

**Use for Phase 45:** extend the existing semantic-cache tables in place. Follow the same `create_if_not_exists`, explicit defaults, and targeted indexes style for new status/fingerprint columns.

---

### `test/scoria/semantic_cache_test.exs` (test, CRUD)

**Analog:** `test/scoria/semantic_cache_test.exs`

**DB sandbox setup** (`test/scoria/semantic_cache_test.exs:9-13`)
```elixir
setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
  Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
  :ok
end
```

**Lifecycle assertion style** (`test/scoria/semantic_cache_test.exs:15-44`)
```elixir
assert {:ok, %{entry: %Entry{} = entry, event: event}} =
         SemanticCache.admit(%{...})

persisted_entry = Repo.get!(Entry, entry.id)
[persisted_event] = SemanticCache.list_events(entry.id)

assert persisted_entry.tenant_id == "tenant-a"
assert persisted_event.event_kind == "admitted"
assert persisted_event.workflow_run_id == run.id
```

**Lookup behavior assertion style** (`test/scoria/semantic_cache_test.exs:78-103`, `118-143`)
```elixir
assert {:hit, %Entry{id: shared_entry_id}} = SemanticCache.lookup(%{...})
assert :miss = SemanticCache.lookup(%{...})
assert {:bypass, :tenant_scope_missing} = SemanticCache.lookup(%{...})
assert {:ok, %{entry: reused_entry, event: reused_event}} =
         SemanticCache.record_reuse(entry, %{reason_code: "tenant_cache_hit"})
```

**Use for Phase 45:** add direct unit coverage for `reject`, `stale`, `invalidated`, compatibility mismatch, and explicit reason-coded events in this style.

---

### `test/scoria/semantic_cache/eligibility_test.exs` (test, request-response)

**Analog:** `test/scoria/semantic_cache/eligibility_test.exs`

**Tagged tuple assertions** (`test/scoria/semantic_cache/eligibility_test.exs:6-19`, `21-33`)
```elixir
assert {:bypass, :lane_not_registered} = Eligibility.evaluate(%{...})
assert {:bypass, :approval_required} = Eligibility.evaluate(%{...})
assert {:bypass, :tenant_scope_missing} = Eligibility.evaluate(%{...})
assert {:bypass, :personalized_tool} = Eligibility.evaluate(%{...})
```

**Structured payload assertions** (`test/scoria/semantic_cache/eligibility_test.exs:35-71`)
```elixir
assert {:eligible, attrs} = Eligibility.evaluate(%{...})
assert attrs.scope_kind == :tenant_shared
assert attrs.scope_reason == "lane_default"

assert {:eligible_actor_scoped, actor_attrs} = Eligibility.evaluate(%{...})
assert actor_attrs.scope_kind == :actor_scoped
assert actor_attrs.scope_reason == "actor_scope_required"
```

**Use for Phase 45:** mirror this test shape for compatibility functions so each reason code is asserted directly, not inferred from broader runtime tests.

---

### `test/scoria/runtime/semantic_fast_path_test.exs` (test, request-response)

**Analog:** `test/scoria/runtime/semantic_fast_path_test.exs`

**In-test lane modules** (`test/scoria/runtime/semantic_fast_path_test.exs:10-16`)
```elixir
defmodule AccountFaqLane do
  use Scoria.SemanticLane, lane_key: "account_faq", default_scope: :tenant_shared, safe_read_only: true
end

defmodule ActorLane do
  use Scoria.SemanticLane, lane_key: "actor_help", default_scope: :actor_scoped, safe_read_only: true
end
```

**End-to-end runtime assertions** (`test/scoria/runtime/semantic_fast_path_test.exs:108-121`, `141-146`, `149-196`)
```elixir
assert {:ok, summary} =
         Runtime.start_run(
           %{tenant_id: "tenant-hit", actor_id: "actor-hit", session_id: "session-hit"},
           semantic_cache: [lane: AccountFaqLane],
           input: "what is scoria?"
         )

run = Workflows.get_run_tree!(summary.run_id)
[step] = run.steps

assert step.result_envelope["semantic_cache"]["status"] == "hit"
assert run.metadata["runtime"]["semantic_cache"]["lookup_status"] == "bypass"
assert run.metadata["runtime"]["semantic_cache"]["lookup_reason_code"] == "approval_required"
assert entry.status == "writeback_rejected"
```

**Use for Phase 45:** keep one end-to-end file that proves runtime metadata projection and fallback behavior after `reject`, `stale`, and `invalidated` outcomes.

---

### `test/scoria/semantic_cache/invalidation_test.exs` (test, batch)

**Analog:** `test/scoria/runtime/compacted_memory_test.exs`

**Pattern to copy:** batch-oriented DB assertions with explicit before/after persisted state checks. This is the best nearby analog for a transaction that mutates multiple rows in one workflow-owned operation.

## Shared Patterns

### Public Semantic-Cache Facade
**Source:** `lib/scoria/semantic_cache.ex:45-58`, `61-88`, `91-133`
**Apply to:** `semantic_cache.ex`, `semantic_cache/lookup.ex`, `semantic_cache/invalidation.ex`
```elixir
def lookup(attrs) when is_map(attrs) or is_list(attrs) do
  ...
end

def admit(attrs) when is_map(attrs) or is_list(attrs) do
  ...
end

def record_reuse(%Entry{} = entry, attrs \\ %{}) do
  ...
end
```

### Tagged Outcome Contracts
**Source:** `lib/scoria/semantic_cache/eligibility.ex:15-23`, `45-48`; `lib/scoria/workflows/runtime.ex:40-88`
**Apply to:** lookup, compatibility, runtime projection, tests
```elixir
{:bypass, :reason_code}
{:eligible, payload}
{:eligible_actor_scoped, payload}
:miss
{:hit, entry}
```

### Runtime Metadata Projection
**Source:** `lib/scoria/runtime/params.ex:167-177`; `lib/scoria/workflows/runtime.ex:42-47`, `53-63`, `68-78`
**Apply to:** any new compatibility/freshness data that needs to travel through runtime
```elixir
Map.put(runtime_metadata, "semantic_cache", %{
  "lane" => semantic_cache.lane_module,
  "lane_key" => semantic_cache.lane_key,
  "default_scope" => Atom.to_string(semantic_cache.default_scope),
  "safe_read_only" => semantic_cache.safe_read_only,
  "metadata" => semantic_cache.metadata
})
```

### pgvector Querying
**Source:** `lib/scoria/knowledge/backends/pgvector.ex:23-30`
**Apply to:** semantic fallback ranking only after compatibility filters
```elixir
|> order_by(
  [chunk],
  asc: cosine_distance(chunk.embedding, ^Pgvector.new(query_embedding))
)
|> limit(^limit)
```

### Transactional State Transition + Event Append
**Source:** `lib/scoria/compaction/summarize_worker.ex:59-80`; `lib/scoria/semantic_cache.ex:72-88`
**Apply to:** invalidation, stale marking, writeback lifecycle, future reuse counters
```elixir
Multi.new()
|> Multi.update_all(...)
|> Multi.insert(...)
|> Repo.transaction()
```

### Canonical Prompt/Policy/Source Facts
**Source:** `lib/scoria/prompt_policy.ex:88-108`; `lib/scoria/knowledge/source.ex:8-16`
**Apply to:** compatibility snapshot/fingerprint building
```elixir
policy_key: normalize_string(canonical_value(attrs, :policy_key)),
prompt_ref: normalize_string(canonical_value(attrs, :prompt_ref)),
prompt_version: normalize_string(canonical_value(attrs, :prompt_version)),
...
field :version, :integer, default: 1
field :digest, :string
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| None | - | - | The repo already contains close analogs for all Phase 45 seams, though `semantic_cache/invalidation.ex` is only a dataflow match rather than an exact module match. |

## Metadata

**Analog search scope:** `lib/scoria`, `lib/scoria/semantic_cache`, `lib/scoria/runtime`, `lib/scoria/knowledge`, `lib/scoria/compaction`, `priv/repo/migrations`, `test/scoria`
**Files scanned:** 15
**Pattern extraction date:** 2026-05-25
