defmodule Scoria.SRE.ParapetTranslationTest do
  use ExUnit.Case, async: true

  alias Scoria.SRE.Adapters.Parapet
  alias Scoria.SRE.TelemetryIdentity

  test "runtime telemetry translates with canonical labels and ref-only correlation fields" do
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
      Parapet.translate([:scoria, :sre, :sli, :latency], %{duration_ms: 42}, metadata)

    assert translated.metric == "scoria.sli.latency"
    assert translated.labels.identity_key == "tenant-1:workflow_step:workflow:success:completed:global:success:workflow"
    assert translated.refs.trace_id == "trace-1"
    refute Map.has_key?(translated.labels, :incident_key)
  end

  test "incident telemetry keeps namespace separation and includes incident_key only after materialization" do
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
      Parapet.translate([:scoria, :sre, :incident, :lifecycle], %{count: 1, delivery_count: 1}, metadata)

    assert translated.metric == "scoria.incident.lifecycle"
    assert translated.labels.incident_key == "tenant-1:workflow:tenant:default:quality:ci_baseline_dip:2026-05-12T09"
    assert translated.labels.identity_key == "tenant-1:workflow:tenant:default:quality:ci_baseline_dip:2026-05-12T09:new"
    assert translated.refs.workflow_run_id == "run-1"
  end
end
