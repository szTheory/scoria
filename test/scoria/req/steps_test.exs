defmodule Scoria.Req.StepsTest do
  use ExUnit.Case, async: false

  alias Scoria.Observe.CircuitBreaker, as: CB

  setup do
    CB.init_table()
    :ets.delete_all_objects(:scoria_circuit_breakers)
    
    Req.Test.stub(Scoria.Req.StepsTest, fn conn ->
      conn
      |> Plug.Conn.put_status(500)
      |> Req.Test.json(%{status: "error"})
    end)
    
    :ok
  end

  test "attach/2 registers model_id and appends steps" do
    req = Req.new() |> Scoria.Req.Steps.attach(model_id: "test_attach")

    assert req.options[:model_id] == "test_attach"
    
    # We can check that the steps are in the pipeline
    assert Keyword.has_key?(req.request_steps, :scoria_circuit_breaker)
    assert Keyword.has_key?(req.response_steps, :scoria_resiliency)
    assert Keyword.has_key?(req.error_steps, :scoria_resiliency)
  end

  test "integration: respects transient retries without tripping circuit breaker too early" do
    model_id = "test_integration_500"
    
    req =
      Req.new(plug: {Req.Test, Scoria.Req.StepsTest})
      |> Scoria.Req.Steps.attach(model_id: model_id)
      |> Req.Request.merge_options(retry: :transient, max_retries: 2, retry_delay: fn _ -> 10 end)

    # Initial state
    assert [] = :ets.lookup(:scoria_circuit_breakers, model_id)

    # Make the request. It should fail and retry 2 times (3 total attempts).
    # Since our threshold is 5 (default) and we don't over-count transient retries,
    # the circuit breaker will only record 1 failure for the entire request lifecycle.
    {_req, response} = Req.Request.run_request(req)
    assert response.status == 500

    # Ensure it's still closed but with 1 failure recorded
    assert [{^model_id, :closed, 1, _}] = :ets.lookup(:scoria_circuit_breakers, model_id)

    # Do it 4 more times to trip the circuit (total 5 failures)
    for _ <- 1..4 do
      {_req, _response} = Req.Request.run_request(req)
    end

    # It should be open
    assert [{^model_id, :open, count, _}] = :ets.lookup(:scoria_circuit_breakers, model_id)
    assert count >= 5
    
    # Next request should be halted immediately by CircuitBreaker before even attempting
    {req3, _} = Req.Request.run_request(req)
    assert req3.halted == true
  end
end
