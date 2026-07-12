defmodule Scoria.Observe do
  @moduledoc """
  Host-facing span-emission facade — two symmetric emitters hosts call
  directly, keeping `Scoria.Knowledge`/host prompt-assembly code free of
  span plumbing (consumer-not-provider DNA):

  - `emit_retriever_span/1` — the RETR-01 spine. `Scoria.Knowledge.retrieve/2`
    calls this after its `with`-chain succeeds, emitting a RETRIEVER-kind
    span alongside the `ai_retrieval_runs` system-of-record row it already
    writes (dual-write, not a replacement).
  - `emit_prompt_span/1` — the ATTR-02 lane and the D-ATTR01-7 resolution.
    `req_llm`'s native telemetry does not forward arbitrary host metadata
    (verified — RESEARCH.md §8b), so a host that wants `feature`/`route`/
    `archetype`/`intent` and context-pack composition attributes on the
    trace calls this Scoria-owned helper directly at prompt-assembly time.

  Both emitters build a span map and emit it on the shared
  `[:scoria, :observe, :span, :stop]` event — the same event the Phase-51
  adapters (`Scoria.Observe.Adapters.ReqLLM`/`Jido`) use — so redaction,
  `ReviewerBroadcast`, and the FK-safe `Buffer` flush apply identically.
  Both mint a fresh own `:id` and wrap the emit in `try/rescue -> :ok` so a
  raising telemetry handler can never propagate into the caller's business
  logic (D-R6).

  **Phase-53 continuity note:** `emit_prompt_span/1` carries ATTR-02
  composition attributes on this Scoria-emitted composition span. It does
  NOT build a real duration/parent-linked PROMPT child span, `ai_span_events`,
  or the SEC-01 write-time bound — those are Phase 53 / EVENT-01. The same
  Semconv keys (`Semconv.prompt_context_key/0`, the usage input-tokens key)
  relocate onto a real PROMPT child span in Phase 53 with zero contract
  change (D-ATTR02-1).
  """

  alias Scoria.Observe.Semconv
  alias Scoria.Observe.SpanKind

  @doc """
  Builds and emits a RETRIEVER-kind span for one `Scoria.Knowledge.retrieve/2`
  call (RETR-01, the RETR-01 spine).

  `opts` is a map with:
  - `:config_map` — the canonical `%{embedding_model:, index_version:,
    reranker:}` map (RETR-02); projected via
    `Semconv.retrieval_config_attributes/1`.
  - `:host_metadata` — an atom-keyed map that may carry any of
    `Semconv.host_declared_keys/0` (`feature`/`route`/`archetype`/`intent`,
    ATTR-01); merged via `Semconv.merge_host_declared/2`. Extra keys are
    ignored — callers may pass the retrieval opts map as-is.
  - `:trace_id` — the trace this retrieval's span joins.
  - `:span_id` — THIS retrieval's own, freshly-minted span id (D-R2). This
    becomes the span's `:id` explicitly (not left to `Buffer`'s
    `put_new_lazy/2`) and is also written to `ai_retrieval_runs.span_id` by
    the caller so the join between the two never comes up empty. **Must be
    fresh/unique** — passing an existing `ai_spans.id` PK-collides (the
    span `insert_all` has no `on_conflict`) and is silently dropped.
  - `:parent_id` — the caller's/originating span id, or `nil` to root the
    trace (D-R3). Host declares, Scoria never infers.
  - `:started_wall` — the wall-clock `DateTime` captured at the top of
    `retrieve/2`, used as `start_time` (D-R4). The authoritative
    `latency_ms` stays the existing monotonic-clock computation in
    `retrieve/2`; this wall-clock pair is display-only.

  Emits `:telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)`
  wrapped in `try/rescue -> :ok` (D-R6) — a raising handler never
  propagates into the caller. Always returns `:ok`. Success-path only for
  v3.6 (D-R6) — call this only after the retrieval `with`-chain succeeds.
  """
  @spec emit_retriever_span(map()) :: :ok
  def emit_retriever_span(opts) when is_map(opts) do
    config_map = opts[:config_map] || %{}
    host_metadata = opts[:host_metadata] || %{}

    attributes =
      %{}
      |> Map.put(Semconv.openinference_span_kind_key(), SpanKind.to_openinference("retriever"))
      |> Map.merge(Semconv.retrieval_config_attributes(config_map))
      |> Semconv.merge_host_declared(host_metadata)

    span = %{
      name: "knowledge.retrieve",
      span_kind: SpanKind.normalize("retriever"),
      status_code: "OK",
      start_time: opts[:started_wall] || DateTime.utc_now(),
      end_time: DateTime.utc_now(),
      trace_id: opts[:trace_id],
      id: opts[:span_id],
      parent_id: opts[:parent_id],
      attributes: attributes
    }

    emit_span(span)
  end

  @doc """
  Builds and emits a `prompt`-kind composition span carrying host-declared
  keys, context-pack composition, and provider-reported input tokens
  (ATTR-02, resolving the D-ATTR01-7 blocker: `req_llm`'s native telemetry
  cannot forward arbitrary host metadata, so a host that wants these
  attributes on the trace calls this Scoria-owned helper directly).

  `opts` is a map with:
  - `:trace_id` — the trace this prompt-composition span joins (the same
    trace as any linked RETRIEVER span, so operators can join
    retriever → prompt on chunk/memory IDs).
  - `:parent_id` — the caller's/originating span id, or `nil` to root the
    trace. Host declares, Scoria never infers.
  - `:span_id` — this prompt span's OWN id. When omitted, a fresh
    `Ecto.UUID.generate()` is minted (D-R2 own-id semantics) — passing an
    existing span's id would PK-collide and be silently dropped.
  - `:context_pack` — a `%{chunks:, memories:, token_budget:}` map (see
    `Semconv.prompt_context/1`). When absent, or when both `:chunks` and
    `:memories` are empty, `Semconv.prompt_context_key/0` is omitted from
    the span entirely rather than attached as an empty-but-present key
    (D-ATTR02-7).
  - `:input_tokens` — the host-supplied provider usage-total value, merged
    onto the req_llm-owned usage input-tokens key via
    `Semconv.merge_usage_input_tokens/2` (never hand-written here,
    FOUND-03). `nil`/absent omits the key — usage is `nil` on
    embedding-only or failed calls and its presence is never asserted
    unconditionally (D-ATTR02-5).
  - `:feature` / `:route` / `:archetype` / `:intent` — any of
    `Semconv.host_declared_keys/0`, read directly off `opts` and merged via
    `Semconv.merge_host_declared/2` (ATTR-01).

  Never passes raw chunk/memory text — `Semconv.prompt_context/1` maps
  every item to `%{"id" => id, "tokens" => tokens}` only, structurally.

  Emits `:telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)`
  wrapped in `try/rescue -> :ok` (D-R6 mirror). Always returns `:ok`.

  **Phase-53 continuity:** this attaches composition attributes to the
  prompt-composition span now; Phase 53 relocates the identical Semconv
  keys onto a real duration/parent-linked PROMPT child span with zero
  contract change (D-ATTR02-1).
  """
  @spec emit_prompt_span(map()) :: :ok
  def emit_prompt_span(opts) when is_map(opts) do
    attributes =
      %{}
      |> Map.put(Semconv.openinference_span_kind_key(), SpanKind.to_openinference("prompt"))
      |> Semconv.merge_host_declared(opts)
      |> maybe_put_prompt_context(opts[:context_pack])
      |> Semconv.merge_usage_input_tokens(opts[:input_tokens])

    span = %{
      name: "prompt.compose",
      span_kind: SpanKind.normalize("prompt"),
      status_code: "OK",
      start_time: DateTime.utc_now(),
      end_time: DateTime.utc_now(),
      trace_id: opts[:trace_id],
      id: opts[:span_id] || Ecto.UUID.generate(),
      parent_id: opts[:parent_id],
      attributes: attributes
    }

    emit_span(span)
  end

  defp maybe_put_prompt_context(attributes, nil), do: attributes

  defp maybe_put_prompt_context(attributes, %{chunks: chunks, memories: memories} = pack) do
    if Enum.empty?(chunks) and Enum.empty?(memories) do
      attributes
    else
      Map.put(attributes, Semconv.prompt_context_key(), Semconv.prompt_context(pack))
    end
  end

  defp maybe_put_prompt_context(attributes, _pack), do: attributes

  defp emit_span(span) do
    :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)
    :ok
  rescue
    _ -> :ok
  end
end
