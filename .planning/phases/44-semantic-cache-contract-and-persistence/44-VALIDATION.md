---
phase: 44
slug: semantic-cache-contract-and-persistence
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
---

# Phase 44 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/scoria/semantic_cache_test.exs test/scoria/runtime/semantic_fast_path_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~45-90 seconds for quick lane, longer for full suite |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scoria/semantic_cache_test.exs test/scoria/runtime/semantic_fast_path_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 44-01-01 | 01 | 1 | FAST-02 | T-44-01-01 | Entry rows cannot be written without tenant partition fields | unit + migration | `mix test test/scoria/semantic_cache_test.exs` | ✅ | ⬜ pending |
| 44-01-02 | 01 | 1 | FAST-02 | T-44-01-02 | Event rows remain append-only and linked to entry lineage | unit | `mix test test/scoria/semantic_cache_test.exs` | ✅ | ⬜ pending |
| 44-02-01 | 02 | 2 | FAST-01 | T-44-02-01 | Only explicit semantic lanes become eligible for fast-path evaluation | unit | `mix test test/scoria/semantic_cache/lane_test.exs test/scoria/semantic_cache/eligibility_test.exs` | ❌ W0 | ⬜ pending |
| 44-02-02 | 02 | 2 | SAFE-01 | T-44-02-02 | Approval-sensitive and personalized-tool-backed requests yield stable bypass codes | unit | `mix test test/scoria/semantic_cache/eligibility_test.exs` | ❌ W0 | ⬜ pending |
| 44-03-01 | 03 | 3 | FAST-01 | T-44-03-01 | Runtime lookup attempts only occur for explicit safe lanes | integration | `mix test test/scoria/runtime/semantic_fast_path_test.exs` | ❌ W0 | ⬜ pending |
| 44-03-02 | 03 | 3 | SAFE-01 | T-44-03-02 | Misses and bypasses fall through without mutating workflow truth | integration | `mix test test/scoria/runtime/semantic_fast_path_test.exs` | ❌ W0 | ⬜ pending |
| 44-03-03 | 03 | 3 | FAST-02 | T-44-03-03 | Reuse and write-back preserve tenant/actor scope and lineage refs | integration | `mix test test/scoria/runtime/semantic_fast_path_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/scoria/semantic_cache_test.exs` — semantic cache persistence and service coverage
- [ ] `test/scoria/semantic_cache/lane_test.exs` — lane DSL/behaviour coverage
- [ ] `test/scoria/semantic_cache/eligibility_test.exs` — reason-code and scope derivation coverage
- [ ] `test/scoria/runtime/semantic_fast_path_test.exs` — runtime fallback and write-back coverage

---

## Manual-Only Verifications

All Phase 44 behaviors should be automatable in ExUnit. No manual-only verification is expected.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s for quick lane
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
