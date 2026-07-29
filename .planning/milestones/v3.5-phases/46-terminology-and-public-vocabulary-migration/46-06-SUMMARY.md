---
phase: 46-terminology-and-public-vocabulary-migration
plan: 06
subsystem: docs/package
tags: [terminology, glossary, exdoc, hex-package, release-preview, compatibility]

requires: [46-01, 46-02, 46-03, 46-04, 46-05]
provides:
  - docs/glossary.md final terminology source of truth
  - ExDoc extras exposure for docs/glossary.md
  - Hex package file exposure for docs/glossary.md
  - release-preview required path guard for docs/glossary.md
  - README docs-list link to the glossary
affects: [phase-46, docs, README, package-surface, release-preview, hex-consumer-contracts]

tech-stack:
  added: []
  patterns:
    - Glossary content is guarded by explicit Markdown contract tests
    - Package docs exposure is guarded at ExDoc, package metadata, release-preview, and Hex consumer layers

key-files:
  created:
    - docs/glossary.md
    - test/scoria/glossary_contract_test.exs
  modified:
    - README.md
    - docs/adoption_lanes.md
    - docs/operator_verification.md
    - mix.exs
    - lib/mix/tasks/scoria.release_preview.ex
    - test/scoria/adoption_surface_test.exs
    - test/scoria/package_surface_test.exs
    - test/scoria/hex_consumer_contract_test.exs
    - test/mix/tasks/scoria.release_preview_test.exs

key-decisions:
  - "docs/glossary.md is the canonical adopter-facing vocabulary reference for final Phase 46 terms and legacy mappings."
  - "Glossary compatibility aliases document accepted 0.1.x names and options without encouraging storage or schema renames."
  - "README only gained the glossary docs-list link in this plan; broader first-screen positioning remains deferred to Phase 47."
  - "ReleasePreviewTest was updated alongside the release-preview task because it pins the same explicit required path list."

patterns-established:
  - "Glossary tests assert both required final terms and legacy mappings so future docs edits cannot silently drop the terminology contract."
  - "Package-facing docs should be added to mix.exs extras, package files, release-preview paths, README, and Hex consumer contracts together."

requirements-completed: [TERM-01, TERM-02]

duration: 4 min
completed: 2026-07-09
status: complete
---

# Phase 46 Plan 06: Glossary And Package Exposure Summary

**The final terminology glossary now exists and is exposed through README, ExDoc, Hex package metadata, release preview, and Hex consumer contracts.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-09T22:32:00Z
- **Completed:** 2026-07-09T22:36:00Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Added `docs/glossary.md` with required D-03 terms: run, reviewer, trace, evidence, capability, verification suite, scoped context, semantic cache, knowledge base, grounding, and bounded handoff.
- Added legacy mappings for operator, projected context, semantic fast path, optional knowledge, adoption/capability lane, proof/verification lane, surface-sense evidence, and RAG/citation evidence.
- Documented 0.1.x compatibility aliases for `OperatorSurface`, `OperatorBroadcast`, `VerificationLanes`, `SemanticLane`, `lane:`, `lane_key`, and `projected_context:`.
- Added glossary contract tests and adoption-surface coverage for the evidence/trace boundary.
- Wired the glossary into ExDoc extras, package files, release-preview required paths, README docs list, package surface tests, and Hex consumer tests.
- Corrected the already-exposed docs drift where the default proof sentence still said "lane" after Wave 1 moved proof-command vocabulary to "verification suite."

## Task Commits

1. **Task 1 RED: Glossary contract** - `cae28de2` (test)
2. **Task 1 GREEN: Terminology glossary** - `21444903` (docs)
3. **Task 2 RED: Glossary exposure contract** - `bef14c32` (test)
4. **Task 2 GREEN: Package/docs exposure** - `f32b52f7` (feat)

## Files Created/Modified

