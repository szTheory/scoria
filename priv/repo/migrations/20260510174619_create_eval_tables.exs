defmodule Scoria.Repo.Migrations.CreateEvalTables do
  use Ecto.Migration

  def change do
    create table(:ai_datasets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entity_id, :binary_id, null: false
      add :version, :integer, null: false, default: 1
      add :is_current, :boolean, null: false, default: true
      add :name, :string, null: false
      add :description, :text

      timestamps(type: :utc_datetime_usec)
    end

    create index(:ai_datasets, [:entity_id, :version], unique: true)
    create index(:ai_datasets, [:entity_id])

    create table(:ai_dataset_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :dataset_id, references(:ai_datasets, on_delete: :delete_all, type: :binary_id), null: false
      add :input, :map, null: false
      add :expected_output, :map
      add :metadata, :map

      timestamps(type: :utc_datetime_usec)
    end

    create index(:ai_dataset_items, [:dataset_id])

    create table(:ai_eval_specs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entity_id, :binary_id, null: false
      add :version, :integer, null: false, default: 1
      add :is_current, :boolean, null: false, default: true
      add :name, :string, null: false
      add :description, :text
      add :rubric, :map, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:ai_eval_specs, [:entity_id, :version], unique: true)
    create index(:ai_eval_specs, [:entity_id])

    create table(:ai_eval_runs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :dataset_id, references(:ai_datasets, on_delete: :nothing, type: :binary_id), null: false
      add :eval_spec_id, references(:ai_eval_specs, on_delete: :nothing, type: :binary_id), null: false
      add :status, :string, null: false, default: "pending"
      add :duration_ms, :integer

      timestamps(type: :utc_datetime_usec)
    end

    create index(:ai_eval_runs, [:dataset_id])
    create index(:ai_eval_runs, [:eval_spec_id])

    create table(:ai_scores, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :eval_run_id, references(:ai_eval_runs, on_delete: :delete_all, type: :binary_id), null: false
      add :dataset_item_id, references(:ai_dataset_items, on_delete: :delete_all, type: :binary_id), null: false
      add :score, :float, null: false
      add :reasoning, :text
      add :details, :map

      timestamps(type: :utc_datetime_usec)
    end

    create index(:ai_scores, [:eval_run_id])
    create index(:ai_scores, [:dataset_item_id])
  end
end
