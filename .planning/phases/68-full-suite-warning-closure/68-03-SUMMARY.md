---
phase: 68-full-suite-warning-closure
plan: 03
subsystem: testing
tags: [elixir, warnings-as-errors, liveview, ci, warning-baseline, warn-07]

requires:
  - phase: 68-full-suite-warning-closure
    plan: 02
    provides: p2 host-proof verified clean, adoption/ratchet WAE green
provides:
  - Full-suite WAE green locally and in CI (WARN-07)
  - Baseline ledger Path A closeout (Resolved During v2.6)
  - CI flip from staged ratchet to mix test --warnings-as-errors
  - 68-VERIFICATION.md closeout evidence
affects:
  - Phase 69 CI Trust And Milestone Closeout
  - v2.6 milestone closeout

tech-stack:
  added: []
  patterns:
    - "render_async(view) before LiveView test teardown (orchestrator pattern)"
    - "Installer subprocess MIX_BUILD_PATH=_build/install_subprocess (not _build/test)"
    - "WarningInventory.capture_output skips nested subprocess when ExUnit is running"

key-files:
  created:
    - .planning/phases/68-full-suite-warning-closure/68-VERIFICATION.md
  modified:
    - test/scoria_web/live/workflow_live_test.exs
    - test/scoria_web/live/review_queue_live_test.exs
    - test/scoria_web/live/prompt_live/release_workbench_live_test.exs
    - lib/scoria/warning_inventory.ex
    - test/support/scoria/host_install_fixtures.ex
    - .planning/WARNING-BASELINE.md
    - .planning/warning-inventory.baseline.json
    - .github/workflows/ci.yml
    - test/scoria/ci_policy_contract_test.exs
    - docs/operator_verification.md

key-decisions:
  - "Path A baseline closeout — both Accepted rows resolved; empty inventory clusters"
  - "CI ratchet bridge removed; full mix test --warnings-as-errors is production gate"
  - "Installer subprocess builds isolated from _build/test to preserve test/support beams"

patterns-established:
  - "68-03 nested capture: parent ExUnit suite is WAE gate; inventory subprocess skipped"
  - "68-03 CI contract scopes WAE assertions to test job section (policy job also has lane WAE)"

requirements-completed: [WARN-07]

duration: 69min
completed: 2026-05-27
---

# Phase 68 Plan 03: Full-Suite WAE Flip Summary

**WARN-07 closed: CI runs `mix test --warnings-as-errors` after closeout lanes; baseline ledger empty; LiveView render_async sweep and installer build isolation made full suite green.**

## Performance

- **Duration:** 69 min
- **Started:** 2026-05-27T22:16:00Z
- **Completed:** 2026-05-27T23:25:00Z
- **Tasks:** 4
- **Files modified:** 14

## Accomplishments

- Added `render_async(view)` to workflow/replay, review queue, and release workbench LiveView tests.
- Achieved green `MIX_ENV=test mix test --warnings-as-errors` (457 tests) with `SCORIA_DB_PORT=55432`.
- Closed baseline ledger Path A: both Accepted rows → **Resolved During v2.6**; `"clusters": {}` in baseline JSON.
- Flipped CI test job from staged ratchet to full WAE; updated policy contract and operator docs.
- Created `68-VERIFICATION.md` with WARN-07 closeout evidence.

## Task Commits

Each task was committed atomically:

1. **Task 68-03-01: Bounded LiveView render_async sweep** - `a2a44c3` (test)
2. **Task 68-03-02: Full-suite WAE and compile/subprocess fixes** - `9b3d6e8` (fix)
3. **Task 68-03-03: Baseline ledger closeout and inventory --write** - `d875a5e` (docs)
4. **Task 68-03-04: CI flip to full WAE and gate contracts** - `7a3f263` (feat)

**Plan metadata:** (this commit)

## Files Created/Modified

- LiveView test files — async teardown drain via `render_async`
- `lib/scoria/warning_inventory.ex` — nested capture guard
- `test/support/scoria/host_install_fixtures.ex` — isolated subprocess build path
- `.planning/WARNING-BASELINE.md` — Resolved During v2.6 section
- `.github/workflows/ci.yml` — full WAE gate
- `68-VERIFICATION.md` — closeout evidence

## Decisions Made

- Path A success (not Path B partial): full inventory zero clusters after render_async + subprocess fix.
- Scoped CI policy contract to test job section to avoid matching policy job lane WAE string.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Installer subprocess clobbered test/support beams**
- **Found during:** Task 68-03-02 (full WAE attempt)
- **Issue:** `scoria.install_check_test` subprocesses used `MIX_BUILD_PATH=_build/test`, deleting `HostAppProof.Generator` beams mid-suite
- **Fix:** Route subprocess builds to `_build/install_subprocess`; skip nested inventory subprocess capture inside ExUnit
- **Files modified:** `host_install_fixtures.ex`, `scoria.install_test.exs`, `warning_inventory.ex`
- **Verification:** Full WAE green after fix
- **Committed in:** `9b3d6e8`

**2. [Rule 3 - Blocking] CI policy contract matched policy job WAE string**
- **Found during:** Task 68-03-04
- **Issue:** `index_of(ci_workflow, "mix test --warnings-as-errors")` matched policy job lane contract step first
- **Fix:** Assert gate order within test job section only (`run: mix test --warnings-as-errors`)
- **Files modified:** `ci_policy_contract_test.exs`
- **Verification:** `mix test test/scoria/ci_policy_contract_test.exs` passes
- **Committed in:** `7a3f263`

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Required for WARN-07 gate correctness; no scope creep beyond full-suite closeout.

## Issues Encountered

- Postgres `too_many_connections` during long local runs — cleared stale beam processes and restarted `scoria-pgvector` container.
- Full WAE ~44s locally with clean DB (inventory `--write` ~47s standalone).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 68 complete (4/4 plans). Ready for Phase 69 CI Trust And Milestone Closeout.
- CI enforces full WAE; baseline expiry pressure for 2026-06-07 cleared.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| `mix scoria.warning_baseline.check` | PASS |
| `MIX_ENV=test mix compile --warnings-as-errors` | PASS |
| `MIX_ENV=test mix test --warnings-as-errors` | PASS (457 tests) |
| `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs` | PASS |
| `rg "mix test --warnings-as-errors" .github/workflows/ci.yml` (test job) | PASS |
| `rg "scoria.warning_ratchet.test" .github/workflows/ci.yml` | PASS (no matches) |
| `68-VERIFICATION.md` contains WARN-07 | PASS |
| `WARNING-BASELINE.md` Resolved During v2.6 | PASS |
| `"clusters": {}` in baseline JSON | PASS |
| `git log --grep="68-03"` | PASS (4 task commits) |
| `68-03-SUMMARY.md` exists | PASS |

---
*Phase: 68-full-suite-warning-closure*
*Completed: 2026-05-27*
