---
phase: 52-retriever-span-host-declared-attributes
plan: 06
subsystem: observability
tags: [telemetry, ecto, postgres, opentelemetry, openinference, exunit]

# Dependency graph
requires:
  - phase: 52-03
    provides: "Scoria.Observe.emit_prompt_span/1 (the prompt-composition span emitter with host-declared keys, context_pack, and gen_ai.usage.input_tokens merge)"
provides:
  - "SC#4 real-emission acceptance proof: emit_prompt_span/1 -> Buffer -> Postgres persists scoria.prompt.context coexisting with gen_ai.usage.input_tokens"
  - "never-text end-to-end guard over the persisted composition value"
  - "ATTR-01 host-key pass-through proof on a real prompt-span emission"
affects: [53-structured-child-spans-and-ai-span-events]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Real-emission DB-backed test pattern for Observe emitters: checkout sandbox, start a scoped supervised Buffer, detach/re-attach the shared Scoria.Observe.Telemetry handler onto that scoped buffer name, call the public emitter, Buffer.flush_now/1, then Repo.get_by!/2 the persisted row (mirrors telemetry_test.exs; avoids hand-synthesized :telemetry.execute calls, D-ATTR01-6)."

key-files:
  created:
    - test/scoria/observe/prompt_span_test.exs
  modified:
    - .planning/phases/52-retriever-span-host-declared-attributes/deferred-items.md

key-decisions:
  - "Test file mirrors telemetry_test.exs's real DB-backed setup (scoped Buffer + Telemetry.attach) rather than hand-synthesizing a span map, so the SC#4 proof exercises the actual production telemetry->buffer->Postgres pipeline (D-ATTR01-6)."
  - "The never-text guard walks the persisted composition value recursively (not just the top-level chunk/memory item shape), asserting no key matches the forbidden regex and every leaf is a non-empty binary or non-negative integer, matching D-ATTR02-4's structural guarantee end-to-end on real persisted data."

patterns-established:
  - "Real-emission DB-backed test pattern for Observe emitters (see tech-stack.patterns above) — reusable for the analogous RETRIEVER-span acceptance test if one is added later."

requirements-completed: [ATTR-02, ATTR-01]

coverage:
  - id: D1
    description: "A real emit_prompt_span/1 call with a populated context_pack (>=1 chunk AND >=1 memory with token counts) plus host input_tokens persists an ai_spans row whose attributes carry BOTH the nested scoria.prompt.context map and gen_ai.usage.input_tokens (SC#4 coexistence)."
    requirement: "ATTR-02"
    verification:
      - kind: integration
        ref: "test/scoria/observe/prompt_span_test.exs#SC#4: populated context_pack coexists with gen_ai.usage.input_tokens persisted span attributes carry both scoria.prompt.context and gen_ai.usage.input_tokens"
        status: pass
    human_judgment: false
  - id: D2
    description: "The persisted scoria.prompt.context value contains only IDs and counts end-to-end — no key matches the never-text regex and every chunk/memory item has only id/tokens keys."
    requirement: "ATTR-02"
    verification:
      - kind: integration
        ref: "test/scoria/observe/prompt_span_test.exs#SC#4: populated context_pack coexists with gen_ai.usage.input_tokens the persisted composition value carries only IDs and counts (never-text, end-to-end)"
        status: pass
    human_judgment: false
  - id: D3
    description: "A non-deny-listed host feature value passes byte-for-byte onto the prompt span on a real emission; an omitted host key (route/archetype/intent) is absent from the persisted attributes."
    requirement: "ATTR-01"
    verification:
      - kind: integration
        ref: "test/scoria/observe/prompt_span_test.exs#ATTR-01: host-declared keys on a real prompt-span emission (D-ATTR01-6) a non-deny-listed host feature value passes byte-for-byte; an omitted host key is absent"
        status: pass
    human_judgment: false
  - id: D4
    description: "With input_tokens absent, scoria.prompt.context persists and the gen_ai.usage.input_tokens key is absent (no unconditional-presence assertion)."
    requirement: "ATTR-02"
    verification:
      - kind: integration
        ref: "test/scoria/observe/prompt_span_test.exs#input_tokens absence tolerance (D-ATTR02-5) populated pack, no input_tokens: prompt-context persists and the usage key is absent"
        status: pass
    human_judgment: false
  - id: D5
    description: "With no context_pack, the scoria.prompt.context key is absent from the persisted span."
    requirement: "ATTR-02"
    verification:
      - kind: integration
        ref: "test/scoria/observe/prompt_span_test.exs#empty-pack omit (D-ATTR02-7) no context_pack: scoria.prompt.context is absent from the persisted span"
        status: pass
    human_judgment: false

duration: 16min
completed: 2026-07-12
status: complete
---

# Phase 52 Plan 06: SC#4 Prompt-Span Acceptance Summary

