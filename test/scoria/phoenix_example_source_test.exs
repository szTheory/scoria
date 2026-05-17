defmodule Scoria.PhoenixExampleSourceTest do
  use ExUnit.Case, async: true

  alias Scoria.TestSupport.AdoptionExample

  @phoenix_example "docs/phoenix_runtime_example.md"

  test "Phoenix guide stays aligned with the checked adoption example source" do
    content = File.read!(@phoenix_example)

    for fragment <- AdoptionExample.doc_fragments() do
      assert content =~ fragment
    end
  end
end
