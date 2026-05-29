defmodule Scoria.IntegrationCase do
  @moduledoc """
  Shared setup for integration and e2e specs that need Sandbox, Reconciler, and async workers.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use ExUnit.Case, async: false

      import Scoria.TestSupport.Eventually, only: [eventually: 1, eventually: 2]
    end
  end

  setup _tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    allow_async_workers!()
    start_supervised!(Scoria.Workflows.Reconciler)
    :ok
  end

  @doc """
  Grants workflow and MCP Task.Supervisor children access to the Sandbox connection.
  """
  def allow_async_workers! do
    parent = self()

    for supervisor <- [Scoria.Workflow.TaskSupervisor, Scoria.MCP.TaskSupervisor] do
      if pid = Process.whereis(supervisor) do
        Ecto.Adapters.SQL.Sandbox.allow(Scoria.Repo, parent, pid)
      end
    end

    :ok
  end
end
