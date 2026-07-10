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
  Milestone banner phrases README must not contain.
  """
  def milestone_banner_refutes, do: @milestone_banner_refutes

  @doc """
  Maintainer-only Mix commands that must not appear in README body copy.
  """
  def readme_maintainer_command_refutes, do: @readme_maintainer_command_refutes
end
