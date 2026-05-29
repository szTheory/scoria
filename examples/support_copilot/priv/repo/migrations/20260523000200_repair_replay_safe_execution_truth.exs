defmodule Scoria.Repo.Migrations.RepairReplaySafeExecutionTruth do
  use Ecto.Migration

  def change do
    alter table(:ai_approvals) do
      add_if_not_exists :reason, :string
      add_if_not_exists :trace_id, :string
      add_if_not_exists :replay_disposition, :string
      add_if_not_exists :replay_scope, :string
      add_if_not_exists :replay_reason_code, :string
      add_if_not_exists :source_run_id, :binary_id
      add_if_not_exists :source_checkpoint_id, :binary_id
      add_if_not_exists :source_step_id, :binary_id
      add_if_not_exists :source_approval_id, :binary_id
      add_if_not_exists :source_audit_outbox_event_id, :binary_id
      add_if_not_exists :args_fingerprint, :string
      add_if_not_exists :subject_ref, :string
      add_if_not_exists :required_scopes, {:array, :string}, default: [], null: false
      add_if_not_exists :policy_key, :string
      add_if_not_exists :executed_live, :boolean, default: false, null: false
      add_if_not_exists :replay_idempotency_key, :string
    end

    create_if_not_exists index(:ai_approvals, [:workflow_run_id, :replay_disposition])
    create_if_not_exists index(:ai_approvals, [:source_approval_id])
    create_if_not_exists index(:ai_approvals, [:replay_idempotency_key])

    alter table(:ai_workflow_checkpoints) do
      add_if_not_exists :replay_disposition, :string
      add_if_not_exists :replay_reason_code, :string
    end

    create_if_not_exists index(:ai_workflow_checkpoints, [:replay_disposition])

    alter table(:ai_workflow_events) do
      add_if_not_exists :replay_disposition, :string
      add_if_not_exists :replay_reason_code, :string
    end

    create_if_not_exists index(:ai_workflow_events, [:replay_disposition])

    alter table(:ai_audit_outbox_events) do
      add_if_not_exists :replay_disposition, :string
      add_if_not_exists :replay_reason_code, :string
      add_if_not_exists :source_run_id, :binary_id
      add_if_not_exists :source_checkpoint_id, :binary_id
      add_if_not_exists :source_step_id, :binary_id
      add_if_not_exists :source_approval_id, :binary_id
      add_if_not_exists :source_audit_outbox_event_id, :binary_id
      add_if_not_exists :args_fingerprint, :string
      add_if_not_exists :policy_key, :string
      add_if_not_exists :executed_live, :boolean, default: false, null: false
      add_if_not_exists :replay_idempotency_key, :string
    end

    create_if_not_exists index(:ai_audit_outbox_events, [:replay_disposition])
    create_if_not_exists index(:ai_audit_outbox_events, [:replay_idempotency_key])
  end
end
