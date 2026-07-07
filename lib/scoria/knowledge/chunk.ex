defmodule Scoria.Knowledge.Chunk do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @scope_fields [:tenant_id, :actor_id, :scope_kind]
  @scope_kinds ~w(tenant_shared actor_scoped)

  schema "ai_knowledge_chunks" do
    field(:tenant_id, :string)
    field(:actor_id, :string)
    field(:scope_kind, :string)
    field(:chunk_digest, :string)
    field(:body, :string)
    field(:heading_path, {:array, :string}, default: [])
    field(:start_offset, :integer)
    field(:end_offset, :integer)
    field(:token_count, :integer)
    field(:embedding, Pgvector.Ecto.Vector)
    field(:metadata, :map, default: %{})

    belongs_to(:source, Scoria.Knowledge.Source)
    has_many(:citations, Scoria.Knowledge.Citation)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(chunk, attrs) do
    chunk
    |> cast(
      attrs,
      @scope_fields ++
        [
          :source_id,
          :chunk_digest,
          :body,
          :heading_path,
          :start_offset,
          :end_offset,
          :token_count,
          :embedding,
          :metadata
        ]
    )
    |> validate_required([
      :tenant_id,
      :scope_kind,
      :source_id,
      :chunk_digest,
      :body,
      :start_offset,
      :end_offset,
      :token_count
    ])
    |> validate_inclusion(:scope_kind, @scope_kinds)
    |> foreign_key_constraint(:source_id)
    |> unique_constraint([:source_id, :chunk_digest])
  end
end
