---
phase: 43-knowledge-tenant-isolation
plan: 01
subsystem: knowledge
tags: [knowledge, tenant-isolation, scope, actor-scoped, test-lane]

# Dependency graph
requires:
  - phase: 42-eval-fails-closed
    provides: v3.4 fail-closed security posture and release-gate context
provides:
  - Canonical Scoria.Knowledge.Scope normalization and visibility helper
  - Focused tenant isolation test spine for later Phase 43 slices
  - Knowledge lane contract registration for tenant isolation proof
affects: [phase-43, knowledge-api, retrieval, citation-validation, mix-test-knowledge]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Plain-data tenant scope struct with fail-closed missing-tenant validation
    - Shared tenant/actor visibility helper usable by records and Ecto queries
    - Runtime knowledge-lane test discovery to avoid stale compile-time file lists

key-files:
  created:
    - lib/scoria/knowledge/scope.ex
    - test/scoria/knowledge/tenant_isolation_test.exs
  modified:
    - lib/mix/tasks/scoria.test.knowledge.ex
    - test/scoria/knowledge_lane_contract_test.exs

key-decisions:
  - "Scoria.Knowledge.Scope raises ArgumentError for missing, nil, empty, whitespace, or conflicting tenant scope instead of returning a miss/bypass tuple."
  - "Actor-scoped write scope requires actor_id, while read visibility with no actor remains tenant-shared only."
  - "The knowledge lane computes its test file list at runtime so newly added knowledge tests are immediately visible to the lane contract."

patterns-established:
  - "Knowledge scope normalization: callers pass explicit scope data or tenant/actor shorthand, and all downstream writes/read filters consume the normalized struct."
  - "Visibility contract: tenant-shared rows are visible within the same tenant; actor-scoped rows require same tenant and same actor."

requirements-completed: [KNOW-03, KNOW-04]

# Metrics
duration: 3 min
completed: 2026-07-07
status: complete
---

# Phase 43 Plan 01: Scope Contract and Tenant Isolation Test Spine Summary

**Fail-closed knowledge scope helper with actor-narrowed visibility and registered tenant isolation proof lane**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-07T11:46:10Z
- **Completed:** 2026-07-07T11:48:20Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `Scoria.Knowledge.Scope` with `new!/1`, `from_opts!/1`, `for_write!/1`, `put_source_attrs/2`, `put_audit_attrs/2`, and `visible_to/2`.
- Added focused tests proving missing/conflicting tenant scope raises, actor-scoped writes require an actor, and missing/different actors do not see actor-scoped rows.
- Registered `test/scoria/knowledge/tenant_isolation_test.exs` in the knowledge lane contract.
- Made `Mix.Tasks.Scoria.Test.Knowledge.knowledge_test_files/0` discover files at runtime so the lane contract reflects newly added knowledge tests without a forced rebuild.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add failing knowledge scope tests** - `8de6617a` (test)
2. **Task 1 GREEN: Add knowledge scope contract** - `068224ca` (feat)
3. **Task 2: Register tenant isolation knowledge lane** - `997c0993` (test)

_Note: Task 1 was TDD and produced RED then GREEN commits._

## Files Created/Modified

- `lib/scoria/knowledge/scope.ex` - Canonical fail-closed scope normalization and tenant/actor visibility helper.
- `test/scoria/knowledge/tenant_isolation_test.exs` - Focused test spine for Phase 43 tenant isolation assertions.
- `test/scoria/knowledge_lane_contract_test.exs` - Knowledge lane expected-file list now includes the tenant isolation test.
- `lib/mix/tasks/scoria.test.knowledge.ex` - Knowledge lane file discovery now runs at call time instead of compile time.

## Decisions Made

- `scope_kind` normalizes to the existing semantic-cache strings `"tenant_shared"` and `"actor_scoped"`.
- `visible_to/2` supports both plain records and Ecto queryables so later API/backend plans can share one predicate shape.
- Runtime knowledge test discovery is necessary for the lane contract to stay truthful during incremental local execution.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Made knowledge lane file discovery runtime-based**
- **Found during:** Task 2 (knowledge lane contract verification)
- **Issue:** `Mix.Tasks.Scoria.Test.Knowledge` captured `@knowledge_test_files` at compile time, so the newly added tenant isolation test was missing from the actual lane file list until a forced rebuild.
- **Fix:** Replaced the compile-time module attribute with a runtime `knowledge_test_files/0` function.
- **Files modified:** `lib/mix/tasks/scoria.test.knowledge.ex`
- **Verification:** `MIX_ENV=test mix test test/scoria/knowledge/tenant_isolation_test.exs test/scoria/knowledge_lane_contract_test.exs --warnings-as-errors` passed.
- **Committed in:** `997c0993`

---

**Total deviations:** 1 auto-fixed (1 blocking).
**Impact on plan:** Narrow lane-contract correctness fix; no production knowledge API behavior widened.

## Issues Encountered

- The exact plan command passes but excludes `:knowledge` tests by project default. A second run with `--include knowledge` executed the focused assertions and passed.

## Known Stubs

None.

## Verification

- `MIX_ENV=test mix test test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` — PASS (compiled cleanly; 4 knowledge tests excluded by default project filter)
- `MIX_ENV=test mix test --include knowledge test/scoria/knowledge/tenant_isolation_test.exs --warnings-as-errors` — PASS (4 tests, 0 failures)
- `MIX_ENV=test mix test test/scoria/knowledge/tenant_isolation_test.exs test/scoria/knowledge_lane_contract_test.exs --warnings-as-errors` — PASS (2 tests, 0 failures; 4 knowledge tests excluded)
- `MIX_ENV=test mix test --include knowledge test/scoria/knowledge/tenant_isolation_test.exs test/scoria/knowledge_lane_contract_test.exs --warnings-as-errors` — PASS (6 tests, 0 failures)

## TDD Gate Compliance

- RED gate present: `8de6617a` before `068224ca` for `Scoria.Knowledge.Scope`.
- GREEN gate present: `068224ca` after the failing scope test.
- Refactor gate: not needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `43-02-PLAN.md` to add tenant/actor/scope storage and schema validations using `Scoria.Knowledge.Scope` as the canonical normalization point.

## Self-Check: PASSED

- Verified created files exist: `lib/scoria/knowledge/scope.ex`, `test/scoria/knowledge/tenant_isolation_test.exs`, and this summary.
- Verified task commits exist: `8de6617a`, `068224ca`, and `997c0993`.
- Verified `test/scoria/knowledge_lane_contract_test.exs` contains `tenant_isolation_test.exs`.

---
*Phase: 43-knowledge-tenant-isolation*
*Completed: 2026-07-07*
