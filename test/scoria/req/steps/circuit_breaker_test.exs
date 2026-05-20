defmodule Scoria.Req.Steps.CircuitBreakerTest do
  use ExUnit.Case, async: false

  alias Scoria.Req.Steps.CircuitBreaker
  alias Scoria.Observe.CircuitBreaker, as: CB

  setup do
    CB.init_table()
    # Reset ETS for safe async: false testing
    :ets.delete_all_objects(:scoria_circuit_breakers)
    :ok
  end

  test "halts request when circuit is open" do
    model_id = "test_model_1"
    
    # Force open the circuit breaker
    Enum.each(1..5, fn _ -> CB.record_failure(model_id, threshold: 5) end)
    assert CB.open?(model_id)

    request = Req.new() |> Req.Request.register_options([:model_id]) |> Req.merge(model_id: model_id)
    
    {returned_request, error} = CircuitBreaker.run(request)
    
    assert returned_request.halted == true
    assert %RuntimeError{message: "Circuit breaker is open"} = error
  end

  test "returns request unmodified when circuit is closed" do
    model_id = "test_model_2"
    
    # Circuit is closed initially
    assert not CB.open?(model_id)

    request = Req.new() |> Req.Request.register_options([:model_id]) |> Req.merge(model_id: model_id)
    
    returned_request = CircuitBreaker.run(request)
    
    assert returned_request == request
    assert returned_request.halted == false
  end

  test "returns request unmodified when model_id is not set" do
    request = Req.new()
    returned_request = CircuitBreaker.run(request)
    
    assert returned_request == request
    assert returned_request.halted == false
  end
end
