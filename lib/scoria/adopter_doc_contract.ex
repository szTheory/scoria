defmodule Scoria.AdopterDocContract do
  @moduledoc """
  Single source of truth for adopter-facing README and support-doc contracts.

  Exports capability nouns, upgrade-safe install markers, and refute patterns for
  milestone banner language and maintainer-only commands. Maintainer CI commands
  belong in the operator guide, not in adopter README assertions.
  """

  @shipped_capability_nouns [
    "default runtime",
    "bounded handoff",
    "semantic cache",
    "optional knowledge",
    "remote connector",
    "upgrade-safe install"
  ]

  @upgrade_safe_install_markers [
    "mix scoria.install --check",
    "mix scoria.install --dry-run"
  ]

  @embedded_phoenix_intro_marker "Scoria is an Elixir/Phoenix library you add to an existing Phoenix app to run AI/LLM work durably and inspectably."

  @readme_first_screen_precedes_markers [
    "Choose Your Capability",
    "Default runtime capability",
    "verification suite"
  ]

  @readme_stale_version_refutes [
    "tag: \"v0.1.1\"",
    "Current release: `0.1.1`"
  ]

  @golden_path_guide_path "guides/golden-path.md"
  @jtbd_and_user_flows_guide_path "guides/jtbd-and-user-flows.md"
  @ownership_boundary_guide_path "guides/ownership-boundary.md"
  @reviewer_verification_guide_path "guides/reviewer-verification.md"
  @comparison_guide_path "guides/scoria-vs-external-llm-ops.md"
  @glossary_guide_path "guides/reference/glossary.md"
  @comparison_guide_title "Scoria vs external LLM-ops platforms"

  @comparison_required_peer_names [
    "LangSmith",
    "Langfuse",
    "Braintrust",
    "Arize Phoenix"
  ]

  @comparison_peer_source_links [
    "https://docs.langchain.com/langsmith/self-hosted",
    "https://langfuse.com/self-hosting",
    "https://www.braintrust.dev/docs/admin/self-hosting",
    "https://arize.com/docs/phoenix/self-hosting"
  ]

  @comparison_safe_current_claims [
    "runs inside your Phoenix app",
    "host Postgres/Ecto boundary",
    "embedded LiveView reviewer dashboard at `/scoria`",
    "host app owns identity, authorization, role values, and business truth",
    "durable runs",
    "reviewer-visible traces",
    "approvals",
    "fail-closed eval posture",
    "tenant-scoped knowledge retrieval",
    "upgrade-safe verification suites",
    "no separate Scoria-hosted control plane",
    "no required egress for Scoria governance records"
  ]

  @comparison_ceded_strengths [
    "cross-language SDK coverage",
    "managed warehouse-scale analytics",
    "hosted dashboards across many services",
    "mature prompt playgrounds",
    "broad eval collaboration",
    "non-Phoenix stacks"
  ]

  @comparison_deferred_not_current_claims [
    "OpenInference export is not a current Scoria claim",
    "Rule-of-Two/lethal-trifecta enforcement is not a current Scoria claim",
    "deeper scorer calibration is not a current Scoria claim",
    "richer retrieval evals are not current Scoria claims",
    "retention, masking, purge, and feedback governance are not current Scoria claims",
    "persistent AI feature grouping is not a current Scoria claim"
  ]

  @comparison_forbidden_current_claims [
    "OpenInference export",
    "OpenInference-compatible export",
    "Rule-of-Two",
    "lethal-trifecta enforcement",
    "mature scorer calibration",
    "regression depth",
    "deep retrieval eval",
    "faithfulness metrics",
    "retention governance",
    "masking governance",
    "purge governance",
    "feedback governance",
    "persistent AI feature grouping"
  ]

  @milestone_banner_refutes [
    "Scoria is shipped through",
    "shipped through `v"
  ]

  @readme_maintainer_command_refutes [
    "mix scoria.test.install_contract",
    "mix test.install_contract",
    "mix scoria.test.ci_trust",
    "mix scoria.warning_ratchet",
    "mix scoria.warning_inventory",
    "mix scoria.warning_baseline",
    "mix scoria.eval",
    "mix scoria.milestone",
    "mix scoria.post_publish_smoke",
    "mix scoria.test.knowledge"
  ]

  @doc """
  Capability nouns that adopter README and support docs must mention.
  """
  def shipped_capability_nouns, do: @shipped_capability_nouns

  @doc """
  Exact upgrade-safe install command markers for README Install guidance.
  """
  def upgrade_safe_install_markers, do: @upgrade_safe_install_markers

  @doc """
  Plain-English README intro marker that must precede capability vocabulary.
  """
  def embedded_phoenix_intro_marker, do: @embedded_phoenix_intro_marker

  @doc """
  README markers that must appear only after the embedded Phoenix intro.
  """
  def readme_first_screen_precedes_markers, do: @readme_first_screen_precedes_markers

  @doc """
  README-scoped stale release and fallback examples that must not reappear.
  """
  def readme_stale_version_refutes, do: @readme_stale_version_refutes

  @doc """
  Stable DOCS-03 golden path guide path.
  """
  def golden_path_guide_path, do: @golden_path_guide_path

  @doc """
  Stable DOCS-03 jobs-to-be-done and user flows guide path.
  """
  def jtbd_and_user_flows_guide_path, do: @jtbd_and_user_flows_guide_path

  @doc """
  Stable DOCS-03 ownership boundary guide path.
  """
  def ownership_boundary_guide_path, do: @ownership_boundary_guide_path

  @doc """
  Stable DOCS-03 reviewer verification guide path.
  """
  def reviewer_verification_guide_path, do: @reviewer_verification_guide_path

  @doc """
  Stable POS-04 external LLM-ops comparison guide path.
  """
  def comparison_guide_path, do: @comparison_guide_path

  @doc """
  Stable DOCS-03 glossary guide path.
  """
  def glossary_guide_path, do: @glossary_guide_path

  @doc """
  Exact title for the stable POS-04 comparison guide.
  """
  def comparison_guide_title, do: @comparison_guide_title

  @doc """
  Required peer names in the POS-04 comparison guide.
  """
  def comparison_required_peer_names, do: @comparison_required_peer_names

  @doc """
  Official peer source links that anchor deployment-posture claims.
  """
  def comparison_peer_source_links, do: @comparison_peer_source_links

  @doc """
  Current Scoria claims that are safe to make in the POS-04 comparison guide.
  """
  def comparison_safe_current_claims, do: @comparison_safe_current_claims

  @doc """
  External-platform strengths that Scoria should explicitly cede.
  """
  def comparison_ceded_strengths, do: @comparison_ceded_strengths

  @doc """
  Deferred seeds that the comparison guide must frame as not-current.
  """
  def comparison_deferred_not_current_claims, do: @comparison_deferred_not_current_claims

  @doc """
  Claims that must not appear inside the current-Scoria section.
  """
  def comparison_forbidden_current_claims, do: @comparison_forbidden_current_claims

  @doc """
  Milestone banner phrases README must not contain.
  """
  def milestone_banner_refutes, do: @milestone_banner_refutes

  @doc """
  Maintainer-only Mix commands that must not appear in README body copy.
  """
  def readme_maintainer_command_refutes, do: @readme_maintainer_command_refutes
end
