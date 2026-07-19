---
phase: 53B-ai-span-events-emit-event-1
plan: 03
subsystem: observability
tags: [elixir, telemetry, semconv, security, event-vocabulary]

# Dependency graph
requires:
  - phase: 53B-01
    provides: "Semconv closed 3-atom event vocabulary (event_names/0, event_name?/1) + ai_span_events.span_id FK drop"
  - phase: 53B-02
    provides: "Buffer.cast_event/2 + independently-capped events accumulator + two-phase do_flush"
provides:
  - "Scoria.Observe.emit_event/1 — the public, never-raising, allow-list-gated point-event verb"
  - "Telemetry [:scoria, :observe, :event, :emit] handler — the boundary of record (independent allow-list re-check, single redact/1, fail-closed time/span_id seam, Bounds :event activation, buffer_event/1 fixed-key cast)"
  - "Telemetry reject_event/2 + [:scoria, :observe, :event, :rejected] telemetry event"
affects: [53B-04, 53B-05]

tech-stack:
  added: []
  patterns:
    - "Single collapsed redact/1 private helper shared by span/delta/event handler clauses — a source-scan drift guard asserts exactly one Redactor.redact( token in telemetry.ex"
    - "Fail-closed seam ahead of a write-time bound (default missing/nil :time, drop nil :span_id) mirrors Bounds' own fail-closed philosophy but lives in the handler, not Bounds, since these are NOT NULL raise classes specific to the raw event bus"
    - "reject_event/2 dedupes its Logger.warning once-per-event-name-per-node via the same lazy-create ETS :ets.insert_new idiom ReviewerBroadcast/Bounds already use, while the telemetry emit itself stays unconditional"

key-files:
  created: []
  modified:
    - lib/scoria/observe.ex
    - lib/scoria/observe/telemetry.ex
    - CHANGELOG.md
    - test/scoria/observe/telemetry_test.exs
    - test/scoria/observe/observe_test.exs

key-decisions:
  - "emit_event/1 gained a catch-all def emit_event(_event), do: {:error, :unknown_event} clause beyond the plan-literal %{name: name} = event when is_map(event) clause -- a bare FunctionClauseError on a non-map or no-:name input would defeat the must_have 'NEVER raises' truth, since that raise happens at the function head before the primary clause's own try/rescue body ever runs (Rule 2: closing a missing-input-validation gap)."
  - "buffer_event/1 stringifies the atom :name value (Map.update(:name, nil, &to_string/1)) before handing off to Buffer.cast_event/2 -- Semconv.event_names/0 is an ATOM vocabulary (D-03a) but ai_span_events.name is a :string Ecto column, and Buffer.cast_event/2 feeds straight into Repo.insert_all/2, which bypasses changeset casting entirely. Without this, every real event would raise a type-mismatch at flush time and silently vanish (caught only by Buffer's own rescue+log, not surfaced as a test failure) -- found via a throwaway integration smoke test before Task 3's real tests were written, fixed inline (Rule 1)."
  - "Drift-guard comment text says 'Redactor.redact/1' (not 'Redactor.redact(') to avoid the source-scan guard counting its own explanatory comment as a second occurrence of the literal token it asserts is unique."

requirements-completed: [EVENT-02]

