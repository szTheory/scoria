---
phase: 50-release-readiness-and-0-1-3-cut
plan: 07
subsystem: testing
tags: [ci-verify-lane, tenant-scoping, liveview, phoenix, dashboard-scope]

# Dependency graph
requires:
  - phase: 50-release-readiness-and-0-1-3-cut (plan 02)
    provides: "REL-02 arity-3 tenant-scoped start_release_workflow contract — same tenant-scoping shape repaired here in test fixtures"
provides:
  - "Bucket C of the REL-04 CI gap inventory closed: seeded-run rendered contracts and shared notebook/incident rendered contracts all green"
affects: [50-08, 50-09, 50-10, 50-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Tenant-scoped test fixtures: the conn session tenant_id and the seeded run's tenant_id must match for ScoriaWeb.DashboardScope-mounted LiveViews to resolve the run (ReviewerSurface.fetch_tenant_run_detail/2 does strict tenant_id equality)"
    - "Rendered-contract test repair: repoint stale assertions to the current SSOT source (confirmed via git blame/grep) instead of weakening or deleting them"

key-files:
  created: []
  modified:
    - test/scoria/runtime_integration_test.exs
    - test/scoria/workflows/integration_test.exs
    - test/scoria_web/components/memory_notebook_component_test.exs
    - test/scoria_web/live/incidents_live_test.exs

key-decisions:
  - "Fixed the tenant_id seed/scope mismatch at its root: made the seeded run's tenant_id and the mounting conn session's tenant_id consistent in both integration tests, rather than changing the LiveView's tenant-lookup logic or loosening the rendered assertions"
  - "Repointed memory_notebook_component_test.exs's delegated-primitive adapter check from delegated_evidence_component.ex (a Phase 48 legacy 0.1.x compatibility wrapper) to delegated_trace_component.ex, the canonical module that now owns the shared notebook primitives"
  - "Repointed incidents_live_test.exs's 'Trace-first incident evidence' assertions (both the positive detail-page assertion and the negative index-page refute) to 'Trace-first incident review' — confirmed via git log -p on incident_evidence_component.ex that commit 59190886 (Phase 46-05) deliberately renamed this heading"

requirements-completed: []

coverage:
  - id: D1
    description: "Seeded-run operator workflow LiveView renders the seeded run (not 'Workflow run not found') under a consistent tenant scope"
    requirement: "REL-04"
    verification:
      - kind: integration
        ref: "test/scoria/runtime_integration_test.exs#operator-visible workflow page stays aligned with the public runtime contract"
        status: pass
      - kind: integration
        ref: "test/scoria/workflows/integration_test.exs#operator-visible LiveView state matches the durable recovery path"
        status: pass
    human_judgment: false
  - id: D2
    description: "Shared notebook-primitive contract check targets the canonical delegated-trace module instead of the legacy compatibility wrapper"
    requirement: "REL-04"
    verification:
      - kind: unit
        ref: "test/scoria_web/components/memory_notebook_component_test.exs#retrieval, delegated, and memory adapters use shared notebook primitives"
        status: pass
    human_judgment: false
  - id: D3
    description: "Incident detail rendered-evidence assertion matches the current (Phase 46-05 renamed) heading copy"
    requirement: "REL-04"
    verification:
      - kind: integration
        ref: "test/scoria_web/live/incidents_live_test.exs#incident detail route renders evidence for the chosen incident"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-11
status: complete
---

# Phase 50 Plan 07: Bucket C CI gap closure — seeded-run tenant scope and rendered-contract repointing Summary

**Repaired 4 REL-04 CI verify-lane failures by fixing a tenant_id seed/scope mismatch in two runtime integration tests and repointing two rendered-contract assertions (delegated-notebook primitives, incident-evidence heading) to their relocated/reworded canonical source — zero assertions deleted or loosened.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-11T14:22:28Z
- **Completed:** 2026-07-11T14:32:55Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- `test/scoria/runtime_integration_test.exs` and `test/scoria/workflows/integration_test.exs`: both integration tests were rendering "Workflow run not found" because the tenant_id used to seed the run did not match the tenant_id the test conn session mounted the operator `WorkflowLive.Show` LiveView under (`ReviewerSurface.fetch_tenant_run_detail/2` does strict tenant_id equality). Fixed by making the seed and the mounting scope tenant-consistent in each test.
- `test/scoria_web/components/memory_notebook_component_test.exs`: the "shared notebook primitives" contract check was reading `delegated_evidence_component.ex`, which is now a thin Phase 48 legacy 0.1.x compatibility wrapper that delegates to `ScoriaWeb.DelegatedTraceComponent`. Repointed the adapter-path list and the `delegated_status_label` check to `delegated_trace_component.ex`, the module that actually owns the shared `<.notebook>`/`import ScoriaWeb.UI` primitives now.
- `test/scoria_web/live/incidents_live_test.exs`: "Trace-first incident evidence" was renamed to "Trace-first incident review" in commit `59190886` (Phase 46-05, "normalize trace evidence copy boundary"). Repointed both the positive detail-page assertion and the negative index-page refute to the current heading.
- Verified the required four-file gate (`mix test test/scoria/runtime_integration_test.exs test/scoria/workflows/integration_test.exs test/scoria_web/components/memory_notebook_component_test.exs test/scoria_web/live/incidents_live_test.exs`) exits 0 with 25 tests, 0 failures.

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix the tenant-scoped seeded-run lookup so operator workflow pages render the seeded run** - `0d540fc7` (fix)
2. **Task 2: Repair the shared notebook primitives and incident-evidence rendered contracts** - `2618fcef` (fix)

**Plan metadata:** (this commit, docs: complete plan)

## Files Created/Modified
- `test/scoria/runtime_integration_test.exs` - Conn session `tenant_id` changed from `"tenant-integration"` to `"live-tenant"` so the operator mount resolves the tenant that owns the seeded run.
- `test/scoria/workflows/integration_test.exs` - `Workflows.create_run/1` now passes `tenant_id: "tenant-integration"` so the seeded run is tenant-scoped to match the mounting conn session (previously created with no tenant_id, defaulting to nil).
- `test/scoria_web/components/memory_notebook_component_test.exs` - Adapter-path list and delegated-source read repointed from `delegated_evidence_component.ex` (legacy wrapper) to `delegated_trace_component.ex` (canonical module); added a comment explaining the Phase 48 relocation.
- `test/scoria_web/live/incidents_live_test.exs` - Both the positive assertion (line ~240) and negative refute (line ~128) repointed from "Trace-first incident evidence" to "Trace-first incident review" (Phase 46-05 rename, confirmed via `git log -p`).

## Decisions Made
- Root-cause fix for the tenant mismatch: aligned seed and scope tenant_id values rather than touching `WorkflowLive.Show`'s lookup logic (`load_run/3` → `ReviewerSurface.fetch_tenant_run_detail/2`) or weakening either test's rendered assertions.
- For both rendered-contract drifts (notebook primitives, incident evidence copy), confirmed via `git log -p`/grep against the current source before repointing — both were genuine relocations/renames from prior phases (48 and 46-05 respectively), not regressions requiring a source fix.

## Deviations from Plan

None - plan executed exactly as written. Both root causes matched the plan's hypothesis (tenant-scoping mismatch for Task 1; relocated/reworded copy for Task 2), and no architectural decision was required.

## Issues Encountered

None. Both root causes were identified and confirmed on the first pass per task, matching the plan's `<read_first>` guidance.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Bucket C of the REL-04 CI gap inventory is closed: all 4 named failures (2 runtime/LiveView seeded-run render tests, notebook-primitive contract, incident-evidence contract) are green.
- A full `mix test` run after these fixes shows `3 doctests, 1129 tests, 6 failures (56 excluded)` — the remaining 6 failures (`PackageSurfaceTest`, `DevLabBoundaryTest`, two `UIComponentTest` cases, `SupportCopilotGalleryTest`/`OrchestratorProducerTest`/`SupportCopilot.JourneyTest`, `WarningInventory.CaptureParityTest`) are pre-existing REL-04 gap-inventory failures explicitly assigned to other buckets/plans (50-08 through 50-11) per `.planning/phases/50-release-readiness-and-0-1-3-cut/50-CI-GAP-INVENTORY.md` — out of scope for this plan and untouched by these changes.
- No blockers for subsequent gap-closure plans (50-08..50-11).

---
*Phase: 50-release-readiness-and-0-1-3-cut*
*Completed: 2026-07-11*

## Self-Check: PASSED

All modified test files and both task commits verified present.
