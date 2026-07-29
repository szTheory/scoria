defmodule Scoria.Knowledge.RetrievalTest do
  use Scoria.KnowledgeCase, async: false

  alias Scoria.Knowledge
  alias Scoria.Knowledge.Chunk
  alias Scoria.Knowledge.RetrievalRun
  alias Scoria.Observe.Buffer
  alias Scoria.Observe.Semconv
  alias Scoria.Observe.SpanKind
  alias Scoria.Repo
  alias Scoria.Repo.Span
  alias Scoria.Repo.Trace

  @scope [tenant_id: "tenant-a", actor_id: "actor-a", scope_kind: :tenant_shared]
  @buffer_name :retrieval_test_buffer

  defmodule BackendSpy do
    def similar_chunks(query_embedding, opts) do
      send(self(), {:backend_opts, query_embedding, opts})
      {:ok, []}
    end
  end

  defmodule RetrieverSpy do
    def retrieve(query_text, opts) do
      send(self(), {:retriever_opts, query_text, opts})
      {:ok, []}
    end
  end

  # Real-Postgres RETRIEVER-span assertions (D-R2b, RETR-01, RETR-02, ATTR-01,
  # D-R6) need the actual telemetry -> Buffer -> Postgres pipeline wired,
  # mirroring Scoria.Observe.TelemetryTest's setup -- Scoria's own
  # application supervision tree does not start Buffer/Telemetry (host apps
  # wire that themselves), so tests that need it start/attach it explicitly.
  setup do
    pid =
      start_supervised!(
        {Buffer, [name: @buffer_name, flush_interval: 10_000, max_size: 100]}
      )

    :telemetry.detach("scoria-observe-telemetry")
    Scoria.Observe.Telemetry.attach(@buffer_name)

    on_exit(fn -> :telemetry.detach("scoria-observe-telemetry") end)

    %{buffer: pid}
  end

  test "retrieve/2 persists RetrievalRun and ordered results" do
    assert {:ok, source} =
             Knowledge.ingest_source(
               %{
                 kind: "doc",
                 title: "retrieval",
                 uri: "file:///retrieval.md",
                 body: "retrieval evidence keeps every answer challengeable."
               },
               scope: @scope
             )

    [chunk | _] = Knowledge.list_source_chunks(source.id, scope: @scope)

    {:ok, trace} =
      Repo.insert(%Trace{
        session_id: "session-1",
        attributes: %{}
      })

    {:ok, span} =
      Repo.insert(%Span{
        trace_id: trace.id,
        name: "retrieve",
        start_time: DateTime.utc_now() |> DateTime.truncate(:microsecond)
      })

    # D-R2b migration: opts[:span_id] is redefined to "this retrieval's OWN
    # span id" -- the caller's/originating span is now passed as
    # opts[:parent_id] instead.
    assert {:ok, %{run: %RetrievalRun{} = run, results: [result | _], span_id: returned_span_id}} =
             Knowledge.retrieve("challengeable answer",
               query_embedding: [0.1, 0.2, 0.3],
               filters: %{source_id: source.id},
               scope: @scope,
               trace_id: trace.id,
               parent_id: span.id
             )

    assert run.query_text == "challengeable answer"
    assert run.trace_id == trace.id
    assert run.span_id == returned_span_id
    assert run.tenant_id == "tenant-a"
    assert run.actor_id == "actor-a"
    assert result.chunk_id == chunk.id
    assert result.rank == 1
    assert result.tenant_id == "tenant-a"
    assert result.actor_id == "actor-a"

    :ok = Buffer.flush_now(@buffer_name)

    retriever_span = Repo.get_by!(Span, id: run.span_id)
    assert retriever_span.parent_id == span.id
  end

  test "RETR-01: retrieve/2 produces a linked RETRIEVER span sharing trace_id/span_id with the run" do
    assert {:ok, source} =
             Knowledge.ingest_source(
               %{
                 kind: "doc",
                 title: "retr-01 join",
                 uri: "file:///retr-01-join.md",
                 body: "the retriever span join must never come up empty."
               },
               scope: @scope
             )

    assert {:ok, %{run: run}} =
             Knowledge.retrieve("retriever join query",
               query_embedding: [0.1, 0.2, 0.3],
               filters: %{source_id: source.id},
               scope: @scope
             )

    :ok = Buffer.flush_now(@buffer_name)

    span = Repo.get_by!(Span, id: run.span_id)

    assert span.trace_id == run.trace_id
    assert span.span_kind == SpanKind.normalize("retriever")
    assert span.status_code == "OK"
  end

  test "RETR-02: scoria.retrieval.* keys are equal on span.attributes and run.metadata (single origin)" do
    assert {:ok, source} =
             Knowledge.ingest_source(
               %{
                 kind: "doc",
                 title: "retr-02 equality",
                 uri: "file:///retr-02-equality.md",
                 body: "config keys must never diverge between the two sinks."
               },
               scope: @scope
             )

    assert {:ok, %{run: run}} =
             Knowledge.retrieve("config equality query",
               query_embedding: [0.1, 0.2, 0.3],
               filters: %{source_id: source.id},
               scope: @scope,
               embedding_model: "test-model",
               index_version: "v1"
             )

    :ok = Buffer.flush_now(@buffer_name)

    span = Repo.get_by!(Span, id: run.span_id)
    keys = Keyword.values(Semconv.retrieval_config_keys())

    assert map_size(Map.take(run.metadata, keys)) == 3
    assert Map.take(span.attributes, keys) == Map.take(run.metadata, keys)
    assert run.metadata["scoria.retrieval.embedding_model"] == "test-model"
    assert run.metadata["scoria.retrieval.index_version"] == "v1"
    assert run.metadata["scoria.retrieval.reranker"] == "none"
  end

  test "ATTR-01: host-declared feature value passes through byte-for-byte; omitted keys stay absent" do
    assert {:ok, source} =
             Knowledge.ingest_source(
               %{
                 kind: "doc",
                 title: "attr-01 pass-through",
                 uri: "file:///attr-01-pass-through.md",
                 body: "host-declared values flow through unmodified."
               },
               scope: @scope
             )

    assert {:ok, %{run: run}} =
             Knowledge.retrieve("attr01 query",
               query_embedding: [0.1, 0.2, 0.3],
               filters: %{source_id: source.id},
               scope: @scope,
               feature: "support-copilot"
             )

    :ok = Buffer.flush_now(@buffer_name)

    span = Repo.get_by!(Span, id: run.span_id)

    assert span.attributes["feature"] == "support-copilot"
    refute Map.has_key?(span.attributes, "archetype")
    refute Map.has_key?(span.attributes, "route")
    refute Map.has_key?(span.attributes, "intent")

    assert run.metadata["feature"] == "support-copilot"
    refute Map.has_key?(run.metadata, "archetype")
  end

  test "D-R6: retrieve/2 still succeeds even when the span emit path raises" do
    assert {:ok, source} =
             Knowledge.ingest_source(
               %{
                 kind: "doc",
                 title: "d-r6 emit isolation",
                 uri: "file:///d-r6-emit-isolation.md",
                 body: "span emission must never fail retrieval."
               },
               scope: @scope
             )

    handler_id = "retrieval-test-emit-raiser-#{System.unique_integer([:positive])}"

    :telemetry.attach(
      handler_id,
      [:scoria, :observe, :span, :stop],
      fn _event, _measurements, _span, _config -> raise "boom" end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    assert {:ok, %{run: %RetrievalRun{}}} =
             Knowledge.retrieve("emit raises query",
               query_embedding: [0.1, 0.2, 0.3],
               filters: %{source_id: source.id},
               scope: @scope
             )
  end

  test "retrieve/2 persists the pgvector-projected cosine score unchanged" do
    assert {:ok, source} =
             Knowledge.create_source(
               %{
                 kind: "doc",
                 title: "known vector retrieval",
                 uri: "file:///known-vector.md",
                 body: "known vector retrieval"
               },
               scope: @scope
             )

    exact_chunk = insert_chunk!(source, "exact", [1.0, 0.0, 0.0])
    _orthogonal_chunk = insert_chunk!(source, "orthogonal", [0.0, 1.0, 0.0])

    assert {:ok, %{run: %RetrievalRun{} = run, results: [result | _]}} =
             Knowledge.retrieve("known vector",
               query_embedding: [1.0, 0.0, 0.0],
               filters: %{source_id: source.id},
               scope: @scope
             )

    [persisted_result | _] = Knowledge.list_retrieval_results(run)

    assert result.id == persisted_result.id
    assert persisted_result.chunk_id == exact_chunk.id
    assert persisted_result.rank == 1
    assert_in_delta persisted_result.score, 1.0, 0.000001
    assert persisted_result.tenant_id == "tenant-a"
    assert persisted_result.actor_id == "actor-a"
  end

  test "retrieve/2 passes normalized scope to the backend before persistence" do
    assert {:ok, %{run: %RetrievalRun{}, results: []}} =
             Knowledge.retrieve("scoped backend",
               query_embedding: [0.1, 0.2, 0.3],
               backend: BackendSpy,
               scope: @scope
             )

    assert_receive {:backend_opts, [0.1, 0.2, 0.3], opts}
    assert %Scoria.Knowledge.Scope{tenant_id: "tenant-a", actor_id: "actor-a"} = opts[:scope]
  end

  test "retrieve/2 passes normalized scope to custom retrievers" do
    assert {:ok, %{run: %RetrievalRun{}, results: []}} =
             Knowledge.retrieve("scoped retriever",
               retriever: RetrieverSpy,
               scope: @scope
             )

    assert_receive {:retriever_opts, "scoped retriever", opts}
    assert %Scoria.Knowledge.Scope{tenant_id: "tenant-a", actor_id: "actor-a"} = opts[:scope]
  end

  test "retrieve/2 raises before backend work without tenant scope" do
    assert_raise ArgumentError, ~r/tenant_id is required/, fn ->
      Knowledge.retrieve("missing scope",
        query_embedding: [0.1, 0.2, 0.3],
        backend: BackendSpy
      )
    end

    refute_received {:backend_opts, _embedding, _opts}
  end

  defp insert_chunk!(source, suffix, embedding) do
    scope = Scoria.Knowledge.Scope.for_write!(@scope)

    %Chunk{}
    |> Chunk.changeset(%{
      source_id: source.id,
      tenant_id: scope.tenant_id,
      actor_id: scope.actor_id,
      scope_kind: scope.scope_kind,
      chunk_digest: "retrieval-#{suffix}",
      body: "Retrieval #{suffix}",
      heading_path: [],
      start_offset: 0,
      end_offset: 16,
      token_count: 2,
      embedding: embedding,
      metadata: %{}
    })
    |> Repo.insert!()
  end
end
