defmodule Scoria.Observe.BufferTest do
  use ExUnit.Case, async: false
  
  alias Scoria.Observe.Buffer
  alias Scoria.Repo.Span
  alias Scoria.Repo.Trace
  alias Scoria.Repo

  setup do
    # Shared mode so the GenServer process can access the checked out sandbox connection
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    
    {:ok, trace} = Repo.insert(%Trace{id: Ecto.UUID.generate()})
    
    # Start the buffer with a short flush interval for testing
    pid = start_supervised!({Buffer, [name: :test_buffer, flush_interval: 10, max_size: 5]})
    
    %{trace: trace, buffer_pid: pid}
  end

  test "buffers incoming spans via cast/1 and flushes periodically", %{trace: trace} do
    Buffer.cast_span(%{name: "test_span_1", start_time: DateTime.utc_now(), trace_id: trace.id}, :test_buffer)
    Buffer.cast_span(%{name: "test_span_2", start_time: DateTime.utc_now(), trace_id: trace.id}, :test_buffer)

    # Initially not inserted
    assert Repo.aggregate(Span, :count) == 0

    # Wait for flush_interval to pass
    Process.sleep(50)

    # Should be inserted
    assert Repo.aggregate(Span, :count) == 2
  end

  test "drops spans if max_size is exceeded", %{trace: trace} do
    for i <- 1..10 do
      Buffer.cast_span(%{name: "test_span_#{i}", start_time: DateTime.utc_now(), trace_id: trace.id}, :test_buffer)
    end

    # Max size is 5, so only 5 should be buffered and flushed
    Process.sleep(50)

    assert Repo.aggregate(Span, :count) == 5
  end

  test "flushes spans on graceful shutdown", %{trace: trace, buffer_pid: pid} do
    Buffer.cast_span(%{name: "test_span_shutdown", start_time: DateTime.utc_now(), trace_id: trace.id}, :test_buffer)
    
    # Stop the buffer gracefully
    GenServer.stop(pid)
    
    # Assert it was flushed
    assert Repo.aggregate(Span, :count) == 1
  end
end