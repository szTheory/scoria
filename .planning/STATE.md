---
gsd_state_version: 1.0
milestone: v2.7
milestone_name: Scope
status: executing
last_updated: "2026-05-28T14:02:55.795Z"
last_activity: 2026-05-28 -- Phase 71 planning complete
progress:
  total_phases: 3
  completed_phases: 1
  total_plans: 7
  completed_plans: 3
  percent: 33
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-28)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Phase 71 — release-infrastructure

## Current Position

Phase: 71
Plan: Not started
Status: Ready to execute
Last activity: 2026-05-28 -- Phase 71 planning complete

## Performance Metrics

- **Latest Shipped Milestone:** `v2.6 Warning Ratchet` on 2026-05-28
- **Current Milestone:** `v2.7 OSS Release + Docs Truth`
- **Hex semver target:** `0.1.0` at git tag `v0.1.0` (distinct from GSD milestone tags `v2.x`)

## Accumulated Context

### Roadmap Evolution

- **v2.6 (shipped):** WARN-03–CI-03 complete; full-suite WAE in CI; milestone archived 2026-05-28.
- **v2.7 (active):** docs truth → release infra → Hex publish + coordinated README/test flip.
- **Deferred from v2.7:** SEM-CI-01 (semantic lane in PR CI) — document maintainer command only.
- **Preserve:** v2.4 lane contracts, v2.5 installer planner/check/apply, v2.6 warning-ratchet CI topology.

### Research decisions (2026-05-28)

- Capability-based shipped banner (not milestone codenames) for adopter docs.
- Docs truth merges before `mix hex.publish` — avoid public HexDocs with stale v2.1 narrative.
- release-please + publish workflow mirroring full CI test topology (szTheory pattern).
- `mix scoria.test.install_contract` — maintainer lane for deep installer proofs (Phase 70).

### Evidence (v2.6 closeout baseline)

- `mix scoria.test.ci_trust` — local Phase 69 contract verification
- `.planning/warning-inventory.baseline.json` — `"clusters": {}`
- `.planning/milestones/v2.6-MILESTONE-AUDIT.md` — passed; remote CI attestation pending (Phase 71 gate-zero)

## Active Threads

- Uncommitted WIP: `scoria.test.install_contract`, adoption lane boundary test — fold into Phase 70

## Deferred Items

| Category | Item | Status | Owner |
|----------|------|--------|-------|
| v2.7 | SEM-CI-01 semantic lane in PR CI | deferred — document only | scoria-maintainers |
| v2.7+ | Knowledge WAE in CI | deferred (Phase 69 D-17) | scoria-maintainers |
| v2.6 carryover | Remote GitHub Actions green attestation | Phase 71 gate-zero | scoria-maintainers |

## Operator Next Steps

- `/gsd-discuss-phase 70` or `/gsd-plan-phase 70` after roadmap approval
- Sequence: Phase 70 docs → Phase 71 release prep → Phase 72 publish
