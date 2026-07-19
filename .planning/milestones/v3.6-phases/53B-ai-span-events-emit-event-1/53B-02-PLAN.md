---
phase: 53B-ai-span-events-emit-event-1
plan: 02
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/scoria/observe/buffer.ex
  - test/scoria/observe/buffer_test.exs
autonomous: true
requirements: [EVENT-02]
must_haves:
  truths:
    - "Buffer state carries a SEPARATE events list with its own cap (max_event_size) and its own failure counter (event_consecutive_failures), independent of spans (D-02a)."
    - "Buffer.cast_event/2 mirrors cast_span/2; an over-cap event is dropped + Logger.warning'd, parity with spans (D-02a/D-02c)."
    - "do_flush runs two ordered phases: the UNCHANGED traces→spans Ecto.Multi first, then a SEPARATE Repo.insert_all(SpanEvent, ...) in its own try/rescue that runs regardless of Phase 1's outcome (D-02b) — spans committed in Phase 1 can never be touched by an event-flush failure."
    - "Event flush errors reuse surface_flush_error parameterized by signal: :span | :event with an independent storm counter; the GenServer never crashes; :raise reraises on the timer path only (D-02e)."
  artifacts:
    - "Buffer state fields events, max_event_size, event_consecutive_failures"
    - "Buffer.cast_event/2, the {:cast_event, ...} handle_cast clause"
    - "Buffer.flush_events/2 (Phase 2 of do_flush); surface_flush_error/* gains a signal dimension"
  key_links:
    - "The Plan 03 telemetry handler calls Buffer.cast_event/2 after redact + fail-closed seam + Bounds.enforce(_, :event)."
    - "flush_now/1 stays byte-for-byte (D-02d) — it routes through the two-phase do_flush, so the one synchronous test hook proves both the ordered-flush and (in Plan 05) the SC#4 orphan test."
---

<objective>
Give `Buffer` a second, independently-capped `events` accumulation and a two-phase `do_flush`: Phase 1 is the existing traces→spans `Ecto.Multi` (unchanged), Phase 2 is a SEPARATE `Repo.insert_all(SpanEvent, ...)` in its own `try/rescue` that runs regardless of Phase 1's outcome. This is the structural half of SC#4 — because events flush in a transaction separate from spans, any event-insert failure is incapable of rolling back already-committed spans.

Purpose: EVENT-02's ordered flush (traces → spans → events) and the "orphan can never sink a batch of good spans" isolation both live here; the FK drop (Plan 01) removes the dominant raise class, this separation earns the SC's word "never."
Output: extended Buffer state, `cast_event/2`, two-phase `do_flush` + `flush_events/2`, a `signal`-parameterized `surface_flush_error`, and buffer-level flush tests.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/53B-ai-span-events-emit-event-1/53B-CONTEXT.md
@.planning/phases/53B-ai-span-events-emit-event-1/53B-RESEARCH.md
@.planning/phases/53B-ai-span-events-emit-event-1/53B-PATTERNS.md

@lib/scoria/observe/buffer.ex
@lib/scoria/repo/span_event.ex
@test/scoria/observe/buffer_test.exs
</context>

<artifacts>
NEW symbols this plan produces:
- Buffer state fields: `events` (list), `max_event_size` (default 1000), `event_consecutive_failures` (0)
- `Buffer.cast_event/2` + the `{:cast_event, event_data}` `handle_cast` clause
- `Buffer.flush_events/2` (Phase 2 of `do_flush`)
- `surface_flush_error/*` gains a `signal: :span | :event` parameter (same function, one new dimension — NOT a new function)
</artifacts>

<tasks>

