defmodule Scoria.SRE.BreakerTrip do
  use Ecto.Schema
  import Ecto.Changeset

  @states ~w(closed open half_open)
  @integration_kinds ~w(provider remote_mcp tool)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_breaker_trips" do
    field(:tenant_id, :string)
    field(:breaker_key, :string)
    field(:integration_kind, :string)
    field(:reason_code, :string)
    field(:transition, :string)
    field(:state, :string)
    field(:workflow_run_id, :binary_id)
    field(:trace_id, :string)
    field(:evidence_refs, :map, default: %{})
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(trip, attrs) do
    trip
    |> cast(attrs, [
      :tenant_id,
      :breaker_key,
      :integration_kind,
      :reason_code,
      :transition,
      :state,
      :workflow_run_id,
      :trace_id,
      :evidence_refs,
      :metadata
    ])
    |> validate_required([
      :tenant_id,
      :breaker_key,
      :integration_kind,
      :reason_code,
      :transition,
      :state
    ])
    |> validate_inclusion(:integration_kind, @integration_kinds)
    |> validate_inclusion(:state, @states)
  end
end
