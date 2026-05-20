defmodule Scoria.Observe.CircuitBreakerTest do
  use ExUnit.Case, async: false
  
  alias Scoria.Observe.CircuitBreaker

  setup do
    if :ets.whereis(:scoria_circuit_breakers) != :undefined do
      :ets.delete(:scoria_circuit_breakers)
    end
    :ok
  end

  test "init_table/0 creates named public ETS table :scoria_circuit_breakers" do
    assert :ets.whereis(:scoria_circuit_breakers) == :undefined
    assert :ok = CircuitBreaker.init_table()
    assert :ets.whereis(:scoria_circuit_breakers) != :undefined
    
    info = :ets.info(:scoria_circuit_breakers)
    assert info[:named_table] == true
    assert info[:protection] == :public
    assert info[:type] == :set
    assert info[:read_concurrency] == true
  end

  test "open?/1 returns false for unknown or :closed models" do
    CircuitBreaker.init_table()
    assert CircuitBreaker.open?("unknown_model") == false
    
    :ets.insert(:scoria_circuit_breakers, {"closed_model", :closed, 0, 0})
    assert CircuitBreaker.open?("closed_model") == false
  end

  test "record_failure/2 increments failure count atomically, transitions to :open" do
    CircuitBreaker.init_table()
    model_id = "test_model_1"
    
    # 1st to 4th failure
    for _ <- 1..4 do
      assert :ok = CircuitBreaker.record_failure(model_id, threshold: 5)
      assert CircuitBreaker.open?(model_id) == false
    end
    
    # 5th failure trips it
    assert :ok = CircuitBreaker.record_failure(model_id, threshold: 5)
    assert CircuitBreaker.open?(model_id) == true
    
    [{^model_id, status, count, last_failure_at}] = :ets.lookup(:scoria_circuit_breakers, model_id)
    assert status == :open
    assert count == 5
    assert last_failure_at > 0
  end

  test "open?/1 returns true when status is :open and timeout has not expired" do
    CircuitBreaker.init_table()
    model_id = "test_model_2"
    now = System.system_time(:millisecond)
    
    # Set to open with a recent failure
    :ets.insert(:scoria_circuit_breakers, {model_id, :open, 5, now})
    # Should be open (default timeout 30_000ms)
    assert CircuitBreaker.open?(model_id) == true
    
    # Set to open with an old failure (past 30_000ms)
    old_time = now - 35_000
    :ets.insert(:scoria_circuit_breakers, {model_id, :open, 5, old_time})
    assert CircuitBreaker.open?(model_id) == false
  end

  test "record_success/1 resets failure count to 0 and status to :closed" do
    CircuitBreaker.init_table()
    model_id = "test_model_3"
    now = System.system_time(:millisecond)
    
    :ets.insert(:scoria_circuit_breakers, {model_id, :open, 5, now})
    assert CircuitBreaker.open?(model_id) == true
    
    assert :ok = CircuitBreaker.record_success(model_id)
    assert CircuitBreaker.open?(model_id) == false
    
    [{^model_id, status, count, _}] = :ets.lookup(:scoria_circuit_breakers, model_id)
    assert status == :closed
    assert count == 0
  end

  test "sweep_half_open/0 finds :open circuits past their timeout and transitions them to :half_open with count 0" do
    CircuitBreaker.init_table()
    now = System.system_time(:millisecond)
    
    # Model 1: open, expired timeout
    expired_time = now - 35_000
    :ets.insert(:scoria_circuit_breakers, {"model_expired", :open, 5, expired_time})
    
    # Model 2: open, not expired
    recent_time = now - 10_000
    :ets.insert(:scoria_circuit_breakers, {"model_recent", :open, 5, recent_time})
    
    # Model 3: closed
    :ets.insert(:scoria_circuit_breakers, {"model_closed", :closed, 0, 0})
    
    CircuitBreaker.sweep_half_open()
    
    # Check states
    [{_, status1, count1, _}] = :ets.lookup(:scoria_circuit_breakers, "model_expired")
    assert status1 == :half_open
    assert count1 == 0
    
    [{_, status2, count2, _}] = :ets.lookup(:scoria_circuit_breakers, "model_recent")
    assert status2 == :open
    assert count2 == 5
    
    [{_, status3, _count3, _}] = :ets.lookup(:scoria_circuit_breakers, "model_closed")
    assert status3 == :closed
  end
end
