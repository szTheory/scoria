defmodule Scoria.Eval.Verdict do
  @moduledoc false

  @passing_verdict "passed"

  def passing_verdict, do: @passing_verdict

  def compute(scores, threshold_policy) when is_list(scores) do
    scored = Enum.filter(scores, &item_scored?/1)

    cond do
      scores == [] ->
        :inconclusive

      scored == [] ->
        :inconclusive

      Enum.any?(scores, &(not item_scored?(&1))) and not_scored_tolerance(threshold_policy) == nil ->
        :inconclusive

      passes_policy?(scored, threshold_policy) ->
        :passed

      true ->
        :failed
    end
  end

  def blocks_release?(@passing_verdict), do: false
  def blocks_release?(_verdict), do: true

  def item_scored?(score) do
    fetch(score, :status) != "not_scored" and not is_nil(fetch(score, :score))
  end

  defp passes_policy?(scores, threshold_policy) do
    total = length(scores)
    pass_rate = Enum.count(scores, &(fetch(&1, :status) == @passing_verdict)) / total
    mean_score = Enum.sum(Enum.map(scores, &(fetch(&1, :score) || 0.0))) / total
    avg_latency = Enum.sum(Enum.map(scores, &latency_ms/1)) / total

    pass_rate_gte = fetch(threshold_policy, :pass_rate_gte) || 0.0
    mean_score_gte = fetch(threshold_policy, :mean_score_gte) || 0.0
    max_latency_ms = fetch(threshold_policy, :max_latency_ms) || 0

    pass_rate >= pass_rate_gte and
      mean_score >= mean_score_gte and
      avg_latency <= max_latency_ms
  end

  defp latency_ms(score) do
    score
    |> fetch(:metadata)
    |> case do
      metadata when is_map(metadata) -> fetch(metadata, :latency_ms) || 0
      _ -> 0
    end
    |> case do
      value when is_integer(value) -> value
      value when is_binary(value) -> parse_integer(value)
      _ -> 0
    end
  end

  defp parse_integer(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      _ -> 0
    end
  end

  defp not_scored_tolerance(policy), do: fetch(policy, :not_scored_tolerance)

  defp fetch(nil, _key), do: nil

  defp fetch(attrs, key) when is_map(attrs) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end
end
