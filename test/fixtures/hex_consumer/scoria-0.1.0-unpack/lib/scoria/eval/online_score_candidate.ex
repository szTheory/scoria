defmodule Scoria.Eval.OnlineScoreCandidate do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ~w(
    queued
    scored
    needs_review
    promotion_candidate
    approval_requested
    reviewing
    promoted
    dismissed
    superseded
  )
  @review_statuses ~w(pending in_review approved dismissed promoted)

  schema "ai_online_score_candidates" do
    field(:tenant_id, :string)
    field(:dedupe_key, :string)
    field(:status, :string, default: "queued")
    field(:review_status, :string, default: "pending")
    field(:sampling_metadata, :map, default: %{})
    field(:score, :float)
    field(:score_status, :string)
    field(:score_explanation, :string)
    field(:scorer_kind, :string)
    field(:scorer_version, :string)
    field(:judge_model, :string)
    field(:rubric_version, :string)
    field(:evidence_refs, :map, default: %{})
    field(:promotion_snapshot, :map, default: %{})
    field(:metadata, :map, default: %{})
    field(:sampled_at, :utc_datetime_usec)
    field(:reviewed_at, :utc_datetime_usec)
    field(:promoted_at, :utc_datetime_usec)

    belongs_to(:trace, Scoria.Repo.Trace)
    belongs_to(:workflow_run, Scoria.Workflows.Run)
    belongs_to(:workflow_step, Scoria.Workflows.Step)
    belongs_to(:campaign, Scoria.Eval.EvalCampaign)
    belongs_to(:eval_run, Scoria.Eval.EvalRun)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(candidate, attrs) do
    candidate
    |> cast(attrs, [
      :tenant_id,
      :trace_id,
      :workflow_run_id,
      :workflow_step_id,
      :campaign_id,
      :eval_run_id,
      :dedupe_key,
      :status,
      :review_status,
      :sampling_metadata,
      :score,
      :score_status,
      :score_explanation,
      :scorer_kind,
      :scorer_version,
      :judge_model,
      :rubric_version,
      :evidence_refs,
      :promotion_snapshot,
      :metadata,
      :sampled_at,
      :reviewed_at,
      :promoted_at
    ])
    |> validate_required([
      :tenant_id,
      :trace_id,
      :workflow_run_id,
      :workflow_step_id,
      :dedupe_key,
      :status,
      :review_status
    ])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:review_status, @review_statuses)
    |> unique_constraint(:dedupe_key, name: :ai_online_score_candidates_active_dedupe_idx)
    |> foreign_key_constraint(:trace_id)
    |> foreign_key_constraint(:workflow_run_id)
    |> foreign_key_constraint(:workflow_step_id)
    |> foreign_key_constraint(:campaign_id)
    |> foreign_key_constraint(:eval_run_id)
  end
end
