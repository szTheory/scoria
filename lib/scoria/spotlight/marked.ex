defmodule Scoria.Spotlight.Marked do
  @moduledoc """
  The result struct returned by `Scoria.Spotlight.render/2` (D-11).

  A plain struct (no Ecto), mirroring the field-list style of
  `Scoria.Knowledge.Chunk`, but with no persistence of its own — it is a
  transient, host-consumed return value.

  ## Fields

    - `marked` — the assembled marked text across every input item: trusted
      items pass through byte-identical, untrusted items are wrapped per
      the resolved `technique`; items are joined with a blank line between
      them.
    - `instruction` — the canonical (host-overridable) system-prompt
      instruction explaining the marking scheme to the model, returned as
      DATA (D-13). `Scoria.Spotlight` never injects this into a prompt —
      the host decides placement.
    - `technique` — the technique applied overall for this call: one of
      `:datamark`, `:delimit`, `:encode`, or `:none` (every item resolved
      trusted, so nothing was marked). See `spans` for the per-item detail
      when a batch mixes trust tiers or content shapes.
    - `tier` — the aggregate resolved tier for the call: `"untrusted"` if
      ANY input item resolved untrusted (fail-closed, mirrors
      `Scoria.Trust`'s vocabulary), else `"trusted"`.
    - `marked?` — `true` when at least one item was actually marked.
    - `spans` — the per-item detail list, in input order, each entry
      `%{tier:, technique:, marked:, marked?:}`.
  """

  @enforce_keys [:marked, :instruction, :technique, :tier, :marked?, :spans]
  defstruct [:marked, :instruction, :technique, :tier, :marked?, :spans]

  @typedoc "Per-item marking detail, as returned in `t:t/0`'s `spans` field."
  @type span :: %{
          tier: Scoria.Trust.tier(),
          technique: atom(),
          marked: String.t(),
          marked?: boolean()
        }

  @type t :: %__MODULE__{
          marked: String.t(),
          instruction: String.t(),
          technique: atom(),
          tier: Scoria.Trust.tier(),
          marked?: boolean(),
          spans: [span()]
        }
end
