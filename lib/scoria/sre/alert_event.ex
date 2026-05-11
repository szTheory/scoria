defmodule Scoria.SRE.AlertEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @severities ~w(info warning critical)
  @statuses ~w(new deduped acked resolved)

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_alert_events" do
    field(:tenant_id, :string)
    field(:incident_key, :string)
    field(:reason_code, :string)
    field(:severity, :string)
    field(:status, :string, default: "new")
    field(:measured_value, :decimal)
    field(:threshold_value, :decimal)
    field(:scorer_version_ref, :string)
    field(:baseline_version_ref, :string)
    field(:workflow_run_id, :binary_id)
    field(:trace_id, :string)
    field(:evidence_refs, :map, default: %{})
    field(:metadata, :map, default: %{})

    belongs_to(:alert_policy, Scoria.SRE.AlertPolicy)
    belongs_to(:incident, Scoria.SRE.Incident)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(alert_event, attrs) do
    alert_event
    |> cast(attrs, [
      :tenant_id,
      :alert_policy_id,
      :incident_id,
      :incident_key,
      :reason_code,
      :severity,
      :status,
      :measured_value,
      :threshold_value,
      :scorer_version_ref,
      :baseline_version_ref,
      :workflow_run_id,
      :trace_id,
      :evidence_refs,
      :metadata
    ])
    |> validate_required([
      :tenant_id,
      :incident_key,
      :reason_code,
      :severity,
      :status,
      :measured_value,
      :threshold_value
    ])
    |> validate_inclusion(:severity, @severities)
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:alert_policy_id)
    |> foreign_key_constraint(:incident_id)
  end
end
