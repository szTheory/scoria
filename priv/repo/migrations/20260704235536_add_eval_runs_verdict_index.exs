defmodule Scoria.Repo.Migrations.AddEvalRunsVerdictIndex do
  use Ecto.Migration

  def up do
    create_if_not_exists(index(:ai_eval_runs, [:prompt_template_id, :status, "inserted_at DESC"]))
  end

  def down do
    drop_if_exists(index(:ai_eval_runs, [:prompt_template_id, :status, "inserted_at DESC"]))
  end
end
