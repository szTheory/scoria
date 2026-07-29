defmodule ScoriaWeb.EvalVocabularyTest do
  use ExUnit.Case, async: true

  alias ScoriaWeb.Copy
  alias ScoriaWeb.UI

  test "not scored and inconclusive render as amber warning states with curated labels" do
    assert UI.tone("not_scored") == :warn
    assert UI.tone("inconclusive") == :warn

    assert Copy.status_label("not_scored") == "Not scored"
    assert Copy.status_label("inconclusive") == "Inconclusive"
  end

  test "existing eval pass/fail tones remain unchanged" do
    assert UI.tone("passed") == :pass
    assert UI.tone("failed") == :fail
  end

  test "a halted run renders with the failure tone, not a neutral badge (RAIL-01 D-01, plan 56.1-05 Task 3)" do
    assert UI.tone("halted") == :fail
  end
end
