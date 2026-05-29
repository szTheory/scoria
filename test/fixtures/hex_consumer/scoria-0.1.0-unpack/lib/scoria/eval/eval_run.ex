defmodule Scoria.Eval.EvalRun do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_eval_runs" do
    field(:runner_mode, Ecto.Enum, values: [:offline_replay, :live_judge, :refresh_capture])
    field(:status, :string, default: "pending")
    field(:tenant_id, :string)
    field(:duration_ms, :integer)
    field(:prompt_template_id, :binary_id)
    field(:prompt_version, :integer)
    field(:dataset_version, :string)
    field(:eval_spec_version, :integer)
    field(:provider, :string)
    field(:model, :string)
    field(:judge_provider, :string)
    field(:judge_model, :string)
    field(:fixture_key, :string)
    field(:fixture_path, :string)
    field(:fixture_sha256, :string)
    field(:total_items, :integer)
    field(:passed_items, :integer)
    field(:failed_items, :integer)
    field(:avg_latency_ms, :integer)
    field(:total_cost_usd, :decimal)
    field(:threshold_verdict, :string)
    field(:baseline_eval_run_id, :binary_id)

    belongs_to(:dataset, Scoria.Eval.Dataset, type: :id)
    belongs_to(:eval_spec, Scoria.Eval.EvalSpec)
    belongs_to(:campaign, Scoria.Eval.EvalCampaign)
    belongs_to(:campaign_target, Scoria.Eval.EvalCampaignTarget)

    has_many(:scores, Scoria.Eval.Score)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(eval_run, attrs) do
    eval_run
    |> cast(attrs, [
      :runner_mode,
      :status,
      :tenant_id,
      :duration_ms,
      :prompt_template_id,
      :prompt_version,
      :dataset_id,
      :dataset_version,
      :eval_spec_id,
      :eval_spec_version,
      :provider,
      :model,
      :judge_provider,
      :judge_model,
      :fixture_key,
      :fixture_path,
      :fixture_sha256,
      :total_items,
      :passed_items,
      :failed_items,
      :avg_latency_ms,
      :total_cost_usd,
      :threshold_verdict,
      :baseline_eval_run_id,
      :campaign_id,
      :campaign_target_id
    ])
    |> validate_required([
      :runner_mode,
      :status,
      :dataset_id,
      :dataset_version,
      :eval_spec_id,
      :eval_spec_version
    ])
    |> validate_inclusion(:status, ["pending", "running", "completed", "failed"])
    |> validate_number(:prompt_version, greater_than: 0)
    |> validate_number(:eval_spec_version, greater_than: 0)
    |> validate_number(:total_items, greater_than_or_equal_to: 0)
    |> validate_number(:passed_items, greater_than_or_equal_to: 0)
    |> validate_number(:failed_items, greater_than_or_equal_to: 0)
    |> validate_number(:avg_latency_ms, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:dataset_id)
    |> foreign_key_constraint(:eval_spec_id)
    |> foreign_key_constraint(:campaign_id)
    |> foreign_key_constraint(:campaign_target_id)
  end
end
