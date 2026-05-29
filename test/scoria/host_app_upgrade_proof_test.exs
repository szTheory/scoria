defmodule Scoria.HostAppUpgradeProofTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 180_000
  @moduletag :host_upgrade

  alias Scoria.HexConsumerContract
  alias Scoria.TestSupport.HostAppProof.Generator
  alias Scoria.TestSupport.HostAppProof.Runner

  setup_all do
    baseline = HexConsumerContract.baseline_unpack_root!()
    current = HexConsumerContract.ensure_current_unpack_root!()

    {:ok, baseline_unpack_root: baseline, current_unpack_root: current}
  end

  test "generated Phoenix host proves content-revision upgrade from 0.1.0 baseline", %{
    baseline_unpack_root: baseline,
    current_unpack_root: current
  } do
    assert HexConsumerContract.same_semver_content_upgrade?(),
           "baseline fixture must differ from current HEAD tarball — refresh fixture or bump semver"

    assert HexConsumerContract.baseline_package_fingerprint() != HexConsumerContract.package_fingerprint()

    host = Generator.create_host!(dep_mode: :hex_tarball, unpack_root: baseline, overlay_source: baseline, cleanup: &on_exit/1)
    mix_exs = File.read!(Path.join(host.root, "mix.exs"))

    refute mix_exs =~ "{:scoria, path: #{inspect(host.repo_root)}}"
    assert mix_exs =~ HexConsumerContract.tarball_dep_snippet(baseline)

    proof = Runner.run_upgrade_proof!(host, current_unpack_root: current)

    assert proof.steps == Runner.expected_upgrade_steps(host)
  end
end
