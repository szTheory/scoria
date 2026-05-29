defmodule Scoria.Repo.Migrations.CreateAiEvalDatasets do
  use Ecto.Migration

  def change do
    create table(:ai_eval_datasets) do
      add :name, :string, null: false
      add :version, :string, null: false
      add :description, :string
      add :tags, {:array, :string}, default: []
      add :state, :string, default: "open", null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:ai_eval_datasets, [:name, :version])

    create table(:ai_eval_dataset_items) do
      add :dataset_id, references(:ai_eval_datasets, on_delete: :delete_all), null: false
      add :source_trace_id, :string
      add :input, :map, null: false
      add :expected_output, :map
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:ai_eval_dataset_items, [:dataset_id])
    create index(:ai_eval_dataset_items, [:source_trace_id])
  end
end
