defmodule Scoria.Eval.Scorers.ExactMatch do
  @moduledoc false

  @scorer_kind "exact_match"
  @scorer_version "exact-match@1"

  def score(nil, _expected_output, _opts), do: {:not_scored, :missing_actual}

  def score(actual, expected_output, opts) do
    if map_match?(opts) do
      score_map(actual, expected_output)
    else
      score_field(actual, expected_output, opts)
    end
  end

  defp score_field(actual, expected_output, opts) when is_map(expected_output) do
    field = fetch(opts, :field) || "answer"

    case fetch(expected_output, field) do
      nil -> {:not_scored, :missing_expected}
      expected -> score_strings(actual, expected, field, opts)
    end
  end

  defp score_field(_actual, _expected_output, _opts), do: {:not_scored, :missing_expected}

  defp score_strings(actual, expected, field, opts)
       when is_binary(actual) and is_binary(expected) do
    case_insensitive? = case_insensitive?(opts)
    normalized_actual = normalize_string(actual, case_insensitive?)
    normalized_expected = normalize_string(expected, case_insensitive?)

    verdict(
      normalized_actual == normalized_expected,
      %{
        field: to_string(field),
        actual: actual,
        expected: expected,
        normalized_actual: normalized_actual,
        normalized_expected: normalized_expected,
        case_insensitive: case_insensitive?
      }
    )
  end

  defp score_strings(_actual, _expected, _field, _opts), do: {:not_scored, :incomparable_types}

  defp score_map(%{} = actual, %{} = expected_output) do
    canonical_actual = canonicalize(actual)
    canonical_expected = canonicalize(expected_output)

    verdict(
      canonical_actual == canonical_expected,
      %{actual: canonical_actual, expected: canonical_expected, match: "map"}
    )
  end

  defp score_map(_actual, _expected_output), do: {:not_scored, :incomparable_types}

  defp verdict(true, details) do
    %{
      status: "passed",
      score: 1.0,
      scorer_kind: @scorer_kind,
      scorer_version: @scorer_version,
      details: details
    }
  end

  defp verdict(false, details) do
    %{
      status: "failed",
      score: 0.0,
      scorer_kind: @scorer_kind,
      scorer_version: @scorer_version,
      details: details
    }
  end

  defp normalize_string(value, case_insensitive?) do
    value
    |> String.normalize(:nfc)
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
    |> maybe_downcase(case_insensitive?)
  end

  defp maybe_downcase(value, true), do: String.downcase(value)
  defp maybe_downcase(value, false), do: value

  defp canonicalize(%{} = map) do
    Map.new(map, fn {key, value} ->
      {to_string(key), canonicalize(value)}
    end)
  end

  defp canonicalize(value) when is_list(value), do: Enum.map(value, &canonicalize/1)
  defp canonicalize(value), do: value

  defp map_match?(opts), do: fetch(opts, :match) in ["map", :map]

  defp case_insensitive?(opts), do: fetch(opts, :case_insensitive) in [true, "true"]

  defp fetch(attrs, key) when is_map(attrs) or is_list(attrs) do
    attrs
    |> Enum.find(fn {candidate, _value} -> key_matches?(candidate, key) end)
    |> case do
      {_candidate, value} -> value
      nil -> nil
    end
  end

  defp fetch(_attrs, _key), do: nil

  defp key_matches?(candidate, key) do
    candidate == key or to_string(candidate) == to_string(key)
  end
end
