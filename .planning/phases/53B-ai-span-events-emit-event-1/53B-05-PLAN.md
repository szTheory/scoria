---
phase: 53B-ai-span-events-emit-event-1
plan: 05
type: execute
wave: 4
depends_on: [53B-01, 53B-02, 53B-03, 53B-04]
files_modified:
  - test/scoria/observe/event_emit_test.exs
autonomous: true
requirements: [EVENT-02, EVENT-03]
must_haves:
  truths:
    - "SC#1: a deny-listed key inside an emit_event/1 event's :attributes comes back [REDACTED] in the persisted ai_span_events row — proven end-to-end through the same Redactor.redact/1 call site spans use (real Postgres, real Telemetry.attach/1, flush_now)."
    - "SC#2: an unknown name is rejected/never-persisted via BOTH the direct emit_event/1 path ({:error, :unknown_event}) AND a raw :telemetry.execute([:scoria, :observe, :event, :emit], ...) bypass (dropped at the handler, [:scoria, :observe, :event, :rejected] fires)."
    - "SC#4: 50 real span/4 emissions + 1 real emit_event/1 orphan (its span never flushed) → 50 spans persist, the orphan event ROW EXISTS with its dangling span_id, and no span exists for that id."
    - "D-05 fail-closed: a raw-bus event with nil span_id or missing time is dropped at the handler (never reaches insert_all) while 50 good sibling events land in the same batch."
    - "SEC-01: an oversized/denied event attribute key is bounded exactly as a span attribute key is, end-to-end through the real handler (Bounds :event activation proof)."
  artifacts:
    - "test/scoria/observe/event_emit_test.exs (NEW) — the SC#1/SC#2/SC#4/D-05/SEC-01 canary suite"
  key_links:
    - "Uses the real scoped-Buffer + Telemetry.attach/1 + flush_now + real-Postgres scaffold from prompt_span_test.exs — never hand-synthesizes production evidence (EXCEPT the deliberate SC#2 raw-bus bypass canary)."
    - "SC#4 asserting the orphan ROW EXISTS is what FORCES the FK drop (Plan 01) — a span-count-only test would pass under a kept FK while silently losing the event."
---

