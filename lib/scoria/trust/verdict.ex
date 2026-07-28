defmodule Scoria.Trust.Verdict do
  @moduledoc """
  The result of a `Scoria.Trust.Scanner` classification (D-16).

  `%Verdict{}` is a published contract a host's `Scoria.Trust.Scanner`
  implementation constructs, and `Scoria.Trust.Scan` consumes to resolve
  the monotonic taint law (D-19). `tier` is required — a verdict without a
  tier is not constructable (`@enforce_keys`).

  ## Fields

    - `tier` — one of `Scoria.Trust.tiers/0` (D-01's closed binary enum).
      This is the ONLY field `Scoria.Trust.Scan` folds into the resolved
      taint outcome.
    - `score` — an optional host-only numeric confidence score. **Never**
      persisted to a trace, span attribute, or `step.result_envelope` — it
      never leaves the host boundary (D-16, D-21, T-55-18).
    - `reason_code` — an optional atom, normalized against the closed
      `~w(prompt_injection moderation_flag untrusted_source scanner_error
      scanner_timeout unknown)` enum before use (D-21). See
      `normalize_reason_code/1`.
    - `scanner` — the scanner module that produced this verdict.
  """

  @enforce_keys [:tier]
  defstruct [:tier, :score, :reason_code, :scanner]

  @type t :: %__MODULE__{
          tier: String.t(),
          score: float() | nil,
          reason_code: atom() | nil,
          scanner: module() | nil
        }

  @reason_codes ~w(
    prompt_injection
    moderation_flag
    untrusted_source
    scanner_error
    scanner_timeout
    unknown
  )a

  @doc """
  Returns the closed `reason_code` enum (D-21).
  """
  @spec reason_codes() :: [atom()]
  def reason_codes, do: @reason_codes

  @doc """
  Normalizes an arbitrary term to a member of `reason_codes/0`, falling
  back to `:unknown` for anything unrecognized (D-21) — mirrors
  `Scoria.Observe.Semconv.normalize_reason_code/1`'s fail-closed idiom, but
  operates on atoms (this value never reaches a trace as free text; it is
  itself the closed-enum value).
  """
  @spec normalize_reason_code(term()) :: atom()
  def normalize_reason_code(value) when value in @reason_codes, do: value
  def normalize_reason_code(_value), do: :unknown
end
