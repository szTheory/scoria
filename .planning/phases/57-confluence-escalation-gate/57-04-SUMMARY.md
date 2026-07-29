---
phase: 57-confluence-escalation-gate
plan: 04
subsystem: observability
tags: [otel, semconv, telemetry, attribute-registry, confluence]

# Dependency graph
requires:
  - phase: 55-content-trust-taint-substrate
    provides: "Trust.Verdict / trust attribute group precedent (@trust_keys, trust_attributes/1)"
  - phase: 56-tool-declared-trifecta-classification
    provides: "Classification attribute group precedent (@classification_keys, classification_attributes/1)"
provides:
  - "Scoria.Observe.Semconv.confluence_keys/0 — the five scoria.confluence.* dotted key strings"
  - "Scoria.Observe.Semconv.confluence_attributes/1 — hand-written no-passthrough fixed-key projector"
  - "Scoria.Observe.Semconv.confluence_grades/0 — the four-value closed grade enum"
  - "Five scoria.confluence.* keys registered in attribute_registry/0 with their classes"
affects: [57-01, 57-02, 57-03, 58-confluence-govern-surface]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "No-passthrough fixed-key Enum.reduce projector (mirrors trust_attributes/1 / classification_attributes/1)"
    - "Hand-written attribute-key keyword lists (never derived by aliasing the owning domain module) to preserve a dependency-free leaf module boundary"

key-files:
  created: []
  modified:
    - lib/scoria/observe/semconv.ex
    - test/scoria/observe/semconv_test.exs

key-decisions:
  - "@confluence_keys is hand-written, never derived from Scoria.Confluence — Semconv must not alias or call into Scoria.Confluence (D-03/D-08)"
  - "scoria.confluence.decision reuses guardrail_decisions/0's existing three-value set verbatim rather than introducing a parallel enum (D-08)"
  - "Neither guardrail_names/0 nor guardrail_reason_codes/0 was widened; confluence gets its own reason-code enum owned by Scoria.Confluence in a later plan (D-09, D-10)"

patterns-established:
  - "Confluence attribute group follows the exact shape of trust_attributes/1 and classification_attributes/1: guard on is_map, Enum.reduce over the keyword list, skip nil, never Map.merge/spread"

requirements-completed: [GATE-04]

coverage:
  - id: D1
    description: "Five scoria.confluence.* attribute keys registered in Semconv's closed attribute registry with correct classes (combination/decision/grade/reason_code: :enum, approval_ref: :id)"
    requirement: "GATE-04"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#attribute_registry/0 registry canary (SEC-01 Test 1)"
        status: pass
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#confluence_keys/0 + confluence_attributes/1 fixed-key projection (phase 57, GATE-04, D-08) alignment test"
        status: pass
    human_judgment: false
  - id: D2
    description: "confluence_attributes/1 is a no-passthrough fixed-key projector that drops unregistered fields, including long free-text strings, and never spreads its input map"
    requirement: "GATE-04"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#no-passthrough: unregistered fields (including a long free-text string) never reach the output"
        status: pass
    human_judgment: false
  - id: D3
    description: "guardrail_names/0 and guardrail_reason_codes/0 remain byte-identical to their pre-phase values; scoria.confluence.decision reuses guardrail_decisions/0 verbatim"
    requirement: "GATE-04"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#non-widening guard: frozen guardrail enums are unchanged by the confluence group (D-09, D-10)"
        status: pass
    human_judgment: false
  - id: D4
    description: "A caveat-free allow omits scoria.confluence.reason_code from the projector output rather than emitting a placeholder value"
    requirement: "GATE-04"
    verification:
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs#omission: a caveat-free allow with no reason_code omits scoria.confluence.reason_code"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-07-29
status: complete
---

# Phase 57 Plan 04: Confluence Attribute Group in Semconv Summary

**Five hand-written `scoria.confluence.*` keys (combination/decision/grade/reason_code/approval_ref) registered in Semconv's closed attribute registry via a no-passthrough fixed-key projector, with both frozen guardrail enums proven byte-identical to their pre-phase values.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-07-29T01:25:16Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added `@confluence_keys`, `confluence_keys/0`, `confluence_attributes/1`, and `confluence_grades/0` to `Scoria.Observe.Semconv`, following the exact shipped shape of `@trust_keys`/`trust_attributes/1` and `@classification_keys`/`classification_attributes/1`
- Registered all five `scoria.confluence.*` keys in `attribute_registry/0` with the classes D-08 specifies (`:enum` x4, `:id` for `approval_ref`)
- Updated the sorted registry canary literal in `test/scoria/observe/semconv_test.exs` from 44 to 49 keys, preserving exact-equality (never weakened to subset/count)
- Added no-passthrough, omission, and registry-alignment test coverage for `confluence_attributes/1`, plus exact-match coverage for `confluence_grades/0`
- Added a non-widening guard proving `guardrail_names/0` and `guardrail_reason_codes/0` are unchanged, and that `scoria.confluence.decision` reuses `guardrail_decisions/0`'s three-value set verbatim

## Task Commits

Each task was committed atomically:

1. **Task 1: Register the five confluence attribute keys and the fixed-key projector** - `59cbb5e0` (feat)
2. **Task 2: Update the registry canary and pin the no-passthrough and non-widening contracts** - `47e3a4fe` (test)

**Plan metadata:** (this commit, following this SUMMARY)

## Files Created/Modified
- `lib/scoria/observe/semconv.ex` - Added `@confluence_keys`, `confluence_keys/0`, `confluence_attributes/1`, `confluence_grades/0`, and five new `attribute_registry/0` entries
- `test/scoria/observe/semconv_test.exs` - Extended registry canary (44→49 keys), added confluence projector/grade test coverage, added non-widening guard for the two frozen guardrail enums

## Decisions Made
- `@confluence_keys` is hand-written rather than derived from `Scoria.Confluence` — calling into `Scoria.Confluence` from `Semconv` would create the module edge D-03 forbids (this plan runs in wave 1, independent of the `Scoria.Confluence` module a sibling plan builds concurrently)
- Placed `@confluence_keys`/`confluence_keys/0`/`confluence_grades/0` immediately after `@classification_keys`/`classification_keys/0` in the source file, keeping the trust → rail → classification → confluence grouping order established by prior phases
- `confluence_attributes/1` placed between `classification_attributes/1` and `rail_attributes/1` in projector-function order, matching declaration order of the corresponding keyword lists

## Deviations from Plan

None - plan executed exactly as written. Both tasks matched their `<action>` and `<acceptance_criteria>` blocks without requiring auto-fixes.

## Issues Encountered

Fresh worktree required `mix deps.get` before `mix compile` would succeed (expected per the environment setup notes — not a plan issue). No other issues.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `Semconv.confluence_attributes/1` is ready for the gate implementation (a sibling/later plan building `Scoria.Confluence` and wiring the executor) to call when emitting its own event on all three dispositions (allow/escalate/block), per D-08's requirement that the confluence attributes never ride the `[:scoria, :tool, :completed]` event.
- `Semconv.confluence_grades/0` is ready for the grading logic (D-29/D-30) to reference when building `%Confluence.Evidence{}`.
- No blockers. This plan deliberately does not alias or reference `Scoria.Confluence`, so it has zero merge risk against the sibling worktree building that module and `lib/scoria/mcp/executor.ex`.

---
*Phase: 57-confluence-escalation-gate*
*Completed: 2026-07-29*