coverage:
  - id: D1
    description: "emit_event/1 takes a single map, checks Semconv.event_name?/1 up front, executes [:scoria, :observe, :event, :emit] telemetry for a member (returns :ok), returns {:error, :unknown_event} with NO telemetry for a non-member, and never raises (including on malformed/non-map input via the added catch-all clause)"
    requirement: "EVENT-02"
    verification:
      - kind: unit
        ref: "test/scoria/observe/observe_test.exs#emit_event/1 synchronous return contract (EVENT-02, Plan 53B-03)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The [:scoria, :observe, :event, :emit] handler independently re-checks Semconv.event_name?/1 (closing the raw-bus SC#2 bypass), then redact -> fail-closed seam -> Bounds.enforce(_, :event) -> Buffer.cast_event"
    requirement: "EVENT-02"
    verification:
      - kind: unit
        ref: "test/scoria/observe/telemetry_test.exs#[:scoria, :observe, :event, :emit] handler (EVENT-02, Plan 53B-03) — a known event name persists; the raw-bus bypass (unknown name) is rejected and never persisted"
        status: pass
    human_judgment: false
  - id: D3
    description: "The fail-closed seam defaults a missing/nil time to DateTime.utc_now() and drops (via reject_event, never reaching Bounds/insert_all) a nil span_id — the only two NOT NULL raise classes reachable via the raw bus are closed at the handler"
    requirement: "EVENT-02"
    verification:
      - kind: unit
        ref: "test/scoria/observe/telemetry_test.exs#a nil span_id is rejected before Bounds/persistence; a missing time defaults to DateTime.utc_now() and the event still persists"
        status: pass
    human_judgment: false
  - id: D4
    description: "telemetry.ex has exactly ONE Redactor.redact( token; token/span/delta/event clauses all funnel through a single defp redact/1"
    requirement: "EVENT-02"
    verification:
      - kind: unit
        ref: "test/scoria/observe/telemetry_test.exs#single-redact-site drift guard (D-03d) — exactly one Redactor.redact( call site remains in telemetry.ex"
        status: pass
    human_judgment: false
  - id: D5
    description: "The event tuple is added to Telemetry.attach/1's @events (without it the handler never fires); Bounds.enforce(_, :event) is activated with no new Bounds code"
    requirement: "EVENT-02"
    verification:
      - kind: unit
        ref: "test/scoria/observe/telemetry_test.exs — all 9 telemetry_test.exs tests green, including the new :event-handler describe block exercising a live Telemetry.attach/1 subscription"
        status: pass
    human_judgment: false

duration: 45min
completed: 2026-07-18
status: complete
---

# Phase 53B Plan 03: emit_event/1 + the :event telemetry handler (boundary of record) Summary

**`Scoria.Observe.emit_event/1` is the new never-raising, allow-list-gated public verb for the closed point-event vocabulary; the `[:scoria, :observe, :event, :emit]` telemetry handler independently re-checks the allow-list, redacts through a single collapsed call site, closes the two raw-bus NOT NULL raise classes before Bounds, activates `Bounds.enforce(_, :event)`, and casts to the durable `ai_span_events` table via a fixed-key projection.**

## Performance

- **Duration:** ~45 min
- **Completed:** 2026-07-18
- **Tasks:** 3/3 completed
- **Files modified:** 5

## Accomplishments

- `Scoria.Observe.emit_event/1`: a single-map (`%{name:, span_id:, attributes:, time:}`) public verb, observe-domain (not top-level `Scoria`, D-03a). Checks `Semconv.event_name?/1` up front — a member fires `[:scoria, :observe, :event, :emit]` telemetry and returns `:ok`; a non-member returns `{:error, :unknown_event}` with NO telemetry executed. Never raises, including on malformed non-map/no-`:name` input via an added catch-all clause. Moduledoc documents the reserved-only `user_feedback_received` vocabulary member and the D-00b forward flag (a future OTLP exporter must ship `guardrail_triggered` as a log record, never an OTel span event).
- The `[:scoria, :observe, :event, :emit]` handler in `Scoria.Observe.Telemetry` is the boundary of record: added to `@events` (so `attach/1` subscribes it), independently re-checks `Semconv.event_name?/1` (closing the raw-bus bypass around `emit_event/1`), redacts through a single collapsed `defp redact/1` shared with the span/delta clauses (exactly one `Redactor.redact(` token in the file, drift-guard-locked), runs the fail-closed seam (defaults a missing/nil `time`, drops a `nil` `span_id` via `reject_event/2` before Bounds ever sees it), activates `Bounds.enforce(_, :event)`, and casts via the new fixed-key `buffer_event/1` (`@event_buffer_fields ~w(span_id name time attributes)a`).
- `reject_event/2` unconditionally emits `[:scoria, :observe, :event, :rejected]` telemetry and gates a `Logger.warning` (pointing at "edit Semconv @event_names") once per distinct event name per node via the lazy-create ETS `:ets.insert_new` idiom `ReviewerBroadcast`/`Bounds` already use. A rejected event is never persisted.
- CHANGELOG Unreleased gained an entry for the new `emit_event/1` surface, naming the reserved-only vocabulary member and the deliberate v3.6 gap: a fired `guardrail_triggered` lands in Postgres with no operator UI yet.
- Added a single-file source-scan drift guard (reads only `lib/scoria/observe/telemetry.ex`, never `Path.wildcard`) asserting exactly one `Redactor.redact(` occurrence, plus 4 `:event`-handler integration tests and 4 `emit_event/1` synchronous-contract unit tests.

