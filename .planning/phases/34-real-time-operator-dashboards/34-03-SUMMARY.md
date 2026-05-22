---
phase: 34-real-time-operator-dashboards
plan: 03
subsystem: orchestrator-dashboard
tags: [phoenix, liveview, eval, campaign-detail]
requires:
  - phase: 34-real-time-operator-dashboards
    plan: 02
    provides: dashboard refresh state and campaign board selection surface
provides:
  - inline campaign drill-in with target lineage
  - selection persistence across campaign refreshes
  - fallback-aware target detail and eval-run links
affects: [dashboard, liveview, operator-ux]
tech-stack:
  added: []
  patterns: [id-only selection persistence, inline detail panel, durable drill-in links]
key-files:
  created: [.planning/phases/34-real-time-operator-dashboards/34-03-SUMMARY.md, lib/scoria_web/components/eval_campaign_detail_component.ex]
  modified: [lib/scoria_web/live/orchestrator_live.ex, test/scoria_web/live/orchestrator_live_test.exs]
key-decisions:
  - "Persisted only selected ids in LiveView assigns and always rehydrated detail from `Scoria.Eval` after refresh."
  - "Kept campaign drill-in inline rather than modal so operators retain board context during live updates."
  - "Rendered canonical durable status strings and explicit fallback badges instead of UI-derived summaries."
patterns-established:
  - "Treat campaign detail as a tenant-scoped projection lookup keyed by `selected_campaign_id`."
  - "Refresh selected campaign and model detail opportunistically during `load_operator_surface/1` when the selected row still exists."
requirements-completed: [OBS-01, OBS-02]
duration: 1h
completed: 2026-05-21
---

# Phase 34 Plan 03 Summary

**Operators can now inspect one selected campaign inline, keep that context across live refreshes, and drill into fallback-aware target lineage without leaving `/scoria`.**

## Accomplishments
- Added `select_campaign` and `clear_campaign_selection` flows backed by `Eval.get_campaign_dashboard_detail/2`.
- Rendered an inline campaign detail panel with target status, `Fallback used`, latest error reason, and `View Eval Run` links.
- Preserved selected campaign and selected model state across dashboard reloads when the underlying rows still exist.
- Added focused LiveView coverage for inline detail rendering, fallback badges, and selection persistence during broadcasts.

## Verification
- `mix test test/scoria_web/live/orchestrator_live_test.exs`
- `mix test test/scoria/orchestrator_test.exs test/scoria/eval/campaign_worker_test.exs test/scoria/eval/dashboard_projection_test.exs test/scoria/req/steps/resiliency_test.exs test/scoria_web/live/orchestrator_live_test.exs`

## Notes
- The final Phase 34 verification set passed with `41 tests, 0 failures`.
- Existing unrelated warnings remain in the repo, including `ReqCassette.with_cassette/3` references outside this phase and the local telemetry-handler warning in tests.

## Phase Readiness

Phase 34 is execution-complete. The dashboard now exposes summary, health, campaign progress, and inline drill-in from durable eval truth with tenant-scoped live refresh.
