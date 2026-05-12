defmodule Scoria.Knowledge.GroundingTest do
  use Scoria.KnowledgeCase, async: false

  alias Scoria.Knowledge

  test "score_grounding/2 persists unsupported_claims and retrieval_ranking checks before judge review" do
    assert {:ok, source} =
             Knowledge.ingest_source(%{
               kind: "doc",
               title: "grounding",
               uri: "file:///grounding.md",
               body: "retrieval grounding requires evidence."
             })

    [chunk | _] = Knowledge.list_source_chunks(source.id)
    [anchor] = Knowledge.build_citations([chunk], label: "[1]", locator: %{title: "grounding"})

    payload = %{
      answer: "retrieval grounding requires evidence.",
      citations: [Map.put(anchor, :quote, "retrieval grounding requires evidence")],
      results: [%{chunk_id: chunk.id, rank: 1}],
      expected_chunk_ids: [chunk.id]
    }

    assert {:ok, scores} =
             Knowledge.score_grounding(payload,
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
    assert Enum.any?(scores, &(&1.scorer_kind == "retrieval_ranking"))
    assert Enum.any?(scores, &(&1.rubric_version == "rubric_version"))
  end
end
