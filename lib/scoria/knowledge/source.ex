defmodule Scoria.Knowledge.Source do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
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
    |> cast(attrs, [
      :tenant_id,
      :actor_id,
      :scope_kind,
      :entity_id,
      :version,
      :is_current,
      :kind,
      :uri,
      :title,
      :digest,
      :metadata
    ])
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
