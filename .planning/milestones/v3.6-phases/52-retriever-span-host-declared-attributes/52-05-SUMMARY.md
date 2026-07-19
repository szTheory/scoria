---
phase: 52-retriever-span-host-declared-attributes
plan: 05
subsystem: observability
tags: [telemetry, semconv, opentelemetry, openinference, req_llm, jido]

# Dependency graph
requires:
  - phase: 52-01
    provides: "Semconv.merge_host_declared/2 (host-declared keys single seam)"
provides:
  - "req_llm adapter attribute pipe includes Semconv.merge_host_declared(metadata)"
  - "jido adapter attribute pipe includes Semconv.merge_host_declared(metadata)"
  - "Inline code comments documenting the D-ATTR01-7 reachability caveat on both adapters"
  - "Adapter tests proving host-key byte-for-byte pass-through and never-default absence"
affects: [52-retriever-span-host-declared-attributes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single-seam host-declared attribute merge (Semconv.merge_host_declared/2) reused identically across RETRIEVER span, prompt span, and both adapters"

key-files:
  created: []
  modified:
    - lib/scoria/observe/adapters/req_llm.ex
    - lib/scoria/observe/adapters/jido.ex
    - test/scoria/observe/adapters/jido_test.exs
    - test/scoria/observe/adapters/req_llm_test.exs

key-decisions:
  - "Both adapters pipe metadata through Semconv.merge_host_declared/2 identically -- no adapter-specific key handling, keeping the seam single-origin."
  - "req_llm.ex carries an explicit inline comment documenting D-ATTR01-7: the pipe stage is correct/harmless but only exercised by hand-synthesized test events, not real production req_llm emissions (production carrier is emit_prompt_span/1 from 52-03)."
  - "jido.ex carries an explicit inline comment noting its metadata IS host-supplied at the call site, so the same pipe stage is reachable on real production TOOL-span emissions."

patterns-established: []

requirements-completed: [ATTR-01]

coverage:
  - id: D1
    description: "Both adapters (req_llm, jido) route metadata through Semconv.merge_host_declared/2 so feature/route/archetype/intent ride the LLM and TOOL spans when present"
    requirement: "ATTR-01"
    verification:
      - kind: unit
        ref: "test/scoria/observe/adapters/jido_test.exs#D-ATTR01-5: host-declared attribute pass-through (production-shaped) a host-supplied feature key passes through byte-for-byte and an omitted host key is absent"
        status: pass
      - kind: unit
        ref: "test/scoria/observe/adapters/req_llm_test.exs#D-ATTR01-5: host-declared attribute pass-through a host-supplied feature key passes through byte-for-byte and an omitted host key is absent"
        status: pass
    human_judgment: false
  - id: D2
    description: "No reserved host-declared key string literal (feature/route/archetype/intent) appears inline in either adapter file -- the seam owns them (52-01 anti-inline discipline)"
    requirement: "ATTR-01"
    verification:
      - kind: unit
        ref: "grep -nE '\"(feature|route|archetype|intent)\"' lib/scoria/observe/adapters/req_llm.ex lib/scoria/observe/adapters/jido.ex (no matches)"
        status: pass
      - kind: unit
        ref: "test/scoria/observe/semconv_test.exs (anti-inline grep guards, 22 tests)"
        status: pass
    human_judgment: false

duration: 8min
completed: 2026-07-12
status: complete
---

# Phase 52 Plan 05: Adapter Host-Declared Attribute Pipe Summary

**Inserted the shared `Semconv.merge_host_declared/2` stage into both req_llm and jido adapter attribute pipes so host-declared feature/route/archetype/intent keys ride the LLM and TOOL spans when present in metadata, with the jido path proven production-reachable and the req_llm path's hand-synthesized-only caveat documented inline.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-12T20:24:36Z
- **Completed:** 2026-07-12T20:27:13Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- `Semconv.merge_host_declared(metadata)` added as the final pipe stage in both `req_llm.ex` and `jido.ex` attribute pipelines
- Inline code comments in both adapters document the D-ATTR01-7 reachability asymmetry (req_llm test-only vs. jido production-reachable) without restating any reserved key literal
- New tests in both adapter test files prove byte-for-byte host-key pass-through and never-default (absent key -> absent attribute) behavior
- `mix test test/scoria/observe/adapters/` green (12 tests, up from 10); `mix test test/scoria/observe/semconv_test.exs` green (22 tests, anti-inline grep guards unaffected)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add merge_host_declared/2 pipe to both adapters** - `7d81ef95` (feat)
2. **Task 2: Adapter host-key pass-through tests (real-shape for jido)** - `52f359c2` (test)

**Plan metadata:** (this commit)

## Files Created/Modified
- `lib/scoria/observe/adapters/req_llm.ex` - added `Semconv.merge_host_declared(metadata)` pipe stage + D-ATTR01-7 caveat comment
- `lib/scoria/observe/adapters/jido.ex` - added `Semconv.merge_host_declared(metadata)` pipe stage + production-reachability comment
- `test/scoria/observe/adapters/jido_test.exs` - added production-shaped host-key pass-through test
- `test/scoria/observe/adapters/req_llm_test.exs` - added parallel pass-through test on the adapter's hand-synthesized event, with D-ATTR01-7 caveat documented in a comment

## Decisions Made
- No deviations from the plan's literal instruction on where to insert the pipe stage or what to assert in tests.
- Chose `"support-copilot"` as the non-deny-listed sample `feature` value per the plan's own example, and `"route"` as the omitted-key control in both new tests, consistent with `Semconv.host_declared_keys/0`'s canonical ordering.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Both adapters now generalize the host-declared attribute convention established in 52-01/52-03. This closes out the last of the 6 planned Phase 52 plans covering ATTR-01's adapter-level coverage; the RETRIEVER-span and prompt-span carriers (52-02/52-03/52-04) remain the reliable production paths for the LLM/prompt lane, as documented inline. No blockers for phase closeout.

---
*Phase: 52-retriever-span-host-declared-attributes*
*Completed: 2026-07-12*

## Self-Check: PASSED

- FOUND: .planning/phases/52-retriever-span-host-declared-attributes/52-05-SUMMARY.md
- FOUND: lib/scoria/observe/adapters/req_llm.ex
- FOUND: lib/scoria/observe/adapters/jido.ex
- FOUND: commit 7d81ef95 (feat: merge_host_declared pipe stage)
- FOUND: commit 52f359c2 (test: adapter host-key pass-through tests)
