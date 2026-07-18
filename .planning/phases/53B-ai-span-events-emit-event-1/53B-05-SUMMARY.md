---
phase: 53B-ai-span-events-emit-event-1
plan: 05
subsystem: observability
tags: [telemetry, redaction, bounds, ecto, postgres, ex_unit]

requires:
  - phase: 53B-01
    provides: "the FK drop on ai_span_events.span_id (orphan events insertable)"
  - phase: 53B-02
    provides: "emit_event/1 closed-vocabulary facade + Semconv.event_name?/1"
  - phase: 53B-03
    provides: "Telemetry.handle_event/4's [:scoria, :observe, :event, :emit] handler (redact -> default_time -> reject_if_nil_span_id -> Bounds.enforce(_, :event) -> Buffer.cast_event/2), plus the [:scoria, :observe, :event, :rejected] signal"
  - phase: 53B-04
    provides: "real emit_event/1 call sites (prompt_rendered, guardrail_triggered)"
provides:
  - "test/scoria/observe/event_emit_test.exs — the phase's SC canary suite (6 tests, all green): SC#1 identical redaction, SC#2 closed vocabulary on both the direct and raw-bus paths, SEC-01 Bounds:event end-to-end wiring, SC#4 orphan isolation, D-05 fail-closed batch atomicity"
affects: [53B-verification, 54-docs-accuracy-conformance-check]

tech-stack:
  added: []
  patterns:
    - "DB-backed telemetry test scaffold (Sandbox checkout + {:shared, self()} + scoped Buffer + Telemetry.attach onto that buffer + flush_now, no Process.sleep) reused verbatim from prompt_span_test.exs/telemetry_test.exs"
    - "Redactor's adopter-facing deny_list config seam used to redact a Bounds-registered key for a test that must observe a surviving [REDACTED] placeholder (rather than one of Redactor's hardcoded deny-listed keys, none of which are Bounds-registered)"

key-files:
  created:
    - test/scoria/observe/event_emit_test.exs
  modified: []

key-decisions:
  - "SC#1's deny-listed test key is 'session_id' (Bounds-registered, class :id) configured into Redactor's deny_list via Application.put_env, not one of Redactor's 4 hardcoded default deny-listed keys (password/api_key/token/secret) — none of which are Bounds-registered, so Bounds.enforce/2 would DROP them entirely post-redaction (proven by telemetry_test.exs's existing span-level 'password' case), leaving no '[REDACTED]' marker to assert on."
  - "D-05's second test asserts the REAL behavior of each malformed raw-bus event rather than the plan's literal 'both dropped' wording: a nil span_id is dropped at the handler (never reaches insert_all); a missing/nil time is DEFAULTED to DateTime.utc_now() by default_time/1 and DOES persist. Both mechanisms independently prevent a NOT NULL crash from rolling back the batch, which is the guarantee that actually matters."

patterns-established: []

requirements-completed: [EVENT-02, EVENT-03]