**A real `emit_prompt_span/1` emission — driven through the actual telemetry -> `Buffer` -> Postgres pipeline (not a hand-synthesized event) — persists `ai_spans` attributes carrying the nested `scoria.prompt.context` composition map coexisting with `gen_ai.usage.input_tokens`, proving SC#4 end-to-end.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-07-12T20:53:43Z
- **Completed:** 2026-07-12T21:09:35Z
- **Tasks:** 1
- **Files modified:** 1 created (`test/scoria/observe/prompt_span_test.exs`), 1 deferred-items note appended

## Accomplishments
- Real-emission SC#4 acceptance test: a populated `context_pack` (2 chunks, 1 memory, all with token counts) plus host `input_tokens` persists an `ai_spans` row whose attributes carry both `scoria.prompt.context` and `gen_ai.usage.input_tokens` after `Buffer.flush_now/1` against real Postgres.
- Never-text end-to-end guard: recursively walks the persisted composition value, asserting no key matches `~r/text|content|body|message|prompt|raw/i` and every leaf is a non-empty binary (an ID) or non-negative integer; separately asserts every chunk/memory item has exactly `id`/`tokens` keys.
- ATTR-01 proof on a REAL prompt-span emission (not hand-synthesized, D-ATTR01-6): a non-deny-listed `feature` value passes byte-for-byte onto the persisted span; omitted host keys (`route`/`archetype`/`intent`) are absent.
- `input_tokens`-absence tolerance (D-ATTR02-5): populated pack with no `input_tokens` persists `scoria.prompt.context` while the usage key stays absent — no unconditional-presence assertion.
- Empty-pack omit proof (D-ATTR02-7): no `context_pack` means `scoria.prompt.context` is absent from the persisted span entirely.

## Task Commits

Each task was committed atomically:

1. **Task 1: SC#4 prompt-span acceptance (real emit + flush_now + persisted-span assertions)** - `c3cd834c` (test)

**Plan metadata:** (this commit, appended below)

## Files Created/Modified
- `test/scoria/observe/prompt_span_test.exs` - Real-Postgres integration test for `emit_prompt_span/1`: SC#4 coexistence, never-text end-to-end guard, ATTR-01 host-key pass-through, `input_tokens`-absence tolerance, empty-pack key-omission (5 tests).
- `.planning/phases/52-retriever-span-host-declared-attributes/deferred-items.md` - Logged 2 additional pre-existing `test/tmp` cross-test race failures observed on this plan's full-suite run (out of scope, unrelated to `Observe`/prompt-span files).

## Decisions Made
- Mirrored `test/scoria/observe/telemetry_test.exs`'s real DB-backed setup (sandbox checkout, a scoped supervised `Buffer`, detach/re-attach `Scoria.Observe.Telemetry` onto that scoped buffer name) instead of hand-synthesizing a span map via raw `:telemetry.execute/3` — required by D-ATTR01-6's warning against treating synthetic events as production evidence.
- Implemented the never-text guard as a full recursive walk over the persisted value (not just a shallow key check) so the D-ATTR02-4 structural guarantee is proven on the actual persisted `token_budget`/`chunks`/`memories` nesting, not just the top-level shape.

## Deviations from Plan

None - plan executed exactly as written. The single task's action, verification, and acceptance criteria were implemented literally; no bugs, missing functionality, or blocking issues were found in `emit_prompt_span/1`, `Semconv`, or `Buffer` that required auto-fixing.

## Issues Encountered

Ran the full `mix test` suite per the plan's phase-gate verification step and observed 4 pre-existing failures, none touching this plan's file (`test/scoria/observe/prompt_span_test.exs`):
- `Scoria.KnowledgeLaneContractTest` file-set drift and `Scoria.WarningInventory.CaptureParityTest` flakiness — both already logged as pre-existing in `deferred-items.md` from plan 52-04.
- `Mix.Tasks.Scoria.InstallCheckTest` and `Scoria.WarningInventory.TmpPreflightTest` — two additional `test/tmp` cross-test concurrency races (SEED-004 class), newly logged in `deferred-items.md` under "Found during 52-06".

All 5 tests in `test/scoria/observe/prompt_span_test.exs` pass in isolation (`mix test test/scoria/observe/prompt_span_test.exs`). Per the Scope Boundary policy these are out-of-scope pre-existing issues, not caused by this plan's changes, and were logged rather than fixed inline.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 52 (retriever-span-host-declared-attributes) plans 1-6 are now all complete: RETR-01/RETR-02 (RETRIEVER span + config attributes), ATTR-01 (host-declared keys convention), and ATTR-02 (prompt-composition attributes) are all implemented and proven with real-Postgres acceptance tests.
- Phase 53 relocates the identical `scoria.prompt.context`/`gen_ai.usage.input_tokens` Semconv keys from this Scoria-emitted composition span onto a real duration/parent-linked `PROMPT` child span, with zero contract change (D-ATTR02-1) — this plan's test asserts the current-span behavior that Phase 53 must preserve byte-for-byte.
- 4 pre-existing full-suite failures remain open project-level debt (SEED-004 test-determinism class); see `deferred-items.md`.

---
*Phase: 52-retriever-span-host-declared-attributes*
*Completed: 2026-07-12*

## Self-Check: PASSED

- FOUND: test/scoria/observe/prompt_span_test.exs
- FOUND: c3cd834c
