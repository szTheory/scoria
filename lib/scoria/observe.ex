defmodule Scoria.Observe do
  @moduledoc """
  Host-facing span-emission facade.

  The single transparent primitive every producer in this phase funnels
  through is `span/4` (D-01a): it mints a span, runs the host's `fun`, times
  it from the monotonic clock, marks `status_code: "ERROR"` on failure, and
  reraises the host's exception unchanged (D-01d, SC#3). `with_tool/3`,
  `with_prompt/3`, and `with_guardrail/3` are thin kind wrappers over it
  (D-01b). `trace_id_for_run/1` returns a run's id verbatim — a run IS a
  trace (D-03a).

  Two symmetric legacy-shaped emitters remain for hosts that have an
  already-completed span to describe (no `fun` to run), keeping
  `Scoria.Knowledge`/host prompt-assembly code free of span plumbing
  (consumer-not-provider DNA):

  - `emit_retriever_span/1` — the RETR-01 spine. `Scoria.Knowledge.retrieve/2`
    calls this after its `with`-chain succeeds, emitting a RETRIEVER-kind
    span alongside the `ai_retrieval_runs` system-of-record row it already
    writes (dual-write, not a replacement).
  - `emit_prompt_span/1` — the ATTR-02 lane and the D-ATTR01-7 resolution.
    `req_llm`'s native telemetry does not forward arbitrary host metadata
    (verified — RESEARCH.md §8b), so a host that wants `feature`/`route`/
    `archetype`/`intent` and context-pack composition attributes on the
    trace calls this Scoria-owned helper directly at prompt-assembly time.

  `span/4` and both legacy emitters build their span map through one shared
  private builder (single origin, D-00c) and emit it on the shared
  `[:scoria, :observe, :span, :stop]` event — the same event the Phase-51
  adapters (`Scoria.Observe.Adapters.ReqLLM`/`Jido`) use — so redaction,
  `ReviewerBroadcast`, and the FK-safe `Buffer` flush apply identically.
  Every span mints a fresh own `:id` when the caller omits `:span_id` (own-id
  semantics, Phase-52 D-R2 — passing an existing span's id PK-collides and
  is silently dropped by the `insert_all` with no `on_conflict`), and the
  emit itself is wrapped in `try/rescue -> :ok` so a raising telemetry
  handler can never propagate into the caller's business logic (D-R6
  continuity). This is a deliberate asymmetry: the EMIT is swallowed, the
  HOST'S exception is not — `span/4` is transparent to the caller's failure
  and opaque to its own.

  **`:telemetry.span/3` prior art (D-01d):** `:telemetry.span/3`
  (hexdocs.pm/telemetry) already implements this catch-mark-reraise
  contract — "if an exception does occur, an `EventPrefix ++ [exception]`
  event will be emitted and the caught error will be re-raised" — so this
  shape is the ecosystem-standard idiom, not a Scoria invention. Scoria
  does not call `:telemetry.span/3` directly only because every existing
  consumer (`Telemetry.handle_event/4`, `Buffer`, `ReviewerBroadcast`) is
  wired to a single flat `[:scoria, :observe, :span, :stop]` event rather
  than telemetry's three-event start/stop/exception shape. For comparison,
  OpenTelemetry's own `with_span/3` is `try...after` — it does NOT catch,
  does NOT set an error status, and records no exception; Scoria's
  `try/rescue -> ERROR + reraise` is strictly stronger than that reference
  implementation.

  **Explicit context, no implicit process-local variant (D-02b):**
  `parent_id`/`trace_id`/`span_id` are ALWAYS explicit opts on `span/4` and
  its wrappers. An implicit process-local context variant (an ambient
  "current span" resolved from process dictionary or similar) was
  considered and deliberately cut — not one of this phase's producers (a
  pre-run release gate, the workflow runtime, two Oban job processes) runs
  in a process where an ambient span context would resolve correctly. This
  is a known, deliberate deferral, not an oversight.

  **Phase-53 continuity note (historical):** `emit_prompt_span/1` used to
  carry ATTR-02 composition attributes on a zero-duration composition span
  only. It now shares `span/4`'s span-map builder and double-writes
  `tenant_id`/`workflow_run_id`/`session_id` like every other producer
  (D-00c/D-01e). The same Semconv keys (`Semconv.prompt_context_key/0`, the
  usage input-tokens key) that were promised to relocate onto a real
  PROMPT child span with zero contract change (D-ATTR02-1) do so here.

  **`emit_event/1` — the point-event vocabulary (Phase 53B, EVENT-02).**
  Unlike `span/4` and the two span emitters above, `emit_event/1` does not
  describe a duration — it announces that something happened at an instant
  in a trace's lifetime. The vocabulary is closed and small:
  `Semconv.event_names/0` (`prompt_rendered`, `guardrail_triggered`,
  `user_feedback_received`), checked by up-front MEMBERSHIP only
  (`Semconv.event_name?/1` — never `String.to_atom` on inbound data,
  D-03a). `user_feedback_received` is RESERVED-ONLY in this milestone: it
  has no `lib/` emitter yet (SEED-011 / FB-01 flywheel work); calling
  `emit_event/1` with that name still fires the telemetry event today, but
  nothing in `lib/` does so.

  `emit_event/1` executes `[:scoria, :observe, :event, :emit]` telemetry
  for a member name and returns `:ok`, or returns `{:error, :unknown_event}`
  for a non-member WITHOUT executing any telemetry (a clean bus + a
  synchronous DX signal for the caller). Like `span/4`'s emit, the whole
  body is wrapped `try/rescue -> :ok` — it never raises, mirroring the
  Phase 51 D-05..D-09 never-raise continuity every producer in this module
  upholds.

  **Forward flag (D-00b):** if Scoria ever adds an OTLP exporter,
  `guardrail_triggered` MUST be exported as a log record / a separate
  signal, NEVER as an OTel span event — point events in this vocabulary are
  Scoria-internal persistence records today, not OTel span-event-shaped
  data, and that distinction must not be lost if/when an exporter is built.
  """

  alias Scoria.Observe.Semconv
  alias Scoria.Observe.SpanKind

  @doc """
  The single transparent span primitive (D-01a). Runs `fun.()` inside a
  `try`, measures its duration from `System.monotonic_time/0`, and returns
  `fun`'s value verbatim on success — `span/4` never transforms the
  caller's return.

  On every outcome — success, a raised exception, or a thrown/exited value
  — EXACTLY ONE span is emitted (RESEARCH Pitfall 1): each outcome branch
  owns its own single emit-then-return/reraise, and there is no emit call
  reachable after the `try` block.

  - Normal return: emits `status_code: "OK"` and returns `value` verbatim.
  - `rescue e`: emits `status_code: "ERROR"` with `Semconv.error_attributes/1`
    merged into attributes, then `reraise e, __STACKTRACE__` — the host's
    exception struct, message, and original stacktrace reach the caller
    unchanged (D-01d, SC#3).
  - `catch kind, reason` (a throw or an exit): emits `status_code: "ERROR"`
    with type-only error attributes, then `:erlang.raise(kind, reason,
    __STACKTRACE__)` — `reraise/2` only covers the `rescue` case, a
    throw/exit needs the BIF.

  `__STACKTRACE__` is only bound inside its matching `rescue`/`catch`
  clause — this is exactly why the reraise/raise must live inside that
  branch; hoisting it out (or sharing one emit call across branches) is the
  double-emit footgun Test 5 exists to catch.

  `opts` (a map or keyword list) accepts `:trace_id`, `:parent_id`,
  `:span_id` (own-id semantics — a fresh id is minted when omitted, D-R2),
  `:tenant_id`, `:workflow_run_id`, `:session_id`, `:attributes` (a
  pre-built map merged into the span's attributes), plus the four
  `Semconv.host_declared_keys/0` values read directly off `opts`.

  The emit itself stays wrapped `try/rescue -> :ok` (Phase-52 D-R6
  continuity) — a raising telemetry handler can never reach the caller.
  """
  @spec span(String.t(), String.t(), map() | keyword(), (-> any())) :: any()
  def span(kind, name, opts, fun) when is_function(fun, 0) do
    opts = normalize_opts(opts)
    start_wall = DateTime.utc_now()
    start_mono = System.monotonic_time()

    try do
      fun.()
    rescue
      e ->
        emit_outcome_span(kind, name, opts, "ERROR", start_wall, start_mono, Semconv.error_attributes(e))
        reraise e, __STACKTRACE__
    catch
      error_kind, reason ->
        emit_outcome_span(
          kind,
          name,
          opts,
          "ERROR",
          start_wall,
          start_mono,
          Semconv.error_attributes({error_kind, reason})
        )

        :erlang.raise(error_kind, reason, __STACKTRACE__)
    else
      value ->
        emit_outcome_span(kind, name, opts, "OK", start_wall, start_mono, %{})
        value
    end
  end

  @doc """
  Thin `tool`-kind wrapper over `span/4` (D-01b).
  """
  @spec with_tool(String.t(), map() | keyword(), (-> any())) :: any()
  def with_tool(name, opts, fun), do: span("tool", name, opts, fun)

  @doc """
  Thin `prompt`-kind wrapper over `span/4` (D-01b).
  """
  @spec with_prompt(String.t(), map() | keyword(), (-> any())) :: any()
  def with_prompt(name, opts, fun), do: span("prompt", name, opts, fun)

  @doc """
  Thin `guardrail`-kind wrapper over `span/4` (D-01b).
  """
  @spec with_guardrail(String.t(), map() | keyword(), (-> any())) :: any()
  def with_guardrail(name, opts, fun), do: span("guardrail", name, opts, fun)

  @doc """
  Returns the trace id for a workflow run — a RUN IS A TRACE (D-03a).

  Accepts either a `%Scoria.Workflows.Run{}` struct or a raw run id binary
  and returns the run's id verbatim. This is safe by construction:
  `ai_spans.trace_id` FKs to `ai_traces`, `Buffer` upserts trace rows
  idempotently (`insert_all ... on_conflict: :nothing, conflict_target:
  [:id]`), and `ai_traces.id` has no other producer — so reusing `run.id`
  as a trace id is FK-safe and collision-free, and it creates the
  run↔trace join the operator surface already assumes (`OrchestratorLive`
  renders `trace[:workflow_run_id]`). Before this, both Phase-51 adapters
  fell back to `metadata[:trace_id] || Ecto.UUID.generate()` — a fresh
  random orphan trace per span with no run join at all.
  """
  @spec trace_id_for_run(Scoria.Workflows.Run.t() | binary()) :: binary()
  def trace_id_for_run(%Scoria.Workflows.Run{id: id}), do: id
  def trace_id_for_run(run_id) when is_binary(run_id), do: run_id

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
  - `:trust_attributes` — a pre-projected `scoria.trust.*` attribute map
    (`Semconv.trust_attributes/1`'s output, D-21) merged onto this SAME
    RETRIEVER span's attributes — the taint-MINTING chokepoint's scan
    verdict tagging. Defaults to `%{}` (no scanner registered / no tags).

  Emits `:telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)`
  wrapped in `try/rescue -> :ok` (D-R6) — a raising handler never
  propagates into the caller. Always returns `:ok`. Success-path only for
  v3.6 (D-R6) — call this only after the retrieval `with`-chain succeeds.
  """
  @spec emit_retriever_span(map()) :: :ok
  def emit_retriever_span(opts) when is_map(opts) do
    config_map = opts[:config_map] || %{}
    host_metadata = opts[:host_metadata] || %{}
    trust_attributes = opts[:trust_attributes] || %{}

    attributes =
      Semconv.retrieval_config_attributes(config_map)
      |> Semconv.merge_host_declared(host_metadata)
      |> Map.merge(trust_attributes)

    span =
      build_span_map(
        "retriever",
        "knowledge.retrieve",
        opts,
        "OK",
        opts[:started_wall] || DateTime.utc_now(),
        DateTime.utc_now(),
        attributes
      )

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
      |> Semconv.merge_host_declared(opts)
      |> maybe_put_prompt_context(opts[:context_pack])
      |> Semconv.merge_usage_input_tokens(opts[:input_tokens])

    span =
      build_span_map(
        "prompt",
        "prompt.compose",
        opts,
        "OK",
        DateTime.utc_now(),
        DateTime.utc_now(),
        attributes
      )

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

  # -- span/4 internals --------------------------------------------------

  # span/4's opts type is `map() | keyword()` -- normalize once at the top
  # so every downstream helper (build_span_map/7, Semconv.merge_host_declared/2,
  # which uses Map.get/2 internally) can assume a map.
  defp normalize_opts(opts) when is_map(opts), do: opts
  defp normalize_opts(opts) when is_list(opts), do: Map.new(opts)

  # Computes end_time from the monotonic clock so `end_time - start_time`
  # is a real, monotonic-derived interval rather than two back-to-back wall
  # reads (the bug this replaces in the legacy emitters). `max(elapsed_us,
  # 1)` guarantees end_time is strictly after start_time even for a
  # near-instant `fun` -- a zero-width span would misrepresent a real
  # function call as having taken no time at all.
  defp monotonic_end_time(start_wall, start_mono) do
    elapsed_native = System.monotonic_time() - start_mono
    elapsed_us = System.convert_time_unit(elapsed_native, :native, :microsecond)
    DateTime.add(start_wall, max(elapsed_us, 1), :microsecond)
  end

  # span/4's single per-outcome-branch emit call. Builds the OpenInference
  # kind attribute + any host-supplied :attributes, merges in
  # outcome-specific attributes (empty on success, Semconv.error_attributes/1
  # on failure), and emits through the same shared builder + emit path the
  # legacy emitters use (single origin, D-00c).
  defp emit_outcome_span(kind, name, opts, status_code, start_wall, start_mono, outcome_attributes) do
    end_time = monotonic_end_time(start_wall, start_mono)

    attributes =
      (opts[:attributes] || %{})
      |> Semconv.merge_host_declared(opts)
      |> Map.merge(outcome_attributes)

    span = build_span_map(kind, name, opts, status_code, start_wall, end_time, attributes)
    emit_span(span)
  end

  # The single origin of every emitted span's shape (D-00c doctrine):
  # span/4's three outcome branches and both legacy emitters
  # (emit_retriever_span/1, emit_prompt_span/1) all call this. Owns the
  # OpenInference span-kind attribute derivation and the tenant_id /
  # workflow_run_id / session_id double-write -- both a top-level span-map
  # field (read by `ReviewerBroadcast.span_stopped/1`, which fail-closes
  # without a top-level `tenant_id`, and by the future `Bounds` tollbooth)
  # AND into `attributes` (read by `OrchestratorLive`'s
  # `attributes->>'tenant_id'` SQL filter and any other attributes-only
  # consumer).
  defp build_span_map(kind, name, opts, status_code, start_time, end_time, attributes) do
    normalized_kind = SpanKind.normalize(kind)

    full_attributes =
      attributes
      |> Map.put(Semconv.openinference_span_kind_key(), SpanKind.to_openinference(normalized_kind))
      |> merge_scoped_ids(opts)

    %{
      name: name,
      span_kind: normalized_kind,
      status_code: status_code,
      start_time: start_time,
      end_time: end_time,
      trace_id: opts[:trace_id],
      id: opts[:span_id] || Ecto.UUID.generate(),
      parent_id: opts[:parent_id],
      tenant_id: opts[:tenant_id],
      workflow_run_id: opts[:workflow_run_id],
      session_id: opts[:session_id],
      attributes: full_attributes
    }
  end

  defp merge_scoped_ids(attributes, opts) do
    attributes
    |> maybe_put_scoped_id("tenant_id", opts[:tenant_id])
    |> maybe_put_scoped_id("workflow_run_id", opts[:workflow_run_id])
    |> maybe_put_scoped_id("session_id", opts[:session_id])
  end

  defp maybe_put_scoped_id(attributes, _key, nil), do: attributes
  defp maybe_put_scoped_id(attributes, key, value), do: Map.put(attributes, key, value)

  defp emit_span(span) do
    :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)
    :ok
  rescue
    _ -> :ok
  end

  @doc """
  Emits a closed-vocabulary point event (EVENT-02): `%{name: name, span_id:
  span_id, attributes: attributes, time: time}`, where `name` is an atom
  member of `Semconv.event_names/0`.

  Checks `Semconv.event_name?/1` UP FRONT — a membership check only, never
  `String.to_atom` on `name` (D-03a). A member fires
  `:telemetry.execute([:scoria, :observe, :event, :emit], %{}, event)` and
  returns `:ok`; a non-member returns `{:error, :unknown_event}` and
  executes NO telemetry at all, keeping the bus clean of events no handler
  should ever see.

  Never raises: the whole body is wrapped `try/rescue -> :ok` (Phase 51
  D-05..D-09 continuity) — a deliberately malformed `event` still returns
  `:ok`, `{:error, :unknown_event}`, or `{:error, :invalid_event}`, never
  propagates an exception to the caller.

  Also validates `:span_id`/`:time` shape up front (WR-02, the public-API
  half of CR-01): a member `name` with a `span_id` that is not a
  UUID-castable binary, or a `time` that is not a `%DateTime{}`, returns
  `{:error, :invalid_event}` and fires NO telemetry — a synchronous signal
  to the caller instead of a silent async drop at the handler seam. This
  mirrors, at the public API, the exact fail-closed check
  `Scoria.Observe.Telemetry`'s handler independently re-applies against the
  raw bus.

  The `[:scoria, :observe, :event, :emit]` handler
  (`Scoria.Observe.Telemetry`) is the real boundary of record: it
  independently re-checks `Semconv.event_name?/1` (closing the raw-bus
  bypass where a caller skips this function and calls `:telemetry.execute/3`
  directly), then redacts, bounds, and persists. This function's up-front
  check exists for synchronous caller DX and a clean bus, not as the only
  gate.
  """
  @spec emit_event(map()) :: :ok | {:error, :unknown_event} | {:error, :invalid_event}
  def emit_event(%{name: name} = event) when is_map(event) do
    cond do
      not Semconv.event_name?(name) ->
        {:error, :unknown_event}

      not valid_event_shape?(event) ->
        {:error, :invalid_event}

      true ->
        :telemetry.execute([:scoria, :observe, :event, :emit], %{}, event)
        :ok
    end
  rescue
    _ -> :ok
  end

  # A malformed call (not a map, or a map with no :name key at all) never
  # reaches the clause above's function head, so it can never hit that
  # clause's try/rescue either -- a bare FunctionClauseError would defeat
  # the never-raises guarantee. This catch-all closes that gap (Rule 2):
  # any shape that isn't `%{name: _}` is simply an unknown event.
  def emit_event(_event), do: {:error, :unknown_event}

  # WR-02: both `:span_id` and `:time` must already be well-formed before
  # this event ever reaches the bus -- `:span_id` must be a UUID-castable
  # binary (the same `Ecto.UUID.cast/1` check `ai_span_events.span_id`'s
  # `:binary_id` column implies) and `:time` must be a real `%DateTime{}`
  # (the same shape `ai_span_events.time`'s `:utc_datetime_usec` column
  # requires). An absent key reads as `nil` via `Map.get/2` and fails both
  # checks, same as an explicit `nil`.
  defp valid_event_shape?(event) do
    valid_span_id?(Map.get(event, :span_id)) and valid_time?(Map.get(event, :time))
  end

  defp valid_span_id?(span_id) when is_binary(span_id) do
    match?({:ok, _}, Ecto.UUID.cast(span_id))
  end

  defp valid_span_id?(_span_id), do: false

  defp valid_time?(%DateTime{}), do: true
  defp valid_time?(_time), do: false
end
