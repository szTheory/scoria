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
end
