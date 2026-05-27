---
gsd_state_version: 1.0
milestone: none
milestone_name: Awaiting next milestone
status: planning
last_updated: "2026-05-27T17:20:00Z"
last_activity: 2026-05-27 — Milestone v2.5 completed and archived
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-27)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Planning next milestone — `WARN-03` warning ratchet (run `/gsd-new-milestone`)

## Current Position

Phase: —
Plan: —
Status: Awaiting next milestone
Last activity: 2026-05-27 — Milestone v2.5 completed and archived

## Performance Metrics

- **Latest Shipped Milestone:** `v2.5 Installer Safety & Upgrade Confidence` on 2026-05-27
- **Archived Milestone Artifacts:** `.planning/milestones/v2.5-ROADMAP.md`, `v2.5-REQUIREMENTS.md`, `v2.5-MILESTONE-AUDIT.md`
- **Milestone Scope Shipped (v2.5):** 7 phases, 16 plans, 6 requirements (`INST-03`–`INST-08`)
- **Coverage (v2.5):** 6/6 milestone requirements satisfied (per `.planning/milestones/v2.5-MILESTONE-AUDIT.md`)
- **Active Milestone:** none — start with `/gsd-new-milestone`

## Accumulated Context

### Roadmap Evolution

- `v2.5` shipped planner/check no-write contracts, manifest-aware drift-safe apply, installer contract SSOT, and Nyquist/discoverability gap closure (phases 59–65).
- `WARN-03` full-suite warning ratchet is the immediate next milestone; baseline expiry `2026-06-07`.
- `v2.4` lane contracts, CI closeout order, and canonical verification commands remain non-negotiable constraints.

**Decisions:**

- Installer preview/check/apply share one planner artifact; check uses live fingerprints, apply uses stored manifest freshness gate.
- `Scoria.Install.Contract` is operator-output SSOT; adoption lane discoverability tests mirror `adoption_test_files/0`.
- UAT frontmatter must use `status: complete` (not `resolved`) for milestone-close artifact audits.

## Active Threads

- `.planning/threads/2026-05-27-warning-ratchet-followup.md` — primary scope for next milestone (`WARN-03`).
- `.planning/threads/2026-05-27-milestone-assessment-learnings.md` — lessons to promote into next phase `NN-LEARNINGS.md`.

## Deferred Items

| Category | Item | Status | Owner | Expires |
|----------|------|--------|-------|---------|
| tech debt | Project-level full-suite warning audit outside owned adoption lanes | baseline tracked in `.planning/WARNING-BASELINE.md` | scoria-maintainers | 2026-06-07 |
| tech debt | LiveView async teardown noise in workflow/replay test lane | accepted at `v1.9` close | scoria-web-runtime | 2026-06-30 |
| tech debt | `--dry-run` has no rescue path; check/apply degrade to structured error plans | low; Phase 59 carryover | installer | 2026-07-31 |
| tech debt | `mix scoria.test.install_contract` outside CI closeout chain | by design | installer | n/a |
| future milestone | Advanced bounded-handoff examples beyond shipped Relay lane | deferred | product-runtime | 2026-07-31 |

## Operator Next Steps

- `/clear` then `/gsd-new-milestone` to define `WARN-03` warning ratchet requirements and roadmap.
