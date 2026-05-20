defmodule Scoria.Req.Steps.Resiliency do
  @moduledoc """
  Req response and error steps that track successes and failures in the circuit breaker.
  """

  alias Scoria.Observe.CircuitBreaker

  @doc """
  Req response step. Records successes and failures based on the HTTP status code.
  2xx statuses are recorded as successes.
  429 and 5xx statuses are recorded as failures.
  All other statuses (e.g., 400, 401, 404) are ignored by the circuit breaker logic
  because they typically represent client errors, not service outages.
  """
  def handle_response({request, response}) do
    model_id = request.options[:model_id]

    if model_id != nil do
      cond do
        response.status >= 200 and response.status < 300 ->
          CircuitBreaker.record_success(model_id)

        response.status == 429 or response.status >= 500 ->
          CircuitBreaker.record_failure(model_id)

        true ->
          :ok
      end
    end

    {request, response}
  end

  @doc """
  Req error step. Records transport and parsing errors as failures.
  """
  def handle_error({request, exception}) do
    model_id = request.options[:model_id]

    if model_id != nil do
      CircuitBreaker.record_failure(model_id)
    end

    {request, exception}
  end
end
