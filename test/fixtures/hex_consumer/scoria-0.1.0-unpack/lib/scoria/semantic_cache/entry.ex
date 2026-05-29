defmodule Scoria.SemanticCache.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(active stale writeback_rejected invalidated)
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
    field :query_text, :string
    field :query_embedding, Pgvector.Ecto.Vector
    field :answer_payload, :map, default: %{}
    field :evidence_refs, :map, default: %{}
    field :policy_fingerprint, :string
    field :source_fingerprint, :string
    field :status, :string, default: "active"
    field :state_reason_code, :string
    field :last_hit_at, :utc_datetime_usec
    field :hit_count, :integer, default: 0
    field :expires_at, :utc_datetime_usec
    field :invalidated_at, :utc_datetime_usec
    field :metadata, :map, default: %{}

    belongs_to :origin_run, Scoria.Workflows.Run, foreign_key: :origin_run_id
    belongs_to :origin_span, Scoria.Repo.Span, foreign_key: :origin_span_id
    belongs_to :origin_retrieval_run, Scoria.Knowledge.RetrievalRun, foreign_key: :origin_retrieval_run_id

    has_many :events, Scoria.SemanticCache.EntryEvent, foreign_key: :entry_id

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [
      :tenant_id,
      :actor_id,
      :scope_kind,
      :scope_reason,
      :lane_key,
      :lane_module,
      :policy_key,
      :prompt_ref,
      :prompt_version,
      :provider,
      :model,
      :query_text,
      :query_embedding,
      :answer_payload,
      :evidence_refs,
      :policy_fingerprint,
      :source_fingerprint,
      :origin_run_id,
      :origin_span_id,
      :origin_retrieval_run_id,
      :status,
      :state_reason_code,
      :last_hit_at,
      :hit_count,
      :expires_at,
      :invalidated_at,
      :metadata
    ])
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
  end
end
