---
phase: 52-retriever-span-host-declared-attributes
plan: 03
subsystem: observability
tags: [telemetry, opentelemetry, openinference, elixir, semconv]

# Dependency graph
requires:
  - phase: 52-01
    provides: "Semconv.openinference_span_kind_key/0, retrieval_config_attributes/1, host_declared_keys/0, merge_host_declared/2, prompt_context_key/0, prompt_context/1 — all reused verbatim here"
provides:
  - "Scoria.Observe.emit_retriever_span/1 — the RETR-01 spine, host-facing RETRIEVER span emitter"
  - "Scoria.Observe.emit_prompt_span/1 — the ATTR-02 lane, host-facing PROMPT composition span emitter"
  - "Semconv.merge_usage_input_tokens/2 — sole call site sourcing gen_ai.usage.input_tokens via ReqLLM.OpenTelemetry.Attributes.terminal/1"
affects: [52-04, 52-05, 52-06, phase-53]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Host-facing emitter facade: build attributes map from %{} through Semconv/SpanKind only (no inline key literals), build span map with explicit own :id, wrap :telemetry.execute in try/rescue -> :ok"
    - "Omit-when-absent attribute attach via private maybe_put_*/2 helpers (never attach an empty-but-present key)"

key-files:
  created: []
  modified:
    - lib/scoria/observe.ex
    - lib/scoria/observe/semconv.ex
    - test/scoria/observe/observe_test.exs
    - test/scoria/observe/semconv_test.exs

key-decisions:
  - "emit_prompt_span/1's usage-input-tokens attach is implemented as a new Semconv.merge_usage_input_tokens/2 helper (not inlined in observe.ex) — required by Task 2's own action instructions to keep gen_ai.* key sourcing solely in Semconv (FOUND-03), so this is plan-following, not a deviation from files_modified."

patterns-established:
  - "Both emitters share a private emit_span/1 helper: :telemetry.execute wrapped in try/rescue -> :ok (D-R6), the single failure-isolation point for the whole module."

requirements-completed: [RETR-01, ATTR-01, ATTR-02]

coverage:
  - id: D1
    description: "emit_retriever_span/1 builds and emits a RETRIEVER-kind span (OpenInference kind attribute, retrieval-config attributes, host-declared keys, caller-supplied id/trace_id/parent_id, status_code OK, wall-clock start/end)"
    requirement: "RETR-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/observe_test.exs#describe emit_retriever_span/1 (5 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "emit_prompt_span/1 builds and emits a prompt-composition span carrying host-declared keys, context-pack (id/token-only, never text), and gen_ai.usage.input_tokens, with omit-when-absent semantics for both context-pack and input_tokens"
    requirement: "ATTR-02"
    verification:
      - kind: unit
        ref: "test/scoria/observe/observe_test.exs#describe emit_prompt_span/1 (8 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Both emitters route feature/route/archetype/intent through Semconv.merge_host_declared/2 (host-declared, never inferred)"
    requirement: "ATTR-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/observe_test.exs#attributes carry the three retrieval-config keys and host-declared keys; #host-declared keys ride the span via merge_host_declared/2"
        status: pass
    human_judgment: false
  - id: D4
    description: "Both emitters are failure-isolated: a raising telemetry handler still yields :ok (D-R6)"
    verification:
      - kind: unit
        ref: "test/scoria/observe/observe_test.exs#returns :ok even when the telemetry handler raises (both describe blocks)"
        status: pass
    human_judgment: false

# Metrics
duration: 4min
completed: 2026-07-12
status: complete
---

# Phase 52 Plan 03: Scoria.Observe Host-Facing Emitters Summary

**`Scoria.Observe.emit_retriever_span/1` and `emit_prompt_span/1` — two symmetric, failure-isolated host-facing span emitters that route every attribute key through Semconv/SpanKind, resolving the D-ATTR01-7 host-metadata-forwarding blocker via a Scoria-owned seam.**

## Performance

- **Duration:** 4 min (15:39:11 → 15:42:20 UTC-4, 2026-07-12)
- **Started:** 2026-07-12T19:39:11Z
- **Completed:** 2026-07-12T19:42:20Z
- **Tasks:** 2 completed (both TDD: RED → GREEN)
- **Files modified:** 4

