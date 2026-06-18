---
phase: 33-doc-restructure-verification-copy-correction
plan: 03
subsystem: dev-harness
tags: [playwright, screenshots, e2e, mix-task, docs]

# Dependency graph
requires:
  - phase: 29-makefile-hardening
    provides: "make dev native host server on localhost:4799"
  - phase: 33-doc-restructure-verification-copy-correction
    provides: "Active docs corrected to make dev and localhost:4799/scoria"
provides:
  - "Host screenshot and e2e Mix task defaults use localhost:4799/scoria"
  - "Playwright config and direct spec fallbacks use localhost:4799/scoria"
  - "Dev seed completion copy prints the native dashboard URL"
affects: [phase-33, phase-34-docker-dx-contract, host-harness, playwright]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Host harness defaults preserve PLAYWRIGHT_BASE_URL / --url overrides while using make dev's native 4799 default"
    - "Direct Playwright spec execution remains possible through the same fallback URL"

key-files:
  created:
    - .planning/phases/33-doc-restructure-verification-copy-correction/33-03-SUMMARY.md
  modified:
    - lib/mix/tasks/scoria.ui.shots.ex
    - lib/mix/tasks/scoria.ui.e2e.ex
    - priv/repo/dev_seed.exs
    - priv/dev/shots.mjs
    - priv/dev/e2e/playwright.config.mjs
    - priv/dev/e2e/uat.spec.mjs
    - priv/dev/e2e/command_palette.spec.mjs
    - priv/dev/e2e/ia_orientation.spec.mjs
    - priv/dev/e2e/phase16_parity.spec.mjs

key-decisions:
  - "Kept PLAYWRIGHT_BASE_URL and --url as override paths; only defaults and user-facing comments changed."
  - "Did not touch generated static assets, Docker-internal service URLs, Compose ports, Traefik labels, CI ports, or config/dev.exs fallback."

patterns-established:
  - "Host harness defaults and docs align on make dev -> http://localhost:4799/scoria."
  - "Docker profile service URLs such as web:4000 stay untouched because they are container-internal."

requirements-completed: [DOCS-01]

# Metrics
duration: 14min
completed: 2026-06-18
status: complete
---

# Phase 33 Plan 03: Host Harness Defaults Summary

**Screenshot, e2e, Playwright, and seed surfaces now default to the native `make dev` dashboard at `http://localhost:4799/scoria`**

## Performance

- **Duration:** ~14 min
- **Started:** 2026-06-18T17:01:00Z
- **Completed:** 2026-06-18T17:15:52Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Updated `mix scoria.ui.shots` docs/default URL and critique path to use `http://localhost:4799/scoria`.
- Updated `mix scoria.ui.e2e` docs/default base URL and recovery copy to use `make dev` and `http://localhost:4799/scoria`.
- Updated `priv/repo/dev_seed.exs` completion output to print the native dashboard URL.
- Updated `priv/dev/shots.mjs`, Playwright config, UAT spec, and remaining direct e2e spec fallbacks to default to `localhost:4799/scoria`.
- Preserved `PLAYWRIGHT_BASE_URL` and task `--url` override behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: Correct Mix task docs/defaults and seed completion copy** - `a0efaea` (docs)
2. **Task 2: Correct Playwright entrypoint defaults and UAT prerequisite comments** - `07cbe17` (docs)
3. **Task 3: Correct remaining e2e spec base URL constants** - `4e01b86` (docs)

**Plan metadata:** committed separately with this SUMMARY.

## Files Created/Modified

- `lib/mix/tasks/scoria.ui.shots.ex` - Default URL and prerequisite copy now use native 4799.
- `lib/mix/tasks/scoria.ui.e2e.ex` - Default base URL, usage, prerequisite, and recovery copy now use native 4799.
- `priv/repo/dev_seed.exs` - Final printed dashboard URL now points at `localhost:4799/scoria`.
- `priv/dev/shots.mjs` - Usage comment and `baseUrl` default now use native 4799.
- `priv/dev/e2e/playwright.config.mjs` - Fallback baseURL and serving comment now use `make dev` / native 4799.
- `priv/dev/e2e/uat.spec.mjs` - Prerequisite comment and fallback BASE now use `make dev` / native 4799.
- `priv/dev/e2e/command_palette.spec.mjs` - Fallback BASE now uses native 4799.
- `priv/dev/e2e/ia_orientation.spec.mjs` - Fallback BASE now uses native 4799.
- `priv/dev/e2e/phase16_parity.spec.mjs` - Fallback BASE now uses native 4799.
- `.planning/phases/33-doc-restructure-verification-copy-correction/33-03-SUMMARY.md` - This completion record.

## Decisions Made

None beyond the locked Phase 33 plan. The implementation only changed user-facing copy and host-harness defaults.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. All task gates passed.

## Verification

Task 1 gate:

```bash
rg -n "http://localhost:4799/scoria|make dev" lib/mix/tasks/scoria.ui.shots.ex lib/mix/tasks/scoria.ui.e2e.ex priv/repo/dev_seed.exs
rg -n "Done\\. Open http://localhost:4799/scoria" priv/repo/dev_seed.exs
! rg -n "localhost:4000/scoria|mix phx\\.server" lib/mix/tasks/scoria.ui.shots.ex lib/mix/tasks/scoria.ui.e2e.ex priv/repo/dev_seed.exs
make -n dev | rg -n "http://localhost:4799/scoria|PORT=4799"
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/package_surface_test.exs test/scoria/support_journey_source_test.exs
```

Result: PASSED - `10 tests, 0 failures`.

Task 2 gate:

```bash
rg -n "http://localhost:4799/scoria|make dev|PLAYWRIGHT_BASE_URL" priv/dev/shots.mjs priv/dev/e2e/playwright.config.mjs priv/dev/e2e/uat.spec.mjs
! rg -n "localhost:4000/scoria|mix phx\\.server" priv/dev/shots.mjs priv/dev/e2e/playwright.config.mjs priv/dev/e2e/uat.spec.mjs
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/package_surface_test.exs test/scoria/support_journey_source_test.exs
```

Result: PASSED - `10 tests, 0 failures`.

Task 3 gate:

```bash
for f in priv/dev/e2e/command_palette.spec.mjs priv/dev/e2e/ia_orientation.spec.mjs priv/dev/e2e/phase16_parity.spec.mjs; do rg -n "process\\.env\\.PLAYWRIGHT_BASE_URL \\|\\| .http://localhost:4799/scoria." "$f" >/dev/null; done
! rg -n "localhost:4000/scoria|mix phx\\.server" priv/dev/e2e/command_palette.spec.mjs priv/dev/e2e/ia_orientation.spec.mjs priv/dev/e2e/phase16_parity.spec.mjs
! rg -n "localhost:4000/scoria|mix phx\\.server" lib/mix/tasks/scoria.ui.*.ex priv/dev priv/repo/dev_seed.exs
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/package_surface_test.exs test/scoria/support_journey_source_test.exs
```

Result: PASSED - `10 tests, 0 failures`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 1 is complete. Plan 33-04 can now sweep active planning prose against the corrected docs and harness defaults.

## Self-Check: PASSED

- `33-03-SUMMARY.md` exists.
- Task commits exist for all three `33-03` tasks.
- Host harness stale-copy sweep returns zero hits.
- Existing source-contract tests passed.

---
*Phase: 33-doc-restructure-verification-copy-correction*
*Completed: 2026-06-18*
