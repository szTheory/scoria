defmodule Scoria.KnowledgeTest do
  use Scoria.KnowledgeCase, async: false

  alias Scoria.Knowledge
  alias Scoria.Knowledge.Chunk
  alias Scoria.Knowledge.Source

  @scope [tenant_id: "tenant-a", actor_id: "actor-a", scope_kind: :tenant_shared]
  @source_attrs %{
    kind: "doc",
    uri: "file:///guide.md",
    title: "Guide",
    body: "# Intro\n\nPhoenix LiveView keeps the UI trace-first.\n\npgvector powers retrieval."
  }

  test "create_source/2 creates a durable tenant-scoped source record" do
    assert {:ok, %Source{} = source} = Knowledge.create_source(@source_attrs, scope: @scope)
    assert source.entity_id
    assert source.version == 1
    assert source.is_current == true
    assert source.tenant_id == "tenant-a"
    assert source.actor_id == "actor-a"
    assert source.scope_kind == "tenant_shared"
  end

  test "ingest_source/2 persists corpus chunks" do
    assert {:ok, %Source{} = source} = Knowledge.ingest_source(@source_attrs, scope: @scope)

    chunks = Knowledge.list_source_chunks(source.id, scope: @scope)
    assert [%Chunk{} | _] = chunks
    assert Enum.all?(chunks, &(&1.source_id == source.id))
    assert Enum.all?(chunks, &(&1.tenant_id == "tenant-a"))
    assert Enum.all?(chunks, &(&1.actor_id == "actor-a"))
    assert Enum.all?(chunks, &(&1.scope_kind == "tenant_shared"))
    assert Enum.all?(chunks, &(is_integer(&1.start_offset) and is_integer(&1.end_offset)))
  end

  test "reembed_source/2 updates persisted embeddings" do
    assert {:ok, %Source{} = source} = Knowledge.ingest_source(@source_attrs, scope: @scope)
    assert {:ok, chunks} = Knowledge.reembed_source(source)
    assert Enum.all?(chunks, &(!is_nil(&1.embedding)))
  end

  test "create_retrieval_run/1 and append_retrieval_results/2 persist retrieval state" do
    assert {:ok, %Source{} = source} = Knowledge.ingest_source(@source_attrs, scope: @scope)
    [chunk | _] = Knowledge.list_source_chunks(source.id, scope: @scope)

    assert {:ok, run} =
             Knowledge.create_retrieval_run(%{
               query_text: "pgvector",
               backend: "test",
               tenant_id: "tenant-a",
               actor_id: "actor-a"
             })

    assert {:ok, [result]} =
             Knowledge.append_retrieval_results(run.id, [
               %{
                 chunk_id: chunk.id,
                 source_id: source.id,
                 rank: 1,
                 score: 0.99,
                 tenant_id: "tenant-a",
                 actor_id: "actor-a",
                 metadata: %{}
               }
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
