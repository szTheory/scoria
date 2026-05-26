defmodule Scoria.HostAppConsumerProofTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 180_000

  alias Scoria.TestSupport.HostAppProof.Generator
  alias Scoria.TestSupport.HostAppProof.Runner

  test "generated Phoenix host proves the bounded Scoria adoption path" do
    host = Generator.create_host!(cleanup: &on_exit/1)
    mix_exs = File.read!(Path.join(host.root, "mix.exs"))

    assert mix_exs =~ "{:scoria, path: "

    proof = Runner.run_full_proof!(host)

    assert proof.steps == [
             :deps_get,
             :scoria_install,
             :ecto_create,
             :ecto_migrate,
             :route_smoke,
             :runtime_smoke
           ]
  end
end
