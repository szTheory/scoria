---
phase: 46-terminology-and-public-vocabulary-migration
plan: 07
subsystem: docs/public-api
tags: [terminology, docs, reviewer, trace, semantic-cache, scoped-context, compatibility]

requires: [46-06]
provides:
  - final vocabulary across README and stable adopter guides
  - public Scoria facade docs for scoped_context
  - expanded terminology drift guards for public docs and facade docs
  - retained semantic_fast_path.md path with semantic cache content
affects: [phase-46, README, guides, public-facade-docs, docs-contracts]

tech-stack:
  added: []
  patterns:
    - Stable guide paths can remain while visible vocabulary migrates
    - Legacy aliases are allowed only in explicit 0.1.x compatibility notes
    - Public facade docs should teach preferred option aliases before storage-backed legacy names

key-files:
  modified:
    - lib/scoria.ex
    - lib/scoria/adopter_doc_contract.ex
    - README.md
    - docs/adoption_lanes.md
    - docs/bounded_handoffs.md
    - docs/phoenix_runtime_example.md
    - docs/semantic_fast_path.md
    - docs/operator_verification.md
    - docs/connector_adoption.md
    - docs/support_copilot_gallery.md
    - test/scoria/adoption_surface_test.exs
    - test/scoria/terminology_contract_test.exs
    - test/scoria/semantic_fast_path_example_source_test.exs
    - test/support/scoria/adoption_example.ex

key-decisions:
  - "README and stable guides now use reviewer, trace, capability, verification suite, scoped context, semantic cache, and optional knowledge base vocabulary."
  - "docs/semantic_fast_path.md remains the stable file path, but its title and content now present the semantic cache concept and preferred profile API."
  - "Scoria.start_handoff_run/3 docs prefer scoped_context: and frame projected_context: only as a legacy 0.1.x compatibility alias."
  - "AdopterDocContract now uses semantic cache as the shipped capability noun, matching the final docs vocabulary."

patterns-established:
  - "Terminology contracts should scan both selected Markdown docs and public facade docs."
  - "Source-fragment tests should move with public docs when examples switch from legacy aliases to preferred names."

requirements-completed: [TERM-01, TERM-02, TERM-03]

duration: 14 min
completed: 2026-07-09
status: complete
---

# Phase 46 Plan 07: Public Docs Vocabulary Summary

**README and stable adopter guides now use the final public vocabulary while preserving explicit 0.1.x compatibility notes.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-07-09T22:38:00Z
- **Completed:** 2026-07-09T22:52:00Z
- **Tasks:** 1
- **Files modified:** 14

## Accomplishments

- Migrated README and stable guides from lane/operator/projected-context/semantic-fast-path wording to capability/reviewer/scoped-context/semantic-cache vocabulary.
- Removed retired current-doc wording: `Keystone`, `v2.0 Relay`, and `The Four Lanes`.
- Updated public `Scoria.start_handoff_run/3` docs to show `scoped_context:` first and `projected_context:` as a legacy 0.1.x compatibility alias.
- Updated semantic cache examples to `use Scoria.SemanticCache.Profile`, `cache_key:`, and `semantic_cache: [profile: MyApp.AI.AccountFaqCache]`.
- Preserved evidence wording for RAG/citation, grounding, audit, and support proof while switching run-inspection surfaces to trace vocabulary.
- Expanded terminology and adoption-surface tests to guard stable docs, selected public facade docs, retired wording, glossary links, preferred public examples, and explicit compatibility aliases.

## Task Commits

1. **Task 1 RED: Final vocabulary docs contract** - `4fc69733` (test)
2. **Task 1 GREEN: Public docs vocabulary migration** - `dc0fdba4` (docs)

## Files Created/Modified

