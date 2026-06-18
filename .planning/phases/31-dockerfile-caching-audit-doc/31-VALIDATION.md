---
phase: 31
slug: dockerfile-caching-audit-doc
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-18
---

# Phase 31 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built into Elixir/Mix) |
| **Config file** | `config/test.exs` |
| **Quick run command** | `mix test --no-start test/scoria/ci_policy_contract_test.exs` |
| **Full suite command** | `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs` |
| **Estimated runtime** | ~2 seconds (policy lane, `--no-start`, no DB, no app boot) |

---

## Sampling Rate

- **After every task commit:** Run `mix test --no-start test/scoria/ci_policy_contract_test.exs`
- **After every plan wave:** Run `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs`
- **Before `/gsd-verify-work`:** Full suite must be green + empirical Docker proof recorded in SUMMARY
- **Max feedback latency:** ~2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 31-01-01 | 01 | 1 | CACHE-01 | — | N/A | unit (policy lane) | `mix test --no-start test/scoria/ci_policy_contract_test.exs` | ✅ (append to existing) | ⬜ pending |
| 31-01-02 | 01 | 1 | CACHE-01 | — | N/A | unit (policy lane) | `mix test --no-start test/scoria/ci_policy_contract_test.exs` | ✅ (append to existing) | ⬜ pending |
| 31-01-03 | 01 | 1 | CACHE-01 | — | N/A | manual (local Docker) | `docker compose build --progress=plain web 2>&1 \| grep -nE 'mix deps\.get'` | N/A (one-time, record in SUMMARY) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

Map detail (from RESEARCH §"Phase Requirements → Test Map"):

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CACHE-01 (structural) | COPY order is lock → config → lib | unit (policy lane) | `mix test --no-start test/scoria/ci_policy_contract_test.exs` | ✅ (append to existing) |
| CACHE-01 (marker) | Boundary invariant comment present (`@layer_invariant_marker`) | unit (policy lane) | `mix test --no-start test/scoria/ci_policy_contract_test.exs` | ✅ (append to existing) |
| CACHE-01 (empirical) | No executing `mix deps.get` on CSS/HEEx touch | manual (local Docker) | `docker compose build --progress=plain web 2>&1 \| grep -nE 'mix deps\.get'` | N/A (one-time, record in SUMMARY) |

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* No new test file, no framework install, no shared fixture — the COPY-order + marker test appends to the existing `test/scoria/ci_policy_contract_test.exs` (already `async: true`, `--no-start`, `File.read!`-of-repo-files idiom). Reuse the existing private `index_of/2` helper (NOT `index_of!` — that does not exist).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| No executing `mix deps.get` step on a CSS/HEEx-only edit (cold `--build`) | CACHE-01 | Requires a real Docker daemon + BuildKit cache; cannot run in the daemon-free policy lane and is non-deterministic in CI (per-runner cache). One-time recorded evidence per D-04. | 1) `docker compose build web` (warm cache). 2) `touch assets/css/06-utilities.css lib/scoria_web/components/layouts/root.html.heex`. 3) `docker compose build --progress=plain web 2>&1 \| tee /tmp/scoria-cacheproof.log`. 4) `grep -nE 'mix deps\.get' /tmp/scoria-cacheproof.log`. **Pass =** the `mix deps.get` step appears only as a `CACHED` step (no executing download output). Paste the grepped line(s) + the `CACHED` markers into SUMMARY. |

*The static COPY-order test (D-08) is the automated, every-`mix test` guard for the structural precondition; the empirical proof is the complementary one-time runtime evidence — keep both, they are not redundant.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or are explicitly the one-time manual Docker proof
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (none — existing infra covers all)
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
