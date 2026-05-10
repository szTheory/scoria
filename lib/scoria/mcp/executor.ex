defmodule Scoria.MCP.Executor do
  @moduledoc """
  Executes MCP tools in an isolated Task with strict timeouts.
  Emits telemetry events for auditing.
  """

  @doc """
  Executes a tool module with the given arguments and context.
  """
  def execute(tool_module, args, context, timeout \\ 5000) do
    context = context || %{}
    metadata = Map.merge(context, %{tool: tool_module, args: args})

    :telemetry.execute([:scoria, :tool, :started], %{system_time: System.system_time()}, metadata)

    start_time = System.monotonic_time()

    task = Task.Supervisor.async_nolink(Scoria.MCP.TaskSupervisor, fn ->
      tool_module.execute(args, context)
    end)

    case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} ->
        duration = System.monotonic_time() - start_time
        :telemetry.execute([:scoria, :tool, :completed], %{duration: duration}, metadata)
        result

      nil ->
        duration = System.monotonic_time() - start_time
        :telemetry.execute([:scoria, :tool, :timeout], %{duration: duration}, metadata)
        {:error, :timeout}

      {:exit, reason} ->
        duration = System.monotonic_time() - start_time
        :telemetry.execute([:scoria, :tool, :failed], %{duration: duration}, Map.put(metadata, :reason, reason))
        {:error, :execution_failed}
    end
  end
end
