defmodule Scoria.KnowledgeTest do
  use Scoria.KnowledgeCase, async: false

  alias Scoria.Knowledge
  alias Scoria.Knowledge.Chunk
  alias Scoria.Knowledge.Source

  @source_attrs %{
    kind: "doc",
    uri: "file:///guide.md",
    title: "Guide",
    body: "# Intro\n\nPhoenix LiveView keeps the UI trace-first.\n\npgvector powers retrieval."
  }

  test "create_source/1 creates a durable source record" do
    assert {:ok, %Source{} = source} = Knowledge.create_source(@source_attrs)
    assert source.entity_id
    assert source.version == 1
    assert source.is_current == true
  end

  test "ingest_source/2 persists corpus chunks" do
    assert {:ok, %Source{} = source} = Knowledge.ingest_source(@source_attrs)

    chunks = Knowledge.list_source_chunks(source.id)
    assert [%Chunk{} | _] = chunks
    assert Enum.all?(chunks, &(&1.source_id == source.id))
    assert Enum.all?(chunks, &(is_integer(&1.start_offset) and is_integer(&1.end_offset)))
  end

  test "reembed_source/2 updates persisted embeddings" do
    assert {:ok, %Source{} = source} = Knowledge.ingest_source(@source_attrs)
    assert {:ok, chunks} = Knowledge.reembed_source(source)
    assert Enum.all?(chunks, &(!is_nil(&1.embedding)))
  end

  test "create_retrieval_run/1 and append_retrieval_results/2 persist retrieval state" do
    assert {:ok, %Source{} = source} = Knowledge.ingest_source(@source_attrs)
    [chunk | _] = Knowledge.list_source_chunks(source.id)
    assert {:ok, run} = Knowledge.create_retrieval_run(%{query_text: "pgvector", backend: "test"})

    assert {:ok, [result]} =
             Knowledge.append_retrieval_results(run.id, [
               %{chunk_id: chunk.id, source_id: source.id, rank: 1, score: 0.99, metadata: %{}}
             ])

    assert result.rank == 1
  end

  test "create_grounding_score/1 persists rubric_version" do
    assert {:ok, score} =
             Knowledge.create_grounding_score(%{
               scorer_kind: "judge",
               rubric_version: "v1",
               score: 0.8,
               status: "passed",
               reasoning: "grounded"
             })

    assert score.rubric_version == "v1"
  end
end
