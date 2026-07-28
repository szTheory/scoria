defmodule Scoria.Knowledge.TrustTest do
  use Scoria.KnowledgeCase, async: false

  import ExUnit.CaptureLog

  alias Scoria.Knowledge
  alias Scoria.Knowledge.Chunk
  alias Scoria.Repo
  alias Scoria.Trust
  alias Scoria.Trust.Verdict

  @scope [tenant_id: "tenant-trust", actor_id: "actor-trust", scope_kind: :tenant_shared]

  # Test scanner double for the batch-scan-at-retrieve tests below (D-18):
  # unconditionally flags every scan as untrusted with reason_code
  # :prompt_injection, mirroring the fixture style already used by
  # test/scoria/trust/scan_test.exs.
  defmodule FlaggingScanner do
    @behaviour Scoria.Trust.Scanner

    @impl true
    def scan(_content, _context), do: {:ok, %Verdict{tier: "untrusted", reason_code: :prompt_injection}}
  end

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

  describe "reembed_source/2 and reindex_source/2 trust idempotency (D-04 red-team fix)" do
    test "reembed_source/2 preserves a declared trusted tier (never reverts to untrusted)" do
      assert {:ok, source} =
               Knowledge.ingest_source(
                 %{
                   kind: "doc",
                   title: "reembed trusted doc",
                   uri: "file:///reembed-trusted.md",
                   body: "Content that must stay trusted across a re-embed."
                 },
                 scope: @scope,
                 trust: "trusted"
               )

      [chunk | _] = Knowledge.list_source_chunks(source.id, scope: @scope)
      assert Trust.tier(chunk.metadata) == "trusted"

      assert {:ok, reembedded_chunks} = Knowledge.reembed_source(source, scope: @scope)
      refute reembedded_chunks == []

      for reembedded_chunk <- reembedded_chunks do
        assert Trust.tier(reembedded_chunk.metadata) == "trusted"
      end

      [persisted_chunk | _] = Knowledge.list_source_chunks(source.id, scope: @scope)
      assert Trust.tier(persisted_chunk.metadata) == "trusted"
    end

    test "reindex_source/2 preserves a declared trusted tier (never reverts to untrusted)" do
      assert {:ok, source} =
               Knowledge.ingest_source(
                 %{
                   kind: "doc",
                   title: "reindex trusted doc",
                   uri: "file:///reindex-trusted.md",
                   body: "Content that must stay trusted across a re-index."
                 },
                 scope: @scope,
                 trust: "trusted"
               )

      assert {:ok, reindexed_chunks} = Knowledge.reindex_source(source, scope: @scope)
      refute reindexed_chunks == []

      for reindexed_chunk <- reindexed_chunks do
        assert Trust.tier(reindexed_chunk.metadata) == "trusted"
      end

      [persisted_chunk | _] = Knowledge.list_source_chunks(source.id, scope: @scope)
      assert Trust.tier(persisted_chunk.metadata) == "trusted"
    end

    test "a source with no declared trust survives reembed/reindex reading untrusted (unchanged)" do
      assert {:ok, source} =
               Knowledge.ingest_source(
                 %{
                   kind: "doc",
                   title: "reembed untagged doc",
                   uri: "file:///reembed-untagged.md",
                   body: "Content with no declared trust across a re-embed."
                 },
                 scope: @scope
               )

      assert {:ok, reembedded_chunks} = Knowledge.reembed_source(source, scope: @scope)

      for reembedded_chunk <- reembedded_chunks do
        assert Trust.tier(reembedded_chunk.metadata) == "untrusted"
      end

      assert {:ok, reindexed_chunks} = Knowledge.reindex_source(source, scope: @scope)

      for reindexed_chunk <- reindexed_chunks do
        assert Trust.tier(reindexed_chunk.metadata) == "untrusted"
      end
    end

    test "a post-hoc set_source_trust/3 flip survives a subsequent reembed_source/2" do
      assert {:ok, source} =
               Knowledge.create_source(
                 %{
                   kind: "doc",
                   title: "flip-then-reembed doc",
                   uri: "file:///flip-then-reembed.md",
                   digest: "flip-then-reembed-digest"
                 },
                 scope: @scope
               )

      assert {:ok, _chunks} =
               Knowledge.ingest_source(
                 source,
                 scope: @scope,
                 source_payload: %{body: "Flip-then-reembed content."}
               )

      assert {:ok, updated_source, _count} =
               Knowledge.set_source_trust(source, "trusted", scope: @scope)

      assert {:ok, reembedded_chunks} = Knowledge.reembed_source(updated_source, scope: @scope)
      refute reembedded_chunks == []

      for reembedded_chunk <- reembedded_chunks do
        assert Trust.tier(reembedded_chunk.metadata) == "trusted"
      end
    end
  end

  describe "batch-scan wired at Knowledge.retrieve/2 (D-18, D-21)" do
    setup do
      test_pid = self()
      handler_id = "retrieve-trust-span-test-#{System.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        [:scoria, :observe, :span, :stop],
        fn _event, _measurements, span, _config -> send(test_pid, {:retriever_span, span}) end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      :ok
    end

    test "NoOp (no scanner registered): retrieve/2 output is unchanged and the RETRIEVER span carries only the default tier + scanned_count, no reason_code beyond default" do
      assert {:ok, source} =
               Knowledge.ingest_source(
                 %{
                   kind: "doc",
                   title: "noop scan doc",
                   uri: "file:///noop-scan.md",
                   body: "NoOp-scanned content."
                 },
                 scope: @scope
               )

      assert {:ok, %{results: [result]}} =
               Knowledge.retrieve("noop scan query",
                 query_embedding: [0.1, 0.2, 0.3],
                 filters: %{source_id: source.id},
                 scope: @scope
               )

      # Output unchanged -- exactly today's retrieve/2 result shape.
      assert result.chunk_id

      assert_received {:retriever_span, span}
      assert span.attributes["scoria.trust.tier"] == "untrusted"
      assert span.attributes["scoria.trust.scanned_count"] == 1
      refute Map.has_key?(span.attributes, "scoria.trust.reason_code")
    end

    test "a registered flagging scanner tags the RETRIEVER span with reason_code/tier/scanned_count (result set size)" do
      assert {:ok, source} =
               Knowledge.ingest_source(
                 %{
                   kind: "doc",
                   title: "flagged scan doc",
                   uri: "file:///flagged-scan.md",
                   body: "Flagged content."
                 },
                 scope: @scope
               )

      assert {:ok, %{results: [_result]}} =
               Knowledge.retrieve("flagged scan query",
                 query_embedding: [0.1, 0.2, 0.3],
                 filters: %{source_id: source.id},
                 scope: @scope,
                 content_scanner: FlaggingScanner
               )

      assert_received {:retriever_span, span}
      assert span.attributes["scoria.trust.tier"] == "untrusted"
      assert span.attributes["scoria.trust.reason_code"] == :prompt_injection
      assert span.attributes["scoria.trust.scanned_count"] == 1
      assert span.attributes["scoria.trust.scanner"] =~ "FlaggingScanner"
    end
  end
end
