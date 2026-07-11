defmodule Scoria.PhoenixExampleSourceTest do
  use ExUnit.Case, async: true

  alias Scoria.TestSupport.AdoptionExample

  for {path, fragments} <- AdoptionExample.phoenix_doc_surfaces() do
    test "#{path} stays aligned with the checked adoption example source" do
      content = File.read!(unquote(path))

      for fragment <- unquote(Macro.escape(fragments)) do
        assert content =~ fragment,
               "expected #{unquote(path)} to contain fragment #{inspect(fragment)}"
      end
    end
  end
end
