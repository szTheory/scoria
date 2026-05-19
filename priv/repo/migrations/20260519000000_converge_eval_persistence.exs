defmodule Scoria.Repo.Migrations.ConvergeEvalPersistence do
  use Ecto.Migration

  def up do
    alter table(:ai_eval_datasets) do
      add :legacy_dataset_id, :binary_id
    end

    create unique_index(:ai_eval_datasets, [:legacy_dataset_id],
             where: "legacy_dataset_id IS NOT NULL"
           )

    execute("""
    INSERT INTO ai_eval_datasets (name, version, description, tags, state, legacy_dataset_id, inserted_at, updated_at)
    SELECT d.name,
           d.version::text,
           d.description,
           ARRAY[]::varchar[],
           'sealed',
           d.id,
           d.inserted_at,
           d.updated_at
    FROM ai_datasets AS d
    ON CONFLICT (name, version) DO UPDATE
    SET legacy_dataset_id = EXCLUDED.legacy_dataset_id
    """)

    alter table(:ai_eval_dataset_items) do
      add :legacy_dataset_item_id, :binary_id
    end

    create unique_index(:ai_eval_dataset_items, [:legacy_dataset_item_id],
             where: "legacy_dataset_item_id IS NOT NULL"
           )

    execute("""
    INSERT INTO ai_eval_dataset_items (
      dataset_id,
      source_trace_id,
      input,
      expected_output,
      metadata,
      legacy_dataset_item_id,
      inserted_at,
      updated_at
    )
    SELECT datasets.id,
           NULL,
           items.input,
           items.expected_output,
           COALESCE(items.metadata, '{}'::jsonb),
           items.id,
           items.inserted_at,
           items.updated_at
    FROM ai_dataset_items AS items
    JOIN ai_eval_datasets AS datasets
      ON datasets.legacy_dataset_id = items.dataset_id
    """)

    drop_if_exists index(:ai_eval_runs, [:dataset_id])
    execute("ALTER TABLE ai_eval_runs DROP CONSTRAINT IF EXISTS ai_eval_runs_dataset_id_fkey")

    alter table(:ai_eval_runs) do
      add :canonical_dataset_id, references(:ai_eval_datasets, on_delete: :nothing), null: true
    end

    execute("""
    UPDATE ai_eval_runs AS runs
    SET canonical_dataset_id = datasets.id
    FROM ai_eval_datasets AS datasets
    WHERE datasets.legacy_dataset_id = runs.dataset_id
    """)

    execute("""
    ALTER TABLE ai_eval_runs
    ALTER COLUMN canonical_dataset_id SET NOT NULL
    """)

    alter table(:ai_eval_runs) do
      remove :dataset_id
    end

    rename table(:ai_eval_runs), :canonical_dataset_id, to: :dataset_id
    create index(:ai_eval_runs, [:dataset_id])

    drop_if_exists index(:ai_scores, [:dataset_item_id])
    execute("ALTER TABLE ai_scores DROP CONSTRAINT IF EXISTS ai_scores_dataset_item_id_fkey")

    alter table(:ai_scores) do
      add :canonical_dataset_item_id, references(:ai_eval_dataset_items, on_delete: :delete_all),
        null: true
    end

    execute("""
    UPDATE ai_scores AS scores
    SET canonical_dataset_item_id = items.id
    FROM ai_eval_dataset_items AS items
    WHERE items.legacy_dataset_item_id = scores.dataset_item_id
    """)

    execute("""
    ALTER TABLE ai_scores
    ALTER COLUMN canonical_dataset_item_id SET NOT NULL
    """)

    alter table(:ai_scores) do
      remove :dataset_item_id
    end

    rename table(:ai_scores), :canonical_dataset_item_id, to: :dataset_item_id
    create index(:ai_scores, [:dataset_item_id])

    drop table(:ai_dataset_items)
    drop table(:ai_datasets)

    alter table(:ai_eval_datasets) do
      remove :legacy_dataset_id
    end

    alter table(:ai_eval_dataset_items) do
      remove :legacy_dataset_item_id
    end
  end

  def down do
    raise Ecto.MigrationError, "irreversible migration"
  end
end
