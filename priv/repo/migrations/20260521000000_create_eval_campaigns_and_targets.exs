defmodule Scoria.Repo.Migrations.CreateEvalCampaignsAndTargets do
  use Ecto.Migration

  def change do
    create table(:ai_eval_campaigns, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, :string, null: false
      add :eval_spec_id, references(:ai_eval_specs, on_delete: :nothing, type: :binary_id),
        null: false

      add :status, :string, null: false, default: "queued"
      add :total_targets, :integer, null: false, default: 0
      add :queued_targets, :integer, null: false, default: 0
      add :running_targets, :integer, null: false, default: 0
      add :completed_targets, :integer, null: false, default: 0
      add :failed_targets, :integer, null: false, default: 0
      add :cancelled_targets, :integer, null: false, default: 0
      add :started_at, :utc_datetime_usec
      add :finished_at, :utc_datetime_usec
      add :last_progress_at, :utc_datetime_usec
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:ai_eval_campaigns, [:tenant_id])
    create index(:ai_eval_campaigns, [:eval_spec_id])
    create index(:ai_eval_campaigns, [:tenant_id, :status])

    create table(:ai_eval_campaign_targets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :campaign_id, references(:ai_eval_campaigns, on_delete: :delete_all, type: :binary_id),
        null: false

      add :eval_spec_id, references(:ai_eval_specs, on_delete: :nothing, type: :binary_id),
        null: false

      add :tenant_id, :string, null: false
      add :provider, :string, null: false
      add :model, :string, null: false
      add :queue, :string
      add :priority, :integer
      add :status, :string, null: false, default: "pending"
      add :started_at, :utc_datetime_usec
      add :finished_at, :utc_datetime_usec
      add :metadata, :map, null: false, default: %{}
      add :last_error, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:ai_eval_campaign_targets, [:campaign_id])
    create index(:ai_eval_campaign_targets, [:tenant_id])
    create index(:ai_eval_campaign_targets, [:eval_spec_id])
    create index(:ai_eval_campaign_targets, [:campaign_id, :status])
    create index(:ai_eval_campaign_targets, [:tenant_id, :campaign_id])

    alter table(:ai_eval_runs) do
      add :tenant_id, :string

      # Legacy eval runs predate campaign fan-out. Keep these nullable so historical rows
      # remain readable without fabricating synthetic campaign or target lineage.
      add :campaign_id, references(:ai_eval_campaigns, on_delete: :nilify_all, type: :binary_id)

      add :campaign_target_id,
          references(:ai_eval_campaign_targets, on_delete: :nilify_all, type: :binary_id)
    end

    create index(:ai_eval_runs, [:tenant_id])
    create index(:ai_eval_runs, [:campaign_id])
    create index(:ai_eval_runs, [:campaign_target_id])
    create index(:ai_eval_runs, [:tenant_id, :campaign_id])
  end
end
