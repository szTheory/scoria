---
phase: 53B-ai-span-events-emit-event-1
plan: 04
subsystem: observability
tags: [telemetry, ai-span-events, guardrail, judge, opentelemetry, otel-genai]

# Dependency graph
requires:
  - phase: 53B-03
    provides: Scoria.Observe.emit_event/1, the closed-vocabulary point-event bus, Telemetry.handle_event/4 event persistence into ai_span_events
provides:
  - guardrail_triggered emitted inline inside Guardrail.do_emit, gated to real interventions (decision not in [nil, "allow"])
  - prompt_rendered emitted inline at the judge's build_judge_prompt_span (now /4), after a successful render
  - Real-call-site integration proofs for both events (no hand-synthesized telemetry)
affects: [54-docs-accuracy-conformance, observability-operator-ui]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Point events are emitted inline at the producer, immediately after the span emits, reusing the span's own span_id for correlation -- no new public wrapper."
    - "Emit-after-success: an event that must never see a pre-computed model output is threaded through span/4's own-id seam (opts[:span_id]) and only emitted after the wrapped fn returns (a raise reraises through span/4 before reaching the event emit line)."

key-files:
  created: []
  modified:
    - lib/scoria/observe/guardrail.ex
    - lib/scoria/eval/judge_runner.ex
    - test/scoria/observe/guardrail_test.exs
    - test/scoria/eval/judge_runner_test.exs

key-decisions:
  - "guardrail_triggered fires inside Guardrail.do_emit itself (not at any of the four callers) -- all five real call sites (runtime.ex:131,154; workflows/runtime.ex:417,434,452) inherit the event for free with zero caller edits (D-04a)."
  - "guardrail_triggered attributes reuse Semconv.guardrail_attributes/1 verbatim, passed only name/decision/reason_code -- subject_ref/policy_key are structurally omitted (D-04c), not merely convention."
  - "prompt_rendered fires inline at build_judge_prompt_span (now arity /4, threading eval_spec) after with_prompt/3 returns -- a raised render reraises through span/4 and never reaches the emit line, producing an ERROR span and NO event (D-04b)."
  - "prompt_rendered attributes carry ONLY scoria.prompt.template_ref (mirroring the existing 'eval-spec-v#{eval_spec.version}' rubric_version literal) -- no scoria.prompt.tokens, and the judge's free-text explanation cannot reach it because it doesn't exist yet at render time (D-04c)."

requirements-completed: [EVENT-03]

coverage:
  - id: D1
    description: "guardrail_triggered fires from real Guardrail.emit/1 calls with an actual intervention (block/escalate), carrying only the guardrail enum attributes, and does NOT fire on allow."
    requirement: "EVENT-03"
    verification:
      - kind: integration
        ref: "test/scoria/observe/guardrail_test.exs#Task 3 (SC#3): guardrail_triggered fires from the real Guardrail.emit/1 producer"
        status: pass
    human_judgment: false
  - id: D2
    description: "prompt_rendered fires from the real judge render path (JudgeRunner.run_live/1 -> build_judge_prompt_span/4) with only scoria.prompt.template_ref, and never leaks the judge's free-text explanation/verdict."
    requirement: "EVENT-03"
    verification:
      - kind: integration
        ref: "test/scoria/eval/judge_runner_test.exs#run_live/1's real judge render persists a prompt_rendered event with template_ref and no explanation/verdict leak"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-07-18
status: complete
---

# Phase 53B Plan 04: Wire guardrail_triggered + prompt_rendered into real production call sites Summary

**Both real point-events (EVENT-03) now fire from live production code paths: `guardrail_triggered` inline inside `Guardrail.do_emit` gated to actual interventions, and `prompt_rendered` inline at the judge's prompt-render helper after a successful render -- both structurally incapable of leaking free text.**

## Performance

- **Duration:** ~7 min
- **Tasks:** 3/3 completed
- **Files modified:** 4 (2 lib, 2 test)

## Accomplishments
- `Scoria.Observe.Guardrail.do_emit/1` now emits `guardrail_triggered` immediately after `emit_span(span)`, gated to `decision not in [nil, "allow"]` -- all five real guardrail call sites (`runtime.ex:131,154`; `workflows/runtime.ex:417,434,452`) inherit the event with zero caller edits.
- `Scoria.Eval.JudgeRunner.build_judge_prompt_span/3` is now `/4` (threading `eval_spec`), pre-mints a `span_id`, threads it through `with_prompt/3`'s `opts[:span_id]` own-id seam, and emits `prompt_rendered` only after the render succeeds -- a raised render reraises through `span/4` before reaching the emit line, so it produces an ERROR span and NO event.
- Added real-call-site integration proofs (no hand-synthesized `:telemetry.execute`) for both events: guardrail block/escalate persist `guardrail_triggered`, allow persists none; a real judge render persists `prompt_rendered` with `scoria.prompt.template_ref` set and no explanation/verdict text anywhere in the attributes.

