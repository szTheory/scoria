defmodule Scoria.Repo.Migrations.DropAiSpanEventsSpanIdFk do
  use Ecto.Migration

  @moduledoc """
  Drops the immediate FK on `ai_span_events.span_id` so an orphan event
  (whose span never flushed, or was dropped by Bounds/buffer-full) is
  INSERTABLE rather than raising Postgrex 23503 and rolling back the
  whole batch it shares an `insert_all` transaction with (D-01a).

  `span_id` stays `NOT NULL` and its index stays present — orphans persist
  dangling, never null (D-01b). This is a core-lane migration (not
  dev-only): a new post-0.1.0 migration auto-surfaces via
  `Install.Surface.Migrations` structural-set drift (D-01d).

  Follows the existing in-repo `DROP CONSTRAINT IF EXISTS` idiom at
  `priv/repo/migrations/20260519000000_converge_eval_persistence.exs:117,144`,
  and mirrors the FK-free-by-construction end-state already used for
  `ai_spans.parent_id` at
  `priv/repo/migrations/20260510015813_create_ai_observability_tables.exs:19`.
  """

  def up do
    execute("ALTER TABLE ai_span_events DROP CONSTRAINT IF EXISTS ai_span_events_span_id_fkey")
  end

  def down do
    execute("""
    ALTER TABLE ai_span_events
    ADD CONSTRAINT ai_span_events_span_id_fkey
    FOREIGN KEY (span_id) REFERENCES ai_spans(id) ON DELETE CASCADE
    """)
  end
end
