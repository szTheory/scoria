defmodule Scoria.Eval.EvalCampaign do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ["queued", "running", "completed", "completed_partial", "failed_fatal", "cancelled"]

  schema "ai_eval_campaigns" do
    field(:tenant_id, :string)
    field(:status, :string, default: "queued")
    field(:total_targets, :integer, default: 0)
    field(:queued_targets, :integer, default: 0)
    field(:running_targets, :integer, default: 0)
    field(:completed_targets, :integer, default: 0)
    field(:failed_targets, :integer, default: 0)
    field(:cancelled_targets, :integer, default: 0)
    field(:started_at, :utc_datetime_usec)
    field(:finished_at, :utc_datetime_usec)
    field(:last_progress_at, :utc_datetime_usec)
    field(:metadata, :map, default: %{})

    belongs_to(:eval_spec, Scoria.Eval.EvalSpec)

    has_many(:targets, Scoria.Eval.EvalCampaignTarget, foreign_key: :campaign_id)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(campaign, attrs) do
    campaign
    |> cast(attrs, [
      :tenant_id,
      :eval_spec_id,
      :status,
      :total_targets,
      :queued_targets,
      :running_targets,
      :completed_targets,
      :failed_targets,
      :cancelled_targets,
      :started_at,
      :finished_at,
      :last_progress_at,
      :metadata
    ])
    |> validate_required([:tenant_id, :eval_spec_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:total_targets, greater_than_or_equal_to: 0)
    |> validate_number(:queued_targets, greater_than_or_equal_to: 0)
    |> validate_number(:running_targets, greater_than_or_equal_to: 0)
    |> validate_number(:completed_targets, greater_than_or_equal_to: 0)
    |> validate_number(:failed_targets, greater_than_or_equal_to: 0)
    |> validate_number(:cancelled_targets, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:eval_spec_id)
  end
end
