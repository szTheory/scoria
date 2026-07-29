defmodule Scoria.Observe.PromptSpanTest do
  @moduledoc """
  SC#4 acceptance test (52-06): a REAL `Scoria.Observe.emit_prompt_span/1`
  emission — through the actual telemetry -> `Telemetry.handle_event/4` ->
  `Buffer.cast_span/2` -> `Buffer.flush_now/1` pipeline against real
  Postgres — persists an `ai_spans` row whose attributes carry the nested
  `scoria.prompt.context` composition map coexisting with
  `gen_ai.usage.input_tokens` (D-ATTR02-7). Also proves ATTR-01 host-key
  pass-through on the prompt span, `input_tokens`-absence tolerance
  (D-ATTR02-5), and the never-text structural guarantee (D-ATTR02-4)
  end-to-end on the persisted value.

  Mirrors the DB-backed setup pattern from `telemetry_test.exs` (real
  sandbox checkout, a scoped supervised `Buffer`, detach/attach the shared
  `Scoria.Observe.Telemetry` handler onto that scoped buffer name) rather
  than hand-synthesizing a span (D-ATTR01-6).
  """

  use ExUnit.Case, async: false

  alias Scoria.Observe
  alias Scoria.Observe.Buffer
  alias Scoria.Observe.Semconv
  alias Scoria.Repo
  alias Scoria.Repo.Span

  @never_text_key_regex ~r/text|content|body|message|prompt|raw/i

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    buffer_name = :"prompt_span_test_buffer_#{System.unique_integer([:positive])}"

    pid =
      start_supervised!(
        Supervisor.child_spec(
          {Buffer, [name: buffer_name, flush_interval: 10_000, max_size: 100]},
          id: buffer_name
        )
      )

    # Real production wiring, not a hand-synthesized :telemetry.execute call
    # (D-ATTR01-6): detach the default-named handler and re-attach it onto
    # this test's scoped buffer, exactly as telemetry_test.exs does.
    :telemetry.detach("scoria-observe-telemetry")
    Scoria.Observe.Telemetry.attach(buffer_name)

    on_exit(fn -> :telemetry.detach("scoria-observe-telemetry") end)

    %{buffer: buffer_name, buffer_pid: pid}
  end

  defp populated_context_pack do
    %{
      chunks: [
        %{id: Ecto.UUID.generate(), tokens: 128},
        %{id: Ecto.UUID.generate(), tokens: 96}
      ],
      memories: [%{id: Ecto.UUID.generate(), tokens: 64}],
      token_budget: %{total: 2048, chunks: 224, memories: 64, overhead: 1760}
    }
  end

  # Calls the real emit_prompt_span/1, flushes the scoped buffer
  # synchronously (no Process.sleep race against the timer, D-08), and
  # loads the persisted span back from Postgres.
  defp emit_and_flush(opts, buffer_name) do
    trace_id = opts[:trace_id] || Ecto.UUID.generate()
    span_id = opts[:span_id] || Ecto.UUID.generate()

    :ok =
      opts
      |> Map.merge(%{trace_id: trace_id, span_id: span_id})
      |> Observe.emit_prompt_span()

    :ok = Buffer.flush_now(buffer_name)

    Repo.get_by!(Span, id: span_id)
  end

  describe "SC#4: populated context_pack coexists with gen_ai.usage.input_tokens" do
    test "persisted span attributes carry both scoria.prompt.context and gen_ai.usage.input_tokens", %{
      buffer: buffer_name
    } do
      pack = populated_context_pack()

      span = emit_and_flush(%{context_pack: pack, input_tokens: 1900, parent_id: nil}, buffer_name)

      assert span.attributes[Semconv.prompt_context_key()] == Semconv.prompt_context(pack)
      assert span.attributes["gen_ai.usage.input_tokens"] == 1900
    end

    test "the persisted composition value carries only IDs and counts (never-text, end-to-end)", %{
      buffer: buffer_name
    } do
      pack = populated_context_pack()

      span = emit_and_flush(%{context_pack: pack, input_tokens: 500}, buffer_name)

      composition = span.attributes[Semconv.prompt_context_key()]
      assert composition

      assert_never_text(composition)

      for item <- composition["chunks"] ++ composition["memories"] do
        assert Enum.sort(Map.keys(item)) == ["id", "tokens"]
      end
    end
  end

  describe "ATTR-01: host-declared keys on a real prompt-span emission (D-ATTR01-6)" do
    test "a non-deny-listed host feature value passes byte-for-byte; an omitted host key is absent", %{
      buffer: buffer_name
    } do
      span = emit_and_flush(%{feature: "support-copilot"}, buffer_name)

      assert span.attributes["feature"] == "support-copilot"
      refute Map.has_key?(span.attributes, "route")
      refute Map.has_key?(span.attributes, "archetype")
      refute Map.has_key?(span.attributes, "intent")
    end
  end

  describe "input_tokens absence tolerance (D-ATTR02-5)" do
    test "populated pack, no input_tokens: prompt-context persists and the usage key is absent", %{
      buffer: buffer_name
    } do
      pack = populated_context_pack()

      span = emit_and_flush(%{context_pack: pack}, buffer_name)

      assert span.attributes[Semconv.prompt_context_key()] == Semconv.prompt_context(pack)
      refute Map.has_key?(span.attributes, "gen_ai.usage.input_tokens")
    end
  end

  describe "empty-pack omit (D-ATTR02-7)" do
    test "no context_pack: scoria.prompt.context is absent from the persisted span", %{buffer: buffer_name} do
      span = emit_and_flush(%{input_tokens: 42}, buffer_name)

      refute Map.has_key?(span.attributes, Semconv.prompt_context_key())
      assert span.attributes["gen_ai.usage.input_tokens"] == 42
    end
  end

  # Recursively walks the persisted composition value: no key may match the
  # never-text guard regex, and every leaf must be a non-empty binary (an
  # ID) or a non-negative integer (D-ATTR02-4).
  defp assert_never_text(value) when is_map(value) do
    for {k, v} <- value do
      refute k =~ @never_text_key_regex, "forbidden key #{inspect(k)} matched the never-text guard"
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