<objective>
Prove all four success criteria (plus the D-05 fail-closed and SEC-01 Bounds:event corollaries) end-to-end against the real telemetry → Buffer → Postgres pipeline, in one new canary file. These are the acceptance bar for the phase: identical redaction (SC#1), a closed vocabulary that cannot grow even via the raw bus (SC#2), and orphan isolation that keeps a batch of good spans whole (SC#4).

Purpose: this is the goal-backward proof plan — every truth the phase claims is a red-then-green test here, driven through the real production path (never hand-synthesized, except the deliberate SC#2 raw-bus bypass which IS the attack surface under test).
Output: `test/scoria/observe/event_emit_test.exs`.
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
@.planning/phases/53B-ai-span-events-emit-event-1/53B-VALIDATION.md

@test/scoria/observe/prompt_span_test.exs
@lib/scoria/observe.ex
@lib/scoria/observe/telemetry.ex
@lib/scoria/observe/redactor.ex
@lib/scoria/repo/span_event.ex
</context>

<artifacts>
NEW symbols this plan produces:
- `test/scoria/observe/event_emit_test.exs` — the phase's SC canary suite (SC#1, SC#2 both paths, SC#4 orphan, D-05 fail-closed, SEC-01 Bounds:event e2e)
</artifacts>

<tasks>

<task type="auto">
  <name>Task 1: SC#1 identical-redact integration proof</name>
  <files>test/scoria/observe/event_emit_test.exs</files>
  <read_first>
    - test/scoria/observe/prompt_span_test.exs:29-52 (setup: Sandbox.checkout + {:shared, self()}, uniquely-named start_supervised! Buffer, :telemetry.detach("scoria-observe-telemetry") + Scoria.Observe.Telemetry.attach(buffer_name), on_exit detach), :68-80 (emit_and_flush pattern)
    - lib/scoria/observe/redactor.ex (deny-list behavior — recurses into nested :attributes)
  </read_first>
  <action>
    Create the new file with the scoped-Buffer + real `Telemetry.attach/1` + `flush_now` setup copied from prompt_span_test.exs:29-52 (real Postgres, no Process.sleep). SC#1 (EVENT-02): call the REAL `Scoria.Observe.emit_event(%{name: :prompt_rendered, span_id: <uuid>, time: DateTime.utc_now(), attributes: %{<a deny-listed key> => "secret", "scoria.prompt.template_ref" => "eval-spec-v1"}})`, `flush_now`, read the persisted ai_span_events row back from Repo, and assert the deny-listed key's value comes back `"[REDACTED]"` (or the Redactor's canonical redaction marker) while the allow-listed template_ref survives — proving the event's attributes passed through the identical `Redactor.redact/1` call site spans use. Pick the deny-listed key from the Redactor's actual deny-list (read redactor.ex to choose a real one). Do NOT hand-synthesize `:telemetry.execute` here — call the real public emitter.
  </action>
  <verify>
    <automated>mix test test/scoria/observe/event_emit_test.exs -x 2>&amp;1 | tail -12</automated>
  </verify>
  <acceptance_criteria>
    - The persisted event row's deny-listed attribute value is redacted; template_ref survives intact.
    - The test uses the real emit_event/1 + Telemetry.attach + flush_now scaffold (no hand-synthesized telemetry, no Process.sleep).
  </acceptance_criteria>
  <done>SC#1 proven: event attributes are redacted through the identical call site, end-to-end against real Postgres.</done>
</task>

<task type="auto">
  <name>Task 2: SC#2 closed-vocabulary (both paths) + SEC-01 Bounds:event e2e</name>
  <files>test/scoria/observe/event_emit_test.exs</files>
  <read_first>
    - test/scoria/observe/event_emit_test.exs (the setup from Task 1)
    - test/scoria/observe/bounds_test.exs:265-269 (the :event arm unit coverage — this task is the END-TO-END wiring proof, a different test)
    - lib/scoria/observe/telemetry.ex (the reject_event path + [:scoria, :observe, :event, :rejected] telemetry from Plan 03)
  </read_first>
  <action>
    SC#2 (EVENT-02) — direct path: assert `Scoria.Observe.emit_event(%{name: :not_a_real_event, span_id: <uuid>, ...})` returns `{:error, :unknown_event}`, then `flush_now` and assert ZERO ai_span_events rows for it. SC#2 — raw-bus path (the ONE deliberate hand-synthesized call, because the raw bus IS the attack surface): attach a test handler to `[:scoria, :observe, :event, :rejected]`, then call `:telemetry.execute([:scoria, :observe, :event, :emit], %{}, %{name: :not_a_real_event, span_id: <uuid>, time: DateTime.utc_now(), attributes: %{}})` directly, `flush_now`, and assert (a) NO ai_span_events row was persisted and (b) the `:rejected` telemetry fired (handler is the boundary of record, D-03b). SEC-01 (D-06 activation): emit a REAL `emit_event/1` `prompt_rendered` whose attributes include an oversized value or a denied (unregistered) key, `flush_now`, and assert the persisted row is bounded exactly as a span attribute is (the oversized value truncated / the denied key dropped per Bounds), proving `Bounds.enforce(_, :event)` is wired end-to-end (bounds_test.exs:265-269 already covers the unit arm — this is the pipeline proof).
  </action>
  <verify>
    <automated>mix test test/scoria/observe/event_emit_test.exs -x 2>&amp;1 | tail -12</automated>
  </verify>
  <acceptance_criteria>
    - Direct path: `{:error, :unknown_event}` and zero persisted rows for the unknown name.
    - Raw-bus path: no persisted row AND `[:scoria, :observe, :event, :rejected]` fires.
    - SEC-01: an oversized/denied event attribute is bounded in the persisted row exactly as a span attribute would be.
  </acceptance_criteria>
  <done>SC#2 is proven on both the direct and raw-bus paths; the vocabulary cannot silently grow; Bounds:event is proven wired end-to-end.</done>
</task>

<task type="auto">
  <name>Task 3: SC#4 orphan isolation + D-05 fail-closed handler seam</name>
  <files>test/scoria/observe/event_emit_test.exs</files>
  <read_first>
    - test/scoria/observe/event_emit_test.exs (the setup from Task 1)
    - lib/scoria/observe.ex (span/4 / with_* emitters used to produce the 50 real spans; emit_event/1 for the orphan)
    - lib/scoria/repo/span_event.ex, lib/scoria/repo/span.ex (readback shapes)
  </read_first>
  <action>
    SC#4 (D-01/D-05 — the assertion that FORCES the FK drop): drive 50 real span emissions (via the real span emitter path so ai_spans rows are produced) and 1 real `Scoria.Observe.emit_event/1` orphan event whose `span_id` references a span that was NEVER emitted/flushed; `flush_now`; assert (1) 50 spans persisted, (2) THE ORPHAN ROW EXISTS with its dangling `span_id`, and (3) no ai_spans row exists for that `span_id`. Asserting (2) is load-bearing — a span-count-only test would pass under a kept FK while silently losing the event (D-05b). Second test — D-05 fail-closed batch atomicity: send (via the deliberate raw bus) one event with a nil `span_id` and one with a missing `time`, alongside 50 valid events; `flush_now`; assert the two malformed events were DROPPED at the handler (never reached insert_all — the handler defaults time / drops nil span_id, D-05a) while all 50 good events landed — proving the only two NOT NULL raise classes reachable via the raw bus cannot roll back a batch of sibling events.
  </action>
  <verify>
    <automated>mix test test/scoria/observe/event_emit_test.exs 2>&amp;1 | tail -15</automated>
  </verify>
  <acceptance_criteria>
    - SC#4: 50 spans persist; the orphan event row EXISTS with its dangling span_id; no span exists for that id.
    - D-05: a nil-span_id event and a missing-time event are dropped at the handler while 50 good sibling events persist in the same batch.
    - The full file (`mix test test/scoria/observe/event_emit_test.exs`) is green.
  </acceptance_criteria>
  <done>SC#4 is proven (orphan row survives, FK drop forced by the row-exists assertion) and the fail-closed handler seam is proven to protect batch atomicity.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| raw `:telemetry.execute` → handler | The SC#2/D-05 canaries deliberately exercise this bypass — the only place hand-synthesized telemetry is legitimate. |
| batch of events → Postgres | One malformed event must not roll back its 50 valid siblings, and an orphan must persist without taking down spans. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-53B-01 | Information Disclosure | redaction | high | mitigate | SC#1 proves the deny-listed key is [REDACTED] in the persisted row via the identical call site. |
| T-53B-02 | Tampering (vocabulary) | raw-bus bypass | high | mitigate | SC#2 proves both the direct and raw-bus unknown-name paths are rejected and never persisted. |
| T-53B-03 | DoS (data integrity) | orphan / malformed batch | high | mitigate | SC#4 proves the orphan persists without touching 50 good spans; D-05 test proves nil-span_id/missing-time events are dropped at the handler without rolling back 50 good siblings. |
| T-53B-SC | Tampering | package installs | low | accept | No new packages; mix.exs untouched. |
</threat_model>

<verification>
- `mix test test/scoria/observe/event_emit_test.exs` green (SC#1, SC#2 both paths, SC#4, D-05, SEC-01).
- Per VALIDATION.md phase gate: `mix test --warnings-as-errors` green before `/gsd-verify-work`.
</verification>

<success_criteria>
All four ROADMAP success criteria are proven end-to-end against the real pipeline (SC#1 identical redact, SC#2 closed vocabulary on both paths, SC#3 real call sites [Plan 04], SC#4 orphan isolation), plus the D-05 fail-closed seam and SEC-01 Bounds:event wiring. The phase acceptance bar is met.
</success_criteria>

<output>
Create `.planning/phases/53B-ai-span-events-emit-event-1/53B-05-SUMMARY.md` when done.
</output>
