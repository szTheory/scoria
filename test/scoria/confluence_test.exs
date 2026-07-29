defmodule Scoria.ConfluenceTest do
  use ExUnit.Case, async: true

  alias Scoria.Confluence
  alias Scoria.Confluence.Evidence

  describe "classify/1 -- totality over all eight leg vectors (D-05, GATE-01)" do
    test "no legs lit resolves to \"none\"" do
      input = %{private_data: nil, untrusted_content: nil, exfil: nil}

      assert {"none", %Evidence{combination: "none", grade: nil}} = Confluence.classify(input)
    end

    test "private data alone resolves to \"private_data\"" do
      input = %{private_data: %{source: :declared}, untrusted_content: nil, exfil: nil}

      assert {"private_data", %Evidence{combination: "private_data", grade: "declared"}} =
               Confluence.classify(input)
    end

    test "untrusted content alone resolves to \"untrusted_content\"" do
      input = %{private_data: nil, untrusted_content: %{source: :declared}, exfil: nil}

      assert {"untrusted_content", %Evidence{combination: "untrusted_content", grade: "declared"}} =
               Confluence.classify(input)
    end

    test "exfil alone resolves to \"exfil_capable\"" do
      input = %{private_data: nil, untrusted_content: nil, exfil: %{source: :declared}}

      assert {"exfil_capable", %Evidence{combination: "exfil_capable", grade: "declared"}} =
               Confluence.classify(input)
    end

    test "private data and untrusted content, no exfil, resolves to \"private_data_and_untrusted_content\"" do
      input = %{
        private_data: %{source: :declared},
        untrusted_content: %{source: :declared},
        exfil: nil
      }

      assert {"private_data_and_untrusted_content",
              %Evidence{combination: "private_data_and_untrusted_content", grade: "declared"}} =
               Confluence.classify(input)
    end

    test "private data and exfil, no untrusted content, resolves to \"private_data_to_egress\"" do
      input = %{
        private_data: %{source: :declared},
        untrusted_content: nil,
        exfil: %{source: :declared}
      }

      assert {"private_data_to_egress",
              %Evidence{combination: "private_data_to_egress", grade: "declared"}} =
               Confluence.classify(input)
    end

    test "untrusted content and exfil, no private data, resolves to \"untrusted_content_to_egress\"" do
      input = %{
        private_data: nil,
        untrusted_content: %{source: :declared},
        exfil: %{source: :declared}
      }

      assert {"untrusted_content_to_egress",
              %Evidence{combination: "untrusted_content_to_egress", grade: "declared"}} =
               Confluence.classify(input)
    end

    test "all three legs lit resolves to \"exfiltration_path\" (D-05)" do
      input = %{
        private_data: %{source: :declared},
        untrusted_content: %{source: :declared},
        exfil: %{source: :declared},
        action_class: "read",
        run_id: "run-1",
        step_id: "step-1",
        tool_ref: "SomeTool"
      }

      assert {"exfiltration_path", %Evidence{} = evidence} = Confluence.classify(input)

      assert evidence.combination == "exfiltration_path"
      assert evidence.grade == "declared"
      assert evidence.private_data_source == :declared
      assert evidence.untrusted_content_source == :declared
      assert evidence.exfil_source == :declared
      assert evidence.action_class == "read"
      assert evidence.run_id == "run-1"
      assert evidence.step_id == "step-1"
      assert evidence.tool_ref == "SomeTool"
      assert evidence.confluence_idempotency_key =~ "confluence:"
    end

    test "is total over the leg vector regardless of dict insertion order or extra keys" do
      input = %{
        exfil: %{source: :declared},
        private_data: %{source: :declared},
        untrusted_content: %{source: :declared},
        unrelated_key: "ignored"
      }

      assert {"exfiltration_path", %Evidence{grade: "declared"}} = Confluence.classify(input)
    end

    test "none of the eight leg vectors ever falls to the terminal :unevaluable sentinel" do
      witness = %{source: :declared}

      for private_data <- [nil, witness],
          untrusted_content <- [nil, witness],
          exfil <- [nil, witness] do
        input = %{private_data: private_data, untrusted_content: untrusted_content, exfil: exfil}

        assert {combination, %Evidence{}} = Confluence.classify(input)
        refute combination == :unevaluable
      end
    end
  end

  describe "classify/1 -- terminal fallback stays reachable only via internal misuse (D-06)" do
    test "the unreachable-by-construction terminal clause is preserved verbatim in source" do
      {:ok, source} = File.read(Path.join([File.cwd!(), "lib", "scoria", "confluence.ex"]))

      assert source =~ ":confluence_resolver_fallthrough"
      assert source =~ ":unevaluable"
      assert source =~ "unreachable by construction"
    end
  end

  describe "classify/1 -- confluence_idempotency_key" do
    test "is absent when run_id or tool_ref is absent" do
      assert {"none", %Evidence{confluence_idempotency_key: nil}} =
               Confluence.classify(%{private_data: nil, untrusted_content: nil, exfil: nil})
    end
  end

  describe "combinations/0 and normalize_combination/1 (D-05)" do
    test "combinations/0 returns exactly the eight closed-enum string values in order" do
      assert Confluence.combinations() == [
               "none",
               "private_data",
               "untrusted_content",
               "exfil_capable",
               "private_data_and_untrusted_content",
               "private_data_to_egress",
               "untrusted_content_to_egress",
               "exfiltration_path"
             ]

      assert length(Confluence.combinations()) == 8
    end

    test "normalize_combination/1 passes through a recognized value" do
      assert Confluence.normalize_combination("private_data") == "private_data"
    end

    test "normalize_combination/1 fails closed to \"none\" for an unrecognized value and does not raise" do
      assert Confluence.normalize_combination("not_a_combination") == "none"
      assert Confluence.normalize_combination(:none) == "none"
      assert Confluence.normalize_combination(nil) == "none"
    end
  end

  describe "reason_codes/0 and normalize_reason_code/1 (D-09)" do
    test "reason_codes/0 returns the domain-owned closed enum without widening Semconv's" do
      assert Confluence.reason_codes() == [
               :unclassified_default,
               :approval_pending,
               :approval_granted,
               :approval_denied,
               :confluence_rejected,
               :scanner_malformed,
               :unknown,
               :confluence_resolver_fallthrough
             ]
    end

    test "normalize_reason_code/1 passes through a recognized atom" do
      assert Confluence.normalize_reason_code(:scanner_malformed) == :scanner_malformed
    end

    test "normalize_reason_code/1 fails closed to :unknown for an unrecognized value and does not raise" do
      assert Confluence.normalize_reason_code(:not_a_code) == :unknown
      assert Confluence.normalize_reason_code("scanner_malformed") == :unknown
      assert Confluence.normalize_reason_code(nil) == :unknown
    end
  end

  describe "Semconv guardrail enums are untouched (D-09)" do
    test "Scoria.Observe.Semconv.guardrail_reason_codes/0 and guardrail_names/0 are byte-identical to their pre-phase values" do
      assert Scoria.Observe.Semconv.guardrail_reason_codes() == [
               "unapproved_draft",
               "eval_not_passing",
               "eval_required",
               "approval_required",
               "budget_rejected",
               "breaker_open"
             ]

      assert Scoria.Observe.Semconv.guardrail_names() == [
               "release_gate",
               "approval_gate",
               "budget_gate",
               "breaker_gate"
             ]
    end
  end

  describe "module hygiene (D-03)" do
    test "the module defines no Scoria-side alias other than its own leaf Evidence struct" do
      {:ok, source} = File.read(Path.join([File.cwd!(), "lib", "scoria", "confluence.ex"]))

      offending =
        source
        |> String.split("\n")
        |> Enum.reject(fn line -> String.trim(line) |> String.starts_with?("#") end)
        |> Enum.filter(&Regex.match?(~r/alias\s+Scoria\.(Observe|Workflows|Trust|MCP|Repo)/, &1))

      assert offending == [],
             "Scoria.Confluence must not alias any Scoria-side module beyond its own Evidence struct (D-03), found: #{inspect(offending)}"
    end

    test "the module compiles without warnings and defines classify/1, combinations/0 and reason_codes/0" do
      # function_exported?/3 reports false for a module that is merely not loaded
      # yet, and Elixir loads modules lazily. In this async case that races the
      # rest of the suite: under a seed where nothing has called classify/1
      # first, the module is unloaded and the assertion fails spuriously.
      assert Code.ensure_loaded?(Confluence)
      assert function_exported?(Confluence, :classify, 1)
      assert function_exported?(Confluence, :combinations, 0)
      assert function_exported?(Confluence, :normalize_combination, 1)
      assert function_exported?(Confluence, :reason_codes, 0)
      assert function_exported?(Confluence, :normalize_reason_code, 1)
    end
  end
end
