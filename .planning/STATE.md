---
gsd_state_version: 1.0
milestone: v2.8
milestone_name: CI Hardening & Post-Ship Hygiene
status: Awaiting next milestone
last_updated: "2026-05-29T16:00:00.000Z"
last_activity: 2026-05-29 — Milestone v2.8 completed and archived
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-29)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** v2.8 complete — CI hardening shipped; Hex `0.1.0` on main

## Current Position

Phase: Milestone v2.8 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-05-29 — Milestone v2.8 completed and archived

## Performance Metrics

- **Latest Shipped Milestone:** `v2.8 CI Hardening & Post-Ship Hygiene` on 2026-05-29
- **Hex release:** `0.1.0` at git tag `v0.1.0` — https://hex.pm/packages/scoria
- **Previous:** `v2.7 OSS Release + Docs Truth` (2026-05-29)

## Accumulated Context

### Roadmap Evolution

- **v2.8 (shipped):** Semantic lane WAE, knowledge WAE, inventory baseline policy gate; `docs/connector_adoption.md`.
- **v2.7 (shipped):** Docs truth → release infra → Hex publish + README flip.
- **v2.6 (shipped):** WARN-03–CI-03; full-suite WAE in CI.

### Evidence

- `.planning/phases/72-hex-publish-closeout/72-VERIFICATION.md` — integration, publish, smoke
- `.planning/milestones/v2.8-REQUIREMENTS.md` — SEM-CI-01, CI-KNOW-01, CI-INV-01
- `mix scoria.test.ci_trust` — policy + ratchet hygiene contracts

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| v2.9+ | Next milestone scope | open — planning |

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