- `lib/scoria.ex` - `start_handoff_run/3` docs now prefer `scoped_context:` and mark `projected_context:` legacy.
- `lib/scoria/adopter_doc_contract.ex` - Capability noun SSOT now uses semantic cache.
- `README.md` - Final public vocabulary, preferred identifiers, and explicit 0.1.x compatibility note.
- `docs/adoption_lanes.md` - Capability guide language, verification suite wording, semantic cache example, and glossary link.
- `docs/bounded_handoffs.md` - Scoped context, delegated trace, and compatibility alias language.
- `docs/phoenix_runtime_example.md` - Removed retired code name and updated trace/scoped-context examples.
- `docs/semantic_fast_path.md` - Stable path retained; content migrated to semantic cache/profile vocabulary.
- `docs/operator_verification.md` - Reviewer/verification-suite wording and preferred `VerificationSuites` references.
- `docs/connector_adoption.md` - Reviewer/capability/verification-suite wording and glossary link.
- `docs/support_copilot_gallery.md` - Reviewer/capability/verification-suite wording and glossary link.
- `test/scoria/adoption_surface_test.exs` - Final vocabulary expectations for README and guides.
- `test/scoria/terminology_contract_test.exs` - Stable docs and facade docs terminology guards.
- `test/scoria/semantic_fast_path_example_source_test.exs` - Semantic cache profile example guard.
- `test/support/scoria/adoption_example.ex` - Bounded handoff scoped-context source fragments.

## Decisions Made

- Kept `docs/semantic_fast_path.md` as the file path for link stability during Phase 46.
- Left real storage/error names such as `projected_context:` and `:unsafe_projected_context` only where they are explicit legacy compatibility or runtime result details.
- Kept `VerificationLanes.closeout_order/0` in one explicit 0.1.x compatibility note while making `Scoria.VerificationSuites` the preferred reference.

## Deviations from Plan

- Updated `lib/scoria/adopter_doc_contract.ex` because its capability noun SSOT still required "semantic fast path" after docs moved to semantic cache.
- Updated `test/scoria/semantic_fast_path_example_source_test.exs` and `test/support/scoria/adoption_example.ex` because existing source-fragment guards pinned the old public examples.

**Total deviations:** 2 auto-fixed.
**Impact on plan:** No scope change; both updates were required for final-vocabulary docs verification.

## Issues Encountered

- The first GREEN verification caught the stale capability noun SSOT and a bounded-handoff gap paragraph that no longer contained the word "closeout"; both were corrected without reintroducing retired milestone wording.

## Verification

- `bash -lc 'set -euo pipefail; ! rg -n "Keystone|v2\\.0 Relay|The Four Lanes" README.md docs; MIX_ENV=test mix test --warnings-as-errors test/scoria/adoption_surface_test.exs test/scoria/terminology_contract_test.exs'` - PASS, 27 tests, 0 failures.
- `MIX_ENV=test mix test --warnings-as-errors test/scoria/semantic_fast_path_example_source_test.exs test/scoria/handoff_example_source_test.exs test/scoria/phoenix_example_source_test.exs test/scoria/support_journey_source_test.exs` - PASS, 10 tests, 0 failures.
- `MIX_ENV=test mix test --warnings-as-errors test/scoria/package_surface_test.exs test/scoria/hex_consumer_contract_test.exs test/scoria/glossary_contract_test.exs` - PASS, 22 tests, 0 failures.
- `MIX_ENV=test mix compile --warnings-as-errors` - PASS.
- `rg -n "Keystone|v2\\.0 Relay|The Four Lanes|operator evidence|operator-visible|Delegated Evidence|Scoria\\.SemanticLane,|semantic_cache: \\[lane|projected_context: %\\{" README.md docs/adoption_lanes.md docs/bounded_handoffs.md docs/phoenix_runtime_example.md docs/semantic_fast_path.md docs/operator_verification.md docs/connector_adoption.md docs/support_copilot_gallery.md lib/scoria.ex` - PASS, no matches.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `46-08-PLAN.md`; the docs now use final vocabulary, so the final drift/no-schema guards and upgrade-note closeout can build on stable public wording.

## Self-Check: PASSED

- Verified final vocabulary appears in README, stable guides, and public facade docs.
- Verified retired internal wording is absent from current adopter docs.
- Verified semantic cache/profile and scoped-context examples replaced legacy examples.
- Verified compatibility aliases remain explicit and framed as 0.1.x compatibility.
- Verified package/glossary contracts still pass after README/doc changes.

---
*Phase: 46-terminology-and-public-vocabulary-migration*
*Completed: 2026-07-09*
