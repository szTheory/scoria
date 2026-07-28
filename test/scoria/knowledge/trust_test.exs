defmodule Scoria.Knowledge.TrustTest do
  use Scoria.KnowledgeCase, async: false

  import ExUnit.CaptureLog

  alias Scoria.Knowledge
  alias Scoria.Knowledge.Chunk
  alias Scoria.Repo
  alias Scoria.Trust

  @scope [tenant_id: "tenant-trust", actor_id: "actor-trust", scope_kind: :tenant_shared]

  setup do
    handler_id = "knowledge-trust-test-#{System.unique_integer([:positive])}"

    :telemetry.attach(
      handler_id,
      [:scoria, :trust, :fallback],
      fn event, measurements, metadata, _config ->
        send(self(), {:telemetry_event, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    :ok
  end

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

  describe "host-override trust API (D-05)" do
    test "create_source(attrs, trust: \"trusted\") persists the tier on Source.metadata" do
      assert {:ok, source} =
               Knowledge.create_source(
                 %{
                   kind: "doc",
                   title: "override doc",
                   uri: "file:///override.md",
                   digest: "override-digest"
                 },
                 scope: @scope,
                 trust: "trusted"
               )

      assert Trust.tier(source.metadata) == "trusted"
    end

    test "ingest_source(attrs, trust: \"trusted\") stamps every created chunk trusted" do
      assert {:ok, source} =
               Knowledge.ingest_source(
                 %{
                   kind: "doc",
                   title: "override ingest doc",
                   uri: "file:///override-ingest.md",
                   body: "Override-ingested content."
                 },
                 scope: @scope,
                 trust: "trusted"
               )

      assert Trust.tier(source.metadata) == "trusted"

      chunks = Knowledge.list_source_chunks(source.id, scope: @scope)
      refute chunks == []

      for chunk <- chunks do
        assert Trust.tier(chunk.metadata) == "trusted"
      end
    end

    test "ingest_source(attrs, trust: \"TYPO\") fails closed to untrusted + fallback telemetry" do
      log =
        capture_log(fn ->
          assert {:ok, source} =
                   Knowledge.ingest_source(
                     %{
                       kind: "doc",
                       title: "typo doc",
                       uri: "file:///typo.md",
                       body: "Typo-trust-declared content."
                     },
                     scope: @scope,
                     trust: "TYPO"
                   )

          assert Trust.tier(source.metadata) == "untrusted"

          [chunk | _] = Knowledge.list_source_chunks(source.id, scope: @scope)
          assert Trust.tier(chunk.metadata) == "untrusted"
        end)

      assert log =~ "Unrecognized trust tier"
      assert_received {:telemetry_event, [:scoria, :trust, :fallback], %{}, %{value: "TYPO"}}
    end

    test "set_source_trust/3 flips existing chunks within the scoped tenant only" do
      assert {:ok, source} =
               Knowledge.create_source(
                 %{
                   kind: "doc",
                   title: "post-hoc doc",
                   uri: "file:///post-hoc.md",
                   digest: "post-hoc-digest"
                 },
                 scope: @scope
               )

      assert {:ok, _chunks} =
               Knowledge.ingest_source(
                 source,
                 scope: @scope,
                 source_payload: %{body: "Post-hoc trust content."}
               )

      [chunk | _] = Knowledge.list_source_chunks(source.id, scope: @scope)
      assert Trust.tier(chunk.metadata) == "untrusted"

      # A same-`source_id` chunk row under a DIFFERENT tenant -- inserted
      # directly to prove the bulk UPDATE's WHERE double-scoping never
      # crosses tenants (T-55-03), mirroring the tenant-scoped
      # `Multi.delete_all` at `ingest_source/2`.
      assert {:ok, other_tenant_chunk} =
               %Chunk{}
               |> Chunk.changeset(%{
                 source_id: source.id,
                 tenant_id: "tenant-trust-other",
                 scope_kind: "tenant_shared",
                 chunk_digest: "other-tenant-digest",
                 body: "Other tenant content.",
                 start_offset: 0,
                 end_offset: 10,
                 token_count: 2,
                 metadata: %{}
               })
               |> Repo.insert()

      assert {:ok, updated_source, updated_count} =
               Knowledge.set_source_trust(source, "trusted", scope: @scope)

      assert updated_count == 1
      assert Trust.tier(updated_source.metadata) == "trusted"

      [flipped_chunk | _] = Knowledge.list_source_chunks(source.id, scope: @scope)
      assert Trust.tier(flipped_chunk.metadata) == "trusted"

      untouched_chunk = Repo.get!(Chunk, other_tenant_chunk.id)
      assert Trust.tier(untouched_chunk.metadata) == "untrusted"
    end

    test "set_source_trust/3 with a junk tier fails closed and never mints a bogus-trusted row" do
      assert {:ok, source} =
               Knowledge.create_source(
                 %{
                   kind: "doc",
                   title: "post-hoc junk doc",
                   uri: "file:///post-hoc-junk.md",
                   digest: "post-hoc-junk-digest"
                 },
                 scope: @scope
               )

      log =
        capture_log(fn ->
          assert {:ok, updated_source, _count} =
                   Knowledge.set_source_trust(source, "bogus", scope: @scope)

          assert Trust.tier(updated_source.metadata) == "untrusted"
        end)

      assert log =~ "Unrecognized trust tier"
      assert_received {:telemetry_event, [:scoria, :trust, :fallback], %{}, %{value: "bogus"}}
    end
  end
end
