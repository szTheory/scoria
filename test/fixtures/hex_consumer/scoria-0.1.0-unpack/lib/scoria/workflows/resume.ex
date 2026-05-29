defmodule Scoria.Workflows.Resume do
  @moduledoc """
  Thin recovery entrypoints that reconstruct the next action from durable workflow state.
  """

  alias Scoria.Workflows
  alias Scoria.Workflows.Reconciler

  def resume_run(run_id, opts \\ []) do
    with {:ok, _step} <- Workflows.resume_run(run_id),
         {:ok, _count} <- Reconciler.dispatch_run(run_id, opts) do
      {:ok, Workflows.get_run!(run_id)}
    end
  end

  def retry_failed_step(run_id, opts \\ []) do
    run = Workflows.get_run!(run_id)

    with step_id when not is_nil(step_id) <- run.current_step_id,
         {:ok, _step} <- Workflows.retry_step(step_id),
         {:ok, _count} <- Reconciler.dispatch_run(run_id, opts) do
      {:ok, Workflows.get_run!(run_id)}
    else
      nil -> {:error, :no_failed_step}
      error -> error
    end
  end
end
