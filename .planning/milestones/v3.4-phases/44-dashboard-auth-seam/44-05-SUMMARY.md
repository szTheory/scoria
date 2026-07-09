---
phase: 44-dashboard-auth-seam
plan: 05
subsystem: auth
tags: [phoenix-liveview, dashboard-auth, tenant-scope, eval, datasets, review-queue]

# Dependency graph
requires:
  - phase: 44-dashboard-auth-seam
    provides: ScoriaWeb.DashboardScope assigns from Plan 44-01
provides:
  - Tenant-scoped review queue dashboard helpers and wiring
  - Tenant-filtered eval run evidence in Eval Workbench
  - Tenant-checked Dataset Builder review and workflow promotion evidence
  - Cross-tenant quality/data dashboard proof for AUTH-03
affects: [phase-44, dashboard-liveviews, auth-seam, tenant-isolation, eval, datasets]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Dashboard LiveViews treat URL filters and IDs as hints, then reload evidence through asserted tenant scope.
    - Tenant-specific Eval context helpers preserve broad public APIs for non-dashboard callers.

key-files:
  created:
    - test/scoria_web/live/dashboard_auth_quality_data_test.exs
  modified:
    - lib/scoria/eval.ex
    - lib/scoria_web/live/review_queue_live.ex
    - lib/scoria_web/live/eval_spec_live/index.ex
    - lib/scoria_web/live/dataset_live/index.ex
    - test/scoria_web/live/review_queue_live_test.exs
    - test/scoria_web/live/eval_spec_live/index_test.exs
    - test/scoria_web/live/dataset_live/index_test.exs

key-decisions:
  - "Review Queue and Dataset Builder treat review candidate IDs as hints and reload them through Scoria.Eval.get_review_candidate_for_tenant/2."
  - "Eval Workbench keeps eval specs as global catalog metadata while listing eval runs only through Scoria.Eval.list_eval_runs_for_tenant/1."
  - "Dataset Builder validates workflow promotion run IDs through OperatorSurface.fetch_tenant_run_detail/2 before rendering promotion evidence."

patterns-established:
  - "Quality/data LiveViews consume socket.assigns.tenant_id from DashboardScope before tenant-owned evidence reads."
  - "Tenant-aware Eval helpers return empty/nil for blank tenants instead of widening queries."

requirements-completed: [AUTH-03]

# Metrics
duration: 11 min
completed: 2026-07-07
status: complete
---

# Phase 44 Plan 05: Review Queue, Eval Workbench, and Dataset Builder Tenant Evidence Summary

**Tenant-scoped quality/data dashboard evidence for review candidates, eval runs, and dataset promotion hints**

## Performance

- **Duration:** 11 min
- **Started:** 2026-07-07T16:16:28Z
- **Completed:** 2026-07-07T16:27:12Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Added focused cross-tenant LiveView tests proving Review Queue, Eval Workbench, and Dataset Builder do not render tenant B evidence under tenant A dashboard scope.
- Added dashboard-specific `Scoria.Eval` tenant helpers for review queue rows, review summaries, review candidate lookup, and eval run listing.
- Wired quality/data dashboard reads through `socket.assigns.tenant_id` from `ScoriaWeb.DashboardScope`, keeping URL params as UI hints rather than authority.
- Validated Dataset Builder review and workflow promotion deep links against the asserted tenant before rendering source evidence.

## Task Commits

Each task was committed atomically:

1. **Task 1: Prove quality/data dashboards do not render foreign tenant evidence** - `7c7aa10a` (test)
2. **Task 2: Add tenant-aware Eval read helpers** - `152f5f1e` (feat)
3. **Task 3: Wire Review Queue, Eval Workbench, and Dataset Builder to asserted scope** - `fb9f95a8` (feat)

_Note: Task 1 intentionally committed the RED proof. Task 2 and Task 3 are the GREEN implementation commits for the plan-level TDD slice._

## Files Created/Modified

- `test/scoria_web/live/dashboard_auth_quality_data_test.exs` - New cross-tenant auth proof for Review Queue, Eval Workbench, Dataset Builder review promotion, and Dataset Builder workflow promotion.
- `lib/scoria/eval.ex` - New tenant-aware dashboard helpers that fail closed for blank tenants and filter review/eval evidence before applying facets or preloads.
- `lib/scoria_web/live/review_queue_live.ex` - Review rows, summaries, and selected candidate refresh now use tenant-scoped Eval helpers.
- `lib/scoria_web/live/eval_spec_live/index.ex` - Eval specs remain global catalog rows, while eval runs are listed through tenant-scoped Eval helpers.
- `lib/scoria_web/live/dataset_live/index.ex` - Review candidate and workflow promotion params are reloaded under the asserted tenant before source evidence is shown.
- `test/scoria_web/live/review_queue_live_test.exs` - Routed existing review queue tests through explicit dashboard tenant session data.
- `test/scoria_web/live/eval_spec_live/index_test.exs` - Mounted through `scoria_dashboard("/scoria")` with explicit tenant sessions and tenant-matching eval run fixtures.
- `test/scoria_web/live/dataset_live/index_test.exs` - Mounted through explicit tenant sessions and adjusted workflow promotion fixture scope.

