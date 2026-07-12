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

  # SC#1 primary proof: a span persists with a matching auto-upserted
  # ai_traces row, WITHOUT this test hand-inserting the trace first.
  test "auto-upserts the parent trace row before inserting the span (no hand-inserted trace)" do
    pid =
      start_supervised!(
        Supervisor.child_spec({Buffer, [name: :test_buffer_autoupsert, flush_interval: 10_000, max_size: 5]},
          id: :test_buffer_autoupsert
        )
      )

    trace_id = Ecto.UUID.generate()

    Buffer.cast_span(
      %{name: "auto_upsert_span", start_time: DateTime.utc_now(), trace_id: trace_id},
      :test_buffer_autoupsert
    )

    # Synchronous flush -- no Process.sleep, no race with the timer (D-08).
    :ok = GenServer.call(pid, :flush_now)

    assert %Trace{} = Repo.get(Trace, trace_id)

    span = Repo.get_by(Span, name: "auto_upsert_span")
    assert span
    assert span.trace_id == trace_id
  end

  # D-08 (a): loud, non-fatal surfacing on a real Postgrex constraint failure.
  test "flush_error telemetry fires on a real constraint failure and the buffer survives" do
    handler_id = "buffer-flush-error-test-#{System.unique_integer([:positive])}"
    test_pid = self()

    :telemetry.attach(
      handler_id,
      [:scoria, :observe, :buffer, :flush_error],
      fn _event, measurements, metadata, _config ->
        # The handler runs synchronously in the caller's process (the
        # Buffer GenServer), so self() here would be the Buffer, not this
        # test process -- send to the captured test_pid instead.
        send(test_pid, {:flush_error, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    pid =
      start_supervised!(
        Supervisor.child_spec({Buffer, [name: :test_buffer_flush_error, flush_interval: 10_000, max_size: 5]},
          id: :test_buffer_flush_error
        )
      )

    # Missing required :name -- ai_spans.name is NOT NULL, so insert_all
    # raises a real Postgrex error (Pitfall 3), not a changeset {:error, ...}.
    Buffer.cast_span(
      %{start_time: DateTime.utc_now(), trace_id: Ecto.UUID.generate()},
      :test_buffer_flush_error
    )

    :ok = GenServer.call(pid, :flush_now)

    assert_receive {:flush_error, measurements, _metadata}, 1000
    assert measurements.dropped_count > 0

    assert Process.alive?(pid)
  end

  # D-08 (b) / D-09 (i): :on_flush_error :raise raises ONLY from the timer
  # path; terminate/2 never reraises, even in :raise mode.
  test ":on_flush_error :raise crashes the buffer on the timer path" do
    pid =
      start_supervised!(
        Supervisor.child_spec(
          {Buffer, [name: :test_buffer_raise, flush_interval: 10, max_size: 5, on_flush_error: :raise]},
          id: :test_buffer_raise
        )
      )

    ref = Process.monitor(pid)

    # Missing required :name -- induces a real constraint failure on the
    # periodic timer flush.
    Buffer.cast_span(
      %{start_time: DateTime.utc_now(), trace_id: Ecto.UUID.generate()},
      :test_buffer_raise
    )

    assert_receive {:DOWN, ^ref, :process, ^pid, _reason}, 1000
  end

  test ":on_flush_error :raise never reraises from terminate/2 (graceful shutdown)" do
    pid =
      start_supervised!(
        Supervisor.child_spec(
          {Buffer,
           [name: :test_buffer_terminate_raise, flush_interval: 10_000, max_size: 5, on_flush_error: :raise]},
          id: :test_buffer_terminate_raise
        )
      )

    # Missing required :name -- would fail to persist on flush, but this
    # buffer only ever flushes via terminate/2 below (10s timer never fires).
    Buffer.cast_span(
      %{start_time: DateTime.utc_now(), trace_id: Ecto.UUID.generate()},
      :test_buffer_terminate_raise
    )

    assert :ok = GenServer.stop(pid)
  end

  # D-08: :flush_now is synchronous -- no Process.sleep needed, the row is
  # present as soon as the call returns.
  test "flush_now flushes synchronously with no race against the timer" do
    pid =
      start_supervised!(
        Supervisor.child_spec({Buffer, [name: :test_buffer_flush_now, flush_interval: 10_000, max_size: 5]},
          id: :test_buffer_flush_now
        )
      )

    trace_id = Ecto.UUID.generate()

    Buffer.cast_span(
      %{name: "flush_now_span", start_time: DateTime.utc_now(), trace_id: trace_id},
      :test_buffer_flush_now
    )

    :ok = GenServer.call(pid, :flush_now)

    assert Repo.get_by(Span, name: "flush_now_span")
  end
end