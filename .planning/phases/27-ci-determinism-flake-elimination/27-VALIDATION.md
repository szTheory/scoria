---
phase: 27
slug: ci-determinism-flake-elimination
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-16
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (bundled with Elixir) |
| **Config file** | `config/test.exs` |
| **Quick run command** | `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~3 seconds (contract test is `--no-start`, pure file/regex scan) |

---

## Sampling Rate

- **After every task commit:** Run `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs`
- **After every plan wave:** Same (this phase is a single plan/wave)
- **Before `/gsd:verify-work`:** Full suite (`mix test --warnings-as-errors`) must be green
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 27-01-* | 01 | 1 | FLAKE-01 | — | No CI Postgres job binds a host port in the ephemeral range (≥ 32768) | contract | `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` | ✅ existing file | ⬜ pending |
| 27-01-* | 01 | 1 | FLAKE-02 | — | TEMP diagnostic step absent from `e2e` job in `ci.yml` | contract | `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` | ✅ existing file | ⬜ pending |
| 27-01-* | 01 | 1 | FLAKE-03 | — | No `continue-on-error`/retry-action on gating test workflow steps | contract | `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` | ✅ existing file | ⬜ pending |
| 27-01-* | 01 | 1 | SC-4 | — | All existing contract tests + verification lanes stay green; no lane removed/demoted | regression | `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` | ✅ existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* `test/scoria/ci_policy_contract_test.exs` already exists; the `job_blocks/1` helper is file-agnostic and ready. The new D-12 assertions are added to the existing file — no new test files, no framework install, no shared fixtures needed.

New assertions to add (durable guards):
- [ ] `"no CI Postgres job binds a host port in the ephemeral range (>= 32768)"` — D-12 / FLAKE-01
- [ ] `"e2e job in ci.yml has no TEMP diagnostic step"` — FLAKE-02 durable guard
- [ ] (Claude's Discretion) `"no gating test workflow step uses continue-on-error or a retry-action"` — D-07 / FLAKE-03

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Non-recurrence corroboration: ~10× `workflow_dispatch` sweep across `ci.yml` e2e + `ci-verify.yml` lanes | FLAKE-01 / SC-1 | Empirical CI-runtime evidence cannot be asserted in a unit test; the durable guarantee is structural (host port now below ephemeral range) + the contract test (D-12). The sweep is weak probabilistic corroboration only (D-13/D-14). | Trigger ~10 `workflow_dispatch` runs; paste run URLs into VERIFICATION.md; do NOT overclaim "10× proves it's gone." |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
