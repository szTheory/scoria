---
phase: 53-structured-child-spans-write-time-bound
plan: 08
subsystem: observability
tags: [elixir, telemetry, workflows, guardrail, otel-genai, openinference, span-tree]

# Dependency graph
requires:
  - phase: 53-structured-child-spans-write-time-bound
    plan: "03"
    provides: "Scoria.Observe.span/4 + with_tool/3/with_prompt/3/with_guardrail/3 + trace_id_for_run/1 -- the span primitive every producer in this plan funnels through"
  - phase: 53-structured-child-spans-write-time-bound
    plan: "04"
    provides: "Scoria.Observe.Bounds.enforce/2 -- the write-time choke point; every attribute key emitted here is registered in Semconv so it survives Bounds"
  - phase: 53-structured-child-spans-write-time-bound
    plan: "07"
    provides: "Scoria.Observe.Guardrail.emit/1 -- the pure guardrail emitter this plan reuses for G2/G3/G4"
provides:
  - "Step-level parent span: Scoria.Workflows.Runtime.execute_step/2 wraps its outcome dispatch in Scoria.Observe.span/4 (trace_id = run.id, parent_id nil, span_id minted at the call site so children can reference it)"
  - "trace_id + step span id threaded into the step handler via run.metadata[\"runtime\"] so handler-emitted LLM/tool spans link as children (SC#1 parent_id linkage)"
  - "G2 (approval/escalate), G3 (budget/block), G4 (breaker/block) guardrail spans emitted through Scoria.Observe.Guardrail.emit/1, parented to the step span"
  - "JudgeRunner prompt-render site wrapped in a PROMPT span carrying ids/duration/kind only -- never the judge's free-form explanation (SEC-01)"
  - "ReqLLM + Jido adapters mint span :id at emit time (not flush-time) so a future child span can name them as parent_id"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Step span id minted at the call site (execute_step/2), not deferred to Buffer flush-time put_new_lazy/2 -- a flush-time id is unreferenceable, so no child span could name it as parent_id"
    - "StepFailureSignal carries the already-computed fail_step/2 return value out through span/4's rescue, so a failed step yields an ERROR step span (SC#3) with execute_step/2's return byte-for-byte unchanged"
    - "trace_id/parent_id threaded through the existing run.metadata[\"runtime\"] extension point that run_runtime_defaults/1 already reads -- no new handler parameter"
    - "Adapter :id set at emit time; the || Ecto.UUID.generate() fallback is documented as a last-resort producing an ORPHAN single-span trace, not the intended path"

key-files:
  created:
    - test/scoria/workflows/runtime_span_test.exs
  modified:
    - lib/scoria/workflows/runtime.ex
    - lib/scoria/eval/judge_runner.ex
    - lib/scoria/observe/adapters/req_llm.ex
    - lib/scoria/observe/adapters/jido.ex

key-decisions:
  - "execute_step/2 opens the step span BEFORE reserve_budget/3 runs (design fork PINNED): a budget-rejected step therefore still has an open step span for its G3 guardrail span to parent to, rather than emitting an orphan."
  - "The step span threads trace_id = run.id directly (a run IS a trace, D-03a) and mints parent_id nil -- the step is the root of the run's trace tree; handler-emitted LLM/tool/guardrail spans are its children."
  - "G4 (breaker) reads the breaker envelope's own reason_code (D-05j) rather than synthesizing one, keeping the guardrail decision traceable to the source signal."
  - "The JudgeRunner PROMPT span sits on a live path (an Oban :evals job reaches it via CampaignWorker.perform/1 -> online_scoring.ex) and carries duration/kind/ids ONLY -- nothing from the judge's free-form explanation reaches the span (SEC-01)."

requirements-completed: []

