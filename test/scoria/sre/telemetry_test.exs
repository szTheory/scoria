defmodule Scoria.SRE.TelemetryTest do
  use ExUnit.Case, async: false

  alias Scoria.SRE.Telemetry
  alias Scoria.SRE.TelemetryIdentity

  setup do
    parent = self()
    handler_id = "scoria-sre-telemetry-test-#{System.unique_integer()}"

    events = [
      [:scoria, :sre, :runtime, :latency],
      [:scoria, :sre, :runtime, :cost],
      [:scoria, :sre, :runtime, :quality],
      [:scoria, :sre, :runtime, :tool_reliability],
      [:scoria, :sre, :runtime, :budget_burn],
      [:scoria, :sre, :runtime, :breaker_state]
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

  test "quality telemetry preserves canonical identity and correlation refs for Parapet consumers" do
    :ok =
      Telemetry.emit_quality(%{
        score: 0.61,
        threshold: 0.8,
        tenant_id: "tenant-1",
        subject_kind: "workflow",
        reason_code: "quality_regression",
        severity: "review",
        trace_id: "trace-123",
        run_id: "run-123",
        policy_key: "quality:helpfulness",
        scorer_version: "scorer:v2",
        baseline_version: "baseline:v4",
        prompt_text: "should not leak"
      })

    assert_receive {:telemetry_event, [:scoria, :sre, :runtime, :quality], measurements, metadata}
    assert measurements.score == 0.61
    assert measurements.threshold == 0.8
    assert metadata.identity_key ==
             TelemetryIdentity.identity_key(%{
               tenant_id: "tenant-1",
               subject_kind: "workflow",
               policy_key: "quality:helpfulness",
               reason_code: "quality_regression",
               window_bucket: "global",
               severity: "review"
             })

    assert metadata.reason_code == "quality_regression"
    assert metadata.scorer_version == "scorer:v2"
    assert metadata.baseline_version == "baseline:v4"
    refute Map.has_key?(metadata, :incident_key)
    refute Map.has_key?(metadata, :prompt_text)

  end

  test "latency telemetry emits stable incident metadata with low-cardinality labels" do
    :ok =
      Telemetry.emit_latency(%{
        duration_ms: 245,
        threshold_ms: 200,
        tenant_id: "tenant-1",
        subject_kind: "workflow_step",
        reason_code: "latency_budget_burn",
        severity: "page",
        trace_id: "trace-latency",
        run_id: "run-latency",
        policy_key: "provider:openai",
        provider: "openai",
        model: "gpt-5",
        actor_id: "actor-123"
      })

    assert_receive {:telemetry_event, [:scoria, :sre, :runtime, :latency], measurements, metadata}
    assert measurements.duration_ms == 245
    assert measurements.threshold_ms == 200
    assert metadata.provider == "openai"
    assert metadata.model == "gpt-5"
    assert metadata.identity_key ==
             "tenant-1:workflow_step:provider:openai:latency_budget_burn:global:openai:gpt-5"
    assert metadata.actor_id == "actor-123"
  end

  test "telemetry identity splits canonical labels from correlation refs" do
    attrs = %{
      tenant_id: "tenant-1",
      subject_kind: "mcp_tool",
      actor_id: "actor-tool",
      session_id: "session-tool",
      policy_key: "tool:refund_customer",
      reason_code: "timeout",
      window_bucket: "5m",
      provider: "openai",
      model: "gpt-5",
      tool_name: "refund_customer",
      integration_kind: "remote_mcp",
      trace_id: "trace-tool",
      run_id: "run-tool",
      workflow_run_id: "run-tool",
      incident_key: "tenant-1:mcp_tool:tool:refund_customer:timeout:5m",
      prompt_text: "do not leak",
      tool_arguments: %{"customer_id" => "cus_123"}
    }

    assert TelemetryIdentity.labels(attrs) == %{
             identity_key: "tenant-1:mcp_tool:tool:refund_customer:timeout:5m:openai:gpt-5:refund_customer:remote_mcp",
             tenant_id: "tenant-1",
             subject_kind: "mcp_tool",
             policy_key: "tool:refund_customer",
             reason_code: "timeout",
             window_bucket: "5m",
             provider: "openai",
             model: "gpt-5",
             tool_name: "refund_customer",
             integration_kind: "remote_mcp"
           }

    assert TelemetryIdentity.refs(attrs) == %{
             actor_id: "actor-tool",
             session_id: "session-tool",
             trace_id: "trace-tool",
             run_id: "run-tool",
             workflow_run_id: "run-tool"
           }

    runtime_metadata = TelemetryIdentity.runtime_metadata(attrs)
    incident_metadata = TelemetryIdentity.incident_metadata(attrs)

    assert runtime_metadata == Map.merge(TelemetryIdentity.labels(attrs), TelemetryIdentity.refs(attrs))
    refute Map.has_key?(runtime_metadata, :incident_key)
    refute Map.has_key?(runtime_metadata, :prompt_text)
    refute Map.has_key?(runtime_metadata, :tool_arguments)

    assert incident_metadata.incident_key == "tenant-1:mcp_tool:tool:refund_customer:timeout:5m"
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

    assert_receive {:telemetry_event, [:scoria, :sre, :runtime, :tool_reliability], measurements, metadata}
    assert measurements.duration_ms == 5_000
    assert measurements.failure_count == 1
    assert metadata.tool_name == "refund_customer"
    assert metadata.integration_kind == "remote_mcp"
    refute Map.has_key?(metadata, :tool_arguments)

  end
end
