---
phase: 51-foundation-fix-key-convention-span-kind-taxonomy
plan: 03
subsystem: observability
tags: [ecto, ecto-multi, genserver, telemetry, postgres, otp]

# Dependency graph
requires:
  - phase: 51-01
    provides: Scoria.Observe.SpanKind (unrelated but same phase; no functional dependency)
  - phase: 51-02
    provides: Scoria.Observe.Semconv (unrelated but same phase; no functional dependency)
provides:
  - Buffer.flush_spans/2 that upserts the parent ai_traces row before inserting ai_spans in one Ecto.Multi transaction, closing the pre-existing FK gap that silently dropped every span since 0.1.0
  - Scoria.Observe.Telemetry.emit_flush_error/1 wrapper + [:scoria, :observe, :buffer, :flush_error] event contract
  - Buffer :on_flush_error start_link opt (:log default | :raise), :flush_now sync test hook, consecutive-failure storm-control counter, terminate/2 raise-gate
affects: [52-retriever-span-and-host-declared-attributes, phase-51-plans-04-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Ecto.Multi trace-upsert-then-span-insert (on_conflict: :nothing, conflict_target: [:id]) in one Repo.transaction"
    - "try/rescue wrapping Repo.transaction(multi) in addition to matching {:error, ...} -- insert_all bypasses changesets and raises raw Postgrex exceptions on constraint violations"
    - "Telemetry emit-wrapper convention (Scoria.Observe.Telemetry.emit_X/1) mirrored for a second event type"
    - "GenServer state-threaded config opts (name, on_flush_error) alongside max_size/flush_interval"

key-files:
  created: []
  modified:
    - lib/scoria/observe/telemetry.ex
    - lib/scoria/observe/buffer.ex
    - test/scoria/observe/buffer_test.exs

key-decisions:
  - "Ecto.Multi trace-upsert (insert_all traces on_conflict: :nothing, conflict_target: [:id]) followed by insert_all spans in one transaction -- avoids N round-trips per flush batch and is race-safe if two Buffer instances flush overlapping trace_ids"
  - "Both {:error, failed_op, failed_value, _} AND a wrapping try/rescue route to the same surface_flush_error/5 path -- insert_all raises raw Postgrex/Ecto exceptions on constraint violations rather than returning a tidy Multi error tuple (Pitfall 3)"
  - ":on_flush_error :raise only fires from the handle_info(:flush, state) timer path (from_timer?: true); handle_call(:flush_now,...) and terminate/2 both pass from_timer?: false so neither can ever raise, even in :raise mode (D-09 i)"
  - "consecutive_failures counter lives in Buffer GenServer state (not the CircuitBreaker module, which is model-ID-keyed and semantically mismatched per RESEARCH Pitfall 4) -- logs full detail once per failure run, resets to 0 on success, but telemetry always fires regardless"
  - "dropped_count is computed from length(span_entries) before the transaction attempt, not state.spans post-reset, so it reflects the attempted count even on failure (D-09 iii)"
  - "safe_emit_flush_error/1 wraps Telemetry.emit_flush_error/1 in its own rescue so a bad host telemetry handler can't crash or re-enter the flush path (D-09 iv)"

patterns-established:
  - "New Buffer start_link opts thread through init/1 into state the same way existing max_size/flush_interval do -- future opts should follow this convention, not a separate config path"
  - "Buffer test child specs that add a second Buffer instance alongside the shared setup's default :test_buffer MUST pass an explicit Supervisor.child_spec(..., id: :unique_atom) -- the default child_spec id is the module name (Scoria.Observe.Buffer), which collides across multiple start_supervised! calls in the same test"

requirements-completed: [FOUND-01]

coverage:
  - id: D1
    description: "A span emitted through Buffer persists as a row in ai_spans with a matching auto-upserted ai_traces row -- no FK violation, no hand-inserted trace in the test"
    requirement: "FOUND-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/buffer_test.exs#auto-upserts the parent trace row before inserting the span (no hand-inserted trace)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The silent bare rescue in Buffer.flush_spans/1 is replaced by structured Logger.error + a [:scoria,:observe,:buffer,:flush_error] telemetry event on a real Postgrex constraint failure, and the Buffer process survives"
    requirement: "FOUND-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/buffer_test.exs#flush_error telemetry fires on a real constraint failure and the buffer survives"
        status: pass
    human_judgment: false
  - id: D3
    description: ":on_flush_error :raise threads through start_link opts and raises ONLY from the handle_info(:flush,...) timer path, never from terminate/2"
    requirement: "FOUND-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/buffer_test.exs#:on_flush_error :raise crashes the buffer on the timer path"
        status: pass
      - kind: unit
        ref: "test/scoria/observe/buffer_test.exs#:on_flush_error :raise never reraises from terminate/2 (graceful shutdown)"
        status: pass
    human_judgment: false
  - id: D4
    description: "handle_call(:flush_now,...) synchronous test hook flushes and replies without racing the periodic flush timer"
    requirement: "FOUND-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/buffer_test.exs#flush_now flushes synchronously with no race against the timer"
        status: pass
    human_judgment: false

duration: 14min
completed: 2026-07-12
status: complete
---

# Phase 51 Plan 03: Buffer FK-Upsert + Loud Flush-Error Surfacing Summary

**Ecto.Multi trace-upsert-then-span-insert closes the pre-existing silent FK gap in `Buffer.flush_spans/1`, replacing the bare `rescue` with structured `Logger.error` + a new `[:scoria, :observe, :buffer, :flush_error]` telemetry event, an `:on_flush_error` (`:log`/`:raise`) knob, a `:flush_now` sync test hook, and error-storm control.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-07-12T10:57:00-04:00 (approx, first commit 10:57:50)
- **Completed:** 2026-07-12T11:11:09-04:00
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- `Buffer.flush_spans/2` now runs one `Ecto.Multi` per flush: `insert_all(:traces, ..., on_conflict: :nothing, conflict_target: [:id])` then `insert_all(:spans, ...)` inside `Repo.transaction/1` -- every span persists with a real, auto-created parent trace row, closing the FK gap that has silently dropped every span since 0.1.0.
- Both `{:error, failed_op, failed_value, _}` (changeset-shaped Multi failure) and a raw Postgrex exception (raised by `insert_all` bypassing changesets, per RESEARCH Pitfall 3) route to the same non-fatal surfacing path: structured `Logger.error` (buffer name + attempted `dropped_count`, never a bare `inspect(e)`) plus `Scoria.Observe.Telemetry.emit_flush_error/1`.
- `Scoria.Observe.Telemetry.emit_flush_error/1` mirrors the existing `emit_span_delta/1` wrapper convention exactly, carrying only counts + error identity + buffer identity in metadata (no raw span `entries`/`attributes`, per T-51-03).
- `:on_flush_error` (`:log` default | `:raise`) threads through `start_link` opts into state; `:raise` fires only from the `handle_info(:flush, state)` timer path, never from `terminate/2` (verified: a graceful `GenServer.stop/1` never reraises even with `:on_flush_error: :raise` and a guaranteed-to-fail buffered span).
- `handle_call(:flush_now, ...)` gives tests a synchronous flush hook -- no `Process.sleep` needed to prove persistence.
- A `consecutive_failures` counter in Buffer state provides storm control: full log detail fires once per consecutive-failure run and resets on success, while the telemetry event always fires so alerting math stays accurate (D-09 ii).

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Telemetry.emit_flush_error/1 wrapper** - `db576cdc` (feat)
2. **Task 2: Rewrite Buffer.flush_spans/1 as Ecto.Multi trace-upsert + loud failure surfacing** - `c2bdc096` (fix)
3. **Task 3: Extend buffer_test.exs** - `9edc7c87` (test)

## Files Created/Modified
- `lib/scoria/observe/telemetry.ex` - Added `emit_flush_error/1` pure emit-wrapper for the new flush-error event; not attached, not added to `@events`.
- `lib/scoria/observe/buffer.ex` - Rewrote `flush_spans/1` (now `/2`, opts-aware) as an `Ecto.Multi` trace-upsert + span-insert; added `:on_flush_error`/`:name`/`consecutive_failures` to state; added `handle_call(:flush_now, ...)`; `terminate/2` now routes through the same non-raising `do_flush/2` path.
- `test/scoria/observe/buffer_test.exs` - Added 5 tests: auto-upsert (SC#1 primary, no hand-inserted trace), flush_error telemetry on a real constraint failure (buffer survives), `:raise`-mode timer-path crash, `:raise`-mode terminate/2 non-raise proof, `:flush_now` synchronous proof.

## Decisions Made
- **Trace-upsert transaction shape (Claude's Discretion, resolved via RESEARCH Pattern 1):** one `Ecto.Multi` per flush batch (dedup `trace_id`s -> `insert_all` with `on_conflict: :nothing` -> `insert_all` spans), rather than a per-span `get_or_insert`. Avoids N round-trips; safe if two Buffer instances race on the same `trace_id`.
- **Dual failure-path catch:** `insert_all` inside a `Multi` does not turn a real Postgrex constraint violation into a tidy `{:error, ...}` tuple -- it raises. Wrapped the whole `Repo.transaction(multi)` call in `try/rescue` in addition to matching `{:error, ...}`, so both failure shapes surface identically (Pitfall 3).
- **Storm control lives in Buffer's own state**, not the existing `CircuitBreaker` module -- `CircuitBreaker` is model-ID-keyed retry-backoff machinery with no "call to block" semantics that map onto "suppress a repeated log line" (RESEARCH Pitfall 4, D-09's explicitly-allowed simpler option).
- **`:raise` gate is path-scoped, not global:** implemented via a `from_timer?` flag threaded through `do_flush/2`, set `true` only by `handle_info(:flush, state)`. Both `handle_call(:flush_now, ...)` and `terminate/2` pass `from_timer?: false`, so neither can ever raise regardless of `:on_flush_error` -- satisfies D-09 (i) without a separate special case in `terminate/2`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test-only: `send(self(), ...)` inside a `:telemetry.attach` handler sent to the wrong process**
- **Found during:** Task 3 (flush_error telemetry test)
- **Issue:** `:telemetry.execute/3` runs the attached handler synchronously in the *calling* process -- which is the Buffer GenServer (since `emit_flush_error/1` is called from inside `Buffer.flush_spans/2`), not the test process. The handler's `send(self(), {:flush_error, ...})` therefore sent the message to the Buffer's own mailbox, and `assert_receive` in the test timed out.
- **Fix:** Captured `test_pid = self()` in the test body (outside the handler closure) and sent to that captured pid instead.
- **Files modified:** test/scoria/observe/buffer_test.exs
- **Verification:** `mix test test/scoria/observe/buffer_test.exs` -- flush_error test passes; `assert_receive {:flush_error, measurements, _metadata}` succeeds with `measurements.dropped_count > 0`.
- **Committed in:** 9edc7c87 (Task 3 commit)

**2. [Rule 1 - Bug] Test-only: `start_supervised!` child-spec `id` collision across multiple Buffer instances in one test**
- **Found during:** Task 3 (writing the 5 new tests)
- **Issue:** `start_supervised!({Buffer, opts})` uses the default `child_spec/1` generated by `use GenServer`, whose `id` defaults to the module (`Scoria.Observe.Buffer`) -- NOT the runtime process `name:` opt. Since the shared `setup` block already starts one Buffer under that same default `id`, every new test that also calls `start_supervised!({Buffer, [name: :something_else, ...]})` collided with `{:already_started, pid}` from the *setup's* buffer, even though the registered process names were distinct.
- **Fix:** Wrapped each new-test child spec in `Supervisor.child_spec({Buffer, opts}, id: :unique_atom_matching_the_name)` so each test's second Buffer instance gets a distinct supervisor child id.
- **Files modified:** test/scoria/observe/buffer_test.exs
- **Verification:** `mix test test/scoria/observe/buffer_test.exs` -- all 8 tests pass (3 existing + 5 new), stable across 3 different `--seed` values.
- **Committed in:** 9edc7c87 (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1, both test-file-only bugs discovered while writing Task 3's tests; no production `lib/` code was affected by either fix).
**Impact on plan:** Both fixes were necessary to make the new tests correctly prove what they claim to prove. No scope creep -- neither touched `buffer.ex` or `telemetry.ex`.

## Issues Encountered

Full-suite `mix test` showed 1 failure in `test/scoria/warning_inventory/capture_parity_test.exs` (an unrelated warning-inventory ratchet test with zero relationship to `lib/scoria/observe/*`). Confirmed pre-existing/environment-dependent: the file passes standalone (`mix test test/scoria/warning_inventory/capture_parity_test.exs` -- 2 tests, 0 failures) and only fails under full-suite parallel `--only __ratchet_compile_only__` subprocess isolation. STATE.md already documents this exact test as a known local-env-only artifact from a prior phase. Logged to `deferred-items.md` per the executor scope boundary (out of scope for this plan's files); not fixed.

Plan 51-03's own verification lanes are all green:
- `mix test test/scoria/observe/buffer_test.exs test/scoria/observe/telemetry_test.exs` -- 12 tests, 0 failures
- `mix test test/scoria/observe/` (regression) -- 72 tests, 0 failures

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- FOUND-01 is complete: every span Scoria emits through `Buffer` now actually persists to Postgres with a correctly auto-upserted parent trace row, and persistence failures are loud (log + telemetry) instead of silently swallowed.
- Plan 51-04 and 51-05 (adapter-layer `gen_ai.*`/`span_kind` wiring) can now assume spans reaching `Buffer` will actually land in the database -- no more silent data loss masking their work.
- No blockers.

---
*Phase: 51-foundation-fix-key-convention-span-kind-taxonomy*
*Completed: 2026-07-12*

## Self-Check: PASSED

All created/modified files and all commit hashes verified present on disk / in git log.
