defmodule Scoria.Eval.DatasetItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ai_eval_dataset_items" do
    belongs_to :dataset, Scoria.Eval.Dataset
    field :source_trace_id, :string
    field :input, :map
    field :expected_output, :map
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(item, attrs, dataset_state \\ :open) do
    item
    |> cast(attrs, [:dataset_id, :source_trace_id, :input, :expected_output, :metadata])
    |> validate_required([:dataset_id, :input])
    |> validate_dataset_state(dataset_state)
  end

  defp validate_dataset_state(changeset, :sealed) do
    add_error(changeset, :dataset_id, "cannot add or modify items in a sealed dataset")
  end

  defp validate_dataset_state(changeset, _), do: changeset
end
