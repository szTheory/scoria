defmodule Scoria.HexConsumerBaselineFixtureTest do
  use ExUnit.Case, async: true

  alias Scoria.HexConsumerContract

  test "baseline stamp fingerprint and git SHA match fixture contract" do
    stamp_path = Path.expand(HexConsumerContract.baseline_stamp_rel(), File.cwd!())
    [fingerprint, git_sha | _] = stamp_path |> File.read!() |> String.split("\n", trim: true)

    assert fingerprint == HexConsumerContract.baseline_package_fingerprint()
    assert git_sha == HexConsumerContract.baseline_git_sha()
    assert git_sha == "49f2d60018c4c79fbc09969116526c48454a8e84"
  end
end
