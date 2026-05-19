defmodule Scoria.Runtime do
  @moduledoc """
  Advanced runtime lifecycle and inspection APIs behind the `Scoria` facade.

  Most host apps should call `Scoria` directly. This module exists for the
  deeper lifecycle layer once you already have canonical identity and want the
  underlying start, resume, and inspection primitives spelled out explicitly.

  The same identity contract still applies here: `session_id` groups continuity
  across related turns, while `run_id` identifies one exact durable run for
  inspection or resume.
  """

  import Ecto.Query, warn: false

  alias Ecto.NoResultsError
  alias Scoria.Repo
  alias Scoria.Runtime.{Params, RunDetail, RunSummary}
  alias Scoria.Workflows
  alias Scoria.Workflows.{Reconciler, Resume, Run}

  @doc """
  Starts a new run from canonical identity plus explicit runtime options.
  """
  def start_run(identity, opts \\ []) do
    with {:ok, %{workflow_attrs: workflow_attrs, dispatch_opts: dispatch_opts}} <-
           Params.start(identity, opts),
         :ok <- Scoria.Runtime.ReleaseGate.check(workflow_attrs),
         {:ok, run} <- Workflows.create_run(workflow_attrs),
         {:ok, _count} <- maybe_dispatch(run.id, dispatch_opts) do
      {:ok, get_run!(run.id)}
    end
  end

  @doc """
  Resumes an existing run by exact durable `run_id`.
  """
  def resume_run(run_id, opts \\ []) do
    with {:ok, dispatch_opts} <- Params.resume(run_id, opts),
         {:ok, run} <- Resume.resume_run(run_id, dispatch_opts) do
      {:ok, RunSummary.from_run(run)}
    end
  end

  @doc """
  Returns the stable public summary for a run.
  """
  def get_run(run_id) do
    {:ok, get_run!(run_id)}
  rescue
    NoResultsError -> {:error, :not_found}
  end

  @doc """
  Returns the stable public summary for a run or raises.
  """
  def get_run!(run_id) do
    run_id
    |> Workflows.get_run!()
    |> RunSummary.from_run()
  end

  @doc """
  Returns the curated detailed public view for a run.
  """
  def get_run_detail(run_id) do
    {:ok, get_run_detail!(run_id)}
  rescue
    NoResultsError -> {:error, :not_found}
  end

  @doc """
  Returns the curated detailed public view for a run or raises.
  """
  def get_run_detail!(run_id) do
    run_id
    |> Workflows.get_run_tree!()
    |> RunDetail.from_run_tree()
  end

  @doc """
  Lists runs that share the same host-owned `session_id`.
  """
  def list_runs_for_session(session_id) do
    Run
    |> where([run], run.session_id == ^session_id)
    |> order_by([run], desc: run.inserted_at, desc: run.id)
    |> Repo.all()
    |> Enum.map(&RunSummary.from_run/1)
  end

  defp maybe_dispatch(_run_id, dispatch_opts) when dispatch_opts == [] or dispatch_opts == %{},
    do: {:ok, 0}

  defp maybe_dispatch(run_id, dispatch_opts), do: Reconciler.dispatch_run(run_id, dispatch_opts)
end
