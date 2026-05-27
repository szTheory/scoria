---
phase: 67-high-signal-warning-ratchet
plan: 00
subsystem: testing
tags: [elixir, warnings-as-errors, mix-tasks, inventory, warn-06]

requires:
  - phase: 66-baseline-expiry-and-inventory
    provides: WarningInventory capture/classify, baseline check, inventory --write artifacts
provides:
  - Scoria.WarningRatchet high_signal_wae_paths/0 code SSOT
  - mix scoria.warning_ratchet.test scoped WAE runner
  - mix scoria.warning_ratchet.check unclassified high-signal gate
  - Refreshed WARNING-INVENTORY.md with Phase 67 fixed/deferred queue
affects: [67-01, 67-02, 67-03, 67-04, 68-full-suite-warning-closure]

tech-stack:
  added: []
  patterns:
    - "Code-composed high-signal path SSOT (not JSON-derived)"
    - "Shared WarningInventory.capture_output/0 for inventory and ratchet check"

key-files:
  created:
    - lib/scoria/warning_ratchet.ex
    - lib/mix/tasks/scoria.warning_ratchet.test.ex
    - lib/mix/tasks/scoria.warning_ratchet.check.ex
    - test/scoria/warning_ratchet_test.exs
    - .planning/WARNING-INVENTORY.md
    - .planning/warning-inventory.baseline.json
  modified:
    - lib/scoria/warning_inventory.ex
    - lib/mix/tasks/scoria.warning_inventory.ex
    - docs/operator_verification.md

key-decisions:
  - "Extracted capture_output/0 to Scoria.WarningInventory for shared inventory/ratchet capture"
  - "Phase 67 fixed/deferred queue documented in WARNING-INVENTORY.md from CONTEXT D-02–D-05"

patterns-established:
  - "WARN-06 path list composed from adoption_test_files/0 + test/scoria + test/scoria_web/live globs"

requirements-completed: [WARN-06]

duration: 3min
completed: 2026-05-27
---

# Phase 67 Plan 00: Inventory Queue Refresh Summary

**WARN-06 infrastructure: WarningRatchet path SSOT, scoped ratchet Mix tasks, and committed inventory with Phase 67 fix/defer queue**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-27T18:11:30Z
- **Completed:** 2026-05-27T18:14:05Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Added `Scoria.WarningRatchet` with deterministic high-signal path list (adoption + `test/scoria` + LiveView globs)
- Shipped `mix scoria.warning_ratchet.test` and `mix scoria.warning_ratchet.check` maintainer gates
- Refreshed `.planning/warning-inventory.baseline.json` and `WARNING-INVENTORY.md` with Phase 67 fixed/deferred table
- Documented WARN-06 maintainer command chain in `docs/operator_verification.md`

## Task Commits

1. **Task 67-00-01: Implement Scoria.WarningRatchet path SSOT** - `d0a5475` (feat)
2. **Task 67-00-02: Add mix scoria.warning_ratchet.test and .check** - `60ca804` (feat)
3. **Task 67-00-03: Refresh inventory artifacts and document Phase 67 queue** - `1468642` (feat)

## Files Created/Modified

- `lib/scoria/warning_ratchet.ex` - High-signal WAE path SSOT
- `test/scoria/warning_ratchet_test.exs` - Path list contract tests
- `lib/mix/tasks/scoria.warning_ratchet.test.ex` - Scoped WAE runner
- `lib/mix/tasks/scoria.warning_ratchet.check.ex` - Unclassified compile gate for high-signal paths
- `lib/scoria/warning_inventory.ex` - Public `capture_output/0`
- `lib/mix/tasks/scoria.warning_inventory.ex` - Phase 67 queue markdown + JSON-safe row encoding
- `.planning/warning-inventory.baseline.json` - Cluster-count baseline (3 clusters)
- `.planning/WARNING-INVENTORY.md` - Ratchet queue + fixed/deferred table
- `docs/operator_verification.md` - WARN-06 maintainer subsection

## Decisions Made

- Extracted `capture_output/0` to `Scoria.WarningInventory` rather than duplicating capture logic in ratchet check
- Added `json_encode_rows/1` helper so `--write` can persist `tmp/warning-inventory/latest.json` without Jason tuple errors

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Jason encode failure on inventory --write**
- **Found during:** Task 3 (inventory refresh)
- **Issue:** `write_artifacts!/2` failed encoding rows containing tuple `dedupe_key` values
- **Fix:** Added `json_encode_rows/1` to convert atoms and tuples to JSON-safe values before writing `latest.json`
- **Files modified:** `lib/mix/tasks/scoria.warning_inventory.ex`
- **Verification:** `MIX_ENV=test mix scoria.warning_inventory --write --scope full` exits 0
- **Committed in:** `1468642` (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Required for committed inventory artifacts; no scope creep.

## Issues Encountered

None beyond the JSON encoding bug (auto-fixed above).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for plan 67-01 (`warn-05-canonical-surface-guard`)
- Wave 0 artifacts in place for downstream plans to use scoped WAE and ratchet check
- Inventory baseline shows 8 warning rows across 3 clusters pending fix in plans 67-02–67-04

## Self-Check: PASSED

- `[ -f lib/scoria/warning_ratchet.ex ]` — PASS
- `[ -f test/scoria/warning_ratchet_test.exs ]` — PASS
- `git log --oneline --grep="67-00"` — 3 commits
- `MIX_ENV=test mix test test/scoria/warning_ratchet_test.exs` — PASS (5 tests)
- `mix scoria.warning_baseline.check` — PASS
- `test -f .planning/warning-inventory.baseline.json` — PASS
- `rg -q "Phase 67 — Fixed vs Deferred" .planning/WARNING-INVENTORY.md` — PASS

---
*Phase: 67-high-signal-warning-ratchet*
*Completed: 2026-05-27*
