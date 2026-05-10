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

  # Callbacks

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)

    state = %{
      spans: [],
      max_size: Keyword.get(opts, :max_size, @default_max_size),
      flush_interval: Keyword.get(opts, :flush_interval, @default_flush_interval),
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
  def handle_info(:flush, state) do
    flush_spans(state.spans)
    state = %{state | spans: []}
    state = schedule_flush(state)
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    flush_spans(state.spans)
  end

  defp schedule_flush(state) do
    if state.timer, do: Process.cancel_timer(state.timer)
    timer = Process.send_after(self(), :flush, state.flush_interval)
    %{state | timer: timer}
  end

  defp flush_spans([]), do: :ok
  defp flush_spans(spans) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    
    entries = Enum.map(spans, fn span ->
      span
      |> Map.put_new_lazy(:id, fn -> Ecto.UUID.generate() end)
      |> Map.put_new(:inserted_at, now)
      |> Map.put_new(:updated_at, now)
    end)
    
    try do
      Scoria.Repo.insert_all(Scoria.Repo.Span, entries)
    rescue
      e ->
        Logger.error("Failed to flush spans: #{inspect(e)}")
    end
  end
end