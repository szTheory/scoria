---
phase: 79-tarball-consumer-overlay-proof
plan: 02
subsystem: testing
tags: [hex, tarball, host-proof, diagnostics, snapshot, exunit]

requires:
  - phase: 79-01
    provides: enriched host map (working_root, dep_mode, unpack_root), run_full_proof!/1, expected_steps/1
provides:
  - Structured triage raise on every failed run_mix!/1 step with replay and preserve hints
  - SCORIA_PRESERVE_HOST opt-in host tree preservation in Generator cleanup
  - Workspace failure snapshot at tmp/scoria-host-proof-last-failure/ with MANIFEST.txt
affects: [79-03, phase-80-upgrade-smoke]

tech-stack:
  added: []
  patterns:
    - "triage_message/4 plain-string raise body — no custom exception module (D-39)"
    - "extract_nested_failure_line/1 surfaces first FAIL/** (` from overlay subprocess (D-39)"
    - "SCORIA_PRESERVE_HOST in ~w(1 true yes) skips on_exit rm_rf with IO.warn (D-40)"
    - "maybe_snapshot_failure!/3 replaces prior tmp/scoria-host-proof-last-failure/ on each failure (D-41)"

key-files:
  created: []
  modified:
    - test/support/scoria/host_app_proof/runner.ex
    - test/support/scoria/host_app_proof/generator.ex

key-decisions:
  - "Triage block omits SCORIA_DB_PASSWORD — host/port/username only (T-79-06)"
  - "Snapshot copy failures are non-fatal — MANIFEST records copy_note and triage still raises"
  - "File.cp_r! falls back to cp -RL on broken symlinks in generated host assets tree"

patterns-established:
  - "Failure diagnostics: triage raise → optional snapshot → re-raise with nested overlay line"
  - "SCORIA_HOST_PROOF_ROOT env overrides default @snapshot_root destination"

requirements-completed: [HEX-CONSUMER-01]

duration: 25min
completed: 2026-05-29
---

# Phase 79 Plan 02: Host Proof Failure Diagnostics Summary

**Operator-first triage raises, SCORIA_PRESERVE_HOST opt-in cleanup, and replaceable workspace failure snapshots for tarball overlay proof**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-05-29T21:00:00Z
- **Completed:** 2026-05-29T21:25:00Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Enhanced `Runner.run_mix!/1` failure path with `triage_message/4` including step, command, host paths, unpack/tarball context, overlay list, DB env (no password), replay, and preserve hint
- Added `extract_nested_failure_line/1` to prepend first FAIL or `** (` line from overlay subprocess output
- Implemented `SCORIA_PRESERVE_HOST` opt-in in `Generator.register_cleanup/2` — default cleanup-on-exit unchanged
- Added `maybe_snapshot_failure!/3` copying `working_root` to `tmp/scoria-host-proof-last-failure/host/` with `MANIFEST.txt` before re-raise

## Task Commits

Each task was committed atomically:

1. **Task 79-02-01: Implement enhanced Runner triage raise on subprocess failure** - `76975d6` (feat)
2. **Task 79-02-02: Add SCORIA_PRESERVE_HOST opt-in to Generator cleanup** - `17c6446` (feat)
3. **Task 79-02-03: Implement failure snapshot to tmp/scoria-host-proof-last-failure/** - `d855063` (feat)

**Plan metadata:** `f59133e` (docs: complete plan)

## Files Created/Modified

- `test/support/scoria/host_app_proof/runner.ex` - triage_message/4, extract_nested_failure_line/1, maybe_snapshot_failure!/3, replay_command/3
- `test/support/scoria/host_app_proof/generator.ex` - preserve_host?/0 and SCORIA_PRESERVE_HOST cleanup skip

## Decisions Made

- Triage and MANIFEST omit database password; only host/port/username surfaced (T-79-06)
- Snapshot destination workspace-relative at `tmp/scoria-host-proof-last-failure/` with optional `SCORIA_HOST_PROOF_ROOT` override
- Snapshot copy excludes `_build`, `deps`, and `node_modules` from `host.root` for triage-focused CI artifacts (2026-05-29 hygiene)
- Copy uses selective walk of `host.root` — no full-tree `cp -RL` fallback

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Snapshot copy must not block triage raise**
- **Found during:** Task 79-02-03 (failure snapshot)
- **Issue:** `File.cp_r!` raised on broken `assets/node_modules` symlinks in generated host, preventing triage raise from firing
- **Fix:** Wrapped copy in try/rescue inside `maybe_snapshot_failure!/3`; record `copy_note` in MANIFEST on failure; broadened `copy_working_root!/2` rescue to fall back to `cp -RL`
- **Files modified:** `test/support/scoria/host_app_proof/runner.ex`
- **Verification:** Induced overlay failure produced MANIFEST with `failed_step: overlay_smoke` and host directory; triage raise emitted with nested FAIL line
- **Committed in:** `d855063`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Necessary for D-39 triage path to always fire; snapshot best-effort when copy fails.

## Issues Encountered

None

## Verification Results

```bash
MIX_ENV=test mix compile --warnings-as-errors                              # PASS
MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs         # PASS (45.2s warm)
SCORIA_PRESERVE_HOST=1 MIX_ENV=test mix test --only host_proof             # PASS (56.3s, preserved host warn)
MIX_ENV=test mix test --only host_proof                                    # PASS (47.1s, no preserve warn)
MIX_ENV=test mix test.adoption                                             # PASS (50.3s, 51 tests)
# Induced overlay failure (reverted):
#   tmp/scoria-host-proof-last-failure/MANIFEST.txt — failed_step, package_fingerprint present
#   tmp/scoria-host-proof-last-failure/host/ — directory present
```

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for 79-03 — CI artifact upload on failure, VERIFICATION ceremony, optional README/operator blurb
- HEX-CONSUMER-01 milestone Complete deferred to 79-03 per D-45

## Self-Check: PASSED

- All acceptance criteria verified via grep and automated tests
- Induced failure snapshot verified manually then reverted
- All plan-level verification commands green

---
*Phase: 79-tarball-consumer-overlay-proof*
*Completed: 2026-05-29*
