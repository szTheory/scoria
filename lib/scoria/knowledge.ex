defmodule Scoria.Knowledge do
  @moduledoc """
  `Scoria.Knowledge` is the optional knowledge base capability for retrieval,
  citations, and grounding inside a Phoenix app.

  Start with the default runtime first; the default runtime does not require
  knowledge setup, pgvector bootstrap, retrieval, or grounding. Add this module
  when your product intentionally needs host-selected source content to support
  answers and reviewer-visible evidence.

  The host app owns the corpus, tenant membership, source truth, and product
  meaning of retrieved material. Scoria owns tenant-scoped ingestion,
  retrieval-run evidence, citations, and deterministic grounding checks inside
  the embedded boundary.

  See `guides/capabilities/default-runtime.md` for the default-first adoption
  path and `guides/reviewer-verification.md` for the optional knowledge base
  verification suite.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Scoria.Knowledge.Backends.Pgvector
  alias Scoria.Knowledge.Citation
  alias Scoria.Knowledge.CitationFormatter
  alias Scoria.Knowledge.Chunk
  alias Scoria.Knowledge.Chunker
  alias Scoria.Knowledge.Embedder
  alias Scoria.Knowledge.Grounding
  alias Scoria.Knowledge.GroundingScore
  alias Scoria.Knowledge.RetrievalResult
  alias Scoria.Knowledge.RetrievalRun
  alias Scoria.Knowledge.Retrievers.Scrypath
  alias Scoria.Knowledge.Scope
  alias Scoria.Knowledge.Source
  alias Scoria.Observe
  alias Scoria.Observe.Semconv
  alias Scoria.Repo
  alias Scoria.Trust

  # D-05: `opts[:trust]` is the host-override for a Source's canonical trust
  # tier. Accepted by both `create_source/2` and `ingest_source/2` (below);
  # every value routes through `Trust.normalize_tier/1` so a typo fails
  # closed to `Trust.default_tier/0` + fallback telemetry rather than
  # minting a bogus-trusted row.
  def create_source(attrs \\ %{}, opts \\ []) do
    scope = Scope.for_write!(scope_input(attrs, opts))

    attrs =
      attrs
      |> attrs_to_map()
      |> Scope.put_source_attrs(scope)
      |> Map.put_new(:entity_id, Ecto.UUID.generate())
      |> Map.put_new(:version, 1)
      |> Map.put_new(:is_current, true)
      |> Map.put_new_lazy(:digest, fn -> digest_body(attrs) end)
      |> maybe_put_trust_override(opts)

    %Source{}
    |> Source.changeset(attrs)
    |> Repo.insert()
  end

  def ingest_source(source_or_attrs, opts \\ [])

  def ingest_source(%Source{} = source, opts) do
    scope = Scope.for_write!(scope_input(source, opts))
    chunker = Keyword.get(opts, :chunker, Chunker.Default)
    embedder = Keyword.get(opts, :embedder, Embedder.Deterministic)
    backend = Keyword.get(opts, :backend, Pgvector)

    chunks = chunker.chunk(source_or_payload(source, opts), opts)
    embeddings = embedder.embed_chunks(chunks, opts)

    Multi.new()
    |> Multi.run(:source, fn repo, _changes ->
      # D-05: an explicit `opts[:trust]` override is written to
      # `Source.metadata` BEFORE the chunk denormalization below reads it,
      # so a first-create/re-ingest override flows through to every chunk.
      # No-op (no extra write) when `:trust` is absent.
      maybe_apply_trust_override(repo, source, opts)
    end)
    |> Multi.delete_all(
      :delete_chunks,
      from(chunk in Chunk,
        where: chunk.source_id == ^source.id and chunk.tenant_id == ^scope.tenant_id
      )
    )
    |> Multi.run(:chunks, fn repo, %{source: source} ->
      # D-04: the canonical trust tier lives on `source.metadata`; every
      # created chunk denormalizes it onto its OWN `metadata` at ingest so
      # `retrieve/2` (and any other reader) resolves trust with NO Source
      # join on the hot path. Read once here (not per-chunk) since it is
      # the same source for every chunk in this ingest.
      source_tier = Trust.tier(source.metadata || %{})

      chunks
      |> Enum.map(fn chunk_attrs ->
        chunk_attrs
        |> Map.put(:source_id, source.id)
        |> Scope.put_source_attrs(scope)
        |> Map.put(:metadata, Trust.put_tier(Map.get(chunk_attrs, :metadata) || %{}, source_tier))
      end)
      |> Enum.map(fn attrs ->
        %Chunk{}
        |> Chunk.changeset(attrs)
        |> repo.insert()
      end)
      |> collect_multi_results()
    end)
    |> Multi.run(:embedded_chunks, fn _repo, %{chunks: persisted_chunks} ->
      backend.upsert_chunk_embeddings(persisted_chunks, embeddings)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{chunks: persisted_chunks}} -> {:ok, persisted_chunks}
      {:error, _op, reason, _changes} -> {:error, reason}
    end
  end

  def ingest_source(attrs, opts) when is_map(attrs) do
    with {:ok, source} <- create_source(attrs, opts),
         {:ok, _chunks} <-
           ingest_source(
             source,
             opts |> Keyword.put(:source_payload, attrs) |> Keyword.delete(:trust)
           ) do
      {:ok, source}
    end
  end

  def reembed_source(%Source{} = source, opts \\ []) do
    scope = Scope.for_write!(scope_input(source, opts))
    embedder = Keyword.get(opts, :embedder, Embedder.Deterministic)
    backend = Keyword.get(opts, :backend, Pgvector)

    # D-04 red-team fix: re-stamp every chunk's metadata with the tier
    # DERIVED FROM THE STORED `source.metadata` value -- never a fresh
    # `Trust.default_tier()` -- so a re-embed is idempotent w.r.t. trust
    # and never silently reverts a host's declared tier back to
    # "untrusted" (Pitfall 4). Runs BEFORE `list_source_chunks/2` below so
    # the chunks handed to the embedder/backend already carry the
    # preserved metadata.
    preserve_chunk_trust_from_source(source, scope)

    chunks = list_source_chunks(source.id, scope: scope)
    embeddings = embedder.embed_chunks(chunks, opts)
    backend.upsert_chunk_embeddings(chunks, embeddings)
  end

  def reindex_source(%Source{} = source, opts \\ []) do
    scope = Scope.for_write!(scope_input(source, opts))

    with :ok <- Pgvector.delete_source_embeddings(source.id),
         {:ok, chunks} <- reembed_source(source, Keyword.put(opts, :scope, scope)) do
      {:ok, chunks}
    end
  end

  @doc """
  Post-hoc host-override trust API (D-05): writes `tier` onto
  `Source.metadata` AND bulk-updates every EXISTING chunk row for
  `source.id`, scoped to `opts[:scope]`'s `tenant_id` -- mirroring the
  tenant-scoped `WHERE` at `ingest_source/2`'s `Multi.delete_all`
  (`chunk.source_id == ^source.id and chunk.tenant_id == ^scope.tenant_id`).
  A chunk sharing `source_id` under a DIFFERENT `tenant_id` is never
  touched.

  `tier` routes through `Trust.normalize_tier/1` before either write, so a
  host typo fails closed to `Trust.default_tier/0` (+ fallback telemetry)
  rather than minting a bogus-trusted row.

  Returns `{:ok, updated_source, updated_chunk_count}` or `{:error, reason}`.
  """
  @spec set_source_trust(Source.t(), term(), keyword()) ::
          {:ok, Source.t(), non_neg_integer()} | {:error, term()}
  def set_source_trust(%Source{} = source, tier, opts \\ []) do
    scope = Scope.for_write!(scope_input(source, opts))
    normalized_tier = Trust.normalize_tier(tier)

    Multi.new()
    |> Multi.run(:source, fn repo, _changes ->
      source
      |> Source.changeset(%{
        metadata: Map.put(source.metadata || %{}, Trust.tier_key(), normalized_tier)
      })
      |> repo.update()
    end)
    |> Multi.run(:chunks, fn repo, _changes ->
      {count, _} =
        repo.update_all(
          from(chunk in Chunk,
            where: chunk.source_id == ^source.id and chunk.tenant_id == ^scope.tenant_id,
            update: [
              set: [
                metadata:
                  fragment(
                    "? || ?",
                    chunk.metadata,
                    type(^%{Trust.tier_key() => normalized_tier}, :map)
                  )
              ]
            ]
          ),
          []
        )

      {:ok, count}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{source: updated_source, chunks: count}} -> {:ok, updated_source, count}
      {:error, _op, reason, _changes} -> {:error, reason}
    end
  end

  def list_source_chunks(source_or_id, opts \\ [])

  def list_source_chunks(%Source{} = source, opts) do
    scope = Scope.from_opts!(scope_input(source, opts))
    list_source_chunks(source.id, scope: scope)
  end

  def list_source_chunks(source_id, opts) do
    scope = Scope.from_opts!(opts)

    Chunk
    |> Scope.visible_to(scope)
    |> where([chunk], chunk.source_id == ^source_id)
    |> preload(:source)
    |> order_by([chunk], asc: chunk.start_offset)
    |> Repo.all()
  end

  def create_retrieval_run(attrs \\ %{}) do
    attrs = attrs_to_map(attrs)
    scope = Scope.from_opts!(attrs)

    %RetrievalRun{}
    |> RetrievalRun.changeset(
      attrs
      |> Scope.put_audit_attrs(scope)
      |> Map.new()
      |> Map.put_new(:backend, inspect(Pgvector))
      |> Map.put_new(:status, "pending")
      |> Map.put_new(:top_k, 5)
    )
    |> Repo.insert()
  end

  def append_retrieval_results(%RetrievalRun{id: run_id}, results),
    do: append_retrieval_results(run_id, results)

  def append_retrieval_results(run_id, results) do
    Multi.new()
    |> Multi.run(:run, fn repo, _changes ->
      case repo.get(RetrievalRun, run_id) do
        nil -> {:error, :retrieval_run_not_found}
        %RetrievalRun{} = run -> {:ok, run}
      end
    end)
    |> Multi.run(:validated_results, fn repo, %{run: run} ->
      validate_retrieval_results(repo, run, results)
    end)
    |> Multi.run(:results, fn repo, %{run: run, validated_results: validated_results} ->
      run_scope = retrieval_run_scope(run)

      validated_results
      |> Enum.map(fn attrs ->
        attrs
        |> Scope.put_audit_attrs(run_scope)
        |> Map.put(:retrieval_run_id, run.id)
        |> then(&RetrievalResult.changeset(%RetrievalResult{}, &1))
        |> repo.insert()
      end)
      |> collect_multi_results()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{results: persisted_results}} -> {:ok, persisted_results}
      {:error, _op, reason, _changes} -> {:error, reason}
    end
  end

  def create_grounding_score(attrs \\ %{}) do
    %GroundingScore{}
    |> GroundingScore.changeset(attrs)
    |> Repo.insert()
  end

  def build_citations(chunks, opts \\ []) do
    CitationFormatter.build_anchors(chunks, opts)
  end

  def create_citation(attrs \\ %{}, opts \\ [])

  def create_citation(attrs, opts) do
    attrs = attrs_to_map(attrs)
    scope = Scope.for_write!(scope_input(attrs, opts))

    with {:ok, _anchor} <- CitationFormatter.validate_anchor(attrs, scope: scope) do
      attrs =
        attrs
        |> Scope.put_source_attrs(scope)
        |> Map.delete(:scope)

      %Citation{}
      |> Citation.changeset(attrs)
      |> Repo.insert()
    end
  end

  @doc """
  Retrieves chunks for `query_text` and persists the run as both an
  `ai_retrieval_runs` row (kept, system-of-record) and a linked RETRIEVER
  span sharing the same `trace_id`/`span_id` (RETR-01) -- the join between
  the two never comes up empty for a successful call.

  Two distinct ID axes in `opts`, per D-R2/D-R3:

  - `opts[:parent_id]` -- the CALLER's/originating span id, or `nil` to
    root the trace. Scoria never infers this; the host declares it.
  - `opts[:span_id]` -- THIS retrieval's own span id (the join key written
    to both `run.span_id` and the emitted span's `:id`). When omitted, a
    fresh id is minted. **Must be fresh/unique** if supplied -- passing an
    existing `ai_spans.id` PK-collides on flush and is silently dropped.

  Also accepts `opts[:embedder]` (a Scoria.Knowledge.Embedder
  implementation, defaults to `Embedder.Deterministic`) plus
  `opts[:embedding_model]`/`opts[:index_version]`/`opts[:reranker]` and the
  reserved host-declared keys (`feature`/`route`/`archetype`/`intent`,
  ATTR-01) -- all threaded through unmodified onto both persistence sinks
  via Scoria.Observe.Semconv.

  Returns `{:ok, %{run:, results:, trace_id:, span_id:}}` (additive --
  existing callers pattern-matching only `%{run:, results:}` are
  unaffected). Span emission runs only after this with-chain succeeds and
  is isolated so a raising telemetry handler never fails the retrieval
  (D-R6).
  """
  def retrieve(query_text, opts \\ []) do
    scope = Scope.from_opts!(opts)
    opts = Keyword.put(opts, :scope, scope)
    backend = Keyword.get(opts, :backend, Pgvector)
    retriever = Keyword.get(opts, :retriever)
    limit = Keyword.get(opts, :limit, 5)
    filters = Keyword.get(opts, :filters, %{})
    embedder = Keyword.get(opts, :embedder, Embedder.Deterministic)
    started_at = System.monotonic_time(:millisecond)
    started_wall = DateTime.utc_now()
    trace_id = opts[:trace_id] || Ecto.UUID.generate()
    span_id = opts[:span_id] || Ecto.UUID.generate()

    config_map = %{
      embedding_model: resolve_embedding_model(opts, embedder),
      index_version: opts[:index_version] || Application.get_env(:scoria, :index_version),
      reranker: opts[:reranker]
    }

    host_metadata = Map.new(opts)

    results =
      case retriever do
        nil ->
          query_embedding =
            opts[:query_embedding] ||
              embedder.embed_query(query_text, opts)

          backend.similar_chunks(query_embedding, limit: limit, filters: filters, scope: scope)

        Scrypath ->
          Scrypath.retrieve(query_text, opts)

        module ->
          module.retrieve(query_text, opts)
      end

    with {:ok, result_rows} <- results,
         trust_attrs = resolve_trust_attributes(result_rows, opts),
         {:ok, run} <-
           create_retrieval_run(%{
             query_text: query_text,
             backend: inspect(backend),
             retriever: retriever && inspect(retriever),
             top_k: limit,
             filters: filters,
             trace_id: trace_id,
             span_id: span_id,
             scope: scope,
             status: "completed",
             latency_ms: System.monotonic_time(:millisecond) - started_at,
             metadata:
               config_map
               |> Semconv.retrieval_config_attributes()
               |> Semconv.merge_host_declared(host_metadata)
           }),
         {:ok, persisted_results} <- append_retrieval_results(run.id, result_rows) do
      emit_retriever_span(
        config_map,
        host_metadata,
        trace_id,
        span_id,
        opts[:parent_id],
        started_wall,
        trust_attrs
      )

      {:ok, %{run: run, results: persisted_results, trace_id: trace_id, span_id: span_id}}
    end
  end

  # D-18: batch-scans the WHOLE result set in ONE Scoria.Trust.Scan call
  # (scanned_count = the result-set size), rather than per-chunk -- this is
  # the taint-MINTING chokepoint for retrieval (a host that assembles its
  # own prompt would never call Scoria.Spotlight.render, so scan must fire
  # here, not only there). The scanner is resolved via `Keyword.get(opts,
  # :content_scanner, ...)` (D-17, matching the existing
  # `:embedder`/`:retriever` opts idiom on this same keyword-list `opts`
  # container).
  #
  # `incoming_tier` is the aggregate of every result row's ALREADY
  # DENORMALIZED chunk-metadata trust tier (Plan 01, D-04) -- "untrusted"
  # if ANY row resolves untrusted, else "trusted" -- mirroring
  # `Scoria.Spotlight.Marked`'s call-level tier aggregation (55-03). No
  # `Source` join is added; `Trust.tier/1` reads `row.metadata` directly.
  defp resolve_trust_attributes(result_rows, opts) do
    scanner =
      Keyword.get(opts, :content_scanner, Application.get_env(:scoria, :content_scanner, Scoria.Trust.Scanner.NoOp))

    incoming_tier = aggregate_incoming_tier(result_rows)

    {:ok, verdict} =
      Trust.scan(%{chunks: result_rows}, %{content_scanner: scanner, incoming_tier: incoming_tier})

    Semconv.trust_attributes(%{
      tier: verdict.tier,
      scanner: verdict.scanner && inspect(verdict.scanner),
      reason_code: verdict.reason_code,
      scanned_count: length(result_rows)
    })
  end

  defp aggregate_incoming_tier(result_rows) do
    Enum.reduce(result_rows, "trusted", fn row, acc ->
      if Trust.tier(row.metadata) == "untrusted", do: "untrusted", else: acc
    end)
  end

  # opts[:embedding_model] wins outright. When the host supplied its own
  # query_embedding (opts[:query_embedding]), Scoria never invoked `embedder`
  # to produce it, so calling embedder.model_name/0 here would misattribute
  # provenance -- fall through to the "none" sentinel instead (D-RETR02-2).
  # Otherwise call the OPTIONAL model_name/0 callback only when the embedder
  # module actually implements it (@optional_callbacks, D-RETR02-5) -- a host
  # embedder without it must fall through, never UndefinedFunctionError.
  defp resolve_embedding_model(opts, embedder) do
    cond do
      opts[:embedding_model] -> opts[:embedding_model]
      opts[:query_embedding] -> nil
      function_exported?(embedder, :model_name, 0) -> embedder.model_name()
      true -> nil
    end
  end

  # Emitted only after the with-chain above succeeds (success-path only,
  # D-R6/RETR-01) and isolated with try/rescue so a raising telemetry
  # handler can never propagate into retrieve/2's caller. Observe.emit_retriever_span/1
  # already wraps its own :telemetry.execute in try/rescue -> :ok; this is a
  # second, defense-in-depth layer per the task's explicit instruction.
  #
  # D-21: `trust_attrs` (the projected `scoria.trust.*` map from
  # `resolve_trust_attributes/2`) folds into the SAME RETRIEVER span's
  # attributes -- no new span, no Guardrail.emit/1.
  defp emit_retriever_span(config_map, host_metadata, trace_id, span_id, parent_id, started_wall, trust_attrs) do
    Observe.emit_retriever_span(%{
      config_map: config_map,
      host_metadata: host_metadata,
      trace_id: trace_id,
      span_id: span_id,
      parent_id: parent_id,
      started_wall: started_wall,
      trust_attributes: trust_attrs
    })
  rescue
    _ -> :ok
  end

  def list_retrieval_results(%RetrievalRun{id: run_id}), do: list_retrieval_results(run_id)

  def list_retrieval_results(run_id) do
    RetrievalResult
    |> where([result], result.retrieval_run_id == ^run_id)
    |> order_by([result], asc: result.rank)
    |> Repo.all()
  end

  def score_grounding(payload, opts \\ []) do
    payload =
      payload
      |> attrs_to_map()
      |> Map.merge(attrs_to_map(opts))

    checks = [
      {"citation_presence", Grounding.score_citation_presence(payload)},
      {"citation_validity", Grounding.score_citation_validity(payload, opts)},
      {"chunk_membership", Grounding.score_chunk_membership(payload.answer || "", payload)},
      {"unsupported_claims", Grounding.score_unsupported_claims(payload.answer || "", payload)},
      {"retrieval_hits", Grounding.score_retrieval_hits(payload.results || [], payload)},
      {"retrieval_ranking", Grounding.score_retrieval_ranking(payload.results || [], payload)}
    ]

    deterministic_scores =
      Enum.map(checks, fn {scorer_kind, result} ->
        create_grounding_score(%{
          retrieval_run_id: payload[:retrieval_run_id],
          citation_id: payload[:citation_id],
          scorer_kind: scorer_kind,
          rubric_version: Keyword.get(opts, :rubric_version, "deterministic-v1"),
          score: result.score,
          status: result.status,
          reasoning: "Deterministic grounding check",
          details: result.details,
          evidence_refs: %{
            citations: Enum.map(payload[:citations] || [], &Map.take(&1, [:chunk_id, :source_id]))
          }
        })
      end)

    case Enum.find(deterministic_scores, &match?({:error, _}, &1)) do
      nil ->
        maybe_append_judge_score(deterministic_scores, payload, opts)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_append_judge_score(scores, payload, opts) do
    case opts[:judge_result] do
      nil ->
        {:ok, Enum.map(scores, fn {:ok, score} -> score end)}

      judge_result ->
        with {:ok, score} <-
               create_grounding_score(%{
                 retrieval_run_id: payload[:retrieval_run_id],
                 citation_id: payload[:citation_id],
                 scorer_kind: Map.get(judge_result, :scorer_kind, "judge"),
                 rubric_version: Map.get(judge_result, :rubric_version, "judge-v1"),
                 model: Map.get(judge_result, :model),
                 prompt_version: Map.get(judge_result, :prompt_version),
                 score: Map.get(judge_result, :score, 0.0),
                 status: Map.get(judge_result, :status, "passed"),
                 reasoning: Map.get(judge_result, :reasoning),
                 details: Map.get(judge_result, :details, %{}),
                 evidence_refs: Map.get(judge_result, :evidence_refs, %{})
               }) do
          {:ok, Enum.map(scores, fn {:ok, deterministic} -> deterministic end) ++ [score]}
        end
    end
  end

  # D-05: applied inside `create_source/2` -- when `opts[:trust]` is present,
  # normalize it and stamp it onto the about-to-be-inserted Source's
  # `:metadata`. Absent `:trust` is a no-op (existing/default metadata
  # governs, per `Trust.tier/1`'s fail-closed default).
  defp maybe_put_trust_override(attrs, opts) do
    case Keyword.fetch(opts, :trust) do
      :error ->
        attrs

      {:ok, trust} ->
        Map.put(attrs, :metadata, Trust.put_tier(Map.get(attrs, :metadata) || %{}, trust))
    end
  end

  # D-05: applied inside `ingest_source/2` -- when `opts[:trust]` is
  # present, normalize it and PERSIST it onto the existing Source row's
  # `:metadata` before the chunk-denormalization step reads it, so a
  # re-ingest override flows through to every chunk. Absent `:trust` is a
  # no-op read-through (no extra write), preserving whatever tier is
  # already stored on `source.metadata`.
  defp maybe_apply_trust_override(repo, %Source{} = source, opts) do
    case Keyword.fetch(opts, :trust) do
      :error ->
        {:ok, source}

      {:ok, trust} ->
        source
        |> Source.changeset(%{metadata: Trust.put_tier(source.metadata || %{}, trust)})
        |> repo.update()
    end
  end

  # D-04 red-team fix / Pitfall 4: derives the tier from the STORED
  # `source.metadata` (via `Trust.tier/1`, itself fail-closed) and
  # re-stamps it onto every chunk row for this source, scoped by
  # `tenant_id` -- the same tenant-scoped `WHERE` shape used by
  # `ingest_source/2`'s `Multi.delete_all` and `set_source_trust/3`'s bulk
  # update. Never reconstructs chunk attrs with `Trust.default_tier()`.
  defp preserve_chunk_trust_from_source(%Source{} = source, %Scope{} = scope) do
    source_tier = Trust.tier(source.metadata || %{})

    Repo.update_all(
      from(chunk in Chunk,
        where: chunk.source_id == ^source.id and chunk.tenant_id == ^scope.tenant_id,
        update: [
          set: [
            metadata:
              fragment(
                "? || ?",
                chunk.metadata,
                type(^%{Trust.tier_key() => source_tier}, :map)
              )
          ]
        ]
      ),
      []
    )

    :ok
  end

  defp source_or_payload(source, opts) do
    opts[:source_payload]
    |> case do
      nil -> Map.from_struct(source)
      payload -> Map.merge(Map.from_struct(source), payload)
    end
  end

  defp scope_input(attrs, opts) do
    attrs
    |> attrs_to_map()
    |> Map.merge(attrs_to_map(opts))
  end

  defp attrs_to_map(%_{} = attrs), do: attrs |> Map.from_struct() |> attrs_to_map()
  defp attrs_to_map(attrs) when is_list(attrs), do: Enum.into(attrs, %{})
  defp attrs_to_map(attrs) when is_map(attrs), do: attrs
  defp attrs_to_map(nil), do: %{}

  defp validate_retrieval_results(repo, %RetrievalRun{} = run, results) do
    scope = retrieval_run_scope(run)

    results
    |> Enum.map(&attrs_to_map/1)
    |> Enum.reduce_while({:ok, []}, fn attrs, {:ok, acc} ->
      case validate_retrieval_result(repo, attrs, scope) do
        :ok -> {:cont, {:ok, [attrs | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, validated} -> {:ok, Enum.reverse(validated)}
      error -> error
    end
  end

  defp validate_retrieval_result(repo, attrs, scope) do
    chunk_id = get_attr(attrs, :chunk_id)
    source_id = get_attr(attrs, :source_id)

    cond do
      is_nil(chunk_id) ->
        {:error, {:invalid_retrieval_result, :missing_chunk_id}}

      is_nil(source_id) ->
        {:error, {:invalid_retrieval_result, :missing_source_id}}

      not visible_source?(repo, source_id, scope) ->
        {:error, {:invalid_retrieval_result, :source_not_visible, source_id}}

      not visible_chunk?(repo, chunk_id, source_id, scope) ->
        {:error, {:invalid_retrieval_result, :chunk_not_visible, chunk_id}}

      true ->
        :ok
    end
  end

  defp visible_source?(repo, source_id, scope) do
    Source
    |> Scope.visible_to(scope)
    |> where([source], source.id == ^source_id)
    |> select([_source], true)
    |> limit(1)
    |> repo.one()
    |> Kernel.==(true)
  end

  defp visible_chunk?(repo, chunk_id, source_id, scope) do
    Chunk
    |> Scope.visible_to(scope)
    |> where([chunk], chunk.id == ^chunk_id and chunk.source_id == ^source_id)
    |> select([_chunk], true)
    |> limit(1)
    |> repo.one()
    |> Kernel.==(true)
  end

  defp retrieval_run_scope(%RetrievalRun{} = run) do
    Scope.from_opts!(tenant_id: run.tenant_id, actor_id: run.actor_id)
  end

  defp get_attr(attrs, key) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end

  defp digest_body(attrs) do
    body =
      Map.get(attrs, :body) ||
        Map.get(attrs, "body") ||
        [Map.get(attrs, :title), Map.get(attrs, :uri)]
        |> Enum.reject(&is_nil/1)
        |> Enum.join(":")

    :crypto.hash(:sha256, body) |> Base.encode16(case: :lower)
  end

  defp collect_multi_results(results) do
    case Enum.find(results, fn {status, _value} -> status == :error end) do
      nil -> {:ok, Enum.map(results, fn {:ok, value} -> value end)}
      {:error, reason} -> {:error, reason}
    end
  end
end
