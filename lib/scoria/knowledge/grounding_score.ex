defmodule Scoria.Knowledge.GroundingScore do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ai_grounding_scores" do
    field :scorer_kind, :string
    field :rubric_version, :string
    field :model, :string
    field :prompt_version, :string
    field :score, :float
    field :status, :string, default: "passed"
    field :reasoning, :string
    field :details, :map, default: %{}
    field :evidence_refs, :map, default: %{}
    field :metadata, :map, default: %{}

    belongs_to :retrieval_run, Scoria.Knowledge.RetrievalRun
    belongs_to :citation, Scoria.Knowledge.Citation

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(score, attrs) do
    score
    |> cast(attrs, [
      :retrieval_run_id,
      :citation_id,
      :scorer_kind,
      :rubric_version,
      :model,
      :prompt_version,
      :score,
      :status,
      :reasoning,
      :details,
      :evidence_refs,
      :metadata
    ])
    |> validate_required([:scorer_kind, :rubric_version, :score, :status])
    |> foreign_key_constraint(:retrieval_run_id)
    |> foreign_key_constraint(:citation_id)
  end
end
