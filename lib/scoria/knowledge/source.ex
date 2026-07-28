defmodule Scoria.Knowledge.Source do
  @moduledoc """
  A knowledge source and its provenance.

  Trust is a property of the `Source` (D-04): the canonical tier lives at
  `metadata["scoria.trust.tier"]` (see `Scoria.Trust.tier_key/0`) — no new
  Ecto column, convention over the existing jsonb `metadata` field. This is
  the value `Scoria.Knowledge.ingest_source/2` denormalizes onto every
  chunk's own `metadata` at ingest time (via `Scoria.Trust.tier/1` +
  `Scoria.Trust.put_tier/2`), so retrieval reads a chunk's trust with no
  `Source` join on the hot path. Absent/junk values fail closed to
  `Scoria.Trust.default_tier/0` (`"untrusted"`).
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @scope_fields [:tenant_id, :actor_id, :scope_kind]
  @scope_kinds ~w(tenant_shared actor_scoped)

  schema "ai_knowledge_sources" do
    field(:tenant_id, :string)
    field(:actor_id, :string)
    field(:scope_kind, :string)
    field(:entity_id, :binary_id)
    field(:version, :integer, default: 1)
    field(:is_current, :boolean, default: true)
    field(:kind, :string)
    field(:uri, :string)
    field(:title, :string)
    field(:digest, :string)
    field(:metadata, :map, default: %{})

    has_many(:chunks, Scoria.Knowledge.Chunk)
    has_many(:citations, Scoria.Knowledge.Citation)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(source, attrs) do
    source
    |> cast(
      attrs,
      @scope_fields ++
        [:entity_id, :version, :is_current, :kind, :uri, :title, :digest, :metadata]
    )
    |> validate_required([
      :tenant_id,
      :scope_kind,
      :entity_id,
      :version,
      :is_current,
      :kind,
      :digest
    ])
    |> validate_inclusion(:scope_kind, @scope_kinds)
    |> unique_constraint([:entity_id, :version])
    |> unique_constraint([:tenant_id, :entity_id, :version],
      name: :ai_knowledge_sources_tenant_entity_version_index
    )
  end
end