## Accomplishments
- `Scoria.Observe.emit_retriever_span/1` — the RETR-01 spine: builds a RETRIEVER-kind span (OpenInference kind attribute, 3 retrieval-config keys via `Semconv.retrieval_config_attributes/1`, host-declared keys via `Semconv.merge_host_declared/2`), sets explicit own `:id` (D-R2), `status_code: "OK"`, wall-clock start/end, and never any tenant/workflow/session top-level field.
- `Scoria.Observe.emit_prompt_span/1` — the ATTR-02 lane and D-ATTR01-7 resolution: carries host-declared keys, omits `scoria.prompt.context` entirely when the context pack is absent/empty (D-ATTR02-7), and omits `gen_ai.usage.input_tokens` when nil (D-ATTR02-5); mints a fresh `:id` when the caller doesn't supply one.
- New `Semconv.merge_usage_input_tokens/2` — the sole call site sourcing `gen_ai.usage.input_tokens` via `ReqLLM.OpenTelemetry.Attributes.terminal/1` with a minimal usage-only metadata shape, so `observe.ex` never hand-writes a `gen_ai.*` literal (FOUND-03, verified: `grep -n 'gen_ai\.' lib/scoria/observe.ex` — no match).
- Both emitters share a private `emit_span/1` helper wrapping `:telemetry.execute([:scoria, :observe, :span, :stop], %{}, span)` in `try/rescue _ -> :ok` (D-R6) — a raising handler can never propagate into the caller's business logic.

## Task Commits

Each task was committed atomically (TDD RED → GREEN):

1. **Task 1: emit_retriever_span/1 (RETR-01 spine)**
   - `cee6324b` (test) — failing test for emit_retriever_span (5 tests: RETRIEVER kind + OpenInference attribute, id/trace_id/parent_id preservation, retrieval-config + host-declared attributes, status_code/wall-clock, raise isolation)
   - `854a0689` (feat) — `Scoria.Observe.emit_retriever_span/1` implementation
2. **Task 2: emit_prompt_span/1 (ATTR-02 lane, D-ATTR01-7 resolution)**
   - `919bafd2` (test) — failing test for emit_prompt_span (8 tests: coexistence, omit-when-empty, tolerate-absent, host-declared, span_kind/name/id, raise isolation)
   - `3865b6a7` (feat) — `Scoria.Observe.emit_prompt_span/1` implementation + `Semconv.merge_usage_input_tokens/2`

**Plan metadata:** this commit (docs: complete plan)

_Note: these 4 commits were made in a prior session; this execution verified the work, confirmed all tests pass, and completes the SUMMARY/state/final-commit steps that were not finished at the time._

## Files Created/Modified
- `lib/scoria/observe.ex` - New `Scoria.Observe` facade module: `emit_retriever_span/1`, `emit_prompt_span/1`, private `maybe_put_prompt_context/2` and `emit_span/1` helpers
- `lib/scoria/observe/semconv.ex` - Added `merge_usage_input_tokens/2` (sole `gen_ai.usage.input_tokens` sourcing seam)
- `test/scoria/observe/observe_test.exs` - New test file: 13 tests across both emitters
- `test/scoria/observe/semconv_test.exs` - Added coverage for `merge_usage_input_tokens/2`

## Decisions Made
- `emit_prompt_span/1`'s usage-input-tokens attach lives in a new `Semconv.merge_usage_input_tokens/2` function rather than inline in `observe.ex`, per Task 2's own action instructions (keep all `gen_ai.*` key sourcing solely inside Semconv, FOUND-03). This extends `files_modified` beyond the plan's literal `lib/scoria/observe.ex`/`test/scoria/observe/observe_test.exs` pair to also touch `lib/scoria/observe/semconv.ex`/`test/scoria/observe/semconv_test.exs` — explicitly sanctioned by the plan text, not a deviation.

## Deviations from Plan

None — plan executed exactly as written. (The Semconv/semconv_test.exs touch noted above was explicitly instructed by Task 2's `<action>` block, not an unplanned addition.)

## Issues Encountered

None. `mix test test/scoria/observe/` — 109 tests, 0 failures (full `observe/` regression, including the Phase-51 anti-inline grep guard in `semconv_test.exs`). `mix test test/scoria/observe/observe_test.exs` — 13 tests, 0 failures in isolation. No `gen_ai.*` string literal appears in `lib/scoria/observe.ex` (grep-verified).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

`emit_retriever_span/1` is ready for 52-04 to call from `Scoria.Knowledge.retrieve/2` as the single span-build path after the `with`-chain succeeds (trace_id/span_id join to `ai_retrieval_runs`). `emit_prompt_span/1` is ready for host prompt-assembly call sites (52-05/52-06 doc/example work). Both are already exercised end-to-end via the shared `[:scoria, :observe, :span, :stop]` telemetry event, so no further wiring is needed on the `Buffer`/`Redactor`/`ReviewerBroadcast` side. RETR-01 is only fully satisfied once 52-04 wires `emit_retriever_span/1` into the real `Knowledge.retrieve/2` call site — this plan delivers the spine, not the wiring.

---
*Phase: 52-retriever-span-host-declared-attributes*
*Completed: 2026-07-12*

## Self-Check: PASSED

All 4 modified files found on disk; all 4 task commits (`cee6324b`, `919bafd2`, `854a0689`, `3865b6a7`) found in git history.
