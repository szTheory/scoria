defmodule Scoria.SRE.Incident do
  use Ecto.Schema
  import Ecto.Changeset

  @severities ~w(info warning critical)
  @statuses ~w(open acknowledged resolved closed)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_incidents" do
    field(:tenant_id, :string)
    field(:incident_key, :string)
    field(:severity, :string)
    field(:status, :string, default: "open")
    field(:summary, :string)
    field(:routing_class, :string)
    field(:dedupe_key, :string)
    field(:first_seen_at, :utc_datetime_usec)
    field(:last_seen_at, :utc_datetime_usec)
    field(:workflow_run_id, :binary_id)
    field(:trace_id, :string)
    field(:evidence_summary, :map, default: %{})
    field(:lock_version, :integer, default: 1)
    field(:metadata, :map, default: %{})

    has_many(:alert_events, Scoria.SRE.AlertEvent)
    has_many(:incident_events, Scoria.SRE.IncidentEvent)
    has_many(:notification_deliveries, Scoria.SRE.NotificationDelivery)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(incident, attrs) do
    incident
    |> cast(attrs, [
      :tenant_id,
      :incident_key,
      :severity,
      :status,
      :summary,
      :routing_class,
      :dedupe_key,
      :first_seen_at,
      :last_seen_at,
      :workflow_run_id,
      :trace_id,
      :evidence_summary,
      :lock_version,
      :metadata
    ])
    |> validate_required([
      :tenant_id,
      :incident_key,
      :severity,
      :status,
      :summary,
      :routing_class,
      :dedupe_key,
      :first_seen_at,
      :last_seen_at
    ])
    |> validate_inclusion(:severity, @severities)
    |> validate_inclusion(:status, @statuses)
    |> optimistic_lock(:lock_version)
    |> unique_constraint([:tenant_id, :incident_key])
  end
end
