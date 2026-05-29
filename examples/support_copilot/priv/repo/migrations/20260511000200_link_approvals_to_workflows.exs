defmodule Scoria.Repo.Migrations.LinkApprovalsToWorkflows do
  use Ecto.Migration

  def change do
    alter table(:ai_approvals) do
      add_if_not_exists :workflow_run_id, references(:ai_workflow_runs, on_delete: :delete_all, type: :binary_id)
      add_if_not_exists :step_id, references(:ai_workflow_steps, on_delete: :nilify_all, type: :binary_id)
      add_if_not_exists :checkpoint_id, references(:ai_workflow_checkpoints, on_delete: :nilify_all, type: :binary_id)
      add_if_not_exists :lock_version, :integer, null: false, default: 1
    end

    create_if_not_exists index(:ai_approvals, [:workflow_run_id])
    create_if_not_exists index(:ai_approvals, [:step_id])
    create_if_not_exists index(:ai_approvals, [:checkpoint_id])
  end
end
