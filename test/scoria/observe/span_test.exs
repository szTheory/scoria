defmodule Scoria.Observe.SpanTest do
  @moduledoc """
  Wave-0 test for `Scoria.Observe.span/4` — the single transparent span
  primitive plans 53-05/53-07/53-08 funnel through (D-01a/D-01d).

  Mirrors the DB-backed setup pattern from `prompt_span_test.exs` (real
  sandbox checkout, a scoped supervised `Buffer`, detach/re-attach the
  shared `Scoria.Observe.Telemetry` handler onto that scoped buffer name)
  rather than hand-synthesizing a span (D-ATTR01-6). Because plan 53-01
  now attaches the handler at boot, `on_exit` restores the default
  (boot-equivalent) handler after detaching the scoped one, so the boot
  pipeline is available to subsequent tests in the suite.
  """

  use ExUnit.Case, async: false

  import Ecto.Query, only: [from: 2]

  alias Scoria.Observe
  alias Scoria.Observe.Buffer
  alias Scoria.Observe.ReviewerBroadcast
  alias Scoria.Observe.Semconv
  alias Scoria.Observe.SpanKind
  alias Scoria.Repo
  alias Scoria.Repo.Span

  @never_text_key_regex ~r/text|content|body|message|prompt|raw/i

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    buffer_name = :"span_test_buffer_#{System.unique_integer([:positive])}"

    start_supervised!(
      Supervisor.child_spec(
        {Buffer, [name: buffer_name, flush_interval: 10_000, max_size: 100]},
        id: buffer_name
      )
    )

    # Real production wiring, not a hand-synthesized :telemetry.execute call
    # (D-ATTR01-6): detach the default-named handler and re-attach it onto
    # this test's scoped buffer, exactly as prompt_span_test.exs does.
    :telemetry.detach("scoria-observe-telemetry")
    Scoria.Observe.Telemetry.attach(buffer_name)

    on_exit(fn ->
      :telemetry.detach("scoria-observe-telemetry")

      # Plan 53-01 attaches this handler at boot; restore it so later tests
      # in the suite still run against the default-named boot pipeline.
      case Scoria.Observe.Telemetry.attach() do
        :ok -> :ok
        {:error, :already_exists} -> :ok
      end
    end)

    ReviewerBroadcast.reset_trace_seen!()

    %{buffer: buffer_name}
  end

  defp flush_and_get(span_id, buffer_name) do
    :ok = Buffer.flush_now(buffer_name)
    Repo.get_by!(Span, id: span_id)
  end

  # Recursively walks a persisted attributes map: no key may match the
  # never-text guard regex, and every leaf must be a non-empty binary, a
  # non-negative integer, true, or nil (D-ATTR02-4 style guard, reused from
  # prompt_span_test.exs).
  defp assert_never_text(value) when is_map(value) do
    for {k, v} <- value do
      refute k =~ @never_text_key_regex,
             "forbidden key #{inspect(k)} matched the never-text guard"

      assert_never_text(v)
    end
  end

  defp assert_never_text(value) when is_list(value) do
    Enum.each(value, &assert_never_text/1)
  end

  defp assert_never_text(value) when is_binary(value) do
    assert byte_size(value) > 0
  end

  defp assert_never_text(value) when is_integer(value) do
    assert value >= 0
  end

  defp assert_never_text(true), do: :ok
  defp assert_never_text(nil), do: :ok

  describe "Test 1: transparency" do
    test "span/4 returns fun's value verbatim, never transforms it", %{buffer: buffer_name} do
      opts = %{trace_id: Ecto.UUID.generate(), span_id: Ecto.UUID.generate(), parent_id: nil}

      assert Observe.span("tool", "t", opts, fn -> :sentinel_value end) == :sentinel_value

      :ok = Buffer.flush_now(buffer_name)
    end
  end

  describe "Test 2: real duration" do
    test "a sleeping fun yields a persisted span with a real, monotonic-derived duration", %{
      buffer: buffer_name
    } do
      trace_id = Ecto.UUID.generate()
      span_id = Ecto.UUID.generate()
      opts = %{trace_id: trace_id, span_id: span_id, parent_id: nil}

      Observe.span("tool", "t", opts, fn ->
        Process.sleep(50)
        :ok
      end)

      span = flush_and_get(span_id, buffer_name)

      assert DateTime.compare(span.end_time, span.start_time) == :gt
      assert DateTime.diff(span.end_time, span.start_time, :millisecond) >= 40
    end
  end

  describe "Test 3: ERROR + reraise (SC#3)" do
    test "a raising fun produces one ERROR span with a real duration and reraises the host exception unchanged",
         %{buffer: buffer_name} do
      trace_id = Ecto.UUID.generate()
      span_id = Ecto.UUID.generate()
      opts = %{trace_id: trace_id, span_id: span_id, parent_id: nil}

      assert_raise RuntimeError, "boom", fn ->
        Observe.span("tool", "t", opts, fn -> raise "boom" end)
      end

      span = flush_and_get(span_id, buffer_name)

      assert span.status_code == "ERROR"
      assert DateTime.compare(span.end_time, span.start_time) == :gt
    end
  end

  describe "Test 4: stacktrace fidelity" do
    test "reraise preserves the original stacktrace: the top frame is the raise site, not Scoria.Observe",
         %{buffer: buffer_name} do
      trace_id = Ecto.UUID.generate()
      span_id = Ecto.UUID.generate()
      opts = %{trace_id: trace_id, span_id: span_id, parent_id: nil}

      stacktrace =
        try do
          Observe.span("tool", "t", opts, fn -> raise "boom" end)
          flunk("expected span/4 to reraise")
        rescue
          _ -> __STACKTRACE__
        end

      :ok = Buffer.flush_now(buffer_name)

      {top_mod, _fun, _arity, _info} = hd(stacktrace)

      assert top_mod == __MODULE__,
             "expected the top stacktrace frame to be the anonymous raise-site fun in #{inspect(__MODULE__)}, got #{inspect(top_mod)}"
    end
  end

  describe "Test 5: single emit (RESEARCH Pitfall 1)" do
    test "a raising span/4 call persists EXACTLY ONE span row, never two", %{buffer: buffer_name} do
      trace_id = Ecto.UUID.generate()
      span_id = Ecto.UUID.generate()
      opts = %{trace_id: trace_id, span_id: span_id, parent_id: nil}

      assert_raise RuntimeError, fn ->
        Observe.span("tool", "t", opts, fn -> raise "boom" end)
      end

      :ok = Buffer.flush_now(buffer_name)

      spans = Repo.all(from s in Span, where: s.trace_id == ^trace_id)
      assert length(spans) == 1
    end
  end

  describe "Test 6: throw/exit" do
    test "a throwing fun propagates the throw unchanged and persists exactly one ERROR span", %{
      buffer: buffer_name
    } do
      trace_id = Ecto.UUID.generate()
      span_id = Ecto.UUID.generate()
      opts = %{trace_id: trace_id, span_id: span_id, parent_id: nil}

      result =
        try do
          Observe.span("tool", "t", opts, fn -> throw(:nope) end)
        catch
          :throw, value -> {:caught_throw, value}
        end

      assert result == {:caught_throw, :nope}

      span = flush_and_get(span_id, buffer_name)
      assert span.status_code == "ERROR"

      spans = Repo.all(from s in Span, where: s.trace_id == ^trace_id)
      assert length(spans) == 1
    end

    test "an exiting fun propagates the exit unchanged and persists exactly one ERROR span", %{
      buffer: buffer_name
    } do
      trace_id = Ecto.UUID.generate()
      span_id = Ecto.UUID.generate()
      opts = %{trace_id: trace_id, span_id: span_id, parent_id: nil}

      result =
        try do
          Observe.span("tool", "t", opts, fn -> exit(:shutdown) end)
        catch
          :exit, reason -> {:caught_exit, reason}
        end

      assert result == {:caught_exit, :shutdown}

      span = flush_and_get(span_id, buffer_name)
      assert span.status_code == "ERROR"

      spans = Repo.all(from s in Span, where: s.trace_id == ^trace_id)
      assert length(spans) == 1
    end
  end

  describe "Test 7: no message leak (SC#4, T-53-05)" do
    test "the persisted ERROR span's attributes carry only type-only exception info, never the message",
         %{buffer: buffer_name} do
      trace_id = Ecto.UUID.generate()
      span_id = Ecto.UUID.generate()
      opts = %{trace_id: trace_id, span_id: span_id, parent_id: nil}

      distinctive_message =
        "leak-guard-#{System.unique_integer([:positive])}-do-not-persist-this-detail"

      assert_raise RuntimeError, distinctive_message, fn ->
        Observe.span("tool", "t", opts, fn -> raise distinctive_message end)
      end

      span = flush_and_get(span_id, buffer_name)

      assert span.attributes["exception.type"] == "RuntimeError"
      assert span.attributes["error.type"] == "RuntimeError"

      assert_never_text(span.attributes)

      encoded = Jason.encode!(span.attributes)
      refute encoded =~ distinctive_message
    end
  end

  describe "Test 8: tenant_id double-write (D-00c)" do
    test "tenant_id lands in attributes AND drives a real ReviewerBroadcast fan-out", %{
      buffer: buffer_name
    } do
      tenant_id = "tenant-#{System.unique_integer([:positive])}"
      trace_id = Ecto.UUID.generate()
      span_id = Ecto.UUID.generate()

      Phoenix.PubSub.subscribe(Scoria.PubSub, ReviewerBroadcast.tenant_topic(tenant_id))

      opts = %{trace_id: trace_id, span_id: span_id, parent_id: nil, tenant_id: tenant_id}

      assert Observe.span("tool", "t", opts, fn -> :ok end) == :ok

      assert_receive {:trace_span, ^trace_id, _span_view}

      span = flush_and_get(span_id, buffer_name)
      assert span.attributes["tenant_id"] == tenant_id
    end
  end

  describe "Test 9: parent linkage" do
    test "parent_id persists exactly as given; nil roots the trace", %{buffer: buffer_name} do
      trace_id = Ecto.UUID.generate()
      parent_span_id = Ecto.UUID.generate()
      child_span_id = Ecto.UUID.generate()

      opts = %{trace_id: trace_id, span_id: child_span_id, parent_id: parent_span_id}
      Observe.span("tool", "t", opts, fn -> :ok end)

      child_span = flush_and_get(child_span_id, buffer_name)
      assert child_span.parent_id == parent_span_id

      root_span_id = Ecto.UUID.generate()
      root_opts = %{trace_id: trace_id, span_id: root_span_id, parent_id: nil}
      Observe.span("tool", "t", root_opts, fn -> :ok end)

      root_span = flush_and_get(root_span_id, buffer_name)
      assert root_span.parent_id == nil
    end
  end

  describe "Test 10: kind wrappers" do
    test "with_tool/3, with_prompt/3, with_guardrail/3 produce spans with the normalized kind and OpenInference mapping",
         %{buffer: buffer_name} do
      trace_id = Ecto.UUID.generate()

      tool_span_id = Ecto.UUID.generate()
      tool_opts = %{trace_id: trace_id, span_id: tool_span_id, parent_id: nil}

      assert Observe.with_tool("t", tool_opts, fn -> :ok end) == :ok
      tool_span = flush_and_get(tool_span_id, buffer_name)
      assert tool_span.span_kind == SpanKind.normalize("tool")

      assert tool_span.attributes[Semconv.openinference_span_kind_key()] ==
               SpanKind.to_openinference("tool")

      prompt_span_id = Ecto.UUID.generate()
      prompt_opts = %{trace_id: trace_id, span_id: prompt_span_id, parent_id: nil}

      assert Observe.with_prompt("p", prompt_opts, fn -> :ok end) == :ok
      prompt_span = flush_and_get(prompt_span_id, buffer_name)
      assert prompt_span.span_kind == SpanKind.normalize("prompt")

      assert prompt_span.attributes[Semconv.openinference_span_kind_key()] ==
               SpanKind.to_openinference("prompt")

      guardrail_span_id = Ecto.UUID.generate()
      guardrail_opts = %{trace_id: trace_id, span_id: guardrail_span_id, parent_id: nil}

      assert Observe.with_guardrail("g", guardrail_opts, fn -> :ok end) == :ok
      guardrail_span = flush_and_get(guardrail_span_id, buffer_name)
      assert guardrail_span.span_kind == SpanKind.normalize("guardrail")

      assert guardrail_span.attributes[Semconv.openinference_span_kind_key()] ==
               SpanKind.to_openinference("guardrail")
    end
  end

  describe "Test 11: emit_retriever_span/1 and emit_prompt_span/1 contract preservation (D-ATTR02-1)" do
    test "emit_retriever_span/1 still returns :ok and carries all three retrieval_config_keys/0 values",
         %{buffer: buffer_name} do
      span_id = Ecto.UUID.generate()

      assert :ok =
               Observe.emit_retriever_span(%{
                 config_map: %{embedding_model: "m", index_version: "v1", reranker: "r"},
                 host_metadata: %{feature: "support-copilot"},
                 trace_id: Ecto.UUID.generate(),
                 span_id: span_id,
                 parent_id: nil,
                 started_wall: DateTime.utc_now()
               })

      span = flush_and_get(span_id, buffer_name)

      for {_field, key} <- Semconv.retrieval_config_keys() do
        assert Map.has_key?(span.attributes, key)
      end

      assert span.attributes["scoria.retrieval.embedding_model"] == "m"
      assert span.attributes["scoria.retrieval.index_version"] == "v1"
      assert span.attributes["scoria.retrieval.reranker"] == "r"
    end

    test "emit_prompt_span/1 still returns :ok and carries scoria.prompt.context for a non-empty pack",
         %{buffer: buffer_name} do
      span_id = Ecto.UUID.generate()

      pack = %{
        chunks: [%{id: "c1", tokens: 10}],
        memories: [],
        token_budget: %{total: 10, chunks: 10, memories: 0, overhead: 0}
      }

      assert :ok =
               Observe.emit_prompt_span(%{
                 trace_id: Ecto.UUID.generate(),
                 span_id: span_id,
                 context_pack: pack
               })

      span = flush_and_get(span_id, buffer_name)
      assert span.attributes[Semconv.prompt_context_key()] == Semconv.prompt_context(pack)
    end
  end
end
