defmodule Scoria.Observe.BoundsTest do
  @moduledoc """
  SEC-01 full surface (plan 53-04): `Scoria.Observe.Bounds.enforce/2` is the
  single write-time choke point that enforces the closed key registry (plan
  53-02) plus size/count/depth caps, and fails closed on any input it
  cannot make sense of.

  Two blocks live in this one file per plan 53-04's action instruction:
  pure-unit tests of `enforce/2` (Tests 1-10, 13, 14 -- no Postgres) and
  real-pipeline acceptance tests (Tests 11, 12 -- real Buffer + real
  `Telemetry.attach/1`, the `prompt_span_test.exs` scaffold). The acceptance
  block needs real Postgres + the global `:telemetry` handler registry, so
  the whole module runs `async: false` (ExUnit's `async:` flag is
  module-wide, not per-`describe`) -- the pure-unit tests are simply not
  maximally parallel as a result, which is a performance-only tradeoff, not
  a correctness one.
  """

  use ExUnit.Case, async: false

  alias Scoria.Observe.Bounds
  alias Scoria.Observe.Buffer
  alias Scoria.Observe.Redactor
  alias Scoria.Observe.ReviewerBroadcast
  alias Scoria.Observe.Semconv
  alias Scoria.Repo
  alias Scoria.Repo.Span

  @never_text_key_regex ~r/text|content|body|message|prompt|raw/i

  # -- Pure-unit tests of enforce/2 (Tests 1-10, 13, 14) --------------------

  describe "Test 1: registry admission" do
    test "a registered key survives byte-for-byte; an unregistered bare key is dropped, not truncated" do
      metadata = %{
        attributes: %{"tenant_id" => "tenant-abc", "my_random_key" => "should be dropped"}
      }

      assert {:ok, bounded} = Bounds.enforce(metadata, :span)
      assert bounded.attributes["tenant_id"] == "tenant-abc"
      refute Map.has_key?(bounded.attributes, "my_random_key")
    end
  end

  describe "Test 2: drop-not-truncate (D-06e)" do
    test "an unregistered key's 100-byte value is absent from the output, never truncated" do
      long_value = String.duplicate("x", 100)
      metadata = %{attributes: %{"unregistered" => long_value}}

      assert {:ok, bounded} = Bounds.enforce(metadata, :span)
      assert Map.has_key?(bounded.attributes, "unregistered") == false
    end
  end

  describe "Test 3: EXACT dot-segment matching (D-06c-2)" do
    test "args_fingerprint / gen_ai.usage.input_tokens / gen_ai.output.type survive; gen_ai.input.messages is dropped" do
      metadata = %{
        attributes: %{
          "args_fingerprint" => "fp-123",
          "gen_ai.usage.input_tokens" => 150,
          "gen_ai.output.type" => "text",
          "gen_ai.input.messages" => [%{"role" => "user", "content" => "leaked prompt"}]
        }
      }

      assert {:ok, bounded} = Bounds.enforce(metadata, :span)

      # args_fingerprint is a REGISTRY key -- it contains the denied segment
      # "args" only as a SUBSTRING, never as a dot-segment. A substring-match
      # denylist (String.contains?/2 or a whole-key regex) would drop this
      # and break the MCP tool span's args_fingerprint field (D-04b).
      assert bounded.attributes["args_fingerprint"] == "fp-123"

      # vendor-prefixed, no dot-segment equals a denied segment
      assert bounded.attributes["gen_ai.usage.input_tokens"] == 150
      assert bounded.attributes["gen_ai.output.type"] == "text"

      # final dot-segment is EXACTLY "messages" -- denied
      refute Map.has_key?(bounded.attributes, "gen_ai.input.messages")
    end
  end

  describe "Test 4: req_llm exact-key denylist (D-06c-3)" do
    test "all four req_llm content-promotion keys are dropped" do
      metadata = %{
        attributes: %{
          "gen_ai.input.messages" => "leak",
          "gen_ai.output.messages" => "leak",
          # Segment-only denial provably MISSES these two: their final
          # dot-segments are "system_instructions" / "definitions", not
          # "messages" -- only the exact-key denylist catches them.
          "gen_ai.system_instructions" => "leak",
          "gen_ai.tool.definitions" => "leak"
        }
      }

      assert {:ok, bounded} = Bounds.enforce(metadata, :span)

      refute Map.has_key?(bounded.attributes, "gen_ai.input.messages")
      refute Map.has_key?(bounded.attributes, "gen_ai.output.messages")
      refute Map.has_key?(bounded.attributes, "gen_ai.system_instructions")
      refute Map.has_key?(bounded.attributes, "gen_ai.tool.definitions")
    end
  end

  describe "Test 5: version-pinned req_llm canary (D-06c-3)" do
    test "the req_llm ~> 1.13 attribute-builder key set contains no denied_exact_keys/0 member" do
      # Realistic [:req_llm, :request, :stop]-shaped metadata (mirrors
      # test/scoria/observe/adapters/req_llm_test.exs's realistic_metadata/1).
      metadata = %{
        model: LLMDB.Model.new!(%{id: "gpt-5", provider: :openai}),
        provider: :openai,
        operation: :chat,
        request_options: %{temperature: 0.7, top_p: 0.9, max_tokens: 512, seed: 42},
        usage: %{input_tokens: 150, output_tokens: 42}
      }

      actual_keys =
        (Map.keys(ReqLLM.OpenTelemetry.Attributes.start(metadata)) ++
           Map.keys(ReqLLM.OpenTelemetry.Attributes.terminal(metadata)))
        |> Enum.uniq()
        |> Enum.sort()

      # Pinned literal (req_llm ~> 1.13, locked at 1.13.0 in mix.lock,
      # verified against this exact metadata shape via `mix run` at
      # test-write time) -- NOT derived from ReqLLM.OpenTelemetry.Attributes
      # at runtime. A canary computed from the thing it guards guards
      # nothing (plan 53-04 D-06c-3). If a req_llm minor bump widens the
      # capture surface, this assertion goes RED.
      expected_keys = [
        "gen_ai.operation.name",
        "gen_ai.output.type",
        "gen_ai.provider.name",
        "gen_ai.request.max_tokens",
        "gen_ai.request.model",
        "gen_ai.request.seed",
        "gen_ai.request.temperature",
        "gen_ai.request.top_p",
        "gen_ai.usage.input_tokens",
        "gen_ai.usage.output_tokens"
      ]

      assert actual_keys == expected_keys

      denied = Semconv.denied_exact_keys()
      assert Enum.filter(actual_keys, &(&1 in denied)) == []
    end
  end

  describe "Test 6: fail-closed on a non-map input (D-06h)" do
    test "a bare atom, a struct, and nil all return :drop and never raise" do
      assert Bounds.enforce(:custom_mfa_called, :span) == :drop
      assert Bounds.enforce(%Span{}, :span) == :drop
      assert Bounds.enforce(nil, :span) == :drop
    end

    test "a drop on non-map input emits [:scoria, :observe, :bounds, :exceeded] telemetry" do
      :telemetry.attach(
        "bounds-test-nonmap-telemetry",
        [:scoria, :observe, :bounds, :exceeded],
        fn _name, measurements, metadata, _config ->
          send(self(), {:bounds_exceeded, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach("bounds-test-nonmap-telemetry") end)

      assert Bounds.enforce(:custom_mfa_called, :span) == :drop
      assert_receive {:bounds_exceeded, _measurements, _metadata}
    end
  end

  describe "Test 7: value truncation of an admitted key" do
    test "a registered key's 1000-byte value is truncated to max_attribute_bytes with a suffix, and appears in scoria.attributes.truncated_keys" do
      long_value = String.duplicate("a", 1000)
      metadata = %{attributes: %{"tenant_id" => long_value}}

      assert {:ok, bounded} = Bounds.enforce(metadata, :span)

      truncated = bounded.attributes["tenant_id"]
      assert String.ends_with?(truncated, "…[TRUNCATED]")
      assert byte_size(truncated) == 256 + byte_size("…[TRUNCATED]")
      assert "tenant_id" in bounded.attributes["scoria.attributes.truncated_keys"]
    end
  end

  describe "Test 8: count cap (max_attribute_count)" do
    test "200 admitted keys are capped at 128, dropped in deterministic sorted-key order" do
      attrs =
        for i <- 1..200, into: %{} do
          padded = String.pad_leading(Integer.to_string(i), 3, "0")
          {"gen_ai.custom.key_#{padded}", "v#{i}"}
        end

      metadata = %{attributes: attrs}

      assert {:ok, bounded} = Bounds.enforce(metadata, :span)

      admitted_keys =
        bounded.attributes
        |> Map.keys()
        |> Enum.reject(&String.starts_with?(&1, "scoria.attributes."))

      assert length(admitted_keys) == 128
      assert bounded.attributes["scoria.attributes.dropped"] == 200 - 128
      assert length(bounded.attributes["scoria.attributes.dropped_keys"]) <= 10

      assert Enum.all?(bounded.attributes["scoria.attributes.dropped_keys"], fn key ->
               byte_size(key) <= 64
             end)

      # deterministic: keeps the alphabetically-first 128 keys
      assert Enum.sort(admitted_keys) == attrs |> Map.keys() |> Enum.sort() |> Enum.take(128)
    end
  end

  describe "Test 9: Phase 52 regression -- feature/route/archetype/intent value hygiene" do
    test "host-declared values pass through enforce/2 BYTE-FOR-BYTE unchanged" do
      metadata = %{
        attributes: %{
          "feature" => "support-copilot",
          "route" => "/tickets/:id",
          "archetype" => "agentic-tool-use",
          "intent" => "resolve-ticket"
        }
      }

      assert {:ok, bounded} = Bounds.enforce(metadata, :span)

      assert bounded.attributes["feature"] == "support-copilot"
      assert bounded.attributes["route"] == "/tickets/:id"
      assert bounded.attributes["archetype"] == "agentic-tool-use"
      assert bounded.attributes["intent"] == "resolve-ticket"
    end
  end

  describe "Test 10: the full Phase 52 100-chunk + 100-memory pack survives intact (D-06d)" do
    test "no clipping, stays under max_total_bytes, never-text leaf-asserted" do
      pack = %{
        chunks: for(i <- 1..100, do: %{id: "chunk-#{i}", tokens: 50}),
        memories: for(i <- 1..100, do: %{id: "memory-#{i}", tokens: 30}),
        token_budget: %{total: 8000, chunks: 5000, memories: 3000, overhead: 0}
      }

      context_value = Semconv.prompt_context(pack)
      metadata = %{attributes: %{Semconv.prompt_context_key() => context_value}}

      assert {:ok, bounded} = Bounds.enforce(metadata, :span)

      # byte-for-byte -- no clipping. max_depth (5) and max_list_length (100)
      # do not clip it: it needs depth 3 and exactly 100 items.
      assert bounded.attributes[Semconv.prompt_context_key()] == context_value
      refute Map.has_key?(bounded.attributes[Semconv.prompt_context_key()], "truncated")

      # 16 KB not 8 KB: Phase 52's D-ATTR02-4 already asserts the
      # prompt-context value alone can reach 8 KB -- an 8 KB whole-map
      # budget would truncate a full pack and regress Phase 52 SC#4.
      assert byte_size(Jason.encode!(bounded.attributes)) < 16_384

      assert_never_text(bounded.attributes[Semconv.prompt_context_key()])
    end
  end

  describe "Test 13: the :event arm is built and unit-tested (activated in Phase 53b, D-06i)" do
    test "enforce(metadata, :event) returns {:ok, bounded} and applies the same registry admission" do
      metadata = %{attributes: %{"tenant_id" => "t1", "my_random_key" => "drop me"}}

      assert {:ok, bounded} = Bounds.enforce(metadata, :event)
      assert bounded.attributes["tenant_id"] == "t1"
      refute Map.has_key?(bounded.attributes, "my_random_key")
    end
  end

  describe "Test 14: observability on drop/truncate (D-06f)" do
    test "a drop emits [:scoria, :observe, :bounds, :exceeded] with counts, a reason, and the dropped key NAMES" do
      :telemetry.attach(
        "bounds-test-observability",
        [:scoria, :observe, :bounds, :exceeded],
        fn _name, measurements, metadata, _config ->
          send(self(), {:bounds_exceeded, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach("bounds-test-observability") end)

      metadata = %{attributes: %{"my_random_key" => "drop me"}}

      assert {:ok, _bounded} = Bounds.enforce(metadata, :span)

      assert_receive {:bounds_exceeded, measurements, meta}
      assert measurements.dropped_count >= 1
      assert meta.reason
      assert "my_random_key" in meta.keys
      assert meta.kind == :span
    end
  end

  # -- Real-pipeline acceptance tests (Tests 11, 12) -------------------------

  describe "Tests 11-12: real-pipeline acceptance (bound BEFORE broadcast, :drop short-circuits both sinks)" do
    setup do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

      buffer_name = :"bounds_test_buffer_#{System.unique_integer([:positive])}"

      pid =
        start_supervised!(
          Supervisor.child_spec(
            {Buffer, [name: buffer_name, flush_interval: 10_000, max_size: 100]},
            id: buffer_name
          )
        )

      # Real production wiring, not a hand-synthesized :telemetry.execute call
      # as production evidence (D-ATTR01-6): detach the default-named handler
      # and re-attach it onto this test's scoped buffer, exactly as
      # prompt_span_test.exs / plan 53-03's acceptance scaffold do. Re-attach
      # the default boot handler on exit (plan 53-01 attaches it at boot).
      :telemetry.detach("scoria-observe-telemetry")
      Scoria.Observe.Telemetry.attach(buffer_name)

      on_exit(fn ->
        :telemetry.detach("scoria-observe-telemetry")

        case Scoria.Observe.Telemetry.attach() do
          :ok -> :ok
          {:error, :already_exists} -> :ok
        end
      end)

      %{buffer: buffer_name}
    end

    test "Test 11 (T-53-03): an unregistered attribute key is bounded BEFORE the PubSub broadcast, not just before Buffer",
         %{buffer: buffer_name} do
      tenant_id = "tenant-bounds-#{System.unique_integer([:positive])}"
      trace_id = Ecto.UUID.generate()
      span_id = Ecto.UUID.generate()

      Phoenix.PubSub.subscribe(Scoria.PubSub, ReviewerBroadcast.tenant_topic(tenant_id))

      span = %{
        id: span_id,
        trace_id: trace_id,
        parent_id: nil,
        name: "bounds-broadcast-check",
        span_kind: "llm",
        status_code: "OK",
        start_time: DateTime.utc_now(),
        end_time: DateTime.utc_now(),
        tenant_id: tenant_id,
        attributes: %{"tenant_id" => tenant_id, "my_unregistered_key" => "leaked prompt text"}
      }

      :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)

      assert_receive {:trace_span, ^trace_id, span_view}
      refute Map.has_key?(span_view.attributes_preview, "my_unregistered_key")

      :ok = Buffer.flush_now(buffer_name)
      persisted = Repo.get_by!(Span, id: span_id)
      refute Map.has_key?(persisted.attributes, "my_unregistered_key")
    end

    test "Test 12: :drop short-circuits BOTH sinks -- no Postgres row and no PubSub message",
         %{buffer: buffer_name} do
      tenant_id = "tenant-bounds-drop-#{System.unique_integer([:positive])}"
      trace_id = Ecto.UUID.generate()
      span_id = Ecto.UUID.generate()

      # Drive the real D-06h fail-closed path: Redactor's :mfa config hook
      # (adopter-removable, redactor.ex:11-14) returns a non-map, which
      # Bounds.enforce/2 must fail closed on -- proving :drop reaches neither
      # sink, not just that redaction was replaced.
      Application.put_env(:scoria, Redactor, mfa: {__MODULE__, :fail_closed_redact, []})
      on_exit(fn -> Application.delete_env(:scoria, Redactor) end)

      Phoenix.PubSub.subscribe(Scoria.PubSub, ReviewerBroadcast.tenant_topic(tenant_id))

      span = %{
        id: span_id,
        trace_id: trace_id,
        parent_id: nil,
        name: "bounds-drop-check",
        span_kind: "llm",
        status_code: "OK",
        start_time: DateTime.utc_now(),
        end_time: DateTime.utc_now(),
        tenant_id: tenant_id,
        attributes: %{"tenant_id" => tenant_id}
      }

      :telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)

      refute_receive {:trace_span, ^trace_id, _}, 100
      refute_receive {:trace_opened, _}, 100

      :ok = Buffer.flush_now(buffer_name)
      refute Repo.get_by(Span, id: span_id)
    end
  end

  @doc false
  def fail_closed_redact(_data), do: :custom_mfa_called

  # Recursively walks a value: no key may match the never-text guard regex,
  # and every leaf must be a non-empty binary (an ID) or a non-negative
  # integer (D-ATTR02-4). Generalized from
  # test/scoria/observe/prompt_span_test.exs's assert_never_text/1 per
  # D-06b's INV-SEC01.
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
