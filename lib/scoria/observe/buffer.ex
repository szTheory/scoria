defmodule Scoria.Observe.Buffer do
  use GenServer
  require Logger

  @default_max_size 1000
  @default_flush_interval 5000

  # API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  def cast_span(span_data, name \\ __MODULE__) do
    GenServer.cast(name, {:cast_span, span_data})
  end

  def cast_event(event_data, name \\ __MODULE__) do
    GenServer.cast(name, {:cast_event, event_data})
  end

  @doc """
  Synchronously flushes the buffer's current spans and replies once the
  flush attempt (success or non-fatal failure) has completed. Test hook --
  avoids racing the periodic flush timer (D-08).
  """
  def flush_now(name \\ __MODULE__) do
    GenServer.call(name, :flush_now)
  end

  # Callbacks

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)

    state = %{
      spans: [],
      max_size: Keyword.get(opts, :max_size, @default_max_size),
      flush_interval: Keyword.get(opts, :flush_interval, @default_flush_interval),
      name: Keyword.get(opts, :name, __MODULE__),
      on_flush_error: Keyword.get(opts, :on_flush_error, :log),
      consecutive_failures: 0,
      events: [],
      max_event_size: Keyword.get(opts, :max_event_size, @default_max_size),
      event_consecutive_failures: 0,
      timer: nil
    }

    state = schedule_flush(state)
    {:ok, state}
  end

  @impl true
  def handle_cast({:cast_span, span_data}, state) do
    if length(state.spans) >= state.max_size do
      Logger.warning("Scoria.Observe.Buffer is full (#{state.max_size}), dropping span.")
      {:noreply, state}
    else
      {:noreply, %{state | spans: [span_data | state.spans]}}
    end
  end

  @impl true
  def handle_cast({:cast_event, event_data}, state) do
    if length(state.events) >= state.max_event_size do
      Logger.warning("Scoria.Observe.Buffer is full (#{state.max_event_size}), dropping event.")
      {:noreply, state}
    else
      {:noreply, %{state | events: [event_data | state.events]}}
    end
  end

  @impl true
  def handle_call(:flush_now, _from, state) do
    state = do_flush(state, from_timer?: false)
    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:flush, state) do
    state = do_flush(state, from_timer?: true)
    state = schedule_flush(state)
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    # Never honor :on_flush_error == :raise from terminate/2 (D-09 i) --
    # a raise during shutdown is noisy/pointless and dangerous under
    # Process.flag(:trap_exit, true).
    do_flush(state, from_timer?: false)
    :ok
  end

  defp schedule_flush(state) do
    if state.timer, do: Process.cancel_timer(state.timer)
    timer = Process.send_after(self(), :flush, state.flush_interval)
    %{state | timer: timer}
  end

  defp do_flush(state, timer_opts) do
    new_consecutive_failures =
      flush_spans(state.spans, %{
        name: state.name,
        max_size: state.max_size,
        on_flush_error: state.on_flush_error,
        consecutive_failures: state.consecutive_failures,
        from_timer?: Keyword.get(timer_opts, :from_timer?, false)
      })

    %{state | spans: [], consecutive_failures: new_consecutive_failures}
  end

  # Rewritten per RESEARCH Pattern 1: upsert the parent trace row(s) for this
  # batch before inserting spans, inside one Ecto.Multi, so a span never fails
  # its FK insert because nothing created the trace first (FOUND-01).
  defp flush_spans([], opts), do: opts[:consecutive_failures] || 0

  defp flush_spans(spans, opts) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    span_entries =
      Enum.map(spans, fn span ->
        span
        |> Map.put_new_lazy(:id, fn -> Ecto.UUID.generate() end)
        |> Map.put_new(:inserted_at, now)
        |> Map.put_new(:updated_at, now)
      end)

    trace_entries =
      span_entries
      |> Enum.map(& &1.trace_id)
      |> Enum.uniq()
      |> Enum.map(&%{id: &1, inserted_at: now, updated_at: now})

    # Attempted count, not post-reset state.spans (D-09 iii).
    dropped_count = length(span_entries)

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert_all(:traces, Scoria.Repo.Trace, trace_entries,
        on_conflict: :nothing,
        conflict_target: [:id]
      )
      |> Ecto.Multi.insert_all(:spans, Scoria.Repo.Span, span_entries)

    try do
      case Scoria.Repo.transaction(multi) do
        {:ok, _changes} ->
          0

        {:error, failed_op, failed_value, _changes_so_far} ->
          new_count =
            surface_flush_error(
              failed_value,
              dropped_count,
              opts,
              nil,
              "op=#{inspect(failed_op)}: #{inspect(failed_value)}"
            )

          if opts[:on_flush_error] == :raise and opts[:from_timer?] do
            raise "Scoria.Observe.Buffer flush failed (op=#{inspect(failed_op)}): " <>
                    inspect(failed_value)
          end

          new_count
      end
    rescue
      # insert_all bypasses changesets and raises a raw Postgrex/Ecto
      # exception on a real constraint violation instead of returning
      # {:error, ...} -- must be caught here too (Pitfall 3), or an
      # uncaught exception crashes the Buffer GenServer, which D-05
      # explicitly forbids.
      e ->
        new_count =
          surface_flush_error(e, dropped_count, opts, __STACKTRACE__, Exception.message(e))

        if opts[:on_flush_error] == :raise and opts[:from_timer?] do
          reraise e, __STACKTRACE__
        end

        new_count
    end
  end

  # Logs full detail once per consecutive-failure run (storm control, D-09 ii)
  # but ALWAYS emits telemetry so alerting math stays accurate. Returns the
  # new consecutive-failure count.
  defp surface_flush_error(error, dropped_count, opts, stacktrace, log_detail) do
    new_consecutive_failures = (opts[:consecutive_failures] || 0) + 1

    if new_consecutive_failures == 1 do
      Logger.error(
        "Scoria.Observe.Buffer failed to flush #{dropped_count} span(s) " <>
          "for buffer #{inspect(opts[:name])}: #{log_detail}"
      )
    end

    safe_emit_flush_error(%{
      dropped_count: dropped_count,
      buffer: opts[:name],
      max_size: opts[:max_size],
      kind: :error,
      error: error,
      stacktrace: stacktrace
    })

    new_consecutive_failures
  end

  # Defensively wrapped so a bad/re-entrant host telemetry handler can't
  # crash or re-enter the flush path (D-09 iv).
  defp safe_emit_flush_error(metadata) do
    Scoria.Observe.Telemetry.emit_flush_error(metadata)
  rescue
    _ -> :ok
  end
end
