defmodule Scoria.AiDocContractTest do
  use ExUnit.Case, async: true

  alias Scoria.AiDocContract

  test "AI-01/D-01 and D-04 root AI doc paths stay explicit" do
    assert AiDocContract.root_llms_path() == "llms.txt"
    assert AiDocContract.root_agents_path() == "AGENTS.md"
    assert AiDocContract.gemini_bridge_path() == "GEMINI.md"
  end

  test "AI-01/D-20 packaged AI docs exclude the Gemini repo bridge" do
    assert AiDocContract.packaged_ai_doc_paths() == ["llms.txt", "AGENTS.md"]
    assert AiDocContract.repo_only_ai_doc_paths() == ["GEMINI.md"]
  end

  test "AI-01/D-02 required llms paths cover public docs, public modules, and verification suites" do
    required_paths = AiDocContract.required_llms_paths()

    for path <- [
          "README.md",
          "guides/getting-started.md",
          "guides/golden-path.md",
          "guides/jtbd-and-user-flows.md",
          "guides/ownership-boundary.md",
          "guides/capabilities/default-runtime.md",
          "guides/capabilities/bounded-handoffs.md",
          "guides/capabilities/semantic-cache.md",
          "guides/capabilities/connectors-and-mcp.md",
          "guides/capabilities/support-copilot-gallery.md",
          "guides/reviewer-verification.md",
          "guides/troubleshooting.md",
          "guides/scoria-vs-external-llm-ops.md",
          "guides/cheatsheet.cheatmd",
          "guides/reference/glossary.md",
          "guides/maintainers.md",
          "lib/scoria.ex",
          "lib/scoria/verification_suites.ex",
          "lib/scoria_web/reviewer_surface.ex",
          "lib/scoria/observe/reviewer_broadcast.ex",
          "lib/scoria/semantic_cache/profile.ex",
          "test/scoria/adoption_surface_test.exs",
          "test/scoria/terminology_contract_test.exs"
        ] do
      assert path in required_paths, "expected #{path} in required llms.txt source map"
    end

    assert required_paths == Enum.uniq(required_paths)
  end

  test "AI-01/D-02 and D-03 required headings and sections are fact-level contracts" do
    assert AiDocContract.required_llms_headings() == [
             "## Start Here",
             "## Public API",
             "## Capability Guides",
             "## Verify",
             "## Source vs Generated",
             "## Optional and Derived References"
           ]

    assert AiDocContract.required_agent_sections() == [
             "## Project Boundary",
             "## Source of Truth",
             "## Generated Files",
             "## Setup and Verification",
             "## Docs Language",
             "## Public API",
             "## Avoid"
           ]
  end

  test "AI-02/D-06 through D-09 source truth fragments distinguish source from generated docs" do
    fragments = AiDocContract.source_truth_fragments()

    for fragment <- [
          "README.md and guides/ are canonical source docs",
          "docs/*.md files are compatibility stubs",
          "doc/ output, including doc/llms.txt, is generated",
          "Edit source docs and tests, not generated doc/ output",
          "mix scoria.release_preview",
          "MIX_ENV=dev mix docs --warnings-as-errors"
        ] do
      assert fragment in fragments, "expected source/generated fragment #{inspect(fragment)}"
    end
  end

  test "AI-02/D-10 and D-22 forbidden fragments block planning-only and future-seed overclaims" do
    forbidden = AiDocContract.forbidden_ai_doc_fragments()

    for fragment <- [
          ".planning/",
          "prompts/",
          "priv/dev/",
          "Scoria AI",
          "autonomous agent platform",
          "OpenInference export",
          "lethal-trifecta",
          "Rule-of-Two",
          "Keystone",
          "v2.0 Relay",
          "The Four Lanes"
        ] do
      assert fragment in forbidden, "expected forbidden AI-doc fragment #{inspect(fragment)}"
    end
  end
end
