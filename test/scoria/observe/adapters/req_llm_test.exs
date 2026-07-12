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

  # Realistic %LLMDB.Model{} fixture — NOT a bare string. Production
  # [:req_llm, :request, :stop] events carry metadata[:model] as a real
  # %LLMDB.Model{} struct (RESEARCH.md Pitfall 1); a bare-string fixture
  # would mask the struct-in-jsonb bug fixed by this plan.
  defp realistic_metadata(overrides \\ %{}) do
    %{
      model: LLMDB.Model.new!(%{id: "gpt-5", provider: :openai}),
      provider: :openai,
      operation: :chat,
      trace_id: Ecto.UUID.generate(),
      tenant_id: "tenant-1",
      workflow_run_id: "run-1",
      request_options: %{
        temperature: 0.7,
        top_p: 0.9,
        max_tokens: 512,
        seed: 42
      },
      usage: %{input_tokens: 150, output_tokens: 42}
    }
    |> Map.merge(overrides)
  end

  test "transforms req_llm stop event into a scoria span with gen_ai.* attributes, correct span_kind, and no legacy keys" do
    metadata = realistic_metadata()

    :telemetry.execute([:req_llm, :request, :stop], %{}, metadata)

    assert_receive {:span, span}
    assert span.name == "req_llm_request"
    assert span.trace_id == metadata.trace_id

    # SPAN-01 / SC#2: all four model-config params + a usage key present TOGETHER
    assert span.attributes["gen_ai.request.model"] == "gpt-5"
    assert span.attributes["gen_ai.request.temperature"] == 0.7
    assert span.attributes["gen_ai.request.top_p"] == 0.9
    assert span.attributes["gen_ai.request.max_tokens"] == 512
    assert span.attributes["gen_ai.request.seed"] == 42
    assert span.attributes["gen_ai.usage.input_tokens"] == 150

    # SPAN-02: native-lowercase span_kind + mirrored openinference.span.kind
    assert span.span_kind == "llm"
    assert span.attributes["openinference.span.kind"] == "LLM"

    # COMPAT-01: legacy keys are gone (clean replacement, no dual-emit)
    refute Map.has_key?(span.attributes, "llm.model_name")
    refute Map.has_key?(span.attributes, "llm.token_count")
    refute Map.has_key?(span.attributes, "req.url")

    # tenant_id / workflow_run_id still appear when present
    assert span.attributes["tenant_id"] == "tenant-1"
    assert span.attributes["workflow_run_id"] == "run-1"
  end
end
