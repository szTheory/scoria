defmodule Scoria.Req.Steps.ResiliencyTest do
  use ExUnit.Case, async: false

  alias Scoria.Req.Steps.Resiliency
  alias Scoria.Observe.CircuitBreaker, as: CB

  setup do
    CB.init_table()
    :ets.delete_all_objects(:scoria_circuit_breakers)
    :ok
  end

  test "handle_response/1 calls record_success on 2xx response" do
    model_id = "test_resiliency_2xx"
    request = Req.new() |> Req.Request.register_options([:model_id]) |> Req.merge(model_id: model_id)
    response = %Req.Response{status: 200, body: "OK"}

    # We ensure failure count goes to 0 by forcing an error first
    CB.record_failure(model_id)
    assert [{^model_id, :closed, 1, _}] = :ets.lookup(:scoria_circuit_breakers, model_id)

    assert {^request, ^response} = Resiliency.handle_response({request, response})

    assert [{^model_id, :closed, 0, 0}] = :ets.lookup(:scoria_circuit_breakers, model_id)
  end

  test "handle_response/1 calls record_failure on 429 response" do
    model_id = "test_resiliency_429"
    request = Req.new() |> Req.Request.register_options([:model_id]) |> Req.merge(model_id: model_id)
    response = %Req.Response{status: 429, body: "Too Many Requests"}

    assert {^request, ^response} = Resiliency.handle_response({request, response})

    assert [{^model_id, :closed, 1, _}] = :ets.lookup(:scoria_circuit_breakers, model_id)
  end

  test "handle_response/1 calls record_failure on 5xx response" do
    model_id = "test_resiliency_5xx"
    request = Req.new() |> Req.Request.register_options([:model_id]) |> Req.merge(model_id: model_id)
    response = %Req.Response{status: 503, body: "Service Unavailable"}

    assert {^request, ^response} = Resiliency.handle_response({request, response})

    assert [{^model_id, :closed, 1, _}] = :ets.lookup(:scoria_circuit_breakers, model_id)
  end

  test "handle_response/1 ignores 4xx (except 429)" do
    model_id = "test_resiliency_4xx"
    request = Req.new() |> Req.Request.register_options([:model_id]) |> Req.merge(model_id: model_id)
    response = %Req.Response{status: 400, body: "Bad Request"}

    assert {^request, ^response} = Resiliency.handle_response({request, response})

    # Record failure not called (so no entry created for 400s initially)
    assert [] = :ets.lookup(:scoria_circuit_breakers, model_id)
  end

  test "handle_error/1 calls record_failure on exception" do
    model_id = "test_resiliency_err"
    request = Req.new() |> Req.Request.register_options([:model_id]) |> Req.merge(model_id: model_id)
    exception = %Mint.TransportError{reason: :timeout}

    assert {^request, ^exception} = Resiliency.handle_error({request, exception})

    assert [{^model_id, :closed, 1, _}] = :ets.lookup(:scoria_circuit_breakers, model_id)
  end

  test "does nothing if model_id is absent" do
    request = Req.new()
    response = %Req.Response{status: 500}
    exception = %Mint.TransportError{reason: :timeout}

    assert {^request, ^response} = Resiliency.handle_response({request, response})
    assert {^request, ^exception} = Resiliency.handle_error({request, exception})
  end
end
