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
    field :rubric, :map

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(eval_spec, attrs) do
    eval_spec
    |> cast(attrs, [:entity_id, :version, :is_current, :name, :description, :rubric])
    |> validate_required([:entity_id, :version, :is_current, :name, :rubric])
    |> unique_constraint([:entity_id, :version])
  end
end
