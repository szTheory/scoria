defmodule Scoria.Repo.Migrations.AddReplaySafeExecutionTruth do
  use Ecto.Migration

  @run_execution_mode_constraint "ai_workflow_runs_execution_mode_check"

  def up do
    alter table(:ai_workflow_runs) do
      add_if_not_exists :source_run_id, :binary_id
      add_if_not_exists :source_checkpoint_id, :binary_id
      add_if_not_exists :execution_mode, :string, default: "live", null: false
      add_if_not_exists :replay_overrides, :map, default: %{}, null: false
    end

    execute("""
    UPDATE ai_workflow_runs
    SET execution_mode = 'replay'
    WHERE execution_mode = 'historical_stubbed'
    """)

    execute("""
    ALTER TABLE ai_workflow_runs
    DROP CONSTRAINT IF EXISTS #{@run_execution_mode_constraint}
    """)

    execute("""
    ALTER TABLE ai_workflow_runs
    ADD CONSTRAINT #{@run_execution_mode_constraint}
    CHECK (execution_mode IN ('live', 'replay'))
    """)

    create_if_not_exists index(:ai_workflow_runs, [:execution_mode])
    create_if_not_exists index(:ai_workflow_runs, [:source_run_id])
    create_if_not_exists index(:ai_workflow_runs, [:source_checkpoint_id])

    alter table(:ai_approvals) do
      add_if_not_exists :blocker_kind, :string
      add_if_not_exists :connector_id, :binary_id
      add_if_not_exists :local_tool_id, :binary_id
      add_if_not_exists :connector_label, :string
      add_if_not_exists :connector_key, :string
      add_if_not_exists :local_tool_name, :string
      add_if_not_exists :grant_status, :string
      add_if_not_exists :grant_subject_ref, :string
      add_if_not_exists :policy_outcome, :string
      add_if_not_exists :missing_scopes, {:array, :string}, default: [], null: false
      add_if_not_exists :requested_scopes, {:array, :string}, default: [], null: false
      add_if_not_exists :reason, :string
      add_if_not_exists :trace_id, :string
      add_if_not_exists :replay_allowed, :boolean, default: false, null: false
      add_if_not_exists :blocker_workflow_event_id, :binary_id
      add_if_not_exists :blocker_audit_outbox_event_id, :binary_id
      add_if_not_exists :audit_outbox_event_id, :binary_id
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

    execute("""
    UPDATE ai_approvals AS approvals
    SET replay_disposition = COALESCE(approvals.replay_disposition, 'historical_stub'),
        replay_reason_code = COALESCE(approvals.replay_reason_code, 'legacy_historical_stubbed_run'),
        source_run_id = COALESCE(approvals.source_run_id, approvals.workflow_run_id)
    FROM ai_workflow_runs AS runs
    WHERE approvals.workflow_run_id = runs.id
      AND runs.execution_mode = 'replay'
      AND approvals.replay_reason_code IS NULL
    """)

    create_if_not_exists index(:ai_approvals, [:workflow_run_id, :replay_disposition])
    create_if_not_exists index(:ai_approvals, [:source_approval_id])
    create_if_not_exists index(:ai_approvals, [:replay_idempotency_key])
  end

  def down do
    drop_if_exists index(:ai_approvals, [:replay_idempotency_key])
    drop_if_exists index(:ai_approvals, [:source_approval_id])
    drop_if_exists index(:ai_approvals, [:workflow_run_id, :replay_disposition])

    alter table(:ai_approvals) do
      remove_if_exists :replay_idempotency_key
      remove_if_exists :executed_live
      remove_if_exists :policy_key
      remove_if_exists :required_scopes
      remove_if_exists :subject_ref
      remove_if_exists :args_fingerprint
      remove_if_exists :source_audit_outbox_event_id
      remove_if_exists :source_approval_id
      remove_if_exists :source_step_id
      remove_if_exists :source_checkpoint_id
      remove_if_exists :source_run_id
      remove_if_exists :replay_reason_code
      remove_if_exists :replay_scope
      remove_if_exists :replay_disposition
      remove_if_exists :audit_outbox_event_id
      remove_if_exists :blocker_audit_outbox_event_id
      remove_if_exists :blocker_workflow_event_id
      remove_if_exists :replay_allowed
      remove_if_exists :trace_id
      remove_if_exists :reason
      remove_if_exists :requested_scopes
      remove_if_exists :missing_scopes
      remove_if_exists :policy_outcome
      remove_if_exists :grant_subject_ref
      remove_if_exists :grant_status
      remove_if_exists :local_tool_name
      remove_if_exists :connector_key
      remove_if_exists :connector_label
      remove_if_exists :local_tool_id
      remove_if_exists :connector_id
      remove_if_exists :blocker_kind
    end

    drop_if_exists index(:ai_workflow_runs, [:source_checkpoint_id])
    drop_if_exists index(:ai_workflow_runs, [:source_run_id])
    drop_if_exists index(:ai_workflow_runs, [:execution_mode])

    execute("""
    ALTER TABLE ai_workflow_runs
    DROP CONSTRAINT IF EXISTS #{@run_execution_mode_constraint}
    """)

    alter table(:ai_workflow_runs) do
      remove_if_exists :replay_overrides
      remove_if_exists :execution_mode
      remove_if_exists :source_checkpoint_id
      remove_if_exists :source_run_id
    end
  end
end
