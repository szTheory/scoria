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
end
