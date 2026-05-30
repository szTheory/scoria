defmodule Scoria.Observe.Adapters.ReqLLM do
  def attach do
    :telemetry.attach_many(
      "scoria-observe-reqllm",
      [[:req_llm, :request, :stop]],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event([:req_llm, :request, :stop], measurements, metadata, _config) do
    tenant_id = metadata[:tenant_id]
    workflow_run_id = metadata[:workflow_run_id]

    attributes =
      %{
        "llm.model_name" => metadata[:model],
        "llm.token_count" => measurements[:total_tokens],
        "req.url" => metadata[:url],
        "tenant_id" => tenant_id,
        "workflow_run_id" => workflow_run_id
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    span = %{
      name: "req_llm_request",
      span_kind: "LLM",
      start_time: metadata[:start_time] || DateTime.utc_now(),
      end_time: DateTime.utc_now(),
      trace_id: metadata[:trace_id] || Ecto.UUID.generate(),
      parent_id: metadata[:parent_id],
      tenant_id: tenant_id,
      workflow_run_id: workflow_run_id,
      session_id: metadata[:session_id],
      attributes: attributes
    }

    :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)
  end
end
