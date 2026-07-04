defmodule Scoria.Eval.Scorers.ExactMatchTest do
  use ExUnit.Case, async: true

  alias Scoria.Eval.Scorers.ExactMatch

  describe "score/3" do
    test "passes when the actual output exactly matches the expected answer" do
      assert %{
               status: "passed",
               score: 1.0,
               scorer_kind: "exact_match",
               scorer_version: "exact-match@1"
             } = ExactMatch.score("Scoria", %{"answer" => "Scoria"}, [])
    end

    test "fails with a binary zero score when strings cleanly mismatch" do
      assert %{
               status: "failed",
               score: score,
               details: %{normalized_actual: "scoria", normalized_expected: "Scoria"}
             } = ExactMatch.score("scoria", %{"answer" => "Scoria"}, [])

      assert score == 0.0
    end

    test "can compare strings case-insensitively when configured" do
      assert %{
               status: "passed",
               score: 1.0
             } = ExactMatch.score("scoria", %{"answer" => "Scoria"}, case_insensitive: true)
    end

    test "normalizes unicode, trims, and collapses internal whitespace for string compares" do
      assert %{
               status: "passed",
               score: 1.0
             } = ExactMatch.score("  Scoria  is\tgreat ", %{"answer" => "Scoria is great"}, [])
    end

    test "returns not_scored when actual output is absent" do
      assert {:not_scored, :missing_actual} = ExactMatch.score(nil, %{"answer" => "Scoria"}, [])
    end

    test "returns not_scored when the expected field is missing or nil" do
      assert {:not_scored, :missing_expected} = ExactMatch.score("x", %{}, [])
      assert {:not_scored, :missing_expected} = ExactMatch.score("x", %{"answer" => nil}, [])
    end

    test "coerces expected atom and string keys and supports field overrides" do
      assert %{
               status: "passed",
               score: 1.0
             } = ExactMatch.score("Scoria", %{answer: "Scoria"}, [])

      assert %{
               status: "passed",
               score: 1.0
             } = ExactMatch.score("Phoenix", %{"expected" => "Phoenix"}, field: :expected)
    end

    test "passes for canonical whole-map comparisons" do
      assert %{
               status: "passed",
               score: 1.0
             } = ExactMatch.score(%{"a" => 1}, %{a: 1}, match: "map")
    end

    test "returns not_scored for incomparable non-string values in field mode" do
      assert {:not_scored, :incomparable_types} =
               ExactMatch.score(123, %{"answer" => "123"}, [])
    end
  end
end
