---
phase: 36
slug: vanguard-milestone-state-reconciliation
status: executed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-22
executed_on: 2026-05-22
---

# Phase 36 — Validation Strategy

> Executed validation map for the milestone-state reconciliation that made v1.8 closure-ready without mutating the historical pre-reconciliation audit snapshot.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | planning-doc verification plus targeted route/component tests |
| **Quick run command** | `mix test test/scoria_web/components/runtime_detail_drawer_component_test.exs test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/router_test.exs` |
| **Full verification command** | `rg -n "Ready to close|v1.8|30-VERIFICATION.md|31-VERIFICATION.md|32-VERIFICATION.md|33-VERIFICATION.md|34-VERIFICATION.md" .planning/milestones/v1.8-ROADMAP.md .planning/milestones/v1.8-REQUIREMENTS.md .planning/ROADMAP.md .planning/REQUIREMENTS.md .planning/STATE.md .planning/PROJECT.md .planning/MILESTONES.md .planning/MILESTONE-ARC.md && mix test test/scoria_web/components/runtime_detail_drawer_component_test.exs test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/router_test.exs` |
| **Estimated runtime** | < 30 seconds |

---

## Per-Task Verification Map

| Task ID | Plan | Requirement | Secure Behavior | Test Type | Automated Command | Status |
|---------|------|-------------|-----------------|-----------|-------------------|--------|
| 36-01 | 01 | milestone-local truth | Milestone-local roadmap and requirements surfaces agree on closure-ready v1.8 truth and terminate proof at phase-local verification files | docs + grep | `rg -n "Ready to close|30-VERIFICATION.md|31-VERIFICATION.md|32-VERIFICATION.md|33-VERIFICATION.md|34-VERIFICATION.md" .planning/milestones/v1.8-ROADMAP.md .planning/milestones/v1.8-REQUIREMENTS.md` | ✅ green |
| 36-02 | 02 | root projection truth | Root roadmap and requirements project the milestone-local v1.8 truth without stale pending markers | docs + grep | `rg -n "Ready to close|30-VERIFICATION.md|31-VERIFICATION.md|32-VERIFICATION.md|33-VERIFICATION.md|34-VERIFICATION.md" .planning/ROADMAP.md .planning/REQUIREMENTS.md` | ✅ green |
| 36-03 | 03 | live state alignment | State, milestone, and project narrative surfaces present audit-first v1.8 closure status coherently | docs + grep | `rg -n "Ready to close|\\$gsd-audit-milestone v1.8|v1.8 Vanguard" .planning/STATE.md .planning/PROJECT.md .planning/MILESTONES.md .planning/MILESTONE-ARC.md` | ✅ green |
| 36-04 | 03 | operator drill-in parity | Mounted `/scoria` workflow routes are reflected in rendered component links | component + liveview | `mix test test/scoria_web/components/runtime_detail_drawer_component_test.exs test/scoria_web/live/orchestrator_live_test.exs test/scoria_web/router_test.exs` | ✅ green |

---

## Validation Sign-Off

- [x] All tasks have automated verify paths
- [x] Validation covers milestone-local, root-level, and live status surfaces
- [x] Mounted `/scoria` workflow navigation is proven by tests after reconciliation closeout
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Executed during milestone audit gap closure.
