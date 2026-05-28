---
gsd_state_version: 1.0
milestone: v2.6
milestone_name: Warning Ratchet
status: awaiting_next_milestone
last_updated: "2026-05-28T11:32:23.681Z"
last_activity: 2026-05-28 — Milestone v2.6 completed and archived
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 15
  completed_plans: 15
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-28)

**Core value:** Phoenix teams can add AI runtime governance, visibility, and recovery to an existing app without guessing where Scoria begins, where their app owns identity and policy, or how to verify the integration is working.

**Current focus:** Planning v2.7 OSS Release + Docs Truth

## Current Position

Phase: Milestone v2.6 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-05-28 — Milestone v2.6 completed and archived

## Performance Metrics

- **Latest Shipped Milestone:** `v2.6 Warning Ratchet` on 2026-05-28
- **Next Milestone:** `v2.7 OSS Release + Docs Truth` (HEX-01, DOCS-03)
- **Baseline expiry pressure:** cleared; baseline ledger empty at v2.6 closeout

## Accumulated Context

### Roadmap Evolution

- `v2.5` shipped planner/check no-write contracts, manifest-aware drift-safe apply, installer contract SSOT (phases 59–65).
- **v2.6 (shipped):** WARN-03–CI-03 complete; milestone archived 2026-05-28.
- **v2.7 (next):** first Hex publish + README/shipped-state docs-truth.
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
| Phase 69 P01 | 6 | 2 tasks | 2 files |
| Phase 69 P02 | 12 min | 3 tasks | 5 files |

## Operator Next Steps

- Run `/gsd-new-milestone` to define v2.7 requirements and roadmap
- Preserve v2.6 CI gates: `mix scoria.test.ci_trust`, policy→test topology in `ci.yml`

### Phase 69 Decisions (69-01)

- `warning_ratchet.test` mirrors check tmp lifecycle: `ensure_clean_tmp!` → work → `cleanup_transient_tmp!` in `after` (WR-01)
- Ratchet integration test uses subprocess `mix scoria.warning_ratchet.check` to avoid nested ExUnit capture skip (WR-02)

### Phase 69 Decisions (69-00)

- CI gate map in `docs/operator_verification.md` only — no `docs/ci.md` duplicate (D-05)
- `ci.yml` comments-only; step order unchanged for contract tests
- CI-03 checkbox deferred to 69-02 verification (D-09)

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
