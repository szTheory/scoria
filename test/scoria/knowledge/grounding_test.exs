defmodule Scoria.Knowledge.GroundingTest do
  use Scoria.KnowledgeCase, async: false

  alias Scoria.Knowledge
  alias Scoria.Knowledge.Grounding

  @scope [tenant_id: "tenant-a", actor_id: "actor-a", scope_kind: :tenant_shared]
  @other_scope [tenant_id: "tenant-b", actor_id: "actor-b", scope_kind: :tenant_shared]

  test "score_citation_presence/1 respects explicit answerability labels" do
    citation = %{chunk_id: Ecto.UUID.generate()}

    assert %{
             status: "passed",
             score: 1.0,
             details: %{count: 1, expected_answerable: true}
           } =
             Grounding.score_citation_presence(%{
               expected_answerable: true,
               citations: [citation]
             })

    answerable_without_citations =
      Grounding.score_citation_presence(%{expected_answerable: true, citations: []})

    assert answerable_without_citations.status == "failed"
    assert answerable_without_citations.score == 0.0
    assert answerable_without_citations.details == %{count: 0, expected_answerable: true}

    assert %{
             status: "passed",
             score: 1.0,
             details: %{count: 0, expected_answerable: false}
           } = Grounding.score_citation_presence(%{expected_answerable: false, citations: []})

    unanswerable_with_citations =
      Grounding.score_citation_presence(%{
        expected_answerable: false,
        citations: [citation]
      })

    assert unanswerable_with_citations.status == "failed"
    assert unanswerable_with_citations.score == 0.0
    assert unanswerable_with_citations.details == %{count: 1, expected_answerable: false}
  end

  test "score_citation_presence/1 supports string keys and answerable alias only for booleans" do
    citation = %{chunk_id: Ecto.UUID.generate()}

    assert %{status: "passed", details: %{expected_answerable: false}} =
             Grounding.score_citation_presence(%{"expected_answerable" => false, citations: []})

    assert %{status: "passed", details: %{expected_answerable: true}} =
             Grounding.score_citation_presence(%{"answerable" => true, citations: [citation]})

    assert %{status: "failed", details: %{count: 0} = details} =
             Grounding.score_citation_presence(%{answerable: "false", citations: []})

    refute Map.has_key?(details, :expected_answerable)
  end

  test "score_citation_presence/1 preserves missing-label empty-citation failure" do
    result = Grounding.score_citation_presence(%{citations: []})

    assert result.status == "failed"
    assert result.score == 0.0
    assert result.details == %{count: 0}
  end

  test "score_grounding/2 persists unsupported_claims and retrieval_ranking checks before judge review" do
    assert {:ok, source} =
             Knowledge.ingest_source(
               %{
                 kind: "doc",
                 title: "grounding",
                 uri: "file:///grounding.md",
                 body: "retrieval grounding requires evidence."
               },
               scope: @scope
             )

    [chunk | _] = Knowledge.list_source_chunks(source.id, scope: @scope)
    [anchor] = Knowledge.build_citations([chunk], label: "[1]", locator: %{title: "grounding"})

    payload = %{
      answer: "retrieval grounding requires evidence.",
      citations: [Map.put(anchor, :quote, "retrieval grounding requires evidence")],
      results: [%{chunk_id: chunk.id, rank: 1}],
      expected_chunk_ids: [chunk.id]
    }

    assert {:ok, scores} =
             Knowledge.score_grounding(payload,
               scope: @scope,
               rubric_version: "deterministic-v1",
               judge_result: %{
                 rubric_version: "rubric_version",
                 prompt_version: "prompt-v1",
                 scorer_kind: "judge",
                 score: 0.95,
                 status: "passed",
                 evidence_refs: %{chunk_id: chunk.id}
               }
             )

    assert Enum.any?(scores, &(&1.scorer_kind == "unsupported_claims"))
    assert Enum.any?(scores, &(&1.scorer_kind == "citation_validity" and &1.status == "passed"))
    assert Enum.any?(scores, &(&1.scorer_kind == "retrieval_ranking"))
    assert Enum.any?(scores, &(&1.rubric_version == "rubric_version"))
  end

  test "score_citation_validity/1 fails closed without tenant scope" do
    assert {:ok, source} =
             Knowledge.ingest_source(
               %{
                 kind: "doc",
                 title: "grounding missing scope",
                 uri: "file:///grounding-missing-scope.md",
                 body: "grounding validity requires scope."
               },
               scope: @scope
             )

    [chunk | _] = Knowledge.list_source_chunks(source.id, scope: @scope)
    [anchor] = Knowledge.build_citations([chunk], label: "[1]")

    result = Grounding.score_citation_validity(%{citations: [anchor]})

    assert result.status == "failed"
    assert result.score == 0.0
    assert result.details == %{invalid: 1, total: 1}
  end

  test "score_citation_validity/1 invalidates wrong-tenant anchors under supplied scope" do
    assert {:ok, other_source} =
             Knowledge.ingest_source(
               %{
                 kind: "doc",
                 title: "foreign grounding",
                 uri: "file:///foreign-grounding.md",
                 body: "foreign grounding anchors must not validate."
               },
               scope: @other_scope
             )

    [foreign_chunk | _] = Knowledge.list_source_chunks(other_source.id, scope: @other_scope)
    [foreign_anchor] = Knowledge.build_citations([foreign_chunk], label: "[1]")

    result = Grounding.score_citation_validity(%{citations: [foreign_anchor], scope: @scope})

    assert result.status == "failed"
    assert result.score == 0.0
    assert result.details == %{invalid: 1, total: 1}
  end
end
