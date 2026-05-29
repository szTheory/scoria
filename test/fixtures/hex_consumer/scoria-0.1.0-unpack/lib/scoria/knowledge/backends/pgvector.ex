defmodule Scoria.Knowledge.Backends.Pgvector do
  import Ecto.Query, warn: false
  import Pgvector.Ecto.Query

  alias Scoria.Knowledge.Chunk
  alias Scoria.Repo

  def upsert_chunk_embeddings(chunks, embeddings) when is_list(chunks) and is_list(embeddings) do
    Enum.zip(chunks, embeddings)
    |> Enum.map(fn {%Chunk{} = chunk, embedding} ->
      chunk
      |> Chunk.changeset(%{embedding: embedding})
      |> Repo.update()
    end)
    |> collect_results()
  end

  def similar_chunks(query_embedding, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5)
    filters = Keyword.get(opts, :filters, %{})
    source_id = Map.get(filters, :source_id) || Map.get(filters, "source_id")

    Chunk
    |> maybe_filter_source(source_id)
    |> order_by(
      [chunk],
      asc: cosine_distance(chunk.embedding, ^Pgvector.new(query_embedding))
    )
    |> limit(^limit)
    |> Repo.all()
    |> Enum.with_index(1)
    |> Enum.map(fn {chunk, rank} ->
      %{
        chunk_id: chunk.id,
        source_id: chunk.source_id,
        rank: rank,
        score: score_chunk(chunk.embedding, query_embedding),
        metadata: chunk.metadata,
        backend_payload: %{chunk_digest: chunk.chunk_digest}
      }
    end)
    |> then(&{:ok, &1})
  end

  def delete_source_embeddings(source_id) do
    from(chunk in Chunk, where: chunk.source_id == ^source_id)
    |> Repo.update_all(set: [embedding: nil])

    :ok
  end

  defp maybe_filter_source(query, nil), do: query
  defp maybe_filter_source(query, source_id), do: where(query, [chunk], chunk.source_id == ^source_id)

  defp collect_results(results) do
    case Enum.find(results, fn {status, _value} -> status == :error end) do
      nil -> {:ok, Enum.map(results, fn {:ok, chunk} -> chunk end)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp score_chunk(nil, _query_embedding), do: 0.0

  defp score_chunk(embedding, query_embedding) do
    query_sum = Enum.sum(query_embedding)
    embedding_sum = embedding |> Pgvector.to_list() |> Enum.sum()
    1.0 / (1.0 + abs(embedding_sum - query_sum))
  end
end
