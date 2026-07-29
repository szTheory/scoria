defmodule Scoria.Repo.KnowledgeMigrations.DropRetrievalRunTraceSpanFk do
  use Ecto.Migration

  @moduledoc """
  ai_retrieval_runs.trace_id/span_id are eventually-consistent join keys
  into the async-flushed ai_traces/ai_spans tables (RETR-01, Phase 52,
  D-R1/D-R2). The run row is written synchronously inside
  Knowledge.retrieve/2's with-chain; the linked RETRIEVER span is
  persisted later via the Phase-51 telemetry -> Buffer -> Postgres
  pipeline (D-R1 forbids a synchronous span insert -- it would re-open
  the FK footgun Phase 51 fixed and skip redaction/broadcast). D-R2
  mints a fresh trace_id/span_id for every context-less retrieval (the
  common case), so at run-insert time the referenced ai_traces/ai_spans
  rows do not exist yet -- a hard, immediate-check foreign key here makes
  every context-less retrieve/2 call raise. Linkage correctness is
  proven at the application level (the RETR-01 join test asserts a
  non-empty join after Buffer.flush_now/1), not by a database-enforced
  synchronous reference. Drop the FK constraints; keep the columns and
  their indexes for lookup/join purposes.
  """

  def up do
    drop(constraint(:ai_retrieval_runs, "ai_retrieval_runs_trace_id_fkey"))
    drop(constraint(:ai_retrieval_runs, "ai_retrieval_runs_span_id_fkey"))
  end

  def down do
    alter table(:ai_retrieval_runs) do
      modify(:trace_id, references(:ai_traces, type: :binary_id, on_delete: :nilify_all))
      modify(:span_id, references(:ai_spans, type: :binary_id, on_delete: :nilify_all))
    end
  end
end
