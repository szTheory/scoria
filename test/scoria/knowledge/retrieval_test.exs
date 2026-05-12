defmodule Scoria.Knowledge.RetrievalTest do
  use Scoria.KnowledgeCase, async: false

  alias Scoria.Knowledge
  alias Scoria.Knowledge.RetrievalRun
  alias Scoria.Repo
  alias Scoria.Repo.Span
  alias Scoria.Repo.Trace

  test "retrieve/2 persists RetrievalRun and ordered results" do
    assert {:ok, source} =
             Knowledge.ingest_source(%{
               kind: "doc",
               title: "retrieval",
               uri: "file:///retrieval.md",
               body: "retrieval evidence keeps every answer challengeable."
             })

    [chunk | _] = Knowledge.list_source_chunks(source.id)
    {:ok, trace} =
      Repo.insert(%Trace{
        session_id: "session-1",
        attributes: %{}
      })

    {:ok, span} =
      Repo.insert(%Span{
        trace_id: trace.id,
        name: "retrieve",
        start_time: DateTime.utc_now() |> DateTime.truncate(:microsecond)
      })

    assert {:ok, %{run: %RetrievalRun{} = run, results: [result | _]}} =
             Knowledge.retrieve("challengeable answer",
               query_embedding: [0.1, 0.2, 0.3],
               filters: %{source_id: source.id},
               trace_id: trace.id,
               span_id: span.id
             )

    assert run.query_text == "challengeable answer"
    assert run.trace_id == trace.id
    assert run.span_id == span.id
    assert result.chunk_id == chunk.id
    assert result.rank == 1
  end
end
