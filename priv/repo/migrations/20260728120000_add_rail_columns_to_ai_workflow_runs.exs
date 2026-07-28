defmodule Scoria.Repo.Migrations.AddRailColumnsToAiWorkflowRuns do
  use Ecto.Migration

  # Per-run rails (RAIL-01, 56.1-01 D-07). Copied into host repos by
  # `ApplyExecutor.copy_missing_migrations!/2` -- the house-style
  # if-not-exists column helpers are used throughout so a partially-applied
  # host repo is safe.
  # No index: `index(:ai_workflow_runs, [:status])` already exists and the
  # composite this phase considered existed only to serve `sweep/1`, which is
  # cut (see 56.1-CONTEXT.md D-07, <deferred>). No CHECK constraint: the three
  # `rail_max_*` limits are validated by `validate_number/2` in
  # `Run.changeset/2` instead (planner discretion 1). No backfill: Postgres
  # `ADD COLUMN ... DEFAULT <constant>` is catalog-only, so existing rows read
  # `0` counters and `NULL` limits, and `NULL` means unlimited -- preserving
  # today's behaviour (SC#3).
  #
  # Never edit this file after release; corrections ship as a new migration.
  def up do
    alter table(:ai_workflow_runs) do
      add_if_not_exists :rail_max_steps, :integer
      add_if_not_exists :rail_max_tool_calls, :integer
      add_if_not_exists :rail_max_active_ms, :bigint
      add_if_not_exists :rail_steps, :bigint, null: false, default: 0
      add_if_not_exists :rail_tool_calls, :bigint, null: false, default: 0
      add_if_not_exists :rail_paused_ms, :bigint, null: false, default: 0
      add_if_not_exists :rail_paused_at, :utc_datetime_usec
    end
  end

  def down do
    alter table(:ai_workflow_runs) do
      remove_if_exists :rail_paused_at
      remove_if_exists :rail_paused_ms
      remove_if_exists :rail_tool_calls
      remove_if_exists :rail_steps
      remove_if_exists :rail_max_active_ms
      remove_if_exists :rail_max_tool_calls
      remove_if_exists :rail_max_steps
    end
  end
end
