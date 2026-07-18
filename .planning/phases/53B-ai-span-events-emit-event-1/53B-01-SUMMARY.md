---
phase: 53B-ai-span-events-emit-event-1
plan: 01
subsystem: observability
tags: [ecto, migration, telemetry, semconv, event-vocabulary]

# Dependency graph
requires:
  - phase: 53-structured-child-spans-write-time-bound
    provides: ai_span_events table, ai_spans.parent_id FK-free-by-construction precedent, Bounds :event arm (unit-tested, unactivated)
provides:
  - Core-lane migration dropping the ai_span_events.span_id immediate FK (orphan events become insertable)
  - Semconv closed 3-atom event vocabulary (@event_names / event_names/0 / event_name?/1)
  - Semconv scoria.prompt.template_ref registry key (class :id) + prompt_template_ref_key/0 accessor
  - Vocabulary unit tests + user_feedback_received reserved-only grep guard
affects: [53B-02 (Buffer event list + ordered flush), 53B-03 (emit_event/1 + :event telemetry handler — hard prerequisite on this plan), 53B-04 (guardrail + judge call sites), 53B-05 (SC canaries + integration tests)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Closed atom vocabulary + membership-only predicate (event_name?/1) mirroring @guardrail_names/guardrail_names/0 — never String.to_atom on inbound data"
    - "Core-lane DROP CONSTRAINT IF EXISTS migration with an exact re-ADD CONSTRAINT down/1, following converge_eval_persistence.exs:117,144"

key-files:
  created:
    - priv/repo/migrations/20260718230000_drop_ai_span_events_span_id_fk.exs
  modified:
    - lib/scoria/observe/semconv.ex
    - test/scoria/observe/semconv_test.exs

key-decisions:
  - "Migration timestamp 20260718230000 (today, sorts after the last existing migration 20260704235536) — the plan's cited phantom 20260712210000_* migration does not exist in the repo (D-00a) and was not cited anywhere in this work."
  - "span_id stays NOT NULL and indexed; only the FK constraint is dropped (D-01b) — verified via pg_constraint query showing 0 rows post-migrate and \\d ai_span_events showing span_id still NOT NULL with its btree index intact."
  - "event_names/0 vocabulary is 3 ATOMS (not strings), mirroring @guardrail_names' string-list shape but per D-03a's drift-proof/pattern-matchable requirement; event_name?/1 is membership-only, never coerces via String.to_atom."
  - "Added scoria.prompt.template_ref to @attribute_registry as class :id and updated the pre-existing registry canary test (SEC-01 Test 1, an exact sorted-key-list assertion) to include the new key — otherwise Task 3 would have broken that test."

patterns-established:
  - "Reserved-but-unemitted vocabulary member (user_feedback_received) enforced by a grep guard over a hardcoded producer-file list, not Path.wildcard — mirrors the existing scoria.retrieval./host-declared-keys anti-inline guard template at semconv_test.exs:128-142."

requirements-completed: [EVENT-02, EVENT-03]

coverage:
  - id: D1
    description: "Core-lane migration drops the ai_span_events.span_id immediate FK; span_id stays NOT NULL and indexed; rollback/reapply round-trips cleanly on scoria_dev and scoria_test"
    requirement: "EVENT-02"
    verification:
      - kind: other
        ref: "mix ecto.migrate / mix ecto.rollback --step 1 / mix ecto.migrate (manual run against scoria_dev, port 5432) + psql pg_constraint query confirming absence"
        status: pass
    human_judgment: false
  - id: D2
    description: "Semconv exposes event_names/0 (3-atom closed list) and event_name?/1 (membership-only, string/atom-drift-proof)"
    requirement: "EVENT-02"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#event_names/0 + event_name?/1 closed vocabulary (EVENT-02, D-03a/D-03c)"
        status: pass
    human_judgment: false
  - id: D3
    description: "scoria.prompt.template_ref registered as an :id-class attribute key with prompt_template_ref_key/0 accessor"
    requirement: "EVENT-03"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#prompt_template_ref_key/0 (EVENT-02, D-04c)"
        status: pass
    human_judgment: false
  - id: D4
    description: "No lib/ file wires a user_feedback_received emitter — grep-guard goes RED if one is added"
    requirement: "EVENT-03"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#anti-inline grep: user_feedback_received has ZERO lib/ emitters (D-04d reserved-only guard)"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-18
status: complete
---

# Phase 53B Plan 01: FK-drop migration + closed event vocabulary Summary

**Core-lane migration dropping the ai_span_events.span_id FK (orphan events now insertable) plus Semconv's closed 3-atom point-event vocabulary and the new scoria.prompt.template_ref registry key.**

## Performance

- **Duration:** ~10 min
- **Completed:** 2026-07-18
- **Tasks:** 3/3
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments
- New core-lane migration `20260718230000_drop_ai_span_events_span_id_fk.exs` drops `ai_span_events_span_id_fkey` (IF EXISTS) so an orphan event whose span never flushed is insertable rather than raising Postgrex 23503; `span_id` stays `NOT NULL` and indexed; `down/1` re-adds the exact FK for a clean rollback. Verified round-trip (migrate → rollback → migrate) against the real `scoria_dev` and `scoria_test` databases.
- `Semconv.@event_names` / `event_names/0` / `event_name?/1` — a closed, drift-proof 3-atom vocabulary (`prompt_rendered`, `guardrail_triggered`, `user_feedback_received`) mirroring the existing `@guardrail_names` shape. `event_name?/1` is a pure membership check — never coerces a string via `String.to_atom`.
- `Semconv.prompt_template_ref_key/0` returns the new `"scoria.prompt.template_ref"` registry key (class `:id`), mirroring `prompt_context_key/0`; the key is now admitted by `attribute_registry/0`.
- 8 new unit tests lock the vocabulary contract, the template_ref key, and registry admission; a reserved-only grep guard proves no `lib/` file currently wires a `:user_feedback_received` emitter (GREEN on arrival, will go RED if one is added, points to SEED-011 / FB-01 in its failure message).

## Task Commits

Each task was committed atomically:

1. **Task 1: Core-lane migration dropping the ai_span_events.span_id FK** - `061754d6` (feat)
2. **Task 2: Add the closed event vocabulary + template_ref registry key to Semconv** - `4fbe498e` (feat)
3. **Task 3: Vocabulary unit tests + user_feedback_received zero-emitter grep guard** - `362fbdca` (test)

_No plan-metadata commit in this worktree — SUMMARY.md is committed separately per worktree-mode convention; STATE.md/ROADMAP.md are owned by the orchestrator after wave merge._

## Files Created/Modified
- `priv/repo/migrations/20260718230000_drop_ai_span_events_span_id_fk.exs` - New core-lane migration; drops the `ai_span_events.span_id` FK, keeps column NOT NULL + indexed, exact reversible `down/1`
- `lib/scoria/observe/semconv.ex` - Adds `@event_names`/`event_names/0`/`event_name?/1` and `@prompt_template_ref_key`/`prompt_template_ref_key/0`; registers the new key in `@attribute_registry` as class `:id`
- `test/scoria/observe/semconv_test.exs` - Adds vocabulary contract tests, template_ref key tests, the reserved-only anti-inline grep guard, and updates the pre-existing registry canary (SEC-01 Test 1) to include the new key

## Decisions Made
- Migration timestamp chosen as `20260718230000` (today's date, sorts after the last existing migration `20260704235536`) since the plan's cited `20260712210000_*` precedent does not exist in the repo (confirmed absent, per phase CONTEXT D-00a) — this plan cites only the two real precedents (`ai_spans.parent_id` FK-free-by-construction and `converge_eval_persistence.exs:117,144`'s `DROP CONSTRAINT IF EXISTS` idiom).
- Verified the FK-drop against the real native Postgres instance backing `scoria_dev`/`scoria_test` (port 5432, not the unpublished-port `scoria-native-postgres-1` Docker container) since the container publishes no host port per the project's no-published-DB Docker DX convention — migrated both databases so Task 3's test run has parity.
- Updated the pre-existing `attribute_registry/0` registry canary test (an exact sorted-key-list assertion, SEC-01 Test 1) to include the new `scoria.prompt.template_ref` key — this is a required, in-scope edit to the same Task-3 test file (not a deviation), since the canary is specifically designed to force a deliberate edit whenever the registry grows.

## Deviations from Plan

None - plan executed exactly as written. All three tasks matched their `<action>` instructions and acceptance criteria; no Rule 1-4 auto-fixes were needed.

## Issues Encountered
- The worktree had no fetched deps (`mix deps.get` required) and no compiled `_build` on first invocation — resolved by running `mix deps.get` then `mix compile` before any verification step; not a plan deviation, just first-run worktree setup.
- The default `SCORIA_DB_PORT` (55432, pointed at the unpublished-port Docker container `scoria-native-postgres-1`) was unreachable from the host; resolved by pointing at the real native Postgres on port 5432 (where `scoria_dev`/`scoria_test` already existed) for all `mix ecto.migrate`/`rollback`/`test` invocations in this plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Gates SC#4 (FK drop) and SC#2 (closed vocabulary) for the rest of Phase 53B: Plan 02 (Buffer event list + two-phase flush) and Plan 03 (`emit_event/1` + the `:event` telemetry handler, which hard-depends on both this plan and Plan 02) can now proceed.
- `Semconv.event_name?/1` is ready to be the single membership source of truth for both `emit_event/1` and the `:event` telemetry handler in Plan 03 — neither may inline its own name list.
- No blockers identified.

---
*Phase: 53B-ai-span-events-emit-event-1*
*Completed: 2026-07-18*

## Self-Check: PASSED

- FOUND: priv/repo/migrations/20260718230000_drop_ai_span_events_span_id_fk.exs
- FOUND: lib/scoria/observe/semconv.ex
- FOUND: test/scoria/observe/semconv_test.exs
- FOUND: .planning/phases/53B-ai-span-events-emit-event-1/53B-01-SUMMARY.md
- FOUND commit: 061754d6 (Task 1)
- FOUND commit: 4fbe498e (Task 2)
- FOUND commit: 362fbdca (Task 3)
- FOUND commit: e848eed0 (docs: summary)
