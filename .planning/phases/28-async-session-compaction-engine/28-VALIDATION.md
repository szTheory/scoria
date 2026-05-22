# Phase 28: Async Session Compaction Engine - Validation

This document maps the phase success criteria to observable test commands.

## Success Criteria 1: An active session that breaches a configured token/time limit automatically enqueues an Oban compaction job.

**Validation Command:**
```bash
mix test test/scoria/workflows/event_compactor_test.exs
```

**Expected Outcome:**
The test verifies that inserting a sequence of events exceeding the token threshold successfully triggers an `Oban.insert/1` call for `Scoria.Compaction.SummarizeWorker` with the correct `run_id`.

## Success Criteria 2: The Oban worker successfully calls the LLM, summarizes the raw events, and stores the result in a new Ecto schema.

**Validation Command:**
```bash
mix test test/scoria/compaction/summarize_worker_test.exs
```

**Expected Outcome:**
The test verifies that executing the `Scoria.Compaction.SummarizeWorker` job makes a valid call to the LLM via `ReqLlm`, creates a new `Scoria.Runtime.CompactedMemory` record, and correctly computes the summarized vectors and tokens.

## Success Criteria 3: Raw session events are securely archived or soft-deleted from the active context window.

**Validation Command:**
```bash
mix test test/scoria/compaction/summarize_worker_test.exs
```

**Expected Outcome:**
The test verifies that upon successful compaction and storage in `ai_compacted_memories`, the originally summarized `ai_workflow_events` are updated with a non-null `compacted_at` timestamp.

## Complete Phase Validation

To verify the complete functionality for this phase, run the entire test suite to ensure no regressions were introduced.

```bash
mix test
```