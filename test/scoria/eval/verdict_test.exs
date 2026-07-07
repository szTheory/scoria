defmodule Scoria.Eval.VerdictTest do
  use ExUnit.Case, async: true

  alias Scoria.Eval.Verdict

  describe "compute/2" do
    test "returns inconclusive for an empty score list" do
      assert Verdict.compute([], policy()) == :inconclusive
    end

    test "returns inconclusive when no items have real scores" do
      scores = [
        score(status: "not_scored", score: nil),
        score(status: "not_scored", score: nil)
      ]

      assert Verdict.compute(scores, policy()) == :inconclusive
    end

    test "returns inconclusive when any item is not scored and no tolerance is configured" do
      scores = [
        score(status: "passed", score: 1.0),
        score(status: "not_scored", score: nil)
      ]

      assert Verdict.compute(scores, policy()) == :inconclusive
    end

    test "computes over the scored subset when not_scored_tolerance is configured" do
      scores = [
        score(status: "passed", score: 1.0, metadata: %{"latency_ms" => "25"}),
        score(status: "not_scored", score: nil)
      ]

      assert Verdict.compute(scores, Map.put(policy(), "not_scored_tolerance", 1)) == :passed
    end

    test "returns passed when all scored items clear policy thresholds" do
      scores = [
        score(status: "passed", score: 1.0, metadata: %{"latency_ms" => 25}),
        score(status: "passed", score: 0.9, metadata: %{"latency_ms" => "35"})
      ]

      assert Verdict.compute(scores, policy()) == :passed
    end

    test "returns failed when scored items fall below policy thresholds" do
      scores = [
        score(status: "passed", score: 1.0, metadata: %{"latency_ms" => 10}),
        score(status: "failed", score: 0.0, metadata: %{"latency_ms" => 10})
      ]

      assert Verdict.compute(scores, policy()) == :failed
    end

    test "ignores nil-score items before mean and latency math" do
      scores = [
        score(status: "passed", score: 1.0, metadata: %{"latency_ms" => 10}),
        score(status: "passed", score: nil)
      ]

      assert Verdict.compute(scores, policy()) == :inconclusive

      assert Verdict.compute(scores, Map.put(policy(), :not_scored_tolerance, 1)) == :passed
    end

    test "returns failed when any scored item exceeds configured max latency" do
      scores = [
        score(status: "passed", score: 1.0, metadata: %{"latency_ms" => 10}),
        score(status: "passed", score: 1.0, metadata: %{"latency_ms" => "51"})
      ]

      assert Verdict.compute(scores, policy()) == :failed
    end

    test "returns inconclusive when configured max latency lacks score metadata" do
      scores = [
        score(status: "passed", score: 1.0, metadata: %{})
      ]

      assert Verdict.compute(scores, policy()) == :inconclusive
    end

    test "returns inconclusive when configured max latency has invalid score metadata" do
      scores = [
        score(status: "passed", score: 1.0, metadata: %{"latency_ms" => "fast"})
      ]

      assert Verdict.compute(scores, policy()) == :inconclusive
    end

    test "preserves pass behavior when no latency policy is configured" do
      scores = [
        score(status: "passed", score: 1.0, metadata: %{})
      ]

      policy = Map.drop(policy(), [:max_latency_ms])

      assert Verdict.compute(scores, policy) == :passed
    end
  end

  describe "blocks_release?/1" do
    test "allows only the canonical passing verdict" do
      refute Verdict.blocks_release?("passed")

      assert Verdict.blocks_release?("inconclusive")
      assert Verdict.blocks_release?("failed")
      assert Verdict.blocks_release?(:passed)
      assert Verdict.blocks_release?(nil)
    end
  end

  describe "item_scored?/1" do
    test "requires a non-not-scored status and a non-nil score" do
      refute Verdict.item_scored?(score(status: "not_scored", score: 1.0))
      refute Verdict.item_scored?(score(status: "passed", score: nil))

      assert Verdict.item_scored?(score(status: "passed", score: 1.0))
      assert Verdict.item_scored?(score(status: "failed", score: 0.0))
    end
  end

  defp policy do
    %{
      pass_rate_gte: 1.0,
      mean_score_gte: 0.9,
      max_latency_ms: 50
    }
  end

  defp score(attrs) when is_list(attrs), do: attrs |> Map.new() |> score()

  defp score(attrs) do
    Map.merge(%{status: "passed", score: 1.0, metadata: %{}}, attrs)
  end
end
