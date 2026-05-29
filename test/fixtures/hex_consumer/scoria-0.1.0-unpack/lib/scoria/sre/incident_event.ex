defmodule Scoria.SRE.IncidentEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @event_types ~w(alert_linked status_changed note_added delivery_recorded)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_incident_events" do
    field(:tenant_id, :string)
    field(:incident_key, :string)
    field(:event_type, :string)
    field(:reason_code, :string)
    field(:actor_ref, :string)
    field(:workflow_run_id, :binary_id)
    field(:trace_id, :string)
    field(:evidence_refs, :map, default: %{})
    field(:metadata, :map, default: %{})

    belongs_to(:incident, Scoria.SRE.Incident)
    belongs_to(:alert_event, Scoria.SRE.AlertEvent)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(incident_event, attrs) do
    incident_event
    |> cast(attrs, [
      :tenant_id,
      :incident_id,
      :alert_event_id,
      :incident_key,
      :event_type,
      :reason_code,
      :actor_ref,
      :workflow_run_id,
      :trace_id,
      :evidence_refs,
      :metadata
    ])
    |> validate_required([
      :tenant_id,
      :incident_id,
      :incident_key,
      :event_type,
      :reason_code
    ])
    |> validate_inclusion(:event_type, @event_types)
    |> foreign_key_constraint(:incident_id)
    |> foreign_key_constraint(:alert_event_id)
  end
end
