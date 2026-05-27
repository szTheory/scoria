---
phase: 52-runtime-to-handoff-example-contract
plan: 02
subsystem: docs
tags: [runtime, handoff, phoenix, projected-context, exunit]

requires:
  - phase: 52-runtime-to-handoff-example-contract
    provides: Phase 52 example shape decision and public facade boundary
provides:
  - DB-backed public-facade runtime-to-handoff tests
  - Phoenix runtime guide branch from Scoria.start_run/2 to Scoria.start_handoff_run/3
  - Source-pinned fragments for host-owned escalation and run_id/session_id boundary
affects: [phase-52, phase-53, runtime-to-handoff-example, bounded-handoffs]

tech-stack:
  added: []
  patterns:
    - Public Scoria facade first for adopter examples
    - Host-owned escalation branch with bounded projected_context
    - Curated delegated readback through Scoria.get_run_detail(handoff_run.run_id)

key-files:
  created:
    - .planning/phases/52-runtime-to-handoff-example-contract/52-02-SUMMARY.md
  modified:
    - docs/phoenix_runtime_example.md
    - test/support/scoria/adoption_example.ex
    - test/scoria/runtime_test.exs

key-decisions:
  - "The Phoenix runtime example now starts a default run before bounded review handoff."
  - "The host app owns the escalation predicate; Scoria receives only the explicit handoff contract."
  - "The handoff run is persisted and inspected through handoff_run.run_id, not the host session_id."

patterns-established:
  - "Runtime-to-handoff docs should show Scoria.start_run/2 before Scoria.start_handoff_run/3."
  - "Projected-context safety tests should assert rejected unsafe host session state leaves no durable session run."

requirements-completed: [EXMP-01, EXMP-02]

duration: 3m05s
completed: 2026-05-27
---

# Phase 52 Plan 02: Runtime-to-Handoff Example Path Summary

**Phoenix runtime guide and DB-backed tests now prove the public-facade path from a default Scoria run into a bounded handoff with curated delegated readback.**

## Performance

- **Duration:** 3m05s
- **Started:** 2026-05-27T06:49:30Z
- **Completed:** 2026-05-27T06:52:35Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added DB-backed public `Scoria` facade tests for starting a default run before a bounded handoff and reading delegated evidence through `Scoria.get_run_detail(handoff_run.run_id)`.
- Added rejection coverage proving unsafe host `session` state in `projected_context` returns `{:error, :unsafe_projected_context}` and leaves no durable run for that session.
- Replaced the Phoenix runtime guide's bounded handoff section with a cohesive host-owned escalation branch and pinned the new fragments through the source-alignment test fixture.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add DB-backed runtime-to-handoff behavior tests** - `e97173f` (test)
2. **Task 2: Update the Phoenix runtime guide with a cohesive escalation branch** - `1ef92a9` (docs)
3. **Task 3: Run the phase-relevant verification command or record the PostgreSQL blocker** - `f6feb02` (test, empty verification ledger commit)

**Plan metadata:** pending final docs commit.

## Files Created/Modified

- `test/scoria/runtime_test.exs` - Adds public-facade DB-backed runtime-to-handoff and unsafe projected-context rejection tests.
- `docs/phoenix_runtime_example.md` - Replaces the bounded handoff section with a runtime-first, host-owned escalation branch.
- `test/support/scoria/adoption_example.ex` - Pins new Phoenix runtime guide fragments for source-alignment coverage.
- `.planning/phases/52-runtime-to-handoff-example-contract/52-02-SUMMARY.md` - Records execution, verification, and closeout state.

## Decisions Made

- Kept the adopter-facing path on the existing `Scoria` public facade; no new runtime API was needed.
- Kept `session_id` as host continuity and `run_id` as the exact Scoria execution handle in both docs and tests.
- Recorded Task 3 as an empty commit because it was verification-only and the plan requires per-task commits.

## Deviations from Plan

### Auto-fixed Issues

None.

### TDD Gate Compliance

Task 1 was marked `tdd="true"`, but the RED test command passed immediately after adding the planned tests because the runtime implementation already supported the behavior from prior phases. I did not fabricate a failing assertion. The test-only proof was committed in `e97173f`, and the summary records the TDD RED variance truthfully.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change. The only variance is that Task 1 validated pre-existing implementation rather than driving new implementation.

## Issues Encountered

- Task 1 RED phase did not fail: `MIX_ENV=test mix test test/scoria/runtime_test.exs` passed with PostgreSQL reachable, showing the behavior already existed behind the public facade.
- No PostgreSQL blocker occurred. The full validation command passed, so no fallback command was needed.

## Verification

- Task 1 acceptance greps for the two new test names, `Scoria.start_run(identity, root_role_id: "executor")`, `Scoria.start_handoff_run(identity, "critic"`, and `started.run_id != handoff_run.run_id` - passed.
- Task 1 command `MIX_ENV=test mix test test/scoria/runtime_test.exs` - passed, 18 tests, 0 failures. `runtime_test.exs` passed with PostgreSQL reachable.
- Post-Task 1 sampling command `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs` - passed, 9 tests, 0 failures.
- Task 2 acceptance greps for the host-owned escalation wording, `put_session(conn, :last_scoria_handoff_run_id, handoff_run.run_id)`, `Scoria.get_run_detail(handoff_run.run_id)`, `started.run_id != handoff_run.run_id`, and no `Scoria.Workflows` in `docs/phoenix_runtime_example.md` - passed.
- Task 2 command `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/phoenix_example_source_test.exs test/scoria/handoff_example_source_test.exs` - passed, 10 tests, 0 failures.
- Post-Task 2 sampling command `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs` - passed, 9 tests, 0 failures.
- Plan-level command `MIX_ENV=test mix test test/scoria/runtime_test.exs test/scoria/adoption_surface_test.exs test/scoria/handoff_example_source_test.exs test/scoria/phoenix_example_source_test.exs` - passed, 28 tests, 0 failures. `runtime_test.exs` passed.

## Known Stubs

None. Stub-pattern scan only found existing test assertions for empty lists and nil checks; none are UI-rendered placeholder data or unresolved TODO/FIXME markers introduced by this plan.

## Threat Flags

None. The changed files exercise the planned trust boundaries for Phoenix host escalation, bounded projected context, and curated delegated readback without adding new endpoints, auth paths, file access patterns, or schema changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 52-03 can build on a verified runtime-to-handoff example: docs and tests now show the host-owned escalation predicate, bounded `projected_context`, distinct default and handoff `run_id` values, and delegated readback through `Scoria.get_run_detail(handoff_run.run_id)`.

---
*Phase: 52-runtime-to-handoff-example-contract*
*Completed: 2026-05-27*

## Self-Check: PASSED

- Found `docs/phoenix_runtime_example.md`.
- Found `test/support/scoria/adoption_example.ex`.
- Found `test/scoria/runtime_test.exs`.
- Found `.planning/phases/52-runtime-to-handoff-example-contract/52-02-SUMMARY.md`.
- Found task commit `e97173f`.
- Found task commit `1ef92a9`.
- Found task commit `f6feb02`.