## Task Commits

Each task was committed atomically:

1. **Task 1: Scoria.Observe.emit_event/1 + moduledoc + CHANGELOG** - `19c0d00b` (feat)
2. **Task 2: :event telemetry handler — allow-list re-check, single redact, fail-closed seam, Bounds, cast_event** - `53382fa4` (feat)
3. **Task 3: Single-redact-site drift guard + emit_event return-contract unit test** - `05bc4c79` (test)

_No plan-metadata commit in worktree mode — the orchestrator handles the final docs/state commit centrally after the wave merges._

## Files Created/Modified

- `lib/scoria/observe.ex` - Adds `emit_event/1` (+ catch-all clause) and the corresponding moduledoc section (reserved vocabulary, D-00b forward flag)
- `lib/scoria/observe/telemetry.ex` - Adds `[:scoria, :observe, :event, :emit]` to `@events`, the handler clause, collapsed `defp redact/1`, `@event_buffer_fields`/`buffer_event/1` (with atom->string `:name` stringification), `reject_event/2` + its ETS dedupe table
- `CHANGELOG.md` - Unreleased entry announcing `emit_event/1` + the reserved vocabulary + the no-operator-UI gap
- `test/scoria/observe/telemetry_test.exs` - Drift guard + 4 `:event`-handler integration tests
- `test/scoria/observe/observe_test.exs` - 4 `emit_event/1` synchronous return-contract unit tests

## Decisions Made

