---
gsd_state_version: 1.0
milestone: v3.2
milestone_name: Drydock
current_phase: 35
current_phase_name: maintenance-release-0-1-2-publish-post-publish-smoke
status: complete
stopped_at: Completed 35-03-PLAN.md
last_updated: "2026-06-19T15:45:16Z"
last_activity: 2026-06-19
last_activity_desc: v3.2 milestone archived - 0.1.2 published and post-publish smoke green
progress:
  total_phases: 7
  completed_phases: 7
  total_plans: 15
  completed_plans: 15
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-19 after v3.2 Drydock closeout)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Planning next milestone

## Current Position

Phase: 35 (maintenance-release-0-1-2-publish-post-publish-smoke) — COMPLETE
Plan: 3 of 3
Status: Complete
Last activity: 2026-06-19 — Phase 35 complete; Hex `0.1.2` live and post-publish smoke green

Progress: [██████████] 100%

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
- [Phase ?]: Route list derived live from mix phx.routes ScoriaWeb.DevRouter.
- [Phase 32]: Maintainer szTheory accepted no Anthropic key rotation required because `.env` was local ignored plaintext with no Git history; SEC-02 closeout records no token material.
- [Phase 34]: Created dedicated DOCS-03 ExUnit contract that reads only docs/docker_dev_dx.md via File.read!(@doc_path). — Keeps the docs drift guard file-read-only and safe under mix test --no-start.
- [Phase 34]: Used two-layer stale URL guard for fixed localhost/loopback 4000 browser-start drift while allowing qualified Docker-internal mechanics. — Matches Phase 34 D-17 through D-19 without banning legitimate container, Traefik, service-target, or ephemeral fallback references.
- [Phase 34]: Kept post-publish smoke to the narrow `5432:5432` / `SCORIA_DB_PORT: 5432` fix and extended the existing FLAKE-01 scanner with an exact `post-publish-smoke.yml:smoke` key guard.
- [Phase 34]: Kept Docker DX doc-token ownership in `Scoria.DockerDxDocContractTest`; `ci_policy_contract_test.exs` now retains only the `.env.example` instance example guard for that surface.
- [Phase 34]: Appended `test/scoria/docker_dx_doc_contract_test.exs` to the existing policy-lane `mix test --no-start --warnings-as-errors` file list only.
- [Phase 34]: Left `CI / ci-gate`, `ci.yml`, workflow topology, job names, services, matrices, needs, and `Scoria.VerificationLanes.closeout_order/0` unchanged while completing DOCS-03 lane wiring.
- [Phase 35]: README remains Hex-primary; the commented GitHub fallback is fork/pinned-patch guidance, not a release-candidate tag contract.
- [Phase 35]: `registry_upgrade_pair("0.1.2")` uses previous live Hex release `0.1.0` instead of patch-minus-one arithmetic.
- [Phase 35]: Release PR #3 merge authority was latest head `d0eecbb66c19f85d25a77cbae9ce2fd91ca50f11` with `CI / ci-gate` success before release-pr-automerge merged commit `26eb9a5e686fe4957196dfa5c6654121bda65c03`.
- [Phase 35]: Post-merge Release Please cancellation was classified as uncertain publish recovery because GitHub release `v0.1.2` existed but Hex did not list `0.1.2`; existing `hex-publish.yml` recovery published exact `tag=v0.1.2` / `release_version=0.1.2`.
- [Phase 35]: After Hex listed `0.1.2`, recovery stayed smoke-only; final post-publish smoke run `27834739958` proved fresh install and live-lineage upgrade `0.1.0 -> 0.1.2`.

### Pending Todos

- Phase 33: Restructure Docker DX docs and correct verification-copy drift now that Phase 32's no-Git-exposure SEC-02 closeout is recorded.
- UI follow-up: make approval rejection toasts legible over dense approvals UI — `make-approval-toasts-legible` todo.
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
| Phase 32 P01 | 18 min | 2 tasks | 5 files |
| Phase 32 P02 | 10 min | 1 task | 4 files |
| Phase 33 P01 | 18min | 2 tasks | 1 files |
| Phase 33 P02 | 12min | 2 tasks | 5 files |
| Phase 33 P03 | 14min | 3 tasks | 9 files |
| Phase 33 P04 | 28min | 3 tasks | 11 files |
| Phase 34 P01 | 3 min | 2 tasks | 1 files |
| Phase 34 P02 | 4 min | 2 tasks | 2 files |
| Phase 34 P03 | 2 min | 1 tasks | 1 files |
| Phase 35 P01 | 14 min | 2 tasks | 3 files |
| Phase 35 P02 | 30 min | 3 tasks | 18 files |
| Phase 35 P03 | 48 min | 3 tasks | 6 files |

## Session Continuity

Last session: 2026-06-19T15:45:16Z
Stopped at: Completed 35-03-PLAN.md
Resume file: None
