defmodule Scoria.HexConsumerContract do
  @moduledoc """
  Single source of truth for Hex consumer dependency shapes and tarball wiring.

  Exports adopter-facing Hex dep snippets, version policy, GitHub fallback tuples,
  and CI tarball path tuples. Non-runtime SSOT — tests and Mix tasks import these
  helpers; the running application does not depend on them.
  """

  @app :scoria
  @hex_requirement "~> 0.1"
  @baseline_upgrade_version "0.1.0"
  @github_repo "szTheory/scoria"

  @doc """
  Application atom for Scoria Hex package identity.
  """
  def app, do: @app

  @doc """
  Explicit Hex semver requirement policy (not auto-derived from patch).
  """
  def hex_requirement, do: @hex_requirement

  @doc """
  Published version from Application spec — mirrors mix.exs @version.
  """
  def published_version do
    Application.spec(:scoria, :vsn) |> to_string()
  end

  @doc """
  Baseline upgrade version hook for Phase 80 committed fixture (0.1.0).
  """
  def baseline_upgrade_version, do: @baseline_upgrade_version

  @doc """
  Adopter-facing Hex dep tuple for generated host mix.exs or README guards.
  """
  def hex_dep_tuple, do: {@app, @hex_requirement, hex: @app}

  @doc """
  Adopter-facing Hex dep snippet — byte-match README active dep line.
  """
  def hex_dep_snippet, do: "{:scoria, \"~> 0.1\", hex: :scoria}"

  @doc """
  GitHub fallback dep tuple for forks or pinned patches.
  """
  def github_fallback_tuple(version), do: {@app, github: @github_repo, tag: "v#{version}"}

  @doc """
  GitHub fallback dep snippet for README commented fallback line.
  """
  def github_fallback_snippet(version) do
    "{:scoria, github: \"#{@github_repo}\", tag: \"v#{version}\"}"
  end

  @doc """
  CI tarball dep tuple — path to hex.build --unpack directory (no :hex key).
  """
  def tarball_dep_tuple(unpack_root), do: {@app, path: unpack_root}

  @doc """
  CI tarball dep snippet for generated host mix.exs assertions.
  """
  def tarball_dep_snippet(unpack_root), do: "{:scoria, path: #{inspect(unpack_root)}}"

  @doc """
  Resolve or build the current unpack root for tarball consumer proof.

  Stub in Phase 78 — full fingerprint cache lands in plan 78-02.
  """
  def ensure_current_unpack_root! do
    Mix.raise("HexConsumerContract unpack cache not implemented — complete plan 78-02")
  end
end
