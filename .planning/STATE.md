---
gsd_state_version: 1.0
milestone: v2.6
milestone_name: Scope
status: executing
last_updated: "2026-05-27T23:25:00Z"
last_activity: 2026-05-27 -- Completed 68-03-PLAN.md (WARN-07 full-suite WAE flip)
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 12
  completed_plans: 12
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-27)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Phase 69 — CI Trust And Milestone Closeout

## Current Position

Phase: 68 (full-suite-warning-closure) — COMPLETE
Plan: 4 of 4
Status: Ready for Phase 69
Last activity: 2026-05-27

## Performance Metrics

- **Latest Shipped Milestone:** `v2.5 Installer Safety & Upgrade Confidence` on 2026-05-27
- **Active Milestone:** `v2.6 Warning Ratchet` (phases 66–69)
- **Baseline expiry pressure:** cleared (full-suite + LiveView rows resolved 2026-05-27)

## Accumulated Context

### Roadmap Evolution

- `v2.5` shipped planner/check no-write contracts, manifest-aware drift-safe apply, installer contract SSOT (phases 59–65).
- **v2.6 (active):** WARN-03–WARN-07 complete through Phase 68; Phase 69 milestone closeout remains.
- **v2.7 (queued):** first Hex publish + README/shipped-state docs-truth.
- `v2.4` lane contracts and CI closeout order remain non-negotiable.

### Evidence (Phase 68 closeout)

- `mix compile --warnings-as-errors` — pass
- `mix test --warnings-as-errors` — pass (457 tests, SCORIA_DB_PORT=55432)
- CI test job — `mix test --warnings-as-errors` after closeout lanes
- `.planning/warning-inventory.baseline.json` — `"clusters": {}`

## Active Threads

- `.planning/threads/2026-05-27-warning-ratchet-followup.md` — primary execution scope
- `.planning/phases/68-full-suite-warning-closure/68-VERIFICATION.md` — WARN-07 evidence

## Deferred Items

| Category | Item | Status | Owner | Expires |
|----------|------|--------|-------|---------|
| future milestone | v2.7 OSS release + docs-truth | queued after v2.6 | scoria-maintainers | — |

## Operator Next Steps

- Execute Phase 69 — CI Trust And Milestone Closeout (CI-03)
- Local closeout: `SCORIA_DB_PORT=55432 MIX_ENV=test mix test --warnings-as-errors`
- Resume file: `.planning/phases/69-ci-trust-and-milestone-closeout/` (when planned)

### Phase 68 Decisions (68-03)

- WARN-07 Path A: full WAE green; baseline Accepted rows → Resolved During v2.6
- CI ratchet bridge removed; `mix test --warnings-as-errors` is production gate
- Installer subprocess `MIX_BUILD_PATH=_build/install_subprocess` preserves test/support beams
- Nested `WarningInventory.capture_output/0` skips subprocess when ExUnit parent runs WAE

### Phase 68 Decisions (68-02)

- p2 host-proof clusters already zero at measurement — no generator/runner or overlay template edits
- Adoption + ratchet WAE green with `SCORIA_DB_PORT=55432`

### Phase 68 Decisions (68-01)

- Staged ratchet was interim bridge until 68-03 flip (superseded)
- Policy job excludes ratchet task (D-17)
