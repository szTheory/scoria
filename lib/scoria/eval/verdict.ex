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

      latency_policy_result(scored, threshold_policy) == :inconclusive ->
        :inconclusive

      latency_policy_result(scored, threshold_policy) == :failed ->
        :failed

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

    pass_rate_gte = fetch(threshold_policy, :pass_rate_gte) || 0.0
    mean_score_gte = fetch(threshold_policy, :mean_score_gte) || 0.0

    pass_rate >= pass_rate_gte and mean_score >= mean_score_gte
  end

  defp latency_policy_result(scores, threshold_policy) do
    case fetch(threshold_policy, :max_latency_ms) do
      nil ->
        :ok

      max_latency_ms ->
        case parse_latency_ms(max_latency_ms) do
          {:ok, max_latency_ms} ->
            scores
            |> Enum.map(&score_latency_ms/1)
            |> Enum.reduce_while(:ok, fn
              {:ok, latency_ms}, :ok when latency_ms <= max_latency_ms -> {:cont, :ok}
              {:ok, _latency_ms}, :ok -> {:halt, :failed}
              :error, :ok -> {:halt, :inconclusive}
            end)

          :error ->
            :inconclusive
        end
    end
  end

  defp score_latency_ms(score) do
    case fetch(score, :metadata) do
      metadata when is_map(metadata) -> metadata |> fetch(:latency_ms) |> parse_latency_ms()
      _ -> :error
    end
  end

  defp parse_latency_ms(value) when is_integer(value) and value >= 0, do: {:ok, value}

  defp parse_latency_ms(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} when integer >= 0 -> {:ok, integer}
      _ -> :error
    end
  end

  defp parse_latency_ms(_value), do: :error

  defp not_scored_tolerance(policy), do: fetch(policy, :not_scored_tolerance)

  defp fetch(nil, _key), do: nil

  defp fetch(attrs, key) when is_map(attrs) do
    cond do
      Map.has_key?(attrs, key) -> Map.get(attrs, key)
      Map.has_key?(attrs, Atom.to_string(key)) -> Map.get(attrs, Atom.to_string(key))
      true -> nil
    end
  end
end
