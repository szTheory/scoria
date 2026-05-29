defmodule Scoria.Repo.Migrations.CreateSemanticCacheTables do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:ai_semantic_cache_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, :string, null: false
      add :actor_id, :string
      add :scope_kind, :string, null: false
      add :scope_reason, :string, null: false
      add :lane_key, :string, null: false
      add :lane_module, :string
      add :policy_key, :string
      add :prompt_ref, :string
      add :prompt_version, :string
      add :provider, :string
      add :model, :string
      add :query_text, :text, null: false
      add :query_embedding, :binary
      add :answer_payload, :map, null: false, default: %{}
      add :evidence_refs, :map, null: false, default: %{}
      add :source_fingerprint, :string
      add :origin_run_id, references(:ai_workflow_runs, type: :binary_id, on_delete: :nilify_all)
      add :origin_span_id, references(:ai_spans, type: :binary_id, on_delete: :nilify_all)
      add :origin_retrieval_run_id,
          references(:ai_retrieval_runs, type: :binary_id, on_delete: :nilify_all)

      add :status, :string, null: false, default: "active"
      add :last_hit_at, :utc_datetime_usec
      add :hit_count, :integer, null: false, default: 0
      add :expires_at, :utc_datetime_usec
      add :invalidated_at, :utc_datetime_usec
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists index(:ai_semantic_cache_entries, [:tenant_id])
    create_if_not_exists index(:ai_semantic_cache_entries, [:tenant_id, :lane_key])
    create_if_not_exists index(:ai_semantic_cache_entries, [:tenant_id, :scope_kind, :actor_id])
    create_if_not_exists index(:ai_semantic_cache_entries, [:status])

    create_if_not_exists table(:ai_semantic_cache_entry_events, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :entry_id, references(:ai_semantic_cache_entries, type: :binary_id, on_delete: :delete_all),
        null: false

      add :event_kind, :string, null: false
      add :reason_code, :string
      add :workflow_run_id, references(:ai_workflow_runs, type: :binary_id, on_delete: :nilify_all)
      add :span_id, references(:ai_spans, type: :binary_id, on_delete: :nilify_all)
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists index(:ai_semantic_cache_entry_events, [:entry_id])
  end
end
