defmodule Scoria.Eval.Score do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_scores" do
    field :score, :float
    field :reasoning, :string
    field :details, :map

    belongs_to :eval_run, Scoria.Eval.EvalRun
    belongs_to :dataset_item, Scoria.Eval.DatasetItem

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(score, attrs) do
    score
    |> cast(attrs, [:score, :reasoning, :details, :eval_run_id, :dataset_item_id])
    |> validate_required([:score, :eval_run_id, :dataset_item_id])
    |> foreign_key_constraint(:eval_run_id)
    |> foreign_key_constraint(:dataset_item_id)
  end
end
