defmodule Scoria.HostAppRegistryUpgradeProofTest do
  use ExUnit.Case, async: false

  @moduletag :registry_upgrade

  alias Scoria.HexConsumerContract
  alias Scoria.TestSupport.HostAppProof.Generator
  alias Scoria.TestSupport.HostAppProof.Runner

  test "generated Phoenix host proves registry semver upgrade from previous publish" do
    version =
      System.get_env("SCORIA_REGISTRY_VERSION") ||
        raise """
        SCORIA_REGISTRY_VERSION is required for registry upgrade proof — set to the exact published semver, e.g.:

            SCORIA_REGISTRY_VERSION=0.1.1 mix scoria.post_publish_smoke
        """

    unless HexConsumerContract.semver_upgrade_eligible?(version) do
      raise "registry upgrade proof requires SCORIA_REGISTRY_VERSION > 0.1.0, got #{inspect(version)}"
    end

    %{from: from, to: to} = HexConsumerContract.registry_upgrade_pair(version)

    host =
      Generator.create_host!(
        dep_mode: :hex_registry,
        hex_version: from,
        cleanup: &on_exit/1
      )

    mix_exs = File.read!(Path.join(host.root, "mix.exs"))

    assert mix_exs =~ HexConsumerContract.registry_dep_snippet_pinned(from)

    proof =
      Runner.run_upgrade_proof!(host,
        bump: {:registry, from: from, to: to}
      )

    assert proof.steps == Runner.expected_upgrade_steps(host)
  end
end
