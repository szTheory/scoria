defmodule Scoria.Knowledge.PgvectorTest do
  use Scoria.KnowledgeCase, async: false

  alias Scoria.Knowledge

  test "ingest_source/2 uses chunker: and produces start_offset values for repeat ingest stability" do
    attrs = %{
      kind: "doc",
      title: "repeat ingest",
      uri: "file:///repeat.md",
      body: "# Title\n\nfirst paragraph\n\nsecond paragraph"
    }

    assert {:ok, source} = Knowledge.ingest_source(attrs, chunker: Scoria.Knowledge.Chunker.Default)
    chunks = Knowledge.list_source_chunks(source.id)
    assert Enum.all?(chunks, &is_integer(&1.start_offset))

    assert {:ok, rerun_source} = Knowledge.ingest_source(attrs, chunker: Scoria.Knowledge.Chunker.Default)
    rerun_chunks = Knowledge.list_source_chunks(rerun_source.id)

    assert Enum.map(chunks, & &1.chunk_digest) == Enum.map(rerun_chunks, & &1.chunk_digest)
  end

  test "retrieve/2 uses Scoria.Knowledge.Backends.Pgvector by default" do
    attrs = %{
      kind: "doc",
      title: "retrieval",
      uri: "file:///retrieval.md",
      body: "pgvector retrieval keeps answers grounded."
    }

    assert {:ok, source} = Knowledge.ingest_source(attrs)
    assert [_ | _] = Knowledge.list_source_chunks(source.id)
    assert {:ok, %{results: results}} = Knowledge.retrieve("grounded retrieval", filters: %{source_id: source.id})
    assert [%{rank: 1} | _] = Enum.map(results, &Map.from_struct/1)
  end
end
