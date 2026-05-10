defmodule Scoria.Eval.Dataset do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_datasets" do
    field :entity_id, :binary_id
    field :version, :integer, default: 1
    field :is_current, :boolean, default: true
    field :name, :string
    field :description, :string

    has_many :dataset_items, Scoria.Eval.DatasetItem, on_replace: :delete

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(dataset, attrs) do
    dataset
    |> cast(attrs, [:entity_id, :version, :is_current, :name, :description])
    |> validate_required([:entity_id, :version, :is_current, :name])
    |> unique_constraint([:entity_id, :version])
  end
end
