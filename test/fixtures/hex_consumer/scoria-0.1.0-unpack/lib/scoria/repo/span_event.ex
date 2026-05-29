defmodule Scoria.Repo.SpanEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_span_events" do
    field(:name, :string)
    field(:time, :utc_datetime_usec)
    field(:attributes, :map, default: %{})

    belongs_to(:span, Scoria.Repo.Span)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(span_event, attrs) do
    span_event
    |> cast(attrs, [:span_id, :name, :time, :attributes])
    |> validate_required([:span_id, :name, :time])
  end
end