coverage:
  - id: D1
    description: "SC#1: a deny-listed event attribute is redacted through the identical Redactor.redact/1 call site spans use, end-to-end against real Postgres; an allow-listed attribute (scoria.prompt.template_ref) survives intact"
    requirement: "EVENT-02"
    verification:
      - kind: integration
        ref: "test/scoria/observe/event_emit_test.exs#SC#1: identical redact integration proof (EVENT-02) a deny-listed event attribute is redacted through the identical Redactor.redact/1 call site spans use; an allow-listed attribute survives intact"
        status: pass
    human_judgment: false
  - id: D2
    description: "SC#2 direct path: emit_event/1 with an unknown name returns {:error, :unknown_event} and persists nothing"
    requirement: "EVENT-02"
    verification:
      - kind: integration
        ref: "test/scoria/observe/event_emit_test.exs#SC#2: closed vocabulary rejected on both the direct and raw-bus paths (EVENT-02) direct path: emit_event/1 with an unknown name returns {:error, :unknown_event} and persists nothing"
        status: pass
    human_judgment: false
  - id: D3
    description: "SC#2 raw-bus path: a hand-synthesized :telemetry.execute bypass of emit_event/1 is rejected at the handler (never persisted) and fires [:scoria, :observe, :event, :rejected]"
    requirement: "EVENT-02"
    verification:
      - kind: integration
        ref: "test/scoria/observe/event_emit_test.exs#SC#2: closed vocabulary rejected on both the direct and raw-bus paths (EVENT-02) raw-bus path: a hand-synthesized :telemetry.execute bypass is rejected at the handler and fires [:scoria, :observe, :event, :rejected] (D-03b)"
        status: pass
    human_judgment: false
  - id: D4
    description: "SEC-01: Bounds.enforce(_, :event) proven wired end-to-end — an oversized registered attribute value is truncated and an unregistered attribute key is dropped in the persisted event row, exactly as a span attribute would be"
    requirement: "EVENT-03"
    verification:
      - kind: integration
        ref: "test/scoria/observe/event_emit_test.exs#SEC-01: Bounds.enforce(_, :event) proven wired end-to-end (D-06a/D-06i) an oversized registered attribute value is truncated and an unregistered attribute key is dropped in the persisted event row, exactly as a span attribute would be"
        status: pass
    human_judgment: false
  - id: D5
    description: "SC#4: 50 real spans persist; the orphan emit_event/1 row EXISTS with its dangling span_id; no span exists for that id (forces the FK drop)"
    requirement: "EVENT-02"
    verification:
      - kind: integration
        ref: "test/scoria/observe/event_emit_test.exs#SC#4: orphan isolation forces the FK drop (D-01/D-05) 50 real spans persist; the orphan emit_event/1 row EXISTS with its dangling span_id; no span exists for that id"
        status: pass
    human_judgment: false
  - id: D6
    description: "D-05 fail-closed: a nil-span_id raw-bus event is dropped; a missing-time raw-bus event is defaulted and persists; 50 good sibling events land in the same batch (no rollback)"
    requirement: "EVENT-03"
    verification:
      - kind: integration
        ref: "test/scoria/observe/event_emit_test.exs#D-05 fail-closed: malformed raw-bus events cannot roll back a batch of good siblings a nil-span_id event is dropped; a missing-time event is defaulted and persists; 50 good sibling events land in the same batch"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-07-18
status: complete
---

# Phase 53B Plan 05: Emit-Event Acceptance Canary Suite Summary

**New `test/scoria/observe/event_emit_test.exs` proves SC#1 (identical redaction), SC#2 (closed vocabulary on both the direct and raw-bus paths), SC#4 (orphan isolation), D-05 (fail-closed batch atomicity), and SEC-01 (Bounds:event wiring) end-to-end against the real telemetry -> handler -> Buffer -> Postgres pipeline — all 6 tests green, full suite green except one pre-existing, confirmed-unrelated flake.**

## Performance

- **Duration:** ~20 min
- **Completed:** 2026-07-18
- **Tasks:** 3 (all landed in a single atomic commit since they build one cohesive test file)
- **Files modified:** 2 (1 created: the test file; 1 created: phase deferred-items.md)

## Accomplishments

- **SC#1** proven: a deny-listed event attribute is redacted through the identical `Redactor.redact/1` call site spans use, while an allow-listed attribute (`scoria.prompt.template_ref`) survives byte-for-byte, real Postgres round-trip.
- **SC#2** proven on both paths: `emit_event/1` rejects an unknown name synchronously (`{:error, :unknown_event}`, zero persisted rows), and a raw `:telemetry.execute` bypass of the public facade is independently rejected at the handler boundary, firing `[:scoria, :observe, :event, :rejected]` and persisting nothing.
- **SEC-01** proven: `Bounds.enforce(_, :event)` is wired end-to-end — an oversized registered value is truncated with the `…[TRUNCATED]` suffix, an unregistered key is dropped, and the `scoria.attributes.dropped` marker is written to the persisted row.
- **SC#4** proven: 50 real spans (via `Observe.with_tool/3`) persist alongside 1 orphan `emit_event/1` event whose `span_id` was never emitted as a span — the orphan event row EXISTS (forcing the FK-drop guarantee from Plan 53B-01), and no span exists for that dangling id.
- **D-05** proven: a nil-`span_id` raw-bus event is dropped at the handler; a missing-`time` raw-bus event is defaulted to `DateTime.utc_now()` and persists; both cannot roll back the same batch's 50 valid sibling events (exact count assertion: 51 persisted, not 52 or fewer).

