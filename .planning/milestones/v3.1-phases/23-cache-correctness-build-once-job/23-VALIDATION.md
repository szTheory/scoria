---
phase: 23
slug: cache-correctness-build-once-job
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-14
---

# Phase 23 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `23-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir, built-in) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `SCORIA_LANE_CONTRACT_ONLY=true MIX_ENV=test mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` |
| **Full suite command** | `mix test test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` |
| **Estimated runtime** | ~3–5 seconds (contract tests are pure file-read assertions, `--no-start`) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command (lane-contract tests)
- **After every plan wave:** Run the full suite command
- **Before `/gsd:verify-work`:** Both contract test files green + the no-recompile CI-log proof captured
- **Max feedback latency:** ~5 seconds (local contract tests). CI-log proof (SC#3) is observable only after a real CI run.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 23-XX | — | 1 | CACHE-01 | — / — | Cache keys env+version scoped; no bare `runner.os-mix-` key | unit (contract) | `mix test test/scoria/ci_policy_contract_test.exs` | ❌ W0 (new asserts) | ⬜ pending |
| 23-XX | — | 1 | CACHE-02 (SC#2) | — / — | `build` job present, `needs: policy`, uploads artifact, no `services:` | unit (contract) | `mix test test/scoria/ci_policy_contract_test.exs` | ❌ W0 (new asserts) | ⬜ pending |
| 23-XX | — | 2 | CACHE-02 (SC#3) | — / — | Zero `Compiling N files` in `test` job after artifact restore | CI-log inspection | `gh run view <id> --log \| grep "Compiling"` (absent = pass) | ✅ (manual/CI) | ⬜ pending |
| 23-XX | — | 2 | SC#4 | — / — | No pinned command string moved out of byte-order | unit (contract) | quick run command (both contract files) | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*Task IDs finalized once PLAN.md files are written; map to the contract-test tasks and the artifact tar/restore tasks.*

---

## Wave 0 Requirements

- [ ] New test functions in `test/scoria/ci_policy_contract_test.exs`:
  - `cache keys include MIX_ENV segment to prevent dev/test collision` (CACHE-01 / SC#1)
  - `build job exists, needs policy, uploads artifact, has no services block` (CACHE-02 / SC#2)
  - artifact restore + `needs: build` chain assertions on the `test` job (SC#3 topology)
- [ ] No framework install — ExUnit + `SCORIA_LANE_CONTRACT_ONLY` infra already present

*Existing infrastructure covers SC#4 fully.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Zero downstream recompile (SC#3, make-or-break) | CACHE-02 | The proof is the absence of `Compiling N files` in a real GitHub Actions `test` job log — not reproducible in a pure unit test; depends on artifact mtime preservation on real runners | 1. Push branch, let CI run. 2. `gh run view <id> --log \| grep -A5 "Unpack compiled artifact" \| grep -i Compiling` → expect **no output**. 3. Local dry-run: `MIX_ENV=test mix compile`; `tar -czf /tmp/b.tgz _build/test deps`; `rm -rf _build/test deps`; `tar -xzf /tmp/b.tgz`; `MIX_ENV=test mix compile --warnings-as-errors` → expect no `Compiling`. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (new contract-test functions)
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s (local contract tests)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
