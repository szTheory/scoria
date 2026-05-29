defmodule Scoria.Eval.Dataset do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ai_eval_datasets" do
    field :name, :string
    field :version, :string
    field :description, :string
    field :tags, {:array, :string}, default: []
    field :state, Ecto.Enum, values: [:open, :sealed], default: :open

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(dataset, attrs) do
    dataset
    |> cast(attrs, [:name, :version, :description, :tags, :state])
    |> validate_required([:name, :version])
    |> validate_immutable_if_sealed()
  end

  defp validate_immutable_if_sealed(changeset) do
    if changeset.data.state == :sealed do
      add_error(changeset, :state, "cannot be modified once sealed")
    else
      changeset
    end
  end
end
