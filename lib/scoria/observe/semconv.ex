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
  """

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
      |> Enum.map(fn item -> %{"id" => Map.get(item, :id), "tokens" => Map.get(item, :tokens)} end)

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
end
