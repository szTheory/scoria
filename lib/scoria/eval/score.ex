defmodule Scoria.Eval.Score do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_scores" do
    field(:score, :float)
    field(:status, :string)
    field(:scorer_kind, :string)
    field(:scorer_version, :string)
    field(:reasoning, :string)
    field(:details, :map, default: %{})
    field(:explanation, :string)
    field(:judge_model, :string)
    field(:rubric_version, :string)
    field(:evidence_refs, :map, default: %{})
    field(:metadata, :map, default: %{})

    belongs_to(:eval_run, Scoria.Eval.EvalRun)
    belongs_to(:dataset_item, Scoria.Eval.DatasetItem, type: :id)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(score, attrs) do
    attrs = normalize_attrs(attrs)

    score
    |> cast(attrs, [
      :score,
      :status,
      :scorer_kind,
      :scorer_version,
      :reasoning,
      :details,
      :explanation,
      :judge_model,
      :rubric_version,
      :evidence_refs,
      :metadata,
      :eval_run_id,
      :dataset_item_id
    ])
    |> validate_required([:status, :scorer_kind, :eval_run_id, :dataset_item_id])
    |> require_score_unless_not_scored()
    |> foreign_key_constraint(:eval_run_id)
    |> foreign_key_constraint(:dataset_item_id)
  end

  defp require_score_unless_not_scored(changeset) do
    # not_scored count is derived as total - passed - failed; no stored counter.
    if get_field(changeset, :status) == "not_scored" do
      changeset
    else
      validate_required(changeset, [:score])
    end
  end

  defp normalize_attrs(attrs) do
    attrs = Map.new(attrs)
    explanation = fetch_attr(attrs, :explanation) || fetch_attr(attrs, :reasoning)
    details = fetch_attr(attrs, :details) || fetch_attr(attrs, :metadata) || %{}
    metadata = fetch_attr(attrs, :metadata) || fetch_attr(attrs, :details) || %{}

    attrs
    |> Map.put_new(:explanation, explanation)
    |> Map.put_new(:reasoning, explanation)
    |> Map.put_new(:details, details)
    |> Map.put_new(:metadata, metadata)
    |> Map.put_new(:evidence_refs, fetch_attr(attrs, :evidence_refs) || %{})
  end

  defp fetch_attr(attrs, key) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end
end
