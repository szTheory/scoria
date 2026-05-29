defmodule Scoria.HostAppConsumerProofTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 180_000

  alias Scoria.TestSupport.HostAppProof.Generator
  alias Scoria.TestSupport.HostAppProof.Runner

  setup_all do
    {:ok, unpack_root: Scoria.HexConsumerContract.ensure_current_unpack_root!()}
  end

  test "generated Phoenix host proves tarball adoption path", %{unpack_root: unpack_root} do
    host = Generator.create_host!(dep_mode: :hex_tarball, unpack_root: unpack_root, cleanup: &on_exit/1)
    mix_exs = File.read!(Path.join(host.root, "mix.exs"))

    refute mix_exs =~ "{:scoria, path: #{inspect(host.repo_root)}}"
    assert mix_exs =~ Scoria.HexConsumerContract.tarball_dep_snippet(unpack_root)

    proof = Runner.run_route_proof!(host)

    assert proof.steps == [
             :deps_get,
             :scoria_install,
             :ecto_create,
             :ecto_migrate,
             :host_route_smoke_test
           ]
  end
end
