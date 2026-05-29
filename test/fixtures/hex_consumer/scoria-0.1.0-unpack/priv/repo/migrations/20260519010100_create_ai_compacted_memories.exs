defmodule Scoria.Repo.Migrations.CreateAiCompactedMemories do
  use Ecto.Migration

  def change do
    # execute("CREATE EXTENSION IF NOT EXISTS vector")

    create_if_not_exists table(:ai_compacted_memories, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:run_id, references(:ai_workflow_runs, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      add(:session_id, :string, null: false)
      add(:start_sequence, :integer, null: false)
      add(:end_sequence, :integer, null: false)
      add(:summary_text, :text, null: false)
      # Use :binary for embedding to allow storage in environments without pgvector
      add(:embedding, :binary)
      add(:token_count, :integer, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists(index(:ai_compacted_memories, [:run_id]))
    create_if_not_exists(index(:ai_compacted_memories, [:session_id]))
    create_if_not_exists(index(:ai_compacted_memories, [:start_sequence, :end_sequence]))

    # create_if_not_exists(
    #   index(:ai_compacted_memories, ["embedding vector_cosine_ops"], using: :hnsw)
    # )
  end
end
