---
phase: 53B-ai-span-events-emit-event-1
plan: 02
subsystem: observability
tags: [elixir, ecto, genserver, telemetry, buffer]

requires:
  - phase: 53B-01
    provides: "ai_span_events.span_id FK drop + Semconv event vocabulary (parallel plan, not read by this plan's code)"
provides:
  - "Buffer.cast_event/2 + independently-capped events accumulator"
  - "Two-phase do_flush (Phase 1 traces->spans Multi unchanged, Phase 2 separate Repo.insert_all(SpanEvent) in its own try/rescue)"
  - "surface_flush_error/6 signal-parameterized (:span | :event) with independent storm counters"
affects: [53B-03, 53B-04, 53B-05]

tech-stack:
  added: []
  patterns:
    - "Two-phase flush: Phase 2 (events) always runs regardless of Phase 1 (spans) outcome, in its own try/rescue, so an orphan/failing event can never roll back committed spans (D-02b)"
    - "Independent per-signal caps/counters (events vs spans) prevent cross-signal head-of-line starvation (D-02a)"

key-files:
  created: []
  modified:
    - lib/scoria/observe/buffer.ex
    - test/scoria/observe/buffer_test.exs

key-decisions:
  - "flush_events/2 uses a plain Repo.insert_all (no Ecto.Multi, no per-row savepoints) since it targets a single table with no FK ordering needed after the Plan 01 FK drop"
  - "surface_flush_error gained a signal: :span | :event parameter (same function, new dimension) rather than a second function, per D-02e"
  - "flush_now/1 kept byte-for-byte unchanged (D-02d) -- it already routes through do_flush, so the existing synchronous test hook now proves both phases"

requirements-completed: [EVENT-02]

coverage:
  - id: D1
    description: "Buffer state carries a separate events list with its own cap (max_event_size) and its own failure counter (event_consecutive_failures), independent of spans"
    requirement: "EVENT-02"
    verification:
      - kind: unit
        ref: "test/scoria/observe/buffer_test.exs#drops the newest event if max_event_size is exceeded, independently of the span cap"
        status: pass
    human_judgment: false
  - id: D2
    description: "Buffer.cast_event/2 mirrors cast_span/2; an over-cap event is dropped + Logger.warning'd, parity with spans"
    requirement: "EVENT-02"
    verification:
      - kind: unit
        ref: "test/scoria/observe/buffer_test.exs#drops the newest event if max_event_size is exceeded, independently of the span cap"
        status: pass
    human_judgment: false
  - id: D3
    description: "do_flush runs two ordered phases: the unchanged traces->spans Ecto.Multi first, then a separate Repo.insert_all(SpanEvent, ...) in its own try/rescue that runs regardless of Phase 1's outcome"
    requirement: "EVENT-02"
    verification:
      - kind: unit
        ref: "test/scoria/observe/buffer_test.exs#two-phase flush: cast_span + cast_event for the same span both persist after flush_now"
        status: pass
    human_judgment: false
  - id: D4
    description: "Event flush errors reuse surface_flush_error parameterized by signal: :span | :event with an independent storm counter; the GenServer never crashes; :raise reraises on the timer path only"
    requirement: "EVENT-02"
    verification:
      - kind: unit
        ref: "test/scoria/observe/buffer_test.exs#flush_error telemetry fires on a real constraint failure and the buffer survives"
        status: pass
      - kind: unit
        ref: "test/scoria/observe/buffer_test.exs#:on_flush_error :raise crashes the buffer on the timer path"
        status: pass
      - kind: unit
        ref: "test/scoria/observe/buffer_test.exs#:on_flush_error :raise never reraises from terminate/2 (graceful shutdown)"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-07-18
status: complete
---

# Phase 53B Plan 02: Buffer events list + two-phase flush Summary

**Buffer gained a second, independently-capped `events` accumulator and a two-phase `do_flush` where events flush via a separate `Repo.insert_all` + try/rescue that runs regardless of the spans phase's outcome, so an orphan/failing event insert can never roll back already-committed spans.**

## Performance

