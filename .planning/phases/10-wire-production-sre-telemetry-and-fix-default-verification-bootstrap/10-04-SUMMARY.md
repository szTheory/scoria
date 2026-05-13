---
phase: 10
plan: 04
subsystem: test-bootstrap
tags: [sre, test-bootstrap, ci, knowledge-lane, verification]
requires:
  - phase: 10-03
    provides: default core/SRE bootstrap and explicit knowledge lane command
provides:
  - default-lane suites no longer depend on suite-local ensure helpers
  - CI contract that runs mix test plus mix test.knowledge
  - execution record for remaining out-of-scope knowledge-lane failures
affects: [11]
tech-stack:
  added: []
  patterns: [migration-truth tests, two-lane ci, explicit pgvector lane]
key-files:
  created: []
  modified: [.github/workflows/ci.yml, test/scoria/mcp/executor_test.exs, test/scoria/workflows/integration_test.exs, test/scoria/workflows/runtime_test.exs, test/scoria/sre/audit_outbox_test.exs, test/scoria/sre/incident_test.exs, test/scoria/sre/relay_test.exs, test/scoria_web/live/orchestrator_live_sre_test.exs, test/scoria_web/live/orchestrator_live_test.exs]
decisions:
  - "Accepted the implementation already present in commit 64b4a28 as the plan's product change because the owned suites and CI workflow were already moved onto the default bootstrap."
  - "Verified the default lane directly from the named backend and LiveView suites instead of reintroducing any suite-local DDL helpers."
  - "Recorded knowledge-lane failures as out-of-scope verification blockers because they originate in unowned tests outside this plan's file list."
metrics:
  duration: 17min
  completed: 2026-05-12
  tasks: 2
  files_modified: 1
---

# Phase 10 Plan 04: Default-Lane Helper Cleanup and CI Summary

**The remaining owned default-lane SRE and LiveView suites were already on the repaired shared bootstrap, and CI already encoded the intended two-lane contract in commit `64b4a28`.**

## Performance

- **Duration:** 17 min
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Confirmed the owned backend suites no longer contain local `ensure_*` schema patching and run against the shared default migrated core/SRE schema.
- Confirmed the owned LiveView suites no longer depend on local SRE bootstrap helpers and continue to exercise the operator surfaces through the default lane.
- Confirmed `.github/workflows/ci.yml` already runs the promised two lanes: ordinary `mix test` and explicit `mix test.knowledge`.

## Verification

- `MIX_ENV=test mix test test/scoria/mcp/executor_test.exs test/scoria/workflows/integration_test.exs test/scoria/workflows/runtime_test.exs test/scoria/sre/audit_outbox_test.exs test/scoria/sre/incident_test.exs test/scoria/sre/relay_test.exs --trace`
- `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_sre_test.exs test/scoria_web/live/orchestrator_live_test.exs --trace`
- `SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix scoria.pgvector.bootstrap --check`
- `SCORIA_DB_HOST=localhost SCORIA_DB_PORT=55432 SCORIA_DB_USERNAME=postgres SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.knowledge`

## Task Commits

1. **Task 1: Remove Default-Lane `ensure_*` Helpers from Backend SRE and Workflow Suites** - `64b4a28` (feat)
2. **Task 2: Remove Default-Lane LiveView Helpers and Enforce Two-Lane CI** - `64b4a28` (feat)

## Decisions Made

- Treated commit `64b4a28` as the authoritative implementation for this slice because the owned tests and CI workflow already matched the plan before execution started.
- Kept this execution pass limited to verification and summary work rather than touching unrelated files or reworking already-correct test setup.
- Used the bundled pgvector service on `localhost:55432` for the knowledge lane after recompiling for that port and restoring the `vector` extension in the recreated test database.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking Issue] Adjusted verification commands for the local Mix version**
- **Found during:** Task 1
- **Issue:** The plan's `mix test ... -x` commands are not supported by the installed Mix version.
- **Fix:** Ran the equivalent focused suites with `--trace`, which preserves explicit file targeting and produced passing default-lane evidence.
- **Files modified:** None
- **Commit:** None

### Deferred Issues

**1. Out-of-scope knowledge-lane failures remain outside the owned file set**
- `mix test.knowledge` reached the explicit lane and bootstrapped pgvector successfully, but the suite failed in unowned tests including `test/scoria/sre/parapet_translation_test.exs`, `test/scoria/knowledge/scrypath_test.exs`, and `test/scoria/knowledge/grounding_test.exs`.
- Those failures point at product code and tests outside this plan's ownership boundary, so no code edits were made in this execution pass.

## Known Stubs

None.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/10-wire-production-sre-telemetry-and-fix-default-verification-bootstrap/10-04-SUMMARY.md`
- Verified commit `64b4a28` exists in git history