## Decisions Made

- Kept existing broad `Scoria.Eval` read APIs intact for non-dashboard callers and added new `*_for_tenant` helper names for dashboard evidence reads.
- Treated tenantless eval specs and dataset rows as catalog metadata only; tenant-owned linked evidence stays behind tenant-filtered helpers.
- Used `ScoriaWeb.OperatorSurface.fetch_tenant_run_detail/2` for workflow promotion hints so foreign run IDs fail as missing rather than hydrating runtime evidence globally.
- Left URL filters and deep-link IDs as closed selectors only; all tenant-owned evidence reloads through `socket.assigns.tenant_id`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The RED auth proof initially exposed a duplicate dataset fixture name while constructing isolated cross-tenant data. The fixture was made unique before the RED commit so the committed failure mode was the intended behavior gap only.
- Converting Eval Workbench tests from isolated LiveView mounts to routed `scoria_dashboard("/scoria")` mounts required importing `Phoenix.ConnTest`; this was resolved inside the planned Task 3 test wiring.

## Known Stubs

None. The pre-summary stub scan found only legitimate empty-state rendering, blank filter option values, and nil guards in the touched UI/test files.

## Threat Flags

None. The only new server-side read surfaces are the planned tenant-scoped Eval helpers, and the LiveViews now consume them before tenant-owned evidence rendering.

## Verification

- `MIX_ENV=test mix test test/scoria_web/live/dashboard_auth_quality_data_test.exs --warnings-as-errors` - RED before implementation: 3 tests, 3 expected behavior failures for foreign review, eval, and dataset evidence rendering.
- `MIX_ENV=test mix test test/scoria/eval/review_queue_test.exs test/scoria/eval/eval_run_persistence_test.exs --warnings-as-errors` - PASS after Task 2 helper implementation: 6 tests, 0 failures.
- `rg -n "list_review_queue_for_tenant|summarize_review_queue_for_tenant|get_review_candidate_for_tenant|list_eval_runs_for_tenant" lib/scoria/eval.ex` - PASS after Task 2; all four helper exports present.
- `MIX_ENV=test mix test test/scoria_web/live/dashboard_auth_quality_data_test.exs test/scoria_web/live/review_queue_live_test.exs test/scoria_web/live/eval_spec_live/index_test.exs test/scoria_web/live/dataset_live/index_test.exs --warnings-as-errors` - PASS after Task 3 and plan-level verification: 20 tests, 0 failures.
- `rg -n "list_review_queue_for_tenant|summarize_review_queue_for_tenant|get_review_candidate_for_tenant|list_eval_runs_for_tenant|socket.assigns.tenant_id" lib/scoria/eval.ex lib/scoria_web/live/review_queue_live.ex lib/scoria_web/live/eval_spec_live/index.ex lib/scoria_web/live/dataset_live/index.ex` - PASS; planned tenant helper and asserted-scope call sites present.
- `rg -n "TODO|FIXME|placeholder|coming soon|not available|=\\s*\\[\\]|=\\s*%\\{\\}|=\\s*nil|=\\s*\"\"" lib/scoria/eval.ex lib/scoria_web/live/review_queue_live.ex lib/scoria_web/live/eval_spec_live/index.ex lib/scoria_web/live/dataset_live/index.ex test/scoria_web/live/dashboard_auth_quality_data_test.exs test/scoria_web/live/review_queue_live_test.exs test/scoria_web/live/eval_spec_live/index_test.exs test/scoria_web/live/dataset_live/index_test.exs` - PASS; no blocking stubs found.

## TDD Gate Compliance

- RED gate present: `7c7aa10a`.
- GREEN gates present after RED: `152f5f1e`, `fb9f95a8`.
- Refactor gate: not needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for remaining Phase 44 dashboard slices to continue consuming `socket.assigns.tenant_id` from `ScoriaWeb.DashboardScope`. Quality/data dashboard pages now treat params and deep links as selectors, not tenant authority.

## Self-Check: PASSED

- Verified created/modified files exist: `test/scoria_web/live/dashboard_auth_quality_data_test.exs`, `lib/scoria/eval.ex`, the three planned dashboard LiveViews, their three existing LiveView test files, and this summary.
- Verified task commits exist: `7c7aa10a`, `152f5f1e`, and `fb9f95a8`.
- Verified SUMMARY frontmatter includes `status: complete` and `requirements-completed: [AUTH-03]`.

---
*Phase: 44-dashboard-auth-seam*
*Completed: 2026-07-07*
