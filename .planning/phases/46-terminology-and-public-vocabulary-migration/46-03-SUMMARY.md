---
phase: 46-terminology-and-public-vocabulary-migration
plan: 03
subsystem: runtime
tags: [terminology, semantic-cache, scoped-context, compatibility, storage-guard]

requires: []
provides:
  - Scoria.SemanticCache.Profile final-vocabulary semantic cache profile surface
  - Scoria.SemanticLane 0.1.x compatibility wrapper for lane_key callers
  - semantic_cache profile option alias normalization
  - scoped_context bounded handoff input alias normalization
affects: [phase-46, runtime, semantic-cache, workflows, bounded-handoffs]

tech-stack:
  added: []
  patterns:
    - Public compatibility wrapper delegates to final-vocabulary module
    - New public option aliases normalize before existing validation and storage

key-files:
  created:
    - lib/scoria/semantic_cache/profile.ex
    - test/scoria/semantic_cache/profile_test.exs
  modified:
    - lib/scoria/semantic_lane.ex
    - lib/scoria/runtime/params.ex
    - test/scoria/runtime_test.exs

key-decisions:
  - "SemanticCache.Profile owns the final public macro and describe/1 behavior while preserving lane_key in normalized metadata and durable storage."
  - "SemanticLane remains accepted for 0.1.x callers but delegates describe/1 and macro generation through SemanticCache.Profile."
  - "scoped_context is normalized before projected_context and then passed through the existing unsafe projected-context validation."

patterns-established:
  - "Final option aliases should normalize to existing storage fields instead of introducing parallel durable keys."
  - "Compatibility wrapper macros should avoid applying duplicate behaviours with identical callbacks."

requirements-completed: [TERM-02, TERM-04]

duration: 4 min
completed: 2026-07-09
status: complete
---

# Phase 46 Plan 03: Semantic Cache Profile Summary

**Semantic cache and bounded handoff inputs now expose final vocabulary while preserving legacy aliases and stored keys.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-09T22:17:00Z
- **Completed:** 2026-07-09T22:21:00Z
- **Tasks:** 1
- **Files modified:** 5

## Accomplishments

- Added `Scoria.SemanticCache.Profile` with `cache_key:` public vocabulary and the existing `lane_key` storage/metadata contract.
- Converted `Scoria.SemanticLane` into a 0.1.x compatibility wrapper that accepts `lane_key:` and delegates `describe/1` to `SemanticCache.Profile`.
- Updated `Scoria.Runtime.Params` so `semantic_cache: [profile: Module]` normalizes before the legacy `semantic_cache: [lane: Module]` option.
- Updated bounded handoff parameter normalization so `scoped_context:` stores into the existing `projected_context` handoff field.
- Added tests proving final profile metadata, runtime semantic cache persistence, scoped context storage, and unsafe scoped-context rejection.

## Task Commits

1. **Task 1 RED: Semantic profile aliases** - `11aaf5e1` (test)
2. **Task 1 GREEN: Semantic cache profile aliases** - `adc32475` (feat)

## Files Created/Modified

- `lib/scoria/semantic_cache/profile.ex` - Canonical semantic cache profile macro and `describe/1` implementation.
- `lib/scoria/semantic_lane.ex` - Legacy compatibility wrapper for profile behavior and `lane_key:` macro input.
- `lib/scoria/runtime/params.ex` - Alias normalization for `semantic_cache: [profile: ...]` and `scoped_context:`.
- `test/scoria/semantic_cache/profile_test.exs` - Final-vocabulary profile contract and runtime metadata tests.
- `test/scoria/runtime_test.exs` - Scoped-context bounded handoff acceptance and unsafe rejection coverage.

## Decisions Made

- Kept normalized runtime semantic cache metadata as `"lane"` and `"lane_key"` so there is no storage or projection migration.
- Kept the existing error atom `:invalid_semantic_cache_lane` for invalid profiles to avoid widening public error contracts during a terminology-only phase.
- Let `scoped_context:` take precedence over `projected_context:` when both are present, matching the plan’s final-name-first normalization order.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- The first GREEN test run passed behaviorally but failed `--warnings-as-errors` because legacy lane modules had duplicate behaviours with identical callbacks. The wrapper macro now uses `SemanticCache.Profile` without adding a second behaviour annotation.

## Verification

- `MIX_ENV=test mix test --warnings-as-errors test/scoria/semantic_cache/profile_test.exs test/scoria/semantic_cache/lane_test.exs test/scoria/runtime_test.exs test/scoria/runtime/semantic_fast_path_test.exs` - PASS, 34 tests, 0 failures.
- `MIX_ENV=test mix compile --warnings-as-errors` - PASS.
- `rg -n "defmodule Scoria\\.SemanticCache\\.Profile" lib/scoria/semantic_cache/profile.ex` - PASS.
- `rg -n "Scoria\\.SemanticCache\\.Profile|defdelegate describe|cache_key" lib/scoria/semantic_lane.ex lib/scoria/runtime/params.ex` - PASS.
- `rg -n "profile|scoped_context|projected_context" lib/scoria/runtime/params.ex` - PASS.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 1 is complete. Ready for wave 2 starting at `46-04-PLAN.md`, where UI trace component vocabulary can rely on `scoped_context` and semantic cache profile aliases being available.

## Self-Check: PASSED

- Verified `Scoria.SemanticCache.Profile` exists and describes valid profiles.
- Verified `Scoria.SemanticLane` remains accepted for existing lane modules.
- Verified `profile:` and `scoped_context:` route through the existing validation paths.
- Verified task commits exist: `11aaf5e1` and `adc32475`.
- Verified focused plan tests and compile check pass with warnings as errors.

---
*Phase: 46-terminology-and-public-vocabulary-migration*
*Completed: 2026-07-09*
