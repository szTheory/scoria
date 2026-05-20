defmodule Scoria.Observe.CircuitBreaker.ManagerTest do
  use ExUnit.Case, async: false

  alias Scoria.Observe.CircuitBreaker
  alias Scoria.Observe.CircuitBreaker.Manager

  setup do
    if :ets.whereis(:scoria_circuit_breakers) != :undefined do
      :ets.delete(:scoria_circuit_breakers)
    end
    
    # Set a fast sweep interval for testing
    Application.put_env(:scoria, :circuit_breaker_opts, sweep_interval: 10)
    
    on_exit(fn ->
      Application.delete_env(:scoria, :circuit_breaker_opts)
    end)
    
    :ok
  end

  test "GenServer starts and initializes ETS table" do
    assert :ets.whereis(:scoria_circuit_breakers) == :undefined
    
    {:ok, pid} = start_supervised(Manager)
    assert is_pid(pid)
    
    assert :ets.whereis(:scoria_circuit_breakers) != :undefined
  end

  test "Manager sweeps half-open circuits periodically" do
    # Start without the manager first to setup data
    CircuitBreaker.init_table()
    
    now = System.system_time(:millisecond)
    expired_time = now - 35_000
    :ets.insert(:scoria_circuit_breakers, {"expired_model", :open, 5, expired_time})
    
    # Now start manager
    {:ok, _pid} = start_supervised(Manager)
    
    # Wait for the sweep interval (10ms)
    Process.sleep(50)
    
    # The record should now be :half_open
    [{_, status, _, _}] = :ets.lookup(:scoria_circuit_breakers, "expired_model")
    assert status == :half_open
  end
end
