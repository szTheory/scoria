defmodule Scoria.Observe.SpanKind do
  @moduledoc """
  Canonical span_kind taxonomy — single source of truth for both write sites
  (adapters) and read sites (UI components). Native casing is lowercase;
  `to_openinference/1` derives the UPPERCASE OpenInference portability value.

  Deliberately a plain module with compile-time constant lists — NOT
  `Ecto.Enum` (D-14 rejects it: Ecto.Enum would reject drifted/legacy rows
  on load and bind casing directly into the schema).

  Pinned against the OpenInference span-kind enum as documented at
  github.com/Arize-ai/openinference/blob/main/spec/semantic_conventions.md
  (no formal version scheme upstream; pinned by fetch date 2026-07-11 per
  milestone research — re-verify if OpenInference publishes a versioned spec).

  The fallback-observability event this module emits on an unrecognized
  value is `[:scoria, :observe, :span_kind, :fallback]` (measurements `%{}`,
  metadata `%{value: value, default: default}`) — named here (Phase 51
  Plan 01) per RESEARCH.md Open Question 3.
  """

  require Logger

  @kinds ~w(agent llm prompt tool mcp retriever guardrail eval)

  @openinference_map %{
    "agent" => "AGENT",
    "llm" => "LLM",
    "prompt" => "PROMPT",
    "tool" => "TOOL",
    "mcp" => "TOOL",
    "retriever" => "RETRIEVER",
    "guardrail" => "GUARDRAIL",
    "eval" => "EVALUATOR"
  }

  @doc "Returns the canonical 8-value span_kind list, in UI-rail order."
  @spec kinds() :: [String.t()]
  def kinds, do: @kinds

  @doc "True if `value` (any casing, any term) is a canonical span_kind."
  @spec kind?(term()) :: boolean()
  def kind?(value), do: (to_string(value) |> String.downcase()) in @kinds

  @doc """
  Normalizes any host/adapter-supplied value to a canonical kind. Falls back
  to `default` (default: "agent") on an unrecognized value — and unlike a
  silent `_ -> "agent"` fallback, LOGS + EMITS TELEMETRY on fallback
  (coheres with FOUND-01's "observable, not silent" principle).

  The fallback telemetry emit is wrapped defensively (T-51-01): a raising
  host-attached handler on `[:scoria, :observe, :span_kind, :fallback]`
  cannot crash the caller or interrupt the normalize return path.
  """
  @spec normalize(term(), String.t()) :: String.t()
  def normalize(value, default \\ "agent") do
    normalized = value |> to_string() |> String.downcase()

    if normalized in @kinds do
      normalized
    else
      Logger.warning("Unrecognized span_kind #{inspect(value)}, defaulting to #{default}")

      try do
        :telemetry.execute([:scoria, :observe, :span_kind, :fallback], %{}, %{
          value: value,
          default: default
        })
      rescue
        _ -> :ok
      end

      default
    end
  end

  @doc """
  Derives the UPPERCASE OpenInference portability value for a canonical
  native kind (`mcp` collapses to `TOOL`, `eval` renames to `EVALUATOR`).
  Never raises for any kind in `kinds/0`.
  """
  @spec to_openinference(String.t()) :: String.t()
  def to_openinference(kind) when kind in @kinds, do: Map.fetch!(@openinference_map, kind)
end
