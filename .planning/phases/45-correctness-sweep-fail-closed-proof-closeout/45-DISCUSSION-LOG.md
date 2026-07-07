# Phase 45: Correctness sweep + fail-closed proof & closeout - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-07
**Phase:** 45-Correctness sweep + fail-closed proof & closeout
**Areas discussed:** Pgvector score persistence, citation abstention, chunker overlap cleanup, real latency gate, scope-doctrine closeout

---

## Pgvector Score Persistence

| Option | Description | Selected |
|--------|-------------|----------|
| DB-projected raw similarity | Keep `ORDER BY cosine_distance(...) ASC`; persist `score = 1 - cosine_distance`. | yes |
| Private Elixir cosine helper | Score after DB ranking with local math. | |
| Shared vector scoring module | Add a reusable scoring abstraction now. | |
| Clamped display score | Persist a friendlier `0..1` score. | |

**User's choice:** Auto-follow Claude recommendation.
**Notes:** Subagent research recommended DB projection because it matches pgvector's ranking metric
and avoids math drift. Stored score remains raw cosine similarity, not a probability.

---

## Citation Abstention

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal `expected_answerable` label | Fix citation expectation for answerable vs unanswerable cases without a schema change. | yes |
| Strict label-required scoring | Require every payload to declare answerability. | |
| Explicit `abstained: true` signal | Pass unanswerable/no-citation only when producer marks abstention. | |
| Full abstention/retrieval eval schema | Build richer RAG labels and semantic scoring. | |

**User's choice:** Auto-follow Claude recommendation.
**Notes:** Subagent research recommended the minimal deterministic label path for FIX-02. Full
abstention, faithfulness, and rerank evaluation stays deferred to SEED-009.

---

## Chunker Overlap Cleanup

| Option | Description | Selected |
|--------|-------------|----------|
| Remove dead overlap handling | Delete the no-op option path and document `Default` as non-overlapping. | yes |
| Accept and warn | Keep accepting `overlap:` but log/deprecate it. | |
| Raise on `overlap:` | Treat passing `overlap:` to `Default` as an error. | |
| Add `Chunker.Windowed` now | Build a real overlapping chunker in this phase. | |

**User's choice:** Auto-follow Claude recommendation.
**Notes:** Subagent research recommended preserving current deterministic offsets/digests while
removing the false API signal. A real windowed chunker is SEED-009 scope.

---

## Real Latency Gate

| Option | Description | Selected |
|--------|-------------|----------|
| Per-item scorer wall-clock latency | Record real `ai_scores.metadata["latency_ms"]` and gate through `Verdict`. | yes |
| Frozen subject trace latency | Gate on immutable source trace/step latency snapshot. | |
| Whole-run duration | Use `EvalRun.duration_ms` for `max_latency_ms`. | |
| Judge/provider call latency only | Gate only on remote judge latency. | |

**User's choice:** Auto-follow Claude recommendation.
**Notes:** Subagent research recommended score-level monotonic timing because it fits the current
`Verdict.compute/2` contract and can be proven without live providers. Whole-run duration remains
observability, not gate input.

---

## Scope-Doctrine Closeout

| Option | Description | Selected |
|--------|-------------|----------|
| Targeted cross-link proof | Confirm doctrine SSOT and link eval/knowledge/dashboard/closeout rationale back to it. | yes |
| Full adopter docs table | Write the complete owns-vs-delegates front-door docs now. | |
| PROJECT-only checkbox | Only confirm the doctrine already exists. | |
| UI scope receipt | Add visible operator scope UI now. | |

**User's choice:** Auto-follow Claude recommendation.
**Notes:** Subagent research recommended a targeted proof pass. SEED-005 owns full docs/positioning;
SEED-013 owns structural operator IA.

---

## Claude's Discretion

- User explicitly delegated all choices to Claude and asked for one coherent, research-backed
  recommendation set.
- Claude selected all five real gray areas and did not fold unrelated fuzzy todos into the phase.
- Exact helper names, test placement, and narrow docs placement remain planner discretion.

## Deferred Ideas

- Hex `0.1.3` publish / release cut - SEED-005 / backlog 999.2.
- Full owns-vs-delegates docs table - SEED-005.
- Semantic abstention, faithfulness, RAG metric depth, reranking - SEED-009.
- Real sliding-window overlap chunker - SEED-009.
- Persistent operator scope bar / tenant switcher - SEED-013.
- Fuzzy todo matches reviewed but not folded: approval decision history, CI cache-key copy cleanup,
  Docker DX fleet hardening.
