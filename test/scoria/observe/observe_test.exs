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

  describe "emit_prompt_span/1" do
    defp populated_context_pack do
      %{
        chunks: [%{id: "chunk-1", tokens: 128}],
        memories: [%{id: "mem-1", tokens: 64}],
        token_budget: %{total: 2048, chunks: 128, memories: 64, overhead: 1856}
      }
    end

    test "populated pack + host input_tokens: prompt-context and usage input-tokens coexist" do
      span =
        capture_span(fn ->
          Observe.emit_prompt_span(%{
            trace_id: Ecto.UUID.generate(),
            parent_id: nil,
            context_pack: populated_context_pack(),
            input_tokens: 1900
          })
        end)

      assert span.attributes[Semconv.prompt_context_key()] ==
               Semconv.prompt_context(populated_context_pack())

      assert span.attributes["gen_ai.usage.input_tokens"] == 1900
    end

    test "no context_pack: prompt-context key is absent from attributes" do
      span =
        capture_span(fn ->
          Observe.emit_prompt_span(%{trace_id: Ecto.UUID.generate(), input_tokens: 10})
        end)

      refute Map.has_key?(span.attributes, Semconv.prompt_context_key())
    end

    test "empty context_pack lists: prompt-context key is absent from attributes" do
      span =
        capture_span(fn ->
          Observe.emit_prompt_span(%{
            trace_id: Ecto.UUID.generate(),
            context_pack: %{chunks: [], memories: [], token_budget: %{}},
            input_tokens: 10
          })
        end)

      refute Map.has_key?(span.attributes, Semconv.prompt_context_key())
    end

    test "nil/absent input_tokens: usage input-tokens key is absent" do
      span =
        capture_span(fn ->
          Observe.emit_prompt_span(%{
            trace_id: Ecto.UUID.generate(),
            context_pack: populated_context_pack()
          })
        end)

      refute Map.has_key?(span.attributes, "gen_ai.usage.input_tokens")
    end

    test "host-declared keys ride the span via merge_host_declared/2" do
      span =
        capture_span(fn ->
          Observe.emit_prompt_span(%{
            trace_id: Ecto.UUID.generate(),
            feature: "support-copilot",
            route: "/tickets/:id",
            archetype: "rag",
            intent: "answer"
          })
        end)

      assert span.attributes["feature"] == "support-copilot"
      assert span.attributes["route"] == "/tickets/:id"
      assert span.attributes["archetype"] == "rag"
      assert span.attributes["intent"] == "answer"
    end

    test "span_kind is prompt, name is prompt.compose, :id defaults to a fresh UUID" do
      span = capture_span(fn -> Observe.emit_prompt_span(%{trace_id: Ecto.UUID.generate()}) end)

      assert span.span_kind == SpanKind.normalize("prompt")
      assert span.name == "prompt.compose"
      assert {:ok, _} = Ecto.UUID.cast(span.id)
    end

    test "a supplied :span_id is preserved (not overwritten by a fresh UUID)" do
      span_id = Ecto.UUID.generate()

      span =
        capture_span(fn ->
          Observe.emit_prompt_span(%{trace_id: Ecto.UUID.generate(), span_id: span_id})
        end)

      assert span.id == span_id
    end

    test "returns :ok even when the telemetry handler raises" do
      :telemetry.attach(
        "scoria-observe-test-prompt-raiser",
        [:scoria, :observe, :span, :stop],
        fn _name, _measurements, _span, _config -> raise "boom" end,
        nil
      )

      on_exit(fn -> :telemetry.detach("scoria-observe-test-prompt-raiser") end)

      assert :ok = Observe.emit_prompt_span(%{trace_id: Ecto.UUID.generate()})
    end
  end

  describe "emit_event/1 synchronous return contract (EVENT-02, Plan 53B-03)" do
    # The full DB-persistence rejection proof for both the direct and
    # raw-bus paths (SC#2) lives in Plan 05; this describe block proves
    # only the fast synchronous contract of emit_event/1 itself.
    setup do
      :telemetry.detach("scoria-observe-event-test-capture")

      parent = self()

      :telemetry.attach(
        "scoria-observe-event-test-capture",
        [:scoria, :observe, :event, :emit],
        fn _name, _measurements, event, _config -> send(parent, {:event, event}) end,
        nil
      )

      on_exit(fn -> :telemetry.detach("scoria-observe-event-test-capture") end)

      :ok
    end

    test "a known event name returns :ok and fires the :emit telemetry event" do
      event = %{
        name: :prompt_rendered,
        span_id: Ecto.UUID.generate(),
        attributes: %{},
        time: DateTime.utc_now()
      }

      assert :ok = Observe.emit_event(event)
      assert_receive {:event, ^event}
    end

    test "an unknown event name returns {:error, :unknown_event} and fires no telemetry" do
      assert {:error, :unknown_event} =
               Observe.emit_event(%{name: :not_a_real_event, span_id: Ecto.UUID.generate()})

      refute_receive {:event, _}
    end

    test "a malformed input (no :name key, or not a map) never raises" do
      assert {:error, :unknown_event} = Observe.emit_event(%{garbage: true})
      assert {:error, :unknown_event} = Observe.emit_event("not a map")
      assert {:error, :unknown_event} = Observe.emit_event(%{})
    end

    test "WR-02: a member name with a type-invalid time or span_id returns {:error, :invalid_event} and fires no telemetry" do
      assert {:error, :invalid_event} =
               Observe.emit_event(%{
                 name: :prompt_rendered,
                 span_id: Ecto.UUID.generate(),
                 attributes: %{},
                 time: "2026-01-01"
               })

      refute_receive {:event, _}

      assert {:error, :invalid_event} =
               Observe.emit_event(%{
                 name: :prompt_rendered,
                 span_id: "not-a-uuid",
                 attributes: %{},
                 time: DateTime.utc_now()
               })

      refute_receive {:event, _}

      assert {:error, :invalid_event} =
               Observe.emit_event(%{
                 name: :prompt_rendered,
                 span_id: nil,
                 attributes: %{},
                 time: DateTime.utc_now()
               })

      refute_receive {:event, _}
    end

    test "a raising handler on :emit is swallowed -- emit_event/1 still returns :ok" do
      :telemetry.attach(
        "scoria-observe-event-test-raiser",
        [:scoria, :observe, :event, :emit],
        fn _name, _measurements, _event, _config -> raise "boom" end,
        nil
      )

      on_exit(fn -> :telemetry.detach("scoria-observe-event-test-raiser") end)

      assert :ok =
               Observe.emit_event(%{
                 name: :guardrail_triggered,
                 span_id: Ecto.UUID.generate(),
                 attributes: %{},
                 time: DateTime.utc_now()
               })
    end
  end
end
