---
phase: 81-post-publish-registry-gate
plan: 01
subsystem: testing
tags: [hex, registry, semver, host-app-proof, consumer-contract]

requires:
  - phase: 78-hex-consumer-contract-foundation
    provides: HexConsumerContract SSOT and tarball dep helpers
  - phase: 80-upgrade-smoke-in-adoption-lane
    provides: Upgrade orchestration patterns and semver floor at 0.1.0
provides:
  - Exact-pinned registry dep tuple/snippet helpers separate from ~> 0.1 adopter policy
  - semver_upgrade_eligible?/1 and registry_upgrade_pair/1 for conditional upgrade legs
  - HostAppProof Generator :hex_registry dep mode with overlay_from_dep!/1 and bump_registry_dep!/2
affects: [81-02, 81-03, host_app_registry_proof, post-publish-smoke]

tech-stack:
  added: []
  patterns:
    - "Exact Hex version pins on registry attest path — never ~> 0.1 in proof (D-73, T-81-01)"
    - "Overlays copied from deps/scoria/priv/... after deps.get, not checkout (D-70)"
    - "Registry hosts start with overlay_tests: [] until overlay_from_dep!/1 runs"

key-files:
  created: []
  modified:
    - lib/scoria/hex_consumer_contract.ex
    - test/scoria/hex_consumer_contract_test.exs
    - test/support/scoria/host_app_proof/generator.ex

key-decisions:
  - "registry_upgrade_from_version/1 decrements patch segment with floor at 0.1.0 via Version.parse/1"
  - ":hex_registry create_host! skips checkout overlay copy; route+runtime only via overlay_from_dep!/1"

patterns-established:
  - "Pinned registry helpers are attest-only; hex_dep_snippet/0 (~> 0.1) unchanged for adopter docs"
  - "Generator stores hex_version on host map for Runner MANIFEST/triage (81-02)"

requirements-completed: [HEX-REGISTRY-01]

duration: 12min
completed: 2026-05-30
---

# Phase 81 Plan 01: Registry Contract + Generator Foundation Summary

**Exact-pinned HexConsumerContract registry/semver SSOT and HostAppProof Generator :hex_registry mode with dep-tree overlay copy and registry bump helpers**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-30T00:21:00Z
- **Completed:** 2026-05-30T00:33:13Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `registry_dep_tuple_pinned/1`, `registry_dep_snippet_pinned/1`, `semver_upgrade_eligible?/1`, `registry_upgrade_from_version/1`, and `registry_upgrade_pair/1` to `HexConsumerContract`
- Extended `HostAppProof.Generator` with `:hex_registry` dep mode requiring `hex_version:` opt and exact pin in mix.exs
- Implemented `overlay_from_dep!/1` copying route+runtime overlays from `deps/scoria/priv/host_app_proof/overlay/test`
- Implemented `bump_registry_dep!/2` for semver upgrade baseline/target repointing

## Task Commits

Each task was committed atomically:

1. **Task 81-01-01: Add HexConsumerContract registry and semver APIs** - `9e203e4` (feat)
2. **Task 81-01-02: Extend Generator for :hex_registry dep mode and overlay_from_dep!** - `766b884` (feat)

## Files Created/Modified

- `lib/scoria/hex_consumer_contract.ex` - Pinned registry dep helpers and semver upgrade pair resolution
- `test/scoria/hex_consumer_contract_test.exs` - Unit tests for pinned tuple, eligibility, and upgrade pair
- `test/support/scoria/host_app_proof/generator.ex` - `:hex_registry` mode, `overlay_from_dep!/1`, `bump_registry_dep!/2`

## Decisions Made

- `registry_upgrade_from_version/1` uses `Version.parse/1` patch decrement with `"0.1.0"` floor (matches D-86)
- Registry hosts defer overlay copy until after `deps.get` via `overlay_from_dep!/1` (D-70, D-74)
- Only `host_route_smoke_test.exs` and `host_runtime_smoke_test.exs` copied for registry subset (D-69)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Initial `Version.parse/1` pattern matched bare struct instead of `{:ok, version}` tuple — fixed before task commit; compile WAE caught it.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for 81-02: Runner `run_registry_proof!/1`, ExUnit `:registry_proof` module, and `mix scoria.post_publish_smoke`
- Generator APIs and contract tests provide foundation; no blockers

## Self-Check: PASSED

- `[ -f lib/scoria/hex_consumer_contract.ex ]` — PASS
- `[ -f test/support/scoria/host_app_proof/generator.ex ]` — PASS
- `git log --oneline --grep="81-01"` — 2 commits found
- `MIX_ENV=test mix test test/scoria/hex_consumer_contract_test.exs --warnings-as-errors` — 11 tests, 0 failures
- `MIX_ENV=test mix compile --warnings-as-errors` — PASS

---
*Phase: 81-post-publish-registry-gate*
*Completed: 2026-05-30*
