defmodule Scoria.Workflows.BatchEnqueue do
  @moduledoc """
  Provides bulk chunking and enqueueing of Oban jobs into target queues.
  """

  @default_chunk_size 500

  @doc """
  Enqueues a list of Oban jobs in chunks using Ecto.Multi.

  ## Options
    * `:chunk_size` - The number of jobs per chunk (defaults to 500).

  ## Returns
    `{:ok, results}` on success or `{:error, failed_operation, failed_value, changes_so_far}`.
  """
  def enqueue_all(jobs, opts \\ []) do
    chunk_size = Keyword.get(opts, :chunk_size, @default_chunk_size)

    jobs
    |> Enum.chunk_every(chunk_size)
    |> Enum.with_index()
    |> Enum.reduce(Ecto.Multi.new(), fn {chunk, idx}, multi ->
      Oban.insert_all(multi, :"batch_#{idx}", chunk)
    end)
    |> Scoria.Repo.transaction()
  end
end
