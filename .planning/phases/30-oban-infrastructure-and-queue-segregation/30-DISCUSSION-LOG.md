# Phase 30 Discussion Log

**Phase:** 30 - Oban Infrastructure & Queue Segregation
**Date:** 2026-05-20
**Mode:** recommendation-first discuss-all
**Status:** decisions locked for planning

## Discussion Setup

- Initiated `/gsd-discuss-phase 30`.
- User requested one-shot recommendations in YOLO mode for Phase 30.
- Subagent-backed research considered: Oban configuration, queue concurrency, `Oban.insert_all` batch limits, and testing strategies.

## Inputs Consulted

- `.planning/milestones/v1.8-ROADMAP.md`
- `~/.gemini/gemini.md` (autonomous recommendation mandate)
- Existing Oban usage in Scoria (`lib/scoria/connectors/discovery_job.ex`, `Scoria.Compaction.SummarizeWorker`)

## Area Decisions

### 1. Oban Queue Configuration & Topology

**Options considered:**
- Hardcoded queues in `config.exs` with fixed concurrency limits.
- Dynamic queue topology loaded from database rows.
- Dynamic queues configurable via `ENV` with sensible hardcoded defaults in `config.exs`.

**Locked recommendation:**
- Use dynamic queues configurable via `ENV` with sensible hardcoded defaults in `config.exs`.
- Specific default queues: `system: 10`, `inference: 20`, `evals: 50`.

**Why this won:**
- Idiomatic for Phoenix applications (runtime config via `runtime.exs` or `config.exs` using env vars).
- Avoids the complexity of DB-backed queue topologies (overkill for an embedded library).
- Provides immediate queue segregation for Eval fan-out (Phase 33) without blocking main app processes.

### 2. Batch Insertion Strategy (`Oban.insert_all`)

**Options considered:**
- Standard `Oban.insert/1` inside a `Task.async_stream` or `Enum.each`.
- `Oban.insert_all/1` chunked by Postgres maximum parameter limits (e.g., chunks of 500-1000).

**Locked recommendation:**
- Use `Oban.insert_all/1` wrapped in a batching helper that enforces a maximum chunk size of 500 jobs per transaction.

**Why this won:**
- `Enum.each` + `Oban.insert` exhausts connection pools under load.
- Postgres limits the number of bind parameters (65,535). A large evaluation campaign could easily trip this if not chunked.
- `Oban.insert_all/1` chunked at 500 strikes the perfect balance of DB efficiency and connection pool safety.

### 3. ExUnit Testing Strategy for Queues

**Options considered:**
- Async testing with real DB queues and unique queue names per test.
- `Oban.Testing` helpers (`assert_enqueued`, `perform_job`) relying on Oban's inline testing mode.

**Locked recommendation:**
- Strictly rely on `Oban.Testing` helpers with `config :oban, testing: :inline` (or `:manual`) configured in `test.exs`.
- Do not run the real Oban supervisor with active pollers during `ExUnit` tests.

**Why this won:**
- Standard Oban practice. Prevents flakiness, race conditions, and DB lock contention during concurrent test runs.

## Shift-Left Defaults Locked

- `system` queue handles internal maintenance (compaction, connector sync).
- `inference` queue handles standard application async tasks.
- `evals` queue is explicitly segregated for massive fan-out campaigns.
- Default concurrency limits are aggressive for `evals` but conservative for `system`/`inference` to prevent web request starvation.

## Result

The discussion produced a coherent, recommendation-first Phase 30 posture and was written into `30-CONTEXT.md` for downstream planning.