- Added a catch-all `emit_event(_event), do: {:error, :unknown_event}` clause beyond the plan-literal `%{name: name} = event when is_map(event)` signature — a non-map or no-`:name` input would otherwise raise a bare `FunctionClauseError` before ever reaching the primary clause's own `try/rescue` body, which would silently defeat the must-have "NEVER raises" truth (Rule 2: closing a missing-input-validation gap the plan's literal signature alone left open).
- `buffer_event/1` stringifies the atom `:name` value via `Map.update(:name, nil, &to_string/1)` before handing off to `Buffer.cast_event/2`. `Semconv.event_names/0` is an atom vocabulary (D-03a) but `ai_span_events.name` is a `:string` Ecto column, and `Buffer.cast_event/2` feeds straight into `Repo.insert_all/2`, which bypasses changeset casting entirely — an un-stringified atom would raise a type-mismatch at flush time and silently vanish (caught only by `Buffer`'s own internal rescue+log). Found via a throwaway integration smoke test before writing Task 3's real tests; fixed inline (Rule 1).
- The drift-guard's own explanatory comment intentionally reads "Redactor.redact/1" rather than "Redactor.redact(" so the source-scan guard's literal-token count isn't inflated by its own comment.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing input validation] Added a catch-all `emit_event/1` clause**
- **Found during:** Task 1, while verifying the "never raises" acceptance criterion against a non-map/no-`:name` input
- **Issue:** The plan-literal `def emit_event(%{name: name} = event) when is_map(event)` signature raises a `FunctionClauseError` for any input that doesn't match that shape, before that clause's own `try/rescue` body ever executes — silently violating the frontmatter's must-have "NEVER raises (try/rescue → :ok)" truth for malformed callers.
- **Fix:** Added `def emit_event(_event), do: {:error, :unknown_event}` as a fallback clause.
- **Files modified:** `lib/scoria/observe.ex`
- **Commit:** `19c0d00b`

**2. [Rule 1 - Bug] `buffer_event/1` now stringifies the atom `:name` value**
- **Found during:** Task 2, via a throwaway manual integration smoke test (not part of the committed test suite) exercising the full emit -> handler -> Buffer -> Postgres path
- **Issue:** `Repo.insert_all/2` (used by `Buffer`'s `flush_events/2`) bypasses Ecto changeset casting entirely; passing the atom `:prompt_rendered` against the `:string`-typed `ai_span_events.name` column raised `value :prompt_rendered for Scoria.Repo.SpanEvent.name in insert_all does not match type :string`, caught only by `Buffer`'s own rescue+log — every real event would have silently failed to persist.
- **Fix:** `buffer_event/1` now converts the `:name` field to a string via `Map.update(:name, nil, &to_string/1)` as part of its fixed-key projection.
- **Files modified:** `lib/scoria/observe/telemetry.ex`
- **Commit:** `53382fa4`

## Issues Encountered

- The worktree had no fetched `deps`/compiled `_build` on first invocation. Copied both (gitignored, no repo changes) from the main checkout at `/Users/jon/projects/scoria` to avoid a full re-fetch/recompile, mirroring Plan 02's documented approach. `mix compile` was clean immediately after.
- Local Postgres was reachable this time via the published `55432:5432` port on `scoria-native-postgres-1` (no port-remapping workaround needed, unlike Plan 02's environment note).
- A full unscoped `mix test` run timed out after 2 minutes (pre-existing repo-wide slowness/residual failures noted elsewhere in project history, e.g. Phase 42 P03) and, as a side effect, regenerated several tracked build-artifact `.dag` files under `examples/support_copilot/deps/**/_build/**` (unrelated to this plan's `files_modified`). Reverted those 8 files via `git checkout --` before committing Task 3 — out of scope per the deviation-rules scope boundary, not part of this plan's work.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

`emit_event/1` and the `:event` handler are the hard prerequisite Plan 04 (real call sites: guardrail + judge feedback) and Plan 05 (SC canaries + integration tests, including the full DB-persistence rejection proof for both the direct and raw-bus paths) build on. No blockers identified.

**Process note (not a code deviation, mirrors Plan 01's precedent):** This plan's frontmatter lists `requirements: [EVENT-02]`, and Plan 05 also lists `requirements: [EVENT-02, EVENT-03]` as the phase's SC-canary/integration-proof terminal plan. Following Plan 01's documented convention, `.planning/REQUIREMENTS.md`'s `EVENT-02` checkbox is intentionally left unmarked here — the full end-to-end SC#2 (raw-bus rejection) and SC#1 (identical redaction) proofs Plan 05 delivers are what genuinely closes EVENT-02's stated acceptance bar, even though this plan implements the application-layer wiring the requirement describes. Final `[x]` marking should happen at Plan 05 or phase/wave close.

---
*Phase: 53B-ai-span-events-emit-event-1*
*Completed: 2026-07-18*

## Self-Check: PASSED

- FOUND: lib/scoria/observe.ex
- FOUND: lib/scoria/observe/telemetry.ex
- FOUND: CHANGELOG.md
- FOUND: test/scoria/observe/telemetry_test.exs
- FOUND: test/scoria/observe/observe_test.exs
- FOUND: .planning/phases/53B-ai-span-events-emit-event-1/53B-03-SUMMARY.md
- FOUND commit: 19c0d00b (Task 1)
- FOUND commit: 53382fa4 (Task 2)
- FOUND commit: 05bc4c79 (Task 3)
