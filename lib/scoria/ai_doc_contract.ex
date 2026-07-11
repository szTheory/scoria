defmodule Scoria.AiDocContract do
  @moduledoc false

  @root_llms_path "llms.txt"
  @root_agents_path "AGENTS.md"
  @gemini_bridge_path "GEMINI.md"

  @packaged_ai_doc_paths [
    @root_llms_path,
    @root_agents_path
  ]

  @repo_only_ai_doc_paths [
    @gemini_bridge_path
  ]

  @required_llms_paths [
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
    "lib/scoria/identity.ex",
    "lib/scoria/runtime.ex",
    "lib/scoria/verification_suites.ex",
    "lib/scoria_web/reviewer_surface.ex",
    "lib/scoria/observe/reviewer_broadcast.ex",
    "lib/scoria/semantic_cache/profile.ex",
    "lib/scoria/semantic_cache.ex",
    "lib/scoria/knowledge.ex",
    "lib/scoria/connectors.ex",
    "lib/scoria/connectors/auth.ex",
    "lib/scoria/mcp/tool.ex",
    "lib/scoria/eval.ex",
    "test/scoria/adoption_surface_test.exs",
    "test/scoria/terminology_contract_test.exs"
  ]

  @required_llms_headings [
    "## Start Here",
    "## Public API",
    "## Capability Guides",
    "## Verify",
    "## Source vs Generated",
    "## Optional and Derived References"
  ]

  @required_agent_sections [
    "## Project Boundary",
    "## Source of Truth",
    "## Generated Files",
    "## Setup and Verification",
    "## Docs Language",
    "## Public API",
    "## Avoid"
  ]

  @source_truth_fragments [
    "README.md and guides/ are canonical source docs",
    "docs/*.md files are compatibility stubs",
    "doc/ output, including doc/llms.txt, is generated",
    "Edit source docs and tests, not generated doc/ output",
    "mix scoria.release_preview",
    "MIX_ENV=dev mix docs --warnings-as-errors"
  ]

  @forbidden_ai_doc_fragments [
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
  ]

  def root_llms_path, do: @root_llms_path
  def root_agents_path, do: @root_agents_path
  def gemini_bridge_path, do: @gemini_bridge_path
  def packaged_ai_doc_paths, do: @packaged_ai_doc_paths
  def repo_only_ai_doc_paths, do: @repo_only_ai_doc_paths
  def required_llms_paths, do: @required_llms_paths
  def required_llms_headings, do: @required_llms_headings
  def required_agent_sections, do: @required_agent_sections
  def source_truth_fragments, do: @source_truth_fragments
  def forbidden_ai_doc_fragments, do: @forbidden_ai_doc_fragments
end
