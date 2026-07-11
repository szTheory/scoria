---
phase: 49-ai-accessible-docs-and-docs-verification-gate
plan: 01
subsystem: documentation
tags: [ai-docs, llms-txt, agents-md, exunit, contracts]

requires:
  - phase: 48-exdoc-and-guide-ladder-restructure
    provides: canonical guides/ ladder, public module docs, compatibility stubs, and generated ExDoc markdown boundary
provides:
  - Root `llms.txt` public source map for AI-assisted readers
  - Root `AGENTS.md` repo-aware coding-agent contract
  - Tiny `GEMINI.md` bridge to shared agent instructions
  - `Scoria.AiDocContract` constants and focused AI docs contracts
affects: [phase-49, docs, package-surface, release-preview, ai-docs]

tech-stack:
  added: []
  patterns:
    - Root AI docs use source repository paths rather than generated ExDoc paths.
    - AI docs contracts assert facts, headings, fragments, and boundaries instead of full prose snapshots.

key-files:
  created:
    - llms.txt
    - AGENTS.md
    - lib/scoria/ai_doc_contract.ex
    - test/scoria/ai_doc_contract_test.exs
    - .planning/phases/49-ai-accessible-docs-and-docs-verification-gate/49-01-SUMMARY.md
  modified:
    - GEMINI.md

key-decisions:
  - "Root `llms.txt` is the public AI-readable source map and links to source docs, public modules, guides, and verification suites."
  - "Root `AGENTS.md` is the shared repo-agent operating contract; no `CLAUDE.md`, `CODEX.md`, or additional full vendor-specific root docs were created."
  - "`GEMINI.md` remains a tiny repo-only bridge that preserves the Ash non-goal and delegates shared instructions to `AGENTS.md`."

patterns-established:
  - "Scoria.AiDocContract follows the existing zero-arity docs-contract getter pattern while staying out of public ExDoc curation."
  - "Root AI docs explicitly distinguish README/guides source docs from compatibility stubs and generated `doc/` output."

requirements-completed: [AI-01, AI-02]

duration: 4 min
completed: 2026-07-11
status: complete
---

# Phase 49 Plan 01: Root AI Docs and Contract Constants Summary

**Root AI-readable docs now give humans and coding agents one source-oriented map, one repo-agent operating contract, and a small tested contract module that keeps those files aligned.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-11T00:34:33Z
- **Completed:** 2026-07-11T00:37:57Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `Scoria.AiDocContract` with root AI doc paths, package/repo-only path decisions, required `llms.txt` paths/headings, required `AGENTS.md` sections, source/generated boundary fragments, and forbidden-fragment guards.
- Added `llms.txt` with a public source map for README, canonical guides, public source files, capability guides, verification suites, and derived-reference boundaries.
- Added `AGENTS.md` with repo-agent guidance for source truth, generated files, verification commands, public vocabulary, public API boundaries, and avoid rules.
- Converted `GEMINI.md` into a tiny bridge that preserves the Ash non-goal and points to `AGENTS.md`.
- Added focused ExUnit contracts that prove AI-01 and AI-02 without snapshotting full root doc prose.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add AI docs contract tests** - `77c010ed` (`test`)
2. **Task 1 GREEN: Add AI docs contract constants** - `2e45f5a9` (`feat`)
3. **Task 2 RED: Add root AI docs body contracts** - `bf2c2a0a` (`test`)
4. **Task 2 GREEN: Add root AI docs entry points** - `d90413ef` (`feat`)

**Plan metadata:** recorded in this closeout commit

## Files Created/Modified

- `llms.txt` - Public AI-readable source map for docs, public source files, capability guides, and verification suites.
- `AGENTS.md` - Shared repo-aware coding-agent instructions.
- `GEMINI.md` - Tiny Gemini bridge to `AGENTS.md` with the Ash non-goal preserved.
- `lib/scoria/ai_doc_contract.ex` - Internal contract constants for AI docs.
- `test/scoria/ai_doc_contract_test.exs` - Fact-level AI docs contract tests.

## Verification

- `MIX_ENV=test mix test test/scoria/ai_doc_contract_test.exs --warnings-as-errors` - RED for missing `Scoria.AiDocContract`, then PASS after Task 1 GREEN.
- `MIX_ENV=test mix test test/scoria/ai_doc_contract_test.exs --warnings-as-errors` - RED for missing `llms.txt`, missing `AGENTS.md`, and missing Gemini bridge after Task 2 RED.
- `MIX_ENV=test mix test test/scoria/ai_doc_contract_test.exs test/scoria/terminology_contract_test.exs --warnings-as-errors` - PASS, 20 tests, 0 failures after Task 2 GREEN.

## Decisions Made

- Kept `GEMINI.md` repo-only and adapter-sized; Plan 02 owns package and release-preview exclusion enforcement.
- Put AI docs constants in `Scoria.AiDocContract` instead of broadening `Scoria.AdopterDocContract`.
- Kept forbidden fragments precise enough to block planning-only paths and future-seed claims without blocking source/generated compatibility-stub wording.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 02 can now wire `llms.txt` and `AGENTS.md` into package inventory and release-preview required paths, explicitly keep `GEMINI.md` repo-only, and turn release preview into the docs warning gate.

## Self-Check: PASSED

- Found root docs: `llms.txt`, `AGENTS.md`, and `GEMINI.md`.
- Found contract module and tests: `lib/scoria/ai_doc_contract.ex`, `test/scoria/ai_doc_contract_test.exs`.
- Found task commits for `49-01` in git history.
- Focused AI docs and terminology contract command passed.

---
*Phase: 49-ai-accessible-docs-and-docs-verification-gate*
*Completed: 2026-07-11*
