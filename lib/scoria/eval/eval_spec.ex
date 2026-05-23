defmodule Scoria.Eval.EvalSpec do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_eval_specs" do
    field :entity_id, :binary_id
    field :version, :integer, default: 1
    field :is_current, :boolean, default: true
    field :name, :string
    field :description, :string
    field :dataset_id, :integer
    field :dataset_version, :string
    field :eval_mode, Ecto.Enum, values: [:offline_replay, :live_judge]
    field :subject, :map
    field :scorers, {:array, :map}, default: []
    field :threshold_policy, :map, default: %{}

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(eval_spec, attrs) do
    eval_spec
    |> cast(attrs, [
      :entity_id,
      :version,
      :is_current,
      :name,
      :description,
      :dataset_id,
      :dataset_version,
      :eval_mode,
      :subject,
      :scorers,
      :threshold_policy
    ])
    |> validate_required([
      :entity_id,
      :version,
      :is_current,
      :name,
      :dataset_id,
      :dataset_version,
      :eval_mode,
      :subject,
      :scorers,
      :threshold_policy
    ])
    |> unique_constraint([:entity_id, :version])
  end

  def to_attrs(%__MODULE__{} = eval_spec) do
    %{
      entity_id: eval_spec.entity_id,
      version: eval_spec.version,
      is_current: eval_spec.is_current,
      name: eval_spec.name,
      description: eval_spec.description,
      dataset_id: eval_spec.dataset_id,
      dataset_version: eval_spec.dataset_version,
      eval_mode: eval_spec.eval_mode,
      subject: eval_spec.subject,
      scorers: eval_spec.scorers,
      threshold_policy: eval_spec.threshold_policy
    }
  end
end
