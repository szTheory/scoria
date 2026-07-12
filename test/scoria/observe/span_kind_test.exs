defmodule Scoria.Observe.SpanKindTest do
  use ExUnit.Case, async: true

  alias Scoria.Observe.SpanKind

  describe "kinds/0" do
    test "returns exactly the 8-value canonical list, in order" do
      assert SpanKind.kinds() ==
               ~w(agent llm prompt tool mcp retriever guardrail eval)
    end
  end

  describe "kind?/1" do
    test "true for every canonical kind, any casing" do
      for kind <- SpanKind.kinds() do
        assert SpanKind.kind?(kind)
        assert SpanKind.kind?(String.upcase(kind))
      end
    end

    test "false for non-canonical values" do
      for value <- ["error", "internal", "chain", "embedding", "reranker", nil] do
        refute SpanKind.kind?(value)
      end
    end
  end

  describe "normalize/1" do
    test "downcases and validates a recognized value" do
      assert SpanKind.normalize("LLM") == "llm"
      assert SpanKind.normalize("TOOL") == "tool"
    end

    test "defaults to \"agent\" for an unrecognized value" do
      assert SpanKind.normalize("nonsense") == "agent"
    end
  end

  describe "normalize/2" do
    test "returns the supplied default and emits telemetry + logs a warning on fallback" do
      :telemetry.attach(
        "span-kind-test-fallback",
        [:scoria, :observe, :span_kind, :fallback],
        fn event, measurements, metadata, _config ->
          send(self(), {:telemetry_event, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach("span-kind-test-fallback") end)

      log =
        ExUnit.CaptureLog.capture_log(fn ->
          assert SpanKind.normalize("bogus", "guardrail") == "guardrail"
        end)

      assert log =~ "Unrecognized span_kind"

      assert_receive {:telemetry_event, [:scoria, :observe, :span_kind, :fallback], %{},
                       %{value: "bogus", default: "guardrail"}}
    end
  end

  describe "to_openinference/1" do
    test "maps every native kind to the correct UPPERCASE OpenInference value" do
      assert SpanKind.to_openinference("agent") == "AGENT"
      assert SpanKind.to_openinference("llm") == "LLM"
      assert SpanKind.to_openinference("prompt") == "PROMPT"
      assert SpanKind.to_openinference("tool") == "TOOL"
      assert SpanKind.to_openinference("mcp") == "TOOL"
      assert SpanKind.to_openinference("retriever") == "RETRIEVER"
      assert SpanKind.to_openinference("guardrail") == "GUARDRAIL"
      assert SpanKind.to_openinference("eval") == "EVALUATOR"
    end

    test "never raises for any kind in kinds/0" do
      for kind <- SpanKind.kinds() do
        assert is_binary(SpanKind.to_openinference(kind))
      end
    end
  end
end
