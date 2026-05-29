defmodule Scoria.Repo.Migrations.ExpandAiScoresAndCreateOnlineScoreCandidates do
  use Ecto.Migration

  def up do
    alter table(:ai_scores) do
      add(:status, :string, null: false, default: "recorded")
      add(:scorer_kind, :string, null: false, default: "legacy")
      add(:scorer_version, :string)
      add(:explanation, :text)
      add(:judge_model, :string)
      add(:rubric_version, :string)
      add(:evidence_refs, :map, null: false, default: %{})
      add(:metadata, :map, null: false, default: %{})
    end

    execute("""
    UPDATE ai_scores
    SET explanation = COALESCE(explanation, reasoning),
        metadata = CASE
          WHEN metadata = '{}'::jsonb AND details IS NOT NULL THEN details
          ELSE metadata
        END
    """)

    create(index(:ai_scores, [:status]))
    create(index(:ai_scores, [:scorer_kind]))
    create(index(:ai_scores, [:eval_run_id, :status]))

    create table(:ai_online_score_candidates, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:tenant_id, :string, null: false)
      add(:trace_id, references(:ai_traces, on_delete: :nothing, type: :binary_id), null: false)

      add(
        :workflow_run_id,
        references(:ai_workflow_runs, on_delete: :nilify_all, type: :binary_id),
        null: false
      )

      add(
        :workflow_step_id,
        references(:ai_workflow_steps, on_delete: :nilify_all, type: :binary_id),
        null: false
      )

      add(:campaign_id, references(:ai_eval_campaigns, on_delete: :nilify_all, type: :binary_id))
      add(:eval_run_id, references(:ai_eval_runs, on_delete: :nilify_all, type: :binary_id))
      add(:dedupe_key, :string, null: false)
      add(:status, :string, null: false, default: "queued")
      add(:review_status, :string, null: false, default: "pending")
      add(:sampling_metadata, :map, null: false, default: %{})
      add(:score, :float)
      add(:score_status, :string)
      add(:score_explanation, :text)
      add(:scorer_kind, :string)
      add(:scorer_version, :string)
      add(:judge_model, :string)
      add(:rubric_version, :string)
      add(:evidence_refs, :map, null: false, default: %{})
      add(:promotion_snapshot, :map, null: false, default: %{})
      add(:metadata, :map, null: false, default: %{})
      add(:sampled_at, :utc_datetime_usec)
      add(:reviewed_at, :utc_datetime_usec)
      add(:promoted_at, :utc_datetime_usec)

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:ai_online_score_candidates, [:tenant_id]))
    create(index(:ai_online_score_candidates, [:trace_id]))
    create(index(:ai_online_score_candidates, [:workflow_run_id]))
    create(index(:ai_online_score_candidates, [:workflow_step_id]))
    create(index(:ai_online_score_candidates, [:campaign_id]))
    create(index(:ai_online_score_candidates, [:eval_run_id]))
    create(index(:ai_online_score_candidates, [:tenant_id, :status, :review_status]))

    create(
      unique_index(
        :ai_online_score_candidates,
        [:tenant_id, :dedupe_key],
        name: :ai_online_score_candidates_active_dedupe_idx,
        where: "review_status IN ('pending', 'in_review')"
      )
    )
  end

  def down do
    drop_if_exists(
      unique_index(:ai_online_score_candidates, [:tenant_id, :dedupe_key],
        name: :ai_online_score_candidates_active_dedupe_idx
      )
    )

    drop(table(:ai_online_score_candidates))

    drop_if_exists(index(:ai_scores, [:eval_run_id, :status]))
    drop_if_exists(index(:ai_scores, [:scorer_kind]))
    drop_if_exists(index(:ai_scores, [:status]))

    alter table(:ai_scores) do
      remove(:metadata)
      remove(:evidence_refs)
      remove(:rubric_version)
      remove(:judge_model)
      remove(:explanation)
      remove(:scorer_version)
      remove(:scorer_kind)
      remove(:status)
    end
  end
end
