defmodule Scoria.Repo.Migrations.AddDatasetItemCapturedOutput do
  use Ecto.Migration

  def up do
    alter table(:ai_eval_dataset_items) do
      add_if_not_exists(:captured_output, :map)
      add_if_not_exists(:captured_output_sha256, :string)
      add_if_not_exists(:captured_at, :utc_datetime_usec)
    end
  end

  def down do
    alter table(:ai_eval_dataset_items) do
      remove_if_exists(:captured_at, :utc_datetime_usec)
      remove_if_exists(:captured_output_sha256, :string)
      remove_if_exists(:captured_output, :map)
    end
  end
end
