defmodule Scoria.Knowledge.Retrievers.Scrypath do
  import Ecto.Query, warn: false

  alias Scoria.Knowledge.Chunk
  alias Scoria.Knowledge.Scope
  alias Scoria.Knowledge.Source
  alias Scoria.Repo

  def retrieve(query, opts \\ []) do
    scope = Scope.from_opts!(opts)

    results =
      cond do
        is_function(opts[:query_fun], 1) -> opts[:query_fun].(query)
        true -> opts[:results] || []
      end

    normalize_results(results, scope: scope)
  end

  def normalize_results(results, opts \\ []) do
    scope = Scope.from_opts!(opts)

    results
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, []}, fn {result, rank}, {:ok, acc} ->
      case resolve_chunk(result, scope) do
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

  defp resolve_chunk(result, scope) do
    chunk_id = get_attr(result, :chunk_id)
    source_id = get_attr(result, :source_id)
    digest = get_attr(result, :chunk_digest) || locator_attr(result, :chunk_digest)

    cond do
      chunk_id && source_id ->
        find_scoped_chunk(scope, source_id, chunk_id: chunk_id)

      digest && source_id ->
        find_scoped_chunk(scope, source_id, chunk_digest: digest)

      true ->
        {:error,
         "unsupported Scrypath hit: source_id and chunk_id or durable locator metadata are required"}
    end
  end

  defp find_scoped_chunk(scope, source_id, chunk_constraint) do
    if visible_source?(scope, source_id) do
      chunk =
        Chunk
        |> Scope.visible_to(scope)
        |> where([chunk], chunk.source_id == ^source_id)
        |> apply_chunk_constraint(chunk_constraint)
        |> Repo.one()

      case chunk do
        %Chunk{} = chunk ->
          {:ok, chunk}

        nil ->
          {:error, "unsupported Scrypath hit: no Scoria-owned chunk matched the durable locator"}
      end
    else
      {:error, "unsupported Scrypath hit: no Scoria-owned chunk matched the durable locator"}
    end
  end

  defp visible_source?(scope, source_id) do
    Source
    |> Scope.visible_to(scope)
    |> where([source], source.id == ^source_id)
    |> select([_source], true)
    |> limit(1)
    |> Repo.one()
    |> Kernel.==(true)
  end

  defp apply_chunk_constraint(query, chunk_id: chunk_id),
    do: where(query, [chunk], chunk.id == ^chunk_id)

  defp apply_chunk_constraint(query, chunk_digest: chunk_digest),
    do: where(query, [chunk], chunk.chunk_digest == ^chunk_digest)

  defp get_attr(attrs, key) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end

  defp locator_attr(attrs, key) do
    locator = get_attr(attrs, :locator) || %{}
    get_attr(locator, key)
  end
end
