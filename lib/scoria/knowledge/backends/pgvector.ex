defmodule Scoria.Knowledge.Backends.Pgvector do
  import Ecto.Query, warn: false
  import Pgvector.Ecto.Query

  alias Scoria.Knowledge.Chunk
  alias Scoria.Knowledge.Scope
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
    scope = Scope.from_opts!(opts)
    limit = Keyword.get(opts, :limit, 5)
    filters = Keyword.get(opts, :filters, %{})
    source_id = Map.get(filters, :source_id) || Map.get(filters, "source_id")
    query_vector = Pgvector.new(query_embedding)

    Chunk
    |> Scope.visible_to(scope)
    |> maybe_filter_source(source_id)
    |> where([chunk], not is_nil(chunk.embedding))
    |> order_by(
      [chunk],
      asc: cosine_distance(chunk.embedding, ^query_vector)
    )
    |> select([chunk], {
      chunk,
      1.0 - cosine_distance(chunk.embedding, ^query_vector)
    })
    |> limit(^limit)
    |> Repo.all()
    |> Enum.with_index(1)
    |> Enum.map(fn {{chunk, score}, rank} ->
      %{
        chunk_id: chunk.id,
        source_id: chunk.source_id,
        body: chunk.body,
        rank: rank,
        score: score,
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

  defp maybe_filter_source(query, source_id),
    do: where(query, [chunk], chunk.source_id == ^source_id)

  defp collect_results(results) do
    case Enum.find(results, fn {status, _value} -> status == :error end) do
      nil -> {:ok, Enum.map(results, fn {:ok, chunk} -> chunk end)}
      {:error, reason} -> {:error, reason}
    end
  end
end
