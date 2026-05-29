defmodule Scoria.SupportCopilotGalleryTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 300_000

  alias Scoria.TestSupport.SupportCopilotGallery.Runner

  test "support copilot gallery proves advisory adoption journey" do
    assert File.dir?(Runner.gallery_root())

    proof = Runner.run!()

    assert proof.steps == [:deps_get, :gallery_db, :gallery_test]
  end
end
