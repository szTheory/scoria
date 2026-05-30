---
phase: 78-hex-consumer-contract-foundation
plan: 02
subsystem: testing
tags: [hex, elixir, cache, fingerprint, unpack, exunit]

requires:
  - phase: 78-hex-consumer-contract-foundation
    plan: 01
    provides: HexConsumerContract SSOT API shell and drift guards
provides:
  - Fingerprinted unpack cache with exclusive lock and SCORIA_HEX_UNPACK_ROOT env override
  - package_surface_test hex preview via shared ensure_current_unpack_root!/0 cache
affects: [78-03, 79, 80, 82]

tech-stack:
  added: []
  patterns:
    - "Three-layer unpack cache: env short-circuit, fingerprint dir, exclusive lock build"
    - "Content-hash package_fingerprint/0 invalidates cache on file changes without version bump"

key-files:
  created: []
  modified:
    - lib/scoria/hex_consumer_contract.ex
    - test/scoria/package_surface_test.exs

key-decisions:
  - "O_EXCL lock file fallback when :file.lock/2 unavailable on OTP 28 build (no_warn_undefined + runtime guard)"
  - "package_fingerprint/0 walks directory entries in package[:files] and hashes file contents"

patterns-established:
  - "Shared cache under tmp/scoria-hex-consumer/ survives test runs — no on_exit rm_rf"
  - "Stamp file .scoria-hex-consumer.stamp validates fingerprint before cache hit"

requirements-completed: [DOCS-HEX-01]

duration: 12min
completed: 2026-05-29
---

# Phase 78 Plan 02: Fingerprinted Unpack Cache Summary

**Content-fingerprinted hex.build --unpack cache with env override and lock-protected builds — package_surface_test hex preview reuses shared contract cache**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-29T20:00:00Z
- **Completed:** 2026-05-29T20:12:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Implemented `package_fingerprint/0`, `unpack_root!/1`, and full `ensure_current_unpack_root!/0` resolver with SCORIA_HEX_UNPACK_ROOT env short-circuit, stamp-validated cache hits, and exclusive build locking
- Refactored `package_surface_test` hex preview test to call contract cache instead of per-test inline `hex.build`
- Consecutive test runs confirm cache hit path (0.7s first run → 0.05s second run)

## Task Commits

Each task was committed atomically:

1. **Task 78-02-01: Implement package_fingerprint/0, unpack_root!/1, and ensure_current_unpack_root!/0** - `7a909d8` (feat)
2. **Task 78-02-02: Refactor package_surface_test hex preview to use contract cache** - `9120def` (feat)

**Plan metadata:** pending (docs commit follows)

## Files Created/Modified

- `lib/scoria/hex_consumer_contract.ex` - Fingerprinted unpack cache with lock and env override
- `test/scoria/package_surface_test.exs` - Hex preview integration via ensure_current_unpack_root!/0

## Decisions Made

- Used `@compile {:no_warn_undefined, ...}` plus O_EXCL lock-file fallback because `:file.lock/2` is not exported on this OTP 28 build; runtime `function_exported?/3` guard preserves forward compatibility
- Directory paths in `package[:files]` are walked recursively for content hashing per D-10 discretion

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] O_EXCL lock fallback for missing :file.lock/2**
- **Found during:** Task 78-02-01 (compile verification)
- **Issue:** `MIX_ENV=test mix compile --warnings-as-errors` failed — `:file.lock/2` undefined on OTP 28 build
- **Fix:** Added `@compile {:no_warn_undefined, ...}`, O_EXCL `:exclusive` lock file open with retry, and runtime `function_exported?/3` guard before calling `:file.lock`
- **Files modified:** lib/scoria/hex_consumer_contract.ex
- **Verification:** `MIX_ENV=test mix compile --warnings-as-errors` exits 0; `rg ':file\.lock'` still matches
- **Committed in:** `7a909d8` (Task 78-02-01 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Lock semantics preserved for parallel test contention; forward-compatible when OTP exports `:file.lock/2`. No scope creep.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Verification Results

```
MIX_ENV=test mix compile --warnings-as-errors          → PASS
MIX_ENV=test mix test test/scoria/package_surface_test.exs (run 1) → PASS (0.7s, cache build)
MIX_ENV=test mix test test/scoria/package_surface_test.exs (run 2) → PASS (0.05s, cache hit)
MIX_ENV=test mix test test/scoria/hex_consumer_contract_test.exs test/scoria/package_surface_test.exs → PASS (9 tests)
```

## Self-Check: PASSED

## Next Phase Readiness

- Ready for plan 78-03 (Generator dep_mode, Runner route filter, consumer test setup_all, CI SCORIA_HEX_UNPACK_ROOT)
- `ensure_current_unpack_root!/0` ready for `host_app_consumer_proof_test` setup_all consumption

---
*Phase: 78-hex-consumer-contract-foundation*
*Completed: 2026-05-29*
