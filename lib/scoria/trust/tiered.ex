defprotocol Scoria.Trust.Tiered do
  @moduledoc """
  Foreign-struct polymorphism seam for reading a trust tier off a
  Scoria-owned struct (D-23).

  `Scoria.Trust` stays a dependency-free leaf by never matching on
  `%Scoria.Knowledge.Chunk{}` / `%Scoria.MCP.Envelope{}` directly — instead
  each OWNING module (`Scoria.Knowledge.Chunk`, later `Scoria.MCP.Envelope`)
  implements this protocol, delegating back to `Scoria.Trust.tier/1` (or an
  equivalent fail-closed reader). This is what avoids a `Knowledge <-> Trust`
  / `MCP <-> Trust` compile cycle: the impl lives with the struct, not with
  the vocabulary.
  """

  @doc """
  Returns the resolved trust tier (a member of `Scoria.Trust.tiers/0`) for
  `item`. Implementations MUST fail closed — never raise, never return a
  value outside the closed tier enum.
  """
  @spec tier(t) :: Scoria.Trust.tier()
  def tier(item)
end
