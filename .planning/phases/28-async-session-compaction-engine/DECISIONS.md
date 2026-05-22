# Phase 28: Async Session Compaction Engine - Architectural Decisions

## Overview
Phase 28 introduces an asynchronous, Oban-backed memory compaction engine to prevent long-running external sessions from exceeding LLM context windows. It requires summarizing older runtime events (via LLM) into `compacted_memories` and archiving/soft-deleting the original raw events.

In accordance with project requirements and the global AI strategy, the following architectural decisions and implementations have been formulated to shift decision-making "left" and provide a cohesive, immediate technical path.

## 1. Defining "runtime_events" and the Compaction Source

**Context:** The architecture research (07-outrider-ARCHITECTURE.md) references `runtime_events`. Currently, Scoria tracks session history using `ai_workflow_events` (mapped to `Scoria.Workflows.Event`). External agents connecting via MCP interact within a session, which creates events.

**Decision:** 
We will leverage the existing `ai_workflow_events` as the source of truth for raw `runtime_events`. To support compaction, we will add a `compacted_at` timestamp (or `status` flag) to the `ai_workflow_events` schema to soft-delete/archive them once summarized. 

**Tradeoffs:**
* *Pros:* Avoids duplicating the event stream. Fits naturally with the existing `Scoria.Workflows.Run` hierarchy.
* *Cons:* `ai_workflow_events` could grow large, but the very nature of compaction (and archival) mitigates this.

## 2. Structure of `compacted_memories` (Ecto & pgvector)

**Context:** We need a new schema to store the LLM-generated summaries of past events. The architecture research implies these might be vectorized for future RAG injection.

**Decision:**
Create a new Ecto schema `Scoria.Runtime.CompactedMemory` backed by an `ai_compacted_memories` table.
* **Fields:** 
  * `id` (binary_id)
  * `run_id` (references `ai_workflow_runs`)
  * `session_id` (string, indexed for fast retrieval)
  * `start_sequence` (integer) - the first workflow event sequence covered by this summary.
  * `end_sequence` (integer) - the last workflow event sequence covered.
  * `summary_text` (text) - the LLM-generated summary.
  * `embedding` (vector) - `pgvector` embedding of the summary for future retrieval (Phase 24 / out of scope for *immediate* RAG but schema-ready now).
  * `token_count` (integer) - estimated tokens of the summary text.

**Tradeoffs:**
* *Pros:* Clear boundaries. By storing `start_sequence` and `end_sequence`, we maintain strict lineage to the archived events. Ready for pgvector out of the box.
* *Cons:* Requires a new table and migration.

## 3. The Oban Compaction Trigger Mechanism

**Context:** Compaction needs to run asynchronously (OUTRIDER-03) and must be triggered by heuristics (OUTRIDER-05) without blocking web requests or the BEAM schedulers handling MCP SSE connections.

**Decision:**
Implement a token-based sliding window trigger embedded within the `Scoria.Workflows` event insertion pipeline.
* **Mechanism:** When a new `ai_workflow_event` is appended, we calculate an approximate token count (using the `Tiktoken` library already in `mix.exs`).
* If the rolling sum of uncompacted tokens for a `run_id` exceeds a configurable threshold (e.g., 4,000 tokens), an Oban job (`Scoria.Compaction.SummarizeWorker`) is enqueued.
* The Oban job receives `run_id`. It fetches the oldest uncompacted events, sends them to the LLM (using `req_llm`), inserts the `CompactedMemory` record, and updates the `compacted_at` timestamp on the original events.

**Developer Ergonomics:** The trigger will be completely transparent to the caller inserting the event. Using Oban's unique job constraint (e.g., `unique: [keys: [:run_id], period: 60]`), we ensure multiple events inserted rapidly do not queue redundant compaction jobs.

## 4. LLM Client for Summarization

**Context:** The Oban worker needs to call an LLM to summarize the events.

**Decision:**
Use `ReqLlm` (already in `mix.exs`) for a lightweight, robust LLM interaction within the Oban worker. It handles retries and streaming natively, though we will use synchronous `Req` calls within the background worker since it's already asynchronous to the main request.

## Summary of Execution Plan (Next Steps for Plan Phase)
1. **Migration & Schemas:** Generate migrations for `ai_compacted_memories` and alter `ai_workflow_events` to add `compacted_at`.
2. **Oban Worker:** Implement `Scoria.Compaction.SummarizeWorker` using `ReqLlm`.
3. **Trigger Logic:** Update `Scoria.Workflows.Event` insertion logic to include a token estimator and enqueue the Oban job when thresholds are breached.
4. **LiveView Updates:** (For Phase 29, but prepared here) Ensure the schema supports diffing by retaining `compacted_at` instead of hard deletion.
