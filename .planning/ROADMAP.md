# Roadmap: Scoria

## Milestones

- ◆ **v2.6 Warning Ratchet** — Active (this file)
- ✅ **v2.5 Installer Safety & Upgrade Confidence** — Archived: `.planning/milestones/v2.5-ROADMAP.md` (shipped 2026-05-27)
- ✅ **v2.4 Adoption Reliability Contract** — Archived: `.planning/milestones/v2.4-ROADMAP.md` (shipped 2026-05-27)

## v2.6 Scope

**Goal:** Close full-suite warning debt with staged warnings-as-errors ratchet and executable baseline-expiry policy.

**Requirements mapped:** 6 / 6

| Phase | Name | Goal | Requirements |
|------:|------|------|--------------|
| 66 | Baseline Expiry And Inventory | Executable baseline expiry + classified inventory | WARN-03, WARN-04 |
| 67 | High-Signal Warning Ratchet (5/5) | Clear warnings in compile + canonical lane + targeted high-signal tests | WARN-05, WARN-06 |
| 68 | Full-Suite Warning Closure | Green `mix test --warnings-as-errors` in CI or honest re-baseline | WARN-07 |
| 69 | CI Trust And Milestone Closeout | Preserve lane order; wire gates; close ledger | CI-03 |

## Phases

- [x] Phase 66: Baseline Expiry And Inventory (0/? plans) (completed 2026-05-27)
- [x] Phase 67: High-Signal Warning Ratchet (5/5 plans) (completed 2026-05-27)
- [ ] Phase 68: Full-Suite Warning Closure (0/? plans)
- [ ] Phase 69: CI Trust And Milestone Closeout (0/? plans)

## Phase Details

### Phase 66: Baseline Expiry And Inventory

**Goal:** Turn `.planning/WARNING-BASELINE.md` from prose policy into executable CI truth and produce a classified warning inventory.

**Requirements:** WARN-03, WARN-04

**Success criteria:**

1. CI step fails when any baseline row is past expiry (before or alongside compile WAE).
2. Inventory output groups known warning clusters (e.g. knowledge migration redefines, unused vars, LiveView teardown, host-proof compile) with file/area attribution.
3. Inventory is reproducible from documented maintainer command(s) and referenced in milestone thread or phase notes.

### Phase 67: High-Signal Warning Ratchet

**Goal:** Clear warnings in compile, canonical lane surfaces, and inventory-prioritized high-signal tests without destabilizing the full suite.

**Requirements:** WARN-05, WARN-06

**Success criteria:**

1. `mix compile --warnings-as-errors` passes.
2. `mix test --warnings-as-errors` for lane-contract + adoption surface tests passes.
3. Targeted high-signal test paths from Phase 66 inventory pass under WAE (remaining debt explicitly listed if deferred).

### Phase 68: Full-Suite Warning Closure

**Goal:** Achieve green full-suite WAE in CI or update baseline ledger with honest owner+expiry for any remaining accepted debt.

**Requirements:** WARN-07

**Success criteria:**

1. `mix test --warnings-as-errors` passes locally and in CI.
2. `.planning/WARNING-BASELINE.md` reflects post-ratchet truth (resolved rows removed; any remaining debt has owner+expiry).
3. No silent regression of canonical lane warning-clean status.

### Phase 69: CI Trust And Milestone Closeout

**Goal:** Wire staged gates into CI without changing canonical closeout order; close milestone traceability.

**Requirements:** CI-03

**Success criteria:**

1. CI order remains `release_preview` → `adoption` → `runtime_to_handoff` for closeout lanes.
2. Baseline-expiry check and full-suite WAE gate are present and documented in `.github/workflows/ci.yml`.
3. REQUIREMENTS traceability and milestone audit artifacts updated for v2.6 closeout.

## Non-Goals (v2.6)

- Hex publish or README shipped-state corrections (v2.7).
- New runtime capability families.
- Installer planner/check/apply changes.
- Broad LiveView refactor beyond inventory-targeted warning fixes.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
| ----- | --------- | -------------- | ------ | --------- |
| 66. Baseline Expiry And Inventory | v2.6 | 0/? | Not started | — |
| 67. High-Signal Warning Ratchet | v2.6 | 5/5 | Complete | 2026-05-27 |
| 68. Full-Suite Warning Closure | v2.6 | 0/? | Not started | — |
| 69. CI Trust And Milestone Closeout | v2.6 | 0/? | Not started | — |
