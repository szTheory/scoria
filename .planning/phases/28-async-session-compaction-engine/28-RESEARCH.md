<user_constraints>
## User Constraints (from DECISIONS.md)

### Locked Decisions
- **Source of truth:** `ai_workflow_events` with an added `compacted_at` timestamp.
- **Storage for compacted memories:** `Scoria.Runtime.CompactedMemory` (table `ai_compacted_memories`).
- **Fields:** `id`, `run_id`, `session_id`, `start_sequence`, `end_sequence`, `summary_text`, `embedding` (vector), `token_count`.
- **Trigger:** Token-based sliding window checked upon new event insertion, using `Tiktoken`.
- **Async mechanism:** Oban worker `Scoria.Compaction.SummarizeWorker` with `unique` constraint to debounce.
- **Summarization Tool:** `ReqLlm` within the Oban worker.

### the agent's Discretion
- Token calculation approximations.
- LLM prompting strategy for the summarization (within the worker).
- Oban queue names and retry configurations.

### Deferred Ideas (OUT OF SCOPE)
- LiveView integration for the operator UX (Phase 29).
- Active retrieval logic/RAG for `embedding` field (schema ready only).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OUTRIDER-03 | Asynchronous Memory Compaction Worker | Implement `Scoria.Compaction.SummarizeWorker` using Oban and `ReqLlm`. |
| OUTRIDER-04 | Memory Archival and Ecto Schema Updates | Create Ecto schema `Scoria.Runtime.CompactedMemory` and alter `ai_workflow_events`. |
| OUTRIDER-05 | Compaction Trigger Mechanisms | Add threshold trigger in `Scoria.Workflows.Event` using `Tiktoken` and Oban unique enqueue. |
</phase_requirements>

# Phase 28: Async Session Compaction Engine - Research

**Researched:** 2026-05-19
**Domain:** Elixir, Oban Background Jobs, Ecto, pgvector, LLM Summarization
**Confidence:** HIGH

## Summary

This phase implements an async compaction engine to summarize long-running AI workflow sessions, preventing context token exhaustion. It leans heavily on Oban for background processing, `ReqLlm` for external summarization, and Ecto with `pgvector` for persisting the compacted summaries. A token-based sliding window will evaluate running sessions and enqueue Oban jobs gracefully via uniqueness constraints, ensuring BEAM schedulers are not blocked.

**Primary recommendation:** Use `Tiktoken.encode` to rough-calculate token sizes on `ai_workflow_events` payloads. Use Oban's `unique: [period: 60, keys: [:run_id]]` constraint to debounce burst event generation and prevent race conditions over compaction boundaries.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Compaction Heuristics | API / Backend | — | Token tallying and sliding window logic happen synchronously during Ecto event insertion. |
| Background Processing | Backend Worker | Database | Oban processes the LLM summaries securely without blocking the HTTP / SSE connection layer. |
| Event Storage & Archival | Database | — | Ecto/PostgreSQL manage `compacted_at` timestamps for soft-deletion semantics, pgvector handles embeddings. |
| External Summarization | Backend Worker | External API | `ReqLlm` acts as the sync client inside the async Oban process. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto / Postgrex | ~> 3.10 | DB abstraction | Scoria is entirely Ecto-driven. |
| Oban | ~> 2.19 | Background job queuing | Robust PG-backed queues, handles deduplication, retries natively. |
| Pgvector.Ecto | ~> 0.3.0 | Vector storage | Ecto integration for `ai_compacted_memories.embedding`. |
| ReqLlm | ~> 1.11 | LLM Client interface | Native to the project, easily configures standard endpoints. |
| Tiktoken | ~> 0.4.2 | Token estimation | Provides fast BPE calculation offline, protecting LLM context windows. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Oban Unique Jobs | ETS/Redis cache | Redis violates "standard Phoenix/Ecto" rule; ETS doesn't survive restarts gracefully. Oban uniquely natively fits requirements. |

**Version verification:**
Verified via `mix.exs` locally.

## Architecture Patterns

### Recommended Project Structure
```text
lib/scoria/
├── compaction/
│   ├── summarize_worker.ex      # Oban worker executing ReqLlm
│   └── tokenizer.ex             # Lightweight wrapper around Tiktoken
├── runtime/
│   └── compacted_memory.ex      # New Ecto schema
└── workflows/
    ├── event.ex                 # (Modified) + compacted_at
    └── event_compactor.ex       # Evaluates triggers and enqueues worker
```

