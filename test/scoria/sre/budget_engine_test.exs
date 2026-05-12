defmodule Scoria.SRE.BudgetEngineTest do
  use ExUnit.Case, async: false

  alias Decimal, as: D
  alias Scoria.Repo
  alias Scoria.SRE
  alias Scoria.SRE.BudgetEngine

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    :ok
  end

  describe "reserve_step/1" do
    test "warns at the policy warn threshold and trips at the policy trip threshold" do
      {:ok, policy} =
        SRE.create_budget_policy(%{
          tenant_id: "tenant-budget",
          policy_key: "tenant:default:cost_usd",
          scope_key: "tenant:tenant-budget",
          scope_kind: "tenant",
          resource_kind: "cost_usd",
          status: "active",
          warn_threshold: D.new("80.0"),
          trip_threshold: D.new("100.0"),
          max_workflow_steps: 25,
          max_repeated_tool_calls: 3,
          max_consecutive_failures: 2,
          metadata: %{}
        })

      assert {:ok, %{reservation: reservation, warnings: []}} =
               BudgetEngine.reserve_step(%{
                 tenant_id: policy.tenant_id,
                 actor_id: "actor-1",
                 run_id: Ecto.UUID.generate(),
                 step_id: Ecto.UUID.generate(),
                 trace_id: "trace-1",
                 resource: "cost_usd",
                 reason_code: "llm_completion",
                 estimated_units: D.new("50.0"),
                 integration_kind: "provider"
               })

      assert reservation.status == "reserved"

      assert {:ok, %{warnings: warnings}} =
               BudgetEngine.reserve_step(%{
                 tenant_id: policy.tenant_id,
                 actor_id: "actor-1",
                 run_id: Ecto.UUID.generate(),
                 step_id: Ecto.UUID.generate(),
                 trace_id: "trace-2",
                 resource: "cost_usd",
                 reason_code: "llm_completion",
                 estimated_units: D.new("35.0"),
                 integration_kind: "provider"
               })

      assert Enum.any?(warnings, &(&1.guard == :warn_threshold))

      assert {:error, %{status: :budget_tripped, reason_code: "trip_threshold_exceeded"}} =
               BudgetEngine.reserve_step(%{
                 tenant_id: policy.tenant_id,
                 actor_id: "actor-1",
                 run_id: Ecto.UUID.generate(),
                 step_id: Ecto.UUID.generate(),
                 trace_id: "trace-3",
                 resource: "cost_usd",
                 reason_code: "llm_completion",
                 estimated_units: D.new("20.0"),
                 integration_kind: "provider"
               })
    end

    test "trips the repeated tool hash guard after the configured cap" do
      {:ok, policy} =
        SRE.create_budget_policy(%{
          tenant_id: "tenant-tool",
          policy_key: "tenant:default:tool_calls",
          scope_key: "tenant:tenant-tool",
          scope_kind: "tenant",
          resource_kind: "tool_calls",
          status: "active",
          warn_threshold: D.new("80.0"),
          trip_threshold: D.new("100.0"),
          max_workflow_steps: 25,
          max_repeated_tool_calls: 2,
          max_consecutive_failures: 2,
          metadata: %{}
        })

      run_id = Ecto.UUID.generate()
      attrs = %{
        tenant_id: policy.tenant_id,
        actor_id: "actor-1",
        run_id: run_id,
        step_id: Ecto.UUID.generate(),
        trace_id: "trace-tool",
        resource: "tool_calls",
        reason_code: "mcp.execute",
        estimated_units: 1,
        integration_kind: "tool",
        metadata: %{"tool_hash" => "hash:search"}
      }

      assert {:ok, _} = BudgetEngine.reserve_step(attrs)
      assert {:ok, _} = BudgetEngine.reserve_step(%{attrs | step_id: Ecto.UUID.generate()})

      assert {:error, %{status: :loop_guard_tripped, guard: :repeated_tool_hash}} =
               BudgetEngine.reserve_step(%{attrs | step_id: Ecto.UUID.generate()})
    end

    test "trips the consecutive failure guard when the cap is reached" do
      {:ok, policy} =
        SRE.create_budget_policy(%{
          tenant_id: "tenant-failure",
          policy_key: "tenant:default:workflow_steps",
          scope_key: "tenant:tenant-failure",
          scope_kind: "tenant",
          resource_kind: "workflow_steps",
          status: "active",
          warn_threshold: D.new("80.0"),
          trip_threshold: D.new("100.0"),
          max_workflow_steps: 25,
          max_repeated_tool_calls: 3,
          max_consecutive_failures: 2,
          metadata: %{}
        })

      assert {:error, %{status: :loop_guard_tripped, guard: :consecutive_failures}} =
               BudgetEngine.reserve_step(%{
                 tenant_id: policy.tenant_id,
                 actor_id: "actor-1",
                 run_id: Ecto.UUID.generate(),
                 step_id: Ecto.UUID.generate(),
                 trace_id: "trace-failure",
                 resource: "workflow_steps",
                 reason_code: "workflow_step",
                 estimated_units: 1,
                 integration_kind: "workflow",
                 metadata: %{"consecutive_failures" => 2}
               })
    end
  end

  describe "reconcile_usage/2" do
    test "reconciles actual usage onto the matching durable reservation" do
      {:ok, policy} =
        SRE.create_budget_policy(%{
          tenant_id: "tenant-reconcile",
          policy_key: "tenant:default:cost_usd",
          scope_key: "tenant:tenant-reconcile",
          scope_kind: "tenant",
          resource_kind: "cost_usd",
          status: "active",
          warn_threshold: D.new("80.0"),
          trip_threshold: D.new("100.0"),
          max_workflow_steps: 25,
          max_repeated_tool_calls: 3,
          max_consecutive_failures: 2,
          metadata: %{}
        })

      assert {:ok, %{reservation: reservation}} =
               BudgetEngine.reserve_step(%{
                 tenant_id: policy.tenant_id,
                 actor_id: "actor-1",
                 run_id: Ecto.UUID.generate(),
                 step_id: Ecto.UUID.generate(),
                 trace_id: "trace-reconcile",
                 resource: "cost_usd",
                 reason_code: "llm_completion",
                 estimated_units: D.new("12.5"),
                 integration_kind: "provider"
               })

      assert {:ok, updated} =
               BudgetEngine.reconcile_usage(reservation, %{
                 actual_units: D.new("10.0"),
                 metadata: %{"outcome" => "success"}
               })

      assert updated.status == "reconciled"
      assert updated.actual_units == D.new("10.0")
      assert updated.metadata["outcome"] == "success"
    end

    test "reconciles breaker-open reservations to zero actual usage" do
      {:ok, policy} =
        SRE.create_budget_policy(%{
          tenant_id: "tenant-breaker-open",
          policy_key: "tenant:default:cost_usd",
          scope_key: "tenant:tenant-breaker-open",
          scope_kind: "tenant",
          resource_kind: "cost_usd",
          status: "active",
          warn_threshold: D.new("80.0"),
          trip_threshold: D.new("100.0"),
          max_workflow_steps: 25,
          max_repeated_tool_calls: 3,
          max_consecutive_failures: 2,
          metadata: %{}
        })

      assert {:ok, %{reservation: reservation}} =
               BudgetEngine.reserve_step(%{
                 tenant_id: policy.tenant_id,
                 actor_id: "actor-1",
                 run_id: Ecto.UUID.generate(),
                 step_id: Ecto.UUID.generate(),
                 trace_id: "trace-breaker-open",
                 resource: "cost_usd",
                 reason_code: "llm_completion",
                 estimated_units: D.new("12.5"),
                 integration_kind: "provider"
               })

      assert {:ok, updated} =
               BudgetEngine.reconcile_breaker_open(reservation, %{
                 "breaker_key" => "provider:search"
               })

      assert updated.status == "reconciled"
      assert updated.actual_units == D.new("0")
      assert updated.metadata["outcome"] == "breaker_open"
      assert updated.metadata["breaker_key"] == "provider:search"
    end
  end
end
