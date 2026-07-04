defmodule Scoria.Repo.Migrations.AllowNotScoredScoresWithoutScore do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE ai_scores ALTER COLUMN score DROP NOT NULL")
  end

  def down do
    execute("ALTER TABLE ai_scores ALTER COLUMN score SET NOT NULL")
  end
end
