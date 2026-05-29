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
    "semantic fast path",
    "optional knowledge",
    "upgrade-safe install"
  ]

  @upgrade_safe_install_markers [
    "mix scoria.install --check",
    "mix scoria.install --dry-run"
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
  Milestone banner phrases README must not contain.
  """
  def milestone_banner_refutes, do: @milestone_banner_refutes

  @doc """
  Maintainer-only Mix commands that must not appear in README body copy.
  """
  def readme_maintainer_command_refutes, do: @readme_maintainer_command_refutes
end
