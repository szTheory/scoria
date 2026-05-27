defmodule Scoria.WarningRatchetTest do
  use ExUnit.Case, async: true

  alias Scoria.WarningRatchet

  test "high_signal_wae_paths/0 includes verification_lanes_test.exs" do
    paths = WarningRatchet.high_signal_wae_paths()

    assert "test/scoria/verification_lanes_test.exs" in paths
  end

  test "high_signal_wae_paths/0 paths exist on disk" do
    for path <- WarningRatchet.high_signal_wae_paths() do
      assert File.exists?(path), "expected high-signal path to exist: #{path}"
    end
  end

  test "high_signal_wae_paths/0 is sorted and unique" do
    paths = WarningRatchet.high_signal_wae_paths()

    assert paths == Enum.sort(paths)
    assert paths == Enum.uniq(paths)
  end

  test "high_signal_wae_paths/0 has at least fifteen paths" do
    assert length(WarningRatchet.high_signal_wae_paths()) >= 15
  end

  test "high_signal_path?/1 matches membership in high_signal_wae_paths/0" do
    [sample | _] = WarningRatchet.high_signal_wae_paths()

    assert WarningRatchet.high_signal_path?(sample)
    refute WarningRatchet.high_signal_path?("test/nonexistent/path_test.exs")
  end
end
