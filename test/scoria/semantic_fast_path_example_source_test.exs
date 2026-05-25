defmodule Scoria.SemanticFastPathExampleSourceTest do
  use ExUnit.Case, async: true

  @semantic_guide "docs/semantic_fast_path.md"

  test "semantic fast-path guide stays aligned with the shipped public lane" do
    content = File.read!(@semantic_guide)

    assert content =~ "use Scoria.SemanticLane"
    assert content =~ "lane_key: \"account_faq\""
    assert content =~ "default_scope: :tenant_shared"
    assert content =~ "safe_read_only: true"
    assert content =~ "Scoria.start_run(identity,"
    assert content =~ "semantic_cache: [lane: MyApp.AI.AccountFaqLane]"
    assert content =~ "SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path"
  end
end
