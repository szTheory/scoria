defmodule Scoria.MCP.ExecutorTelemetryTest do
  use ExUnit.Case, async: false

  alias Scoria.MCP.Executor
  alias Scoria.Repo
  alias Scoria.SRE

  defmodule DummyTool do
    @behaviour Scoria.MCP.Tool

    @impl true
    def name, do: "dummy_tool"

    @impl true
    def description, do: "A dummy tool for telemetry tests"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(%{"action" => "success"}, _context), do: {:ok, %{result: "success", actual_units: 3}}

    @impl true
    def execute(%{"action" => "sleep"}, _context) do
      Process.sleep(50)
      {:ok, %{}}
    end

    @impl true
    def execute(%{"action" => "crash"}, _context), do: raise("boom")
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    parent = self()
    handler_id = "mcp-telemetry-test-#{System.unique_integer()}"

    events = [
      [:scoria, :sre, :runtime, :latency],
      [:scoria, :sre, :runtime, :cost],
      [:scoria, :sre, :runtime, :budget_burn],
      [:scoria, :sre, :runtime, :tool_reliability],
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
    :fuse.remove("remote_mcp:https://mcp.example.test")

    if :ets.whereis(:scoria_breaker_registry) != :undefined do
      :ets.delete(:scoria_breaker_registry, "remote_mcp:https://mcp.example.test")
    end

    :ok
  end

  test "completed MCP execution emits canonical runtime telemetry" do
    run_id = Ecto.UUID.generate()
    create_budget_policy!("tenant-mcp", "tool_calls")

    assert {:ok, %{result: "success"}} =
             Executor.execute(DummyTool, %{"action" => "success"}, %{
               tenant_id: "tenant-mcp",
               trace_id: "trace-mcp",
               run_id: run_id,
               estimated_units: 5,
               integration_kind: "remote_mcp",
               tool_name: "dummy_tool",
               provider: "openai",
               model: "gpt-5"
             })

    assert_receive {:telemetry_event, [:scoria, :sre, :runtime, :latency], measurements, metadata}
    assert is_integer(measurements.duration_ms)
    assert metadata.identity_key == "tenant-mcp:mcp_tool:Scoria.MCP.ExecutorTelemetryTest.DummyTool:completed:global:openai:gpt-5:dummy_tool:remote_mcp"
    assert metadata.run_id == run_id

    assert_receive {:telemetry_event, [:scoria, :sre, :runtime, :tool_reliability], measurements, metadata}
    assert measurements.success_count == 1
    assert measurements.failure_count == 0
    assert metadata.tool_name == "dummy_tool"
    assert metadata.run_id == run_id

    assert_receive {:telemetry_event, [:scoria, :sre, :runtime, :cost], measurements, metadata}
    assert measurements.cost_usd == 3
    assert metadata.reason_code == "completed"

    assert_receive {:telemetry_event, [:scoria, :sre, :runtime, :budget_burn], measurements, _metadata}
    assert measurements.burn_rate == 0.6
    assert measurements.budget_remaining == 2
    assert measurements.threshold == 5
  end

  test "breaker-open MCP execution emits breaker-state telemetry with the shared identity contract" do
    context = %{
      tenant_id: "tenant-mcp",
      trace_id: "trace-breaker-open",
      run_id: Ecto.UUID.generate(),
      integration_kind: "remote_mcp",
      mcp_endpoint: "https://mcp.example.test"
    }

    assert {:error, :execution_failed} = Executor.execute(DummyTool, %{"action" => "crash"}, context)
    flush_mailbox()

    assert {:error, envelope} = Executor.execute(DummyTool, %{"action" => "success"}, context)
    assert envelope.status == :breaker_open

    assert_receive {:telemetry_event, [:scoria, :sre, :runtime, :breaker_state], measurements, metadata}
    assert measurements.trip_count == 1
    assert metadata.breaker_key == "remote_mcp:https://mcp.example.test"
    assert metadata.state == "open"
    assert metadata.trace_id == "trace-breaker-open"
  end

  test "access-denied MCP execution emits denied runtime telemetry from the execution seam" do
    context = %{
      tenant_id: "tenant-mcp",
      trace_id: "trace-access-denied",
      run_id: Ecto.UUID.generate(),
      integration_kind: "remote_mcp",
      sensitive_mcp_access: true,
      access_decision: "denied",
      access_reason: "policy_denied",
      policy_key: "tool:dummy_tool"
    }

    assert {:error, envelope} = Executor.execute(DummyTool, %{"action" => "success"}, context)
    assert envelope.status == :access_denied

    assert_receive {:telemetry_event, [:scoria, :sre, :runtime, :latency], measurements, metadata}
    assert measurements.duration_ms == 0
    assert metadata.reason_code == "access_denied"
    assert metadata.trace_id == "trace-access-denied"

    assert_receive {:telemetry_event, [:scoria, :sre, :runtime, :tool_reliability], measurements, _metadata}
    assert measurements.success_count == 0
    assert measurements.failure_count == 1
  end

  defp flush_mailbox do
    receive do
      _ -> flush_mailbox()
    after
      0 -> :ok
    end
  end

  defp create_budget_policy!(tenant_id, resource_kind) do
    {:ok, _policy} =
      SRE.create_budget_policy(%{
        tenant_id: tenant_id,
        policy_key: "#{tenant_id}:#{resource_kind}",
        scope_key: tenant_id,
        scope_kind: "tenant",
        resource_kind: resource_kind,
        warn_threshold: Decimal.new("100"),
        trip_threshold: Decimal.new("200")
      })
  end
end
