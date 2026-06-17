---
phase: 26
slug: full-suite-partition-sharding
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-16
---

# Phase 26 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `26-RESEARCH.md` § Validation Architecture. This phase ships CI/test-infrastructure
> changes; the "behavior" under test is the CI contract itself, asserted as ExUnit contract tests
> plus a runtime `after_suite` guard. There is no application feature surface.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5 / OTP 27) |
| **Config file** | `config/test.exs` (already partition-aware — DO NOT change) |
| **Quick run command** | `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | Contract tests ~a few seconds; full suite per shard ≈ ¼ of prior wall-clock |

---

## Sampling Rate

- **After every task commit:** Run the quick command (contract tests — fast, hermetic, `--no-start`).
- **After every plan wave:** Run the full suite command.
- **Before `/gsd:verify-work`:** Contract tests green AND a real CI run shows the 4 `full-suite (k/4)` shards green under `verify-summary`.
- **Max feedback latency:** ~10 seconds for the contract layer.

---

## Per-Task Verification Map

> Filled by the planner/executor as tasks are defined. Every SHARD-01 success criterion below
> maps to at least one automated assertion. Threat refs from the PLAN `<threat_model>` block.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 26-01-XX | 01 | 1 | SHARD-01 | — | `full-suite:` block declares `--partitions 4`, `matrix.partition [1,2,3,4]`, wires `MIX_TEST_PARTITION` from `matrix.partition`, `needs: build` | contract | `mix test test/scoria/ci_policy_contract_test.exs` | ❌ W0 | ⬜ pending |
| 26-01-XX | 01 | 1 | SHARD-01 | — | `full-suite` ∈ `verify-summary.needs`; `if: always()` retained; no `continue-on-error` | contract | `mix test test/scoria/ci_policy_contract_test.exs` | ❌ W0 | ⬜ pending |
| 26-01-XX | 01 | 1 | SHARD-01 | — | `after_suite` guard exits non-zero on a 0-test partition (gated on `MIX_TEST_PARTITION`) | contract+runtime | `mix test test/scoria/ci_policy_contract_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scoria/ci_policy_contract_test.exs` — D-03 structural coverage-proof asserts (`--partitions 4`, `MIX_TEST_PARTITION` wiring, `partition: [1,2,3,4]`, `needs: build`) + D-04 targeted `assert "full-suite" in verify_summary_needs(...)` + new `after_suite`-guard-present assertion; non-empty `job_blocks` guard so a broken parser can't vacuously pass.
- [ ] `test/test_helper.exs` — `after_suite` zero-test guard, gated on `System.get_env("MIX_TEST_PARTITION")`.
- [ ] Fix the THREE existing contract tests that go RED when the `mix test --WAE` step moves out of `test:` (research B-1/B-2/B-3): two in `ci_policy_contract_test.exs`, one in `verification_lanes_test.exs`.

*Framework already installed — no install task needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Zero coverage loss vs prior single-job run | SHARD-01 / SC#3 | Proven by partition math (rem-completeness) at design time; the union-equals-suite property is mathematical, not observable in one run | Confirmed by D-03 proof comment + structural contract test. The first real sharded CI run should show 4 green shards; compare summed shard test counts informally (not gated). |
| `full-suite (k/4)` shards never auto-required | SHARD-01 / SC#4 | Branch-protection state lives in GitHub settings, not the repo | Verify branch protection still requires only `CI / ci-gate` after merge. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
