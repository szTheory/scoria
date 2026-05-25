defmodule Scoria.HandoffExampleSourceTest do
  use ExUnit.Case, async: true

  alias Scoria.TestSupport.AdoptionExample

  @handoff_guide "docs/bounded_handoffs.md"

  test "bounded handoff guide stays aligned with the checked adoption fragments" do
    content = File.read!(@handoff_guide)

    for fragment <- AdoptionExample.handoff_doc_fragments() do
      assert content =~ fragment
    end
  end
end
