defmodule Scoria.Knowledge.Retrievers.Scrypath do
  import Ecto.Query, warn: false

  alias Scoria.Knowledge.Chunk
  alias Scoria.Repo

  def retrieve(query, opts \\ []) do
    results =
      cond do
        is_function(opts[:query_fun], 1) -> opts[:query_fun].(query)
        true -> opts[:results] || []
      end

    normalize_results(results)
  end

  def normalize_results(results) do
    results
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, []}, fn {result, rank}, {:ok, acc} ->
      case resolve_chunk(result) do
        {:ok, chunk} ->
          normalized = %{
            chunk_id: chunk.id,
            source_id: chunk.source_id,
            chunk_digest: chunk.chunk_digest,
            rank: rank,
            score: Map.get(result, :score) || Map.get(result, "score") || 1.0,
            metadata: Map.get(result, :metadata) || Map.get(result, "metadata") || %{},
            backend_payload: Map.take(result, [:locator, :digest, :offsets])
          }

          {:cont, {:ok, [normalized | acc]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, normalized} -> {:ok, Enum.reverse(normalized)}
      error -> error
    end
  end

  defp resolve_chunk(result) do
    cond do
      result[:chunk_id] && result[:source_id] ->
        {:ok, Repo.get!(Chunk, result[:chunk_id])}

      true ->
        digest = result[:chunk_digest] || get_in(result, [:locator, :chunk_digest]) || result["chunk_digest"]
        source_id = result[:source_id] || result["source_id"]

        if digest && source_id do
          case Repo.one(from chunk in Chunk, where: chunk.source_id == ^source_id and chunk.chunk_digest == ^digest) do
            nil -> {:error, "unsupported Scrypath hit: no Scoria-owned chunk matched the durable locator"}
            chunk -> {:ok, chunk}
          end
        else
          {:error, "unsupported Scrypath hit: source_id and chunk_id or durable locator metadata are required"}
        end
      end
  end
end
