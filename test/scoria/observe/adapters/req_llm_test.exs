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
  # %LLMDB.Model{} struct (RESEARCH.md Pitfall 1, confirmed against
  # deps/req_llm/lib/req_llm/telemetry.ex `new_context/3`); a bare-string
  # fixture would mask the struct-in-jsonb bug fixed by this plan. Pinned
  # against the locked req_llm 1.13.0 dependency (`mix hex.outdated req_llm`
  # pre-flight re-confirmed 2026-07-12: Hex latest is 1.17.1, but the
  # `~> 1.13` mix.exs requirement is still up-to-date/unchanged, so the
  # gen_ai.* key set enumerated below remains correct).
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

  defp capture_span(metadata) do
    :telemetry.execute([:req_llm, :request, :stop], %{}, metadata)
    assert_receive {:span, span}
    span
  end

  describe "span shape" do
    test "transforms a req_llm stop event into a scoria span" do
      metadata = realistic_metadata()
      span = capture_span(metadata)

      assert span.name == "req_llm_request"
      assert span.trace_id == metadata.trace_id
    end

    test "tenant_id / workflow_run_id from metadata appear in attributes when present" do
      span = capture_span(realistic_metadata())

      assert span.attributes["tenant_id"] == "tenant-1"
      assert span.attributes["workflow_run_id"] == "run-1"
    end
  end

  describe "SPAN-01: gen_ai.* completeness (SC#2 — never a partial subset)" do
    test "all four model-config params + a usage key are present together" do
      span = capture_span(realistic_metadata())

      assert span.attributes["gen_ai.request.model"] == "gpt-5"
      assert span.attributes["gen_ai.request.temperature"] == 0.7
      assert span.attributes["gen_ai.request.top_p"] == 0.9
      assert span.attributes["gen_ai.request.max_tokens"] == 512
      assert span.attributes["gen_ai.request.seed"] == 42
      assert span.attributes["gen_ai.usage.input_tokens"] == 150
    end
  end

  describe "SPAN-02: span_kind + mirrored openinference.span.kind" do
    test "span_kind is native-lowercase \"llm\" and the openinference mirror is UPPERCASE" do
      span = capture_span(realistic_metadata())

      assert span.span_kind == "llm"
      assert span.attributes["openinference.span.kind"] == "LLM"
    end
  end

  describe "COMPAT-01: legacy keys are gone (clean replacement, no dual-emit)" do
    test "attributes do not contain the old llm.model_name/llm.token_count/req.url keys" do
      span = capture_span(realistic_metadata())

      refute Map.has_key?(span.attributes, "llm.model_name")
      refute Map.has_key?(span.attributes, "llm.token_count")
      refute Map.has_key?(span.attributes, "req.url")
    end
  end

  describe "D-ATTR01-5: host-declared attribute pass-through" do
    # D-ATTR01-7 caveat: this proves the merge_host_declared/2 pipe wiring
    # on this adapter's OWN hand-synthesized test event, NOT production
    # reachability. A real [:req_llm, :request, :stop] emission carries no
    # host-declared keys in its metadata (req_llm builds a fixed base map);
    # production host keys on the LLM/prompt lane flow via
    # Scoria.Observe.emit_prompt_span/1 (52-03), not this adapter.
    test "a host-supplied feature key passes through byte-for-byte and an omitted host key is absent" do
      span = capture_span(realistic_metadata(%{feature: "support-copilot"}))

      assert span.attributes["feature"] == "support-copilot"
      refute Map.has_key?(span.attributes, "route")
    end
  end
end
