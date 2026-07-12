defmodule Scoria.Observe.Adapters.ReqLLM do
  alias Scoria.Observe.Semconv
  alias Scoria.Observe.SpanKind

  def attach do
    :telemetry.attach_many(
      "scoria-observe-reqllm",
      [[:req_llm, :request, :stop]],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event([:req_llm, :request, :stop], _measurements, metadata, _config) do
    tenant_id = metadata[:tenant_id]
    workflow_run_id = metadata[:workflow_run_id]

    base_attributes =
      %{
        "tenant_id" => tenant_id,
        "workflow_run_id" => workflow_run_id
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    # req_llm.ex only ever emits LLM-model-call spans; the span_kind is
    # always "llm" unless a host explicitly overrides it via metadata[:span_kind]
    # (mirrors the Jido adapter's host-override + flat-default convention).
    # metadata[:operation] is req_llm's OWN telemetry vocabulary (:chat,
    # :embedding, :object — see ReqLLM.Telemetry.new_context/3) and is a
    # different taxonomy than Scoria's span_kind; it must not be read here.
    span_kind = SpanKind.normalize(metadata[:span_kind] || "llm")

    attributes =
      base_attributes
      |> Semconv.merge_req_llm_attributes(metadata)
      |> Map.put(Semconv.openinference_span_kind_key(), SpanKind.to_openinference(span_kind))

    span = %{
      name: "req_llm_request",
      span_kind: span_kind,
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
