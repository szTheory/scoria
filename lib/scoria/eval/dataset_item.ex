defmodule Scoria.Eval.DatasetItem do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_dataset_items" do
    field :input, :map
    field :expected_output, :map
    field :metadata, :map

    belongs_to :dataset, Scoria.Eval.Dataset

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(dataset_item, attrs) do
    dataset_item
    |> cast(attrs, [:input, :expected_output, :metadata, :dataset_id])
    |> validate_required([:input, :dataset_id])
    |> foreign_key_constraint(:dataset_id)
  end
end
