defmodule Scoria.Repo.Migrations.CreateWorkflowTables do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:ai_workflow_runs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :session_id, :string
      add :root_role_id, :string, null: false
      add :status, :string, null: false, default: "running"
      add :current_step_id, :binary_id
      add :latest_checkpoint_id, :binary_id
      add :lock_version, :integer, null: false, default: 1
      add :metadata, :map, null: false, default: %{}
      add :error_envelope, :map, null: false, default: %{}
      add :started_at, :utc_datetime_usec
      add :completed_at, :utc_datetime_usec
      add :last_heartbeat_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists index(:ai_workflow_runs, [:session_id])
    create_if_not_exists index(:ai_workflow_runs, [:status])

    create_if_not_exists table(:ai_workflow_steps, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :run_id, references(:ai_workflow_runs, on_delete: :delete_all, type: :binary_id), null: false
      add :parent_step_id, references(:ai_workflow_steps, on_delete: :nilify_all, type: :binary_id)
      add :sequence, :integer, null: false
      add :kind, :string, null: false
      add :role_id, :string, null: false
      add :status, :string, null: false, default: "queued"
      add :attempt, :integer, null: false, default: 1
      add :retry_count, :integer, null: false, default: 0
      add :idempotency_key, :string
      add :handoff_input, :map, null: false, default: %{}
      add :projected_context, :map, null: false, default: %{}
      add :result_envelope, :map, null: false, default: %{}
      add :error_envelope, :map, null: false, default: %{}
      add :started_at, :utc_datetime_usec
      add :completed_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists index(:ai_workflow_steps, [:run_id])
    create_if_not_exists index(:ai_workflow_steps, [:parent_step_id])
    create_if_not_exists index(:ai_workflow_steps, [:status])
    create_if_not_exists unique_index(:ai_workflow_steps, [:run_id, :sequence])

    create_if_not_exists table(:ai_workflow_checkpoints, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :run_id, references(:ai_workflow_runs, on_delete: :delete_all, type: :binary_id), null: false
      add :step_id, references(:ai_workflow_steps, on_delete: :delete_all, type: :binary_id)
      add :sequence, :integer, null: false
      add :transition, :string, null: false
      add :status, :string, null: false
      add :snapshot, :map, null: false, default: %{}
      add :cursor, :map
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists index(:ai_workflow_checkpoints, [:run_id])
    create_if_not_exists index(:ai_workflow_checkpoints, [:step_id])
    create_if_not_exists unique_index(:ai_workflow_checkpoints, [:run_id, :sequence])

    create_if_not_exists table(:ai_workflow_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :run_id, references(:ai_workflow_runs, on_delete: :delete_all, type: :binary_id), null: false
      add :step_id, references(:ai_workflow_steps, on_delete: :delete_all, type: :binary_id)
      add :sequence, :integer, null: false
      add :event_type, :string, null: false
      add :payload, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists index(:ai_workflow_events, [:run_id])
    create_if_not_exists index(:ai_workflow_events, [:step_id])
    create_if_not_exists unique_index(:ai_workflow_events, [:run_id, :sequence])

    create_if_not_exists table(:ai_workflow_handoffs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :run_id, references(:ai_workflow_runs, on_delete: :delete_all, type: :binary_id), null: false
      add :step_id, references(:ai_workflow_steps, on_delete: :delete_all, type: :binary_id), null: false
      add :delegated_role_id, :string, null: false
      add :capability_tags, {:array, :string}, null: false, default: []
      add :status, :string, null: false, default: "pending"
      add :handoff_input, :map, null: false, default: %{}
      add :result_summary, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create_if_not_exists index(:ai_workflow_handoffs, [:run_id])
    create_if_not_exists index(:ai_workflow_handoffs, [:step_id])
    create_if_not_exists index(:ai_workflow_handoffs, [:delegated_role_id])
  end
end
