# Phase 30: Oban Infrastructure & Queue Segregation - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish robust Oban queue segregation and batch insertion primitives to support the distributed evaluation fan-out and multi-model fallback features in the Vanguard milestone.

This phase extends the existing Oban footprint (introduced in Phase 19/28) by defining explicit queues (`system`, `inference`, `evals`), tuning their concurrency, and building a safe, chunked batch insertion API using `Oban.insert_all`. It lays the plumbing for massive job execution without starving Phoenix web requests or locking the Ecto connection pool. It does NOT implement the eval coordinator or circuit breakers (deferred to Phases 31-33).
</domain>

<decisions>
## Implementation Decisions

### Queue Configuration
- **D-01:** Oban configuration in `config/config.exs` and `config/dev.exs` MUST define three explicit queues: `[system: 10, inference: 20, evals: 50]`.
- **D-02:** These limits should be overridable via standard Phoenix `runtime.exs` env vars, but the defaults should be hardcoded in the baseline config.
- **D-03:** The `system` queue is for internal Scoria tasks (compaction, discovery).
- **D-04:** The `inference` queue is for ad-hoc async inference tasks.
- **D-05:** The `evals` queue is strictly for the distributed evaluation workers (Phase 33).

### Batch Insertion
- **D-06:** Introduce a utility module (e.g., `Scoria.Workflows.BatchEnqueue` or `Scoria.JobBatcher`) that wraps `Oban.insert_all/1`.
- **D-07:** Batch insertion must enforce a chunk size limit (e.g., 500) to prevent Postgres parameter limit exhaustion during massive eval fan-outs.
- **D-08:** `insert_all` should be executed inside an `Ecto.Multi` or simple transaction to ensure atomicity of the batch chunk.

### Testing Strategy
- **D-09:** ExUnit tests must rely exclusively on `Oban.Testing` helpers (`assert_enqueued`, `assert_enqueued_with`).
- **D-10:** Do not spin up real queue execution loops in test mode to avoid race conditions.

</decisions>

<canonical_refs>
## Canonical References

### Milestone and requirement intent
- `.planning/milestones/v1.8-ROADMAP.md` - Phase 30 goals and success criteria (EVAL-01, EVAL-03).
- `.planning/milestones/v1.8-REQUIREMENTS.md` - `EVAL-01` (Queue Segregation), `EVAL-03` (Scalable Evaluation Insertion).

### External standards and adjacent-system guidance
- `https://hexdocs.pm/oban/Oban.html#insert_all/2` - Oban batch insertion guidelines.
- `https://hexdocs.pm/oban/testing.html` - Oban testing best practices.
</canonical_refs>

---

*Phase: 30-oban-infrastructure-and-queue-segregation*
*Context gathered: 2026-05-20*