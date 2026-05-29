---
phase: 78
slug: hex-consumer-contract-foundation
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-29
---

# Phase 78 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` test alias / `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/hex_consumer_contract_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test.adoption` |
| **Estimated runtime** | ~120 seconds (consumer proof dominates) |

---

## Sampling Rate

- **After every task commit:** Run targeted file from Per-Task Verification Map
- **After every plan wave:** Run wave-specific command from RESEARCH.md §Validation Architecture
- **Before `/gsd-verify-work`:** `mix test.adoption` must be green
- **Max feedback latency:** 180 seconds (consumer proof timeout)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 78-01-01 | 01 | 1 | DOCS-HEX-01† | — | SSOT module exposes version + dep snippets | unit | `MIX_ENV=test mix test test/scoria/hex_consumer_contract_test.exs` | ❌ W0 | ⬜ pending |
| 78-01-02 | 01 | 1 | DOCS-HEX-01† | — | README active dep matches contract | drift | `MIX_ENV=test mix test test/scoria/package_surface_test.exs` | ✅ | ⬜ pending |
| 78-02-01 | 02 | 2 | DOCS-HEX-01† | T-78-01 | Unpack cache returns valid artifact root | integration | `MIX_ENV=test mix test test/scoria/package_surface_test.exs` | ✅ | ⬜ pending |
| 78-03-01 | 03 | 3 | HEX-CONSUMER-01† | T-78-02 | Tarball dep, route-only proof | integration | `MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs` | ✅ | ⬜ pending |
| 78-03-02 | 03 | 3 | HEX-CONSUMER-01† | — | Adoption lane green | lane | `MIX_ENV=test mix test.adoption` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `lib/scoria/hex_consumer_contract.ex` — SSOT + unpack cache
- [ ] `test/scoria/hex_consumer_contract_test.exs` — version/snippet guards
- [ ] `Generator` required `dep_mode` keyword
- [ ] `Runner.run_route_proof!/1` route-only filter
- [ ] CI `SCORIA_HEX_UNPACK_ROOT` in `ci-verify.yml`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CI release_preview → adoption reuse | HEX-CONSUMER-01† | Full CI job | Run `MIX_ENV=dev mix scoria.release_preview && SCORIA_HEX_UNPACK_ROOT=tmp/scoria-release-preview mix test.adoption` locally |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