coverage:
  - id: D1
    description: "Executing a step persists ONE step span rooted at the run's trace with a real duration"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/workflows/runtime_span_test.exs#executing a step persists ONE step span rooted at the run's trace with a real duration"
        status: pass
    human_judgment: false
  - id: D2
    description: "A raising handler produces an ERROR step span (SC#3) with a real duration, and execute_step/2's return is unchanged"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/workflows/runtime_span_test.exs#a raising handler produces an ERROR step span with a real duration, and execute_step/2's return is unchanged"
        status: pass
    human_judgment: false
  - id: D3
    description: "A handler-emitted LLM span shares the step span's trace_id and is parented to it (SC#1 parent_id linkage)"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/workflows/runtime_span_test.exs#a handler-emitted LLM span shares the step span's trace_id and is parented to it"
        status: pass
    human_judgment: false
  - id: D4
    description: "G2/G3/G4 each emit a guardrail span parented to the step span; execute_step/2's return is unchanged in every case"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/workflows/runtime_span_test.exs#waiting_for_approval emits a guardrail span parented to the step span; execute_step/2's return is unchanged"
        status: pass
      - kind: integration
        ref: "test/scoria/workflows/runtime_span_test.exs#a budget-rejected step emits a guardrail span parented to the step span (design fork PINNED); execute_step/2's return is unchanged"
        status: pass
      - kind: integration
        ref: "test/scoria/workflows/runtime_span_test.exs#a breaker-open step emits a guardrail span parented to the step span; execute_step/2's return is unchanged"
        status: pass
    human_judgment: false
  - id: D5
    description: "run_live/1 produces a duration-bearing PROMPT span whose attributes never carry the judge's free-form explanation (SEC-01)"
    requirement: "SEC-01"
    verification:
      - kind: integration
        ref: "test/scoria/workflows/runtime_span_test.exs#run_live/1 produces a duration-bearing PROMPT span whose attributes never carry the judge's free-form explanation"
        status: pass
    human_judgment: false
  - id: D6
    description: "A step triggering an MCP tool call, an LLM call, and a guardrail check produces a tree with the step at depth 0 and its children at depth 1 (through TraceProjection)"
    requirement: "EVENT-01"
    verification:
      - kind: integration
        ref: "test/scoria/workflows/runtime_span_test.exs#a step triggering an MCP tool call, an LLM call, and a guardrail check produces a tree with the step at depth 0 and its children at depth 1"
        status: pass
    human_judgment: false

# Metrics
duration: multi-session (3 transport-error interruptions; task commits landed, SUMMARY closed out by orchestrator)
completed: 2026-07-14
status: complete
---

# Phase 53 Plan 08: Workflow Step Spans + G2/G3/G4 Guardrails Summary

**`Scoria.Workflows.Runtime.execute_step/2` now opens a step-level parent span (trace_id = run.id, span_id minted at the call site) and threads `trace_id`/`parent_id` into the step handler so handler-emitted LLM/tool spans link as children; G2/G3/G4 guardrail decisions and the JudgeRunner prompt-render site emit through the existing span/4 + Guardrail.emit/1 primitives, completing SC#1's trace tree with ids-and-duration-only payloads (SEC-01).**

This plan moved the remaining producers onto the Phase 53 span primitive:

- **Step parent span** — `execute_step/2` wraps its outcome dispatch in `Scoria.Observe.span/4`. `trace_id` is `run.id` (a run *is* a trace, D-03a), `parent_id` is nil (the step roots the run's tree), and the span id is minted at the call site so children can name it as `parent_id` (D-03c). A `StepFailureSignal` carries `fail_step/2`'s already-computed return value out through `span/4`'s rescue, so a raised step yields an **ERROR** step span (SC#3) while `execute_step/2`'s return stays byte-for-byte unchanged.
- **Child linkage** — `trace_id` and the step span id are threaded into the handler via `run.metadata["runtime"]`, the same extension point `run_runtime_defaults/1` already reads (D-03b). Handler-emitted LLM/tool spans pick these up and parent to the step.
- **G2/G3/G4** — approval-gate/escalate, budget-gate/block, and breaker-gate/block each emit through `Scoria.Observe.Guardrail.emit/1`, parented to the step span. The step span is opened **before** `reserve_budget/3` runs (design fork PINNED) so a budget-rejected step still has a parent for its G3 span. G4 reads the breaker envelope's own `reason_code` (D-05j).
- **JudgeRunner PROMPT span** — the prompt-render site (live via an Oban `:evals` job) is wrapped in a PROMPT span carrying duration/kind/ids only — never the judge's free-form explanation (SEC-01).
- **Adapters** — the ReqLLM and Jido adapters now set span `:id` at emit time instead of leaving it to `Buffer`'s flush-time `put_new_lazy/2`; a flush-time id is unreferenceable. The `|| Ecto.UUID.generate()` fallback is documented as a last resort producing an orphan single-span trace.

## Verification

`mix test test/scoria/workflows/runtime_span_test.exs --warnings-as-errors` → **8 tests, 0 failures** on the merged tree. The full post-merge suite is **1284 tests, 1 failure** — the sole failure is the pre-existing, unrelated `capture_parity_test.exs` full-suite-only flake (logged in `deferred-items.md`, passes 2/2 in isolation), not a regression from this plan.

## Execution note (process, not product)

This plan's executor agent was interrupted three times by a transient API transport error ("Connection closed mid-response"), each time while running the full test suite. After reordering to commit-before-verify, all four atomic task commits (`a6f8abeb`, `13c23278`, `2d6faa4b`, `ce190f12`) landed durably; only the SUMMARY.md write remained when the third interruption hit. This SUMMARY was written by the orchestrator via the "close out manually" recovery path, from the committed diff and commit bodies, with test results independently re-verified on the merged tree.
