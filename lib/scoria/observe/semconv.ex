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
  - (Phase 52+) reserved host-declared keys: `feature`/`route`/`archetype`/`intent`
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
end
