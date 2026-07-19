---
phase: 52-retriever-span-host-declared-attributes
plan: 04
subsystem: observability
tags: [ecto, postgres, telemetry, opentelemetry, retrieval, rag]

# Dependency graph
requires:
  - phase: 52-01
    provides: Scoria.Observe.SpanKind normalization/OpenInference mirror
  - phase: 52-02
    provides: Scoria.Knowledge.Embedder @optional_callbacks model_name/0
  - phase: 52-03
    provides: Scoria.Observe.emit_retriever_span/1 and Semconv projections (retrieval_config_attributes/1, merge_host_declared/2)
provides:
  - Knowledge.retrieve/2 wired end-to-end to mint trace_id/span_id, build the single retrieval-config map, and emit a linked RETRIEVER span after persisting the ai_retrieval_runs system-of-record row
  - Migrated D-R2b test proving the parent_id/span_id semantic split; new RETR-01 join, RETR-02 config-equality, ATTR-01 pass-through, and D-R6 emit-isolation integration tests
  - A knowledge_migrations migration dropping the ai_retrieval_runs.trace_id/span_id hard foreign keys so the eventually-consistent run<->span join no longer raises on every context-less call
affects: [53-structured-child-spans-and-events, retrieval-observability-consumers]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single canonical config_map computed once in retrieve/2, projected through Semconv.retrieval_config_attributes/1 + merge_host_declared/2 to feed BOTH create_retrieval_run's metadata and the emitted span's attributes (RETR-02 single-origin discipline)."
    - "Span emission called only after the with-chain succeeds, wrapped in a defense-in-depth try/rescue on top of Observe.emit_retriever_span/1's own internal rescue (D-R6 belt-and-suspenders)."
    - "Real-Postgres integration tests start their own Scoria.Observe.Buffer + Scoria.Observe.Telemetry.attach/1 per test (mirroring Scoria.Observe.TelemetryTest), since Scoria's application supervision tree does not start the Observe pipeline by default."

key-files:
  created:
    - priv/repo/knowledge_migrations/20260712210000_drop_retrieval_run_trace_span_fk.exs
  modified:
    - lib/scoria/knowledge.ex
    - test/scoria/knowledge/retrieval_test.exs

key-decisions:
  - "opts[:embedding_model] wins outright; when the host supplied its own opts[:query_embedding] (bypassing Scoria's embedder), embedder.model_name/0 is never called (Scoria did not embed) and the field falls through to the \"none\" sentinel instead of misattributing provenance."
  - "Dropped the ai_retrieval_runs.trace_id/span_id hard foreign keys (kept columns + indexes) — the linked RETRIEVER span is persisted asynchronously via the Phase-51 telemetry->Buffer pipeline (D-R1 forbids a synchronous span insert), so a context-less retrieve/2 call always references a not-yet-existent trace/span row at run-insert time; the join is proven at the application level (RETR-01 test) after Buffer.flush_now/1, not by a database-enforced synchronous reference."

requirements-completed: [RETR-01, RETR-02, ATTR-01]

coverage:
  - id: D1
    description: "Knowledge.retrieve/2 mints trace_id/span_id, persists ai_retrieval_runs (system-of-record), and emits a linked RETRIEVER span sharing the same trace_id/span_id after Buffer.flush_now/1 — the join is never empty for a successful call."
    requirement: "RETR-01"
    verification:
      - kind: integration
        ref: "test/scoria/knowledge/retrieval_test.exs#RETR-01: retrieve/2 produces a linked RETRIEVER span sharing trace_id/span_id with the run"
        status: pass
      - kind: integration
        ref: "test/scoria/knowledge/retrieval_test.exs#retrieve/2 persists RetrievalRun and ordered results"
        status: pass
    human_judgment: false
  - id: D2
    description: "embedding_model/index_version/reranker convention keys are computed once and projected identically onto both run.metadata and the emitted span's attributes, with a \"none\" sentinel when unsupplied."
    requirement: "RETR-02"
    verification:
      - kind: integration
        ref: "test/scoria/knowledge/retrieval_test.exs#RETR-02: scoria.retrieval.* keys are equal on span.attributes and run.metadata (single origin)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Host-declared feature/route/archetype/intent values flow through to persisted RETRIEVER span attributes and run.metadata byte-for-byte, unmodified; omitted keys stay absent on both sinks."
    requirement: "ATTR-01"
    verification:
      - kind: integration
        ref: "test/scoria/knowledge/retrieval_test.exs#ATTR-01: host-declared feature value passes through byte-for-byte; omitted keys stay absent"
        status: pass
    human_judgment: false
  - id: D4
    description: "Span emission never fails retrieval — retrieve/2 still returns {:ok, ...} even when a telemetry handler on the emit path raises."
    verification:
      - kind: integration
        ref: "test/scoria/knowledge/retrieval_test.exs#D-R6: retrieve/2 still succeeds even when the span emit path raises"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-07-12
