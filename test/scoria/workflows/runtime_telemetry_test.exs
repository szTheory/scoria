defmodule Scoria.Workflows.RuntimeTelemetryTest do
  use ExUnit.Case, async: false

  alias Scoria.Repo
  alias Scoria.SRE
  alias Scoria.Workflows
  alias Scoria.Workflows.Runtime

  defmodule Handlers do
    def succeed(step, _run), do: {:ok, %{"step_id" => step.id, "actual_units" => 4}}
    def fail(_step, _run), do: {:error, :boom}
    def sleep(_step, _run) do
      Process.sleep(50)
      {:ok, %{}}
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    parent = self()
    handler_id = "runtime-telemetry-test-#{System.unique_integer()}"

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
    :fuse.remove("provider:runtime-telemetry")

    if :ets.whereis(:scoria_breaker_registry) != :undefined do
      :ets.delete(:scoria_breaker_registry, "provider:runtime-telemetry")
    end

    :ok
  end

  test "completed workflow execution emits canonical latency and reliability telemetry" do
    create_budget_policy!("tenant-runtime", "workflow_steps")
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        actor_id: "runtime-actor",
        tenant_id: "tenant-runtime",
        session_id: "runtime-session"
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "success",
        role_id: "executor",
        status: "queued"
      })

    assert {:ok, _completed_step} =
             Runtime.execute_step(step.id,
               handler: {Handlers, :succeed},
               budget_context: %{
                 tenant_id: "tenant-runtime",
                 trace_id: "trace-runtime",
                 estimated_units: 10,
                 integration_kind: "provider",
                 provider: "openai",
                 model: "gpt-5"
               }
             )

    assert_receive {:telemetry_event, [:scoria, :sre, :runtime, :latency], measurements, metadata}
    assert is_integer(measurements.duration_ms)
    assert metadata.identity_key == "tenant-runtime:workflow_step:workflow:success:completed:global:openai:gpt-5:success:provider"
    assert metadata.actor_id == "runtime-actor"
    assert metadata.session_id == "runtime-session"
    assert metadata.trace_id == "trace-runtime"
    refute Map.has_key?(metadata, :incident_key)

    assert_receive {:telemetry_event, [:scoria, :sre, :runtime, :tool_reliability], measurements, metadata}
    assert measurements.success_count == 1
    assert measurements.failure_count == 0
    assert metadata.tool_name == "success"

    assert_receive {:telemetry_event, [:scoria, :sre, :runtime, :cost], measurements, metadata}
    assert measurements.cost_usd == 4
    assert metadata.reason_code == "completed"

    assert_receive {:telemetry_event, [:scoria, :sre, :runtime, :budget_burn], measurements, _metadata}
    assert measurements.burn_rate == 0.4
    assert measurements.budget_remaining == 6
    assert measurements.threshold == 10
  end

  test "breaker-open workflow execution emits breaker-state telemetry on the real seam" do
    {:ok, first_run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, first_step} =
      Workflows.create_step(first_run.id, %{
        sequence: 1,
        kind: "failing",
        role_id: "executor",
        status: "queued"
      })

    assert {:ok, _failed_step} =
             Runtime.execute_step(first_step.id,
               handler: {Handlers, :fail},
               breaker_context: %{integration_kind: "provider", provider_ref: "runtime-telemetry"}
             )

    flush_mailbox()

    {:ok, second_run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, second_step} =
      Workflows.create_step(second_run.id, %{
        sequence: 1,
        kind: "failing",
        role_id: "executor",
        status: "queued"
      })

    assert {:ok, blocked_step} =
             Runtime.execute_step(second_step.id,
               handler: {Handlers, :fail},
               budget_context: %{tenant_id: "tenant-runtime", trace_id: "trace-breaker"},
               breaker_context: %{integration_kind: "provider", provider_ref: "runtime-telemetry"}
             )

    assert blocked_step.error_envelope["reason_code"] == "breaker_open"

    assert_receive {:telemetry_event, [:scoria, :sre, :runtime, :breaker_state], measurements, metadata}
    assert measurements.trip_count == 1
    assert metadata.breaker_key == "provider:runtime-telemetry"
    assert metadata.state == "open"
    assert metadata.trace_id == "trace-breaker"
  end

  test "timeout workflow execution emits runtime latency and reliability telemetry" do
    {:ok, run} = Workflows.create_run(%{root_role_id: "executor"})

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "slow",
        role_id: "executor",
        status: "queued"
      })

    assert {:ok, failed_step} =
             Runtime.execute_step(step.id,
               handler: {Handlers, :sleep},
               timeout: 10,
               budget_context: %{tenant_id: "tenant-runtime", trace_id: "trace-timeout"}
             )

    assert failed_step.error_envelope["reason"] == "timeout"

    assert_receive {:telemetry_event, [:scoria, :sre, :runtime, :latency], measurements, metadata}
    assert is_integer(measurements.duration_ms)
    assert metadata.reason_code == "timeout"
    assert metadata.trace_id == "trace-timeout"

    assert_receive {:telemetry_event, [:scoria, :sre, :runtime, :tool_reliability], measurements, _metadata}
    assert measurements.success_count == 0
    assert measurements.failure_count == 1
  end

  test "workflow telemetry falls back to the run runtime snapshot when the caller does not restate it" do
    {:ok, run} =
      Workflows.create_run(%{
        root_role_id: "executor",
        actor_id: "runtime-actor",
        tenant_id: "tenant-runtime",
        session_id: "runtime-session",
        metadata: %{
          "runtime" => %{
            "provider" => "openai",
            "model" => "gpt-5",
            "policy_key" => "workflow:policy"
          }
        }
      })

    {:ok, step} =
      Workflows.create_step(run.id, %{
        sequence: 1,
        kind: "success",
        role_id: "executor",
        status: "queued"
      })

    assert {:ok, _completed_step} =
             Runtime.execute_step(step.id,
               handler: {Handlers, :succeed},
               budget_context: %{trace_id: "trace-runtime-fallback"}
             )

    assert_receive {:telemetry_event, [:scoria, :sre, :runtime, :latency], _measurements, metadata}
    assert metadata.provider == "openai"
    assert metadata.model == "gpt-5"
    assert metadata.policy_key == "workflow:policy"
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
