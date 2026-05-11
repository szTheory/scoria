defmodule Scoria.MCP.Executor do
  @moduledoc """
  Executes MCP tools in an isolated Task with strict timeouts.
  Emits telemetry events for auditing.
  """

  alias Scoria.SRE.BudgetEngine

  @doc """
  Executes a tool module with the given arguments and context.
  """
  def execute(tool_module, args, context, timeout \\ 5000) do
    context = context || %{}

    case reserve_budget(tool_module, args, context) do
      {:error, envelope} ->
        {:error, envelope}

      {:ok, reservation_context} ->
        metadata =
          context
          |> Map.merge(%{tool: tool_module, args: args})
          |> attach_budget_metadata(reservation_context)

        :telemetry.execute([:scoria, :tool, :started], %{system_time: System.system_time()}, metadata)

        start_time = System.monotonic_time()

        task = Task.Supervisor.async_nolink(Scoria.MCP.TaskSupervisor, fn ->
          tool_module.execute(args, context)
        end)

        case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
          {:ok, result} ->
            reconcile_budget(reservation_context, context, result, "completed")
            duration = System.monotonic_time() - start_time
            :telemetry.execute([:scoria, :tool, :completed], %{duration: duration}, metadata)
            result

          nil ->
            reconcile_budget(reservation_context, context, %{}, "timeout")
            duration = System.monotonic_time() - start_time
            :telemetry.execute([:scoria, :tool, :timeout], %{duration: duration}, metadata)
            {:error, :timeout}

          {:exit, reason} ->
            reconcile_budget(reservation_context, context, %{}, "execution_failed")
            duration = System.monotonic_time() - start_time
            :telemetry.execute([:scoria, :tool, :failed], %{duration: duration}, Map.put(metadata, :reason, reason))
            {:error, :execution_failed}
        end
    end
  end

  defp reserve_budget(tool_module, args, context) do
    if budget_required?(context) do
      BudgetEngine.reserve_step(%{
        tenant_id: Map.get(context, :tenant_id),
        actor_id: Map.get(context, :actor_id),
        run_id: Map.get(context, :run_id),
        step_id: Map.get(context, :step_id),
        trace_id: Map.get(context, :trace_id),
        resource: budget_resource(context),
        reason_code: Map.get(context, :reason_code, "mcp.execute"),
        estimated_units: estimated_units(context),
        integration_kind: Map.get(context, :integration_kind, "tool"),
        tool_ref: inspect(tool_module),
        metadata:
          context
          |> Map.get(:metadata, %{})
          |> Map.put_new("tool_hash", Integer.to_string(:erlang.phash2({tool_module, args})))
      })
    else
      {:ok, nil}
    end
  end

  defp reconcile_budget(nil, _context, _result, _outcome), do: :ok

  defp reconcile_budget(%{reservation: reservation}, context, result, outcome) do
    BudgetEngine.reconcile_usage(reservation, %{
      actual_units: actual_units(context, result, outcome),
      metadata: %{"outcome" => outcome}
    })
  end

  defp attach_budget_metadata(metadata, nil), do: metadata
  defp attach_budget_metadata(metadata, %{reservation: reservation}), do: Map.put(metadata, :budget_reservation_id, reservation.id)

  defp budget_required?(context) do
    Map.get(context, :estimated_cost_usd) ||
      Map.get(context, :estimated_tokens) ||
      Map.get(context, :estimated_units) ||
      Map.get(context, :sensitive_tool)
  end

  defp budget_resource(context) do
    cond do
      Map.get(context, :resource) -> Map.get(context, :resource)
      Map.get(context, :estimated_cost_usd) -> "cost_usd"
      Map.get(context, :estimated_tokens) -> "token_in"
      true -> "tool_calls"
    end
  end

  defp estimated_units(context) do
    cond do
      Map.get(context, :estimated_units) -> Map.get(context, :estimated_units)
      Map.get(context, :estimated_cost_usd) -> Map.get(context, :estimated_cost_usd)
      Map.get(context, :estimated_tokens) -> Map.get(context, :estimated_tokens)
      true -> 1
    end
  end

  defp actual_units(_context, _result, outcome) when outcome in ["timeout", "execution_failed"], do: 0

  defp actual_units(context, result, _outcome) do
    cond do
      is_map(result) && Map.has_key?(result, :actual_units) -> Map.fetch!(result, :actual_units)
      is_map(result) && Map.has_key?(result, "actual_units") -> Map.fetch!(result, "actual_units")
      is_map(result) && Map.has_key?(result, :actual_cost_usd) -> Map.fetch!(result, :actual_cost_usd)
      is_map(result) && Map.has_key?(result, "actual_cost_usd") -> Map.fetch!(result, "actual_cost_usd")
      true -> estimated_units(context)
    end
  end
end
