defmodule Scoria.SRE.IncidentTelemetryTest do
  use ExUnit.Case, async: false

  alias Decimal, as: D
  alias Scoria.Repo
  alias Scoria.SRE
  alias Scoria.SRE.Incident

  @incident_events [
    [:scoria, :sre, :incident, :created],
    [:scoria, :sre, :incident, :alert_recorded],
    [:scoria, :sre, :incident, :event_appended],
    [:scoria, :sre, :incident, :delivery_intent]
  ]

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    parent = self()
    handler_id = "incident-telemetry-test-#{System.unique_integer()}"

    :telemetry.attach_many(
      handler_id,
      @incident_events,
      fn event, measurements, metadata, _config ->
        send(parent, {:telemetry_event, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)
    :ok
  end

  test "open_incident emits post-commit created telemetry with canonical identity" do
    assert {:ok, incident} =
             SRE.open_incident(%{
               tenant_id: "tenant-open",
               subject_kind: "workflow",
               policy_key: "tenant:default:quality",
               reason_code: "ci_baseline_dip",
               summary: "Open incident",
               trace_id: "trace-open",
               workflow_run_id: Ecto.UUID.generate(),
               window_bucket: "2026-05-12T09",
               routing_class: "review"
             })

    assert_receive {:telemetry_event, [:scoria, :sre, :incident, :created], measurements, metadata}
    assert measurements.count == 1
    assert metadata.incident_key == incident.incident_key
    assert metadata.identity_key == "tenant-open:workflow:tenant:default:quality:ci_baseline_dip:2026-05-12T09:new"
    assert metadata.trace_id == "trace-open"
    refute_received {:telemetry_event, [:scoria, :sre, :runtime, _category], _measurements, _metadata}
  end

  test "durable alert routing emits separate incident, alert, event, and delivery telemetry after commit" do
    assert {:ok, %{incident: incident, notification_deliveries: [delivery]}} =
             SRE.record_alert_event(%{
               tenant_id: "tenant-incident",
               subject_kind: "workflow",
               policy_key: "tenant:default:quality",
               reason_code: "ci_baseline_dip",
               summary: "Review incident",
               measured_value: D.new("0.61"),
               threshold_value: D.new("0.75"),
               scorer_version: "scorer-v4",
               baseline_version: "baseline-v9",
               trace_id: "trace-incident",
               workflow_run_id: Ecto.UUID.generate(),
               window_bucket: "2026-05-12T09",
               routing_class: "review"
             })

    assert delivery.delivery_status == "pending"

    assert_receive {:telemetry_event, [:scoria, :sre, :incident, :created], created_measurements, created_metadata}
    assert created_measurements.count == 1
    assert created_metadata.incident_key == incident.incident_key
    assert created_metadata.identity_key == "tenant-incident:workflow:tenant:default:quality:ci_baseline_dip:2026-05-12T09:new"

    assert_receive {:telemetry_event, [:scoria, :sre, :incident, :alert_recorded], alert_measurements, alert_metadata}
    assert alert_measurements.count == 1
    assert alert_measurements.measured_value == D.new("0.61")
    assert alert_metadata.incident_key == incident.incident_key

    assert_receive {:telemetry_event, [:scoria, :sre, :incident, :event_appended], event_measurements, event_metadata}
    assert event_measurements.count == 1
    assert event_metadata.incident_key == incident.incident_key
    assert event_metadata.trace_id == "trace-incident"

    assert_receive {:telemetry_event, [:scoria, :sre, :incident, :delivery_intent], delivery_measurements, delivery_metadata}
    assert delivery_measurements.count == 1
    assert delivery_measurements.delivery_count == 1
    assert delivery_metadata.incident_key == incident.incident_key
    assert delivery_metadata.scorer_version == "scorer-v4"
    assert delivery_metadata.baseline_version == "baseline-v9"
  end

  test "append_incident_event emits only after the incident-event write commits" do
    assert {:ok, incident} =
             SRE.open_incident(%{
               tenant_id: "tenant-append",
               subject_kind: "workflow",
               policy_key: "tenant:default:quality",
               reason_code: "ci_baseline_dip",
               summary: "Append target",
               trace_id: "trace-append-open",
               workflow_run_id: Ecto.UUID.generate(),
               window_bucket: "2026-05-12T10"
             })

    assert_receive {:telemetry_event, [:scoria, :sre, :incident, :created], _measurements, _metadata}

    assert {:ok, incident_event} =
             SRE.append_incident_event(incident, %{
               event_type: "note_added",
               reason_code: "incident_note",
               actor_ref: "operator:42",
               trace_id: "trace-append-event",
               workflow_run_id: incident.workflow_run_id
             })

    assert_receive {:telemetry_event, [:scoria, :sre, :incident, :event_appended], measurements, metadata}
    assert measurements.count == 1
    assert metadata.incident_key == incident.incident_key
    assert metadata.trace_id == incident_event.trace_id
    assert metadata.reason_code == "incident_note"
  end

  test "append_incident_event does not emit telemetry when the incident-event write rolls back" do
    missing_incident = %Incident{
      id: Ecto.UUID.generate(),
      tenant_id: "tenant-missing",
      incident_key: "tenant-missing:workflow:tenant:default:quality:ci_baseline_dip:2026-05-12T11",
      workflow_run_id: Ecto.UUID.generate(),
      trace_id: "trace-missing",
      status: "open"
    }

    assert {:error, _changeset} =
             SRE.append_incident_event(missing_incident, %{
               event_type: "note_added",
               reason_code: "incident_note",
               actor_ref: "operator:404"
             })

    refute_received {:telemetry_event, [:scoria, :sre, :incident, :event_appended], _measurements, _metadata}
  end
end
