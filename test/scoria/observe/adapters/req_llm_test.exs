defmodule Scoria.Observe.Adapters.ReqLLMTest do
  use ExUnit.Case, async: false

  setup do
    :telemetry.detach("scoria-observe-telemetry-test-req")
    :telemetry.detach("scoria-observe-reqllm")
    
    # We want to capture the transformed event
    parent = self()
    :telemetry.attach(
      "scoria-observe-telemetry-test-req",
      [:scoria, :observe, :span, :stop],
      fn _name, _measurements, metadata, _config ->
        send(parent, {:span, metadata})
      end,
      nil
    )
    
    Scoria.Observe.Adapters.ReqLLM.attach()
    :ok
  end

  test "transforms req_llm stop event to scoria span" do
    trace_id = Ecto.UUID.generate()
    metadata = %{
      model: "gpt-4",
      url: "https://api.openai.com",
      trace_id: trace_id
    }
    measurements = %{total_tokens: 150}

    :telemetry.execute([:req_llm, :request, :stop], measurements, metadata)

    assert_receive {:span, span}
    assert span.name == "req_llm_request"
    assert span.span_kind == "LLM"
    assert span.trace_id == trace_id
    assert span.attributes["llm.model_name"] == "gpt-4"
    assert span.attributes["llm.token_count"] == 150
  end
end