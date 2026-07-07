defmodule Scoria.Knowledge.Citation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @scope_fields [:tenant_id, :actor_id, :scope_kind]
  @scope_kinds ~w(tenant_shared actor_scoped)

  schema "ai_knowledge_citations" do
    field(:tenant_id, :string)
    field(:actor_id, :string)
    field(:scope_kind, :string)
    field(:trace_id, :binary_id)
    field(:span_id, :binary_id)
    field(:label, :string)
    field(:chunk_digest, :string)
    field(:start_offset, :integer)
    field(:end_offset, :integer)
    field(:quote, :string)
    field(:locator, :map, default: %{})
    field(:metadata, :map, default: %{})

    belongs_to(:source, Scoria.Knowledge.Source)
    belongs_to(:chunk, Scoria.Knowledge.Chunk)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(citation, attrs) do
    citation
    |> cast(
      attrs,
      @scope_fields ++
        [
          :source_id,
          :chunk_id,
          :trace_id,
          :span_id,
          :label,
          :chunk_digest,
          :start_offset,
          :end_offset,
          :quote,
          :locator,
          :metadata
        ]
    )
    |> validate_required([
      :tenant_id,
      :scope_kind,
      :source_id,
      :chunk_id,
      :label,
      :chunk_digest,
      :start_offset,
      :end_offset,
      :locator
    ])
    |> validate_inclusion(:scope_kind, @scope_kinds)
    |> foreign_key_constraint(:source_id)
    |> foreign_key_constraint(:chunk_id)
  end
end
