defmodule Scoria.Repo.Trace do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_traces" do
    field(:session_id, :string)
    field(:attributes, :map, default: %{})

    has_many(:spans, Scoria.Repo.Span)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(trace, attrs) do
    trace
    |> cast(attrs, [:session_id, :attributes])
  end
end
