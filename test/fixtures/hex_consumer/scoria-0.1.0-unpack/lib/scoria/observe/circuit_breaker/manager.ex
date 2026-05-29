defmodule Scoria.Observe.CircuitBreaker.Manager do
  use GenServer
  require Logger

  alias Scoria.Observe.CircuitBreaker

  @default_sweep_interval 5000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @impl true
  def init(_opts) do
    CircuitBreaker.init_table()
    state = schedule_sweep(%{timer: nil})
    {:ok, state}
  end

  @impl true
  def handle_info(:sweep, state) do
    CircuitBreaker.sweep_half_open()
    state = schedule_sweep(state)
    {:noreply, state}
  end

  defp schedule_sweep(state) do
    if state.timer, do: Process.cancel_timer(state.timer)
    
    opts = Application.get_env(:scoria, :circuit_breaker_opts, [])
    interval = Keyword.get(opts, :sweep_interval, @default_sweep_interval)
    
    timer = Process.send_after(self(), :sweep, interval)
    %{state | timer: timer}
  end
end
