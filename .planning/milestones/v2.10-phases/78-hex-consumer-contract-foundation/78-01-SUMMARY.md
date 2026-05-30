---
phase: 78-hex-consumer-contract-foundation
plan: 01
subsystem: testing
tags: [hex, elixir, exunit, drift-guards, ssot]

requires:
  - phase: 72-hex-publish-closeout
    provides: Hex 0.1.0 published, README Hex-primary dep line
provides:
  - Scoria.HexConsumerContract public lib SSOT for Hex dep snippets and tarball tuples
  - hex_consumer_contract_test.exs drift guards for version, README, tuple shapes
  - package_surface_test refactored to import contract instead of hardcoded strings
affects: [78-02, 78-03, 79, 80, 82]

tech-stack:
  added: []
  patterns:
    - "Two-surface SSOT: adopter Hex snippet vs CI tarball path tuple in one module"
    - "Public lib contract module mirroring AdopterDocContract (non-runtime)"

key-files:
  created:
    - lib/scoria/hex_consumer_contract.ex
    - test/scoria/hex_consumer_contract_test.exs
  modified:
    - test/scoria/package_surface_test.exs

key-decisions:
  - "HexConsumerContract stays separate from AdopterDocContract (D-05)"
  - "@hex_requirement explicit ~> 0.1, not auto-derived (D-02)"
  - "ensure_current_unpack_root!/0 stub raises until plan 78-02 implements cache (D-10 wave split)"

patterns-established:
  - "README active dep line guarded via hex_dep_snippet/0 byte-match after trim"
  - "Tarball tuples are two-element {:scoria, path: root} without :hex key"

requirements-completed: [DOCS-HEX-01]

duration: 8min
completed: 2026-05-29
---

# Phase 78 Plan 01: Hex Consumer Contract SSOT Summary

**Public lib HexConsumerContract with executable drift guards for version policy, README dep snippet, and tarball tuple separation — package_surface_test imports contract helpers**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-29T19:35:00Z
- **Completed:** 2026-05-29T19:43:17Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Shipped `Scoria.HexConsumerContract` as public non-runtime SSOT with adopter Hex snippet, GitHub fallback, tarball tuple builders, and compile-safe unpack stub
- Added `hex_consumer_contract_test.exs` guarding published_version, README active dep line, hex tuple shape, tarball/adopter separation, and baseline_upgrade_version hook
- Refactored `package_surface_test` Hex-primary guard to import contract helpers; removed hardcoded dep strings

## Task Commits

Each task was committed atomically:

1. **Task 78-01-01: Create Scoria.HexConsumerContract SSOT module** - `3d6a7ce` (feat)
2. **Task 78-01-02: Add hex_consumer_contract_test.exs drift guards** - `24e11c8` (test)
3. **Task 78-01-03: Refactor package_surface_test Hex-primary guard** - `d1acfee` (feat)

**Plan metadata:** pending (docs commit follows)

## Files Created/Modified

- `lib/scoria/hex_consumer_contract.ex` - Hex dep + tarball tuple SSOT; stub unpack resolver
- `test/scoria/hex_consumer_contract_test.exs` - Version and snippet drift guards
- `test/scoria/package_surface_test.exs` - README dep alignment via contract

## Decisions Made

- README line comparison trims whitespace before byte-match (README indents dep line inside code block)
- Tarball tuple test uses tuple_size == 2 and refute hex_dep_tuple equality instead of elem/2 (2-element tuple has no third element)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] README active dep line whitespace trim**
- **Found during:** Task 78-01-02 (hex_consumer_contract_test.exs)
- **Issue:** README active dep line includes leading indentation inside code block; raw equality to hex_dep_snippet/0 failed
- **Fix:** Compare String.trim(hd(active_dep_lines)) to hex_dep_snippet/0; same trim applied in package_surface_test refactor
- **Files modified:** test/scoria/hex_consumer_contract_test.exs, test/scoria/package_surface_test.exs
- **Verification:** MIX_ENV=test mix test test/scoria/hex_consumer_contract_test.exs exits 0
- **Committed in:** 24e11c8, d1acfee

**2. [Rule 1 - Bug] elem/2 raises on 2-element tarball tuple**
- **Found during:** Task 78-01-02 (tarball tuple guard)
- **Issue:** Plan's elem(tuple, 2) pattern raises ArgumentError on {:scoria, path: unpack}
- **Fix:** Assert tuple_size == 2 and refute equality with hex_dep_tuple/0 to prove no :hex key
- **Files modified:** test/scoria/hex_consumer_contract_test.exs
- **Verification:** MIX_ENV=test mix test test/scoria/hex_consumer_contract_test.exs exits 0
- **Committed in:** 24e11c8

---

**Total deviations:** 2 auto-fixed (2 bugs)
**Impact on plan:** Test ergonomics only; contract API matches plan exactly. No scope creep.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for plan 78-02 (ensure_current_unpack_root!/0 fingerprint cache + package_surface_test hex preview refactor)
- Generator dep_mode and consumer proof wiring deferred to plan 78-03 as planned

## Verification Results

```
MIX_ENV=test mix test test/scoria/hex_consumer_contract_test.exs test/scoria/package_surface_test.exs
# 9 tests, 0 failures

MIX_ENV=test mix compile --warnings-as-errors
# exits 0
```

## Self-Check: PASSED

- [x] lib/scoria/hex_consumer_contract.ex exists
- [x] test/scoria/hex_consumer_contract_test.exs exists
- [x] git log --grep="78-01" returns 3 task commits
- [x] All acceptance criteria verified
- [x] Plan-level verification commands pass

---
*Phase: 78-hex-consumer-contract-foundation*
*Completed: 2026-05-29*
