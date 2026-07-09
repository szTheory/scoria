---
phase: 45-correctness-sweep-fail-closed-proof-closeout
plan: 02
subsystem: knowledge
tags: [grounding, citations, chunker, non-overlap]
requires:
  - phase: 43-knowledge-tenant-isolation
    provides: scoped knowledge persistence and citation evidence
provides:
  - Label-aware citation-presence scoring
  - Non-overlapping default chunker behavior
  - Repeat-ingest offset and digest stability proof
affects: [knowledge, grounding, chunking, phase-45]
tech-stack:
  added: []
  patterns: [strict boolean labels, non-overlapping default chunks]
key-files:
  created: []
  modified:
    - lib/scoria/knowledge/grounding.ex
    - lib/scoria/knowledge/chunker.ex
    - test/scoria/knowledge/grounding_test.exs
    - test/scoria/knowledge_test.exs
key-decisions:
  - "Only strict boolean `expected_answerable` or `answerable` labels affect citation-presence scoring."
  - "The default chunker remains section/paragraph based and non-overlapping; real overlap belongs to a future chunker."
patterns-established:
  - "Missing answerability labels preserve legacy empty-citation failure."
  - "Default chunk offsets advance directly to the previous chunk end."
requirements-completed: [FIX-02, FIX-03]
duration: 1h
completed: 2026-07-07
status: complete
---

# Phase 45-02: Grounding And Chunker Summary

**Citation presence now respects explicit answerability labels, and the default chunker is locked as non-overlapping.**

## Performance

- **Duration:** 1h
- **Started:** 2026-07-07
- **Completed:** 2026-07-07
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added the full answerability matrix for answerable/unanswerable cases with citations and without citations.
- Preserved fail-closed legacy behavior when no answerability label is present.
- Removed the dead default-chunker overlap option read and documented the default chunker as non-overlapping.
- Proved repeat ingest preserves deterministic offsets and chunk digests even when callers pass `overlap:`.

## Task Commits

1. **Grounding labels and chunk offsets** - `03d9bef8` (`fix`)

## Files Created/Modified

- `lib/scoria/knowledge/grounding.ex` - Normalizes strict boolean answerability labels and records canonical details.
- `lib/scoria/knowledge/chunker.ex` - Documents and implements non-overlapping offset advancement.
- `test/scoria/knowledge/grounding_test.exs` - Answerability matrix, alias, string-key, and missing-label tests.
- `test/scoria/knowledge_test.exs` - Default chunker non-overlap and repeat-ingest stability tests.

## Decisions Made

The citation-presence scorer remains a citation expectation check only. It does not parse refusal prose, perform semantic answerability scoring, or emit `not_scored`.

## Deviations from Plan

The plan's direct `MIX_ENV=test mix test --include knowledge ...` command was replaced with the repo's canonical `mix test.knowledge` lane because that path applies knowledge migrations.

## Issues Encountered

None beyond the command-lane adjustment above.

## Verification

- `MIX_ENV=test mix test.knowledge test/scoria/knowledge/grounding_test.exs test/scoria/knowledge_test.exs --warnings-as-errors` - PASS, 13 tests, 0 failures.

## User Setup Required

None.

## Next Phase Readiness

FIX-02 and FIX-03 are ready for final closeout proof and prohibition checks.

---
*Phase: 45-correctness-sweep-fail-closed-proof-closeout*
*Completed: 2026-07-07*
