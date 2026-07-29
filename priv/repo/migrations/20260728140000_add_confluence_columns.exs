defmodule Scoria.Repo.Migrations.AddConfluenceColumns do
  use Ecto.Migration

  # Consolidated confluence-gate migration (D-15, D-26, D-45, D-47, D-50).
  # Copied into host repos by `ApplyExecutor.copy_missing_migrations!/2` --
  # the house-style if-not-exists column helpers are used throughout so a
  # partially-applied host repo is safe.
  #
  # `ai_workflow_runs.confluence_legs` (D-15): the per-run leg accumulator.
  # `null: false, default: %{}` is LOAD-BEARING, not stylistic -- in
  # Postgres `'{"a":1}'::jsonb || NULL` evaluates to `NULL`, so a nullable
  # column with no default would make the accumulator permanently dead for
  # every pre-migration row, silently.
  #
  # `ai_approvals.consumed_at` / `consumed_by_step_id` (D-26): the
  # approval-consume CAS pair that prevents `resume_run/1` from
  # re-escalating the identical tool call forever.
  #
  # `ai_approvals.confluence_scope` (D-50, checkpoint-resolved
  # `d50-scope`): the bounded per-run/per-tool/per-grade approval scope.
  # Two permitted values, `"call"` and `"run_tool"`; `NULL` means `"call"`.
  # No CHECK constraint -- validated at the application layer, matching the
  # existing `:status`/`:blocker_kind` string-column convention on this
  # table (no DB-level enum for those either).
  #
  # `ai_audit_outbox_events` `event_type` index (D-45): there is no
  # `event_type` index today, so the D-40 auditor query (every trifecta
  # firing joined to its approval) is currently a sequential scan.
  #
  # No backfill of any kind: all three new/altered defaults are
  # catalog-only (Postgres `ADD COLUMN ... DEFAULT <constant>` never
  # rewrites existing rows).
  #
  # Never edit this file after release; corrections ship as a new migration.
  def up do
    alter table(:ai_workflow_runs) do
      add_if_not_exists :confluence_legs, :map, null: false, default: %{}
    end

    alter table(:ai_approvals) do
      add_if_not_exists :consumed_at, :utc_datetime_usec
      add_if_not_exists :consumed_by_step_id, :binary_id
      add_if_not_exists :confluence_scope, :string
    end

    create_if_not_exists index(:ai_audit_outbox_events, [:tenant_id, :event_type, "inserted_at DESC"])
  end

  def down do
    drop_if_exists index(:ai_audit_outbox_events, [:tenant_id, :event_type, "inserted_at DESC"])

    alter table(:ai_approvals) do
      remove_if_exists :confluence_scope
      remove_if_exists :consumed_by_step_id
      remove_if_exists :consumed_at
    end

    alter table(:ai_workflow_runs) do
      remove_if_exists :confluence_legs
    end
  end
end
