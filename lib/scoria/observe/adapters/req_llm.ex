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
    span = %{
      name: "req_llm_request",
      span_kind: "LLM",
      start_time: metadata[:start_time] || DateTime.utc_now(),
      end_time: DateTime.utc_now(),
      trace_id: metadata[:trace_id] || Ecto.UUID.generate(),
      attributes: %{
        "llm.model_name" => metadata[:model],
        "llm.token_count" => measurements[:total_tokens],
        "req.url" => metadata[:url]
      }
    }
    
    :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)
  end
end