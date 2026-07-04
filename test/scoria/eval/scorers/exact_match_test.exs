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
  end
end
