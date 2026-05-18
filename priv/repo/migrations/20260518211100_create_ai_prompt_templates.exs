defmodule Scoria.Repo.Migrations.CreateAiPromptTemplates do
  use Ecto.Migration

  def change do
    create table(:ai_prompt_templates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entity_id, :binary_id, null: false
      add :version, :integer, null: false, default: 1
      add :is_current, :boolean, null: false, default: true
      add :status, :string, null: false, default: "draft"
      add :system_message, :text
      add :few_shot_examples, :map
      add :user_template, :text
      add :estimated_tokens, :integer

      timestamps(type: :utc_datetime_usec)
    end

    create index(:ai_prompt_templates, [:entity_id, :version], unique: true)
    create index(:ai_prompt_templates, [:entity_id])
  end
end
