defmodule Scoria.Knowledge.CitationFormatter do
  import Ecto.Query, warn: false

  alias Scoria.Knowledge.Chunk
  alias Scoria.Knowledge.Scope
  alias Scoria.Knowledge.Source
  alias Scoria.Repo

  def build_anchors(chunks, opts \\ [])

  def build_anchors(chunks, opts) when is_list(chunks) do
    Enum.with_index(chunks, 1)
    |> Enum.map(fn {chunk, index} -> build_anchor(chunk, index, opts) end)
  end

  def build_anchors(chunk, opts) do
    [build_anchor(chunk, 1, opts)]
  end

  def render_inline(anchor) do
    label = anchor[:label] || "[?]"
    title = get_in(anchor, [:locator, :title]) || "Untitled"
    "#{label} #{title} (#{anchor[:start_offset]}-#{anchor[:end_offset]})"
  end

  def validate_anchor(anchor, opts \\ []) do
    scope = Scope.from_opts!(opts)
    repo = Keyword.get(opts, :repo, Repo)

    source_id = get_attr(anchor, :source_id)
    chunk_id = get_attr(anchor, :chunk_id)

    case scoped_chunk(repo, scope, source_id, chunk_id) do
      nil ->
        {:error, %{reason: :missing_chunk}}

      chunk ->
        cond do
          chunk.chunk_digest != get_attr(anchor, :chunk_digest) ->
            {:error, %{reason: :digest_mismatch}}

          invalid_offsets?(chunk, anchor) ->
            {:error, %{reason: :offset_out_of_bounds}}

          true ->
            {:ok, anchor}
        end
    end
  end

  defp build_anchor(chunk, index, opts) do
    locator =
      %{
        title: chunk.source && chunk.source.title,
        uri: chunk.source && chunk.source.uri
      }
      |> Map.merge(Keyword.get(opts, :locator, %{}))
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    %{
      source_id: chunk.source_id,
      chunk_id: chunk.id,
      chunk_digest: chunk.chunk_digest,
      start_offset: Keyword.get(opts, :start_offset, chunk.start_offset),
      end_offset: Keyword.get(opts, :end_offset, chunk.end_offset),
      label: Keyword.get(opts, :label, "[#{index}]"),
      locator: locator
    }
  end

  defp invalid_offsets?(chunk, anchor) do
    start_offset = get_attr(anchor, :start_offset) || 0
    end_offset = get_attr(anchor, :end_offset) || 0
    chunk_length = String.length(chunk.body || "")

    start_offset < 0 or end_offset < start_offset or end_offset > chunk_length
  end

  defp scoped_chunk(_repo, _scope, nil, _chunk_id), do: nil
  defp scoped_chunk(_repo, _scope, _source_id, nil), do: nil

  defp scoped_chunk(repo, scope, source_id, chunk_id) do
    if visible_source?(repo, scope, source_id) do
      Chunk
      |> Scope.visible_to(scope)
      |> where([chunk], chunk.id == ^chunk_id and chunk.source_id == ^source_id)
      |> repo.one()
    end
  end

  defp visible_source?(repo, scope, source_id) do
    Source
    |> Scope.visible_to(scope)
    |> where([source], source.id == ^source_id)
    |> select([_source], true)
    |> limit(1)
    |> repo.one()
    |> Kernel.==(true)
  end

  defp get_attr(attrs, key) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end
end
