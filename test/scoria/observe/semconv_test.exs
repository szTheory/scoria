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

  describe "single-origin + delegation proof (SPAN-01 key-completeness at the Semconv layer)" do
    test "preserves base attrs and carries model-config + usage keys together, from a realistic %LLMDB.Model{}-shaped [:req_llm, :request, :stop] fixture" do
      metadata = %{
        model: LLMDB.Model.new!(%{id: "gpt-5", provider: :openai}),
        provider: :openai,
        operation: :chat,
        request_options: %{
          temperature: 0.7,
          top_p: 0.9,
          max_tokens: 512,
          seed: 42
        },
        usage: %{input_tokens: 150, output_tokens: 42}
      }

      merged = Semconv.merge_req_llm_attributes(%{"tenant_id" => "t1"}, metadata)

      # (a) caller-supplied base attributes preserved
      assert merged["tenant_id"] == "t1"

      # (b) all four model-config params present TOGETHER
      assert merged["gen_ai.request.model"] == "gpt-5"
      assert merged["gen_ai.request.temperature"] == 0.7
      assert merged["gen_ai.request.top_p"] == 0.9
      assert merged["gen_ai.request.max_tokens"] == 512
      assert merged["gen_ai.request.seed"] == 42

      # (c) a usage key is present
      assert merged["gen_ai.usage.input_tokens"] == 150
    end

    test "openinference_span_kind_key/0 returns the exact key string" do
      assert Semconv.openinference_span_kind_key() == "openinference.span.kind"
    end

    test "single-origin guard: semconv.ex source contains no hand-declared gen_ai.* literal" do
      source =
        "lib/scoria/observe/semconv.ex"
        |> Path.expand(File.cwd!())
        |> File.read!()

      refute source =~ ~r/"gen_ai\./,
             "semconv.ex must delegate to ReqLLM.OpenTelemetry.Attributes, never hand-write a gen_ai.* string literal"
    end
  end
end