## Task Commits

Each task was committed atomically:

1. **Task 1: Emit guardrail_triggered inside Guardrail.do_emit** - `f1cb77d9` (feat)
2. **Task 2: Emit prompt_rendered inline at the judge's build_judge_prompt_span** - `41b5cafe` (feat)
3. **Task 3: Real-call-site emission proofs (SC#3)** - `6b68541b` (test)

_Plan metadata commit deferred: this is a worktree-isolated executor run; the orchestrator applies the final metadata/STATE.md/ROADMAP.md commit after merging the wave._

## Files Created/Modified
- `lib/scoria/observe/guardrail.ex` - Added `alias Scoria.Observe`, captured `span_id` before building the span map, and added `maybe_emit_guardrail_triggered/3` (gated on decision) called right after `emit_span(span)` inside `do_emit/1`.
- `lib/scoria/eval/judge_runner.ex` - Added `alias Scoria.Observe.Semconv`; `build_judge_prompt_span/3` -> `/4` (threads `eval_spec`); pre-mints `span_id`, passes it via `with_prompt/3` opts, and emits `prompt_rendered` after the wrapped render returns; single caller in `score_dataset_item/6` updated to pass `eval_spec`.
- `test/scoria/observe/guardrail_test.exs` - Added `Task 3 (SC#3)` describe block: real block/escalate emit persists `guardrail_triggered` with the closed attribute set (and no `subject_ref`/`policy_key`); real allow emit persists none.
- `test/scoria/eval/judge_runner_test.exs` - Added a scoped-Buffer + `Telemetry.attach/1` setup block (mirroring `prompt_span_test.exs`/`guardrail_test.exs`) and a test driving the real `run_live/1` render path, asserting the persisted `prompt_rendered` row's attributes are exactly `{template_ref}` and never contain the judge's stubbed explanation text.

## Decisions Made
- `guardrail_triggered` lives entirely inside `Guardrail.do_emit` (not at any caller) so all five production call sites get it for free (D-04a) -- confirmed no caller file (`runtime.ex`, `workflows/runtime.ex`) needed modification.
- Reused `Semconv.guardrail_attributes/1` verbatim for the event payload (passing only `name`/`decision`/`reason_code`), rather than minting a new projector -- `subject_ref`/`policy_key` are structurally absent since they're simply not in the input map passed to the projector (D-04c).
- `prompt_rendered`'s emit call sits directly in `build_judge_prompt_span/4`, after `with_prompt/3` returns, guaranteeing emit-after-success semantics without any new public wrapper (`with_prompt_render/3` stays killed per D-04b).
- The `span_id` pre-minted in `build_judge_prompt_span/4` is threaded through `with_prompt/3`'s `opts[:span_id]`, so the emitted event's `span_id` foreign-keys the exact same PROMPT span row -- verified in the Task 3 judge proof via the real telemetry->buffer->Postgres pipeline.

## Deviations from Plan

None - plan executed exactly as written. All four acceptance criteria for Task 1 and Task 2, and all three for Task 3, are met as specified.

## Issues Encountered
- A pre-existing test-harness race (unrelated to this plan's changes) intermittently logs a benign `GenServer ... terminating` error during test teardown when a scoped `Buffer`'s supervised process is stopped after its DB sandbox connection has already been returned. Confirmed via isolated reproduction (reverting this plan's test additions and re-running `guardrail_test.exs` alone) that this race pre-dates Plan 04 and is not introduced by it. It never causes a test failure (`0 failures` in every run) and is out of this plan's file scope (`Buffer.terminate/2`/sandbox teardown ordering, not `guardrail.ex`/`judge_runner.ex`). Logged here for visibility, not fixed (scope boundary).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- EVENT-03 is fully proven from real production call sites; `guardrail_triggered` and `prompt_rendered` both fire correctly with closed attribute sets and structural/temporal immunity to free-text leaks.
- `user_feedback_received` remains reserved-only per its Plan 01 zero-emitter guard -- unaffected by this plan.
- Phase 54 (docs accuracy + conformance check) can now document both events as live, not just reachable via direct API calls.

---
*Phase: 53B-ai-span-events-emit-event-1*
*Completed: 2026-07-18*

## Self-Check: PASSED

All 4 claimed files found on disk; all 3 task commit hashes (f1cb77d9, 41b5cafe, 6b68541b) found in git log.
