defmodule Scoria.Eval.ScoreChangesetTest do
  use ExUnit.Case, async: true

  alias Scoria.Eval.Score

  test "accepts not_scored rows without a score" do
    changeset =
      %Score{}
      |> Score.changeset(base_attrs(status: "not_scored") |> Map.delete(:score))

    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :score) == nil
  end

  test "requires score for passed rows" do
    changeset =
      %Score{}
      |> Score.changeset(base_attrs(status: "passed") |> Map.delete(:score))

    refute changeset.valid?
    assert {"can't be blank", _meta} = changeset.errors[:score]
  end

  test "keeps failed row score persistence unchanged" do
    changeset =
      %Score{}
      |> Score.changeset(base_attrs(status: "failed", score: 0.0))

    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :score) == 0.0
  end

  defp base_attrs(overrides) do
    %{
      score: 1.0,
      status: "passed",
      scorer_kind: "exact_match",
      eval_run_id: Ecto.UUID.generate(),
      dataset_item_id: 123
    }
    |> Map.merge(Map.new(overrides))
  end
end
