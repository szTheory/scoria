---
phase: 53B-ai-span-events-emit-event-1
plan: 04
type: execute
wave: 3
depends_on: [53B-03]
files_modified:
  - lib/scoria/observe/guardrail.ex
  - lib/scoria/eval/judge_runner.ex
  - test/scoria/observe/guardrail_test.exs
  - test/scoria/eval/judge_runner_test.exs
autonomous: true
requirements: [EVENT-03]
must_haves:
  truths:
    - "guardrail_triggered is emitted INSIDE Guardrail.do_emit, AFTER emit_span(span), only when decision not in [nil, \"allow\"] — all five real call sites (runtime.ex:131,154; workflows/runtime.ex:417,434,452) get it for free with zero caller edits (D-04a)."
    - "prompt_rendered is emitted INLINE at the judge's build_judge_prompt_span, after with_prompt/3 returns successfully — a raised render produces an ERROR span and NO event (emit-after-success) (D-04b)."
    - "guardrail event attributes reuse Semconv.guardrail_attributes/1 (decision/reason_code/name enums only, subject_ref/policy_key OMITTED); prompt event attributes carry ONLY scoria.prompt.template_ref (no scoria.prompt.tokens) (D-04c)."
    - "The judge's free-text explanation can never reach prompt_rendered — the event fires at render time (pre-inference) and the fixed-key projection never reads it (D-04c)."
  artifacts:
    - "guardrail_triggered emission call inside Guardrail.do_emit"
    - "build_judge_prompt_span pre-mints span_id (threaded via opts[:span_id]) and emits prompt_rendered after success"
  key_links:
    - "Both call sites go through Scoria.Observe.emit_event/1 (Plan 03) — no new public wrapper (with_prompt_render/3 was KILLED, D-04b)."
    - "prompt_rendered's template_ref value mirrors the existing rubric_version literal \"eval-spec-v#{eval_spec.version}\" at judge_runner.ex:170/:229."
---

<objective>
Wire the two real production call sites (EVENT-03): `guardrail_triggered` inside `Guardrail.do_emit` (after the span emits, gated to an actual intervention) and `prompt_rendered` inline at the judge's `build_judge_prompt_span` (after a successful render). Both go through `emit_event/1` — no new public surface. `user_feedback_received` stays reserved-only (its zero-emitter guard was locked in Plan 01).

Purpose: SC#3 — these two events must fire during NORMAL operation, not just be reachable via a direct API call in a test. All five guardrail call sites inherit the event for free; the judge emits one event per dataset item at render time, structurally and temporally blocked from ever carrying the free-text `explanation`.
Output: the two in-place emission additions + real-call-site integration proofs (guardrail_test.exs, judge_runner_test.exs).
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

@lib/scoria/observe/guardrail.ex
@lib/scoria/eval/judge_runner.ex
@lib/scoria/observe/semconv.ex
@test/scoria/observe/guardrail_test.exs
@test/scoria/eval/judge_runner_test.exs
@test/scoria/observe/prompt_span_test.exs
</context>

<artifacts>
NEW behavior this plan produces:
- A `Scoria.Observe.emit_event(%{name: :guardrail_triggered, ...})` call inside `Guardrail.do_emit`, after `emit_span(span)`, gated `decision not in [nil, "allow"]`
- `build_judge_prompt_span` pre-mints a `span_id`, threads it via `opts[:span_id]`, and emits `%{name: :prompt_rendered, ...}` after a successful `with_prompt/3` return
- No new public wrapper, no new Semconv projector, no new registry key beyond Plan 01's template_ref
</artifacts>

<tasks>

