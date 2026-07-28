defmodule Scoria.Observe.SemconvTest do
  use ExUnit.Case, async: true

  alias Scoria.Observe.Semconv

  describe "openinference_span_kind_key/0" do
    test "returns exactly \"openinference.span.kind\"" do
      assert Semconv.openinference_span_kind_key() == "openinference.span.kind"
    end
  end

  describe "merge_req_llm_attributes/2" do
    test "returns a map containing the core gen_ai.* request/usage keys" do
      metadata = %{
        model: LLMDB.Model.new!(%{id: "gpt-5", provider: :openai}),
        provider: :openai,
        operation: :chat,
        request_options: %{temperature: 0.7, top_p: 0.9, max_tokens: 512, seed: 42},
        usage: %{input_tokens: 150, output_tokens: 42}
      }

      merged = Semconv.merge_req_llm_attributes(%{}, metadata)

      assert Map.has_key?(merged, "gen_ai.request.model")
      assert Map.has_key?(merged, "gen_ai.request.temperature")
      assert Map.has_key?(merged, "gen_ai.request.top_p")
      assert Map.has_key?(merged, "gen_ai.request.max_tokens")
      assert Map.has_key?(merged, "gen_ai.request.seed")

      assert Enum.any?(Map.keys(merged), &String.starts_with?(&1, "gen_ai.usage."))
    end

    test "preserves caller-supplied base attributes" do
      metadata = %{
        model: LLMDB.Model.new!(%{id: "gpt-5", provider: :openai}),
        provider: :openai,
        operation: :chat
      }

      merged = Semconv.merge_req_llm_attributes(%{"tenant_id" => "t1"}, metadata)

      assert merged["tenant_id"] == "t1"
    end
  end

  describe "single-origin + delegation proof (SPAN-01 key-completeness at the Semconv layer)" do
    test "preserves base attrs and carries model-config + usage keys together, from a realistic %LLMDB.Model{}-shaped [:req_llm, :request, :stop] fixture" do
      metadata = %{
        model: LLMDB.Model.new!(%{id: "gpt-5", provider: :openai}),
        provider: :openai,
        operation: :chat,
        request_options: %{
          temperature: 0.7,
          top_p: 0.9,
          max_tokens: 512,
          seed: 42
        },
        usage: %{input_tokens: 150, output_tokens: 42}
      }

      merged = Semconv.merge_req_llm_attributes(%{"tenant_id" => "t1"}, metadata)

      # (a) caller-supplied base attributes preserved
      assert merged["tenant_id"] == "t1"

      # (b) all four model-config params present TOGETHER
      assert merged["gen_ai.request.model"] == "gpt-5"
      assert merged["gen_ai.request.temperature"] == 0.7
      assert merged["gen_ai.request.top_p"] == 0.9
      assert merged["gen_ai.request.max_tokens"] == 512
      assert merged["gen_ai.request.seed"] == 42

      # (c) a usage key is present
      assert merged["gen_ai.usage.input_tokens"] == 150
    end

    test "openinference_span_kind_key/0 returns the exact key string" do
      assert Semconv.openinference_span_kind_key() == "openinference.span.kind"
    end

    test "single-origin guard: semconv.ex source contains no hand-declared gen_ai.* literal" do
      source =
        "lib/scoria/observe/semconv.ex"
        |> Path.expand(File.cwd!())
        |> File.read!()

      refute source =~ ~r/"gen_ai\./,
             "semconv.ex must delegate to ReqLLM.OpenTelemetry.Attributes, never hand-write a gen_ai.* string literal"
    end
  end

  describe "retrieval_config_keys/0 + retrieval_config_attributes/1" do
    test "retrieval_config_keys/0 returns the exact canonical keyword list" do
      assert Semconv.retrieval_config_keys() == [
               embedding_model: "scoria.retrieval.embedding_model",
               index_version: "scoria.retrieval.index_version",
               reranker: "scoria.retrieval.reranker"
             ]
    end

    test "retrieval_config_attributes/1 on an empty map returns 3 keys, all sentinel \"none\"" do
      attrs = Semconv.retrieval_config_attributes(%{})

      assert map_size(attrs) == 3

      assert attrs == %{
               "scoria.retrieval.embedding_model" => "none",
               "scoria.retrieval.index_version" => "none",
               "scoria.retrieval.reranker" => "none"
             }
    end

    test "retrieval_config_attributes/1 projects supplied values onto the dotted keys" do
      attrs =
        Semconv.retrieval_config_attributes(%{
          embedding_model: "m",
          index_version: "v1",
          reranker: "r"
        })

      assert attrs == %{
               "scoria.retrieval.embedding_model" => "m",
               "scoria.retrieval.index_version" => "v1",
               "scoria.retrieval.reranker" => "r"
             }
    end

    test "anti-inline grep: no lib consumer file inlines the \"scoria.retrieval.\" literal" do
      consumer_files = [
        "lib/scoria/knowledge.ex",
        "lib/scoria/observe.ex",
        "lib/scoria/observe/adapters/req_llm.ex",
        "lib/scoria/observe/adapters/jido.ex"
      ]

      for path <- consumer_files, File.exists?(Path.expand(path, File.cwd!())) do
        source = path |> Path.expand(File.cwd!()) |> File.read!()

        refute source =~ "scoria.retrieval.",
               "#{path} must call Semconv.retrieval_config_keys/0, never inline a scoria.retrieval.* literal"
      end
    end
  end

  describe "host_declared_keys/0 + merge_host_declared/2" do
    test "host_declared_keys/0 returns exactly the four reserved dimensions" do
      assert Semconv.host_declared_keys() == [:feature, :route, :archetype, :intent]
    end

    test "merge_host_declared/2 on empty attrs and empty metadata returns %{} — never-default proof" do
      merged = Semconv.merge_host_declared(%{}, %{})

      assert merged == %{}

      for key <- Semconv.host_declared_keys() do
        refute Map.has_key?(merged, Atom.to_string(key))
      end
    end

    test "merge_host_declared/2 passes a present value through byte-for-byte, others absent" do
      merged = Semconv.merge_host_declared(%{}, %{feature: "support-copilot"})

      assert merged == %{"feature" => "support-copilot"}
      refute Map.has_key?(merged, "route")
      refute Map.has_key?(merged, "archetype")
      refute Map.has_key?(merged, "intent")
    end

    test "anti-inline grep: no lib consumer file inlines a reserved host-declared key literal" do
      consumer_files = [
        "lib/scoria/knowledge.ex",
        "lib/scoria/observe.ex",
        "lib/scoria/observe/adapters/req_llm.ex",
        "lib/scoria/observe/adapters/jido.ex"
      ]

      for path <- consumer_files, File.exists?(Path.expand(path, File.cwd!())) do
        source = path |> Path.expand(File.cwd!()) |> File.read!()

        for literal <- ~w("feature" "route" "archetype" "intent") do
          refute source =~ literal,
                 "#{path} must call Semconv.host_declared_keys/0 / merge_host_declared/2, never inline #{literal}"
        end
      end
    end
  end

  describe "prompt_context_key/0 + prompt_context/1" do
    test "prompt_context_key/0 returns the exact canonical key string" do
      assert Semconv.prompt_context_key() == "scoria.prompt.context"
    end

    test "never-text: chunk/memory items built from an over-sharing host item contain ONLY id/tokens" do
      built =
        Semconv.prompt_context(%{
          chunks: [%{id: "c1", tokens: 10, text: "leaked chunk body", content: "also leaked"}],
          memories: [%{id: "m1", tokens: 5, body: "leaked memory body"}],
          token_budget: %{total: 15, chunks: 10, memories: 5, overhead: 0}
        })

      assert [%{"id" => "c1", "tokens" => 10} = chunk_item] = built["chunks"]
      assert Map.keys(chunk_item) |> Enum.sort() == ["id", "tokens"]

      assert [%{"id" => "m1", "tokens" => 5} = memory_item] = built["memories"]
      assert Map.keys(memory_item) |> Enum.sort() == ["id", "tokens"]
    end

    test "structural guard: no key matches text/content/body/message/prompt/raw; leaves are bounded; encoded size <= 8KB" do
      built =
        Semconv.prompt_context(%{
          chunks: [%{id: "c1", tokens: 10}],
          memories: [%{id: "m1", tokens: 5}],
          token_budget: %{total: 15, chunks: 10, memories: 5, overhead: 0}
        })

      allowed_keys = ~w(chunks memories token_budget id tokens total overhead truncated)

      assert_only_allowed_keys(built, allowed_keys)

      encoded = Jason.encode!(built)
      assert byte_size(encoded) <= 8192
    end

    test "≤100-item cap: a 101-item chunk list is capped to 100 items with \"truncated\" => true" do
      chunks = for i <- 1..101, do: %{id: "c#{i}", tokens: 1}

      built =
        Semconv.prompt_context(%{
          chunks: chunks,
          memories: [],
          token_budget: %{total: 101, chunks: 101, memories: 0, overhead: 0}
        })

      assert length(built["chunks"]) == 100
      assert built["truncated"] == true
    end

    test "anti-inline grep: no lib consumer file inlines the \"scoria.prompt.context\" literal" do
      consumer_files = [
        "lib/scoria/knowledge.ex",
        "lib/scoria/observe.ex",
        "lib/scoria/observe/adapters/req_llm.ex",
        "lib/scoria/observe/adapters/jido.ex"
      ]

      for path <- consumer_files, File.exists?(Path.expand(path, File.cwd!())) do
        source = path |> Path.expand(File.cwd!()) |> File.read!()

        refute source =~ "scoria.prompt.context",
               "#{path} must call Semconv.prompt_context_key/0, never inline the scoria.prompt.context literal"
      end
    end
  end

  describe "merge_usage_input_tokens/2" do
    test "merges exactly the usage input-tokens key when input_tokens is present" do
      merged = Semconv.merge_usage_input_tokens(%{}, 1900)

      assert merged == %{"gen_ai.usage.input_tokens" => 1900}
    end

    test "preserves caller-supplied base attributes alongside the merged key" do
      merged = Semconv.merge_usage_input_tokens(%{"feature" => "support-copilot"}, 42)

      assert merged["feature"] == "support-copilot"
      assert merged["gen_ai.usage.input_tokens"] == 42
    end

    test "nil input_tokens is a no-op — tolerate absence, never assert unconditional presence" do
      assert Semconv.merge_usage_input_tokens(%{"a" => 1}, nil) == %{"a" => 1}
    end
  end

  describe "attribute_registry/0 registry canary (SEC-01 Test 1)" do
    test "returns exactly the pinned sorted key list — adding a key requires a deliberate edit here (D-06b)" do
      assert Semconv.attribute_registry() |> Map.keys() |> Enum.sort() == [
               "archetype",
               "args_fingerprint",
               "duration_ms",
               "error.type",
               "exception.type",
               "feature",
               "intent",
               "openinference.span.kind",
               "route",
               "scoria.attributes.dropped",
               "scoria.attributes.dropped_keys",
               "scoria.attributes.truncated_keys",
               "scoria.classification.action_class",
               "scoria.classification.can_exfiltrate",
               "scoria.classification.reads_private_data",
               "scoria.classification.sees_untrusted_content",
               "scoria.classification.source",
               "scoria.guardrail.decision",
               "scoria.guardrail.name",
               "scoria.guardrail.policy_key",
               "scoria.guardrail.reason_code",
               "scoria.guardrail.subject_ref",
               "scoria.prompt.context",
               "scoria.prompt.template_ref",
               "scoria.retrieval.embedding_model",
               "scoria.retrieval.index_version",
               "scoria.retrieval.reranker",
               "scoria.spotlight.marked_bytes",
               "scoria.spotlight.marked_spans",
               "scoria.spotlight.technique",
               "scoria.spotlight.tier",
               "scoria.trust.reason_code",
               "scoria.trust.scanned_count",
               "scoria.trust.scanner",
               "scoria.trust.tier",
               "session_id",
               "status",
               "tenant_id",
               "tool_name",
               "tool_ref",
               "workflow_run_id"
             ]
    end
  end

  describe "attribute_classes/0 exhaustiveness (SEC-01 Test 2)" do
    test "attribute_classes/0 is exactly the 6-member sorted closed vocabulary — a 7th class is the failure mode" do
      assert Semconv.attribute_classes() |> Enum.sort() ==
               [:count, :enum, :flag, :id, :structured, :timestamp]

      assert length(Semconv.attribute_classes()) == 6
    end

    test "every attribute_registry/0 value is a member of attribute_classes/0" do
      classes = Semconv.attribute_classes()

      for {key, class} <- Semconv.attribute_registry() do
        assert class in classes,
               "registry key #{inspect(key)} has class #{inspect(class)} outside attribute_classes/0"
      end
    end
  end

  describe "dashboard pre-seed (SEC-01 Test 3)" do
    test "the bare keys OrchestratorLive.build_hydrated_trace/2 reads are registry keys (D-06c-1)" do
      # OrchestratorLive.build_hydrated_trace/2 (lib/scoria_web/live/orchestrator_live.ex:237)
      # SQL-filters on attributes->>'tenant_id' and reads session_id/workflow_run_id bare
      # from attributes; Phase 52 host-declared keys (feature/route/archetype/intent)
      # render on the dashboard. Dropping any of these from the registry blanks the
      # operator dashboard once Bounds (plan 53-04) is enabled.
      for key <-
            ~w(tenant_id workflow_run_id session_id duration_ms feature route archetype intent) do
        assert Map.has_key?(Semconv.attribute_registry(), key),
               "missing dashboard-critical registry key #{inspect(key)}"
      end
    end
  end

  describe "Semconv-owned keys are registered (SEC-01 Test 4)" do
    test "openinference_span_kind_key/0, prompt_context_key/0, and retrieval_config_keys/0 values are all registry keys" do
      registry = Semconv.attribute_registry()

      assert Map.has_key?(registry, Semconv.openinference_span_kind_key())
      assert Map.has_key?(registry, Semconv.prompt_context_key())

      for {_field, key} <- Semconv.retrieval_config_keys() do
        assert Map.has_key?(registry, key),
               "missing registry entry for retrieval_config_keys/0 value #{inspect(key)}"
      end
    end
  end

  describe "guardrail enums (SEC-01 Test 5)" do
    test "guardrail_names/0 returns the exact 4-value closed list" do
      assert Semconv.guardrail_names() == ~w(release_gate approval_gate budget_gate breaker_gate)
    end

    test "guardrail_decisions/0 returns allow/block/escalate and does NOT contain \"modify\" (D-05h reserved)" do
      assert Semconv.guardrail_decisions() == ~w(allow block escalate)
      refute "modify" in Semconv.guardrail_decisions()
    end

    test "guardrail_reason_codes/0 returns the exact 6-value closed list (not invented — ReleaseGate/BreakerRegistry already return these)" do
      assert Semconv.guardrail_reason_codes() ==
               ~w(unapproved_draft eval_not_passing eval_required approval_required budget_rejected breaker_open)
    end
  end

  describe "normalize_reason_code/1 fallback (SEC-01 Test 6)" do
    test "an unrecognized reason_code normalizes to \"unknown\" and emits the fallback telemetry event" do
      handler_id = "test-guardrail-fallback-#{System.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        [:scoria, :observe, :guardrail, :fallback],
        fn name, meas, meta, pid -> send(pid, {:telemetry, name, meas, meta}) end,
        self()
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      assert Semconv.normalize_reason_code("something_new") == "unknown"

      assert_receive {:telemetry, [:scoria, :observe, :guardrail, :fallback], %{},
                      %{value: "something_new"}}
    end

    test "a recognized reason_code (atom input) round-trips to its string form with no fallback event" do
      handler_id = "test-guardrail-fallback-ok-#{System.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        [:scoria, :observe, :guardrail, :fallback],
        fn name, meas, meta, pid -> send(pid, {:telemetry, name, meas, meta}) end,
        self()
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      assert Semconv.normalize_reason_code(:unapproved_draft) == "unapproved_draft"
      refute_receive {:telemetry, [:scoria, :observe, :guardrail, :fallback], _meas, _meta}, 50
    end
  end

  describe "guardrail_attributes/1 fixed-key projection (SEC-01 Test 7)" do
    test "projects onto exactly the five scoria.guardrail.* keys, all registry keys, no extras" do
      registry = Semconv.attribute_registry()
      guardrail_key_strings = Semconv.guardrail_keys() |> Keyword.values() |> MapSet.new()

      input = %{
        name: "release_gate",
        decision: "block",
        reason_code: "unapproved_draft",
        subject_ref: "run-123",
        policy_key: "prompt-template-abc",
        not_a_registered_field: "should never appear on a span"
      }

      attrs = Semconv.guardrail_attributes(input)

      assert MapSet.new(Map.keys(attrs)) |> MapSet.subset?(guardrail_key_strings)
      assert map_size(attrs) == 5

      for key <- Map.keys(attrs) do
        assert Map.has_key?(registry, key),
               "guardrail_attributes/1 key #{inspect(key)} is not a registered attribute"
      end

      refute Enum.any?(Map.values(attrs), &(&1 == "should never appear on a span"))
    end
  end

  describe "spotlight_attributes/1 fixed-key projection (D-14)" do
    test "projects onto exactly the four scoria.spotlight.* keys, all registry keys, no extras" do
      registry = Semconv.attribute_registry()
      spotlight_key_strings = Semconv.spotlight_keys() |> Keyword.values() |> MapSet.new()

      input = %{
        technique: :datamark,
        marked_spans: 3,
        marked_bytes: 120,
        tier: "untrusted",
        not_a_registered_field: "should never appear on a span"
      }

      attrs = Semconv.spotlight_attributes(input)

      assert MapSet.new(Map.keys(attrs)) |> MapSet.subset?(spotlight_key_strings)
      assert map_size(attrs) == 4

      for key <- Map.keys(attrs) do
        assert Map.has_key?(registry, key),
               "spotlight_attributes/1 key #{inspect(key)} is not a registered attribute"
      end

      refute Enum.any?(Map.values(attrs), &(&1 == "should never appear on a span"))
    end

    test "a nil field is omitted, never defaulted (structural never-free-text guarantee)" do
      attrs = Semconv.spotlight_attributes(%{technique: :delimit, marked_spans: 1, marked_bytes: nil, tier: "untrusted"})

      refute Map.has_key?(attrs, "scoria.spotlight.marked_bytes")
      assert map_size(attrs) == 3
    end
  end

  describe "trust_attributes/1 fixed-key projection (D-21)" do
    test "projects onto exactly the four scoria.trust.* keys, all registry keys, no extras, and score is NEVER projected" do
      registry = Semconv.attribute_registry()
      trust_key_strings = Semconv.trust_keys() |> Keyword.values() |> MapSet.new()

      input = %{
        tier: "untrusted",
        scanner: "MyApp.PromptGuard",
        reason_code: :prompt_injection,
        scanned_count: 5,
        score: 0.987
      }

      attrs = Semconv.trust_attributes(input)

      assert MapSet.new(Map.keys(attrs)) |> MapSet.subset?(trust_key_strings)
      assert map_size(attrs) == 4

      for key <- Map.keys(attrs) do
        assert Map.has_key?(registry, key),
               "trust_attributes/1 key #{inspect(key)} is not a registered attribute"
      end

      refute Map.has_key?(attrs, "scoria.trust.score")
      refute Enum.any?(Map.values(attrs), &(&1 == 0.987))
    end

    test "a nil field is omitted, never defaulted (structural never-free-text guarantee)" do
      attrs =
        Semconv.trust_attributes(%{
          tier: "untrusted",
          scanner: "MyApp.PromptGuard",
          reason_code: nil,
          scanned_count: 3
        })

      refute Map.has_key?(attrs, "scoria.trust.reason_code")
      assert map_size(attrs) == 3
    end
  end

  describe "classification_keys/0 (phase 56, CLASS-02)" do
    test "returns the canonical five-entry keyword list mapped to scoria.classification.* strings" do
      assert Semconv.classification_keys() == [
               action_class: "scoria.classification.action_class",
               source: "scoria.classification.source",
               reads_private_data: "scoria.classification.reads_private_data",
               sees_untrusted_content: "scoria.classification.sees_untrusted_content",
               can_exfiltrate: "scoria.classification.can_exfiltrate"
             ]
    end
  end

  describe "classification_attributes/1 fixed-key projection (phase 56, CLASS-02)" do
    test "projects onto exactly the five scoria.classification.* keys, all registry keys, no extras" do
      registry = Semconv.attribute_registry()
      classification_key_strings = Semconv.classification_keys() |> Keyword.values() |> MapSet.new()

      input = %{
        action_class: "admin",
        source: "unclassified_default",
        reads_private_data: true,
        sees_untrusted_content: true,
        can_exfiltrate: true
      }

      attrs = Semconv.classification_attributes(input)

      assert MapSet.new(Map.keys(attrs)) |> MapSet.subset?(classification_key_strings)
      assert map_size(attrs) == 5

      for key <- Map.keys(attrs) do
        assert Map.has_key?(registry, key),
               "classification_attributes/1 key #{inspect(key)} is not a registered attribute"
      end
    end

    test "an unlisted extra field (e.g. score or reason) is ignored -- exactly five keys emitted" do
      attrs =
        Semconv.classification_attributes(%{
          action_class: "read",
          source: "tool_declared",
          reads_private_data: false,
          sees_untrusted_content: false,
          can_exfiltrate: false,
          score: 0.99,
          reason: "free text should never reach a span"
        })

      assert map_size(attrs) == 5
      refute Map.has_key?(attrs, "scoria.classification.score")
      refute Map.has_key?(attrs, "scoria.classification.reason")
    end

    test "an explicit false-valued leg IS emitted -- only nil is dropped, never a truthiness check" do
      attrs =
        Semconv.classification_attributes(%{
          action_class: "read",
          source: "tool_declared",
          reads_private_data: false,
          sees_untrusted_content: false,
          can_exfiltrate: false
        })

      assert attrs["scoria.classification.reads_private_data"] == false
      assert attrs["scoria.classification.sees_untrusted_content"] == false
      assert attrs["scoria.classification.can_exfiltrate"] == false
      assert map_size(attrs) == 5
    end

    test "a nil field is omitted, never defaulted" do
      attrs =
        Semconv.classification_attributes(%{
          action_class: "read",
          source: "tool_declared",
          reads_private_data: nil,
          sees_untrusted_content: false,
          can_exfiltrate: false
        })

      refute Map.has_key?(attrs, "scoria.classification.reads_private_data")
      assert map_size(attrs) == 4
    end
  end

  describe "error_attributes/1 type-only projection (SEC-01 Test 8)" do
    test "returns exactly exception.type/error.type, both the module name, never the message (D-06g)" do
      result = Semconv.error_attributes(%RuntimeError{message: "SECRET_PARAM=abc"})

      assert map_size(result) == 2
      assert Map.keys(result) |> Enum.sort() == ["error.type", "exception.type"]
      assert Map.values(result) |> Enum.sort() == ["RuntimeError", "RuntimeError"]
    end
  end

  describe "event_names/0 + event_name?/1 closed vocabulary (EVENT-02, D-03a/D-03c)" do
    test "event_names/0 returns exactly the 3-atom closed vocabulary" do
      assert Semconv.event_names() == [
               :prompt_rendered,
               :guardrail_triggered,
               :user_feedback_received
             ]
    end

    test "event_name?/1 is true for each vocabulary member" do
      for name <- Semconv.event_names() do
        assert Semconv.event_name?(name), "#{inspect(name)} should be a member of event_names/0"
      end
    end

    test "event_name?/1 is false for a non-member atom" do
      refute Semconv.event_name?(:nope)
    end

    test "event_name?/1 is false for a string variant of a real event name — drift-proof, no String.to_atom coercion" do
      refute Semconv.event_name?("prompt_rendered")
      refute Semconv.event_name?("guardrail_triggered")
      refute Semconv.event_name?("user_feedback_received")
    end
  end

  describe "prompt_template_ref_key/0 (EVENT-02, D-04c)" do
    test "returns the exact canonical registry key string" do
      assert Semconv.prompt_template_ref_key() == "scoria.prompt.template_ref"
    end

    test "is registry-admitted as class :id" do
      registry = Semconv.attribute_registry()

      assert Map.get(registry, Semconv.prompt_template_ref_key()) == :id
    end
  end

  describe "anti-inline grep: user_feedback_received has ZERO lib/ emitters (D-04d reserved-only guard)" do
    test "no real lib/ producer file wires an emitter call for the reserved :user_feedback_received event" do
      producer_files = [
        "lib/scoria/observe.ex",
        "lib/scoria/observe/guardrail.ex",
        "lib/scoria/eval/judge_runner.ex",
        "lib/scoria/observe/telemetry.ex"
      ]

      for path <- producer_files, File.exists?(Path.expand(path, File.cwd!())) do
        source = path |> Path.expand(File.cwd!()) |> File.read!()

        refute source =~ ~r/name:\s*:user_feedback_received/,
               "#{path} must not wire a :user_feedback_received emitter — " <>
                 "emission is SEED-011 / FB-01; do not wire an emitter"
      end
    end
  end

  defp assert_only_allowed_keys(value, allowed_keys) when is_map(value) do
    for {key, sub} <- value do
      assert key in allowed_keys, "unexpected key #{inspect(key)} in prompt_context value"
      refute key =~ ~r/text|content|body|message|prompt|raw/i

      assert_only_allowed_keys(sub, allowed_keys)
    end
  end

  defp assert_only_allowed_keys(value, allowed_keys) when is_list(value) do
    Enum.each(value, &assert_only_allowed_keys(&1, allowed_keys))
  end

  defp assert_only_allowed_keys(value, _allowed_keys) when is_binary(value) do
    assert byte_size(value) <= 64
  end

  defp assert_only_allowed_keys(value, _allowed_keys) when is_integer(value) do
    assert value >= 0
  end

  defp assert_only_allowed_keys(value, _allowed_keys) when is_boolean(value), do: :ok
  defp assert_only_allowed_keys(nil, _allowed_keys), do: :ok
end
