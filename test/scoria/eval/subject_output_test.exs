defmodule Scoria.Eval.SubjectOutputTest do
  use ExUnit.Case, async: true

  alias Scoria.Eval.DatasetItem
  alias Scoria.Eval.SubjectOutput

  describe "resolve/2" do
    test "returns the frozen captured output for offline replay and live judge" do
      captured_output = %{"answer" => "actual subject output"}
      item = dataset_item(captured_output: captured_output)

      assert SubjectOutput.resolve(item, :offline_replay) == {:ok, captured_output}
      assert SubjectOutput.resolve(item, :live_judge) == {:ok, captured_output}
    end

    test "returns not_scored for nil and empty captures in both modes" do
      for captured_output <- [nil, %{}],
          mode <- [:offline_replay, :live_judge] do
        item = dataset_item(captured_output: captured_output)

        assert {:not_scored, :empty_capture} = SubjectOutput.resolve(item, mode)
      end
    end

    test "never returns expected_output as the actual when capture is absent" do
      expected_output = %{"answer" => "sealed expectation"}
      item = dataset_item(captured_output: nil, expected_output: expected_output)

      assert {:not_scored, :empty_capture} = SubjectOutput.resolve(item, :offline_replay)
      refute SubjectOutput.resolve(item, :offline_replay) == {:ok, expected_output}
    end

    test "live_judge does not blanket-defer when a frozen capture exists" do
      captured_output = %{"answer" => "judge this capture"}
      item = dataset_item(captured_output: captured_output)

      assert SubjectOutput.resolve(item, :live_judge) == {:ok, captured_output}
      refute SubjectOutput.resolve(item, :live_judge) == {:not_scored, :live_subject_deferred}
    end
  end

  defp dataset_item(attrs) do
    struct!(
      DatasetItem,
      Keyword.merge(
        [
          input: %{"question" => "What is the output?"},
          expected_output: %{"answer" => "expected output"}
        ],
        attrs
      )
    )
  end
end
