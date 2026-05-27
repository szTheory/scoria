---
gsd_state_version: 1.0
milestone: v2.6
milestone_name: Scope
status: executing
last_updated: "2026-05-27T18:15:10Z"
last_activity: 2026-05-27 -- Completed 67-01-PLAN.md (WARN-05 canonical surface guard)
progress:
  total_phases: 4
  completed_phases: 1
  total_plans: 8
  completed_plans: 5
  percent: 50
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-27)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Phase 67 — high-signal warning ratchet (plan 67-02 next)

## Current Position

Phase: 67
Plan: 02 (next)
Status: Executing
Last activity: 2026-05-27 -- Completed 67-01-PLAN.md (WARN-05 canonical surface guard)

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

- Execute plan 67-02 (high-signal cluster fixes)
- Resume file: `.planning/phases/67-high-signal-warning-ratchet/67-02-PLAN.md`

### Phase 67 Decisions (67-00)

- WarningRatchet paths are code SSOT from adoption files + `test/scoria` + LiveView globs — not derived from baseline JSON
- Shared `WarningInventory.capture_output/0` backs inventory and ratchet check capture

### Phase 67 Decisions (67-01)

- WARN-05 maintainer proof limited to compile WAE + lane-contract tests (ratchet scope stays WARN-06)
- Policy job must not run `scoria.warning_ratchet` until Phase 68 wiring (D-17)
