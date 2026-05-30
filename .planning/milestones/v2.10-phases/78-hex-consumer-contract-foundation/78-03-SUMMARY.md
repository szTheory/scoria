---
phase: 78-hex-consumer-contract-foundation
plan: 03
subsystem: testing
tags: [hex, elixir, tarball, adoption, host-app-proof, ci]

requires:
  - phase: 78-hex-consumer-contract-foundation
    plan: 02
    provides: ensure_current_unpack_root!/0 fingerprint cache and tarball dep helpers
provides:
  - Required dep_mode (:hex_tarball | :path) on HostAppProof.Generator.create_host!/1
  - Route-only overlay filter in HostAppProof.Runner.run_route_proof!/1
  - Tarball consumer proof test with setup_all unpack root and route-only steps
  - CI SCORIA_HEX_UNPACK_ROOT reuse after release preview lane
affects: [79, 80, 81, 82]

tech-stack:
  added: []
  patterns:
    - "Explicit dep_mode on host generator — no silent repo-root path default"
    - "Route-only adoption proof in Phase 78; full overlay deferred to Phase 79 run_full_proof!/1"

key-files:
  created: []
  modified:
    - test/support/scoria/host_app_proof/generator.ex
    - test/support/scoria/host_app_proof/runner.ex
    - test/scoria/host_app_consumer_proof_test.exs
    - .github/workflows/ci-verify.yml

key-decisions:
  - "smoke_pair!/2 uses two function clauses instead of default arg referencing host (Elixir compile constraint)"
  - "Phase 78 adoption proves tarball dep + route smoke only; runtime/handoff overlays stay Phase 79"

patterns-established:
  - "Consumer test setup_all calls ensure_current_unpack_root!/0 once per module"
  - "CI test job SCORIA_HEX_UNPACK_ROOT=tmp/scoria-release-preview avoids duplicate hex.build"

requirements-completed: [HEX-CONSUMER-01, DOCS-HEX-01]

duration: 28min
completed: 2026-05-29
---

# Phase 78 Plan 03: Tarball Consumer Harness Summary

**Merge-blocking adoption proves hex.build unpack tarball dep install → migrate → route smoke — Generator requires explicit dep_mode, Runner filters route overlay, CI reuses release preview unpack root**

## Performance

- **Duration:** 28 min
- **Started:** 2026-05-29T19:45:00Z
- **Completed:** 2026-05-29T20:13:00Z
- **Tasks:** 4
- **Files modified:** 4

## Accomplishments

- HostAppProof.Generator requires explicit `:dep_mode` (`:hex_tarball` or `:path`); `:hex_tarball` injects `HexConsumerContract.tarball_dep_tuple/1` into generated host mix.exs
- Runner.run_route_proof!/1 executes only `host_route_smoke_test.exs`; run_full_proof!/1 unchanged for Phase 79 full overlay
- host_app_consumer_proof_test uses setup_all unpack root, refutes repo-root path dep, asserts tarball snippet, and verifies five-step route proof chain
- CI test job sets `SCORIA_HEX_UNPACK_ROOT: tmp/scoria-release-preview` to reuse release preview unpack tree

## Task Commits

Each task was committed atomically:

1. **Task 78-03-01: Add required dep_mode to HostAppProof.Generator** - `ff3c835` (feat)
2. **Task 78-03-02: Implement route-only filter in HostAppProof.Runner** - `82c0cd3` (feat)
3. **Task 78-03-03: Rewire host_app_consumer_proof_test for tarball route proof** - `3792e82` (test)
4. **Task 78-03-04: Wire SCORIA_HEX_UNPACK_ROOT in ci-verify.yml test job** - `57ce686` (feat)

**Plan metadata:** `5fdff81` (docs: complete plan); STATE/ROADMAP update follows

## Files Created/Modified

- `test/support/scoria/host_app_proof/generator.ex` - Required dep_mode with :hex_tarball and :path branches
- `test/support/scoria/host_app_proof/runner.ex` - Route-only overlay filter via @route_overlay_test
- `test/scoria/host_app_consumer_proof_test.exs` - Tarball adoption proof with setup_all and route-only steps
- `.github/workflows/ci-verify.yml` - SCORIA_HEX_UNPACK_ROOT env on test job

## Decisions Made

- Used two-clause `smoke_pair!/2` instead of `overlay_files \\ host.overlay_tests` default (Elixir cannot reference prior params in default expressions)
- Kept run_full_proof!/1 invoking all overlays unchanged for Phase 79 switch

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] smoke_pair!/2 default argument compile error**
- **Found during:** Task 78-03-02 (route-only filter)
- **Issue:** `overlay_files \\ host.overlay_tests` fails Elixir compile — default values cannot reference other parameters
- **Fix:** Split into `smoke_pair!(host)` delegating to `smoke_pair!(host, host.overlay_tests)` plus explicit two-arg clause
- **Files modified:** test/support/scoria/host_app_proof/runner.ex
- **Verification:** `MIX_ENV=test mix compile --warnings-as-errors` exits 0
- **Committed in:** 82c0cd3 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Minimal — same runtime behavior as planned API surface; compile-safe Elixir idiom.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 78 complete — HexConsumerContract SSOT, unpack cache, and tarball route adoption harness wired
- Phase 79 ready: switch consumer test to `run_full_proof!/1` for full overlay (runtime + handoff) from tarball dep
- HEX-CONSUMER-01 remains partial until Phase 79 full overlay proof

## Verification Results

```
MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs          → 1 test, 0 failures (56s)
MIX_ENV=test mix test test/scoria/verification_lanes_test.exs               → 5 tests, 0 failures
MIX_ENV=test mix test test/mix/tasks/test.adoption_test.exs                 → 1 test, 0 failures
MIX_ENV=test mix test.adoption                                              → 51 tests, 0 failures (68s)
MIX_ENV=dev mix scoria.release_preview && SCORIA_HEX_UNPACK_ROOT=tmp/scoria-release-preview MIX_ENV=test mix test.adoption → 51 tests, 0 failures (69s)
```

## Self-Check: PASSED

---
*Phase: 78-hex-consumer-contract-foundation*
*Completed: 2026-05-29*
