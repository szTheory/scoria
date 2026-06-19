defmodule Scoria.HostAppProofArchitectureTest do
  use ExUnit.Case, async: true

  alias Scoria.TestSupport.HostAppProof.Generator
  alias Scoria.TestSupport.HostAppProof.Runner

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

  test "registry upgrade expected steps include dependency overlay smokes" do
    host = %{
      dep_mode: :hex_registry,
      overlay_tests: [],
      upgrade_overlay_tests: Generator.overlay_test_files()
    }

    assert Runner.expected_upgrade_steps(host) == [
             :deps_get,
             :scoria_install,
             :ecto_create,
             :ecto_migrate,
             :host_route_smoke_test,
             :host_runtime_smoke_test,
             :scoria_install_check,
             :bump_dep,
             :deps_get,
             :scoria_install_dry_run,
             :scoria_install_check_pre_apply,
             :scoria_install,
             :ecto_migrate,
             :scoria_install_check,
             :host_route_smoke_test,
             :host_runtime_smoke_test
           ]
  end
end
