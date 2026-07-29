defmodule Scoria.ConfluenceTest do
  use ExUnit.Case, async: true

  alias Scoria.Confluence
  alias Scoria.Confluence.Evidence

  describe "classify/1 -- all three legs lit (D-05 exfiltration_path)" do
    test "returns {\"exfiltration_path\", %Evidence{}} when private_data, untrusted_content, and exfil are all lit" do
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
      assert evidence.decision == "escalate"
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
  end

  describe "classify/1 -- terminal fallback (D-06 deliberate divergence from ReplayDisposition)" do
    test "any input other than all-three-legs-lit falls to the unreachable-by-construction :unevaluable sentinel, never :escalate and never silent \"none\"" do
      partial_inputs = [
        %{private_data: nil, untrusted_content: nil, exfil: nil},
        %{private_data: %{source: :declared}, untrusted_content: nil, exfil: nil},
        %{private_data: nil, untrusted_content: %{source: :declared}, exfil: nil},
        %{private_data: nil, untrusted_content: nil, exfil: %{source: :declared}},
        %{private_data: %{source: :declared}, untrusted_content: %{source: :declared}, exfil: nil},
        %{private_data: %{source: :declared}, untrusted_content: nil, exfil: %{source: :declared}},
        %{private_data: nil, untrusted_content: %{source: :declared}, exfil: %{source: :declared}}
      ]

      for input <- partial_inputs do
        assert {:unevaluable, %Evidence{} = evidence} = Confluence.classify(input)
        assert evidence.combination == :unevaluable
        assert evidence.reason_code == :confluence_resolver_fallthrough
        refute evidence.decision == "escalate"
      end
    end

    test "an empty input map also falls to the terminal fallback" do
      assert {:unevaluable, %Evidence{reason_code: :confluence_resolver_fallthrough}} =
               Confluence.classify(%{})
    end
  end

  describe "classify/1 -- confluence_idempotency_key" do
    test "is absent when run_id or tool_ref is absent" do
      assert {:unevaluable, %Evidence{confluence_idempotency_key: nil}} =
               Confluence.classify(%{private_data: nil, untrusted_content: nil, exfil: nil})
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

    test "the module compiles without warnings and defines classify/1" do
      assert function_exported?(Confluence, :classify, 1)
    end
  end
end
