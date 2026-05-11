defmodule Scoria.SRE.TelemetryTest do
  use ExUnit.Case, async: false

  alias Scoria.SRE.Adapters.Parapet
  alias Scoria.SRE.Telemetry

  setup do
    parent = self()
    handler_id = "scoria-sre-telemetry-test-#{System.unique_integer()}"

    events = [
      [:scoria, :sre, :sli, :latency],
      [:scoria, :sre, :sli, :cost],
      [:scoria, :sre, :sli, :quality],
      [:scoria, :sre, :sli, :tool_reliability],
      [:scoria, :sre, :sli, :budget_burn],
      [:scoria, :sre, :sli, :breaker_state]
    ]

    :telemetry.attach_many(
      handler_id,
      events,
      fn event, measurements, metadata, _config ->
        send(parent, {:telemetry_event, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)
    :ok
  end

  test "quality telemetry preserves incident and version metadata for Parapet consumers" do
    :ok =
      Telemetry.emit_quality(%{
        score: 0.61,
        threshold: 0.8,
        tenant_id: "tenant-1",
        incident_key: "tenant-1:quality:helpfulness:quality_regression",
        reason_code: "quality_regression",
        severity: "review",
        trace_id: "trace-123",
        run_id: "run-123",
        policy_key: "quality:helpfulness",
        scorer_version: "scorer:v2",
        baseline_version: "baseline:v4",
        prompt_text: "should not leak"
      })

    assert_receive {:telemetry_event, [:scoria, :sre, :sli, :quality], measurements, metadata}
    assert measurements.score == 0.61
    assert measurements.threshold == 0.8
    assert metadata.incident_key == "tenant-1:quality:helpfulness:quality_regression"
    assert metadata.reason_code == "quality_regression"
    assert metadata.scorer_version == "scorer:v2"
    assert metadata.baseline_version == "baseline:v4"
    refute Map.has_key?(metadata, :prompt_text)

    parapet_event = Parapet.translate([:scoria, :sre, :sli, :quality], measurements, metadata)

    assert parapet_event.metric == "scoria.sli.quality"
    assert parapet_event.category == :quality
    assert parapet_event.labels.policy_key == "quality:helpfulness"
    assert parapet_event.refs.trace_id == "trace-123"
    assert parapet_event.refs.scorer_version == "scorer:v2"
    assert parapet_event.refs.baseline_version == "baseline:v4"
  end

  test "latency telemetry emits stable incident metadata with low-cardinality labels" do
    :ok =
      Telemetry.emit_latency(%{
        duration_ms: 245,
        threshold_ms: 200,
        tenant_id: "tenant-1",
        incident_key: "tenant-1:latency:provider:openai:latency_budget",
        reason_code: "latency_budget_burn",
        severity: "page",
        trace_id: "trace-latency",
        run_id: "run-latency",
        policy_key: "provider:openai",
        provider: "openai",
        model: "gpt-5",
        actor_id: "actor-123"
      })

    assert_receive {:telemetry_event, [:scoria, :sre, :sli, :latency], measurements, metadata}
    assert measurements.duration_ms == 245
    assert measurements.threshold_ms == 200
    assert metadata.provider == "openai"
    assert metadata.model == "gpt-5"
    assert metadata.incident_key == "tenant-1:latency:provider:openai:latency_budget"
    refute Map.has_key?(metadata, :actor_id)
  end

  test "tool reliability telemetry shapes safe envelopes for Parapet" do
    :ok =
      Telemetry.emit_tool_reliability(%{
        success: false,
        duration_ms: 5_000,
        tenant_id: "tenant-1",
        incident_key: "tenant-1:tool:refund_customer:timeout",
        reason_code: "tool_timeout",
        severity: "page",
        trace_id: "trace-tool",
        run_id: "run-tool",
        policy_key: "tool:refund_customer",
        tool_name: "refund_customer",
        integration_kind: "remote_mcp",
        tool_arguments: %{"customer_id" => "cus_123"}
      })

    assert_receive {:telemetry_event, [:scoria, :sre, :sli, :tool_reliability], measurements, metadata}
    assert measurements.duration_ms == 5_000
    assert measurements.failure_count == 1
    assert metadata.tool_name == "refund_customer"
    assert metadata.integration_kind == "remote_mcp"
    refute Map.has_key?(metadata, :tool_arguments)

    parapet_event = Parapet.translate([:scoria, :sre, :sli, :tool_reliability], measurements, metadata)

    assert parapet_event.metric == "scoria.sli.tool_reliability"
    assert parapet_event.labels.tool_name == "refund_customer"
    assert parapet_event.labels.integration_kind == "remote_mcp"
    assert parapet_event.value == 1
  end
end
