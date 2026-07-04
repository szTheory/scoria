defmodule Scoria.Eval.Scorers.ExactMatch do
  @moduledoc false

  @scorer_kind "exact_match"
  @scorer_version "exact-match@1"

  def score(actual, expected_output, _opts) do
    if actual == Map.get(expected_output, "answer") do
      %{
        status: "passed",
        score: 1.0,
        scorer_kind: @scorer_kind,
        scorer_version: @scorer_version,
        details: %{actual: actual, expected: Map.get(expected_output, "answer")}
      }
    end
  end
end
