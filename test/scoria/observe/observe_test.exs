defmodule Scoria.ObserveTest do
  use ExUnit.Case, async: false

  alias Scoria.Observe
  alias Scoria.Observe.Semconv
  alias Scoria.Observe.SpanKind

  setup do
    :telemetry.detach("scoria-observe-test-capture")

    parent = self()

    :telemetry.attach(
      "scoria-observe-test-capture",
      [:scoria, :observe, :span, :stop],
      fn _name, _measurements, span, _config -> send(parent, {:span, span}) end,
      nil
    )

    on_exit(fn -> :telemetry.detach("scoria-observe-test-capture") end)

    :ok
  end

  defp capture_span(fun) do
    :ok = fun.()
    assert_receive {:span, span}
    span
  end

  describe "emit_retriever_span/1" do
    test "emits a RETRIEVER-kind span with the OpenInference kind attribute" do
      span =
        capture_span(fn ->
          Observe.emit_retriever_span(%{
            config_map: %{embedding_model: "m", index_version: "v1", reranker: "r"},
            host_metadata: %{feature: "support-copilot"},
            trace_id: Ecto.UUID.generate(),
            span_id: Ecto.UUID.generate(),
            parent_id: nil,
            started_wall: DateTime.utc_now()
          })
        end)

      assert span.span_kind == SpanKind.normalize("retriever")

      assert span.attributes[Semconv.openinference_span_kind_key()] ==
               SpanKind.to_openinference("retriever")
    end

    test "preserves caller-supplied :id, :trace_id, and :parent_id" do
      trace_id = Ecto.UUID.generate()
      span_id = Ecto.UUID.generate()
      parent_id = Ecto.UUID.generate()

      span =
        capture_span(fn ->
          Observe.emit_retriever_span(%{
            config_map: %{},
            host_metadata: %{},
            trace_id: trace_id,
            span_id: span_id,
            parent_id: parent_id,
            started_wall: DateTime.utc_now()
          })
        end)

      assert span.id == span_id
      assert span.trace_id == trace_id
      assert span.parent_id == parent_id
    end

    test "attributes carry the three retrieval-config keys and host-declared keys" do
      span =
        capture_span(fn ->
          Observe.emit_retriever_span(%{
            config_map: %{embedding_model: "m", index_version: "v1", reranker: "r"},
            host_metadata: %{feature: "support-copilot", route: "/tickets/:id"},
            trace_id: Ecto.UUID.generate(),
            span_id: Ecto.UUID.generate(),
            parent_id: nil,
            started_wall: DateTime.utc_now()
          })
        end)

      assert span.attributes["scoria.retrieval.embedding_model"] == "m"
      assert span.attributes["scoria.retrieval.index_version"] == "v1"
      assert span.attributes["scoria.retrieval.reranker"] == "r"
      assert span.attributes["feature"] == "support-copilot"
      assert span.attributes["route"] == "/tickets/:id"
    end

    test "status_code is OK and start_time/end_time are DateTimes" do
      started_wall = DateTime.utc_now()

      span =
        capture_span(fn ->
          Observe.emit_retriever_span(%{
            config_map: %{},
            host_metadata: %{},
            trace_id: Ecto.UUID.generate(),
            span_id: Ecto.UUID.generate(),
            parent_id: nil,
            started_wall: started_wall
          })
        end)

      assert span.status_code == "OK"
      assert span.start_time == started_wall
      assert %DateTime{} = span.end_time
    end

    test "returns :ok even when the telemetry handler raises" do
      :telemetry.attach(
        "scoria-observe-test-raiser",
        [:scoria, :observe, :span, :stop],
        fn _name, _measurements, _span, _config -> raise "boom" end,
        nil
      )

      on_exit(fn -> :telemetry.detach("scoria-observe-test-raiser") end)

      assert :ok =
               Observe.emit_retriever_span(%{
                 config_map: %{},
                 host_metadata: %{},
                 trace_id: Ecto.UUID.generate(),
                 span_id: Ecto.UUID.generate(),
                 parent_id: nil,
                 started_wall: DateTime.utc_now()
               })
    end
  end
end
