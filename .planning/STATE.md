---
gsd_state_version: 1.0
milestone: v3.2
milestone_name: Drydock
current_phase: 30
current_phase_name: launch-banner-native-dev-notice
status: verifying
stopped_at: Phase 30 context gathered
last_updated: "2026-06-18T05:37:47.342Z"
last_activity: 2026-06-18
last_activity_desc: Phase 30 execution started
progress:
  total_phases: 13
  completed_phases: 2
  total_plans: 2
  completed_plans: 2
  percent: 15
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-17 after v3.2 Drydock roadmap initialized)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Phase 30 — launch-banner-native-dev-notice

## Current Position

Phase: 30 (launch-banner-native-dev-notice) — EXECUTING
Plan: 1 of 1
Status: Phase complete — ready for verification
Last activity: 2026-06-18 — Phase 30 execution started

Progress: [░░░░░░░░░░] 0% (0/7 v3.2 phases complete)

## Performance Metrics

- **Latest Shipped:** `v3.1 CI/CD Velocity` (2026-06-17) — 9 plans, 6 phases, 13 tasks. Audit `passed` (13/13). PR CI 77m→7m38s MEASURED.
- **Previous Shipped:** `v3.0 Control Room` (2026-06-14) — 38 plans, 7 phases, 65 tasks. Audit `gaps_found` accepted.

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- v3.2: `make nuke` uses ONLY `docker compose down -v` — no `docker system/volume prune`; no interactive TTY prompt; named-scope warning is the safety signal.
- v3.2: `PORT ?= 4799` baked into `make dev` (static, stable for shots-native harness; overridable via `PORT=XXXX make dev`; no `config/dev.exs` change).
- v3.2: Stream B (Phase 35) is fully independent of Stream A (Phases 29–34) — can execute in parallel.
- v3.2: `VerificationLanes.closeout_order/0` and `CI / ci-gate` required-check name stay byte-stable; new tests run in existing policy lane only; no CI topology changes.
- v3.2: Parallelism within Stream A: Phases 30, 31, 32 can all run after Phase 29 (no inter-dependencies); Phase 33 depends on 29–32; Phase 34 depends on 33.
- [Phase ?]: Route list derived live from mix phx.routes ScoriaWeb.DevRouter

### Pending Todos

- Rotate `ANTHROPIC_API_KEY` on the Anthropic console before Phase 32 closes (SEC-02 — out-of-band maintainer action).
- Post-v3.2: SEED-004 test-code determinism (async `IntegrationCase`, `Process.sleep` removal) — leading candidate for next milestone.
- Post-v3.2: FLEET-01 sibling-repo convergence (rulestead/parapet) — `docker-dx-fleet-hardening` todo.
- Post-ship cleanup: `ci-policy-job-cache-key-mislabel` (carried from v3.1 close).

### Blockers/Concerns

None at milestone start.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Test determinism | SEED-004: async IntegrationCase, remove Process.sleep, raise shard count | Deferred | v3.1 close |
| Fleet convergence | FLEET-01: migrate sibling repos onto shared Traefik + unpublished-DB standard | Deferred | v3.2 scope decision |
| Fleet targets | FLEET-02: `make nuke-all` fleet-wide teardown (high blast radius) | Deferred | v3.2 out-of-scope |
| v3.0 gaps | Phase 13/14 verification-doc gaps (functional: 0 unsatisfied; 10 partials are proof-only) | Deferred | v3.0 close |
| Release | Publish 0.1.1 → superseded by 0.1.2 in Phase 35 | Absorbed into REL-01 | v3.2 REL |
| Phase 30 P01 | 319 | 2 tasks | 2 files |

## Session Continuity

Last session: 2026-06-18T05:37:39.707Z
Stopped at: Phase 30 context gathered
Resume file: .planning/phases/30-launch-banner-native-dev-notice/30-CONTEXT.md
