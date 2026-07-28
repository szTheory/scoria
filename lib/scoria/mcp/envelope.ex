defmodule Scoria.MCP.Envelope do
  @moduledoc """
  The tool-output leg of the content taint substrate (TAINT-02, D-06).

  `Scoria.MCP.Envelope` wraps a tool's successful return value with a trust
  tier so downstream code treats it as potentially-untrusted content rather
  than implicitly-trusted context. It is a struct (not a plain map, not a
  tagged tuple) so the `__struct__` stamp is pattern-matchable and cannot
  collide with `Scoria.MCP.Executor`'s `is_map(result)` introspection of
  `actual_units`/`actual_cost_usd`. `@enforce_keys [:value, :tier]` makes a
  tier-less envelope unconstructable.

  ## Fields

    - `value` — the tool's raw return value. This is the ONLY place the
      value lives (never duplicated into a second drift-prone field).
    - `tier` — a member of `Scoria.Trust.tiers/0`.
    - `provenance` — a map carrying ONLY low-cardinality ids/enums
      (`tool_ref`, `tool_name`, `trace_id`, `workflow_run_id`, `step_id`,
      `args_fingerprint`) — never free text (D-06, D-09 information
      disclosure mitigation).
    - `scan` — a `nil` slot in this phase, populated by a future Area D
      scan-engine verdict (Plan 05).
    - `enveloped_at` — the `DateTime.t()` the envelope was minted.

  ## Total accessors (D-09)

  `envelope?/1`, `tier/1`, `value/1`, `scan/1`, and `unwrap/1` are TOTAL
  over `t() | term()`: any un-enveloped/unknown value reads
  `tier ⇒ Scoria.Trust.default_tier()`, `value ⇒ itself`. This is the
  forward-compatible read path — callers (Area C, Phase 56/57) read via
  these accessors and never pattern-match the raw `%Envelope{}` shape, so
  they stay flag-agnostic to `Scoria.MCP.Executor`'s soft-launch
  `wrap_tool_output` config (D-08).

  `wrap/2` is idempotent: wrapping an already-enveloped value returns it
  unchanged (guarded by `envelope?/1`), so callers can wrap defensively
  without ever double-nesting a `%Envelope{value: %Envelope{}}`.
  """

  alias Scoria.Trust

  @enforce_keys [:value, :tier]
  defstruct [:value, :tier, :provenance, :scan, :enveloped_at]

  @typedoc """
  Low-cardinality ids/enums only — no free text (D-06, D-09).
  """
  @type provenance :: %{optional(atom()) => term()}

  @type t :: %__MODULE__{
          value: term(),
          tier: Trust.tier(),
          provenance: provenance() | nil,
          scan: term() | nil,
          enveloped_at: DateTime.t() | nil
        }

  @doc """
  Wraps `value` in a `t:t/0` carrying a trust tier and provenance.

  Idempotent (D-09): if `value` is already a `t:t/0` (per `envelope?/1`),
  it is returned unchanged — this guards every call site against
  double-nesting even if wrapping is applied more than once.

  ## Options

    - `:tier` — normalized via `Scoria.Trust.normalize_tier/1`; defaults to
      `Scoria.Trust.default_tier/0` (fail-closed) when omitted.
    - `:provenance` — a `t:provenance/0` map; defaults to `nil`.
    - `:scan` — a scan verdict slot; defaults to `nil`.
  """
  @spec wrap(t() | term(), keyword()) :: t()
  def wrap(value, opts \\ [])

  def wrap(%__MODULE__{} = envelope, _opts), do: envelope

  def wrap(value, opts) do
    %__MODULE__{
      value: value,
      tier: Trust.normalize_tier(Keyword.get(opts, :tier, Trust.default_tier())),
      provenance: Keyword.get(opts, :provenance),
      scan: Keyword.get(opts, :scan),
      enveloped_at: DateTime.utc_now()
    }
  end

  @doc "Returns `true` only when `item` is a `t:t/0`."
  @spec envelope?(term()) :: boolean()
  def envelope?(%__MODULE__{}), do: true
  def envelope?(_other), do: false

  @doc """
  Total over `t() | term()` (D-09): an envelope's normalized tier, or
  `Scoria.Trust.default_tier/0` for any un-enveloped value.
  """
  @spec tier(t() | term()) :: Trust.tier()
  def tier(%__MODULE__{tier: tier}), do: Trust.normalize_tier(tier)
  def tier(_other), do: Trust.default_tier()

  @doc """
  Total over `t() | term()` (D-09): an envelope's inner value, or the term
  itself for any un-enveloped value.
  """
  @spec value(t() | term()) :: term()
  def value(%__MODULE__{value: value}), do: value
  def value(other), do: other

  @doc """
  Total over `t() | term()`: an envelope's scan verdict slot, or `nil` for
  any un-enveloped value.
  """
  @spec scan(t() | term()) :: term() | nil
  def scan(%__MODULE__{scan: scan}), do: scan
  def scan(_other), do: nil

  @doc """
  Returns `{tier, value}`, total over `t() | term()` (D-09).
  """
  @spec unwrap(t() | term()) :: {Trust.tier(), term()}
  def unwrap(item), do: {tier(item), value(item)}
end

defimpl Scoria.Trust.Tiered, for: Scoria.MCP.Envelope do
  def tier(%Scoria.MCP.Envelope{tier: tier}), do: Scoria.Trust.normalize_tier(tier)
end
