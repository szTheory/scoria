defmodule Scoria.SRE.NotificationDelivery do
  use Ecto.Schema
  import Ecto.Changeset

  @delivery_statuses ~w(pending delivering delivered failed abandoned)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_notification_deliveries" do
    field(:tenant_id, :string)
    field(:sink_kind, :string)
    field(:routing_key, :string)
    field(:delivery_status, :string, default: "pending")
    field(:pending_at, :utc_datetime_usec)
    field(:last_attempt_at, :utc_datetime_usec)
    field(:delivered_at, :utc_datetime_usec)
    field(:attempt_count, :integer, default: 0)
    field(:payload_hash, :string)
    field(:last_error, :string)
    field(:workflow_run_id, :binary_id)
    field(:trace_id, :string)
    field(:metadata, :map, default: %{})

    belongs_to(:incident, Scoria.SRE.Incident)
    belongs_to(:alert_event, Scoria.SRE.AlertEvent)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(delivery, attrs) do
    delivery
    |> cast(attrs, [
      :tenant_id,
      :incident_id,
      :alert_event_id,
      :sink_kind,
      :routing_key,
      :delivery_status,
      :pending_at,
      :last_attempt_at,
      :delivered_at,
      :attempt_count,
      :payload_hash,
      :last_error,
      :workflow_run_id,
      :trace_id,
      :metadata
    ])
    |> validate_required([
      :tenant_id,
      :sink_kind,
      :routing_key,
      :delivery_status,
      :pending_at,
      :attempt_count,
      :payload_hash
    ])
    |> validate_inclusion(:delivery_status, @delivery_statuses)
    |> validate_number(:attempt_count, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:incident_id)
    |> foreign_key_constraint(:alert_event_id)
  end
end
