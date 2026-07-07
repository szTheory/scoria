defmodule Scoria.Knowledge do
  @moduledoc """
  Durable knowledge context for corpus ingestion, retrieval, citations, and grounding.
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
  alias Scoria.Repo

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
    |> Multi.delete_all(
      :delete_chunks,
      from(chunk in Chunk,
        where: chunk.source_id == ^source.id and chunk.tenant_id == ^scope.tenant_id
      )
    )
    |> Multi.run(:chunks, fn repo, _changes ->
      chunks
      |> Enum.map(&(&1 |> Map.put(:source_id, source.id) |> Scope.put_source_attrs(scope)))
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
         {:ok, _chunks} <- ingest_source(source, Keyword.put(opts, :source_payload, attrs)) do
      {:ok, source}
    end
  end

  def reembed_source(%Source{} = source, opts \\ []) do
    scope = Scope.for_write!(scope_input(source, opts))
    embedder = Keyword.get(opts, :embedder, Embedder.Deterministic)
    backend = Keyword.get(opts, :backend, Pgvector)
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

  def create_citation(attrs \\ %{}) do
    %Citation{}
    |> Citation.changeset(attrs)
    |> Repo.insert()
  end

  def retrieve(query_text, opts \\ []) do
    scope = Scope.from_opts!(opts)
    opts = Keyword.put(opts, :scope, scope)
    backend = Keyword.get(opts, :backend, Pgvector)
    retriever = Keyword.get(opts, :retriever)
    limit = Keyword.get(opts, :limit, 5)
    filters = Keyword.get(opts, :filters, %{})
    started_at = System.monotonic_time(:millisecond)

    results =
      case retriever do
        nil ->
          query_embedding =
            opts[:query_embedding] ||
              Embedder.Deterministic.embed_query(query_text, opts)

          backend.similar_chunks(query_embedding, limit: limit, filters: filters)

        Scrypath ->
          Scrypath.retrieve(query_text, opts)

        module ->
          module.retrieve(query_text, opts)
      end

    with {:ok, result_rows} <- results,
         {:ok, run} <-
           create_retrieval_run(%{
             query_text: query_text,
             backend: inspect(backend),
             retriever: retriever && inspect(retriever),
             top_k: limit,
             filters: filters,
             trace_id: opts[:trace_id],
             span_id: opts[:span_id],
             scope: scope,
             status: "completed",
             latency_ms: System.monotonic_time(:millisecond) - started_at
           }),
         {:ok, persisted_results} <- append_retrieval_results(run.id, result_rows) do
      {:ok, %{run: run, results: persisted_results}}
    end
  end

  def list_retrieval_results(%RetrievalRun{id: run_id}), do: list_retrieval_results(run_id)

  def list_retrieval_results(run_id) do
    RetrievalResult
    |> where([result], result.retrieval_run_id == ^run_id)
    |> order_by([result], asc: result.rank)
    |> Repo.all()
  end

  def score_grounding(payload, opts \\ []) do
    checks = [
      {"citation_presence", Grounding.score_citation_presence(payload)},
      {"citation_validity", Grounding.score_citation_validity(payload)},
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
