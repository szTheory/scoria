---
phase: 44-dashboard-auth-seam
plan: 06
subsystem: auth
tags: [phoenix-liveview, dashboard-auth, tenant-scope, prompt-release, tdd]

# Dependency graph
requires:
  - phase: 44-dashboard-auth-seam
    plan: 01
    provides: DashboardScope assigns and scoria_dashboard on_mount hook chain
provides:
  - Tenant-scoped prompt release eval-run evidence
  - Tenant-scoped prompt release approval lookup and request context
  - Cross-tenant prompt release dashboard auth regression tests
affects: [phase-44, prompt-release-workbench, dashboard-liveviews, auth-seam]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Prompt templates remain global catalog metadata while release evidence is tenant-owned.
    - Prompt release workbench reads tenant and actor from DashboardScope assigns only.

key-files:
  created:
    - test/scoria_web/live/dashboard_auth_prompts_test.exs
  modified:
    - lib/scoria_web/live/prompt_live/release_workbench_live.ex
    - lib/scoria/workflows/prompt_release.ex
    - test/scoria_web/live/prompt_live_test.exs
    - test/scoria_web/live/prompt_live/release_workbench_live_test.exs

key-decisions:
  - "PromptTemplate reads stay global catalog metadata; EvalRun and Approval evidence are tenant-filtered by DashboardScope tenant."
  - "Prompt release workflow requests now require explicit tenant context instead of creating approval runs under a hardcoded system tenant."
  - "The plan's stale prompt index test path maps to the current test/scoria_web/live/prompt_live_test.exs file."

patterns-established:
  - "ReleaseWorkbenchLive tenant helpers prefer :scoria_scope and fall back only to already-assigned :tenant_id/:actor_id, never session/query/default values."
  - "Prompt release approval workflow creation requires tenant_id in attrs so write-side evidence matches dashboard scope."

requirements-completed: [AUTH-03]

# Metrics
duration: 8 min
completed: 2026-07-07
status: complete
---

# Phase 44 Plan 06: Prompt Release Scope Summary

**Prompt release workbench now filters eval and approval evidence by host-asserted dashboard tenant while keeping prompt templates as global catalog metadata**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-07T16:31:29Z
- **Completed:** 2026-07-07T16:39:26Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added cross-tenant prompt auth tests proving tenant B eval runs and pending approvals do not render under tenant A scope.
- Refactored `ReleaseWorkbenchLive` to read tenant/actor from DashboardScope assigns and to tenant-filter eval run and pending approval queries.
- Changed prompt release workflow creation to require explicit tenant context, so release request approvals are written under the asserted dashboard tenant.
- Refreshed prompt index and release workbench tests to mount through `scoria_dashboard("/scoria")` with explicit tenant/actor scope.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Prove prompt release evidence is tenant-scoped** - `4be7ccdd` (test)
2. **Task 2 GREEN: Wire prompt LiveViews to dashboard scope** - `a235e3cf` (feat)
3. **Task 3: Refresh prompt tests for explicit scope** - `73a5ab8e` (test)

_Note: Task 1/2 followed the TDD RED then GREEN gate. No refactor commit was needed._

## Files Created/Modified

- `test/scoria_web/live/dashboard_auth_prompts_test.exs` - New cross-tenant prompt index/release workbench proof, including release request tenant/actor assertions.
- `lib/scoria_web/live/prompt_live/release_workbench_live.ex` - Reads DashboardScope tenant/actor assigns, filters eval and approval evidence by tenant, and passes tenant into release requests.
- `lib/scoria/workflows/prompt_release.ex` - Requires explicit `tenant_id` for prompt release workflow creation instead of hardcoding `"system"`.
- `test/scoria_web/live/prompt_live_test.exs` - Routes prompt index tests through `scoria_dashboard` with explicit session scope.
- `test/scoria_web/live/prompt_live/release_workbench_live_test.exs` - Seeds tenant-scoped eval runs and release approvals for the scoped workbench behavior.

## Decisions Made

- Prompt templates remain a global catalog: `PromptLive.Index` did not need source changes because it does not use prompt IDs or query params as tenant authority.
- Prompt release evidence is tenant-owned: `EvalRun` and `Approval` lookups now include the asserted tenant where those schemas carry `tenant_id`.
- Release request writes must carry the same scope as reads, so `PromptRelease.start_release_workflow/3` requires tenant context.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected stale prompt index test path**
- **Found during:** Task 1 read-first / Task 3 verification
- **Issue:** The plan referenced `test/scoria_web/live/prompt_live/index_test.exs`, but current HEAD has `test/scoria_web/live/prompt_live_test.exs`.
- **Fix:** Used and updated the current prompt index test file.
- **Files modified:** `test/scoria_web/live/prompt_live_test.exs`
- **Verification:** Focused prompt LiveView suite passed with the corrected path.
- **Committed in:** `73a5ab8e`

