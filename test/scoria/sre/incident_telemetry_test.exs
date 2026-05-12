defmodule Scoria.SRE.IncidentTelemetryTest do
  use ExUnit.Case, async: false

  alias Decimal, as: D
  alias Scoria.Repo
  alias Scoria.SRE

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    parent = self()
    handler_id = "incident-telemetry-test-#{System.unique_integer()}"

    :telemetry.attach(
      handler_id,
      [:scoria, :sre, :incident, :lifecycle],
      fn event, measurements, metadata, _config ->
        send(parent, {:telemetry_event, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)
    :ok
  end

  test "durable incident creation emits separate post-commit lifecycle telemetry" do
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

    assert_receive {:telemetry_event, [:scoria, :sre, :incident, :lifecycle], measurements, metadata}
    assert measurements.count == 1
    assert measurements.delivery_count == 1
    assert metadata.incident_key == incident.incident_key
    assert metadata.identity_key == "tenant-incident:workflow:tenant:default:quality:ci_baseline_dip:2026-05-12T09:new"
    assert metadata.trace_id == "trace-incident"
    assert metadata.scorer_version == "scorer-v4"
    assert metadata.baseline_version == "baseline-v9"
  end
end
