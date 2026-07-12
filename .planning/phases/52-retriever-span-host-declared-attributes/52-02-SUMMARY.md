---
phase: 52-retriever-span-host-declared-attributes
plan: 02
subsystem: observability
tags: [embedder, behaviour, optional-callback, knowledge, retrieval]

# Dependency graph
requires:
  - phase: 52-01
    provides: Semconv host-declared attribute seam + retrieval-config attribute builders
provides:
  - "Scoria.Knowledge.Embedder @callback model_name/0 declared @optional_callbacks [model_name: 0]"
  - "Scoria.Knowledge.Embedder.Deterministic.model_name/0 returning the stable literal \"scoria.deterministic.sha256.v1\""
affects: [52-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Optional behaviour callback + function_exported?/3 guard for host-supplied modules that may not implement every callback"

key-files:
  created: [test/scoria/knowledge/embedder_test.exs]
  modified: [lib/scoria/knowledge/embedder.ex]

key-decisions:
  - "model_name/0 is declared @optional_callbacks so host embedders that only implement embed_chunks/2 produce no missing-callback warning; the guarded function_exported?/3 call site lives in retrieve/2 (52-04), not this plan."

patterns-established:
  - "Behaviour callbacks that only Scoria's own in-app implementer (Deterministic) needs are declared optional up front, with the guard deferred to the actual call site, so host-authored implementers are never forced to grow surface area they don't need."

requirements-completed: [RETR-02]

coverage:
  - id: D1
    description: "Embedder.Deterministic.model_name/0 returns the stable literal \"scoria.deterministic.sha256.v1\""
    requirement: "RETR-02"
    verification:
      - kind: unit
        ref: "test/scoria/knowledge/embedder_test.exs#Deterministic.model_name/0 returns a stable non-empty binary literal"
        status: pass
    human_judgment: false
  - id: D2
    description: "model_name/0 is an optional callback; a module implementing only embed_chunks/2 is detectable via function_exported?/3 without raising, proving the guarded fall-through used by retrieve/2 (52-04) is safe"
    requirement: "RETR-02"
    verification:
      - kind: unit
        ref: "test/scoria/knowledge/embedder_test.exs#guarded fall-through for host embedders lacking model_name/0 function_exported?/3 returns false without raising UndefinedFunctionError"
        status: pass
      - kind: unit
        ref: "test/scoria/knowledge/embedder_test.exs#Deterministic.model_name/0 is exported (an optional callback the Deterministic embedder implements)"
        status: pass
    human_judgment: false

# Metrics
duration: 5min
completed: 2026-07-12
status: complete
---

# Phase 52 Plan 02: Optional Embedder model_name/0 Callback Summary

**Added an `@optional_callbacks`-declared `model_name/0` to `Scoria.Knowledge.Embedder` and implemented it on `Deterministic` with a stable literal, proven safe for host embedders that omit it via `function_exported?/3` (no `UndefinedFunctionError` risk).**

## Performance

- **Duration:** 5 min
- **Tasks:** 1 (TDD: RED → GREEN)
- **Files modified:** 2

## Accomplishments
- `Scoria.Knowledge.Embedder` behaviour gains `@callback model_name() :: String.t()`, declared `@optional_callbacks [model_name: 0]` so implementers are not forced to define it
- `Embedder.Deterministic.model_name/0` returns the stable literal `"scoria.deterministic.sha256.v1"`
- Unit test proves both the literal return value and that `function_exported?/3` correctly reports `false` for a module lacking the callback (proving 52-04's `retrieve/2` guard is safe to rely on)

## Task Commits

Each task was committed atomically (TDD RED → GREEN):

1. **Task 1: Add optional model_name/0 callback + Deterministic impl (RED)** - `1a574d95` (test)
2. **Task 1: Add optional model_name/0 callback + Deterministic impl (GREEN)** - `c5a21f9c` (feat)

**Plan metadata:** (this commit) - `docs: complete plan`

## Files Created/Modified
- `lib/scoria/knowledge/embedder.ex` - added `@callback model_name/0` + `@optional_callbacks [model_name: 0]` to the behaviour; added `Deterministic.model_name/0` returning the stable literal
- `test/scoria/knowledge/embedder_test.exs` - new unit test file (3 tests: literal return value, `function_exported?/3` true for `Deterministic`, `function_exported?/3` false for a module lacking the callback)

## Decisions Made
- Followed the plan literally: the caller-side `function_exported?/3` guard was deliberately NOT added here — it belongs to `retrieve/2` in plan 52-04, per the plan's explicit instruction. This plan only makes the callback optional and provides the `Deterministic` implementation.

## Deviations from Plan

None — plan executed exactly as written, including the TDD RED/GREEN sequencing (test committed first showing 2/3 failures, then the implementation committed to bring all 3 green).

## Issues Encountered
- A stale `_build/test` compilation artifact caused `function_exported?/3` to report `false` immediately after adding `model_name/0` even though `mix compile --force` had run. Resolved with a full `MIX_ENV=test mix compile --force` recompile; unrelated to the plan's code changes, not logged as a deviation since no source file needed a fix.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `Embedder.Deterministic.model_name/0` is ready for plan 52-04 to consume via a `function_exported?/3`-guarded lookup in `retrieve/2`'s `embedding_model` precedence chain (`opts[:embedding_model]` > guarded `embedder.model_name()` > `"none"`).
- No blockers.

---
*Phase: 52-retriever-span-host-declared-attributes*
*Completed: 2026-07-12*

## Self-Check: PASSED

- FOUND: lib/scoria/knowledge/embedder.ex
- FOUND: test/scoria/knowledge/embedder_test.exs
- FOUND commit: 1a574d95 (test)
- FOUND commit: c5a21f9c (feat)