- **Duration:** 12 min
- **Completed:** 2026-07-18
- **Tasks:** 3/3 completed
- **Files modified:** 2

## Accomplishments
- `Buffer` state now carries `events`, `max_event_size` (default 1000), and `event_consecutive_failures`, fully independent of the span fields
- `Buffer.cast_event/2` mirrors `cast_span/2`; the `{:cast_event, ...}` handle_cast clause drops the newest event + warns at `max_event_size`, independently of the span buffer-full path
- `do_flush/2` is now two ordered phases: Phase 1 is the existing, byte-for-byte-unchanged traces→spans `Ecto.Multi` (`flush_spans/2`); Phase 2 is a new `flush_events/2` doing a plain `Repo.insert_all(Scoria.Repo.SpanEvent, ...)` in its own `try/rescue`, run unconditionally after Phase 1
- `surface_flush_error/6` gained a `signal: :span | :event` parameter so span and event storm-control counters (and the `flush_error` telemetry payload) stay independent
- `flush_now/1` stays byte-for-byte unchanged (D-02d) — the existing synchronous test hook now exercises both phases
- Added buffer-level tests: ordered two-phase happy path (span + event for the same span both persist after one `flush_now`, FK-state-agnostic) and event buffer-full drop (independent of the span cap)

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend Buffer state + cast_event/2 + buffer-full drop** - `af0a20fb` (feat)
2. **Task 2: Two-phase do_flush + flush_events/2 + signal-parameterized surface_flush_error** - `e5bb7cac` (feat)
3. **Task 3: Buffer-level two-phase flush + event buffer-full tests** - `07e3e3aa` (test)

_No plan-metadata commit in worktree mode — the orchestrator handles the final docs/state commit centrally after the wave merges._

## Files Created/Modified
- `lib/scoria/observe/buffer.ex` - Added events state fields, `cast_event/2`, `{:cast_event, ...}` handle_cast, two-phase `do_flush`, `flush_events/2`, signal-parameterized `surface_flush_error/6`
- `test/scoria/observe/buffer_test.exs` - Added two-phase ordered-flush test and event buffer-full test; aliased `Scoria.Repo.SpanEvent`

## Decisions Made
- `flush_events/2` uses a plain `Repo.insert_all` (no `Ecto.Multi`, no per-row savepoints) — single table, no FK ordering needed after the Plan 01 FK drop (per plan instruction D-02b/D-05)
- `surface_flush_error` extended with a `signal` parameter rather than a duplicate function, per D-02e
- Test A's event references a same-batch span (`span_id` minted before flush) so the test proves ordering without depending on whether the Plan 01 FK-drop migration has run yet

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- **Local test infra:** the worktree had no `deps`/`_build` yet, and the shared `scoria-native-postgres-1` Docker container (project `scoria-native`) was running without its host port published (`SCORIA_DB_PORT=55432` binding was empty). Copied `deps`/`_build` from the main checkout (both gitignored, no repo changes) to avoid a full re-fetch/recompile, and recreated the Postgres container via `SCORIA_DB_PORT=55432 docker compose -p scoria-native -f dev/pgvector-compose.yml up -d` so the published port matched `config/test.exs`'s default. The named volume was preserved (no `-v`), so no data was lost; this only restored the container's port mapping and is a general dev-environment fix, not a code change. Ran the fresh-DB migration ordering from `dev-harness-mix-phx-server` memory (`mix ecto.migrate --to 20260511000300` → `Scoria.TestSupport.Migrations.migrate_knowledge!()` → `mix ecto.migrate`) since a fresh `scoria_test` DB required it.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

`Buffer.cast_event/2` is ready for Plan 03's telemetry handler (`emit_event/1` + the `[:scoria, :observe, :event, :emit]` handler) to call after redact + the fail-closed seam + `Bounds.enforce(_, :event)`. The two-phase `do_flush` and independent event cap are proven at the Buffer level; the full SC#4 orphan-persistence proof (real `emit_event/1` + 50 spans + a dangling `span_id`) is deferred to Plan 05 as specified. No blockers.

---
*Phase: 53B-ai-span-events-emit-event-1*
*Completed: 2026-07-18*
