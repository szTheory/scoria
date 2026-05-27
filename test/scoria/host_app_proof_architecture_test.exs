defmodule Scoria.HostAppProofArchitectureTest do
  use ExUnit.Case, async: true

  @overlay_support "test/support/scoria/host_app_proof/overlay/test"
  @overlay_priv "priv/host_app_proof/overlay/test"

  test "host proof overlay lives under priv, not test/support" do
    refute File.exists?(@overlay_support)
    assert File.dir?(@overlay_priv)
  end

  test "generator and runner compile paths stay under test/support/scoria/host_app_proof" do
    assert File.exists?("test/support/scoria/host_app_proof/generator.ex")
    assert File.exists?("test/support/scoria/host_app_proof/runner.ex")
  end
end
