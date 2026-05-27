---
gsd_state_version: 1.0
milestone: v2.6
milestone_name: Scope
status: executing
last_updated: "2026-05-27T22:15:55.065Z"
last_activity: 2026-05-27 -- Completed 68-02-PLAN.md (host-proof p2 verified clean)
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 12
  completed_plans: 11
  percent: 92
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-27)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Phase 68 — full-suite-warning-closure

## Current Position

Phase: 68 (full-suite-warning-closure) — EXECUTING
Plan: 3 of 4
Status: Ready for 68-03
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
| Phase 68-full-suite-warning-closure P02 | 55 | 4 tasks | 1 files |

## Operator Next Steps

- Execute plan 68-03 — full-suite WAE flip and baseline ledger `--write`
- Local closeout: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test.adoption --warnings-as-errors`
- Resume file: `.planning/phases/68-full-suite-warning-closure/68-03-PLAN.md`

### Phase 68 Decisions (68-02)

- p2 host-proof clusters already zero at measurement — no generator/runner or overlay template edits
- Adoption + ratchet WAE green with `SCORIA_DB_PORT=55432`; inventory `--write` deferred to 68-03

### Phase 68 Decisions (68-01)

- CI staged WAE uses `mix scoria.warning_ratchet.test --warnings-as-errors` after `runtime_to_handoff`; broad `mix test` stays non-WAE until 68-03
- Policy job excludes ratchet task (D-17); gate-order enforced in `ci_policy_contract_test.exs`
- Ratchet Mix task preflights tmp cleanup, compile, and test/support module load

### Phase 67 Decisions (67-04)

- LiveView p3 debt cleared via same minimal patterns as 67-03 (remove dead defaults / unused bindings)
- VerificationLanes SSOT committed — unblocks adoption surface and warning inventory lane attribution
- Phase 67 inventory closeout: zero clusters; p2/p4 debt explicitly deferred for Phase 68

### Phase 67 Decisions (67-00)

- WarningRatchet paths are code SSOT from adoption files + `test/scoria` + LiveView globs — not derived from baseline JSON
- Shared `WarningInventory.capture_output/0` backs inventory and ratchet check capture

### Phase 67 Decisions (67-01)

- WARN-05 maintainer proof limited to compile WAE + lane-contract tests (ratchet scope stays WARN-06)
- Policy job must not run `scoria.warning_ratchet` until Phase 68 wiring (D-17)

### Phase 67 Decisions (67-03)

- test/scoria non-live p3 debt cleared via inventory row targeting; live-path rows deferred to 67-04
- Dead default args fixed by removing unused defaults, not `_` prefix silencing

### Phase 67 Decisions (67-02)

- Knowledge migrations use `ensure_knowledge_migrated!/0` with scoped `ignore_module_conflict` (D-11)
- Host proof overlay stays under `priv/host_app_proof/overlay/test/` with architecture regression test (D-15)
- `mix test.adoption --warnings-as-errors` green for maintainers; not CI-gated in Phase 67 (D-16)
