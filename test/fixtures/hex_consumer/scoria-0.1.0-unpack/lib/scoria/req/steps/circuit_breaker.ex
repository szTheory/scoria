defmodule Scoria.Req.Steps.CircuitBreaker do
  @moduledoc """
  Req request step that checks the circuit breaker state before executing the request.
  """

  alias Scoria.Observe.CircuitBreaker

  @doc """
  Runs the step on the given `Req.Request`.
  If the request has a `:model_id` option and the circuit is open, halts the request
  with an error. Otherwise, returns the request unmodified.
  """
  def run(%Req.Request{} = request) do
    model_id = request.options[:model_id]

    if model_id != nil and CircuitBreaker.open?(model_id) do
      Req.Request.halt(request, %RuntimeError{message: "Circuit breaker is open"})
    else
      request
    end
  end
end
