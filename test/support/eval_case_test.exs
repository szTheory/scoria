defmodule Scoria.EvalCaseTest do
  use Scoria.EvalCase, async: true

  test "EvalCase sets up sandbox and imports Tribunal" do
    assert Code.ensure_loaded?(Tribunal)
  end
end
