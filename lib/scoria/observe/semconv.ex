defmodule Scoria.Observe.Semconv do
  @moduledoc """
  Single source for every semconv key Scoria itself defines, plus the one
  call site that merges the req_llm-owned `gen_ai.*` attribute set.

  `gen_ai.*` key STRINGS are owned and version-pinned by the `req_llm ~> 1.13`
  dependency (`ReqLLM.OpenTelemetry.Attributes`, OTel-GenAI schema 1.37.0 —
  see `deps/req_llm/lib/req_llm/open_telemetry.ex` `@otel_schema_url`). Do
  NOT hand-duplicate those key names here; call the builder.

  This module owns:
  - the one key Scoria itself writes: `"openinference.span.kind"`
  - the retrieval-config keys (`scoria.retrieval.*`) — embedding model, index
    version, reranker
  - reserved host-declared keys: `feature`/`route`/`archetype`/`intent`
  - the prompt-context key (`scoria.prompt.context`) — never-text
    id/token-count-only projection of a host-supplied context pack
  - `attribute_registry/0` — the CLOSED `%{key => class}` registry that is
    the single origin of every attribute key Scoria itself may persist
    (SEC-01, D-06b). `attribute_classes/0` is a deliberately closed
    six-value vocabulary (`:id`, `:count`, `:enum`, `:flag`, `:timestamp`,
    `:structured`) — **there is no `:free_text` class; it is
    unrepresentable by construction.** A Scoria developer cannot register a
    key for model-generated prose without inventing a seventh class, and
    the class-exhaustiveness test goes RED on a seventh class while the
    registry canary test goes RED on any new key. INV-SEC01: the set of
    attribute keys Scoria itself can persist is exactly
    `attribute_registry/0`'s key set, and no registry entry may declare a
    free-text class.
  - the guardrail vocabulary (D-05f) — `guardrail_names/0`,
    `guardrail_decisions/0` (`"modify"` is RESERVED per D-05h — a future
    `modify` decision would carry an XACML *obligation* the caller MUST
    discharge or deny, fail-closed; it is deliberately absent from the
    active enum), `guardrail_reason_codes/0` (not invented — these atoms
    already come back from `ReleaseGate.check/1` and
    `BreakerRegistry`; we are refusing to widen the enum, not defining
    it), and `guardrail_attributes/1`, a fixed five-key projector with no
    host-map spread — the structural reason a caller cannot smuggle a
    free-text `reason` key onto a guardrail span (D-05g).
  - `error_attributes/1` — a type-only exception projection
    (`exception.type` / `error.type`, both the module name, never
    `Exception.message/1` or `__STACKTRACE__`). This deliberately inverts
    OpenInference's `OPENINFERENCE_HIDE_INPUTS`/`HIDE_OUTPUTS` capture-by-
    default posture (both default `False` upstream): Scoria mirrors the
    vocabulary and inverts the default (D-06g).
  """

  require Logger

  @openinference_span_kind_key "openinference.span.kind"

  @doc "Returns the canonical OpenInference span-kind attribute key."
  @spec openinference_span_kind_key() :: String.t()
  def openinference_span_kind_key, do: @openinference_span_kind_key

  @doc """
  Merges the req_llm-owned `gen_ai.*` attribute set for a request/response
  telemetry metadata map into `attributes`. Sole call site for
  `ReqLLM.OpenTelemetry.Attributes.start/1` + `.terminal/1` so adapters
  never inline a `gen_ai.*` string literal directly.
  """
  @spec merge_req_llm_attributes(map(), map()) :: map()
  def merge_req_llm_attributes(attributes, metadata) do
    attributes
    |> Map.merge(ReqLLM.OpenTelemetry.Attributes.start(metadata))
    |> Map.merge(ReqLLM.OpenTelemetry.Attributes.terminal(metadata))
  end

  @retrieval_config_keys [
    embedding_model: "scoria.retrieval.embedding_model",
    index_version: "scoria.retrieval.index_version",
    reranker: "scoria.retrieval.reranker"
  ]

  @doc """
  Returns the canonical keyword list mapping the three retrieval-config
  dimensions to their dotted `scoria.retrieval.*` attribute-key strings.
  The single origin the RETR-02 span<->table guard reads on both sinks.
  """
  @spec retrieval_config_keys() :: keyword(String.t())
  def retrieval_config_keys, do: @retrieval_config_keys

  @doc """
  Projects a canonical `%{embedding_model:, index_version:, reranker:}` map
  onto the dotted `retrieval_config_keys/0` string keys. Every value is
  normalized to the literal sentinel `"none"` when absent or `nil` — never
  `nil`, never omitted — so the produced map always has exactly three
  string-keyed entries (D-RETR02-4).
  """
  @spec retrieval_config_attributes(map()) :: map()
  def retrieval_config_attributes(config) do
    Map.new(@retrieval_config_keys, fn {field, key} ->
      {key, Map.get(config, field) || "none"}
    end)
  end

  @host_declared_keys ~w(feature route archetype intent)a

  @doc """
  Returns the canonical atom list of the four reserved host-declared
  dimensions, in order. The single origin the RETRIEVER, prompt, and
  adapter spans all reduce over (D-ATTR01-1).
  """
  @spec host_declared_keys() :: [atom()]
  def host_declared_keys, do: @host_declared_keys

  @doc """
  Merges the host-declared dimensions present in an atom-keyed `metadata`
  map into `attributes`. For each of `host_declared_keys/0`, a `nil` or
  absent value is skipped entirely (never defaulted, never put) — empty
  metadata yields no reserved keys. A present value passes through
  byte-for-byte under its bare string key (D-ATTR01-2/6). This is the
  single seam reused by the RETRIEVER span, the prompt span, and both
  adapters.
  """
  @spec merge_host_declared(map(), map()) :: map()
  def merge_host_declared(attributes, metadata) do
    Enum.reduce(@host_declared_keys, attributes, fn key, acc ->
      case Map.get(metadata, key) do
        nil -> acc
        value -> Map.put(acc, Atom.to_string(key), value)
      end
    end)
  end

  @prompt_context_key "scoria.prompt.context"
  @prompt_context_item_cap 100

  @doc "Returns the canonical prompt-context attribute key."
  @spec prompt_context_key() :: String.t()
  def prompt_context_key, do: @prompt_context_key

  @doc """
  Builds the nested, never-text prompt-context value from a host-supplied
  map with `:chunks`, `:memories` (each a list of item maps carrying at
  least `:id` and `:tokens`) and `:token_budget` (a map with `:total`,
  `:chunks`, `:memories`, `:overhead`).

  Each chunk/memory item is projected to ONLY `%{"id" => id, "tokens" =>
  tokens}` — the host's raw item map is never passed through, so a
  `text`/`content`/`body` field on an over-sharing host item cannot reach
  the span (D-ATTR02-4, the structural never-text guarantee). Each of
  `chunks`/`memories` is capped at #{@prompt_context_item_cap} items; when
  a list is truncated, `"truncated" => true` is added at the top level
  (D-ATTR02-6).

  This function only builds the value — it does NOT decide whether to
  attach it to a span. Callers (the emitter) own the omit-when-empty
  decision: when there is no context pack (or both lists are empty), the
  emitter must omit the `prompt_context_key/0` attribute entirely rather
  than attach an empty-but-present value (D-ATTR02-7).
  """
  @spec prompt_context(map()) :: map()
  def prompt_context(%{chunks: chunks, memories: memories, token_budget: token_budget}) do
    {chunks_out, chunks_truncated?} = project_items(chunks)
    {memories_out, memories_truncated?} = project_items(memories)

    value = %{
      "chunks" => chunks_out,
      "memories" => memories_out,
      "token_budget" => %{
        "total" => Map.get(token_budget, :total),
        "chunks" => Map.get(token_budget, :chunks),
        "memories" => Map.get(token_budget, :memories),
        "overhead" => Map.get(token_budget, :overhead)
      }
    }

    if chunks_truncated? or memories_truncated? do
      Map.put(value, "truncated", true)
    else
      value
    end
  end

  defp project_items(items) do
    truncated? = length(items) > @prompt_context_item_cap

    projected =
      items
      |> Enum.take(@prompt_context_item_cap)
      |> Enum.map(fn item ->
        %{"id" => Map.get(item, :id), "tokens" => Map.get(item, :tokens)}
      end)

    {projected, truncated?}
  end

  @doc """
  Merges the req_llm-owned `gen_ai.usage.input_tokens` key into `attributes`
  when `input_tokens` is present (non-`nil`). A `nil` `input_tokens` is a
  no-op — the caller tolerates absence rather than asserting unconditional
  presence (D-ATTR02-5; usage is `nil` on embedding-only or failed calls).

  Sourced via `ReqLLM.OpenTelemetry.Attributes.terminal/1` with a minimal
  `%{usage: %{input_tokens: input_tokens}}` metadata shape — every other
  `terminal/1` field (`finish_reasons`, `response`, `embeddings`, etc.) is
  absent from that shape and is stripped by `terminal/1`'s own `compact/1`,
  so the result is exactly one key: the req_llm-owned usage input-tokens
  attribute, mapped to `input_tokens`. This module never hand-writes a
  gen_ai-namespaced string literal (FOUND-03) — both the key name and
  value come from delegating to req_llm's own builder, not from a literal
  declared here.
  """
  @spec merge_usage_input_tokens(map(), integer() | nil) :: map()
  def merge_usage_input_tokens(attributes, nil), do: attributes

  def merge_usage_input_tokens(attributes, input_tokens) do
    Map.merge(
      attributes,
      ReqLLM.OpenTelemetry.Attributes.terminal(%{usage: %{input_tokens: input_tokens}})
    )
  end

  # -- SEC-01: the closed key registry ---------------------------------

  @attribute_classes ~w(id count enum flag timestamp structured)a

  @doc """
  Returns the closed, six-value attribute-class vocabulary
  (`attribute_registry/0`'s value type). This list is deliberately closed
  at six values and has no member meaning "arbitrary prose" — that
  absence, not a filter, is the SEC-01 guarantee (INV-SEC01). Any future
  key whose value would be a model-generated sentence has no class it can
  legally take.
  """
  @spec attribute_classes() :: [atom()]
  def attribute_classes, do: @attribute_classes

  @guardrail_keys [
    name: "scoria.guardrail.name",
    decision: "scoria.guardrail.decision",
    reason_code: "scoria.guardrail.reason_code",
    subject_ref: "scoria.guardrail.subject_ref",
    policy_key: "scoria.guardrail.policy_key"
  ]

  @doc """
  Returns the canonical keyword list mapping the five guardrail dimensions
  to their dotted `scoria.guardrail.*` attribute-key strings. Sole origin
  for `guardrail_attributes/1`'s fixed-key projection.
  """
  @spec guardrail_keys() :: keyword(String.t())
  def guardrail_keys, do: @guardrail_keys

  @guardrail_names ~w(release_gate approval_gate budget_gate breaker_gate)

  @doc "Returns the canonical 4-value closed guardrail-name enum."
  @spec guardrail_names() :: [String.t()]
  def guardrail_names, do: @guardrail_names

  @guardrail_decisions ~w(allow block escalate)

  @doc """
  Returns the canonical guardrail-decision enum: `allow`, `block`,
  `escalate`. `"modify"` is deliberately RESERVED (D-05h) as a future
  XACML *obligation* the caller MUST discharge or deny (fail-closed) — it
  is not in this active list. The decision axis (allow/block/escalate)
  must never be collapsed into the remediation axis a future `modify`
  would carry.
  """
  @spec guardrail_decisions() :: [String.t()]
  def guardrail_decisions, do: @guardrail_decisions

  @guardrail_reason_codes ~w(
    unapproved_draft
    eval_not_passing
    eval_required
    approval_required
    budget_rejected
    breaker_open
  )

  @doc """
  Returns the canonical 6-value closed guardrail reason_code enum. These
  are not invented — `ReleaseGate.check/1` already returns the first three
  atoms and `BreakerRegistry` already carries `"breaker_open"`. This
  function does not define the enum; it refuses to widen it.
  """
  @spec guardrail_reason_codes() :: [String.t()]
  def guardrail_reason_codes, do: @guardrail_reason_codes

  @attribute_registry Map.merge(
                        %{
                          @openinference_span_kind_key => :enum,
                          @prompt_context_key => :structured,
                          "tenant_id" => :id,
                          "workflow_run_id" => :id,
                          "session_id" => :id,
                          "duration_ms" => :count,
                          "tool_ref" => :enum,
                          "tool_name" => :enum,
                          "status" => :enum,
                          "args_fingerprint" => :id,
                          "exception.type" => :enum,
                          "error.type" => :enum,
                          "scoria.attributes.dropped" => :count,
                          "scoria.attributes.dropped_keys" => :structured,
                          "scoria.attributes.truncated_keys" => :structured,
                          Keyword.fetch!(@guardrail_keys, :name) => :enum,
                          Keyword.fetch!(@guardrail_keys, :decision) => :enum,
                          Keyword.fetch!(@guardrail_keys, :reason_code) => :enum,
                          Keyword.fetch!(@guardrail_keys, :subject_ref) => :id,
                          Keyword.fetch!(@guardrail_keys, :policy_key) => :id
                        },
                        Map.new(@host_declared_keys, &{Atom.to_string(&1), :enum})
                      )
                      |> Map.merge(
                        Map.new(@retrieval_config_keys, fn {_field, key} -> {key, :enum} end)
                      )

  @doc """
  Returns the closed `%{key_string => class_atom}` registry — the single
  origin of every attribute key Scoria itself may persist (SEC-01,
  D-06b). Every value is a member of `attribute_classes/0`.

  Pre-seeded with the bare keys the operator dashboard already reads
  (`tenant_id`, `workflow_run_id`, `session_id`, `duration_ms`, the four
  ATTR-01 host-declared keys), every Semconv-owned dotted key
  (`openinference.span.kind`, the three `scoria.retrieval.*` keys,
  `scoria.prompt.context`), the MCP tool-span projection
  (`tool_ref`/`tool_name`/`status`/`args_fingerprint`, D-04b), the five
  `scoria.guardrail.*` keys, the type-only error keys (`exception.type`/
  `error.type`), and the three `bounds_marker_keys/0` values. Consumed by
  `Scoria.Observe.Bounds` (plan 53-04) as the tollbooth every attribute key
  must pass through — a Scoria developer cannot persist a new key without
  editing this registry, and that edit trips the registry canary test.
  """
  @spec attribute_registry() :: %{String.t() => atom()}
  def attribute_registry, do: @attribute_registry

  @vendor_key_prefixes ~w(gen_ai. server. openai. req_llm. error.)

  @doc """
  Returns the vendor attribute-key prefixes admitted as bounded scalars by
  `Scoria.Observe.Bounds` (plan 53-04) unless a dot-segment hits
  `denied_key_segments/0`. `scoria.`, `openinference.`, `jido.`, and all
  bare keys are REGISTRY-ONLY — there is no prefix escape into Scoria's
  own namespaces.
  """
  @spec vendor_key_prefixes() :: [String.t()]
  def vendor_key_prefixes, do: @vendor_key_prefixes

  @denied_exact_keys ~w(
    gen_ai.input.messages
    gen_ai.output.messages
    gen_ai.system_instructions
    gen_ai.tool.definitions
  )

  @doc """
  Returns the exact-key denylist for the four req_llm `content: :attributes`-
  promoted keys (D-06c-3). Exact-segment denial alone does NOT catch
  `gen_ai.system_instructions` / `gen_ai.tool.definitions` — their final
  dot-segments are `system_instructions` / `definitions`, not
  `messages`/`instructions` — hence an exact-KEY denylist in addition to
  `denied_key_segments/0`.
  """
  @spec denied_exact_keys() :: [String.t()]
  def denied_exact_keys, do: @denied_exact_keys

  @denied_key_segments ~w(messages content completion prompt text body)

  @doc """
  Returns the dot-segment denylist. Consumers MUST split a candidate key
  on `"."` and compare segments for EXACT equality — substring matching
  would drop `args_fingerprint` (it contains `args`) and kill the very
  field D-04b relies on (D-06c-2).
  """
  @spec denied_key_segments() :: [String.t()]
  def denied_key_segments, do: @denied_key_segments

  @bounds_marker_keys %{
    dropped: "scoria.attributes.dropped",
    dropped_keys: "scoria.attributes.dropped_keys",
    truncated_keys: "scoria.attributes.truncated_keys"
  }

  @doc """
  Returns the canonical map of `Scoria.Observe.Bounds` marker attribute
  keys (plan 53-04). All three values are themselves `attribute_registry/0`
  keys.
  """
  @spec bounds_marker_keys() :: %{atom() => String.t()}
  def bounds_marker_keys, do: @bounds_marker_keys

  @doc """
  Normalizes any host/adapter-supplied guardrail reason_code to a
  canonical value. Falls back to `"unknown"` on an unrecognized value —
  and mirrors `Scoria.Observe.SpanKind.normalize/2`'s fallback discipline:
  LOGS + EMITS TELEMETRY on fallback rather than silently defaulting.
  `"unknown"` is itself a legal value of the `scoria.guardrail.reason_code`
  registry entry.

  The fallback telemetry emit is wrapped defensively: a raising
  host-attached handler on `[:scoria, :observe, :guardrail, :fallback]`
  cannot crash the caller.
  """
  @spec normalize_reason_code(term()) :: String.t()
  def normalize_reason_code(value) do
    normalized = to_string(value)

    if normalized in @guardrail_reason_codes do
      normalized
    else
      Logger.warning(
        "Unrecognized guardrail reason_code #{inspect(value)}, defaulting to \"unknown\""
      )

      try do
        :telemetry.execute([:scoria, :observe, :guardrail, :fallback], %{}, %{value: value})
      rescue
        _ -> :ok
      end

      "unknown"
    end
  end

  @doc """
  Projects a host/caller map onto EXACTLY the five `guardrail_keys/0`
  strings and nothing else. Never spreads the input map — a `nil` value
  is omitted, never defaulted, never put (mirrors `merge_host_declared/2`'s
  and `prompt_context/1`'s no-passthrough discipline). This fixed-key
  projection is what makes the never-prose guardrail guarantee structural
  rather than a review convention (D-05g): a caller cannot smuggle an
  extra key through it, because it does not read extra keys.
  """
  @spec guardrail_attributes(map()) :: map()
  def guardrail_attributes(input) when is_map(input) do
    Enum.reduce(@guardrail_keys, %{}, fn {field, key}, acc ->
      case Map.get(input, field) do
        nil -> acc
        value -> Map.put(acc, key, value)
      end
    end)
  end

  @doc """
  Builds a type-only error attribute projection from an exception struct
  or a `{kind, reason}` catch tuple. Returns exactly `"exception.type"`
  and `"error.type"`, both set to the module name (or the kind, for a
  throw/exit) — NEVER `Exception.message/1`, NEVER `__STACKTRACE__`
  (D-06g). An exception message is arbitrary-length, attacker- and
  prompt-influenced text; a module/kind name is low-cardinality and
  enum-like. `capture_error_messages` may exist as a documented future
  opt-in but is NOT implemented here.
  """
  @spec error_attributes(Exception.t() | {atom(), term()}) :: map()
  def error_attributes(%{__exception__: true} = exception) do
    type = inspect(exception.__struct__)
    %{"exception.type" => type, "error.type" => type}
  end

  def error_attributes({kind, _reason}) when kind in [:throw, :exit, :error] do
    type = Atom.to_string(kind)
    %{"exception.type" => type, "error.type" => type}
  end
end