**2. [Rule 2 - Missing Critical] Required explicit tenant for prompt release workflow creation**
- **Found during:** Task 2
- **Issue:** `PromptRelease.start_release_workflow/2` created prompt release approval runs with hardcoded `tenant_id: "system"`, which would keep release request writes outside the asserted dashboard tenant.
- **Fix:** Replaced it with `start_release_workflow/3` requiring `tenant_id`, and passed `socket.assigns.tenant_id` from `ReleaseWorkbenchLive`.
- **Files modified:** `lib/scoria/workflows/prompt_release.ex`, `lib/scoria_web/live/prompt_live/release_workbench_live.ex`, `test/scoria_web/live/prompt_live/release_workbench_live_test.exs`
- **Verification:** New prompt auth test asserts release request approvals persist assigned tenant and actor.
- **Committed in:** `a235e3cf`

---

**Total deviations:** 2 auto-fixed (Rule 2: 1, Rule 3: 1)
**Impact on plan:** Both deviations were required to complete AUTH-03 safely. No unrelated scope was changed.

## Issues Encountered

- The plan-level test command used the stale prompt index path. Verification used the current `test/scoria_web/live/prompt_live_test.exs` path and documented the path correction above.
- Focused test runs emitted verbose Ecto debug output. The final test commands exited successfully.

## Known Stubs

None. The scan found only required generic dashboard-unavailable copy in tests and a direct-mount test `session = %{}` paired with explicit `scoria_scope` assigns.

## Verification

- `MIX_ENV=test mix test test/scoria_web/live/dashboard_auth_prompts_test.exs --warnings-as-errors` - RED before implementation: 5 tests, 2 expected failures proving unscoped eval/action context behavior.
- `MIX_ENV=test mix test test/scoria_web/live/dashboard_auth_prompts_test.exs test/scoria_web/live/prompt_live_test.exs test/scoria_web/live/prompt_live/release_workbench_live_test.exs --warnings-as-errors` - PASS after Task 2: 15 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria_web/live/prompt_live_test.exs test/scoria_web/live/prompt_live/release_workbench_live_test.exs test/scoria_web/live/dashboard_auth_prompts_test.exs --warnings-as-errors` - PASS after Task 3: 15 tests, 0 failures.
- `MIX_ENV=test mix test test/scoria_web/live/dashboard_auth_prompts_test.exs test/scoria_web/live/prompt_live_test.exs test/scoria_web/live/prompt_live/release_workbench_live_test.exs --warnings-as-errors` - PASS plan-level proof: 15 tests, 0 failures.
- `rg -n "socket.assigns.tenant_id|scoria_scope|tenant_id" lib/scoria_web/live/prompt_live/index.ex lib/scoria_web/live/prompt_live/release_workbench_live.ex` - PASS; source scan shows scoped tenant reads and tenant-qualified evidence queries in `ReleaseWorkbenchLive`.
- `rg -n "session\\[\"tenant_id\"\\]|session\\[\"actor_id\"\\]|operator-fallback|\\|\\| \"default\"|tenant_id: \"system\"|params\\[\"tenant" lib/scoria_web/live/prompt_live/release_workbench_live.ex lib/scoria_web/live/prompt_live/index.ex lib/scoria/workflows/prompt_release.ex` - PASS; no legacy fallback patterns remain in the prompt release surface.

## TDD Gate Compliance

- RED gate present: `4be7ccdd`.
- GREEN gate present after RED: `a235e3cf`.
- Refactor gate: not needed.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for remaining Phase 44 dashboard surfaces and source guards to consume this pattern: catalog reads may remain global only when the data is non-tenant metadata, while all tenant-owned evidence must be validated through DashboardScope tenant assigns.

## Self-Check: PASSED

- Verified key files exist: `test/scoria_web/live/dashboard_auth_prompts_test.exs`, `lib/scoria_web/live/prompt_live/release_workbench_live.ex`, `lib/scoria/workflows/prompt_release.ex`, `test/scoria_web/live/prompt_live_test.exs`, `test/scoria_web/live/prompt_live/release_workbench_live_test.exs`, and this summary.
- Verified task commits exist: `4be7ccdd`, `a235e3cf`, and `73a5ab8e`.
- Verified SUMMARY frontmatter includes `status: complete` and `requirements-completed: [AUTH-03]`.

---
*Phase: 44-dashboard-auth-seam*
*Completed: 2026-07-07*
