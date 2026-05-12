defmodule Scoria.Knowledge.ScrypathTest do
  use Scoria.KnowledgeCase, async: false

  alias Scoria.Knowledge
  alias Scoria.Knowledge.Retrievers.Scrypath

  test "normalize_results/1 returns only Scoria-owned source_id and chunk_id hits" do
    assert {:ok, source} =
             Knowledge.ingest_source(%{
               kind: "doc",
               title: "scrypath",
               uri: "file:///scrypath.md",
               body: "Scoria normalizes external retrieval hits."
             })

    [chunk | _] = Knowledge.list_source_chunks(source.id)

    assert {:ok, [result]} =
             Scrypath.normalize_results([
               %{chunk_id: chunk.id, source_id: source.id, chunk_digest: chunk.chunk_digest, score: 0.9}
             ])

    assert result.source_id == source.id
    assert result.chunk_id == chunk.id
  end

  test "retrieve/2 rejects unsupported hits without provenance" do
    assert {:error, message} = Scrypath.retrieve("query", results: [%{score: 0.5}])
    assert message =~ "unsupported"
  end
end
