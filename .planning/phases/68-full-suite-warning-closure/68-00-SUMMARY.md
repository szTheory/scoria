---
phase: 68-full-suite-warning-closure
plan: 00
subsystem: testing
tags: [elixir, mix, warnings, jason, persistent_term, maintainer-tools]

requires:
  - phase: 67-high-signal-warning-ratchet
    provides: WarningInventory capture, WarningRatchet SSOT, ratchet.check task
provides:
  - Shared test/tmp preflight and post-capture cleanup on WarningInventory
  - JSON stdout encoding aligned with artifact write path
  - Memoized high-signal path set for WARN-06 membership checks
affects:
  - 68-full-suite-warning-closure (plans 01–03)
  - CI warning ratchet wiring
  - maintainer ratchet→inventory workflow

tech-stack:
  added: []
  patterns:
    - "Public ensure_clean_tmp!/0 + cleanup_transient_tmp!/0 on WarningInventory"
    - "try/after cleanup on ratchet.check capture"
    - "persistent_term path-set cache keyed by cwd"

key-files:
  created:
    - test/scoria/warning_inventory/tmp_preflight_test.exs
    - test/scoria/warning_inventory/json_encode_test.exs
  modified:
    - lib/scoria/warning_inventory.ex
    - lib/mix/tasks/scoria.warning_inventory.ex
    - lib/mix/tasks/scoria.warning_ratchet.check.ex
    - lib/scoria/warning_ratchet.ex
    - test/scoria/warning_ratchet_test.exs
    - docs/operator_verification.md

key-decisions:
  - "Tmp hygiene lives on WarningInventory as public functions so inventory and ratchet.check share one preflight contract"
  - "Ratchet capture wraps try/after cleanup so full-suite capture cannot leave installer fixture dirs blocking inventory"
  - "JSON --format uses json_encode_rows/1 (same as --write artifacts) to serialize tuple dedupe_key safely"

patterns-established:
  - "Maintainer ratchet.check → inventory chain works without manual rm between commands when ratchet.check ran first"
  - "High-signal path membership uses cwd-keyed persistent_term cache to avoid per-row wildcard rescans"

requirements-completed: [WARN-07]

duration: 50min
completed: 2026-05-27
---

# Phase 68 Plan 00: Warning hygiene blockers Summary

**Shared test/tmp preflight and post-capture cleanup for ratchet.check, unified JSON inventory encoding for tuple dedupe_key rows, and cwd-memoized high-signal path membership.**

## Performance

- **Duration:** 50 min
- **Started:** 2026-05-27T19:38:00Z
- **Completed:** 2026-05-27T19:54:19Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Extracted `ensure_clean_tmp!/0` and `cleanup_transient_tmp!/0` to `Scoria.WarningInventory`; inventory preflight and `warning_ratchet.check` share them with try/after cleanup after capture.
- Fixed `--format json` to route rows through `json_encode_rows/1` so tuple `dedupe_key` values encode as lists; added contract tests for fixture classification and task stdout.
- Memoized expanded WARN-06 path set in `:persistent_term` keyed by `File.cwd!()`; updated operator docs for automatic tmp hygiene after ratchet.check.

## Task Commits

Each task was committed atomically:

1. **Task 68-00-01: Extract shared test/tmp preflight and post-capture cleanup (WR-01)** - `cf977cf` (feat)
2. **Task 68-00-02: Unify JSON encode path for --format json (WR-02)** - `f1a0b15` (fix)
3. **Task 68-00-03: Optional path-set memoization (IN-01) and hygiene closeout** - `c1634da` (feat)

**Plan metadata:** `e844a3c` (docs)

## Files Created/Modified

- `lib/scoria/warning_inventory.ex` - Public tmp preflight/cleanup helpers
- `lib/mix/tasks/scoria.warning_inventory.ex` - Delegates preflight; JSON render uses `json_encode_rows/1`
- `lib/mix/tasks/scoria.warning_ratchet.check.ex` - Preflight before capture; cleanup in `after`
- `lib/scoria/warning_ratchet.ex` - `persistent_term` path-set memoization
- `test/scoria/warning_inventory/tmp_preflight_test.exs` - WR-01 contract and ratchet→inventory integration
- `test/scoria/warning_inventory/json_encode_test.exs` - WR-02 JSON encode contract
- `test/scoria/warning_ratchet_test.exs` - Explicit verification_lanes path assertion
- `docs/operator_verification.md` - WARN-06 tmp hygiene operator notes

## Decisions Made

None beyond plan — followed specified extraction, JSON path unification, and IN-01 memoization.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Initial `tmp_preflight_test` used `Path.join/3` (undefined in Elixir), which produced an unclassified compile warning in the ratchet integration test until fixed to two-argument `Path.join/2`.
- `rm -rf test/tmp/*` fails under zsh when the directory is empty; closeout used `find test/tmp -mindepth 1 -delete` instead (equivalent hygiene).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- WR-01 and WR-02 blockers from 67-REVIEW are remediated; maintainer `warning_ratchet.check` → `warning_inventory` chain verified without manual tmp cleanup.
- Ready for plan 68-01 (CI ratchet wiring and full-suite WAE work).

## Self-Check

**PASSED**

| Check | Result |
|-------|--------|
| `def ensure_clean_tmp!` / `def cleanup_transient_tmp!` in warning_inventory.ex | PASS |
| ratchet.check references ensure/cleanup | PASS |
| JSON render uses `json_encode_rows(rows)` | PASS |
| `persistent_term` in warning_ratchet.ex | PASS |
| operator_verification mentions ratchet tmp hygiene | PASS |
| `mix scoria.warning_baseline.check` | PASS (exit 0) |
| `MIX_ENV=test mix scoria.warning_ratchet.check` on clean tmp | PASS (exit 0) |
| `MIX_ENV=test mix scoria.warning_inventory --format table --quiet` after ratchet | PASS (exit 0) |
| `git log --grep="68-00"` | PASS (3 task commits) |
| Key files `tmp_preflight_test.exs`, `json_encode_test.exs` exist | PASS |

---
*Phase: 68-full-suite-warning-closure*
*Completed: 2026-05-27*
