---
phase: 51-foundation-fix-key-convention-span-kind-taxonomy
plan: 02
subsystem: observability
tags: [otel-genai, openinference, req_llm, semconv, elixir]

# Dependency graph
requires:
  - phase: 51-01
    provides: Scoria.Observe.SpanKind (canonical 8-value span_kind taxonomy module)
provides:
  - "Scoria.Observe.Semconv module — single version-pinned source for the one openinference.span.kind key Scoria writes, plus the sole delegation seam to ReqLLM.OpenTelemetry.Attributes.start/1 + .terminal/1 for the gen_ai.* key set"
affects: [51-04, 51-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Delegating semconv module: do NOT hand-duplicate a dependency's already-correct, version-pinned key vocabulary — call its builder functions verbatim"

key-files:
  created:
    - lib/scoria/observe/semconv.ex
    - test/scoria/observe/semconv_test.exs
  modified: []

key-decisions:
  - "Semconv.merge_req_llm_attributes/2 delegates wholesale to ReqLLM.OpenTelemetry.Attributes.start/1 + .terminal/1 rather than re-declaring the ~20 gen_ai.* key strings, per RESEARCH Pattern 3 / D-16 — avoids a second, driftable copy of req_llm's own vocabulary"
  - "Realistic test fixtures use LLMDB.Model.new!/1 (a real %LLMDB.Model{} struct) for metadata[:model], not a bare string — matches production [:req_llm, :request, :stop] telemetry shape (RESEARCH Pitfall 1)"

patterns-established:
  - "Plain-module-with-constants delegation shape (no GenServer/behaviour), matching Scoria.Observe.CircuitBreaker/SpanKind — reused by future Scoria.Observe.* utility modules"

requirements-completed: [FOUND-03]

coverage:
  - id: D1
    description: "Scoria.Observe.Semconv.openinference_span_kind_key/0 returns the exact string \"openinference.span.kind\""
    requirement: FOUND-03
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#openinference_span_kind_key/0 returns exactly \"openinference.span.kind\""
        status: pass
    human_judgment: false
  - id: D2
    description: "Semconv.merge_req_llm_attributes/2 delegates to ReqLLM.OpenTelemetry.Attributes.start/1 + .terminal/1 and returns the full gen_ai.request.{model,temperature,top_p,max_tokens,seed} + gen_ai.usage.* key set together, while preserving caller-supplied base attributes, from a realistic %LLMDB.Model{}-shaped metadata fixture"
    requirement: FOUND-03
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#preserves base attrs and carries model-config + usage keys together, from a realistic %LLMDB.Model{}-shaped [:req_llm, :request, :stop] fixture"
        status: pass
    human_judgment: false
  - id: D3
    description: "Single-origin guard: semconv.ex source contains zero hand-declared gen_ai.* string literals (delegation only, not duplication)"
    requirement: FOUND-03
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#single-origin guard: semconv.ex source contains no hand-declared gen_ai.* literal"
        status: pass
    human_judgment: false

duration: 3min
completed: 2026-07-12
status: complete
---

# Phase 51 Plan 02: Semconv Delegating Module Summary

**Created `Scoria.Observe.Semconv` — a plain delegating module that owns the one `openinference.span.kind` key Scoria itself writes, and is the sole call site for `ReqLLM.OpenTelemetry.Attributes.start/1` + `.terminal/1` so no adapter ever inlines a `gen_ai.*` string literal.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-12T14:47:40Z
- **Completed:** 2026-07-12T14:50:52Z
- **Tasks:** 2 completed
- **Files modified:** 2 (1 created lib, 1 created test)

## Accomplishments
- `Scoria.Observe.Semconv.openinference_span_kind_key/0` — the single Scoria-owned semconv key accessor, version-pinned in the moduledoc against `req_llm ~> 1.13` / OTel-GenAI schema `1.37.0`.
- `Scoria.Observe.Semconv.merge_req_llm_attributes/2` — delegates wholesale to `ReqLLM.OpenTelemetry.Attributes.start/1` + `.terminal/1`, satisfying SC#4 (single version-pinned key origin) without hand-duplicating req_llm's ~20 `gen_ai.*` constants.
- Unit test suite proves: exact-string accessor, full model-config + usage key presence together (SPAN-01 completeness proof at the Semconv layer), base-attribute preservation, and a single-origin source guard that fails RED if a future edit hand-writes a `gen_ai.*` literal into `semconv.ex`.

## Task Commits

Each task was committed atomically (TDD RED/GREEN for Task 1; test-extension commit for Task 2):

1. **Task 1: Create Scoria.Observe.Semconv delegating module** (TDD)
   - `6e436845` (test) — add failing test for openinference_span_kind_key/0 + merge_req_llm_attributes/2
   - `64f79905` (feat) — implement Scoria.Observe.Semconv delegating module
2. **Task 2: Semconv unit test — single-origin + delegation proof**
   - `686193b6` (test) — extend Semconv test with single-origin + delegation proof (realistic %LLMDB.Model{} fixture)

**Plan metadata:** (this commit, docs — see final commit below)

## Files Created/Modified
- `lib/scoria/observe/semconv.ex` — new plain module: `openinference_span_kind_key/0` + `merge_req_llm_attributes/2` (delegates to `ReqLLM.OpenTelemetry.Attributes`).
- `test/scoria/observe/semconv_test.exs` — new test file: 6 tests covering the accessor, key-completeness, base-attribute preservation, and the single-origin source guard.

## Decisions Made
- Followed RESEARCH Pattern 3 verbatim: `merge_req_llm_attributes/2` is a two-step `Map.merge` pipe over `ReqLLM.OpenTelemetry.Attributes.start/1` then `.terminal/1` — no hand-derived `gen_ai.*` key names anywhere in the module.
- Test fixtures build a real `%LLMDB.Model{}` via `LLMDB.Model.new!(%{id: "gpt-5", provider: :openai})` rather than a bare string, matching the real `[:req_llm, :request, :stop]` telemetry shape (RESEARCH Pitfall 1) so the delegation proof isn't testing an unrealistic path.

## Deviations from Plan

None — plan executed exactly as written. Task 1's TDD RED/GREEN cycle and Task 2's test extension both matched the plan's `<action>` blocks verbatim (the plan gave the real, non-pseudocode module and test shapes to copy).

## Issues Encountered
- One test name exceeded ExUnit's 255-character computed-name limit (describe block name + test name concatenated); shortened the test name without changing its assertions. Not a deviation from plan intent, just a mechanical ExUnit constraint.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `Scoria.Observe.Semconv` is ready for Wave 2 adapter wiring (plans 04/05): `req_llm.ex` will call `Semconv.merge_req_llm_attributes/2` + `Semconv.openinference_span_kind_key/0` instead of any inline `gen_ai.*`/`openinference.*` literal.
- No blockers. `mix test test/scoria/observe/` (67 tests) and `mix test test/scoria/observe/semconv_test.exs` (6 tests) both green.

---
*Phase: 51-foundation-fix-key-convention-span-kind-taxonomy*
*Completed: 2026-07-12*

## Self-Check: PASSED

All created files and commit hashes verified present on disk / in git log.
