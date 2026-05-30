defmodule Scoria.HostAppRegistryProofTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 180_000
  @moduletag :registry_proof

  alias Scoria.TestSupport.HostAppProof.Generator
  alias Scoria.TestSupport.HostAppProof.Runner

  test "generated Phoenix host proves live Hex registry adoption path" do
    version =
      System.get_env("SCORIA_REGISTRY_VERSION") ||
        raise """
        SCORIA_REGISTRY_VERSION is required for registry proof — set to the exact published semver, e.g.:

            SCORIA_REGISTRY_VERSION=0.1.0 mix scoria.post_publish_smoke
        """

    host =
      Generator.create_host!(
        dep_mode: :hex_registry,
        hex_version: version,
        cleanup: &on_exit/1
      )

    mix_exs = File.read!(Path.join(host.root, "mix.exs"))

    assert mix_exs =~ Scoria.HexConsumerContract.registry_dep_snippet_pinned(version)

    proof = Runner.run_registry_proof!(host)

    assert proof.steps == Runner.expected_registry_steps(host)
  end
end
