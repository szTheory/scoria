defmodule Scoria.Workflows.BatchEnqueueTest do
  use ExUnit.Case, async: true
  use Oban.Testing, repo: Scoria.Repo

  alias Scoria.Workflows.BatchEnqueue

  # Let's define some dummy workers for testing
  defmodule EvalsWorker do
    use Oban.Worker, queue: :evals
    @impl Oban.Worker
    def perform(_job), do: :ok
  end

  defmodule SystemWorker do
    use Oban.Worker, queue: :system
    @impl Oban.Worker
    def perform(_job), do: :ok
  end

  # Ecto DataCase for setting up DB transaction sandbox
  setup do
    # Assuming Scoria.Repo provides standard sandbox
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})
    :ok
  end

  test "enqueues jobs in chunks to correct queues" do
    jobs = [
      EvalsWorker.new(%{id: 1}),
      SystemWorker.new(%{id: 2}),
      EvalsWorker.new(%{id: 3}),
      SystemWorker.new(%{id: 4}),
      EvalsWorker.new(%{id: 5})
    ]

    # Test chunk size smaller than list length to ensure chunking works
    assert {:ok, results} = BatchEnqueue.enqueue_all(jobs, chunk_size: 2)

    # 5 jobs / 2 = 3 batches
    assert map_size(results) == 3

    assert_enqueued worker: EvalsWorker, args: %{id: 1}, queue: :evals
    assert_enqueued worker: SystemWorker, args: %{id: 2}, queue: :system
    assert_enqueued worker: EvalsWorker, args: %{id: 3}, queue: :evals
    assert_enqueued worker: SystemWorker, args: %{id: 4}, queue: :system
    assert_enqueued worker: EvalsWorker, args: %{id: 5}, queue: :evals
  end
end
