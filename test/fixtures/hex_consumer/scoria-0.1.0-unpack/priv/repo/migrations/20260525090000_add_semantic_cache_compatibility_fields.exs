defmodule Scoria.Repo.Migrations.AddSemanticCacheCompatibilityFields do
  use Ecto.Migration

  def change do
    execute(
      """
      ALTER TABLE ai_semantic_cache_entries
      ALTER COLUMN query_embedding TYPE vector(3)
      USING NULL
      """,
      """
      ALTER TABLE ai_semantic_cache_entries
      ALTER COLUMN query_embedding TYPE bytea
      USING NULL
      """
    )

    alter table(:ai_semantic_cache_entries) do
      add :policy_fingerprint, :string
      add :state_reason_code, :string
    end

    create_if_not_exists index(:ai_semantic_cache_entries, [:tenant_id, :lane_key, :query_text])

    create_if_not_exists index(:ai_semantic_cache_entries, [
                           :tenant_id,
                           :lane_key,
                           :prompt_ref,
                           :prompt_version,
                           :policy_fingerprint,
                           :source_fingerprint
                         ])

    create_if_not_exists index(:ai_semantic_cache_entries, [:status, :expires_at])
  end
end
