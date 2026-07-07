defmodule Scoria.Repo.KnowledgeMigrations.AddKnowledgeTenantScope do
  use Ecto.Migration

  def up do
    drop_if_exists(unique_index(:ai_knowledge_sources, [:entity_id, :version]))

    alter table(:ai_knowledge_sources) do
      add(:tenant_id, :string)
      add(:actor_id, :string)
      add(:scope_kind, :string)
    end

    alter table(:ai_knowledge_chunks) do
      add(:tenant_id, :string)
      add(:actor_id, :string)
      add(:scope_kind, :string)
    end

    alter table(:ai_retrieval_runs) do
      add(:tenant_id, :string)
      add(:actor_id, :string)
    end

    alter table(:ai_retrieval_results) do
      add(:tenant_id, :string)
      add(:actor_id, :string)
    end

    alter table(:ai_knowledge_citations) do
      add(:tenant_id, :string)
      add(:actor_id, :string)
      add(:scope_kind, :string)
    end

    create_if_not_exists(
      index(:ai_knowledge_sources, [:tenant_id], name: :ai_knowledge_sources_tenant_id_index)
    )

    create_if_not_exists(
      unique_index(:ai_knowledge_sources, [:tenant_id, :entity_id, :version],
        name: :ai_knowledge_sources_tenant_entity_version_index,
        where: "tenant_id IS NOT NULL"
      )
    )

    create_if_not_exists(
      index(:ai_knowledge_chunks, [:tenant_id], name: :ai_knowledge_chunks_tenant_id_index)
    )

    create_if_not_exists(
      index(:ai_knowledge_chunks, [:tenant_id, :source_id],
        name: :ai_knowledge_chunks_tenant_source_id_index
      )
    )

    create_if_not_exists(
      index(:ai_retrieval_runs, [:tenant_id, :status, :inserted_at],
        name: :ai_retrieval_runs_tenant_status_inserted_at_index
      )
    )

    create_if_not_exists(
      index(:ai_retrieval_results, [:tenant_id, :retrieval_run_id, :rank],
        name: :ai_retrieval_results_tenant_run_rank_index
      )
    )

    create_if_not_exists(
      index(:ai_knowledge_citations, [:tenant_id, :source_id],
        name: :ai_knowledge_citations_tenant_source_id_index
      )
    )

    create_if_not_exists(
      index(:ai_knowledge_citations, [:tenant_id, :chunk_id],
        name: :ai_knowledge_citations_tenant_chunk_id_index
      )
    )
  end

  def down do
    drop_if_exists(
      index(:ai_knowledge_citations, [:tenant_id, :chunk_id],
        name: :ai_knowledge_citations_tenant_chunk_id_index
      )
    )

    drop_if_exists(
      index(:ai_knowledge_citations, [:tenant_id, :source_id],
        name: :ai_knowledge_citations_tenant_source_id_index
      )
    )

    drop_if_exists(
      index(:ai_retrieval_results, [:tenant_id, :retrieval_run_id, :rank],
        name: :ai_retrieval_results_tenant_run_rank_index
      )
    )

    drop_if_exists(
      index(:ai_retrieval_runs, [:tenant_id, :status, :inserted_at],
        name: :ai_retrieval_runs_tenant_status_inserted_at_index
      )
    )

    drop_if_exists(
      index(:ai_knowledge_chunks, [:tenant_id, :source_id],
        name: :ai_knowledge_chunks_tenant_source_id_index
      )
    )

    drop_if_exists(
      index(:ai_knowledge_chunks, [:tenant_id], name: :ai_knowledge_chunks_tenant_id_index)
    )

    drop_if_exists(
      unique_index(:ai_knowledge_sources, [:tenant_id, :entity_id, :version],
        name: :ai_knowledge_sources_tenant_entity_version_index
      )
    )

    drop_if_exists(
      index(:ai_knowledge_sources, [:tenant_id], name: :ai_knowledge_sources_tenant_id_index)
    )

    alter table(:ai_knowledge_citations) do
      remove(:scope_kind)
      remove(:actor_id)
      remove(:tenant_id)
    end

    alter table(:ai_retrieval_results) do
      remove(:actor_id)
      remove(:tenant_id)
    end

    alter table(:ai_retrieval_runs) do
      remove(:actor_id)
      remove(:tenant_id)
    end

    alter table(:ai_knowledge_chunks) do
      remove(:scope_kind)
      remove(:actor_id)
      remove(:tenant_id)
    end

    alter table(:ai_knowledge_sources) do
      remove(:scope_kind)
      remove(:actor_id)
      remove(:tenant_id)
    end

    create_if_not_exists(unique_index(:ai_knowledge_sources, [:entity_id, :version]))
  end
end
