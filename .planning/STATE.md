---
gsd_state_version: 1.0
milestone: v2.6
milestone_name: Scope
status: executing
last_updated: "2026-05-27T17:54:24.002Z"
last_activity: 2026-05-27
progress:
  total_phases: 4
  completed_phases: 1
  total_plans: 3
  completed_plans: 3
  percent: 25
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-27)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Phase 66 — baseline-expiry-and-inventory

## Current Position

Phase: 67
Plan: Not started
Status: Executing Phase 66
Last activity: 2026-05-27

## Performance Metrics

- **Latest Shipped Milestone:** `v2.5 Installer Safety & Upgrade Confidence` on 2026-05-27
- **Active Milestone:** `v2.6 Warning Ratchet` (phases 66–69)
- **Baseline expiry pressure:** full-suite debt expires `2026-06-07` (`.planning/WARNING-BASELINE.md`)

## Accumulated Context

### Roadmap Evolution

- `v2.5` shipped planner/check no-write contracts, manifest-aware drift-safe apply, installer contract SSOT (phases 59–65).
- **v2.6 (active):** `WARN-03`–`WARN-07` staged warning ratchet; executable baseline-expiry CI; preserve lane closeout order.
- **v2.7 (queued):** first Hex publish + README/shipped-state docs-truth.
- `v2.4` lane contracts and CI closeout order remain non-negotiable.

### Evidence (milestone start)

- `mix compile --warnings-as-errors` — pass
- `mix test --warnings-as-errors` — fails (knowledge migration redefines, unused vars, LiveView teardown noise, host-proof warnings)
- Canonical lanes — warning-clean (v2.4/v2.5)

## Active Threads

- `.planning/threads/2026-05-27-warning-ratchet-followup.md` — primary execution scope
- `.planning/threads/2026-05-27-milestone-assessment-learnings.md` — graduation candidates for Phase 66 `66-LEARNINGS.md`

## Deferred Items

| Category | Item | Status | Owner | Expires |
|----------|------|--------|-------|---------|
| tech debt | Project-level full-suite warning audit | baseline in `.planning/WARNING-BASELINE.md` | scoria-maintainers | 2026-06-07 |
| tech debt | LiveView async teardown noise in workflow/replay tests | accepted at `v1.9` close | scoria-web-runtime | 2026-06-30 |
| future milestone | v2.7 OSS release + docs-truth | queued after v2.6 | scoria-maintainers | — |

## Operator Next Steps

- `/gsd-plan-phase 66` — plan baseline expiry + inventory implementation
- Resume file: `.planning/phases/66-baseline-expiry-and-inventory/66-CONTEXT.md`
