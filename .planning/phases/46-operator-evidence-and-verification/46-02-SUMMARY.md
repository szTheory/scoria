---
phase: 46-operator-evidence-and-verification
plan: 02
subsystem: liveview
tags: [semantic-cache, operator-evidence, runtime-drawer, liveview]
requires:
  - phase: 46-01
    provides: shared semantic evidence DTO
provides:
  - Summary-first semantic evidence in the runtime drawer
  - Workflow deep links from runtime presence rows
affects: [orchestrator-live, runtime-drawer, operator-surfaces]
requirements-completed: [EVID-01]
completed: 2026-05-25
one_liner: Projected semantic outcome, scope, and deep-link evidence into the runtime drawer.
---

# Plan 46-02 Summary

## Outcome

Projected the shared semantic evidence contract into the runtime drawer as a summary-only surface with explicit fallback wording and workflow deep links.

## Changes

- updated `ScoriaWeb.OrchestratorLive` to load `Runtime.get_run_detail!/1` for runtime rows with `current_run_id`
- projected a compact `semantic` drawer map containing `lookup_status`, `fallback_outcome`, `lane_key`, `scope_kind`, `scope_reason`, `reason_code`, and deep links
- extended `ScoriaWeb.RuntimeDetailDrawerComponent` to render a compact semantic summary block without notebook-only detail
- added component and LiveView tests for runtime rows with and without a current run

## Verification

- `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test test/scoria_web/components/runtime_detail_drawer_component_test.exs test/scoria_web/live/orchestrator_live_test.exs --trace`
