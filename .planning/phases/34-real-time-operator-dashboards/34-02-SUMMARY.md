---
phase: 34-real-time-operator-dashboards
plan: 02
subsystem: orchestrator-dashboard
tags: [phoenix, liveview, eval, dashboard, pubsub]
requires:
  - phase: 34-real-time-operator-dashboards
    plan: 01
    provides: eval dashboard projection APIs and tenant-scoped broadcasts
provides:
  - summary strip for campaign and breaker posture
  - model health matrix with tenant-scoped live refresh
  - compact campaign board embedded in `/scoria`
affects: [dashboard, liveview, operator-ux]
tech-stack:
  added: []
  patterns: [projection-first refresh, tenant-scoped subscriptions, inline dashboard components]
key-files:
  created: [.planning/phases/34-real-time-operator-dashboards/34-02-SUMMARY.md, lib/scoria_web/components/model_health_drawer_component.ex, lib/scoria_web/components/eval_campaign_board_component.ex]
  modified: [lib/scoria_web/live/orchestrator_live.ex, test/scoria_web/live/orchestrator_live_test.exs]
key-decisions:
  - "Kept the dashboard inside the existing `OrchestratorLive` surface rather than creating a separate eval ops LiveView."
  - "Reloaded summary, matrix, and board state from `Scoria.Eval` projection APIs on broadcast instead of incrementally mutating assigns."
  - "Used selection-only actions for model health and campaign inspection to avoid introducing privileged control paths."
patterns-established:
  - "Subscribe `/scoria` to tenant-scoped eval topics in the same mount flow already used for runtimes."
  - "Represent model health as compact provider:model cells plus an inline detail drawer fed by projection queries."
requirements-completed: [OBS-01, OBS-02]
duration: 1h
completed: 2026-05-21
---

# Phase 34 Plan 02 Summary

**The `/scoria` dashboard now shows the approved real-time summary strip, model health matrix, and campaign board from tenant-scoped projection data.**

## Accomplishments
- Added `scoria:eval_campaigns:{tenant}` and `scoria:model_health:{tenant}` subscriptions to `OrchestratorLive`.
- Rendered the exact summary-strip labels `active campaigns`, `completed today`, `fallback targets`, and `breaker-open models`.
- Added a model health matrix and inline drawer surface for provider:model detail, fallback counts, freshness, and linked active campaigns.
- Added a compact campaign board with the primary action text `Inspect Campaign Progress`.

## Verification
- `mix test test/scoria_web/live/orchestrator_live_test.exs`

## Notes
- A mount-time crash surfaced because projection timestamps can arrive as `NaiveDateTime`; the dashboard helpers were widened to accept both `DateTime` and `NaiveDateTime`.
- No scope deviation. The work stayed inside the existing operator surface and reused repo-native component patterns.

## Next Phase Readiness

Plan 34-03 can proceed. The dashboard now has stable refresh wiring and the selection surfaces needed for inline campaign drill-in.
