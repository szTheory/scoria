---
phase: 67-high-signal-warning-ratchet
plan: 02
subsystem: testing
tags: [elixir, warnings-as-errors, knowledge-migration, host-proof, adoption-lane, warn-06]

requires:
  - phase: 67-high-signal-warning-ratchet
    provides: WarningRatchet SSOT and WARN-05 regression shield from plans 67-00/67-01
provides:
  - migrate-once knowledge migrator with scoped ignore_module_conflict (D-11)
  - host-proof overlay architecture guard under priv/ (D-15, D-16)
  - adoption-lane compile warning fixes and refreshed inventory baseline
affects: [67-03, 67-04, 68-full-suite-warning-closure]

tech-stack:
  added: []
  patterns:
    - "ensure_knowledge_migrated!/0 persistent_term gate for knowledge lane setup"
    - "Scoped ignore_module_conflict only inside migrate_knowledge!/0 try/after"
    - "Host proof overlay templates live under priv/host_app_proof/overlay/test/"

key-files:
  created:
    - test/scoria/host_app_proof_architecture_test.exs
    - priv/host_app_proof/overlay/test/host_route_smoke_test.exs
    - priv/host_app_proof/overlay/test/host_runtime_smoke_test.exs
  modified:
    - lib/scoria/test_support/migrations.ex
    - test/scoria/bootstrap/migration_lane_compatibility_test.exs
    - test/support/scoria/host_app_proof/generator.ex
    - test/mix/tasks/scoria.install_route_smoke_test.exs
    - lib/scoria/warning_inventory/cluster.ex
    - .planning/warning-inventory.baseline.json
    - .planning/WARNING-INVENTORY.md

key-decisions:
  - "Knowledge migrations gated via ensure_knowledge_migrated!/0; double-call retained only in migration_lane_compatibility_test (D-11)"
  - "Host proof overlay relocated to priv/ with architecture regression test (D-15)"
  - "Adoption-lane undefined refs classified via :install_fixture_undefined_ref and :test_unused_import cluster rules where inline fix impractical"

patterns-established:
  - "Test setup calls ensure_knowledge_migrated!/0 instead of migrate_knowledge!/0 except documented compatibility test"

requirements-completed: [WARN-06]

duration: 40min
completed: 2026-05-27
---

# Phase 67 Plan 02: WARN-06 Adoption Host-Proof Slice Summary

**Knowledge redefine cluster cleared via migrate-once migrator; host-proof overlay guarded under priv/; adoption-lane compile warnings fixed with inventory refresh**

## Performance

- **Duration:** 40 min
- **Started:** 2026-05-27T18:15:10Z
- **Completed:** 2026-05-27T18:55:28Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- Implemented `ensure_knowledge_migrated!/0` with `:persistent_term` gate and scoped `ignore_module_conflict` in `migrate_knowledge!/0` (D-11, D-13)
- Added host-proof architecture guard and moved overlay smoke templates to `priv/host_app_proof/overlay/test/` (D-15)
- Cleared adoption-lane unclassified compile warnings; refreshed baseline JSON with zero `:knowledge_migration_redefine`
- `mix test.adoption --warnings-as-errors` passes (maintainer command; not CI-gated in Phase 67 per D-16)

## Task Commits

1. **Task 67-02-01: Migrate-once knowledge migrator (D-11)** - `f309297` (feat)
2. **Task 67-02-02: Host-proof overlay architecture guard** - `f00a650` (test)
3. **Task 67-02-03: Fix adoption-lane in-repo compile warnings** - `139af5f` (fix)

**Follow-up:** `3c96eae` (fix) — track `priv/host_app_proof/` overlay templates omitted from task 2 commit

**Plan metadata:** `634b4ef` (docs: complete plan)

## Files Created/Modified