status: complete
---

# Phase 52 Plan 04: Wire retrieve/2 to the RETRIEVER span spine Summary

**`Knowledge.retrieve/2` now mints trace_id/span_id up front, builds one canonical retrieval-config map shared by `ai_retrieval_runs.metadata` and the emitted RETRIEVER span's attributes, and emits `Scoria.Observe.emit_retriever_span/1` after the with-chain succeeds — closing the RETR-01/RETR-02/ATTR-01 spine with a migrated D-R2b linkage test plus four new real-Postgres integration tests.**

## Performance

- **Duration:** 25 min
- **Tasks:** 2
- **Files modified:** 2 (`lib/scoria/knowledge.ex`, `test/scoria/knowledge/retrieval_test.exs`), plus 1 new migration

## Accomplishments
- `retrieve/2` mints `trace_id`/`span_id` (D-R2), captures wall-clock start (D-R4), resolves the embedder (guarded `model_name/0` lookup, D-RETR02-5), and computes ONE `config_map` fed through `Semconv.retrieval_config_attributes/1` + `merge_host_declared/2` to both `create_retrieval_run`'s `metadata:` and the emitted span's `attributes` (single-origin, D-RETR02-1).
- `opts[:span_id]` is redefined to "this retrieval's own span id" and written to both `run.span_id` and the span's `:id`; `opts[:parent_id]` carries the caller's/originating span (D-R2/D-R3). Return is additive: `{:ok, %{run:, results:, trace_id:, span_id:}}`.
- `Scoria.Observe.emit_retriever_span/1` fires only after the `with`-chain succeeds, isolated with `try/rescue -> :ok` (D-R6).
- Migrated the mandatory `retrieval_test.exs` linkage test (D-R2b) and added four new real-Postgres integration tests: RETR-01 join, RETR-02 config equality, ATTR-01 pass-through, D-R6 emit-isolation.
- Fixed a real bug (see Deviations): the `ai_retrieval_runs.trace_id`/`span_id` hard foreign keys made every context-less `retrieve/2` call raise once ID minting became mandatory.

## Task Commits

1. **Task 1: Edit retrieve/2 — mint IDs, one config map, emit RETRIEVER span** - `00a52003` (feat)
2. **Task 2: Migrate retrieval_test.exs (D-R2b) + RETR-01/RETR-02/ATTR-01/D-R6 integration** - `358b9192` (test)

**Plan metadata:** (this commit)

## Files Created/Modified
- `lib/scoria/knowledge.ex` - `retrieve/2` mints IDs, builds the config map, calls `emit_retriever_span/1`; new `@doc`; new private `resolve_embedding_model/2` and `emit_retriever_span/6` helpers
- `test/scoria/knowledge/retrieval_test.exs` - migrated D-R2b assertion; added a per-test `Scoria.Observe.Buffer` + `Telemetry.attach/1` setup; added RETR-01/RETR-02/ATTR-01/D-R6 tests
- `priv/repo/knowledge_migrations/20260712210000_drop_retrieval_run_trace_span_fk.exs` - drops the `ai_retrieval_runs_trace_id_fkey`/`ai_retrieval_runs_span_id_fkey` constraints (columns/indexes kept)

