---
gsd_state_version: 1.0
milestone: v2.8
milestone_name: CI Hardening & Post-Ship Hygiene
status: milestone_complete
last_updated: "2026-05-29T12:00:00Z"
last_activity: 2026-05-29 -- v2.8 CI hardening; post-publish smoke; connector adoption doc
progress:
  total_phases: 1
  completed_phases: 1
  total_plans: 0
  completed_plans: 0
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-29)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** v2.8 complete — CI hardening shipped; Hex `0.1.0` on main

## Current Position

Phase: 73 (complete)
Status: Milestone v2.8 closed
Last activity: 2026-05-29 -- SEM-CI-01, CI-KNOW-01, CI-INV-01 in ci-verify; post-publish smoke attested

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

- Plan v2.9 in `.planning/ROADMAP.md` when ready
- Routine releases: release-please on `main`; monitor `post-publish-smoke.yml` after each Hex publish
