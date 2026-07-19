# Phase 53b: `ai_span_events` + `emit_event/1` - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-18
**Phase:** 53b-ai-span-events-emit-event-1
**Areas discussed:** Orphan-event isolation (SC#4), Buffer event list + ordered flush, Allow-list chokepoint + raw-bus + identical redact (SC#1/SC#2), Real call-site emission (EVENT-03)
**Method:** User selected all 4 gray areas and directed the research+red-team method (not interactive Q&A) — four parallel cross-aware research subagents, each applying the full lens set (Elixir/Ecto/Phoenix library idiom, ecosystem lessons right/wrong/footguns, consumer-first API DX, SRE/security/architecture hats, project DNA in `prompts/`), then one adversarial red-team pass. Every claim verified against real code.

---

## Orphan-event isolation (SC#4)

| Option | Description | Selected |
|--------|-------------|----------|
| Drop the FK only | Make `ai_span_events.span_id` FK-free so an orphan inserts rather than raises | |
| Separate transaction only | Flush events in a txn distinct from spans so an event failure can't roll back spans | |
| Both (drop FK + separate txn) | Each defends a different failure class | ✓ |
| Pre-flight filter | Filter events whose span_id isn't resolvable before insert | |

**User's choice:** Both — locked as D-01a. Orphan fate = **persist dangling, durably** (never drop, never retry); `span_id` stays NOT NULL (D-01b). The SC#4 test asserts the orphan **row exists** with its dangling span_id (D-05b).
**Notes:** Research A cited a Phase 52 FK-drop migration as precedent; orchestrator fact-check found **it does not exist** (D-00a). Decision survived; citation corrected to `ai_spans.parent_id` (FK-free by construction) + `converge_eval_persistence.exs:117` (real `DROP CONSTRAINT` pattern).

---

## Buffer event list + ordered flush

| Option | Description | Selected |
|--------|-------------|----------|
| Separate `events: []` list | Own cap + own failure counter; two-phase `do_flush` (spans Multi, then separate events insert) | ✓ |
| Tagged unified list | One list holding spans + events with type tags | |
| Second GenServer | A dedicated event buffer process | |
| One combined Multi | traces + spans + events in a single transaction | |

**User's choice:** Separate list + two-phase flush — D-02. Combined Multi rejected (reintroduces SC#4 violation); second GenServer rejected (breaks single-`flush_now` proof, doubles supervision).
**Notes:** `flush_now/1` stays byte-for-byte so one hook proves both the ordered-flush and orphan tests. `surface_flush_error` reused with a `signal: :span | :event` dimension.

---

## Allow-list chokepoint + raw-bus + identical redact (SC#1/SC#2)

| Option | Description | Selected |
|--------|-------------|----------|
| `emit_event/1` check only | Enforce the allow-list in the public function | |
| Handler check only | Enforce only in the telemetry handler (catches raw-bus bypass) | |
| Defense-in-depth (both) | Up-front check (DX) + handler re-check (boundary of record for the raw bus) | ✓ |

**User's choice:** Defense-in-depth — D-03b. Both call one `Semconv.event_name?/1` (no second source to drift); the SC#2 canary asserts both the direct-call and raw-bus paths reject an unknown name.
**Notes:** `:name` is an atom from a closed `@event_names` vocabulary in `Semconv`. "Identical redact call site" made literal by collapsing span+delta+event redaction into one shared `defp redact/1` (D-03d). Rejection is fail-closed + observable (`[:scoria, :observe, :event, :rejected]` + once-per-name log).

---

## Real call-site emission (EVENT-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Emit inside `Guardrail.emit/1` `do_emit` | span_id + decision already coexist; all 5 sites get it free | ✓ (guardrail) |
| Emit at each of the 5 guardrail call sites | Explicit per-site emission | |
| New `Observe.with_prompt_render/3` wrapper | A dedicated public wrapper exposing the span_id | |
| Inline at `judge_runner.build_judge_prompt_span/3` | Pre-mint span_id, thread via existing `opts[:span_id]`, no new API | ✓ (prompt) |

**User's choice:** `guardrail_triggered` inside `do_emit` when `decision not in [nil, "allow"]` (D-04a); `prompt_rendered` inline at the judge site, no new wrapper (D-04b, red-team KILLed the wrapper). `user_feedback_received` stays reserved with a grep-guard proving zero `lib/` emitter (D-04d).
**Notes:** Event payloads are ids/enums/counts only — reuse `guardrail_attributes/1`; one new registry key `scoria.prompt.template_ref`. Red-team KILLed `scoria.prompt.tokens` (no v3.6 producer) and the speculative `guardrail_event_attributes/1`.

---

## Claude's Discretion

- Plan sequencing within the ~5-plan budget (red-team ordering: migration+vocab → Buffer → `emit_event/1`+handler [hard prereq] → call sites → SC tests).
- Internal factoring of the two-phase `do_flush` and the shared `redact/1`/`reject_event/2` helpers.
- Whether the two allow-list checks share one private guard or each call `Semconv.event_name?/1` directly (either satisfies the anti-divergence lock).

## Deferred Ideas

- Operator UI for events (Phase 53 D-08 follow-on); `user_feedback_received` emission (SEED-011/FB-01); `scoria.prompt.tokens`; `guardrail_event_attributes/1`; `SummarizeWorker` prompt_rendered; per-event savepoints; OTLP export of events (must not use OTel span events, which OTel is deprecating in 2026).

## Red-team resolutions (the four cross-area risks)

1. **Event-batch atomicity** — accept batch atomicity, no per-event savepoints; close the only reachable raise classes (NULL `time`, NULL `span_id`) at the **handler** fail-closed seam (D-05). This was the caught coherence break.
2. **Enforcement redundancy** — CONFIRM both points; anti-divergence guaranteed by a single `Semconv.event_name?/1` source + canary.
3. **`with_prompt_render/3`** — KILLED; emit inline at the one judge site.
4. **`prompt_rendered` payload** — KILL `scoria.prompt.tokens`; KEEP `scoria.prompt.template_ref`.
