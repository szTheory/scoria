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
  alias Scoria.Runtime.{Instance, Params, ReplayComparison, RunDetail, RunSummary}
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
    run = Workflows.get_run_tree!(run_id)
    source_run = load_source_run(run)

    RunDetail.from_run_tree(run,
      comparison_by_step: ReplayComparison.build(run, source_run),
      replay_provenance_strip: ReplayComparison.provenance_strip(run)
    )
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

  @doc """
  Registers or updates a durable runtime instance presence.
  """
  def register_instance(attrs) when is_map(attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    
    attrs_string = for {k, v} <- attrs, into: %{}, do: {to_string(k), v}
    
    instance = 
      cond do
        id = attrs_string["id"] -> Repo.get(Instance, id) || %Instance{}
        host_session_id = attrs_string["host_session_id"] -> 
          Repo.get_by(Instance, host_session_id: host_session_id) || %Instance{}
        true -> %Instance{}
      end
      
    # Only set first_seen_at if it's a new instance (or hasn't been set)
    attrs_string = 
      if instance.first_seen_at do
        attrs_string
      else
        Map.put_new(attrs_string, "first_seen_at", now)
      end
      |> Map.put("last_seen_at", now)
      |> Map.put("terminal_offline_reason", nil)
      
    instance
    |> Instance.changeset(attrs_string)
    |> Repo.insert_or_update()
  end

  @doc """
  Marks a runtime instance as offline with a reason.
  """
  def mark_offline(instance_id, reason) when is_binary(instance_id) and is_binary(reason) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    
    case Repo.get(Instance, instance_id) do
      nil -> {:error, :not_found}
      instance ->
        instance
        |> Instance.changeset(%{
          "last_seen_at" => now, 
          "terminal_offline_reason" => reason
        })
        |> Repo.update()
    end
  end

  @doc """
  Lists compacted memories for a given run, ordered by sequence.
  """
  def list_compacted_memories_for_run(run_id) do
    Scoria.Runtime.CompactedMemory
    |> where([m], m.run_id == ^run_id)
    |> order_by([m], asc: m.start_sequence)
    |> Repo.all()
  end

  defp maybe_dispatch(_run_id, dispatch_opts) when dispatch_opts == [] or dispatch_opts == %{},
    do: {:ok, 0}

  defp maybe_dispatch(run_id, dispatch_opts), do: Reconciler.dispatch_run(run_id, dispatch_opts)

  defp load_source_run(%Run{execution_mode: "replay", source_run_id: source_run_id})
       when is_binary(source_run_id) do
    Workflows.get_run_tree!(source_run_id)
  rescue
    NoResultsError -> nil
  end

  defp load_source_run(_run), do: nil
end
