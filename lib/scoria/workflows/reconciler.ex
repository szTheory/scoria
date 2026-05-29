defmodule Scoria.Workflows.Reconciler do
  @moduledoc """
  Startup and transition boundary that finds runnable steps and dispatches them safely.
  """

  use GenServer

  alias Scoria.Workflows
  alias Scoria.Workflows.Runtime

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def dispatch_runnable_steps(opts \\ []) do
    GenServer.call(__MODULE__, {:dispatch, opts})
  end

  def dispatch_run(run_id, opts \\ []) do
    GenServer.call(__MODULE__, {:dispatch_run, run_id, opts})
  end

  @impl true
  def init(opts) do
    send(self(), {:reconcile, opts})
    {:ok, opts}
  end

  @impl true
  def handle_call({:dispatch, opts}, _from, state) do
    {:reply, do_dispatch(Workflows.list_runnable_steps(), opts), state}
  end

  def handle_call({:dispatch_run, run_id, opts}, _from, state) do
    steps =
      Workflows.list_runnable_steps()
      |> Enum.filter(&(&1.run_id == run_id))

    {:reply, do_dispatch(steps, opts), state}
  end

  @impl true
  def handle_info({:reconcile, opts}, state) do
    do_dispatch(Workflows.list_runnable_steps(), opts)
    {:noreply, state}
  end

  defp do_dispatch(steps, opts) do
    case Application.get_env(:scoria, :workflow_dispatch, :async) do
      :inline ->
        Enum.each(steps, fn step -> Runtime.execute_step(step.id, opts) end)
        {:ok, length(steps)}

      :async ->
        Enum.each(steps, fn step ->
          Task.Supervisor.start_child(Scoria.Workflow.TaskSupervisor, fn ->
            Runtime.execute_step(step.id, opts)
          end)
        end)

        {:ok, length(steps)}
    end
  end
end
