defmodule Scoria.Req.Steps do
  @moduledoc """
  Provides the `attach/2` function to add Scoria's resiliency and model routing
  steps to a Req pipeline.
  """

  alias Scoria.Req.Steps.CircuitBreaker
  alias Scoria.Req.Steps.Resiliency

  @doc """
  Attaches Scoria steps to the given Req request.
  
  ## Options
    * `:model_id` - The ID of the model being routed to, used for circuit breaking.
  """
  def attach(%Req.Request{} = req, opts \\ []) do
    req
    |> Req.Request.register_options([:model_id])
    |> Req.Request.merge_options(opts)
    |> Req.Request.append_request_steps(scoria_circuit_breaker: &CircuitBreaker.run/1)
    |> Req.Request.append_response_steps(scoria_resiliency: &Resiliency.handle_response/1)
    |> Req.Request.append_error_steps(scoria_resiliency: &Resiliency.handle_error/1)
  end
end
