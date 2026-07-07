defmodule Scoria.Knowledge.RetrievalResult do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ai_retrieval_results" do
    field(:tenant_id, :string)
    field(:actor_id, :string)
    field(:rank, :integer)
    field(:score, :float)
    field(:metadata, :map, default: %{})
    field(:backend_payload, :map, default: %{})

    belongs_to(:retrieval_run, Scoria.Knowledge.RetrievalRun)
    belongs_to(:chunk, Scoria.Knowledge.Chunk)
    belongs_to(:source, Scoria.Knowledge.Source)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(result, attrs) do
    result
    |> cast(attrs, [
      :tenant_id,
      :actor_id,
      :retrieval_run_id,
      :chunk_id,
      :source_id,
      :rank,
      :score,
      :metadata,
      :backend_payload
    ])
    |> validate_required([:tenant_id, :retrieval_run_id, :chunk_id, :source_id, :rank, :score])
    |> foreign_key_constraint(:retrieval_run_id)
    |> foreign_key_constraint(:chunk_id)
    |> foreign_key_constraint(:source_id)
  end
end
