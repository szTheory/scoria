defmodule Scoria.Eval.EvalCampaignTarget do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses ["pending", "running", "completed", "failed", "cancelled"]
  @semantic_override_fields ~w(
    dataset_slice
    judge
    judge_definition
    judge_model
    judge_prompt_template_id
    judge_prompt_version
    prompt_template_id
    prompt_version
    subject
    threshold_policy
  )

  schema "ai_eval_campaign_targets" do
    field(:tenant_id, :string)
    field(:provider, :string)
    field(:model, :string)
    field(:queue, :string)
    field(:priority, :integer)
    field(:status, :string, default: "pending")
    field(:metadata, :map, default: %{})
    field(:started_at, :utc_datetime_usec)
    field(:finished_at, :utc_datetime_usec)
    field(:last_error, :map, default: %{})

    belongs_to(:campaign, Scoria.Eval.EvalCampaign)
    belongs_to(:eval_spec, Scoria.Eval.EvalSpec)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(target, attrs) do
    attrs = Map.new(attrs)

    target
    |> cast(attrs, [
      :campaign_id,
      :eval_spec_id,
      :tenant_id,
      :provider,
      :model,
      :queue,
      :priority,
      :status,
      :metadata,
      :started_at,
      :finished_at,
      :last_error
    ])
    |> validate_required([:campaign_id, :eval_spec_id, :tenant_id, :provider, :model, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:priority, greater_than_or_equal_to: 0)
    |> validate_no_semantic_overrides(attrs)
    |> foreign_key_constraint(:campaign_id)
    |> foreign_key_constraint(:eval_spec_id)
  end

  defp validate_no_semantic_overrides(changeset, attrs) do
    invalid_fields =
      @semantic_override_fields
      |> Enum.filter(&present_key?(attrs, &1))

    case invalid_fields do
      [] ->
        changeset

      fields ->
        add_error(
          changeset,
          :targets,
          "contains unsupported semantic override fields: #{Enum.join(fields, ", ")}"
        )
    end
  end

  defp present_key?(attrs, key) do
    Map.has_key?(attrs, key) || Map.has_key?(attrs, String.to_atom(key))
  rescue
    ArgumentError -> Map.has_key?(attrs, key)
  end
end