<task type="auto">
  <name>Task 1: Emit guardrail_triggered inside Guardrail.do_emit</name>
  <files>lib/scoria/observe/guardrail.ex</files>
  <read_first>
    - lib/scoria/observe/guardrail.ex:131 (do_emit/1), :132 (gate_name), :135-138 (guardrail_fields incl. decision + normalized reason_code), :154 (end_time), :163 (span id), :171 (emit_span(span)), :125-129 (emit/1's outer try/rescue → :ok)
    - lib/scoria/observe/semconv.ex:430 (guardrail_attributes/1 — reuse verbatim)
  </read_first>
  <action>
    Immediately after `emit_span(span)` (guardrail.ex:171), inside `do_emit` (still under `emit/1`'s outer try/rescue → :ok at :125-129), add: capture the emitted span's id (the value at :163 — `Map.get(input, :span_id) || span.id`) and, `if decision not in [nil, "allow"]` (D-04a — the span already records `allow` durably, so the event is reserved for the actual intervention), call `Scoria.Observe.emit_event(%{name: :guardrail_triggered, span_id: <span id>, time: end_time, attributes: Semconv.guardrail_attributes(%{name: gate_name, decision: decision, reason_code: <normalized reason_code from guardrail_fields>})})`. Reuse the EXISTING `Semconv.guardrail_attributes/1` (semconv.ex:430) verbatim — do NOT mint `guardrail_event_attributes/1` (D-04c, cut). OMIT `subject_ref`/`policy_key` (correlate via span_id; don't duplicate the span, D-04c). Do NOT modify any of the five callers (runtime.ex:131,154; workflows/runtime.ex:417,434,452) — they inherit the event for free (D-04a). ≤1 event per blocked/escalated step.
  </action>
  <verify>
    <automated>mix test test/scoria/observe/guardrail_test.exs 2>&amp;1 | tail -12</automated>
  </verify>
  <acceptance_criteria>
    - A `Guardrail.emit/1` with `decision: "block"` (or `"escalate"`) results, after flush, in a persisted ai_span_events row `name = "guardrail_triggered"` whose attributes contain the guardrail decision/reason_code/name enums and NOT subject_ref/policy_key.
    - A `Guardrail.emit/1` with `decision: "allow"` produces NO guardrail_triggered event.
    - No caller file (runtime.ex, workflows/runtime.ex) is modified.
  </acceptance_criteria>
  <done>guardrail_triggered fires from the real do_emit hook on actual interventions only; all five call sites covered with zero caller edits.</done>
</task>

<task type="auto">
  <name>Task 2: Emit prompt_rendered inline at the judge's build_judge_prompt_span</name>
  <files>lib/scoria/eval/judge_runner.ex</files>
  <read_first>
    - lib/scoria/eval/judge_runner.ex:197-206 (build_judge_prompt_span/3 — CURRENTLY arity /3, does NOT pass :span_id), :155 (the single caller inside score_dataset_item/6, where eval_spec is in scope), :170 and :229 (existing "eval-spec-v#{eval_spec.version}" rubric_version literal to mirror), :208-214 (build_judge_prompt), :168/:227 (the free-text explanation literals that fire strictly AFTER this event)
    - lib/scoria/observe.ex:154 (with_prompt/3), :372 (id: opts[:span_id] || generate own-id seam)
    - lib/scoria/observe/semconv.ex (prompt_template_ref_key/0 from Plan 01)
  </read_first>
  <action>
    Thread `eval_spec` into the prompt-render helper so the template_ref value is available, then emit `prompt_rendered` after a successful render (D-04b). NOTE the current signature is `build_judge_prompt_span/3` (NOT /4 as an illustrative research example showed) — change it to `/4` accepting `eval_spec` and update the single caller at :155 (`build_judge_prompt_span(dataset_item, actual_output, attrs, eval_spec)`; eval_spec is already in that scope). In the helper: pre-mint `span_id = fetch(attrs, :span_id) || Ecto.UUID.generate()`, add `span_id: span_id` to the `with_prompt/3` opts map (:200-203) so it threads via the existing `opts[:span_id]` own-id seam (observe.ex:372); after `with_prompt/3` RETURNS (emit-after-success — `span/4` reraises on error so a raised render never reaches this line, correctly producing an ERROR span and NO event), call `Scoria.Observe.emit_event(%{name: :prompt_rendered, span_id: span_id, time: DateTime.utc_now(), attributes: %{Semconv.prompt_template_ref_key() => "eval-spec-v#{eval_spec.version}"}})` — the template_ref value mirrors the existing rubric_version literal at :170/:229. Attributes carry ONLY template_ref (NO scoria.prompt.tokens, D-04c). Do NOT read or pass the judge's `explanation`/verdict output into the event (it does not exist yet at render time and the fixed-key projection would drop it regardless, D-04c). Do NOT add a new public wrapper (with_prompt_render/3 was KILLED, D-04b). Return the wrapper's `result` unchanged.
  </action>
  <verify>
    <automated>mix test test/scoria/eval/judge_runner_test.exs 2>&amp;1 | tail -12</automated>
  </verify>
  <acceptance_criteria>
    - `build_judge_prompt_span` is now `/4`; its single caller passes `eval_spec`; the function still returns the prompt string unchanged.
    - A real judge render produces, after flush, a persisted ai_span_events row `name = "prompt_rendered"` whose only attribute is `scoria.prompt.template_ref = "eval-spec-v<version>"`.
    - No `explanation`/verdict text appears in the event attributes under any path.
    - `with_prompt/3` / `span/4` behavior is otherwise unchanged (transparent, Phase 53 D-01a).
  </acceptance_criteria>
  <done>prompt_rendered fires inline at the one real lib/ producer (the judge), one event per dataset item, structurally + temporally incapable of leaking the explanation.</done>
</task>

<task type="auto">
  <name>Task 3: Real-call-site emission proofs (SC#3)</name>
  <files>test/scoria/observe/guardrail_test.exs, test/scoria/eval/judge_runner_test.exs</files>
  <read_first>
    - test/scoria/observe/prompt_span_test.exs:29-52 (scoped-Buffer + Telemetry.attach/1 + flush_now real-Postgres scaffold), :68-80 (emit_and_flush pattern)
    - test/scoria/observe/guardrail_test.exs (existing setup)
    - test/scoria/eval/judge_runner_test.exs (existing setup)
  </read_first>
  <action>
    Add real-call-site (NOT hand-synthesized, D-ATTR01-6) integration proofs using the scoped-Buffer + real `Telemetry.attach/1` + `flush_now` scaffold from prompt_span_test.exs. Guardrail proof: drive a REAL `Guardrail.emit/1` with `decision: "block"` (and one with `"escalate"`), `flush_now`, assert a persisted `guardrail_triggered` ai_span_events row exists with the expected decision/reason_code/name attributes; drive a REAL `Guardrail.emit/1` with `decision: "allow"` and assert NO guardrail_triggered row. Judge proof: drive the real judge render path so `build_judge_prompt_span/4` runs (via its actual caller or the smallest real entry that reaches it), `flush_now`, assert a persisted `prompt_rendered` row exists with `scoria.prompt.template_ref` set and assert the row's attributes do NOT contain any explanation/verdict text (no-leak assertion). Do NOT hand-synthesize a `:telemetry.execute` for these proofs — they must exercise the real producers.
  </action>
  <verify>
    <automated>mix test test/scoria/observe/guardrail_test.exs test/scoria/eval/judge_runner_test.exs 2>&amp;1 | tail -15</automated>
  </verify>
  <acceptance_criteria>
    - Guardrail: real emit with block/escalate persists guardrail_triggered; real emit with allow persists none.
    - Judge: real render persists prompt_rendered with template_ref and no explanation text.
    - Both proofs drive real producers (no hand-synthesized telemetry).
  </acceptance_criteria>
  <done>SC#3 is proven from real call sites for both emitted events, with the no-leak assertion for the judge path.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| judge inference output → durable event | The judge's free-text `explanation` is the single most likely free-text leak; the event must never carry it. |
| guardrail decision → durable event | Only low-cardinality enums (decision/reason_code/name) may cross into a persisted guardrail event. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-53B-04 | Information Disclosure | judge explanation → prompt_rendered | high | mitigate | Temporal: prompt_rendered fires at render time, before the judge produces `explanation` (which lives at judge_runner.ex:168/:227). Structural: fixed-key attribute payload carries ONLY `scoria.prompt.template_ref`. No-leak assertion in Task 3. Residual: low. |
| T-53B-01 | Information Disclosure | guardrail attributes | high | mitigate | Reuse `Semconv.guardrail_attributes/1` (enums only; subject_ref/policy_key omitted); attributes still pass through the shared redact + Bounds(:event) at the handler (Plan 03). |
| T-53B-SC | Tampering | package installs | low | accept | No new packages; mix.exs untouched. |
</threat_model>

<verification>
- `mix test test/scoria/observe/guardrail_test.exs test/scoria/eval/judge_runner_test.exs` green.
- `mix compile --warnings-as-errors` clean.
</verification>

<success_criteria>
`guardrail_triggered` and `prompt_rendered` fire from real production call sites (SC#3), each with the correct closed attribute set, the guardrail event gated to real interventions, and the judge event structurally + temporally incapable of leaking the explanation. `user_feedback_received` remains reserved-only (guard from Plan 01).
</success_criteria>

<output>
Create `.planning/phases/53B-ai-span-events-emit-event-1/53B-04-SUMMARY.md` when done.
</output>
