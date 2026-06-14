defmodule Scoria.Repo.Migrations.ExpandAiScoresAndCreateOnlineScoreCandidates do
  use Ecto.Migration

  def up do
    # Use add_if_not_exists throughout — a now-deleted interim migration may have already
    # applied some of these columns to ai_scores on existing dev databases.
    alter table(:ai_scores) do
      add_if_not_exists(:status, :string, null: false, default: "recorded")
      add_if_not_exists(:scorer_kind, :string, null: false, default: "legacy")
      add_if_not_exists(:scorer_version, :string)
      add_if_not_exists(:explanation, :text)
      add_if_not_exists(:judge_model, :string)
      add_if_not_exists(:rubric_version, :string)
      add_if_not_exists(:evidence_refs, :map, null: false, default: %{})
      add_if_not_exists(:metadata, :map, null: false, default: %{})
    end

    # Backfill explanation from reasoning column if both exist; skip gracefully if
    # reasoning/details were already removed by a deleted interim migration.
    execute("""
    DO $$
    BEGIN
      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'ai_scores' AND column_name = 'reasoning'
      ) THEN
        UPDATE ai_scores
        SET explanation = COALESCE(explanation, reasoning);
      END IF;
      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'ai_scores' AND column_name = 'details'
      ) THEN
        UPDATE ai_scores
        SET metadata = CASE
          WHEN metadata = '{}'::jsonb AND details IS NOT NULL THEN details
          ELSE metadata
        END;
      END IF;
    END
    $$;
    """)

    create_if_not_exists(index(:ai_scores, [:status]))
    create_if_not_exists(index(:ai_scores, [:scorer_kind]))
    create_if_not_exists(index(:ai_scores, [:eval_run_id, :status]))

    create_if_not_exists table(:ai_online_score_candidates, primary_key: false) do
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

    create_if_not_exists(index(:ai_online_score_candidates, [:tenant_id]))
    create_if_not_exists(index(:ai_online_score_candidates, [:trace_id]))
    create_if_not_exists(index(:ai_online_score_candidates, [:workflow_run_id]))
    create_if_not_exists(index(:ai_online_score_candidates, [:workflow_step_id]))
    create_if_not_exists(index(:ai_online_score_candidates, [:campaign_id]))
    create_if_not_exists(index(:ai_online_score_candidates, [:eval_run_id]))
    create_if_not_exists(index(:ai_online_score_candidates, [:tenant_id, :status, :review_status]))

    create_if_not_exists(
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

    drop_if_exists(table(:ai_online_score_candidates))

    drop_if_exists(index(:ai_scores, [:eval_run_id, :status]))
    drop_if_exists(index(:ai_scores, [:scorer_kind]))
    drop_if_exists(index(:ai_scores, [:status]))

    alter table(:ai_scores) do
      remove_if_exists(:metadata, :map)
      remove_if_exists(:evidence_refs, :map)
      remove_if_exists(:rubric_version, :string)
      remove_if_exists(:judge_model, :string)
      remove_if_exists(:explanation, :text)
      remove_if_exists(:scorer_version, :string)
      remove_if_exists(:scorer_kind, :string)
      remove_if_exists(:status, :string)
    end
  end
end
