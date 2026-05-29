defmodule Scoria.HexConsumerContractTest do
  use ExUnit.Case, async: true

  alias Scoria.HexConsumerContract

  test "published_version/0 matches mix.exs version" do
    assert HexConsumerContract.published_version() == Mix.Project.config()[:version]
  end

  test "README active dep line matches hex_dep_snippet/0" do
    readme = File.read!("README.md")

    active_dep_lines =
      readme
      |> String.split("\n")
      |> Enum.filter(fn line ->
        trimmed = String.trim_leading(line)
        String.starts_with?(trimmed, "{:scoria,") and not String.starts_with?(trimmed, "#")
      end)

    assert length(active_dep_lines) == 1
    assert String.trim(hd(active_dep_lines)) == HexConsumerContract.hex_dep_snippet()
  end

  test "hex_dep_tuple/0 includes hex: :scoria keyword" do
    assert elem(HexConsumerContract.hex_dep_tuple(), 2) == [hex: :scoria]
  end

  test "tarball_dep_tuple/1 uses path only without :hex key" do
    unpack = "/tmp/scoria-unpack-stub"

    assert HexConsumerContract.tarball_dep_tuple(unpack) == {:scoria, path: unpack}
    assert tuple_size(HexConsumerContract.tarball_dep_tuple(unpack)) == 2
    refute HexConsumerContract.tarball_dep_tuple(unpack) == HexConsumerContract.hex_dep_tuple()
  end

  test "baseline_upgrade_version/0 returns 0.1.0 for Phase 80 fixture hook" do
    assert HexConsumerContract.baseline_upgrade_version() == "0.1.0"
  end

  test "baseline_unpack_root!/0 returns committed scoria-0.1.0-unpack path" do
    root = HexConsumerContract.baseline_unpack_root!()
    assert String.contains?(root, "scoria-0.1.0-unpack")
    assert File.regular?(Path.join(root, "mix.exs"))
  end

  test "same_semver_content_upgrade?/0 is true when HEAD fingerprint differs from baseline" do
    assert HexConsumerContract.baseline_package_fingerprint() !=
             HexConsumerContract.package_fingerprint()

    assert HexConsumerContract.same_semver_content_upgrade?()
  end
end