### Pattern 1: Debounced Oban Triggering
**What:** Enqueue an Oban job asynchronously whenever thresholds are passed, but debounce rapid bursts.
**When to use:** Tracking fast streams of workflow events.
**Example:**
```elixir
# In Scoria.Workflows.EventCompactor
def maybe_enqueue_compaction(run_id) do
  %{run_id: run_id}
  |> Scoria.Compaction.SummarizeWorker.new(
    unique: [period: 60, keys: [:run_id], states: [:available, :scheduled, :executing]]
  )
  |> Oban.insert()
end
```

### Anti-Patterns to Avoid
- **Synchronous LLM calls in Event pipeline:** Doing HTTP / API logic inside the workflow event insertion pipeline will choke SSE/live connections. Always push to Oban.
- **Hard Deleting Events:** Losing raw data breaks the "time travel" Operator UX requirement (OUTRIDER-06). Use `compacted_at` for soft-delete semantics in standard queries.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Token estimation | Custom string-length heuristics | `Tiktoken` | LLM token structures are highly specific; length heuristics drift quickly and cause 400 Context Window errors. |
| Job Debouncing | GenServer timers / Redix | Oban Unique Jobs | Oban provides reliable PostgreSQL-level uniqueness across node restarts out-of-the-box. |

## Common Pitfalls

### Pitfall 1: Token Counting Overhead
**What goes wrong:** `Tiktoken` processes large strings inside Ecto transactions, slowing down inserts.
**Why it happens:** Passing massive blobs to tokenizers in synchronous blocks.
**How to avoid:** Perform token calculations purely on the `payload` fields that matter, and do it *before* wrapping in `Repo.transaction`, or maintain a rolling tally on the `Run` parent record.

### Pitfall 2: Race Conditions on Compaction Boundaries
**What goes wrong:** Oban runs while new events stream in, and `end_sequence` misses new events but marks them compacted.
**Why it happens:** Not locking the rows or improperly defining the sequence window.
**How to avoid:** Have the Oban worker explicitly query for `WHERE compacted_at IS NULL AND sequence <= MAX(target_sequence)` and explicitly lock the rows, or just pass an exact `end_sequence` ID in the Oban args so it strictly bounds what gets passed to the LLM.

## Code Examples

### Trigger Condition Evaluation
```elixir
def count_uncompacted_tokens(run_id) do
  # Example query for pulling payload tokens; calculate via Elixir on select to avoid raw fragment injection risks.
  Scoria.Repo.one(
    from e in Scoria.Workflows.Event,
    where: e.run_id == ^run_id and is_nil(e.compacted_at),
    select: sum(fragment("length(?::text)", e.payload))
  )
end
```

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | Data layer | ✓ | - | — |
| LLM Service | ReqLlm API | ✓ | - | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `mix.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OUTRIDER-03 | Oban enqueues unique compaction job | unit | `mix test test/scoria/compaction_test.exs` | ❌ Wave 0 |
| OUTRIDER-04 | `compacted_at` and `CompactedMemory` save successfully | integration | `mix test test/scoria/runtime/compacted_memory_test.exs` | ❌ Wave 0 |
| OUTRIDER-05 | Threshold triggers Oban successfully | unit | `mix test test/scoria/workflows/event_compactor_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/scoria/compaction_test.exs` — covers OUTRIDER-03
- [ ] `test/scoria/runtime/compacted_memory_test.exs` — covers OUTRIDER-04
- [ ] `test/scoria/workflows/event_compactor_test.exs` — covers OUTRIDER-05

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Ecto Changesets for payload boundaries |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| LLM Prompt Injection via Event | Tampering | System prompts strictly formatting the context string in `ReqLlm` request. |
| Async Worker DoS | Denial of Service | Configure maximum concurrent workers (e.g. `ai_compaction: 5`) to prevent queue starvation. |

## Sources

### Primary (HIGH confidence)
- Project Constraints (`.planning/phases/28-async-session-compaction-engine/DECISIONS.md`, `mix.exs`)
- Oban Official documentation for unique constraints.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Extracted verbatim from project requirements and active dependencies.
- Architecture: HIGH - Matches global decisions on Elixir ecosystem limits.
- Pitfalls: HIGH - Known issues with token streams and async workers.

**Research date:** 2026-05-19
**Valid until:** 2026-12-31