## Task Commits

All three tasks were implemented as one cohesive test file (they share setup/scaffold and were verified together) and committed atomically:

1. **Task 1 (SC#1) + Task 2 (SC#2 + SEC-01) + Task 3 (SC#4 + D-05)** - `b1f5264f` (test)

**Plan metadata:** committed as part of this same summary-closing commit per worktree-mode convention (STATE.md/ROADMAP.md excluded; orchestrator updates those centrally after merge).

## Files Created/Modified

- `test/scoria/observe/event_emit_test.exs` - the phase's SC canary suite (6 tests: SC#1, SC#2 direct, SC#2 raw-bus, SEC-01, SC#4, D-05)
- `.planning/phases/53B-ai-span-events-emit-event-1/deferred-items.md` - logs the pre-existing, confirmed-unrelated `capture_parity_test.exs` full-suite flake

## Decisions Made

- **SC#1 key choice:** used `"session_id"` (a real `Semconv.attribute_registry/0` member, class `:id`) configured into `Redactor`'s `deny_list` via `Application.put_env(:scoria, Scoria.Observe.Redactor, deny_list: ["session_id"])`, restored via `on_exit`, rather than one of Redactor's 4 hardcoded default deny-listed keys (`password`/`api_key`/`token`/`secret`). None of those four are Bounds-registered keys — `telemetry_test.exs`'s existing span-level test already documents that `Bounds.enforce/2` DROPS an unregistered key entirely even after `Redactor.redact/1` turns its value into `"[REDACTED]"` (the stricter tier wins). Redacting `"password"` here would have proven the opposite of SC#1: the key would be absent from the persisted row, not `"[REDACTED]"`. Using Redactor's own real adopter-facing config extension point on a registered key exercises the identical call site and produces a row where the marker is actually observable.
- **D-05 second-test wording correction:** the plan's task text says both the nil-`span_id` and missing-`time` raw-bus events are "dropped." Reading `Telemetry.handle_event/4` shows these are two different mechanisms: `reject_if_nil_span_id/2` truly drops the nil-`span_id` case (never reaches `insert_all`), but `default_time/1` DEFAULTS a missing/nil `time` to `DateTime.utc_now()` and lets it continue to `Bounds.enforce/2` and persistence. The test asserts each event's real, distinct outcome rather than the plan's literal (and, for the missing-time case, inaccurate) claim, while still proving the D-05 guarantee that matters: neither malformed event crashes or rolls back the batch of 50 good siblings (asserted via an exact `51`-row count).

## Deviations from Plan

### Auto-fixed Issues

No Rule 1/2/3 code auto-fixes were needed — no production `lib/` files were touched by this plan (test-only, matching the plan's `files_modified` scope).

### Test-design deviations (documented above under Decisions Made)

**1. [Test-design adaptation] SC#1 redaction key required Redactor's config-based deny_list, not a hardcoded default key**
- **Found during:** Task 1 (SC#1 identical-redact integration proof)
- **Issue:** The plan instructed picking "a deny-listed key from the Redactor's actual deny-list." None of Redactor's 4 hardcoded default deny-listed keys (`password`/`api_key`/`token`/`secret`) are members of `Semconv.attribute_registry/0`; `Bounds.enforce/2` (which runs immediately after redaction in the real handler) drops any unregistered key ENTIRELY — the redacted value never survives to be observed. Using one of those 4 keys as written would have made the persisted row show the key ABSENT, disproving rather than proving SC#1's literal truths claim ("...comes back [REDACTED] in the persisted ai_span_events row").
- **Fix:** Used Redactor's own real, documented adopter-facing config extension (`config :scoria, Scoria.Observe.Redactor, deny_list: [...]`) to add `"session_id"` (a real Bounds-registered key) to the deny list for the duration of the test only, restored via `on_exit`. This still calls the real `emit_event/1` and the real `Redactor.redact/1` function — nothing is hand-synthesized or mocked.
- **Files modified:** test/scoria/observe/event_emit_test.exs
- **Verification:** `mix test test/scoria/observe/event_emit_test.exs` (SC#1 test green); full-suite `mix test --warnings-as-errors` shows no side effects from the config change (restored via `on_exit`).
- **Committed in:** b1f5264f

**2. [Test-design adaptation] D-05's "missing time" case is defaulted, not dropped**
- **Found during:** Task 3 (D-05 fail-closed batch atomicity test)
- **Issue:** The plan's literal wording claims both the nil-`span_id` and missing-`time` raw-bus events are "dropped." Reading `Telemetry.handle_event/4`'s `default_time/1` shows a missing/nil `time` is filled with `DateTime.utc_now()` and the event CONTINUES to `Bounds.enforce/2` and `Buffer.cast_event/2` — it is not dropped, it persists with a defaulted, valid time.
- **Fix:** Wrote the assertion to match the real, distinct behavior of each case (nil `span_id` → dropped / no row; missing `time` → persists with a valid `%DateTime{}`), while still proving the D-05 guarantee that matters — an exact `51`-row count (50 good + 1 defaulted survivor) proves neither malformed event crashed or rolled back the batch.
- **Files modified:** test/scoria/observe/event_emit_test.exs
- **Verification:** `mix test test/scoria/observe/event_emit_test.exs` (D-05 test green, asserts `%DateTime{} = persisted_time_defaulted.time` and `Repo.aggregate(SpanEvent, :count) == 51`).
- **Committed in:** b1f5264f

---

**Total deviations:** 2 test-design adaptations (both driven by reading actual `lib/` behavior rather than the plan's literal wording; zero production code changes).
**Impact on plan:** Both truths (SC#1, D-05) are still proven — just via assertions that match the real, already-shipped pipeline behavior instead of a wording mismatch in the plan text. No scope creep; no `lib/` files touched.

## Issues Encountered

- **Worktree had no `deps`/`_build`.** This worktree was freshly created with no fetched dependencies. Ran `mix deps.get` (Hex-only, no network-sensitive git deps) and `MIX_ENV=test mix compile` to establish a working build before any test could run. Confirmed the shared Postgres instance was already reachable and migrated (`mix ecto.migrate` reported "Migrations already up").
- **Full-suite pre-existing flake.** `mix test --warnings-as-errors` (3 doctests + 1312 tests) reported exactly 1 failure: `Scoria.WarningInventory.CaptureParityTest` "optimized compile-only capture catches high-signal unclassified warning (injected)". This is the same recurring SEED-004-class subprocess-race flake already logged repeatedly in Phase 53's `deferred-items.md` (Plans 53-01/53-04/53-07). Re-ran `mix test test/scoria/warning_inventory/capture_parity_test.exs` in isolation immediately after: **2 tests, 0 failures**. `git diff --stat` confirms zero `lib/` changes from this plan — logged to this phase's new `deferred-items.md`, not fixed (out of scope).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All four ROADMAP success criteria for Phase 53B (SC#1, SC#2, SC#4, plus SC#3 from Plan 04) are now proven end-to-end by an executable test suite, alongside the D-05 fail-closed corollary and the SEC-01 Bounds:event wiring corollary.
- `mix test test/scoria/observe/event_emit_test.exs` is the canonical acceptance-bar command for this phase; it is green, and `mix test --warnings-as-errors` (full suite) is green modulo the pre-existing, unrelated `capture_parity_test.exs` flake.
- No blockers for Phase 54 (docs accuracy + conformance check).

---
*Phase: 53B-ai-span-events-emit-event-1*
*Completed: 2026-07-18*

## Self-Check: PASSED

- FOUND: test/scoria/observe/event_emit_test.exs
- FOUND: .planning/phases/53B-ai-span-events-emit-event-1/deferred-items.md
- FOUND: .planning/phases/53B-ai-span-events-emit-event-1/53B-05-SUMMARY.md
- FOUND commit: b1f5264f