- `lib/scoria/test_support/migrations.ex` - `ensure_knowledge_migrated!/0` + scoped compiler option
- `test/scoria/bootstrap/migration_lane_compatibility_test.exs` - D-11 double-call documentation
- `test/scoria/host_app_proof_architecture_test.exs` - overlay path regression guard
- `priv/host_app_proof/overlay/test/*.exs` - host proof smoke templates (priv, not test/support)
- `test/support/scoria/host_app_proof/generator.ex` - copy overlay from priv/
- `test/mix/tasks/scoria.install_route_smoke_test.exs` - purge helper + string asserts for compile cleanliness
- `lib/scoria/warning_inventory/cluster.ex` - `:test_unused_import`, `:install_fixture_undefined_ref` rules
- `.planning/warning-inventory.baseline.json` - clusters reduced to p3 debt only

## Decisions Made

- Scoped `ignore_module_conflict` never in `config/test.exs` — migrator boundary only (D-11)
- Install route smoke uses fixture purge + string assertions instead of compiling undefined PageController refs
- `:knowledge_migration_redefine` matcher tightened to knowledge_migrations paths only

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] priv/host_app_proof overlay not tracked in git**
- **Found during:** Self-check after task commits
- **Issue:** Task 2 removed `test/support/.../overlay/test/` but priv overlay files were untracked; CI would fail architecture guard
- **Fix:** Committed `priv/host_app_proof/overlay/test/*.exs`
- **Files modified:** `priv/host_app_proof/overlay/test/host_route_smoke_test.exs`, `priv/host_app_proof/overlay/test/host_runtime_smoke_test.exs`
- **Verification:** `MIX_ENV=test mix test test/scoria/host_app_proof_architecture_test.exs` exits 0
- **Committed in:** `3c96eae`

**2. [Rule 3 - Blocking] warning ratchet check failed with test/tmp pollution**
- **Found during:** Plan verification
- **Issue:** Stale `test/tmp/` entries caused inventory preflight failure and transient unclassified noise
- **Fix:** Cleaned `test/tmp/` before inventory/ratchet commands (D-27 preflight)
- **Verification:** `MIX_ENV=test mix scoria.warning_ratchet.check` exits 0 after clean tmp
- **Committed in:** n/a (operational preflight, not code change)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking preflight)
**Impact on plan:** priv/ commit required for CI truth; tmp clean is documented maintainer preflight.

## Issues Encountered

None blocking completion. Remaining p3 clusters (`test_unused_binding`, `test_dead_default_args`) deferred to plans 67-03/67-04 per inventory queue.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for plan 67-03 (`warn-06-scoria-unit-test-slice`) — `test/scoria/` p3 clusters remain in baseline
- `:knowledge_migration_redefine` at zero in committed baseline JSON
- `mix test.adoption --warnings-as-errors` green for maintainer verification (not CI policy job in 67)

## Self-Check: PASSED

- `[ -f lib/scoria/test_support/migrations.ex ]` — PASS
- `[ -f test/scoria/host_app_proof_architecture_test.exs ]` — PASS
- `git log --oneline --grep="67-02"` — 4 commits (3 tasks + priv follow-up)
- `rg -n "ensure_knowledge_migrated!" lib/scoria/test_support/migrations.ex` — PASS (def at line 34)
- `rg -n "ignore_module_conflict" config/test.exs` — PASS (no matches)
- `MIX_ENV=test mix test test/scoria/bootstrap/migration_lane_compatibility_test.exs` — PASS (2 tests)
- `MIX_ENV=test mix test test/scoria/host_app_proof_architecture_test.exs` — PASS (2 tests)
- `mix scoria.warning_baseline.check` — PASS
- `MIX_ENV=test mix scoria.warning_ratchet.check` — PASS (after clean test/tmp/)
- `.planning/warning-inventory.baseline.json` — PASS (`knowledge_migration_redefine` absent; counts 2+2 p3 only)
- `MIX_ENV=test mix test.adoption --warnings-as-errors` — PASS (77 tests)

---
*Phase: 67-high-signal-warning-ratchet*
*Completed: 2026-05-27*
