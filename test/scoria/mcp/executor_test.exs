defmodule Scoria.MCP.ExecutorTest do
  use ExUnit.Case, async: true

  alias Scoria.MCP.Executor

  defmodule DummyTool do
    @behaviour Scoria.MCP.Tool

    @impl true
    def name, do: "dummy_tool"

    @impl true
    def description, do: "A dummy tool for testing"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(%{"action" => "success"}, _context) do
      {:ok, %{result: "success"}}
    end

    def execute(%{"action" => "timeout"}, _context) do
      Process.sleep(5000)
      {:ok, %{result: "late"}}
    end

    def execute(%{"action" => "crash"}, _context) do
      raise "boom"
    end
    
    def execute(%{"action" => "exit"}, _context) do
      exit(:killed)
    end
  end

  setup do
    # Capture telemetry events
    parent = self()
    ref = make_ref()

    handler = fn event_name, measurements, metadata, _config ->
      if metadata.tool == Scoria.MCP.ExecutorTest.DummyTool do
        send(parent, {:telemetry_event, ref, event_name, measurements, metadata})
      end
    end

    events = [
      [:scoria, :tool, :started],
      [:scoria, :tool, :completed],
      [:scoria, :tool, :timeout],
      [:scoria, :tool, :failed]
    ]

    handler_id = "executor-test-#{System.unique_integer()}"
    :telemetry.attach_many(handler_id, events, handler, nil)

    on_exit(fn ->
      :telemetry.detach(handler_id)
    end)

    %{ref: ref, context: %{actor_id: "user-123"}}
  end

  describe "execute/4" do
    test "returns tool result and emits started/completed events", %{ref: ref, context: context} do
      assert {:ok, %{result: "success"}} = Executor.execute(DummyTool, %{"action" => "success"}, context)

      assert_receive {:telemetry_event, ^ref, [:scoria, :tool, :started], _measurements, metadata}
      assert metadata.actor_id == "user-123"

      assert_receive {:telemetry_event, ^ref, [:scoria, :tool, :completed], _measurements, metadata}
      assert metadata.actor_id == "user-123"
    end

    test "terminates tool if it exceeds timeout and emits timeout event", %{ref: ref, context: context} do
      # Use a short timeout for the test
      assert {:error, :timeout} = Executor.execute(DummyTool, %{"action" => "timeout"}, context, 100)

      assert_receive {:telemetry_event, ^ref, [:scoria, :tool, :started], _measurements, metadata}
      assert metadata.actor_id == "user-123"

      assert_receive {:telemetry_event, ^ref, [:scoria, :tool, :timeout], _measurements, metadata}
      assert metadata.actor_id == "user-123"
    end

    test "isolates crashes and emits failed event", %{ref: ref, context: context} do
      # We shouldn't crash the test process
      assert {:error, :execution_failed} = Executor.execute(DummyTool, %{"action" => "crash"}, context)

      assert_receive {:telemetry_event, ^ref, [:scoria, :tool, :started], _measurements, metadata}
      assert metadata.actor_id == "user-123"

      assert_receive {:telemetry_event, ^ref, [:scoria, :tool, :failed], _measurements, metadata}
      assert metadata.actor_id == "user-123"
      assert metadata.reason != nil
    end
    
    test "isolates exits and emits failed event", %{ref: ref, context: context} do
      assert {:error, :execution_failed} = Executor.execute(DummyTool, %{"action" => "exit"}, context)

      assert_receive {:telemetry_event, ^ref, [:scoria, :tool, :failed], _measurements, metadata}
      assert metadata.actor_id == "user-123"
    end
  end
end
