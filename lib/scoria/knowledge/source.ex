defmodule Scoria.Knowledge.Source do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ai_knowledge_sources" do
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
    |> cast(attrs, [:entity_id, :version, :is_current, :kind, :uri, :title, :digest, :metadata])
    |> validate_required([:entity_id, :version, :is_current, :kind, :digest])
    |> unique_constraint([:entity_id, :version])
  end
end
