defmodule Scoria.Observe.Adapters.MCPTest do
  @moduledoc """
  Phase 53 Plan 05 acceptance test (EVENT-01, SEC-01): drives the REAL
  `[:scoria, :tool, :started | :completed | :timeout | :failed]` events that
  `Scoria.MCP.Executor` emits (executor.ex:194,51,57,63,69), through the
  real `Scoria.Observe.Adapters.MCP.handle_event/4` ->
  `[:scoria, :observe, :span, :stop]` -> `Scoria.Observe.Telemetry.handle_event/4`
  -> `Scoria.Observe.Buffer.cast_span/2` -> Postgres pipeline. Deliberately
  does NOT hand-synthesize a `[:scoria, :observe, :span, :stop]` event --
  that would bypass the adapter under test and prove nothing (D-ATTR01-6).

  Mirrors the real-Postgres scoped-Buffer setup from `prompt_span_test.exs`
  (detach the shared `"scoria-observe-telemetry"` handler, re-attach it onto
  a scoped, test-local `Buffer`). `Scoria.Observe.Adapters.MCP` itself is
  attached once at `Scoria.Application` boot (`"scoria-observe-mcp"`,
  test_helper.exs starts `:scoria`) and is never detached/re-attached here
  -- its handler id is independent of which buffer `"scoria-observe-telemetry"`
  currently targets, so it stays live across every test in this file.
  """

  use ExUnit.Case, async: false

  alias Scoria.Observe.Buffer
  alias Scoria.Observe.Semconv
  alias Scoria.Repo
  alias Scoria.Repo.Span

  @never_text_key_regex ~r/text|content|body|message|prompt|raw/i

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    buffer_name = :"mcp_test_buffer_#{System.unique_integer([:positive])}"

    pid =
      start_supervised!(
        Supervisor.child_spec(
          {Buffer, [name: buffer_name, flush_interval: 10_000, max_size: 100]},
          id: buffer_name
        )
      )

    :telemetry.detach("scoria-observe-telemetry")
    Scoria.Observe.Telemetry.attach(buffer_name)

    on_exit(fn ->
      :telemetry.detach("scoria-observe-telemetry")

      case Scoria.Observe.Telemetry.attach() do
        :ok -> :ok
        {:error, :already_exists} -> :ok
      end
    end)

    %{buffer: buffer_name, buffer_pid: pid}
  end

  # Reproduces the exact metadata shape Scoria.MCP.Executor builds
  # (executor.ex:35-44) -- including the raw `args` and (on :failed) a raw
  # `reason` term -- because reproducing the leak vector faithfully is the
  # entire point of Tests 5 and 6.
  defp realistic_tool_metadata(overrides \\ %{}) do
    %{
      tool: Scoria.Observe.Adapters.MCPTest.FixtureTool,
      tool_ref: inspect(Scoria.Observe.Adapters.MCPTest.FixtureTool),
      args: %{"query" => "hello"},
      tenant_id: "tenant-#{System.unique_integer([:positive])}",
      trace_id: Ecto.UUID.generate(),
      parent_id: Ecto.UUID.generate()
    }
    |> Map.merge(overrides)
  end

  defp ms(millis), do: System.convert_time_unit(millis, :millisecond, :native)

  defp emit_and_flush(kind, duration_ms, metadata, buffer_name) do
    :telemetry.execute([:scoria, :tool, kind], %{duration: ms(duration_ms)}, metadata)
    :ok = Buffer.flush_now(buffer_name)
  end

  describe "Test 1: completed -> OK span with TOOL kind and real duration" do
    test "yields one persisted span with span_kind mcp -> TOOL, status_code OK, duration_ms", %{
      buffer: buffer_name
    } do
      metadata = realistic_tool_metadata()
      emit_and_flush(:completed, 42, metadata, buffer_name)

      span = Repo.get_by!(Span, trace_id: metadata.trace_id)

      assert span.span_kind == "mcp"
      assert span.attributes[Semconv.openinference_span_kind_key()] == "TOOL"
      assert span.status_code == "OK"
      assert span.attributes["duration_ms"] == 42
    end
  end

  describe "Test 2: timeout -> ERROR span" do
    test "yields ERROR span with status timeout and a real duration", %{buffer: buffer_name} do
      metadata = realistic_tool_metadata()
      emit_and_flush(:timeout, 75, metadata, buffer_name)

      span = Repo.get_by!(Span, trace_id: metadata.trace_id)

      assert span.status_code == "ERROR"
      assert span.attributes["status"] == "timeout"
      assert span.attributes["duration_ms"] == 75
    end
  end

  describe "Test 3: failed -> ERROR span" do
    test "yields ERROR span with status failed", %{buffer: buffer_name} do
      metadata = realistic_tool_metadata(%{reason: :some_error})
      emit_and_flush(:failed, 10, metadata, buffer_name)

      span = Repo.get_by!(Span, trace_id: metadata.trace_id)

      assert span.status_code == "ERROR"
      assert span.attributes["status"] == "failed"
    end
  end

  describe "Test 4: started emits nothing" do
    test "a started event alone produces no persisted span", %{buffer: buffer_name} do
      metadata = realistic_tool_metadata()

      :telemetry.execute(
        [:scoria, :tool, :started],
        %{system_time: System.system_time()},
        metadata
      )

      :ok = Buffer.flush_now(buffer_name)

      refute Repo.get_by(Span, trace_id: metadata.trace_id)
    end
  end

  describe "Test 5: args are fingerprinted, never persisted (SEC-01)" do
    test "the raw args token never reaches the encoded attributes and no args key exists", %{
      buffer: buffer_name
    } do
      metadata =
        realistic_tool_metadata(%{
          args: %{"query" => "DISTINCTIVE_SECRET_TOKEN_9f3a", "user_email" => "a@b.test"}
        })

      emit_and_flush(:completed, 5, metadata, buffer_name)

      span = Repo.get_by!(Span, trace_id: metadata.trace_id)
      encoded = Jason.encode!(span.attributes)

      assert is_binary(span.attributes["args_fingerprint"])
      assert span.attributes["args_fingerprint"] != ""
      refute encoded =~ "DISTINCTIVE_SECRET_TOKEN_9f3a"
      refute Map.has_key?(span.attributes, "args")
    end
  end

  describe "Test 6: raw failure term is not persisted" do
    test "the raw failure term token never reaches the encoded attributes", %{buffer: buffer_name} do
      metadata =
        realistic_tool_metadata(%{
          reason: {:badmatch, %{"secret" => "DISTINCTIVE_FAILURE_TOKEN_7c1b"}}
        })

      emit_and_flush(:failed, 5, metadata, buffer_name)

      span = Repo.get_by!(Span, trace_id: metadata.trace_id)
      encoded = Jason.encode!(span.attributes)

      refute encoded =~ "DISTINCTIVE_FAILURE_TOKEN_7c1b"
      assert_never_text(span.attributes)
    end
  end

  describe "Test 7: fingerprint is stable and discriminating" do
    test "identical args produce the same fingerprint; different args produce a different one", %{
      buffer: buffer_name
    } do
      args = %{"a" => 1, "b" => 2}

      metadata1 = realistic_tool_metadata(%{args: args})
      emit_and_flush(:completed, 5, metadata1, buffer_name)
      span1 = Repo.get_by!(Span, trace_id: metadata1.trace_id)

      metadata2 = realistic_tool_metadata(%{args: args})
      emit_and_flush(:completed, 5, metadata2, buffer_name)
      span2 = Repo.get_by!(Span, trace_id: metadata2.trace_id)

      assert span1.attributes["args_fingerprint"] == span2.attributes["args_fingerprint"]

      metadata3 = realistic_tool_metadata(%{args: %{"a" => 999}})
      emit_and_flush(:completed, 5, metadata3, buffer_name)
      span3 = Repo.get_by!(Span, trace_id: metadata3.trace_id)

      assert span3.attributes["args_fingerprint"] != span1.attributes["args_fingerprint"]
    end
  end

  describe "Test 8: explicit linkage (D-02a)" do
    test "trace_id/parent_id/tenant_id metadata produces a span with exactly those values", %{
      buffer: buffer_name
    } do
      trace_id = Ecto.UUID.generate()
      parent_id = Ecto.UUID.generate()
      tenant_id = "tenant-explicit-#{System.unique_integer([:positive])}"

      metadata =
        realistic_tool_metadata(%{trace_id: trace_id, parent_id: parent_id, tenant_id: tenant_id})

      emit_and_flush(:completed, 5, metadata, buffer_name)

      span = Repo.get_by!(Span, trace_id: trace_id)

      assert span.parent_id == parent_id
      assert span.attributes["tenant_id"] == tenant_id
    end
  end

  describe "Test 9: boot attach" do
    test "Adapters.MCP.attach/0 called a second time returns {:error, :already_exists}, proving the boot call registered the handler id" do
      assert {:error, :already_exists} = Scoria.Observe.Adapters.MCP.attach()
    end
  end

  # Recursively walks a persisted attributes map: no key may match the
  # never-text guard regex, and every leaf must be a non-empty binary or a
  # non-negative integer (mirrors prompt_span_test.exs:150-171).
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
end