## Decisions Made
- `opts[:embedding_model]` wins outright; when the host supplied `opts[:query_embedding]` directly (Scoria did not invoke the embedder), `embedder.model_name/0` is skipped entirely and the field falls through to the `"none"` sentinel rather than attributing a model that never ran.
- Dropped the `ai_retrieval_runs.trace_id`/`span_id` foreign keys (see Deviations below) rather than synchronously pre-inserting trace/span rows, which would have either bypassed redaction (a security regression) or collided with the async Buffer's own unconditional span insert (silently dropping the real, attribute-bearing span).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `ai_retrieval_runs.trace_id`/`span_id` foreign keys made every context-less `retrieve/2` call raise**
- **Found during:** Task 1, first `mix scoria.test.knowledge` run after wiring `retrieve/2`
- **Issue:** `ai_retrieval_runs.trace_id`/`span_id` carry hard, immediate-check Postgres foreign keys to `ai_traces`/`ai_spans` (`priv/repo/knowledge_migrations/20260511000300_create_knowledge_tables.exs:54-55`). D-R2 mandates minting a fresh `trace_id`/`span_id` on every call (not just when the host supplies one) and writing them synchronously into the run row inside `create_retrieval_run`. The linked RETRIEVER span, however, is persisted asynchronously via the Phase-51 telemetry -> Buffer pipeline — D-R1 explicitly forbids a synchronous span insert ("re-opens the exact FK footgun Phase 51 fixed... skips redaction/broadcast"). The result: at run-insert time the referenced trace/span rows never yet exist for the common context-less case, and every such call raised `Ecto.ConstraintError` (`ai_retrieval_runs_trace_id_fkey` / `ai_retrieval_runs_span_id_fkey`) — 10 of 58 knowledge-lane tests failed, including pre-existing tests unrelated to this plan's new assertions (e.g. "retrieve/2 passes normalized scope to the backend before persistence").
- **Fix:** Added `priv/repo/knowledge_migrations/20260712210000_drop_retrieval_run_trace_span_fk.exs`, dropping both FK constraints while keeping the columns and their indexes. Considered and rejected two alternatives: (a) synchronously pre-inserting a full span row would bypass `Redactor` (security regression, violates the T-52-04c mitigation) and (b) synchronously upserting a bare-bones stub span row would collide with the async `Buffer`'s own unconditional `insert_all` (no `on_conflict` by design, Pitfall 1) and silently drop the real, attribute-bearing span for the entire flush batch. Dropping the FK matches the documented eventually-consistent join design (RESEARCH.md: "The 'join never comes up empty' criterion is about linkage correctness... not zero-latency persistence") — linkage correctness is now proven at the application level by the RETR-01 test after `Buffer.flush_now/1`.
- **Files modified:** `priv/repo/knowledge_migrations/20260712210000_drop_retrieval_run_trace_span_fk.exs` (new)
- **Verification:** `mix scoria.test.knowledge --only knowledge` — 58/58 green (was 48/58 before the fix); full `mix test` — 3 doctests + 1197 tests, 2 pre-existing unrelated failures (see Issues Encountered), 0 failures attributable to this plan.
- **Committed in:** `00a52003` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug fix)
**Impact on plan:** Necessary for correctness — without it, `RETR-01`'s core acceptance criterion ("a join never comes up empty for a successful call") could never be satisfied for any host that doesn't pre-create trace/span rows itself, which is the overwhelmingly common case. No scope creep — the fix is a single, surgical migration; no other schema or Buffer/Telemetry behavior was touched.

## Issues Encountered
- Full `mix test` surfaced 2 pre-existing failures unrelated to this plan's file set, logged to `.planning/phases/52-retriever-span-host-declared-attributes/deferred-items.md` per the Scope Boundary policy rather than fixed inline: (1) `Scoria.KnowledgeLaneContractTest`'s `@expected_files` list is stale — plan 52-02 added `test/scoria/knowledge/embedder_test.exs` without updating it; (2) `Scoria.WarningInventory.CaptureParityTest` failed intermittently across two full-suite runs with no file changes between them (pre-existing Phase-28 flake, consistent with the project's documented SEED-004 test-code determinism debt).

## Next Phase Readiness
- The RETR-01/RETR-02/ATTR-01-on-the-RETRIEVER-span reliable core is fully wired and proven with real-Postgres integration tests. Plan 52-05 (already complete per STATE.md) covers the adapter host-declared pipe; 52-06 remains for phase closeout.
- Phase 53 (structured child spans + `ai_span_events`) can build on the now-dropped `ai_retrieval_runs` FK precedent if it needs the same eventually-consistent join pattern for other tables.

---
*Phase: 52-retriever-span-host-declared-attributes*
*Completed: 2026-07-12*

## Self-Check: PASSED

All created/modified files and both task commit hashes (`00a52003`, `358b9192`) verified present.
