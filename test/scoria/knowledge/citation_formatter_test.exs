defmodule Scoria.Knowledge.CitationFormatterTest do
  use Scoria.KnowledgeCase, async: false

  alias Scoria.Knowledge
  alias Scoria.Knowledge.CitationFormatter

  test "validate_anchor/2 accepts persisted citation anchors" do
    assert {:ok, source} =
             Knowledge.ingest_source(%{
               kind: "doc",
               title: "citation",
               uri: "file:///citation.md",
               body: "citation anchors stay machine readable."
             })

    [chunk | _] = Knowledge.list_source_chunks(source.id)
    [anchor] = CitationFormatter.build_anchors([chunk], label: "[1]", locator: %{title: "citation"})
    assert {:ok, _anchor} = CitationFormatter.validate_anchor(Map.put(anchor, :end_offset, 10))
  end

  test "validate_anchor/2 rejects offset drift" do
    assert {:ok, source} =
             Knowledge.ingest_source(%{
               kind: "doc",
               title: "citation",
               uri: "file:///citation.md",
               body: "citation anchors stay machine readable."
             })

    [chunk | _] = Knowledge.list_source_chunks(source.id)
    [anchor] = CitationFormatter.build_anchors([chunk], label: "[1]")
    assert {:error, %{reason: :offset_out_of_bounds}} =
             CitationFormatter.validate_anchor(%{anchor | end_offset: 999})
  end
end