<task type="auto">
  <name>Task 1: Extend Buffer state + cast_event/2 + buffer-full drop</name>
  <files>lib/scoria/observe/buffer.ex</files>
  <read_first>
    - lib/scoria/observe/buffer.ex:14-16 (cast_span/2), :33-41 (state map), :48-55 (handle_cast buffer-full drop+warn), :23-25 (flush_now/1)
  </read_first>
  <action>
    Mirror the span fields to add `events: []`, `max_event_size: Keyword.get(opts, :max_event_size, @default_max_size)`, and `event_consecutive_failures: 0` to the state map (buffer.ex:33-41), per D-02a — a SEPARATE list with its OWN cap and OWN counter (rejected: a tagged unified list; rejected: a second GenServer). Add `cast_event/2` mirroring `cast_span/2` (:14-16): `GenServer.cast(name, {:cast_event, event_data})` (D-02c). Add a `{:cast_event, event_data}` `handle_cast` clause mirroring the span clause at :48-55: if `length(state.events) >= state.max_event_size`, `Logger.warning(...)` and drop the newest (parity with the span buffer-full path); else prepend `[event_data | state.events]`. Do NOT couple the two caps. Leave `cast_span/2`, `flush_now/1`, and the span `handle_cast` byte-for-byte unchanged.
  </action>
  <verify>
    <automated>mix compile --warnings-as-errors 2>&amp;1 | tail -5</automated>
  </verify>
  <acceptance_criteria>
    - State map has `events`, `max_event_size`, `event_consecutive_failures`; span fields unchanged.
    - `Buffer.cast_event/2` exists with the same arity/default-name shape as `cast_span/2`.
    - The `{:cast_event, ...}` handle_cast drops+warns at `max_event_size` independently of the span cap.
    - `flush_now/1` and the span pipeline are unchanged; `mix compile --warnings-as-errors` clean.
  </acceptance_criteria>
  <done>Buffer accumulates events in a separate, independently-capped list with a mirror of the span cast/buffer-full path.</done>
</task>

<task type="auto">
  <name>Task 2: Two-phase do_flush + flush_events/2 + signal-parameterized surface_flush_error</name>
  <files>lib/scoria/observe/buffer.ex</files>
  <read_first>
    - lib/scoria/observe/buffer.ex:85-95 (do_flush), :101-169 (flush_spans/2 incl. the Ecto.Multi at :103-129 and the try/rescue at :131-168), :174-193 (surface_flush_error/4), :106-112 (Map.put_new_lazy(:id) + inserted_at/updated_at timestamps)
    - lib/scoria/repo/span_event.ex (columns: span_id, name, time, attributes — insert_all bypasses the changeset)
  </read_first>
  <action>
    Refactor `do_flush/2` into two ordered phases per D-02b. Phase 1: keep the existing traces→spans `Ecto.Multi` (buffer.ex:103-129) and its try/rescue (:131-168) UNCHANGED — factor it as `flush_spans/2` returning the new span failure count. Phase 2 (NEW): add `flush_events/2` that maps events with `Map.put_new_lazy(:id, fn -> Ecto.UUID.generate() end)` + `Map.put_new(:inserted_at, now)` + `Map.put_new(:updated_at, now)` (mirror :106-112), then runs a plain `Scoria.Repo.insert_all(Scoria.Repo.SpanEvent, event_entries)` inside its OWN try/rescue — NO `Ecto.Multi` (single table, no FK ordering after the D-01a drop), NO per-row savepoints (D-02b/D-05 — the FK drop + Plan 03 fail-closed seam make the remaining raise classes unreachable). Phase 2 runs REGARDLESS of Phase 1's outcome and returns the new `event_consecutive_failures` count. `do_flush` resets both lists and stores both counters: `%{state | spans: [], events: [], consecutive_failures: new_span_failures, event_consecutive_failures: new_event_failures}`. Extend `surface_flush_error` (:174) with a `signal: :span | :event` parameter (D-02e — same function, one new dimension) so its `[:scoria, :observe, :buffer, :flush_error]` telemetry carries the `signal`; back the event arm with the independent `event_consecutive_failures` counter (independent storm dedupe). `:raise` reraises on the timer path ONLY (`from_timer?: true`); `terminate/2` and `flush_now/1` (from_timer?: false) NEVER reraise (Phase 53 D-09i continuity). Keep `flush_now/1` byte-for-byte (D-02d).
  </action>
  <verify>
    <automated>mix test test/scoria/observe/buffer_test.exs</automated>
  </verify>
  <acceptance_criteria>
    - `do_flush` calls `flush_spans/2` then `flush_events/2`; Phase 1 (traces→spans Multi + its try/rescue) is unchanged.
    - `flush_events/2` uses a plain `Repo.insert_all(Scoria.Repo.SpanEvent, ...)` in its own try/rescue with `Map.put_new_lazy(:id)` + timestamps; no Multi, no savepoints.
    - `surface_flush_error` takes a `signal` dimension; event failures increment `event_consecutive_failures` independently of `consecutive_failures`.
    - `flush_now/1` byte-for-byte unchanged; existing span-flush tests still green.
  </acceptance_criteria>
  <done>do_flush is two ordered, independently-rescued phases; the event flush cannot roll back committed spans; storm/raise semantics are per-signal.</done>
