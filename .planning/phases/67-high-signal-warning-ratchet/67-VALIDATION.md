---
phase: 67
slug: high-signal-warning-ratchet
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 67 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix test) |
| **Config file** | `mix.exs` test alias |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/warning_inventory/` |
| **WARN-05 command** | `MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test --warnings-as-errors test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs` |
| **WARN-06 command** | `MIX_ENV=test mix scoria.warning_ratchet.test --warnings-as-errors` |
| **Inventory write** | `MIX_ENV=test mix scoria.warning_inventory --write --scope full` |
| **Meta-gate** | `mix scoria.warning_baseline.check` |
| **Estimated runtime** | ~60–120 seconds per scoped gate; full inventory capture ~40s+ suite |

---

## Sampling Rate

- **After every task commit:** Run task `<automated>` verify command
- **After every plan wave:** Run plan-level verification block + `mix scoria.warning_baseline.check`
- **After plans 67-03/67-04:** Run `mix scoria.warning_inventory --write --scope full`
- **Before `/gsd-verify-work`:** WARN-05 + WARN-06 maintainer commands green; inventory shows p3 high-signal clusters at 0
- **Max feedback latency:** Use scoped paths only — never full `mix test --warnings-as-errors` as plan gate

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 67-00-01 | 00 | 0 | WARN-06 | T-67-00-01 | Inventory preflight rejects polluted test/tmp | unit | `MIX_ENV=test mix test test/scoria/warning_ratchet_test.exs` | ❌ W0 | ⬜ pending |
| 67-00-02 | 00 | 0 | WARN-06 | — | WarningRatchet paths non-empty, sorted | unit | same | ❌ W0 | ⬜ pending |
| 67-01-01 | 01 | 1 | WARN-05 | T-67-01-01 | Compile WAE holds | integration | compile + lane WAE | ✅ | ⬜ pending |
| 67-02-01 | 02 | 2 | WARN-06 | T-67-02-01 | Overlay not under test/support | unit | ratchet or dedicated test | ❌ W0 | ⬜ pending |
| 67-03-01 | 03 | 3 | WARN-06 | — | test/scoria p3 clusters zero in inventory | integration | scoped WAE + inventory | ✅ | ⬜ pending |
| 67-04-01 | 04 | 4 | WARN-06 | — | live p3 clusters zero | integration | scoped WAE + inventory write | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scoria/warning_ratchet_test.exs` — WarningRatchet path SSOT tests
- [ ] `lib/scoria/warning_ratchet.ex` — path list module
- [ ] `lib/mix/tasks/scoria.warning_ratchet.test.ex` — scoped WAE runner
- [ ] `lib/mix/tasks/scoria.warning_ratchet.check.ex` — unclassified high-signal gate (optional split from test)

*Wave 0 completes with plan 67-00.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Full inventory capture | WARN-06 | Long runtime; needs clean test/tmp | Empty `test/tmp/`; run `mix scoria.warning_inventory --write --scope full`; inspect `.planning/WARNING-INVENTORY.md` fixed/deferred table |
| Adoption maintainer WAE | WARN-06 (p2 deferred) | Not CI in 67 | After 67-02 fixes: `MIX_ENV=test mix test.adoption --warnings-as-errors`; document pass/fail in plan summary |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers WarningRatchet module + tests
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter after wave 0 green

**Approval:** pending
