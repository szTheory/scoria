defmodule Scoria.Trust do
  @moduledoc """
  The shared trust vocabulary for content flowing through Scoria — a closed
  binary tier (`~w(trusted untrusted)`), fail-closed by default.

  `Scoria.Trust` is a dependency-free leaf module (D-02, D-23): it does not
  alias `Scoria.Knowledge`, `Scoria.MCP`, or `Scoria.Observe`. Foreign-struct
  polymorphism is achieved through `Scoria.Trust.Tiered`, a protocol whose
  `defimpl` blocks live in the OWNING modules (e.g. `Scoria.Knowledge.Chunk`)
  and delegate back to `tier/1` — this keeps `Trust` a leaf and avoids a
  compile cycle.

  A third/graded trust tier is deliberately rejected (D-01): scanner
  severity is expressed via `reason_code`/`score` elsewhere, never a tier.
  Downstream readers (the Phase 57 confluence gate, envelopes, scan
  verdicts) treat "any `untrusted` on the path" with zero collapse logic.

  ## Fail-closed reader semantics (D-03)

  `tier/1` mirrors `Scoria.Observe.Semconv.normalize_reason_code/1`'s
  fail-closed idiom, but with TWO branches instead of one:

    - an ABSENT `"scoria.trust.tier"` key resolves to `default_tier/0`
      **silently** — old rows are legitimately missing the key, and a
      forgetful/legacy reader must still fail closed without being spammed.
    - a PRESENT but unrecognized value resolves to `default_tier/0` too, but
      LOGS a warning and emits `[:scoria, :trust, :fallback]` telemetry —
      this is a signal that something minted a bogus tier value.

  Only the exact strings `"trusted"`/`"untrusted"` ever pass through.
  """

  require Logger

  @tiers ~w(trusted untrusted)
  @default_tier "untrusted"
  @tier_key "scoria.trust.tier"

  @typedoc "One of the closed binary trust tier values."
  @type tier :: String.t()

  @doc """
  Returns the closed binary tier enum. This is a Hex-published contract —
  widening it to a third tier is a breaking change for every reader.
  """
  @spec tiers() :: [tier()]
  def tiers, do: @tiers

  @doc """
  Returns the fail-closed default tier, `"untrusted"`.
  """
  @spec default_tier() :: tier()
  def default_tier, do: @default_tier

  @doc """
  Returns the canonical jsonb metadata key trust is stored under,
  `"scoria.trust.tier"`.
  """
  @spec tier_key() :: String.t()
  def tier_key, do: @tier_key

  @doc """
  Reads the trust tier off a `metadata` map (e.g. `Chunk.metadata`,
  `Source.metadata`) with fail-closed semantics (D-03):

    - absent key ⇒ `default_tier/0`, silently.
    - `"trusted"` / `"untrusted"` ⇒ passed through exactly.
    - any other present value ⇒ `default_tier/0`, logged + telemetried via
      the shared `fallback/1` path.
  """
  @spec tier(map()) :: tier()
  def tier(metadata) when is_map(metadata) do
    case Map.get(metadata, @tier_key) do
      nil -> @default_tier
      "trusted" -> "trusted"
      "untrusted" -> "untrusted"
      junk -> fallback(junk)
    end
  end

  @doc """
  Returns `true` only when `tier/1` resolves the given metadata map to
  `"trusted"`.
  """
  @spec trusted?(map()) :: boolean()
  def trusted?(metadata) when is_map(metadata), do: tier(metadata) == "trusted"

  @doc """
  Normalizes an arbitrary term (typically a host-supplied `trust:` override
  value) to a member of `tiers/0`. Unlike `tier/1`'s silent-absent branch,
  EVERY non-member value here (including `nil`) routes through the logged +
  telemetried `fallback/1` — there is no legitimate "absent override" case
  at this call site, only a caller-supplied value that either is or isn't a
  real tier.
  """
  @spec normalize_tier(term()) :: tier()
  def normalize_tier(value) when value in @tiers, do: value
  def normalize_tier(value), do: fallback(value)

  @doc """
  Writes `normalize_tier(value)` onto `metadata` under `tier_key/0`. A junk
  `value` still stores `default_tier/0` (fails closed) rather than the junk
  value or raising.
  """
  @spec put_tier(map(), term()) :: map()
  def put_tier(metadata, value) when is_map(metadata) do
    Map.put(metadata, @tier_key, normalize_tier(value))
  end

  # Shared fail-closed fallback path (D-03): logs a warning, emits
  # `[:scoria, :trust, :fallback]` telemetry wrapped in try/rescue so a
  # raising host-attached handler can never break the caller, and returns
  # the fail-closed default tier.
  defp fallback(value) do
    Logger.warning(
      "Unrecognized trust tier #{inspect(value)}, defaulting to \"#{@default_tier}\""
    )

    try do
      :telemetry.execute([:scoria, :trust, :fallback], %{}, %{value: value})
    rescue
      _ -> :ok
    end

    @default_tier
  end
end
