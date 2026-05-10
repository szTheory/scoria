defmodule Scoria.Eval.EvalRun do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_eval_runs" do
    field :status, :string, default: "pending"
    field :duration_ms, :integer

    belongs_to :dataset, Scoria.Eval.Dataset
    belongs_to :eval_spec, Scoria.Eval.EvalSpec

    has_many :scores, Scoria.Eval.Score

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(eval_run, attrs) do
    eval_run
    |> cast(attrs, [:status, :duration_ms, :dataset_id, :eval_spec_id])
    |> validate_required([:status, :dataset_id, :eval_spec_id])
    |> validate_inclusion(:status, ["pending", "running", "completed", "failed"])
    |> foreign_key_constraint(:dataset_id)
    |> foreign_key_constraint(:eval_spec_id)
  end
end
