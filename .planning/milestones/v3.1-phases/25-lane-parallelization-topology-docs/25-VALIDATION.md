---
phase: 25
slug: lane-parallelization-topology-docs
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-15
---

# Phase 25 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir, `mix test`) |
| **Config file** | `test/test_helper.exs` (existing — Wave 0 adds none) |
| **Quick run command** | `mix test test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~15 seconds (contract tests parse YAML/docs; no DB) |

---

## Sampling Rate

- **After every task commit:** Run quick command (the two contract-test files)
- **After every plan wave:** Run `mix test --warnings-as-errors`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~15 seconds

---

## Per-Task Verification Map

> Filled by the planner from PLAN.md tasks. Every topology/fan-in/docs invariant is provable
> via an ExUnit contract test (no manual CI run required to prove the YAML/docs shape).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 25-01-01 | 01 | 1 | PAR-03 | — | N/A | contract | `mix test test/scoria/ci_policy_contract_test.exs` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements — ExUnit + the two contract-test files already exist. No new framework install.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live GitHub Actions parallel fan-out actually runs on a PR | PAR-01 / PAR-02 | The contract tests prove the YAML *shape* (parallel jobs, fan-in completeness, skipped=fail); they cannot prove GitHub's scheduler runs them in parallel on a real runner. | Open a PR, confirm `verify-summary` is the single required check and the sibling jobs run concurrently under it. |

*All YAML-topology, fan-in-completeness, and docs-content invariants have automated ExUnit verification. Only live-scheduler behavior is manual.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
