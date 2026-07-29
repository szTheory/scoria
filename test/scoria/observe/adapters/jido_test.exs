defmodule Scoria.Observe.Adapters.JidoTest do
  use ExUnit.Case, async: false

  setup do
    :telemetry.detach("scoria-observe-telemetry-test-jido")
    :telemetry.detach("scoria-observe-jido")

    parent = self()

    :telemetry.attach(
      "scoria-observe-telemetry-test-jido",
      [:scoria, :observe, :span, :stop],
      fn _name, _measurements, metadata, _config ->
        send(parent, {:span, metadata})
      end,
      nil
    )

    Scoria.Observe.Adapters.Jido.attach()
    :ok
  end

  defp base_metadata(overrides \\ %{}) do
    %{
      action_name: "calculate_pi",
      status: "ok",
      trace_id: Ecto.UUID.generate()
    }
    |> Map.merge(overrides)
  end

  defp capture_span(metadata, measurements \\ %{duration: 500}) do
    :telemetry.execute([:jido, :action, :stop], measurements, metadata)
    assert_receive {:span, span}
    span
  end

  describe "span shape" do
    test "transforms jido action stop event to scoria span" do
      metadata = base_metadata()
      span = capture_span(metadata)

      assert span.name == "jido_action"
      assert span.trace_id == metadata.trace_id
      assert span.attributes["jido.action_name"] == "calculate_pi"
      assert span.attributes["jido.status"] == "ok"
      assert span.attributes["duration_ms"] == 500
    end
  end

  describe "SPAN-02: span_kind (host-declared, default tool) + mirrored openinference.span.kind" do
    test "no metadata[:span_kind] defaults to native-lowercase \"tool\"" do
      span = capture_span(base_metadata())

      assert span.span_kind == "tool"
      assert span.attributes["openinference.span.kind"] == "TOOL"
    end

    test "metadata[:span_kind] == \"agent\" is honored (host override, no action-name inference)" do
      span = capture_span(base_metadata(%{span_kind: "agent"}))

      assert span.span_kind == "agent"
      assert span.attributes["openinference.span.kind"] == "AGENT"
    end

    test "metadata[:span_kind] == \"mcp\" mirrors to openinference \"TOOL\" (D-11)" do
      span = capture_span(base_metadata(%{span_kind: "mcp"}))

      assert span.span_kind == "mcp"
      assert span.attributes["openinference.span.kind"] == "TOOL"
    end

    test "every produced span carries an openinference.span.kind attribute" do
      for span_kind <- [nil, "tool", "agent", "mcp"] do
        overrides = if span_kind, do: %{span_kind: span_kind}, else: %{}
        span = capture_span(base_metadata(overrides))

        assert Map.has_key?(span.attributes, "openinference.span.kind")
      end
    end
  end

  describe "D-ATTR01-5: host-declared attribute pass-through (production-shaped)" do
    test "a host-supplied feature key passes through byte-for-byte and an omitted host key is absent" do
      span = capture_span(base_metadata(%{feature: "support-copilot"}))

      assert span.attributes["feature"] == "support-copilot"
      refute Map.has_key?(span.attributes, "route")
    end
  end
end
