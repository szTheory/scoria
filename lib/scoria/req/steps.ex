defmodule Scoria.Req.Steps do
  @moduledoc """
  `Scoria.Req.Steps` attaches Scoria's model resiliency steps to a `Req`
  request pipeline.

  Use it from host-owned provider clients or ReqLLM integration code when you
  want Scoria's circuit-breaker and fallback evidence around outbound model
  calls. The host app still owns provider choice, credentials, prompt policy
  values, and business-specific retry posture; Scoria contributes inspectable
  request/response/error steps that fit the default runtime trace.

  See `guides/capabilities/default-runtime.md` for the first runtime capability
  and `guides/reviewer-verification.md` for verification suite guidance.
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

  @doc """
  Returns the declarative options list to pass to Req.new/1 or ReqLLM.
  """
  def req_options(model_id) do
    [
      {Req.Request, :register_options, [[:model_id]]},
      {Req.Request, :merge_options, [[model_id: model_id]]},
      {Req.Request, :append_request_steps, [[scoria_circuit_breaker: &CircuitBreaker.run/1]]},
      {Req.Request, :append_response_steps, [[scoria_resiliency: &Resiliency.handle_response/1]]},
      {Req.Request, :append_error_steps, [[scoria_resiliency: &Resiliency.handle_error/1]]}
    ]
  end
end
