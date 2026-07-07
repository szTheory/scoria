defmodule Scoria.Knowledge.PgvectorTest do
  use Scoria.KnowledgeCase, async: false

  alias Scoria.Knowledge
  alias Scoria.Knowledge.Backends.Pgvector
  alias Scoria.Knowledge.Chunk

  @scope [tenant_id: "tenant-a", actor_id: "actor-a", scope_kind: :tenant_shared]
  @actor_scope [tenant_id: "tenant-a", actor_id: "actor-a", scope_kind: :actor_scoped]
  @other_actor_scope [tenant_id: "tenant-a", actor_id: "actor-b", scope_kind: :actor_scoped]
  @tenant_b_scope [tenant_id: "tenant-b", actor_id: "actor-b", scope_kind: :tenant_shared]

  test "ingest_source/2 uses chunker: and produces start_offset values for repeat ingest stability" do
    attrs = %{
      kind: "doc",
      title: "repeat ingest",
      uri: "file:///repeat.md",
      body: "# Title\n\nfirst paragraph\n\nsecond paragraph"
    }

    assert {:ok, source} =
             Knowledge.ingest_source(attrs,
               chunker: Scoria.Knowledge.Chunker.Default,
               scope: @scope
             )

    chunks = Knowledge.list_source_chunks(source.id, scope: @scope)
    assert Enum.all?(chunks, &is_integer(&1.start_offset))

    assert {:ok, rerun_source} =
             Knowledge.ingest_source(attrs,
               chunker: Scoria.Knowledge.Chunker.Default,
               scope: @scope
             )

    rerun_chunks = Knowledge.list_source_chunks(rerun_source.id, scope: @scope)

    assert Enum.map(chunks, & &1.chunk_digest) == Enum.map(rerun_chunks, & &1.chunk_digest)
  end

  test "retrieve/2 uses Scoria.Knowledge.Backends.Pgvector by default" do
    attrs = %{
      kind: "doc",
      title: "retrieval",
      uri: "file:///retrieval.md",
      body: "pgvector retrieval keeps answers grounded."
    }

    assert {:ok, source} = Knowledge.ingest_source(attrs, scope: @scope)
    assert [_ | _] = Knowledge.list_source_chunks(source.id, scope: @scope)

    assert {:ok, %{results: results}} =
             Knowledge.retrieve("grounded retrieval",
               filters: %{source_id: source.id},
               scope: @scope
             )

    assert [%{rank: 1} | _] = Enum.map(results, &Map.from_struct/1)
  end

  test "similar_chunks/2 requires tenant scope" do
    assert_raise ArgumentError, ~r/tenant_id is required/, fn ->
      Pgvector.similar_chunks([0.1, 0.2, 0.3])
    end
  end

  test "similar_chunks/2 filters tenant visibility before vector ordering" do
    assert {:ok, tenant_a_source} =
             Knowledge.create_source(source_attrs("tenant-a"), scope: @scope)

    assert {:ok, tenant_b_source} =
             Knowledge.create_source(source_attrs("tenant-b"), scope: @tenant_b_scope)

    tenant_a_chunk = insert_chunk!(tenant_a_source, "tenant-a", @scope, [0.1, 0.1, 0.1])
    tenant_b_chunk = insert_chunk!(tenant_b_source, "tenant-b", @tenant_b_scope, [0.9, 0.9, 0.9])

    assert {:ok, results} = Pgvector.similar_chunks([0.9, 0.9, 0.9], scope: @scope, limit: 5)

    assert Enum.map(results, & &1.chunk_id) == [tenant_a_chunk.id]
    refute Enum.any?(results, &(&1.chunk_id == tenant_b_chunk.id))
  end

  test "similar_chunks/2 projects raw cosine similarity and excludes nil embeddings" do
    assert {:ok, source} = Knowledge.create_source(source_attrs("score-proof"), scope: @scope)

    exact_chunk = insert_chunk!(source, "exact", @scope, [1.0, 0.0, 0.0])
    orthogonal_chunk = insert_chunk!(source, "orthogonal", @scope, [0.0, 1.0, 0.0])
    nil_chunk = insert_chunk!(source, "nil", @scope, nil)

    assert {:ok, results} = Pgvector.similar_chunks([1.0, 0.0, 0.0], scope: @scope, limit: 5)

    assert [exact_result, orthogonal_result] = results
    assert exact_result.chunk_id == exact_chunk.id
    assert_in_delta exact_result.score, 1.0, 0.000001
    assert exact_result.body == exact_chunk.body

    assert orthogonal_result.chunk_id == orthogonal_chunk.id
    assert_in_delta orthogonal_result.score, 0.0, 0.000001

    refute Enum.any?(results, &(&1.chunk_id == nil_chunk.id))
  end

  test "similar_chunks/2 fails loudly for invalid vector dimensions" do
    assert {:ok, source} = Knowledge.create_source(source_attrs("dimension"), scope: @scope)
    _chunk = insert_chunk!(source, "dimension", @scope, [1.0, 0.0, 0.0])

    assert_raise Postgrex.Error, fn ->
      Pgvector.similar_chunks([1.0, 0.0], scope: @scope)
    end
  end

  test "similar_chunks/2 applies source filters only inside tenant scope" do
    assert {:ok, source_a} = Knowledge.create_source(source_attrs("source-a"), scope: @scope)
    assert {:ok, source_b} = Knowledge.create_source(source_attrs("source-b"), scope: @scope)

    _chunk_a = insert_chunk!(source_a, "source-a", @scope, [0.1, 0.1, 0.1])
    chunk_b = insert_chunk!(source_b, "source-b", @scope, [0.2, 0.2, 0.2])

    assert {:ok, results} =
             Pgvector.similar_chunks([0.2, 0.2, 0.2],
               scope: @scope,
               filters: %{source_id: source_b.id}
             )

    assert Enum.map(results, & &1.chunk_id) == [chunk_b.id]
  end

  test "similar_chunks/2 honors actor scoped visibility" do
    assert {:ok, shared_source} = Knowledge.create_source(source_attrs("shared"), scope: @scope)

    assert {:ok, actor_source} =
             Knowledge.create_source(source_attrs("actor"), scope: @actor_scope)

    assert {:ok, other_actor_source} =
             Knowledge.create_source(source_attrs("other-actor"), scope: @other_actor_scope)

    shared_chunk = insert_chunk!(shared_source, "shared", @scope, [0.2, 0.2, 0.2])
    actor_chunk = insert_chunk!(actor_source, "actor", @actor_scope, [0.3, 0.3, 0.3])

    other_actor_chunk =
      insert_chunk!(other_actor_source, "other-actor", @other_actor_scope, [0.9, 0.9, 0.9])

    assert {:ok, results} =
             Pgvector.similar_chunks([0.9, 0.9, 0.9], scope: @actor_scope, limit: 5)

    chunk_ids = Enum.map(results, & &1.chunk_id)
    assert shared_chunk.id in chunk_ids
    assert actor_chunk.id in chunk_ids
    refute other_actor_chunk.id in chunk_ids
  end

  defp source_attrs(suffix) do
    %{
      kind: "doc",
      uri: "file:///#{suffix}.md",
      title: "Pgvector #{suffix}",
      body: "Pgvector body #{suffix}"
    }
  end

  defp insert_chunk!(source, suffix, scope, embedding) do
    scope = Scoria.Knowledge.Scope.for_write!(scope)

    %Chunk{}
    |> Chunk.changeset(%{
      source_id: source.id,
      tenant_id: scope.tenant_id,
      actor_id: scope.actor_id,
      scope_kind: scope.scope_kind,
      chunk_digest: "chunk-#{suffix}",
      body: "Chunk #{suffix}",
      heading_path: [],
      start_offset: 0,
      end_offset: 12,
      token_count: 2,
      embedding: embedding,
      metadata: %{}
    })
    |> Repo.insert!()
  end
end
