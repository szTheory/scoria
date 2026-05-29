---
phase: 79-tarball-consumer-overlay-proof
plan: 01
subsystem: testing
tags: [hex, tarball, host-proof, exunit, adoption]

requires:
  - phase: 78-hex-consumer-contract-foundation
    provides: HexConsumerContract SSOT, tarball dep mode in Generator, route-only consumer seam
provides:
  - Full overlay tarball consumer proof via run_full_proof!/1
  - Runner.expected_steps/1 derived step contract SSOT
  - Enriched host map (working_root, dep_mode, unpack_root)
  - @moduletag :host_proof for local iteration
affects: [79-02, 79-03, phase-80-upgrade-smoke]

tech-stack:
  added: []
  patterns:
    - "Derived step contract from host.overlay_tests sorted basenames"
    - "install ++ overlay atoms via expected_steps/1 — no hardcoded seven-tuple"

key-files:
  created: []
  modified:
    - test/support/scoria/host_app_proof/generator.ex
    - test/support/scoria/host_app_proof/runner.ex
    - test/scoria/host_app_consumer_proof_test.exs

key-decisions:
  - "Consumer proof uses run_full_proof!/1 not run_route_proof!/1 (D-30, D-33)"
  - "Step assertion derives from host.overlay_tests — handoff → route → runtime order (D-32)"
  - "No :overlay_smoke in assertion — only per-file atoms from smoke_pair!/1 flat-map (D-32)"
  - "180_000 module tag preserved; warm full overlay ~52s under D-36 p50 target (D-34, D-36)"

patterns-established:
  - "expected_steps/1 is SSOT for install ++ overlay step list shared by Runner and consumer test"
  - "mix test --only host_proof targets consumer module for fast local iteration (D-43)"

requirements-completed: [HEX-CONSUMER-01]

duration: 15min
completed: 2026-05-29
---

# Phase 79 Plan 01: Tarball Consumer Overlay Proof Summary

**Full v2.9 overlay depth on tarball dep with derived seven-step contract and @moduletag :host_proof local iteration**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-05-29T21:00:00Z
- **Completed:** 2026-05-29T21:15:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Enriched `Generator.create_host!/1` return map with `working_root`, `dep_mode`, and `unpack_root` for 79-02 diagnostics
- Added `Runner.expected_steps/1` SSOT deriving install ++ overlay atoms from sorted overlay basenames
- Switched merge-blocking consumer test to `run_full_proof!/1` with derived step assertion and `@moduletag :host_proof`

## Task Commits

Each task was committed atomically:

1. **Task 79-01-01: Enrich Generator host map with diagnostic fields** - `ba541bb` (feat)
2. **Task 79-01-02: Add Runner.expected_steps/1 derived SSOT helper** - `68b0bbe` (feat)
3. **Task 79-01-03: Switch consumer test to run_full_proof! with derived steps and :host_proof tag** - `d1d589d` (feat)

**Plan metadata:** pending (docs commit follows)

## Files Created/Modified

- `test/support/scoria/host_app_proof/generator.ex` - Host map enriched with working_root, dep_mode, unpack_root
- `test/support/scoria/host_app_proof/runner.ex` - Added expected_steps/1 SSOT helper
- `test/scoria/host_app_consumer_proof_test.exs` - Full overlay proof with derived steps and :host_proof tag

## Decisions Made

- Consumer proof exercises all three overlay smokes (handoff, route, runtime) on tarball dep — closes Phase 78 route-only seam
- Step order follows sorted filenames (handoff → route → runtime), not requirement prose order
- Warm full overlay wall time ~52s — well under D-36 p50 ≤90s target; no timeout escalation needed

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## Verification Results

```bash
MIX_ENV=test mix compile --warnings-as-errors          # PASS
MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs  # PASS (52.1s warm)
MIX_ENV=test mix test --only host_proof                # PASS (54.6s, 1 test)
MIX_ENV=test mix test test/scoria/verification_lanes_test.exs       # PASS (5 tests)
```

Derived step contract today:
`[:deps_get, :scoria_install, :ecto_create, :ecto_migrate, :host_handoff_smoke_test, :host_route_smoke_test, :host_runtime_smoke_test]`

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for 79-02 (Runner diagnostics / snapshot preserve using enriched host map)
- HEX-CONSUMER-01 ceremony deferred to 79-03 per D-45

## Self-Check: PASSED

- All acceptance criteria verified via grep and automated tests
- All plan-level verification commands green
- Key artifacts exist on disk with expected content

---
*Phase: 79-tarball-consumer-overlay-proof*
*Completed: 2026-05-29*
