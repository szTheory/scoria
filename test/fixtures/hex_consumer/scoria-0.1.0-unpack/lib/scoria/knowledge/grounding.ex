defmodule Scoria.Knowledge.Grounding do
  alias Scoria.Knowledge.CitationFormatter

  def score_citation_presence(%{citations: citations}) when is_list(citations) do
    score = if citations == [], do: 0.0, else: 1.0
    status = if score == 1.0, do: "passed", else: "failed"
    %{status: status, score: score, details: %{count: length(citations)}}
  end

  def score_citation_presence(_payload), do: %{status: "failed", score: 0.0, details: %{count: 0}}

  def score_citation_validity(%{citations: citations}) do
    results = Enum.map(citations, &CitationFormatter.validate_anchor/1)
    invalid = Enum.count(results, &match?({:error, _}, &1))
    total = max(length(citations), 1)
    score = (total - invalid) / total
    %{status: status(score), score: score, details: %{invalid: invalid, total: length(citations)}}
  end

  def score_citation_validity(_payload), do: %{status: "failed", score: 0.0, details: %{invalid: 1}}

  def score_chunk_membership(answer, %{citations: citations}) do
    snippets = Enum.map(citations, fn citation -> citation[:quote] || citation["quote"] || "" end)
    matches = Enum.count(snippets, &String.contains?(answer, &1))
    total = max(length(snippets), 1)
    %{status: status(matches / total), score: matches / total, details: %{matches: matches, total: length(snippets)}}
  end

  def score_unsupported_claims(answer, %{citations: citations}) do
    supported_terms =
      citations
      |> Enum.flat_map(fn citation ->
        (citation[:quote] || citation["quote"] || "")
        |> String.split(~r/\W+/, trim: true)
      end)
      |> MapSet.new()

    unsupported_claims =
      answer
      |> String.split(~r/[.!?]/, trim: true)
      |> Enum.reject(fn sentence ->
        sentence
        |> String.split(~r/\W+/, trim: true)
        |> Enum.all?(&MapSet.member?(supported_terms, &1))
      end)

    total = max(length(unsupported_claims) + 1, 1)
    score = 1.0 - length(unsupported_claims) / total
    %{status: status(score), score: score, details: %{unsupported_claims: unsupported_claims}}
  end

  def score_retrieval_hits(results, %{expected_chunk_ids: expected_chunk_ids}) do
    found_ids = MapSet.new(Enum.map(results, &(&1.chunk_id || &1[:chunk_id])))
    expected_ids = MapSet.new(expected_chunk_ids)
    hits = MapSet.intersection(found_ids, expected_ids) |> MapSet.size()
    total = max(MapSet.size(expected_ids), 1)
    %{status: status(hits / total), score: hits / total, details: %{hit_rate: hits / total}}
  end

  def score_retrieval_hits(_results, _labels), do: %{status: "passed", score: 1.0, details: %{hit_rate: 1.0}}

  def score_retrieval_ranking(results, %{expected_chunk_ids: expected_chunk_ids}) do
    reciprocal_rank =
      results
      |> Enum.find_value(0.0, fn result ->
        if (result.chunk_id || result[:chunk_id]) in expected_chunk_ids do
          1.0 / (result.rank || result[:rank] || 1)
        end
      end)

    %{status: status(reciprocal_rank), score: reciprocal_rank, details: %{retrieval_ranking: reciprocal_rank}}
  end

  def score_retrieval_ranking(_results, _labels) do
    %{status: "passed", score: 1.0, details: %{retrieval_ranking: 1.0}}
  end

  defp status(score) when score >= 0.75, do: "passed"
  defp status(score) when score >= 0.4, do: "warning"
  defp status(_score), do: "failed"
end
