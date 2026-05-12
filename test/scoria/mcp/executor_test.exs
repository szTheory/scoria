defmodule Scoria.MCP.ExecutorTest do
  use ExUnit.Case, async: false

  alias Scoria.MCP.Executor
  alias Scoria.Repo
  alias Scoria.SRE
  alias Scoria.SRE.BudgetReservation

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

  defmodule BlockingTool do
    @behaviour Scoria.MCP.Tool

    @impl true
    def name, do: "blocking_tool"

    @impl true
    def description, do: "A blocking tool for audit seam tests"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(args, context) do
      send(context.test_pid, {:tool_started, self(), context.trace_id, args})

      receive do
        :continue -> {:ok, %{result: "released"}}
      after
        1_000 -> {:error, :timed_out_waiting_for_test}
      end
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :fuse.remove("remote_mcp:https://mcp.example.test")
    :fuse.remove("tool:local-dummy")
    if :ets.whereis(:scoria_breaker_registry) != :undefined, do: :ets.delete(:scoria_breaker_registry, "remote_mcp:https://mcp.example.test")

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

    %{ref: ref, context: %{actor_id: "user-123", tenant_id: "tenant-1"}}
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

    test "timeout paths reconcile the durable reservation", %{context: context} do
      create_budget_policy!("tenant-1", "cost_usd")
      trace_id = "trace-timeout"

      assert {:error, :timeout} =
               Executor.execute(
                 DummyTool,
                 %{"action" => "timeout"},
                 Map.merge(context, %{
                   trace_id: trace_id,
                   run_id: Ecto.UUID.generate(),
                   estimated_cost_usd: Decimal.new("5.0"),
                   integration_kind: "tool",
                   sensitive_tool: true
                 }),
                 100
               )

      reservation = Repo.get_by!(BudgetReservation, trace_id: trace_id)
      assert reservation.status == "reconciled"
      assert Decimal.equal?(reservation.actual_units, Decimal.new("0"))
      assert reservation.metadata["outcome"] == "timeout"
    end

    test "crash paths reconcile the durable reservation", %{context: context} do
      create_budget_policy!("tenant-1", "cost_usd")
      trace_id = "trace-crash"

      assert {:error, :execution_failed} =
               Executor.execute(
                 DummyTool,
                 %{"action" => "crash"},
                 Map.merge(context, %{
                   trace_id: trace_id,
                   run_id: Ecto.UUID.generate(),
                   estimated_cost_usd: Decimal.new("5.0"),
                   integration_kind: "tool",
                   sensitive_tool: true
                 })
               )

      reservation = Repo.get_by!(BudgetReservation, trace_id: trace_id)
      assert reservation.status == "reconciled"
      assert Decimal.equal?(reservation.actual_units, Decimal.new("0"))
      assert reservation.metadata["outcome"] == "execution_failed"
    end

    test "breaker-open failures reconcile reservations and stay distinct from timeouts for remote integrations",
         %{context: context} do
      create_budget_policy!("tenant-1", "cost_usd")
      trace_id = "trace-breaker-open"

      remote_context =
        Map.merge(context, %{
          integration_kind: "remote_mcp",
          mcp_endpoint: "https://mcp.example.test",
          run_id: Ecto.UUID.generate(),
          estimated_cost_usd: Decimal.new("5.0"),
          sensitive_tool: true
        })

      assert {:error, :execution_failed} = Executor.execute(DummyTool, %{"action" => "crash"}, remote_context)

      assert {:error, envelope} =
               Executor.execute(
                 DummyTool,
                 %{"action" => "success"},
                 Map.put(remote_context, :trace_id, trace_id)
               )

      assert envelope.status == :breaker_open
      assert envelope.reason_code == "breaker_open"
      assert envelope.breaker_key == "remote_mcp:https://mcp.example.test"

      reservation = Repo.get_by!(BudgetReservation, trace_id: trace_id)
      assert reservation.status == "reconciled"
      assert Decimal.equal?(reservation.actual_units, Decimal.new("0"))
      assert reservation.metadata["outcome"] == "breaker_open"
    end

    test "local tools are not breaker-wrapped unless the context marks them external", %{context: context} do
      local_context = Map.merge(context, %{integration_kind: "tool", tool_target: "local-dummy"})

      assert {:error, :execution_failed} = Executor.execute(DummyTool, %{"action" => "crash"}, local_context)
      assert {:ok, %{result: "success"}} = Executor.execute(DummyTool, %{"action" => "success"}, local_context)
    end

    test "writes a redacted policy-sensitive audit row before the tool invocation completes", %{context: context} do
      trace_id = "trace-sensitive-tool"
      parent = self()

      task =
        Task.async(fn ->
          Executor.execute(
            BlockingTool,
            %{"token" => "secret-value", "target" => "prod"},
            Map.merge(context, %{
              trace_id: trace_id,
              run_id: Ecto.UUID.generate(),
              step_id: Ecto.UUID.generate(),
              tenant_id: "tenant-1",
              actor_id: "user-123",
              policy_sensitive: true,
              tool_target: "deploy_prod",
              test_pid: parent
            }),
            1_000
          )
        end)

      assert_receive {:tool_started, tool_pid, ^trace_id, _args}

      audit_event = Repo.get_by!(Scoria.SRE.AuditOutboxEvent, trace_id: trace_id)
      assert audit_event.event_type == "tool.invocation"
      assert audit_event.policy_class == "policy_sensitive"
      assert audit_event.redacted_refs["args"]["token"] == "[REDACTED]"
      assert audit_event.redacted_refs["args"]["target"] == "prod"
      refute audit_event.metadata["raw_args"]

      send(tool_pid, :continue)
      assert {:ok, %{result: "released"}} = Task.await(task)
    end

    test "writes a durable sensitive MCP access denied audit row without executing the tool", %{context: context} do
      trace_id = "trace-access-denied"

      assert {:error, %{status: :access_denied}} =
               Executor.execute(
                 DummyTool,
                 %{"token" => "secret-value", "target" => "prod"},
                 Map.merge(context, %{
                   trace_id: trace_id,
                   tenant_id: "tenant-1",
                   actor_id: "user-123",
                   integration_kind: "remote_mcp",
                   mcp_endpoint: "https://mcp.example.test",
                   sensitive_mcp_access: true,
                   access_decision: "denied",
                   policy_key: "mcp.admin",
                   access_reason: "policy_denied"
                 })
               )

      audit_event = Repo.get_by!(Scoria.SRE.AuditOutboxEvent, trace_id: trace_id)
      assert audit_event.event_type == "mcp.access.denied"
      assert audit_event.policy_class == "sensitive_mcp_access"
      assert audit_event.redacted_refs["args"]["token"] == "[REDACTED]"
      assert audit_event.redacted_refs["access_decision"] == "denied"
    end
  end

  defp create_budget_policy!(tenant_id, resource_kind) do
    assert {:ok, _policy} =
             SRE.create_budget_policy(%{
               tenant_id: tenant_id,
               policy_key: "tenant:default:#{resource_kind}",
               scope_key: "tenant:#{tenant_id}",
               scope_kind: "tenant",
               resource_kind: resource_kind,
               status: "active",
               warn_threshold: Decimal.new("80.0"),
               trip_threshold: Decimal.new("100.0"),
               max_workflow_steps: 25,
               max_repeated_tool_calls: 3,
               max_consecutive_failures: 2,
               metadata: %{}
             })
  end

end
