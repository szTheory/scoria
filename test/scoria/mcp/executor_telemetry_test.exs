defmodule Scoria.MCP.ExecutorTelemetryTest do
  use ExUnit.Case, async: false

  alias Scoria.MCP.Executor
  alias Scoria.Repo

  defmodule DummyTool do
    @behaviour Scoria.MCP.Tool

    @impl true
    def name, do: "dummy_tool"

    @impl true
    def description, do: "A dummy tool for telemetry tests"

    @impl true
    def input_schema, do: %{}

    def execute(%{"action" => "success"}, _context), do: {:ok, %{result: "success"}}
    def execute(%{"action" => "crash"}, _context), do: raise("boom")
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    parent = self()
    handler_id = "mcp-telemetry-test-#{System.unique_integer()}"

    events = [
      [:scoria, :sre, :sli, :latency],
      [:scoria, :sre, :sli, :tool_reliability],
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
    :fuse.remove("remote_mcp:https://mcp.example.test")

    if :ets.whereis(:scoria_breaker_registry) != :undefined do
      :ets.delete(:scoria_breaker_registry, "remote_mcp:https://mcp.example.test")
    end

    :ok
  end

  test "completed MCP execution emits canonical runtime telemetry" do
    run_id = Ecto.UUID.generate()

    assert {:ok, %{result: "success"}} =
             Executor.execute(DummyTool, %{"action" => "success"}, %{
               tenant_id: "tenant-mcp",
               trace_id: "trace-mcp",
               run_id: run_id,
               integration_kind: "remote_mcp",
               tool_name: "dummy_tool",
               provider: "openai",
               model: "gpt-5"
             })

    assert_receive {:telemetry_event, [:scoria, :sre, :sli, :latency], measurements, metadata}
    assert is_integer(measurements.duration_ms)
    assert metadata.identity_key == "tenant-mcp:mcp_tool:Scoria.MCP.ExecutorTelemetryTest.DummyTool:completed:global:openai:gpt-5:dummy_tool:remote_mcp"
    assert metadata.run_id == run_id

    assert_receive {:telemetry_event, [:scoria, :sre, :sli, :tool_reliability], measurements, metadata}
    assert measurements.success_count == 1
    assert measurements.failure_count == 0
    assert metadata.tool_name == "dummy_tool"
    assert metadata.run_id == run_id
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

    assert_receive {:telemetry_event, [:scoria, :sre, :sli, :breaker_state], measurements, metadata}
    assert measurements.trip_count == 1
    assert metadata.breaker_key == "remote_mcp:https://mcp.example.test"
    assert metadata.state == "open"
    assert metadata.trace_id == "trace-breaker-open"
  end

  defp flush_mailbox do
    receive do
      _ -> flush_mailbox()
    after
      0 -> :ok
    end
  end
end