- `docs/glossary.md` - Final terminology reference, legacy mappings, and compatibility aliases.
- `test/scoria/glossary_contract_test.exs` - Required glossary headings, terms, mappings, aliases, and evidence/trace boundary guard.
- `test/scoria/adoption_surface_test.exs` - Adoption-surface assertion that the glossary preserves final public vocabulary and evidence boundaries.
- `README.md` - Glossary link in the docs list and exact verification-suite boundary sentence.
- `docs/adoption_lanes.md` - Exact verification-suite boundary sentence updates.
- `docs/operator_verification.md` - Exact verification-suite boundary sentence update.
- `mix.exs` - `docs/glossary.md` in ExDoc extras and Hex package files.
- `lib/mix/tasks/scoria.release_preview.ex` - `docs/glossary.md` in release-preview required paths.
- `test/scoria/package_surface_test.exs` - ExDoc/package/unpacked artifact assertions for the glossary.
- `test/scoria/hex_consumer_contract_test.exs` - Hex consumer surface assertion for packaged glossary docs.
- `test/mix/tasks/scoria.release_preview_test.exs` - Explicit release-preview path-list assertion for the glossary.

## Decisions Made

- Kept the glossary as a root `docs/` page rather than moving guide folders; Phase 48 can group it later in ExDoc IA.
- Avoided the literal forbidden trace-reference storage key in the glossary text so future no-schema-rename scans remain simple.
- Left broader README and guide terminology migration for 46-07, except for the exact verification-suite boundary sentence required by current adoption-surface tests.

## Deviations from Plan

- Updated `docs/adoption_lanes.md` and `docs/operator_verification.md` to replace the exact default proof sentence from "This lane..." to "This verification suite..." because `adoption_surface_test` already reads `VerificationLanes.boundary_sentence(:adoption)` from the Wave 1 final-vocabulary wrapper.
- Updated `test/mix/tasks/scoria.release_preview_test.exs` because it pins `Mix.Tasks.Scoria.ReleasePreview.required_package_paths/0`, the same explicit path list changed by this plan.

**Total deviations:** 2 auto-fixed.
**Impact on plan:** No scope change; both fixes were required to make the planned verification truthful.

## Issues Encountered

- The first Task 1 GREEN run failed because the glossary included the exact forbidden trace-reference storage token in a negative sentence. The wording now says "trace-reference storage field" while preserving the no-rename guidance.

## Verification

- `MIX_ENV=test mix test --warnings-as-errors test/scoria/glossary_contract_test.exs test/scoria/adoption_surface_test.exs` - PASS, 22 tests, 0 failures.
- `MIX_ENV=test mix test --warnings-as-errors test/scoria/package_surface_test.exs test/scoria/hex_consumer_contract_test.exs test/mix/tasks/scoria.release_preview_test.exs` - PASS, 18 tests, 0 failures.
- `MIX_ENV=test mix test --warnings-as-errors test/scoria/glossary_contract_test.exs test/scoria/package_surface_test.exs test/scoria/adoption_surface_test.exs test/scoria/hex_consumer_contract_test.exs` - PASS, 39 tests, 0 failures.
- `MIX_ENV=test mix test --warnings-as-errors test/mix/tasks/scoria.release_preview_test.exs` - PASS, 1 test, 0 failures.
- `rg -n "# Glossary|## Core terms|## Legacy and industry equivalents|## Compatibility aliases|docs/glossary\\.md|\\[Glossary\\]\\(docs/glossary\\.md\\)" docs/glossary.md mix.exs README.md lib/mix/tasks/scoria.release_preview.ex` - PASS.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `46-07-PLAN.md`; stable docs can now link to the committed glossary while migrating README/guides to final public vocabulary.

## Self-Check: PASSED

- Verified glossary content covers all required D-03 terms and mappings.
- Verified compatibility aliases are documented without schema/storage rename.
- Verified README, ExDoc, package files, release preview, and Hex consumer tests expose `docs/glossary.md`.
- Verified the required 46-06 command passes.

---
*Phase: 46-terminology-and-public-vocabulary-migration*
*Completed: 2026-07-09*
