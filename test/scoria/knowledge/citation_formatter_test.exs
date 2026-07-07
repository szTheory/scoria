defmodule Scoria.Knowledge.CitationFormatterTest do
  use Scoria.KnowledgeCase, async: false

  alias Scoria.Knowledge
  alias Scoria.Knowledge.CitationFormatter

  @scope [tenant_id: "tenant-a", actor_id: "actor-a", scope_kind: :tenant_shared]
  @other_scope [tenant_id: "tenant-b", actor_id: "actor-b", scope_kind: :tenant_shared]

  test "validate_anchor/2 accepts persisted citation anchors" do
    assert {:ok, source} =
             Knowledge.ingest_source(
               %{
                 kind: "doc",
                 title: "citation",
                 uri: "file:///citation.md",
                 body: "citation anchors stay machine readable."
               },
               scope: @scope
             )

    [chunk | _] = Knowledge.list_source_chunks(source.id, scope: @scope)

    [anchor] =
      CitationFormatter.build_anchors([chunk], label: "[1]", locator: %{title: "citation"})

    assert {:ok, _anchor} =
             CitationFormatter.validate_anchor(Map.put(anchor, :end_offset, 10), scope: @scope)
  end

  test "validate_anchor/2 rejects offset drift" do
    assert {:ok, source} =
             Knowledge.ingest_source(
               %{
                 kind: "doc",
                 title: "citation",
                 uri: "file:///citation.md",
                 body: "citation anchors stay machine readable."
               },
               scope: @scope
             )

    [chunk | _] = Knowledge.list_source_chunks(source.id, scope: @scope)
    [anchor] = CitationFormatter.build_anchors([chunk], label: "[1]")

    assert {:error, %{reason: :offset_out_of_bounds}} =
             CitationFormatter.validate_anchor(%{anchor | end_offset: 999}, scope: @scope)
  end

  test "validate_anchor/2 requires tenant scope" do
    assert {:ok, source} =
             Knowledge.ingest_source(
               %{
                 kind: "doc",
                 title: "citation",
                 uri: "file:///citation-scope.md",
                 body: "citation anchors stay scoped."
               },
               scope: @scope
             )

    [chunk | _] = Knowledge.list_source_chunks(source.id, scope: @scope)
    [anchor] = CitationFormatter.build_anchors([chunk], label: "[1]")

    assert_raise ArgumentError, ~r/tenant_id is required/, fn ->
      CitationFormatter.validate_anchor(anchor)
    end
  end

  test "validate_anchor/2 rejects anchors from another tenant" do
    assert {:ok, other_source} =
             Knowledge.ingest_source(
               %{
                 kind: "doc",
                 title: "foreign citation",
                 uri: "file:///foreign-citation.md",
                 body: "foreign citation anchors must not validate."
               },
               scope: @other_scope
             )

    [foreign_chunk | _] = Knowledge.list_source_chunks(other_source.id, scope: @other_scope)
    [foreign_anchor] = CitationFormatter.build_anchors([foreign_chunk], label: "[1]")

    assert {:error, %{reason: :missing_chunk}} =
             CitationFormatter.validate_anchor(foreign_anchor, scope: @scope)
  end
end
