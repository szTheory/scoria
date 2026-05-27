---
phase: 67-high-signal-warning-ratchet
plan: 03
subsystem: testing
tags: [elixir, warnings-as-errors, warn-06, test-scoria, inventory]

requires:
  - phase: 67-high-signal-warning-ratchet
    provides: adoption-lane inventory refresh and WarningRatchet SSOT from plans 67-00/67-02
provides:
  - zero p3 clusters under test/scoria/ excluding live paths (D-02 scoped slice)
  - refreshed inventory baseline with test_dead_default_args reduced to live-only debt
affects: [67-04, 68-full-suite-warning-closure]

tech-stack:
  added: []
  patterns:
    - "Inventory-driven minimal fixes: remove dead default args rather than prefix silencing"

key-files:
  created: []
  modified:
    - test/scoria/eval/review_queue_test.exs
    - .planning/warning-inventory.baseline.json
    - .planning/WARNING-INVENTORY.md

key-decisions:
  - "Removed unused default from candidate_fixture/1 instead of _prefix silencing — all call sites pass explicit overrides"

patterns-established:
  - "test/scoria non-live p3 debt cleared via inventory row targeting before LiveView slice in 67-04"

requirements-completed: [WARN-06]

duration: 5min
completed: 2026-05-27
---

# Phase 67 Plan 03: WARN-06 Scoria Unit Test Slice Summary

**Removed dead default args from review queue unit test; test/scoria non-live p3 inventory clusters at zero with ratchet check green**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-27T18:58:00Z
- **Completed:** 2026-05-27T19:01:24Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments

- Cleared sole non-live p3 row: `:test_dead_default_args` in `test/scoria/eval/review_queue_test.exs` by making `candidate_fixture/1` require explicit overrides
- Verified zero `:test_unused_binding`, `:test_dead_default_args`, and `:unclassified_compile` rows under `test/scoria/` (excluding `scoria_web/live`)
- Refreshed `.planning/warning-inventory.baseline.json` — `test_dead_default_args` 2→1 (live-only remainder for 67-04)

## Task Commits

1. **Task 67-03-01: Inventory-driven fixes for test/scoria p3 clusters** - `6fe64b4` (fix)

## Files Created/Modified

- `test/scoria/eval/review_queue_test.exs` - removed unused `\ %{}` default from `candidate_fixture/1`
- `.planning/warning-inventory.baseline.json` - cluster counts reflect live-path p3 debt only
- `.planning/WARNING-INVENTORY.md` - regenerated inventory queue table

## Decisions Made

- Minimal fix: drop dead default parameter rather than `_overrides \\ %{}` prefix (inventory cluster proof, not compile-only silence)

## Deviations from Plan

None - plan executed exactly as written. Plan-level jq baseline-zero criteria for global cluster counts intentionally not met — remaining p3 rows are exclusively in `test/scoria_web/live/` per 67-04 scope boundary.

## Issues Encountered

- Full `test/scoria/**/*_test.exs` WAE run hit 23 pgvector-related failures locally (environment); compile-warning inventory and ratchet check are the authoritative gates for this plan slice
- `mix scoria.warning_inventory --format json` stdout path still raises on tuple rows (pre-existing); table output and `--write` artifacts used instead

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for plan 67-04 — three live-path p3 rows remain (`review_queue_live_test.exs` dead defaults; `release_workbench_live_test.exs` unused bindings)
- `MIX_ENV=test mix scoria.warning_ratchet.check` green
- `mix scoria.warning_baseline.check` green

## Self-Check: PASSED

- `[ -f test/scoria/eval/review_queue_test.exs ]` — PASS
- `git log --oneline --grep="67-03"` — PASS (`6fe64b4`)
- `MIX_ENV=test mix scoria.warning_inventory --scope full | rg '^test_(unused_binding|dead_default_args) test/scoria/' | rg -v scoria_web/live` — PASS (zero rows)
- `MIX_ENV=test mix scoria.warning_ratchet.check` — PASS
- `mix scoria.warning_baseline.check` — PASS
- `MIX_ENV=test mix test --warnings-as-errors test/scoria/eval/review_queue_test.exs` — PASS (2 tests)
- `.planning/warning-inventory.baseline.json` — PASS (`test_dead_default_args`: 1 live-only; no `test/scoria/` rows in inventory output)

---
*Phase: 67-high-signal-warning-ratchet*
*Completed: 2026-05-27*
