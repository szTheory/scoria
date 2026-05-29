defmodule Scoria.Repo.Migrations.AddCanonicalIdentityToWorkflowRuns do
  use Ecto.Migration

  def change do
    alter table(:ai_workflow_runs) do
      add_if_not_exists :actor_id, :string
      add_if_not_exists :tenant_id, :string
    end

    create_if_not_exists index(:ai_workflow_runs, [:actor_id])
    create_if_not_exists index(:ai_workflow_runs, [:tenant_id])
    create_if_not_exists index(:ai_workflow_runs, [:tenant_id, :actor_id])
  end
end
