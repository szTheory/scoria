# Phase 43: Knowledge tenant isolation - Pattern Map

**Mapped:** 2026-07-05
**Files analyzed:** 25 primary/affected files
**Analogs found:** 25 / 25

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/scoria/knowledge/scope.ex` | utility | transform, request-response guard | `lib/scoria/semantic_cache.ex`; `lib/scoria/semantic_cache/lookup.ex` | role-match |
| `lib/scoria/knowledge.ex` | service/context | CRUD, request-response | `lib/scoria/knowledge.ex`; `lib/scoria/semantic_cache.ex` | exact |
| `lib/scoria/knowledge/source.ex` | model | CRUD | `lib/scoria/knowledge/source.ex`; `lib/scoria/semantic_cache/entry.ex` | exact |
| `lib/scoria/knowledge/chunk.ex` | model | CRUD, file-I/O payload | `lib/scoria/knowledge/chunk.ex`; `lib/scoria/semantic_cache/entry.ex` | exact |
| `lib/scoria/knowledge/retrieval_run.ex` | model | request-response audit | `lib/scoria/knowledge/retrieval_run.ex`; `lib/scoria/semantic_cache/entry.ex` | exact |
| `lib/scoria/knowledge/retrieval_result.ex` | model | request-response audit | `lib/scoria/knowledge/retrieval_result.ex`; `lib/scoria/semantic_cache/entry.ex` | exact |
| `lib/scoria/knowledge/citation.ex` | model | request-response audit | `lib/scoria/knowledge/citation.ex`; `lib/scoria/semantic_cache/entry.ex` | exact |
| `lib/scoria/knowledge/grounding.ex` | utility | transform, validation | `lib/scoria/knowledge/grounding.ex`; `lib/scoria/knowledge/citation_formatter.ex` | exact |
| `lib/scoria/knowledge/backends/pgvector.ex` | service/backend | request-response retrieval | `lib/scoria/knowledge/backends/pgvector.ex`; `lib/scoria/semantic_cache/lookup.ex` | exact |
| `lib/scoria/knowledge/retrievers/scrypath.ex` | service/retriever | request-response, transform | `lib/scoria/knowledge/retrievers/scrypath.ex`; `lib/scoria/semantic_cache/lookup.ex` | exact |
| `lib/scoria/knowledge/citation_formatter.ex` | utility | transform, validation | `lib/scoria/knowledge/citation_formatter.ex`; `lib/scoria/semantic_cache/lookup.ex` | exact |
| `priv/repo/knowledge_migrations/<timestamp>_add_knowledge_tenant_scope.exs` | migration | batch schema change | `priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs`; `priv/repo/migrations/20260525070000_create_semantic_cache_tables.exs` | role-match |
| `test/scoria/knowledge/tenant_isolation_test.exs` | test | request-response, CRUD, migration proof | `test/scoria/semantic_cache_test.exs`; `test/scoria/knowledge/retrieval_test.exs`; `test/support/knowledge_case.exs` | role-match |
| `test/scoria/knowledge_lane_contract_test.exs` | test | batch contract | `test/scoria/knowledge_lane_contract_test.exs` | exact |
| `test/scoria/knowledge_test.exs` | test | CRUD | `test/scoria/knowledge_test.exs` | exact |
| `test/scoria/knowledge/retrieval_test.exs` | test | request-response retrieval | `test/scoria/knowledge/retrieval_test.exs` | exact |
| `test/scoria/knowledge/pgvector_test.exs` | test | request-response retrieval | `test/scoria/knowledge/pgvector_test.exs`; `test/scoria/semantic_cache_test.exs` | exact |
| `test/scoria/knowledge/scrypath_test.exs` | test | request-response retrieval | `test/scoria/knowledge/scrypath_test.exs` | exact |
| `test/scoria/knowledge/citation_formatter_test.exs` | test | transform, validation | `test/scoria/knowledge/citation_formatter_test.exs` | exact |
| `test/scoria/knowledge/grounding_test.exs` | test | transform, validation | `test/scoria/knowledge/grounding_test.exs` | exact |
| `test/scoria/runtime/semantic_fast_path_test.exs` | test | CRUD fixture setup | `test/scoria/runtime/semantic_fast_path_test.exs` | exact |
| `test/scoria/semantic_cache/invalidation_test.exs` | test | CRUD fixture setup | `test/scoria/semantic_cache/invalidation_test.exs` | exact |
| `README.md` | docs | batch documentation | `README.md` | exact |
| `docs/adoption_lanes.md` | docs | batch documentation | `docs/adoption_lanes.md` | exact |
| `docs/operator_verification.md` | docs | batch documentation | `docs/operator_verification.md` | exact |

Conditional UI analog, not a primary Phase 43 requirement: `lib/scoria_web/components/citation_evidence_component.ex` should be used only if the planner chooses to display Tenant / Scope / Actor evidence in the existing notebook.

## Pattern Assignments

### `lib/scoria/knowledge/scope.ex` (utility, transform/request-response guard)

**Analog:** `lib/scoria/semantic_cache.ex` plus `lib/scoria/semantic_cache/lookup.ex`

**Imports/module shape pattern** (semantic cache public context, lines 1-10):
```elixir
defmodule Scoria.SemanticCache do
  @moduledoc """
  Durable semantic-cache context for persisted reusable answers and lifecycle events.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Scoria.Repo
  alias Scoria.SemanticCache.{Compatibility, Entry, EntryEvent, Invalidation, Lookup}
```

**String-key normalization pattern** (semantic cache, lines 13-44 and 210-217):
```elixir
@known_attr_keys %{
  "actor_id" => :actor_id,
  "scope_kind" => :scope_kind,
  "tenant_id" => :tenant_id
}

defp normalize_attrs(%_{} = attrs), do: attrs |> Map.from_struct() |> normalize_attrs()
defp normalize_attrs(attrs) when is_list(attrs), do: attrs |> Enum.into(%{}) |> normalize_attrs()
defp normalize_attrs(attrs) when is_map(attrs), do: Map.new(attrs, &normalize_pair/1)
defp normalize_attrs(_attrs), do: %{}

defp normalize_pair({key, value}) when is_binary(key), do: {Map.get(@known_attr_keys, key, key), value}
defp normalize_pair({key, value}), do: {key, value}
```

**Fail-closed lower-query precedent** (semantic cache lookup, lines 83-105):
```elixir
defp base_query(attrs) do
  tenant_id = Map.fetch!(attrs, :tenant_id)
  lane_key = Map.fetch!(attrs, :lane_key)
  actor_id = Map.get(attrs, :actor_id)

  Entry
  |> where([entry], entry.tenant_id == ^tenant_id and entry.lane_key == ^lane_key)
  |> where([entry], entry.status in ^@rankable_statuses)
  |> maybe_scope_filter(actor_id)
end

defp maybe_scope_filter(query, nil) do
  where(query, [entry], entry.scope_kind == "tenant_shared")
end

defp maybe_scope_filter(query, actor_id) do
  where(
    query,
    [entry],
    entry.scope_kind == "tenant_shared" or
      (entry.scope_kind == "actor_scoped" and entry.actor_id == ^actor_id)
  )
end
```

**Implementation notes:** Make `Scoria.Knowledge.Scope` the one normalization point. Accept `scope:` plus top-level `tenant_id:`, `actor_id:`, `scope_kind:` shorthands, reject disagreement, normalize `scope_kind` to `"tenant_shared"` / `"actor_scoped"`, and raise `ArgumentError` for nil/empty tenant. Reads must use tenant-shared rows plus same-actor actor-scoped rows; missing actor must not widen visibility.

---

### `lib/scoria/knowledge.ex` (service/context, CRUD/request-response)

**Analog:** current `lib/scoria/knowledge.ex` plus semantic cache boundary validation.

**Import/alias pattern** (lines 6-21):
```elixir
import Ecto.Query, warn: false

alias Ecto.Multi
alias Scoria.Knowledge.Backends.Pgvector
alias Scoria.Knowledge.Citation
alias Scoria.Knowledge.CitationFormatter
alias Scoria.Knowledge.Chunk
alias Scoria.Knowledge.Chunker
alias Scoria.Knowledge.Embedder
alias Scoria.Knowledge.Grounding
alias Scoria.Knowledge.GroundingScore
alias Scoria.Knowledge.RetrievalResult
alias Scoria.Knowledge.RetrievalRun
alias Scoria.Knowledge.Retrievers.Scrypath
alias Scoria.Knowledge.Source
alias Scoria.Repo
```

**Source creation pattern to extend with scope** (lines 23-35):
```elixir
def create_source(attrs \\ %{}) do
  attrs =
    attrs
    |> Map.new()
    |> Map.put_new(:entity_id, Ecto.UUID.generate())
    |> Map.put_new(:version, 1)
    |> Map.put_new(:is_current, true)
    |> Map.put_new_lazy(:digest, fn -> digest_body(attrs) end)

  %Source{}
  |> Source.changeset(attrs)
  |> Repo.insert()
end
```

**Ingest transaction pattern** (lines 39-66):
```elixir
def ingest_source(%Source{} = source, opts) do
  chunker = Keyword.get(opts, :chunker, Chunker.Default)
  embedder = Keyword.get(opts, :embedder, Embedder.Deterministic)
  backend = Keyword.get(opts, :backend, Pgvector)

  chunks = chunker.chunk(source_or_payload(source, opts), opts)
  embeddings = embedder.embed_chunks(chunks, opts)

  Multi.new()
  |> Multi.delete_all(:delete_chunks, from(chunk in Chunk, where: chunk.source_id == ^source.id))
  |> Multi.run(:chunks, fn repo, _changes ->
    chunks
    |> Enum.map(&Map.put(&1, :source_id, source.id))
    |> Enum.map(fn attrs ->
      %Chunk{}
      |> Chunk.changeset(attrs)
      |> repo.insert()
    end)
    |> collect_multi_results()
  end)
  |> Multi.run(:embedded_chunks, fn _repo, %{chunks: persisted_chunks} ->
    backend.upsert_chunk_embeddings(persisted_chunks, embeddings)
  end)
  |> Repo.transaction()
```

**Retrieval boundary pattern to change** (lines 143-181):
```elixir
def retrieve(query_text, opts \\ []) do
  backend = Keyword.get(opts, :backend, Pgvector)
  retriever = Keyword.get(opts, :retriever)
  limit = Keyword.get(opts, :limit, 5)
  filters = Keyword.get(opts, :filters, %{})
  started_at = System.monotonic_time(:millisecond)

  results =
    case retriever do
      nil ->
        query_embedding =
          opts[:query_embedding] ||
            Embedder.Deterministic.embed_query(query_text, opts)

        backend.similar_chunks(query_embedding, limit: limit, filters: filters)
```

**Boundary validation precedent** (`lib/scoria/semantic_cache.ex`, lines 46-53 and 188-195):
```elixir
def lookup(attrs) when is_map(attrs) or is_list(attrs) do
  attrs = normalize_attrs(attrs)

  with :ok <- require_tenant(attrs),
       :ok <- require_lane(attrs),
       :ok <- require_query_text(attrs) do
    Lookup.lookup(attrs)
  end
end

defp require_tenant(%{tenant_id: tenant_id}) when is_binary(tenant_id) and tenant_id != "", do: :ok
defp require_tenant(_attrs), do: {:bypass, :tenant_scope_missing}
```

**Implementation notes:** Normalize `scope = Scope.new!(opts_or_attrs)` at the top of every public knowledge read/write boundary before embedding, backend calls, query construction, or inserts. Unlike semantic cache lookup, Phase 43 requires missing tenant to raise, not bypass. Carry `tenant_id`, `actor_id`, and `scope_kind` into source/chunk/citation attrs; carry `tenant_id` and `actor_id` into run/result attrs. `append_retrieval_results/2` must validate every chunk/source under the run tenant before inserting any result rows.

---

### `lib/scoria/knowledge/source.ex` (model, CRUD)

**Analog:** current `Source` schema plus `SemanticCache.Entry` scope fields.

**Current source schema/changeset shape** (lines 10-31):
```elixir
schema "ai_knowledge_sources" do
  field(:entity_id, :binary_id)
  field(:version, :integer, default: 1)
  field(:is_current, :boolean, default: true)
  field(:kind, :string)
  field(:uri, :string)
  field(:title, :string)
  field(:digest, :string)
  field(:metadata, :map, default: %{})

  has_many(:chunks, Scoria.Knowledge.Chunk)
  has_many(:citations, Scoria.Knowledge.Citation)

  timestamps(type: :utc_datetime_usec)
end

def changeset(source, attrs) do
  source
  |> cast(attrs, [:entity_id, :version, :is_current, :kind, :uri, :title, :digest, :metadata])
  |> validate_required([:entity_id, :version, :is_current, :kind, :digest])
  |> unique_constraint([:entity_id, :version])
end
```

**Scope field/changset pattern to copy** (`SemanticCache.Entry`, lines 11-18 and 46-89):
```elixir
schema "ai_semantic_cache_entries" do
  field :tenant_id, :string
  field :actor_id, :string
  field :scope_kind, :string
  field :scope_reason, :string
  field :lane_key, :string
end

def changeset(entry, attrs) do
  entry
  |> cast(attrs, [
    :tenant_id,
    :actor_id,
    :scope_kind,
    :scope_reason,
    :lane_key
  ])
  |> validate_required([
    :tenant_id,
    :scope_kind,
    :scope_reason,
    :lane_key
  ])
  |> validate_inclusion(:scope_kind, @scope_kinds)
end
```

**Implementation notes:** Add `tenant_id`, `actor_id`, `scope_kind` to source schema. New writes should validate required `tenant_id` and `scope_kind`; actor is required by the Scope helper for actor-scoped writes. Update unique constraint/index handling if same `entity_id/version` is allowed across tenants.

---

### `lib/scoria/knowledge/chunk.ex` (model, CRUD/file-I/O payload)

**Analog:** current `Chunk` schema plus `SemanticCache.Entry` scope fields.

**Current chunk schema/changeset shape** (lines 8-47):
```elixir
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
  has_many :citations, Scoria.Knowledge.Citation
end

def changeset(chunk, attrs) do
  chunk
  |> cast(attrs, [
    :source_id,
    :chunk_digest,
    :body,
    :heading_path,
    :start_offset,
    :end_offset,
    :token_count,
    :embedding,
    :metadata
  ])
  |> validate_required([
    :source_id,
    :chunk_digest,
    :body,
    :start_offset,
    :end_offset,
    :token_count
  ])
```

**Implementation notes:** Copy scope fields from source into every chunk during ingest/reingest. Direct fixture inserts must also include tenant/scope fields once changeset validation is enforced. Tenant filters must reject legacy chunks with null `tenant_id` by construction.

---

### `lib/scoria/knowledge/retrieval_run.ex` (model, request-response audit)

**Analog:** current `RetrievalRun` schema plus semantic cache audit fields.

**Current run schema/changeset shape** (lines 8-41):
```elixir
schema "ai_retrieval_runs" do
  field :query_text, :string
  field :backend, :string
  field :retriever, :string
  field :top_k, :integer, default: 5
  field :filters, :map, default: %{}
  field :trace_id, :binary_id
  field :span_id, :binary_id
  field :status, :string, default: "pending"
  field :latency_ms, :integer
  field :metadata, :map, default: %{}

  has_many :results, Scoria.Knowledge.RetrievalResult
  has_many :grounding_scores, Scoria.Knowledge.GroundingScore
end

def changeset(run, attrs) do
  run
  |> cast(attrs, [
    :query_text,
    :backend,
    :retriever,
    :top_k,
    :filters,
    :trace_id,
    :span_id,
    :status,
    :latency_ms,
    :metadata
  ])
  |> validate_required([:query_text, :backend, :top_k, :status])
end
```

**Implementation notes:** Add `tenant_id` and `actor_id`, cast both, and require tenant. `create_retrieval_run/1` should get scope from the public API path or direct attrs/options and persist the scope evidence used for retrieval.

---

### `lib/scoria/knowledge/retrieval_result.ex` (model, request-response audit)

**Analog:** current `RetrievalResult` schema plus semantic cache audit fields.

**Current result schema/changeset shape** (lines 8-36):
```elixir
schema "ai_retrieval_results" do
  field :rank, :integer
  field :score, :float
  field :metadata, :map, default: %{}
  field :backend_payload, :map, default: %{}

  belongs_to :retrieval_run, Scoria.Knowledge.RetrievalRun
  belongs_to :chunk, Scoria.Knowledge.Chunk
  belongs_to :source, Scoria.Knowledge.Source
end

def changeset(result, attrs) do
  result
  |> cast(attrs, [
    :retrieval_run_id,
    :chunk_id,
    :source_id,
    :rank,
    :score,
    :metadata,
    :backend_payload
  ])
  |> validate_required([:retrieval_run_id, :chunk_id, :source_id, :rank, :score])
```

**Implementation notes:** Add `tenant_id` and `actor_id` to the schema/changeset and require tenant. Do not trust backend result attrs for scope; derive result scope from the validated retrieval run and tenant-qualified chunk/source lookup.

---

### `lib/scoria/knowledge/citation.ex` (model, request-response audit)

**Analog:** current `Citation` schema plus semantic cache audit fields.

**Current citation schema/changeset shape** (lines 8-51):
```elixir
schema "ai_knowledge_citations" do
  field :trace_id, :binary_id
  field :span_id, :binary_id
  field :label, :string
  field :chunk_digest, :string
  field :start_offset, :integer
  field :end_offset, :integer
  field :quote, :string
  field :locator, :map, default: %{}
  field :metadata, :map, default: %{}

  belongs_to :source, Scoria.Knowledge.Source
  belongs_to :chunk, Scoria.Knowledge.Chunk
end

def changeset(citation, attrs) do
  citation
  |> cast(attrs, [
    :source_id,
    :chunk_id,
    :trace_id,
    :span_id,
    :label,
    :chunk_digest,
    :start_offset,
    :end_offset,
    :quote,
    :locator,
    :metadata
  ])
  |> validate_required([
    :source_id,
    :chunk_id,
    :label,
    :chunk_digest,
    :start_offset,
    :end_offset,
    :locator
  ])
```

**Implementation notes:** Add `tenant_id`, `actor_id`, and `scope_kind`; require tenant and scope kind for new citations. `create_citation/1` must tenant-qualify `source_id`, `chunk_id`, and `chunk_digest` before insert.

---

### `lib/scoria/knowledge/grounding.ex` (utility, transform/validation)

**Analog:** current grounding scorer and citation formatter validation.

**Current citation validation call** (lines 12-20):
```elixir
def score_citation_validity(%{citations: citations}) do
  results = Enum.map(citations, &CitationFormatter.validate_anchor/1)
  invalid = Enum.count(results, &match?({:error, _}, &1))
  total = max(length(citations), 1)
  score = (total - invalid) / total
  %{status: status(score), score: score, details: %{invalid: invalid, total: length(citations)}}
end

def score_citation_validity(_payload), do: %{status: "failed", score: 0.0, details: %{invalid: 1}}
```

**Implementation notes:** If `CitationFormatter.validate_anchor/2` becomes scope-required, update grounding to pass scope from the payload or opts. Avoid leaving an unscoped validation path that can `Repo.get(Chunk, id)` globally.

---

### `lib/scoria/knowledge/backends/pgvector.ex` (service/backend, request-response retrieval)

**Analog:** current Pgvector backend plus semantic cache tenant query.

**Current backend imports and result shape** (lines 1-6 and 18-43):
```elixir
defmodule Scoria.Knowledge.Backends.Pgvector do
  import Ecto.Query, warn: false
  import Pgvector.Ecto.Query

  alias Scoria.Knowledge.Chunk
  alias Scoria.Repo

  def similar_chunks(query_embedding, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5)
    filters = Keyword.get(opts, :filters, %{})
    source_id = Map.get(filters, :source_id) || Map.get(filters, "source_id")

    Chunk
    |> maybe_filter_source(source_id)
    |> order_by(
      [chunk],
      asc: cosine_distance(chunk.embedding, ^Pgvector.new(query_embedding))
    )
    |> limit(^limit)
    |> Repo.all()
    |> Enum.with_index(1)
    |> Enum.map(fn {chunk, rank} ->
      %{
        chunk_id: chunk.id,
        source_id: chunk.source_id,
        rank: rank,
        score: score_chunk(chunk.embedding, query_embedding),
        metadata: chunk.metadata,
        backend_payload: %{chunk_digest: chunk.chunk_digest}
      }
    end)
    |> then(&{:ok, &1})
  end
```

**Leak shape to remove** (lines 52-53):
```elixir
defp maybe_filter_source(query, nil), do: query
defp maybe_filter_source(query, source_id), do: where(query, [chunk], chunk.source_id == ^source_id)
```

**Tenant predicate pattern to copy** (`SemanticCache.Lookup`, lines 83-105):
```elixir
tenant_id = Map.fetch!(attrs, :tenant_id)
actor_id = Map.get(attrs, :actor_id)

Entry
|> where([entry], entry.tenant_id == ^tenant_id and entry.lane_key == ^lane_key)
|> maybe_scope_filter(actor_id)
```

**Implementation notes:** `similar_chunks/2` must normalize/require scope itself, apply `where(chunk.tenant_id == ^scope.tenant_id)` and visibility before source filters and before vector ordering. `source_id` remains optional narrowing only after tenant filtering.

---

### `lib/scoria/knowledge/retrievers/scrypath.ex` (service/retriever, request-response/transform)

**Analog:** current Scrypath retriever plus semantic cache tenant query.

**Current normalize/resolve pattern** (lines 7-63):
```elixir
def retrieve(query, opts \\ []) do
  results =
    cond do
      is_function(opts[:query_fun], 1) -> opts[:query_fun].(query)
      true -> opts[:results] || []
    end

  normalize_results(results)
end

def normalize_results(results) do
  results
  |> Enum.with_index(1)
  |> Enum.reduce_while({:ok, []}, fn {result, rank}, {:ok, acc} ->
    case resolve_chunk(result) do
      {:ok, chunk} ->
        normalized = %{
          chunk_id: chunk.id,
          source_id: chunk.source_id,
          chunk_digest: chunk.chunk_digest,
          rank: rank,
          score: Map.get(result, :score) || Map.get(result, "score") || 1.0,
          metadata: Map.get(result, :metadata) || Map.get(result, "metadata") || %{},
          backend_payload: Map.take(result, [:locator, :digest, :offsets])
        }
```

**Global lookup to replace** (lines 45-56):
```elixir
defp resolve_chunk(result) do
  cond do
    result[:chunk_id] && result[:source_id] ->
      {:ok, Repo.get!(Chunk, result[:chunk_id])}

    true ->
      digest = result[:chunk_digest] || get_in(result, [:locator, :chunk_digest]) || result["chunk_digest"]
      source_id = result[:source_id] || result["source_id"]

      if digest && source_id do
        case Repo.one(from chunk in Chunk, where: chunk.source_id == ^source_id and chunk.chunk_digest == ^digest) do
```

**Implementation notes:** Add `opts`/scope through `retrieve/2`, `normalize_results/2`, and `resolve_chunk/2`. Replace global `Repo.get!` and source/digest lookup with tenant-qualified queries that include `tenant_id`, source, and digest. Return errors for mismatched locators rather than raising `Repo.get!` across tenants.

---

### `lib/scoria/knowledge/citation_formatter.ex` (utility, transform/validation)

**Analog:** current citation formatter plus semantic cache tenant query.

**Current anchor validation pattern** (lines 22-39):
```elixir
def validate_anchor(anchor, repo \\ Repo) do
  case repo.get(Chunk, anchor[:chunk_id] || anchor["chunk_id"]) do
    nil ->
      {:error, %{reason: :missing_chunk}}

    chunk ->
      cond do
        chunk.chunk_digest != (anchor[:chunk_digest] || anchor["chunk_digest"]) ->
          {:error, %{reason: :digest_mismatch}}

        invalid_offsets?(chunk, anchor) ->
          {:error, %{reason: :offset_out_of_bounds}}

        true ->
          {:ok, anchor}
      end
  end
end
```

**Current anchor build shape** (lines 41-59):
```elixir
%{
  source_id: chunk.source_id,
  chunk_id: chunk.id,
  chunk_digest: chunk.chunk_digest,
  start_offset: Keyword.get(opts, :start_offset, chunk.start_offset),
  end_offset: Keyword.get(opts, :end_offset, chunk.end_offset),
  label: Keyword.get(opts, :label, "[#{index}]"),
  locator: locator
}
```

**Implementation notes:** Add scope-aware validation. Anchor building can include tenant/scope evidence from chunk/source if the chunk is preloaded, but validation must not trust anchor tenant blindly; reload chunk/source under normalized scope.

---

### `priv/repo/knowledge_migrations/<timestamp>_add_knowledge_tenant_scope.exs` (migration, batch schema change)

**Analog:** existing knowledge migration and semantic cache migration.

**Separate knowledge migration namespace** (`priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs`, lines 1-7):
```elixir
defmodule Scoria.Repo.KnowledgeMigrations.CreateKnowledgeTables do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS vector")

    create_if_not_exists table(:ai_knowledge_sources, primary_key: false) do
```

**Current knowledge tables/index style** (lines 21-45):
```elixir
create_if_not_exists unique_index(:ai_knowledge_sources, [:entity_id, :version])
create_if_not_exists index(:ai_knowledge_sources, [:entity_id])
create_if_not_exists index(:ai_knowledge_sources, [:digest])

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
end

create_if_not_exists unique_index(:ai_knowledge_chunks, [:source_id, :chunk_digest])
create_if_not_exists index(:ai_knowledge_chunks, [:source_id])
create_if_not_exists index(:ai_knowledge_chunks, [:chunk_digest])
create_if_not_exists index(:ai_knowledge_chunks, ["embedding vector_cosine_ops"], using: :hnsw)
```

**Tenant/scope field/index precedent** (`priv/repo/migrations/20260525070000_create_semantic_cache_tables.exs`, lines 5-40):
```elixir
create_if_not_exists table(:ai_semantic_cache_entries, primary_key: false) do
  add :id, :binary_id, primary_key: true
  add :tenant_id, :string, null: false
  add :actor_id, :string
  add :scope_kind, :string, null: false
  add :scope_reason, :string, null: false
  add :lane_key, :string, null: false
end

create_if_not_exists index(:ai_semantic_cache_entries, [:tenant_id])
create_if_not_exists index(:ai_semantic_cache_entries, [:tenant_id, :lane_key])
create_if_not_exists index(:ai_semantic_cache_entries, [:tenant_id, :scope_kind, :actor_id])
```

**Knowledge lane runner source** (`lib/scoria/test_support/migrations.ex`, lines 55-63):
```elixir
def migrate_knowledge! do
  previous = Code.get_compiler_option(:ignore_module_conflict)
  Code.put_compiler_option(:ignore_module_conflict, true)

  try do
    {:ok, _, _} =
      Ecto.Migrator.with_repo(KnowledgeMigrationRepo, fn repo ->
        Ecto.Migrator.run(repo, [knowledge_migrations()], :up, all: true, log: false)
      end)
```

**Implementation notes:** Add a new file under `priv/repo/knowledge_migrations/`; do not modify the historical create migration and do not use the main no-op compatibility shell. Keep new columns nullable for upgrade compatibility, enforce new-write scope in changesets/API, and add the tenant indexes from D-02.

---

### `test/scoria/knowledge/tenant_isolation_test.exs` (test, request-response/CRUD/migration proof)

**Analog:** `Scoria.KnowledgeCase`, semantic cache tenant isolation test, knowledge retrieval tests.

**Knowledge test case setup** (`test/support/knowledge_case.exs`, lines 1-27):
```elixir
defmodule Scoria.KnowledgeCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @moduletag :knowledge

      alias Scoria.Repo
      import Ecto.Query
      import Scoria.KnowledgeCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    end

    Mix.Tasks.Scoria.Pgvector.Bootstrap.ensure_pgvector!()
    :ok
  end
end
```

**Cross-tenant/actor-scoped test precedent** (`test/scoria/semantic_cache_test.exs`, lines 46-103):
```elixir
test "lookup/1 is tenant-filtered and only narrows by actor_id when scope_kind == actor_scoped" do
  assert {:ok, %{entry: shared_entry}} =
           SemanticCache.admit(%{
             tenant_id: "tenant-a",
             lane_key: "account_faq",
             scope_kind: "tenant_shared",
             scope_reason: "lane_default",
             query_text: "same question",
             answer_payload: %{"answer" => "tenant shared"}
           })

  assert {:ok, %{entry: actor_entry}} =
           SemanticCache.admit(%{
             tenant_id: "tenant-a",
             actor_id: "actor-1",
             lane_key: "account_faq",
             scope_kind: "actor_scoped",
             scope_reason: "personalized_tool",
             query_text: "same question",
             answer_payload: %{"answer" => "actor scoped"}
           })

  assert {:ok, %{entry: _other_tenant}} =
           SemanticCache.admit(%{
             tenant_id: "tenant-b",
             lane_key: "account_faq",
             scope_kind: "tenant_shared",
             scope_reason: "lane_default",
             query_text: "same question",
             answer_payload: %{"answer" => "other tenant"}
           })
```

**Knowledge retrieval test shape** (`test/scoria/knowledge/retrieval_test.exs`, lines 10-46):
```elixir
test "retrieve/2 persists RetrievalRun and ordered results" do
  assert {:ok, source} =
           Knowledge.ingest_source(%{
             kind: "doc",
             title: "retrieval",
             uri: "file:///retrieval.md",
             body: "retrieval evidence keeps every answer challengeable."
           })

  [chunk | _] = Knowledge.list_source_chunks(source.id)

  assert {:ok, %{run: %RetrievalRun{} = run, results: [result | _]}} =
           Knowledge.retrieve("challengeable answer",
             query_embedding: [0.1, 0.2, 0.3],
             filters: %{source_id: source.id},
             trace_id: trace.id,
             span_id: span.id
           )
```

**Migration/table assertion helpers** (`test/scoria/bootstrap/migration_lane_compatibility_test.exs`, lines 76-94):
```elixir
defp table_exists?(table_name) do
  %{rows: [[exists?]]} =
    Repo.query!(
      "select exists (select 1 from information_schema.tables where table_schema = current_schema() and table_name = $1)",
      [table_name]
    )

  exists?
end

defp migration_recorded?(table_name, version) do
  %{rows: rows} =
    Repo.query!(
      "select exists (select 1 from #{table_name} where version = $1)",
      [version]
    )

  rows == [[true]]
end
```

**Implementation notes:** New tests should prove missing/nil/empty tenant raises before backend calls, tenant B never appears for tenant A, actor-scoped rows are hidden when actor is missing/mismatched, backend-poison results are rejected atomically, citations reject mismatched anchors, and migration columns/indexes exist.

---

### `test/scoria/knowledge_lane_contract_test.exs` (test, batch contract)

**Analog:** current lane contract file.

**Expected file list pattern** (lines 6-13):
```elixir
@expected_files [
  "test/scoria/knowledge/citation_formatter_test.exs",
  "test/scoria/knowledge/grounding_test.exs",
  "test/scoria/knowledge/pgvector_test.exs",
  "test/scoria/knowledge/retrieval_test.exs",
  "test/scoria/knowledge/scrypath_test.exs",
  "test/scoria/knowledge_test.exs"
]
```

**Contract assertion pattern** (lines 15-30):
```elixir
test "knowledge lane file set is stable and every file uses Scoria.KnowledgeCase" do
  Mix.Task.load_all()

  assert function_exported?(Mix.Tasks.Scoria.Test.Knowledge, :knowledge_test_files, 0)

  actual = Mix.Tasks.Scoria.Test.Knowledge.knowledge_test_files()

  assert actual == @expected_files,
         "Knowledge file set changed — update @expected_files if intentional"

  for path <- actual do
    content = File.read!(path)

    assert content =~ "use Scoria.KnowledgeCase",
           "#{path} must use Scoria.KnowledgeCase to carry the :knowledge tag"
  end
end
```

**Implementation notes:** Add `test/scoria/knowledge/tenant_isolation_test.exs` to `@expected_files` in sorted order.

---

### Existing knowledge tests (`test/scoria/knowledge*.exs`)

**Analog files:** `test/scoria/knowledge_test.exs`, `test/scoria/knowledge/retrieval_test.exs`, `test/scoria/knowledge/pgvector_test.exs`, `test/scoria/knowledge/scrypath_test.exs`, `test/scoria/knowledge/citation_formatter_test.exs`, `test/scoria/knowledge/grounding_test.exs`.

**Knowledge API call sites that need scope updates**:
```elixir
# test/scoria/knowledge_test.exs lines 15-29
assert {:ok, %Source{} = source} = Knowledge.create_source(@source_attrs)
assert {:ok, %Source{} = source} = Knowledge.ingest_source(@source_attrs)
chunks = Knowledge.list_source_chunks(source.id)

# test/scoria/knowledge/pgvector_test.exs lines 32-35
assert {:ok, source} = Knowledge.ingest_source(attrs)
assert [_ | _] = Knowledge.list_source_chunks(source.id)
assert {:ok, %{results: results}} = Knowledge.retrieve("grounded retrieval", filters: %{source_id: source.id})

# test/scoria/knowledge/scrypath_test.exs lines 18-21
assert {:ok, [result]} =
         Scrypath.normalize_results([
           %{chunk_id: chunk.id, source_id: source.id, chunk_digest: chunk.chunk_digest, score: 0.9}
         ])

# test/scoria/knowledge/citation_formatter_test.exs lines 17-18
[anchor] = CitationFormatter.build_anchors([chunk], label: "[1]", locator: %{title: "citation"})
assert {:ok, _anchor} = CitationFormatter.validate_anchor(Map.put(anchor, :end_offset, 10))

# test/scoria/knowledge/grounding_test.exs lines 15-27
[chunk | _] = Knowledge.list_source_chunks(source.id)
[anchor] = Knowledge.build_citations([chunk], label: "[1]", locator: %{title: "grounding"})
assert {:ok, scores} = Knowledge.score_grounding(payload, rubric_version: "deterministic-v1")
```

**Implementation notes:** Define a local `scope` fixture/helper in each test or in the new tenant isolation test. Pass `scope:` to create/ingest/list/retrieve/reembed/reindex/citation/Scrypath calls. Add explicit raise tests for missing scope rather than preserving unscoped success paths.

---

### `test/scoria/runtime/semantic_fast_path_test.exs` (test, CRUD fixture setup)

**Analog:** current helper creates knowledge fixture rows for semantic cache source-fingerprint tests.

**Affected fixture helper** (lines 405-430):
```elixir
defp create_retrieval_run!(query_text) do
  alias Scoria.Knowledge
  alias Scoria.Knowledge.Chunk

  {:ok, source} =
    Knowledge.create_source(%{kind: "doc", digest: "digest-#{query_text}", metadata: %{}, title: "FAQ"})

  {:ok, chunk} =
    %Chunk{}
    |> Chunk.changeset(%{
      source_id: source.id,
      chunk_digest: "chunk-#{query_text}",
      body: query_text,
      start_offset: 0,
      end_offset: String.length(query_text),
      token_count: 3,
      embedding: [0.1, 0.2, 0.3]
    })
    |> Repo.insert()

  {:ok, run} = Knowledge.create_retrieval_run(%{query_text: query_text, backend: "test"})

  {:ok, _results} =
    Knowledge.append_retrieval_results(run.id, [%{chunk_id: chunk.id, source_id: source.id, rank: 1, score: 0.95}])
```

**Implementation notes:** Update fixture setup with a tenant scope matching the semantic test tenant, and include tenant/scope fields in any direct `%Chunk{}` insert if chunk changeset requires them.

---

### `test/scoria/semantic_cache/invalidation_test.exs` (test, CRUD fixture setup)

**Analog:** current source-fingerprint fixture helper.

**Affected fixture helper** (lines 132-157):
```elixir
defp seeded_source_fingerprint do
  {:ok, source} =
    Knowledge.create_source(%{kind: "doc", digest: "digest-1", metadata: %{}, title: "FAQ"})

  {:ok, chunk} =
    %Chunk{}
    |> Chunk.changeset(%{
      source_id: source.id,
      chunk_digest: "chunk-1",
      body: "Scoria answer",
      start_offset: 0,
      end_offset: 12,
      token_count: 2,
      embedding: [0.1, 0.2, 0.3]
    })
    |> Repo.insert()

  {:ok, retrieval_run} = Knowledge.create_retrieval_run(%{query_text: "what is scoria?", backend: "test"})

  {:ok, _results} =
    Knowledge.append_retrieval_results(retrieval_run.id, [
      %{chunk_id: chunk.id, source_id: source.id, rank: 1, score: 0.95}
    ])
```

**Implementation notes:** Same fixture update as semantic fast path: pass scope to public APIs and tenant fields to direct chunk inserts.

---

### Docs (`README.md`, `docs/adoption_lanes.md`, `docs/operator_verification.md`)

**Analog:** existing optional lane wording.

**README optional knowledge section** (lines 218-225):
````markdown
Optional knowledge lane:

```bash
mix scoria.pgvector.bootstrap
mix test.knowledge
```

The knowledge lane does not define first adoption. You do not need pgvector, knowledge tables, retrieval, grounding, semantic fast-path setup, or `mix test.knowledge` to prove the core runtime, identity, approval, and operator-evidence path.
````

**Adoption lane optional knowledge section** (`docs/adoption_lanes.md`, lines 122-139):
````markdown
### 4. Optional knowledge lane

Add this only when you are intentionally validating retrieval, citations, and grounding.

Choose it when:

- you need pgvector-backed retrieval
- you need citation and grounding evidence
- you are ready to own the knowledge setup in your app

Proof lane:

```bash
mix scoria.pgvector.bootstrap
mix test.knowledge
```
````

**Operator verification optional knowledge section** (`docs/operator_verification.md`, lines 162-171):
````markdown
## Optional knowledge lane

Only after the default lane is proven should you expand into the knowledge-backed path:

```bash
mix scoria.pgvector.bootstrap
mix test.knowledge
```

That lane is explicitly optional. It verifies pgvector-backed retrieval and grounding behavior after the core runtime and operator surface already work.
````

**Implementation notes:** Keep docs small and operator-facing. Add that host apps provide tenant/actor identity, knowledge retrieval/citations are tenant-scoped, missing tenant fails closed, and metadata filters are not security proof. Do not change first-adoption lane topology.

## Shared Patterns

### Scope Normalization And Validation

**Source:** `lib/scoria/semantic_cache.ex` lines 13-44, 46-53, 188-217; `lib/scoria/semantic_cache/lookup.ex` lines 83-105.
**Apply to:** `lib/scoria/knowledge/scope.ex`, `lib/scoria/knowledge.ex`, Pgvector, Scrypath, list chunks, citation validation.

Use semantic cache's key normalization and tenant visibility shape, but raise on missing tenant for knowledge APIs instead of returning `{:bypass, :tenant_scope_missing}`.

### Ecto Tenant Visibility Queries

**Source:** `lib/scoria/semantic_cache/lookup.ex` lines 83-105.
**Apply to:** `Pgvector.similar_chunks/2`, `Scrypath.resolve_chunk`, `Knowledge.list_source_chunks`, citation validation, result validation.

Copy the order: fetch required tenant, build tenant predicate first, then apply actor visibility, then apply optional source/digest filters, then order/limit.

### Schema Scope Fields

**Source:** `lib/scoria/semantic_cache/entry.ex` lines 8-18 and 46-89.
**Apply to:** source, chunk, retrieval run, retrieval result, citation schemas.

Use `@scope_kinds ~w(tenant_shared actor_scoped)`, cast scope fields, require tenant/scope on source/chunk/citation, require tenant on run/result, and validate allowed scope kinds where present.

### Multi Transaction And Atomic Result Writes

**Source:** `lib/scoria/knowledge.ex` lines 47-66 and semantic cache transaction style lines 68-84.
**Apply to:** `ingest_source/2`, `append_retrieval_results/2`, any backend-poison rejection path.

Keep multi-step writes inside `Ecto.Multi` / `Repo.transaction()`. Validate all retrieval results before inserting any result rows so a poisoned cross-tenant result set persists no mixed rows.

### Knowledge Migrations

**Source:** `priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs` lines 1-7; `lib/scoria/test_support/migrations.ex` lines 55-63.
**Apply to:** new additive migration.

Add the new migration beside the real knowledge DDL. Preserve `KnowledgeMigrationRepo` and `schema_migrations_knowledge`; do not edit the main compatibility shell.

### Knowledge Lane Tests

**Source:** `test/support/knowledge_case.exs` lines 1-27; `test/scoria/knowledge_lane_contract_test.exs` lines 6-30.
**Apply to:** all tests under `test/scoria/knowledge/`.

All knowledge-lane test files must `use Scoria.KnowledgeCase, async: false`, carry the `:knowledge` tag through the case template, and be listed in the lane contract.

### Conditional UI Evidence

**Source:** `lib/scoria_web/components/citation_evidence_component.ex` lines 1-15, 23-39; `lib/scoria_web/ui.ex` lines 1189-1209.
**Apply to:** only if UI code is touched.

```elixir
defmodule ScoriaWeb.CitationEvidenceComponent do
  use Phoenix.Component
  import ScoriaWeb.UI

  attr(:evidence, :map, required: true)
```

```elixir
<.evidence_rows rows={[{"Query", @query_text}, {"freshness", @freshness}]} />
<.evidence_rows rows={[{"locator", citation_value(citation, :locator, "unknown")}]} />
```

Use existing notebook/evidence rows for `Tenant`, `Scope`, and `Actor`; do not create a new route or design-system primitive.

## No Analog Found

None. `Scoria.Knowledge.Scope` has no exact local module, but semantic cache supplies the normalization, validation, and actor-scope visibility patterns needed for a role-match analog.

## Metadata

**Analog search scope:** `lib/scoria`, `lib/scoria_web`, `test/scoria`, `test/scoria_web`, `test/support`, `priv/repo/knowledge_migrations`, `priv/repo/migrations`, `README.md`, `docs/`.
**Files scanned:** 100+ paths via `rg --files`, targeted `rg`, and full reads for small analogs.
**Pattern extraction date:** 2026-07-05.
**Primary analogs:** current knowledge modules, semantic cache scope/query/schema/migration, existing knowledge lane tests, optional lane docs, conditional citation evidence component.
