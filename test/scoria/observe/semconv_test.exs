defmodule Scoria.Observe.SemconvTest do
  use ExUnit.Case, async: true

  alias Scoria.Observe.Semconv

  describe "openinference_span_kind_key/0" do
    test "returns exactly \"openinference.span.kind\"" do
      assert Semconv.openinference_span_kind_key() == "openinference.span.kind"
    end
  end

  describe "merge_req_llm_attributes/2" do
    test "returns a map containing the core gen_ai.* request/usage keys" do
      metadata = %{
        model: LLMDB.Model.new!(%{id: "gpt-5", provider: :openai}),
        provider: :openai,
        operation: :chat,
        request_options: %{temperature: 0.7, top_p: 0.9, max_tokens: 512, seed: 42},
        usage: %{input_tokens: 150, output_tokens: 42}
      }

      merged = Semconv.merge_req_llm_attributes(%{}, metadata)

      assert Map.has_key?(merged, "gen_ai.request.model")
      assert Map.has_key?(merged, "gen_ai.request.temperature")
      assert Map.has_key?(merged, "gen_ai.request.top_p")
      assert Map.has_key?(merged, "gen_ai.request.max_tokens")
      assert Map.has_key?(merged, "gen_ai.request.seed")

      assert Enum.any?(Map.keys(merged), &String.starts_with?(&1, "gen_ai.usage."))
    end

    test "preserves caller-supplied base attributes" do
      metadata = %{
        model: LLMDB.Model.new!(%{id: "gpt-5", provider: :openai}),
        provider: :openai,
        operation: :chat
      }

      merged = Semconv.merge_req_llm_attributes(%{"tenant_id" => "t1"}, metadata)

      assert merged["tenant_id"] == "t1"
    end
  end
end
