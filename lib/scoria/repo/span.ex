defmodule Scoria.Repo.Span do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_spans" do
    field(:name, :string)
    field(:span_kind, :string)
    field(:status_code, :string)
    field(:start_time, :utc_datetime_usec)
    field(:end_time, :utc_datetime_usec)
    field(:attributes, :map, default: %{})
    field(:parent_id, :binary_id)

    belongs_to(:trace, Scoria.Repo.Trace)
    has_many(:events, Scoria.Repo.SpanEvent)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(span, attrs) do
    span
    |> cast(attrs, [
      :trace_id,
      :parent_id,
      :name,
      :span_kind,
      :status_code,
      :start_time,
      :end_time,
      :attributes
    ])
    |> validate_required([:trace_id, :name, :start_time])
  end
end