</task>

<task type="auto">
  <name>Task 3: Buffer-level two-phase flush + event buffer-full tests</name>
  <files>test/scoria/observe/buffer_test.exs</files>
  <read_first>
    - test/scoria/observe/buffer_test.exs (existing span-flush test setup — sandbox + scoped Buffer + flush_now)
    - lib/scoria/repo/span_event.ex (row shape for a valid event: span_id, name, time, attributes)
  </read_first>
  <action>
    Add tests exercising the Buffer directly (NOT via emit_event — that is Plan 03/05). Test A (ordered two-phase happy path): `cast_span` a valid span, then `cast_event` a valid event whose `span_id` references that just-cast span, `flush_now`, and assert BOTH tables have their row (ai_spans has the span AND ai_span_events has the event) — proving traces→spans→events ordering and that Phase 2 runs and persists. Keep the event's `span_id` pointing at the same-batch span so this test is FK-state-agnostic (green whether or not the Plan 01 migration has run — Phase 1 commits the span before Phase 2 inserts the event). Test B (event buffer-full): with a small `max_event_size`, `cast_event` past the cap and assert the newest is dropped + a warning logged, while spans are unaffected (independent caps, D-02a). Do NOT hand-synthesize telemetry here — call `Buffer.cast_event/2` directly. The full orphan/SC#4 proof (real emit_event + 50 spans + dangling span_id) is Plan 05.
  </action>
  <verify>
    <automated>mix test test/scoria/observe/buffer_test.exs</automated>
  </verify>
  <acceptance_criteria>
    - Test A: after flush, exactly one ai_spans row and one ai_span_events row exist for the cast pair; ordering is spans-then-events.
    - Test B: casting past `max_event_size` drops the newest event and logs a warning; the span list/cap is untouched.
    - Tests drive `Buffer.cast_event/2` directly (no hand-synthesized `:telemetry.execute`).
  </acceptance_criteria>
  <done>The two-phase flush and independent event cap are proven at the Buffer level, FK-state-agnostic.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Buffer GenServer → Postgres | Batched `insert_all` bypasses changesets; a raw Postgrex raise in one phase must not roll back the other. |
| flush timer vs. synchronous flush_now | `:raise` mode must reraise only on the timer path, never on flush_now/terminate. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-53B-03 | DoS (data integrity) | do_flush two-phase | high | mitigate | Events flush in a SEPARATE transaction with its own try/rescue, run regardless of Phase 1 — a failing event insert can never roll back committed spans (D-02b). Proof: SC#4 in Plan 05. |
| T-53B-05 | DoS | orphan-event retry / unbounded memory | medium | accept | Persist-dangling, never retry (D-01b) — bounded retry cannot converge for a permanently-dropped span and is an unbounded-memory DoS; independent event cap drops newest on overflow. |
| T-53B-SC | Tampering | package installs | low | accept | No new packages; mix.exs untouched. |
</threat_model>

<verification>
- `mix test test/scoria/observe/buffer_test.exs` green (new + existing span-flush tests).
- `mix compile --warnings-as-errors` clean.
</verification>

<success_criteria>
Buffer accumulates and flushes events in a phase separate from spans, with independent caps/counters and per-signal error surfacing; a failing event flush cannot touch committed spans. `flush_now/1` unchanged. Provides `cast_event/2` for Plan 03's handler.
</success_criteria>

<output>
Create `.planning/phases/53B-ai-span-events-emit-event-1/53B-02-SUMMARY.md` when done.
</output>
