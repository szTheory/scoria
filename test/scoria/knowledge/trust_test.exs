defmodule Scoria.Knowledge.TrustTest do
  use Scoria.KnowledgeCase, async: false

  alias Scoria.Knowledge
  alias Scoria.Knowledge.Chunk
  alias Scoria.Repo
  alias Scoria.Trust

  @scope [tenant_id: "tenant-trust", actor_id: "actor-trust", scope_kind: :tenant_shared]

  describe "ingest_source/2 -> Chunk.metadata trust denormalization (D-04)" do
    test "a source declaring metadata[\"scoria.trust.tier\"] = \"trusted\" yields trusted chunks" do
      assert {:ok, source} =
               Knowledge.create_source(
                 %{
                   kind: "doc",
                   title: "trusted doc",
                   uri: "file:///trusted.md",
                   digest: "trusted-digest",
                   metadata: %{"scoria.trust.tier" => "trusted"}
                 },
                 scope: @scope
               )

      assert {:ok, chunks} =
               Knowledge.ingest_source(
                 source,
                 scope: @scope,
                 source_payload: %{body: "This is trusted host-declared content."}
               )

      refute chunks == []

      for chunk <- chunks do
        assert %Chunk{} = chunk
        assert Trust.tier(chunk.metadata) == "trusted"
      end

      # No Source join on the retrieval hot path (D-04): re-read the
      # persisted chunk directly and prove trust resolves from its OWN
      # metadata alone.
      for %Chunk{id: id} <- chunks do
        persisted = Repo.get!(Chunk, id)
        assert Trust.tier(persisted.metadata) == "trusted"
      end
    end

    test "a source with no declared trust yields untrusted chunks (fail-closed default)" do
      assert {:ok, source} =
               Knowledge.create_source(
                 %{
                   kind: "doc",
                   title: "untagged doc",
                   uri: "file:///untagged.md",
                   digest: "untagged-digest"
                 },
                 scope: @scope
               )

      assert source.metadata == %{}

      assert {:ok, chunks} =
               Knowledge.ingest_source(
                 source,
                 scope: @scope,
                 source_payload: %{body: "This is host content with no trust declared."}
               )

      refute chunks == []

      for chunk <- chunks do
        assert Trust.tier(chunk.metadata) == "untrusted"
      end
    end

    test "ingest_source/2 with a map of attrs (create + ingest in one call) denormalizes trust" do
      assert {:ok, source} =
               Knowledge.ingest_source(
                 %{
                   kind: "doc",
                   title: "one-shot trusted doc",
                   uri: "file:///one-shot-trusted.md",
                   metadata: %{"scoria.trust.tier" => "trusted"},
                   body: "One-shot ingest with declared trust."
                 },
                 scope: @scope
               )

      [chunk | _] = Knowledge.list_source_chunks(source.id, scope: @scope)

      assert Trust.tier(chunk.metadata) == "trusted"
    end

    test "list_source_chunks/2 returns chunks whose trust reads via the Tiered protocol" do
      assert {:ok, source} =
               Knowledge.create_source(
                 %{
                   kind: "doc",
                   title: "protocol doc",
                   uri: "file:///protocol.md",
                   digest: "protocol-digest",
                   metadata: %{"scoria.trust.tier" => "trusted"}
                 },
                 scope: @scope
               )

      {:ok, _chunks} =
        Knowledge.ingest_source(
          source,
          scope: @scope,
          source_payload: %{body: "Protocol dispatch content."}
        )

      [chunk | _] = Knowledge.list_source_chunks(source.id, scope: @scope)

      assert Scoria.Trust.Tiered.tier(chunk) == "trusted"
    end
  end
end
