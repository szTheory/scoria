defmodule Scoria.Observe.ConformanceTest do
  @moduledoc """
  DOCS-02 falsifiable conformance check (Phase 54 Plan 02): drives all three
  span-emitting adapters (ReqLLM, MCP, Jido) live, captures the emit-layer
  span at `[:scoria, :observe, :span, :stop]` (the `req_llm_test.exs`
  capture idiom), then replays the exact production pipeline
  (`Redactor.redact/1` then `Bounds.enforce/2`, `telemetry.ex:69-71`)
  in-test to derive the post-`Bounds` "record of truth" -- exactly what
  `Buffer.cast_span/2` would persist to the host's Postgres. No DB, no
  Sandbox, no golden fixture, no hand-copied allow-list (D-04/D-05/D-07).

  Deliberately scoped to the 3 adapter-reachable `span_kind` values
  (`"llm"`/`"mcp"`/`"tool"`) per D-06's corrected scoping -- the other 5
  `SpanKind.kinds()` values are emitted elsewhere (`Workflows.Runtime`,
  `Knowledge`, `JudgeRunner`), out of scope for an adapter-level check.
  """

  # async: false — this module attaches a node-global `:telemetry` handler on
  # `[:scoria, :observe, :span, :stop]`; running concurrently with other async
  # modules would let `assert_receive` capture their spans and flake RED (WR-01).
  use ExUnit.Case, async: false

  @moduletag :conformance

  alias Scoria.Observe.Adapters.Jido
  alias Scoria.Observe.Adapters.ReqLLM
  alias Scoria.Observe.Bounds
  alias Scoria.Observe.Redactor
  alias Scoria.Observe.Semconv
  alias Scoria.Observe.SpanKind

  @handler_id "scoria-observe-telemetry-test-conformance"

  setup do
    :telemetry.detach(@handler_id)

    parent = self()

    :telemetry.attach(
      @handler_id,
      [:scoria, :observe, :span, :stop],
      fn _name, _measurements, metadata, _config -> send(parent, {:span, metadata}) end,
      nil
    )

    on_exit(fn -> :telemetry.detach(@handler_id) end)

    case ReqLLM.attach() do
      :ok -> :ok
      {:error, :already_exists} -> :ok
    end

    case Jido.attach() do
      :ok -> :ok
      {:error, :already_exists} -> :ok
    end

    # The MCP adapter's handler ("scoria-observe-mcp") is attached once at
    # Scoria.Application boot -- fire its upstream events directly, never
    # re-attach it here.

    :ok
  end

  # -- capture + record-of-truth helpers --------------------------------

  defp capture_span(event, metadata) do
    :telemetry.execute(event, %{}, metadata)
    assert_receive {:span, span}
    span
  end

  defp capture_span(event, measurements, metadata) do
    :telemetry.execute(event, measurements, metadata)
    assert_receive {:span, span}
    span
  end

  # Replays telemetry.ex:69-71's exact production order in-test:
  # Redactor.redact/1 |> Bounds.enforce(:span). `bounded` is byte-identical
  # to what Buffer.cast_span/2 would persist to the host's Postgres.
  defp record_of_truth(raw_span) do
    {:ok, bounded} = raw_span |> Redactor.redact() |> Bounds.enforce(:span)
    bounded
  end

  # -- fixtures per adapter ----------------------------------------------

  # Realistic %LLMDB.Model{} fixture -- NOT a bare string, mirroring
  # req_llm_test.exs's proven-good fixture (RESEARCH.md Pitfall 1).
  defp req_llm_metadata(overrides \\ %{}) do
    %{
      model: LLMDB.Model.new!(%{id: "gpt-5", provider: :openai}),
      provider: :openai,
      operation: :chat,
      trace_id: Ecto.UUID.generate(),
      tenant_id: "tenant-conformance",
      workflow_run_id: "run-conformance",
      request_options: %{
        temperature: 0.7,
        top_p: 0.9,
        max_tokens: 512,
        seed: 42
      },
      usage: %{input_tokens: 150, output_tokens: 42}
    }
    |> Map.merge(overrides)
  end

  # Mirrors mcp_test.exs's realistic_tool_metadata/1 fixture shape.
  defp mcp_metadata(overrides \\ %{}) do
    %{
      tool: Scoria.Observe.ConformanceTest.FixtureTool,
      tool_ref: inspect(Scoria.Observe.ConformanceTest.FixtureTool),
      args: %{"query" => "hello"},
      tenant_id: "tenant-conformance",
      trace_id: Ecto.UUID.generate(),
      parent_id: Ecto.UUID.generate()
    }
    |> Map.merge(overrides)
  end

  defp jido_metadata(overrides \\ %{}) do
    %{
      action_name: "conformance_action",
      status: "ok",
      tenant_id: "tenant-conformance",
      workflow_run_id: "run-conformance",
      trace_id: Ecto.UUID.generate()
    }
    |> Map.merge(overrides)
  end

  defp ms(millis), do: System.convert_time_unit(millis, :millisecond, :native)

  # -- shared conformance assertion ---------------------------------------

  # Every surviving key in `bounded.attributes` is SSOT-admitted because it
  # survived Bounds.enforce/2 (the direct-call proof, D-05 corrected). The
  # per-key loop below is belt-and-suspenders (RESEARCH.md's "Allow-list
  # membership assertion") -- it does NOT re-derive the admission rule, it
  # sanity-checks that no key slipped through some path outside the
  # documented admission tiers.
  defp assert_conforms(bounded, adapter_name) do
    assert SpanKind.kind?(bounded.span_kind),
           "#{adapter_name}: span_kind #{inspect(bounded.span_kind)} is not in SpanKind.kinds()"

    assert bounded.span_kind in SpanKind.kinds()

    assert bounded.attributes[Semconv.openinference_span_kind_key()] ==
             SpanKind.to_openinference(bounded.span_kind),
           "#{adapter_name}: openinference.span.kind mirror does not match SpanKind.to_openinference/1"

    for {key, _value} <- bounded.attributes do
      assert ssot_admitted?(key),
             "#{adapter_name}: unexpected surviving key #{inspect(key)} for span_kind " <>
               "#{inspect(bounded.span_kind)} -- Bounds.enforce/2 should have dropped this"
    end
  end

  defp ssot_admitted?(key) do
    Map.has_key?(Semconv.attribute_registry(), key) or
      Enum.any?(Semconv.vendor_key_prefixes(), &String.starts_with?(key, &1))
  end

  # -- Task 1: per-adapter record-of-truth conformance --------------------

  describe "record-of-truth conformance: ReqLLM adapter (llm)" do
    test "every surviving key is SSOT-admitted, span_kind is whitelisted, OI mirror matches" do
      raw = capture_span([:req_llm, :request, :stop], req_llm_metadata())
      bounded = record_of_truth(raw)

      assert bounded.span_kind == "llm"
      assert_conforms(bounded, "req_llm")
    end
  end

  describe "record-of-truth conformance: MCP adapter (mcp)" do
    test "completed event: every surviving key is SSOT-admitted, span_kind is whitelisted, OI mirror matches" do
      raw =
        capture_span(
          [:scoria, :tool, :completed],
          %{duration: ms(42)},
          mcp_metadata()
        )

      bounded = record_of_truth(raw)

      assert bounded.span_kind == "mcp"
      assert_conforms(bounded, "mcp")
    end

    test "timeout event: still conforms (ERROR path, D-06 non-empty corpus)" do
      raw =
        capture_span(
          [:scoria, :tool, :timeout],
          %{duration: ms(75)},
          mcp_metadata()
        )

      bounded = record_of_truth(raw)

      assert bounded.span_kind == "mcp"
      assert_conforms(bounded, "mcp")
    end
  end

  describe "record-of-truth conformance: Jido adapter (tool)" do
    test "every surviving key is SSOT-admitted, span_kind is whitelisted, OI mirror matches" do
      raw = capture_span([:jido, :action, :stop], %{duration: 10}, jido_metadata())
      bounded = record_of_truth(raw)

      assert bounded.span_kind == "tool"
      assert_conforms(bounded, "jido")
    end
  end

  # -- D-06: exhaustiveness + non-empty corpus, scoped to adapter-reachable kinds --

  describe "D-06: exhaustiveness + non-empty corpus, scoped to adapter-reachable kinds" do
    test "the observed default span_kind for each adapter is exactly llm/mcp/tool, corpus non-empty per adapter" do
      req_llm_span =
        record_of_truth(capture_span([:req_llm, :request, :stop], req_llm_metadata()))

      mcp_span =
        record_of_truth(
          capture_span([:scoria, :tool, :completed], %{duration: ms(10)}, mcp_metadata())
        )

      jido_span =
        record_of_truth(capture_span([:jido, :action, :stop], %{duration: 10}, jido_metadata()))

      corpus = %{"req_llm" => [req_llm_span], "mcp" => [mcp_span], "tool" => [jido_span]}

      for {adapter, spans} <- corpus do
        assert spans != [], "corpus for adapter #{adapter} must be non-empty"
      end

      observed_kinds =
        [req_llm_span, mcp_span, jido_span]
        |> Enum.map(& &1.span_kind)
        |> Enum.uniq()
        |> Enum.sort()

      # This is deliberately scoped to the 3 adapter-reachable kinds
      # (ReqLLM -> "llm", MCP -> "mcp", Jido -> "tool") per RESEARCH.md item
      # 4 / D-06 corrected scoping. The other 5 SpanKind.kinds() values
      # (agent/prompt/retriever/guardrail/eval) live in
      # Workflows.Runtime/Knowledge/JudgeRunner and are out of scope here.
      assert observed_kinds == Enum.sort(~w(llm mcp tool))

      for span <- [req_llm_span, mcp_span, jido_span] do
        assert SpanKind.kind?(span.span_kind)
      end
    end

    test "host-override probe: ReqLLM honors metadata[:span_kind] override end-to-end through Bounds/SpanKind" do
      raw = capture_span([:req_llm, :request, :stop], req_llm_metadata(%{span_kind: "agent"}))
      bounded = record_of_truth(raw)

      assert bounded.span_kind == "agent"
      assert SpanKind.kind?(bounded.span_kind)
      assert bounded.attributes[Semconv.openinference_span_kind_key()] == "AGENT"
    end
  end

  # -- Task 2: negative self-test (the guard must bite) -------------------
  #
  # Mirrors span_kind_test.exs:132-148's "guard must bite" fallback proof
  # shape: feed a deliberately bogus key/kind through the SAME
  # Bounds.enforce/2 / SpanKind.kind?/1 calls the positive tests use, and
  # assert the guard visibly bites -- proving the check would go RED on
  # real drift, not merely that it doesn't crash.

  describe "negative self-test: the guard must bite" do
    test "a bogus attribute key is dropped by Bounds.enforce/2 (not silently admitted)" do
      raw = %{
        id: Ecto.UUID.generate(),
        span_kind: "llm",
        attributes: %{"totally.not.allowed" => "leaked-value"}
      }

      bounded = record_of_truth(raw)

      refute Map.has_key?(bounded.attributes, "totally.not.allowed"),
             "Bounds.enforce/2 admitted a bogus key #{inspect("totally.not.allowed")} for adapter fixture -- the guard failed to bite"
    end

    test "a bogus span_kind is SpanKind.kind?/1-false (not silently whitelisted)" do
      refute SpanKind.kind?("not_a_kind"),
             "SpanKind.kind?/1 incorrectly admitted bogus span_kind #{inspect("not_a_kind")} -- the guard failed to bite"
    end
  end

  # -- Task 2: D-07 dropped-key classification (secondary bite) -----------
  #
  # Computes the pre-Bounds vs post-Bounds attribute-key difference for the
  # jido corpus and asserts the dropped set is a SUBSET of the documented
  # drop-list (jido.action_name, jido.status) -- so a NEW silently-dropped
  # key becomes a loud failure instead of silently passing (RESEARCH.md
  # item 8).

  @jido_documented_drop_list ~w(jido.action_name jido.status)

  describe "D-07 dropped-key classification: jido's silently-dropped keys are the documented set" do
    test "the pre-Bounds minus post-Bounds key difference for jido is a subset of the documented drop-list" do
      raw = capture_span([:jido, :action, :stop], %{duration: 10}, jido_metadata())
      redacted = Redactor.redact(raw)
      {:ok, bounded} = Bounds.enforce(redacted, :span)

      pre_keys = redacted.attributes |> Map.keys() |> MapSet.new()
      post_keys = bounded.attributes |> Map.keys() |> MapSet.new()
      dropped = MapSet.difference(pre_keys, post_keys)

      for key <- dropped do
        assert key in @jido_documented_drop_list,
               "jido adapter: unexpectedly dropped key #{inspect(key)} not in the documented drop-list #{inspect(@jido_documented_drop_list)}"
      end

      assert MapSet.subset?(MapSet.new(@jido_documented_drop_list), dropped),
             "expected jido's known raw vendor keys #{inspect(@jido_documented_drop_list)} to actually be dropped by Bounds.enforce/2"
    end
  end
end
