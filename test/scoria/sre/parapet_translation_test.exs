defmodule Scoria.SRE.ParapetTranslationTest do
  use ExUnit.Case, async: true

  alias Decimal, as: D
  alias Scoria.SRE.Adapters.Parapet
  alias Scoria.SRE.TelemetryIdentity

  test "runtime telemetry translates the runtime namespace with canonical labels and ref-only correlation fields" do
    metadata =
      TelemetryIdentity.runtime_metadata(%{
        tenant_id: "tenant-1",
        subject_kind: "workflow_step",
        policy_key: "workflow:success",
        reason_code: "completed",
        trace_id: "trace-1",
        run_id: "run-1",
        tool_name: "success",
        integration_kind: "workflow"
      })

    translated =
      Parapet.translate([:scoria, :sre, :runtime, :latency], %{duration_ms: 42}, metadata)

    assert translated.metric == "scoria.runtime.latency"
    assert translated.category == :latency
    assert translated.value == 42
    assert translated.labels.identity_key == "tenant-1:workflow_step:workflow:success:completed:global:success:workflow"
    assert translated.refs.trace_id == "trace-1"
    assert translated.refs.run_id == "run-1"
    refute Map.has_key?(translated.labels, :incident_key)
  end

  test "incident telemetry preserves namespace separation while adding incident_key only after materialization" do
    metadata =
      TelemetryIdentity.incident_metadata(%{
        tenant_id: "tenant-1",
        subject_kind: "workflow",
        policy_key: "tenant:default:quality",
        reason_code: "ci_baseline_dip",
        incident_key: "tenant-1:workflow:tenant:default:quality:ci_baseline_dip:2026-05-12T09",
        trace_id: "trace-1",
        workflow_run_id: "run-1",
        window_bucket: "2026-05-12T09",
        state: "new"
      })

    translated =
      Parapet.translate(
        [:scoria, :sre, :incident, :delivery_intent],
        %{count: 1, delivery_count: 1, measured_value: D.new("0.61")},
        metadata
      )

    assert translated.metric == "scoria.incident.delivery_intent"
    assert translated.category == :delivery_intent
    assert translated.value == 1
    assert translated.labels.incident_key == "tenant-1:workflow:tenant:default:quality:ci_baseline_dip:2026-05-12T09"
    assert translated.labels.identity_key == "tenant-1:workflow:tenant:default:quality:ci_baseline_dip:2026-05-12T09:new"
    assert translated.refs.workflow_run_id == "run-1"
    assert translated.refs.trace_id == "trace-1"
  end
end
