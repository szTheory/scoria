defmodule Scoria.Knowledge.ScrypathTest do
  use Scoria.KnowledgeCase, async: false

  alias Scoria.Knowledge
  alias Scoria.Knowledge.Chunk
  alias Scoria.Knowledge.Retrievers.Scrypath

  @scope [tenant_id: "tenant-a", actor_id: "actor-a", scope_kind: :tenant_shared]
  @tenant_b_scope [tenant_id: "tenant-b", actor_id: "actor-b", scope_kind: :tenant_shared]

  test "normalize_results/2 returns only scoped source_id and chunk_id hits" do
    assert {:ok, source} =
             Knowledge.ingest_source(
               %{
                 kind: "doc",
                 title: "scrypath",
                 uri: "file:///scrypath.md",
                 body: "Scoria normalizes external retrieval hits."
               },
               scope: @scope
             )

    [chunk | _] = Knowledge.list_source_chunks(source.id, scope: @scope)

    assert {:ok, [result]} =
             apply(Scrypath, :normalize_results, [
               [
                 %{
                   chunk_id: chunk.id,
                   source_id: source.id,
                   chunk_digest: chunk.chunk_digest,
                   score: 0.9
                 }
               ],
               [scope: @scope]
             ])

    assert result.source_id == source.id
    assert result.chunk_id == chunk.id
  end

  test "retrieve/2 rejects unsupported hits without provenance" do
    assert {:error, message} = Scrypath.retrieve("query", results: [%{score: 0.5}], scope: @scope)
    assert message =~ "unsupported"
  end

  test "normalize_results/2 raises without tenant scope" do
    assert_raise ArgumentError, ~r/tenant_id is required/, fn ->
      apply(Scrypath, :normalize_results, [[%{score: 0.5}], []])
    end
  end

  test "retrieve/2 rejects chunk_id hits from another tenant" do
    assert {:ok, tenant_b_source} =
             Knowledge.create_source(source_attrs("tenant-b"), scope: @tenant_b_scope)

    tenant_b_chunk = insert_chunk!(tenant_b_source, "tenant-b", @tenant_b_scope)

    assert {:error, message} =
             Scrypath.retrieve("query",
               results: [
                 %{chunk_id: tenant_b_chunk.id, source_id: tenant_b_source.id, score: 0.9}
               ],
               scope: @scope
             )

    assert message =~ "no Scoria-owned chunk"
  end

  test "retrieve/2 rejects durable locators from another tenant" do
    assert {:ok, tenant_b_source} =
             Knowledge.create_source(source_attrs("tenant-b-digest"), scope: @tenant_b_scope)

    tenant_b_chunk = insert_chunk!(tenant_b_source, "tenant-b-digest", @tenant_b_scope)

    assert {:error, message} =
             Scrypath.retrieve("query",
               results: [
                 %{
                   source_id: tenant_b_source.id,
                   chunk_digest: tenant_b_chunk.chunk_digest,
                   score: 0.9
                 }
               ],
               scope: @scope
             )

    assert message =~ "no Scoria-owned chunk"
  end

  defp source_attrs(suffix) do
    %{
      kind: "doc",
      uri: "file:///#{suffix}.md",
      title: "Scrypath #{suffix}",
      body: "Scrypath body #{suffix}"
    }
  end

  defp insert_chunk!(source, suffix, scope) do
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
      metadata: %{}
    })
    |> Repo.insert!()
  end
end
