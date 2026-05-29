defmodule Scoria.Repo.Migrations.AddDelegatedKindToWorkflowHandoffs do
  use Ecto.Migration

  def change do
    alter table(:ai_workflow_handoffs) do
      add(:delegated_kind, :string, null: false, default: "handoff")
    end
  end
end
