# Phase 28: Async Session Compaction Engine - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria/runtime/compacted_memory.ex` | model | CRUD | `lib/scoria/knowledge/chunk.ex` | role-match |
| `priv/repo/migrations/*_create_ai_compacted_memories.exs` | migration | schema | `priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs` | exact |
| `lib/scoria/compaction/summarize_worker.ex` | worker | event-driven | `lib/scoria/connectors/discovery_job.ex` | role-match |
| `lib/scoria/workflows/event.ex` | model | CRUD | `lib/scoria/workflows/event.ex` | exact |
| `lib/scoria/workflows.ex` | context | event-driven | `lib/scoria/workflows.ex` | exact |

## Pattern Assignments

### `lib/scoria/runtime/compacted_memory.ex` (model, CRUD)

**Analog:** `lib/scoria/knowledge/chunk.ex`

**Imports and Pgvector pattern** (lines 1-17):
```elixir
defmodule Scoria.Knowledge.Chunk do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ai_knowledge_chunks" do
    field :chunk_digest, :string
    field :body, :string
    field :heading_path, {:array, :string}, default: []
    field :start_offset, :integer
    field :end_offset, :integer
    field :token_count, :integer
    field :embedding, Pgvector.Ecto.Vector
    field :metadata, :map, default: %{}

    belongs_to :source, Scoria.Knowledge.Source
```

### `priv/repo/migrations/*_create_ai_compacted_memories.exs` (migration, schema)

**Analog:** `priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs`

**Migration pattern with vector extension** (lines 4-7, 21-36):
```elixir
  def change do
    execute("CREATE EXTENSION IF NOT EXISTS vector")

    create_if_not_exists table(:ai_knowledge_chunks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :source_id, references(:ai_knowledge_sources, type: :binary_id, on_delete: :delete_all),
        null: false

      add :chunk_digest, :string, null: false
      add :body, :text, null: false
      add :heading_path, {:array, :string}, null: false, default: []
      add :start_offset, :integer, null: false
      add :end_offset, :integer, null: false
      add :token_count, :integer, null: false
      add :embedding, :vector, size: 3
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists index(:ai_knowledge_chunks, ["embedding vector_cosine_ops"], using: :hnsw)
```

### `lib/scoria/compaction/summarize_worker.ex` (worker, event-driven)

**Analog:** `lib/scoria/connectors/discovery_job.ex`

**Oban Worker Configuration** (lines 6-21):
```elixir
  use Oban.Worker,
    queue: :connector_sync,
    unique: [
      period: {5, :minutes},
      fields: [:worker, :args],
      keys: [:connector_id, :trigger_class],
      states: [:available, :scheduled, :executing, :retryable]
    ]

  alias Oban.Job
  alias Scoria.Connectors.Discovery

  @impl Oban.Worker
  def perform(%Job{args: %{"connector_id" => connector_id} = args}) do
    Discovery.refresh_connector(connector_id, args)
  end
```

### `lib/scoria/workflows.ex` (context, event-driven)

**Analog:** `lib/scoria/workflows.ex`

**Event Insertion Trigger Pattern** (lines 690-701):
```elixir
  defp insert_event(repo, run_id, step_id, attrs) do
    sequence = next_sequence(repo, Event, run_id)

    %Event{}
    |> Event.changeset(
      attrs
      |> Map.put(:run_id, run_id)
      |> Map.put(:step_id, step_id)
      |> Map.put(:sequence, sequence)
    )
    |> repo.insert!()
  end
```
*(This insertion function will be modified to also check token boundaries and enqueue `Scoria.Compaction.SummarizeWorker`.)*

## Shared Patterns

### Oban Enqueueing
**Source:** `lib/scoria/connectors/discovery_job.ex`
**Apply to:** `Scoria.Workflows.insert_event/4`
```elixir
  def new_job(args, opts \\ []) do
    args
    |> normalize_args()
    |> new(opts)
  end
```

## Metadata

**Analog search scope:** `lib/scoria/**/*.ex`, `priv/repo/**/*.exs`
**Files scanned:** ~105 source files, ~18 migration files
**Pattern extraction date:** 2024-05-24
