defmodule Scoria.Repo.KnowledgeMigrations.CreateKnowledgeTables do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS vector")

    create_if_not_exists table(:ai_knowledge_sources, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entity_id, :binary_id, null: false
      add :version, :integer, null: false, default: 1
      add :is_current, :boolean, null: false, default: true
      add :kind, :string, null: false
      add :uri, :string
      add :title, :string
      add :digest, :string, null: false
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

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

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists unique_index(:ai_knowledge_chunks, [:source_id, :chunk_digest])
    create_if_not_exists index(:ai_knowledge_chunks, [:source_id])
    create_if_not_exists index(:ai_knowledge_chunks, [:chunk_digest])
    create_if_not_exists index(:ai_knowledge_chunks, ["embedding vector_cosine_ops"], using: :hnsw)

    create_if_not_exists table(:ai_retrieval_runs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :query_text, :string, null: false
      add :backend, :string, null: false
      add :retriever, :string
      add :top_k, :integer, null: false, default: 5
      add :filters, :map, null: false, default: %{}
      add :trace_id, references(:ai_traces, type: :binary_id, on_delete: :nilify_all)
      add :span_id, references(:ai_spans, type: :binary_id, on_delete: :nilify_all)
      add :status, :string, null: false, default: "pending"
      add :latency_ms, :integer
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists index(:ai_retrieval_runs, [:trace_id])
    create_if_not_exists index(:ai_retrieval_runs, [:span_id])
    create_if_not_exists index(:ai_retrieval_runs, [:backend])
    create_if_not_exists index(:ai_retrieval_runs, [:status])

    create_if_not_exists table(:ai_retrieval_results, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :retrieval_run_id,
        references(:ai_retrieval_runs, type: :binary_id, on_delete: :delete_all),
        null: false

      add :chunk_id, references(:ai_knowledge_chunks, type: :binary_id, on_delete: :nothing),
        null: false

      add :source_id, references(:ai_knowledge_sources, type: :binary_id, on_delete: :nothing),
        null: false

      add :rank, :integer, null: false
      add :score, :float, null: false
      add :metadata, :map, null: false, default: %{}
      add :backend_payload, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists index(:ai_retrieval_results, [:retrieval_run_id])
    create_if_not_exists index(:ai_retrieval_results, [:chunk_id])
    create_if_not_exists index(:ai_retrieval_results, [:source_id])
    create_if_not_exists index(:ai_retrieval_results, [:rank])
    create_if_not_exists index(:ai_retrieval_results, [:score])

    create_if_not_exists table(:ai_knowledge_citations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :source_id, references(:ai_knowledge_sources, type: :binary_id, on_delete: :nothing),
        null: false

      add :chunk_id, references(:ai_knowledge_chunks, type: :binary_id, on_delete: :nothing),
        null: false

      add :trace_id, references(:ai_traces, type: :binary_id, on_delete: :nilify_all)
      add :span_id, references(:ai_spans, type: :binary_id, on_delete: :nilify_all)
      add :label, :string, null: false
      add :chunk_digest, :string, null: false
      add :start_offset, :integer, null: false
      add :end_offset, :integer, null: false
      add :quote, :text
      add :locator, :map, null: false, default: %{}
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists index(:ai_knowledge_citations, [:source_id])
    create_if_not_exists index(:ai_knowledge_citations, [:chunk_id])
    create_if_not_exists index(:ai_knowledge_citations, [:trace_id])
    create_if_not_exists index(:ai_knowledge_citations, [:span_id])

    create_if_not_exists table(:ai_grounding_scores, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :retrieval_run_id,
        references(:ai_retrieval_runs, type: :binary_id, on_delete: :delete_all)

      add :citation_id, references(:ai_knowledge_citations, type: :binary_id, on_delete: :nilify_all)
      add :scorer_kind, :string, null: false
      add :rubric_version, :string, null: false
      add :model, :string
      add :prompt_version, :string
      add :score, :float, null: false
      add :status, :string, null: false, default: "passed"
      add :reasoning, :text
      add :details, :map, null: false, default: %{}
      add :evidence_refs, :map, null: false, default: %{}
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists index(:ai_grounding_scores, [:retrieval_run_id])
    create_if_not_exists index(:ai_grounding_scores, [:citation_id])
    create_if_not_exists index(:ai_grounding_scores, [:scorer_kind])
    create_if_not_exists index(:ai_grounding_scores, [:rubric_version])
    create_if_not_exists index(:ai_grounding_scores, [:score])
  end
end
