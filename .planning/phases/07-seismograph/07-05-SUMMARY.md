---
phase: 07-seismograph
plan: 05
subsystem: scoria_web
tags:
  - liveview
  - sre
  - incident-evidence
dependency_graph:
  requires:
    - 07-04
    - 07-07
  provides:
    - SRE-07
    - SRE-08
  affects:
    - lib/scoria_web/components/incident_evidence_component.ex
    - lib/scoria_web/live/orchestrator_live.ex
    - test/scoria_web/live/orchestrator_live_sre_test.exs
    - test/scoria_web/live/orchestrator_live_test.exs
tech_stack:
  added:
    - Phoenix.LiveView assign_async evidence loading
  patterns:
    - trace-first operator notebook
    - compact run badges with lazy drilldown
key_files:
  created:
    - lib/scoria_web/components/incident_evidence_component.ex
    - test/scoria_web/live/orchestrator_live_sre_test.exs
  modified:
    - lib/scoria_web/live/orchestrator_live.ex
    - test/scoria_web/live/orchestrator_live_test.exs
decisions:
  - Keep heavy incident notebooks async while updating compact trace badges synchronously from small derived evidence.
  - Rescue missing SRE tables in the projection path so the existing dashboard does not crash before migrations land.
metrics:
  completed_at: 2026-05-11
---

# Phase 7 Plan 05: Incident Evidence Surface Summary

Projected Phase 7 budget, breaker, incident, audit, and notification evidence into the existing trace-first LiveView with a compact composite health rollup and on-demand notebook loading.

## Completed Tasks

### Task 1: Build a Trace-First Incident Evidence Component
- Added `ScoriaWeb.IncidentEvidenceComponent` with a calm operator notebook: composite health rollup, budget strip, breaker evidence, review/page incident rows, audit rows, and notification outcomes.
- Added a dedicated SRE LiveView test file that seeds persisted Phase 7 evidence and verifies deep links, scorer/baseline version visibility, and distinct review vs page severity rendering.
- Commits:
  - `9486d4a` `test(07-05): add failing test for incident evidence notebook`
  - `7f43d68` `feat(07-05): add trace-first incident evidence notebook`

### Task 2: Extend OrchestratorLive for Incident and Audit Projection
- Added `load_incident_evidence` and `load_budget_state` handlers with `assign_async/3` so the notebook and budget strip load on demand instead of bloating mount assigns.
- Added compact trace-row badges for budget warn/trip, breaker open, review incidents, and page incidents, refreshed from lightweight derived evidence when operators request SRE state.
- Extended LiveView coverage so retrieval evidence remains available alongside the SRE notebook.
- Commits:
  - `b5813f6` `test(07-05): extend lazy incident evidence coverage`
  - `5918e26` `feat(07-05): refresh trace badges from lazy SRE evidence`

## Verification

- `PASS` `rg -n "defmodule ScoriaWeb\\.IncidentEvidenceComponent|Composite health rollup|Notification delivery outcomes|Breaker and relay evidence" lib/scoria_web/components/incident_evidence_component.ex`
- `PASS` `rg -n "load_incident_evidence|load_budget_state|assign_async|IncidentEvidenceComponent|trace_badges|refresh_trace_badges" lib/scoria_web/live/orchestrator_live.ex`
- `PASS` `rg -n "approval-123|Review incident|Page incident|Budget warn|breaker open|Composite health rollup|Load Retrieval Evidence" test/scoria_web/live/orchestrator_live_sre_test.exs test/scoria_web/live/orchestrator_live_test.exs`
- `PASS` `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_sre_test.exs`
- `PASS` `MIX_ENV=test mix test test/scoria_web/live/orchestrator_live_sre_test.exs test/scoria_web/live/orchestrator_live_test.exs`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking Issue] Forced a fresh compile before the RED phase**
- **Found during:** Task 1 verification
- **Issue:** `mix test` could not start the app because `Scoria.Application` referenced `Scoria.SRE.Relay` before the current workspace compile artifacts recognized the module.
- **Fix:** Ran `mix compile --force` to rebuild the current workspace state before continuing the planned TDD loop.
- **Files modified:** None
- **Verification:** Subsequent `mix test` runs loaded `Scoria.SRE.Relay` successfully and executed the LiveView suites.
- **Commit:** None

**Total deviations:** 1 auto-fixed. **Impact:** No source change; this cleared a workspace compile-state blocker so plan verification could proceed.

## Authentication Gates

None.

## Known Stubs

None.

## Threat Flags

None.
