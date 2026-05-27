---
phase: 68-full-suite-warning-closure
plan: 01
subsystem: testing
tags: [elixir, ci, warnings-as-errors, warning-ratchet, github-actions]

requires:
  - phase: 68-full-suite-warning-closure
    plan: 00
    provides: WarningInventory tmp hygiene, JSON encode, path-set memoization
provides:
  - CI test job runs mix scoria.warning_ratchet.test --warnings-as-errors after runtime_to_handoff
  - ci_policy_contract_test gate-order and policy-isolation assertions for ratchet WAE
  - WARN-07 staged CI documentation in operator_verification.md
affects:
  - 68-full-suite-warning-closure (plans 02–03)
  - CI high-signal WAE enforcement before full-suite flip in 68-03

tech-stack:
  added: []
  patterns:
    - "Staged ratchet WAE between closeout lanes and broad mix test (D-01, D-04)"
    - "Policy job excludes warning_ratchet.test (D-17)"
    - "Ratchet Mix task preflights compile + test/support module load"

key-files:
  created:
    - test/support/scoria/host_install_fixtures.ex
  modified:
    - .github/workflows/ci.yml
    - test/scoria/ci_policy_contract_test.exs
    - docs/operator_verification.md
    - lib/mix/tasks/scoria.warning_ratchet.test.ex
    - lib/scoria/test_support/migrations.ex

key-decisions:
  - "CI adoption-file WAE uses ratchet bridge only — no duplicate mix test.adoption --warnings-as-errors step (D-12, D-14)"
  - "Ratchet task ensures HostInstallFixtures and HostAppProof support modules before path-scoped mix test"

patterns-established:
  - "ci_policy_contract_test indexes ratchet step between runtime_to_handoff and broad mix test"
  - "ensure_knowledge_migrated!/0 re-migrates when compatibility tests drop knowledge tables"

requirements-completed: [WARN-07]

duration: 95min
completed: 2026-05-27
---

# Phase 68 Plan 01: CI Ratchet Wiring Summary

**Staged high-signal WAE gate in CI test job after runtime_to_handoff, with gate-order contracts and operator docs mapping ratchet to adoption paths — without full-suite WAE until plan 68-03.**

## Performance

- **Duration:** 95 min
- **Started:** 2026-05-27T20:30:00Z
- **Completed:** 2026-05-27T22:05:29Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Inserted `Run high-signal warning ratchet` step in `.github/workflows/ci.yml` between `mix test.runtime_to_handoff` and broad `mix test`.
- Extended `Scoria.CiPolicyContractTest` with `@ratchet_wae` placement test and policy-job isolation refutation.
- Documented WARN-07 staged CI gates in `docs/operator_verification.md` (ratchet bridge vs adoption WAE).
- Closed maintainer verification: baseline check + ratchet WAE green with `SCORIA_DB_PORT=55432`.

## Task Commits

Each task was committed atomically:

1. **Task 68-01-01: Insert staged ratchet WAE step in ci.yml test job** - `c545f92` (feat)
2. **Task 68-01-02: Extend ci_policy_contract_test for ratchet placement** - `4fba6ff` (test)
3. **Task 68-01-03: Document CI↔ratchet mapping and run staged WAE closeout** - `e76c78e` (docs)

**Plan metadata:** (included in docs commit below)

## Files Created/Modified

- `.github/workflows/ci.yml` - Ratchet WAE step in test job closeout sequence
- `test/scoria/ci_policy_contract_test.exs` - Gate-order and policy isolation contracts
- `docs/operator_verification.md` - WARN-07 staged CI subsection
- `lib/mix/tasks/scoria.warning_ratchet.test.ex` - Tmp cleanup, compile, support-module preflight
- `lib/scoria/test_support/migrations.ex` - Re-migrate knowledge when tables dropped
- `test/support/scoria/host_install_fixtures.ex` - Subprocess installer fixtures (required by high-signal install tests)

## Decisions Made

- CI enforces adoption-file warnings via `mix scoria.warning_ratchet.test --warnings-as-errors` only; behavioral lanes stay plain `mix test.adoption` / `mix test.runtime_to_handoff`.
- Local ratchet closeout uses `SCORIA_DB_PORT=55432` to match CI compile/runtime Repo config.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Track HostInstallFixtures and stabilize ratchet test preflight**
- **Found during:** Task 68-01-03 (staged WAE closeout)
- **Issue:** `test/support/scoria/host_install_fixtures.ex` was referenced by install tests but never committed; path-scoped `mix test` runs reported `HostInstallFixtures` / `Generator` modules unavailable under load.
- **Fix:** Committed fixtures module; added `cleanup_transient_tmp!/0`, `mix compile`, and `Code.ensure_compiled!/1` for support modules in `warning_ratchet.test`.
- **Files modified:** `test/support/scoria/host_install_fixtures.ex`, `lib/mix/tasks/scoria.warning_ratchet.test.ex`
- **Verification:** `SCORIA_DB_PORT=55432 MIX_ENV=test mix scoria.warning_ratchet.test --warnings-as-errors` exit 0 (428 tests)
- **Committed in:** `e76c78e`

**2. [Rule 1 - Bug] Re-run knowledge migrations after compatibility test table drops**
- **Found during:** Task 68-01-03 (ratchet WAE intermittent failures)
- **Issue:** `MigrationLaneCompatibilityTest` drops knowledge tables while `:persistent_term` cached `ensure_knowledge_migrated!/0`, causing `ai_knowledge_sources` missing errors in semantic fast-path tests.
- **Fix:** `ensure_knowledge_migrated!/0` now checks `knowledge_tables_exist?/0` before skipping migration.
- **Files modified:** `lib/scoria/test_support/migrations.ex`
- **Verification:** Full ratchet suite passes after fix
- **Committed in:** `e76c78e`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Required for green staged WAE closeout and CI parity; no scope creep beyond WARN-07 partial delivery.

## Issues Encountered

- Local ratchet verification requires `SCORIA_DB_PORT=55432` (and compile in that env) to avoid Repo compile-time vs runtime port mismatch; CI sets this in the test job `env:` block.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- CI ratchet step and contracts ready for plan 68-02 (warning debt reduction) and 68-03 (full-suite WAE flip).
- Broad `mix test` in CI remains without WAE until 68-03 per D-01 scope.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| `rg "mix scoria.warning_ratchet.test --warnings-as-errors" .github/workflows/ci.yml` (one match in test job) | PASS |
| `rg "Run high-signal warning ratchet" .github/workflows/ci.yml` | PASS |
| Ratchet after `runtime_to_handoff`, before `run: mix test` | PASS |
| Policy section excludes `scoria.warning_ratchet` | PASS |
| `rg "test job runs warning ratchet after runtime_to_handoff" test/scoria/ci_policy_contract_test.exs` | PASS |
| `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs` | PASS |
| `rg "WARN-07 CI warning gates \\(staged\\)" docs/operator_verification.md` | PASS |
| `mix scoria.warning_baseline.check` | PASS |
| `SCORIA_DB_PORT=55432 MIX_ENV=test mix scoria.warning_ratchet.test --warnings-as-errors` | PASS |
| `git log --grep="68-01"` | PASS (3 task commits) |

---
*Phase: 68-full-suite-warning-closure*
*Completed: 2026-05-27*
