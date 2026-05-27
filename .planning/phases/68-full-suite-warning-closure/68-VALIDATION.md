---
phase: 68
slug: full-suite-warning-closure
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-27
---

# Phase 68 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19 / Mix) |
| **Config file** | `mix.exs`, `config/test.exs` |
| **Quick run command** | `mix scoria.warning_baseline.check && MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test --warnings-as-errors` |
| **Estimated runtime** | ~120 seconds (ratchet); ~300+ seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** Run plan-specific `<automated>` verify from task block
- **After every plan wave:** Run staged ratchet or scoped WAE for that wave
- **Before `/gsd-verify-work`:** Full suite WAE + `mix scoria.warning_baseline.check` must be green
- **Max feedback latency:** 300 seconds (full suite)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 68-00-01 | 00 | 0 | WARN-07 | T-68-01 / — | tmp preflight prevents false inventory failures | unit | `MIX_ENV=test mix test test/scoria/warning_inventory/` | ✅ | ⬜ pending |
| 68-00-02 | 00 | 0 | WARN-07 | T-68-02 / — | JSON encode path unified | unit | `MIX_ENV=test mix test test/scoria/warning_inventory/` | ✅ | ⬜ pending |
| 68-01-01 | 01 | 1 | WARN-07 | T-68-03 / — | ratchet step after runtime_to_handoff | contract | `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs` | ✅ | ⬜ pending |
| 68-01-02 | 01 | 1 | WARN-07 | — | staged ratchet WAE green | integration | `MIX_ENV=test mix scoria.warning_ratchet.test --warnings-as-errors` | ✅ | ⬜ pending |
| 68-02-01 | 02 | 2 | WARN-07 | — | adoption WAE green | integration | `MIX_ENV=test mix test.adoption --warnings-as-errors` | ✅ | ⬜ pending |
| 68-03-01 | 03 | 3 | WARN-07 | — | full suite WAE green | integration | `MIX_ENV=test mix test --warnings-as-errors` | ✅ | ⬜ pending |
| 68-03-02 | 03 | 3 | WARN-07 | — | baseline ledger closeout | integration | `mix scoria.warning_baseline.check` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scoria/warning_inventory/` — WR-01 tmp guard contract test
- [ ] `test/scoria/warning_inventory/` — WR-02 JSON encode contract test

*Existing ExUnit infrastructure covers all other phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CI pgvector parity | WARN-07 | Local dev may lack pgvector | Run full closeout with `SCORIA_DB_PORT=55432` matching ci.yml |
| Runtime LiveView teardown inventory | WARN-07 | Requires `--include-runtime` capture | `MIX_ENV=test mix scoria.warning_inventory --include-runtime --scope full` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s for quick loop
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
