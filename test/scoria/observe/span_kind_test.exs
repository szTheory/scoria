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

  # D-15 mandatory drift-guard suite (FOUND-02). These four assertions are
  # the structural single-source-of-truth guard: any future change to the
  # kind list, the OpenInference mapping, the CSS rails, or a component
  # reverting to an inline whitelist must fail one of these tests.
  describe "D-15 drift guard" do
    @css_path "assets/css/04-components.css"
    @component_paths ~w(
      lib/scoria_web/components/workflow_tree_component.ex
      lib/scoria_web/components/trace_tree_component.ex
    )

    test "CANARY: kinds/0 is exactly the pinned 8-value list (forces review of CSS + OI map on any change)" do
      assert SpanKind.kinds() == ~w(agent llm prompt tool mcp retriever guardrail eval)
    end

    test "EXHAUSTIVENESS: every kind is kind?/1-true and has a non-raising to_openinference/1 clause" do
      for kind <- SpanKind.kinds() do
        assert SpanKind.kind?(kind)

        oi = SpanKind.to_openinference(kind)
        assert is_binary(oi)
        assert oi == String.upcase(oi)
      end
    end

    test "CSS COHERENCE: every kind has a matching scoria-span--<kind> rail, and the status-error overlay replaces the error rail" do
      css = File.read!(@css_path)

      for kind <- SpanKind.kinds() do
        assert css =~ "scoria-span--#{kind}",
               "missing CSS rail for kind #{inspect(kind)} in #{@css_path}"
      end

      refute css =~ "scoria-span--error ",
             "stale .scoria-span--error rail found in #{@css_path} (D-12: error is a status, not a kind)"

      assert css =~ "scoria-span--status-error",
             "expected .scoria-span--status-error overlay in #{@css_path}"
    end

    test "ANTI-INLINE GUARD: no residual span-kind ~w(...) whitelist literal remains in either UI component" do
      for path <- @component_paths do
        source = File.read!(path)

        refute Regex.match?(~r/~w\([^)]*(llm|guardrail|retriever)/, source),
               "inline span-kind ~w(...) whitelist literal found in #{path} — route through Scoria.Observe.SpanKind instead"
      end
    end

    test "FALLBACK OBSERVABILITY: normalize/1 on an unrecognized value emits the fallback telemetry event and returns the default \"agent\"" do
      :telemetry.attach(
        "span-kind-drift-guard-fallback",
        [:scoria, :observe, :span_kind, :fallback],
        fn event, measurements, metadata, _config ->
          send(self(), {:drift_guard_telemetry_event, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach("span-kind-drift-guard-fallback") end)

      assert SpanKind.normalize("bogus") == "agent"

      assert_receive {:drift_guard_telemetry_event, [:scoria, :observe, :span_kind, :fallback],
                       %{}, %{value: "bogus", default: "agent"}}
    end
  end
end
