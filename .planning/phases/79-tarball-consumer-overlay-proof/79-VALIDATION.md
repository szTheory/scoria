---
phase: 79
slug: tarball-consumer-overlay-proof
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-29
---

# Phase 79 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` test alias / `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test --only host_proof` |
| **Full suite command** | `MIX_ENV=test mix test.adoption` |
| **Estimated runtime** | ~60–90s consumer (warm full overlay); ~120s adoption lane p95 |
| **Hard ceiling** | `@moduletag timeout: 180_000` on `HostAppConsumerProofTest` |
| **Escalation** | If CI >120s on two consecutive runs → bump to 240_000 (D-37) |

---

## Sampling Rate

- **After every task commit:** Run targeted file from Per-Task Verification Map
- **After plan 79-01:** `MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs`
- **After plan 79-02:** Induced failure locally; verify preserve + snapshot paths
- **After plan 79-03:** CI parity command + closeout contract tests
- **Before `/gsd-verify-work`:** `mix test.adoption` must be green
- **Max feedback latency:** 180 seconds (240_000 after D-37 escalation)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 79-01-01 | 01 | 1 | HEX-CONSUMER-01 | — | Consumer uses `run_full_proof!/1` | integration | `MIX_ENV=test mix test test/scoria/host_app_consumer_proof_test.exs` | ✅ | ⬜ pending |
| 79-01-02 | 01 | 1 | HEX-CONSUMER-01 | — | Derived seven-step contract from `host.overlay_tests` | integration | same | ✅ | ⬜ pending |
| 79-01-03 | 01 | 1 | HEX-CONSUMER-01 | — | `:host_proof` tag for local iteration | discoverability | `MIX_ENV=test mix test --only host_proof` | ❌ W0 | ⬜ pending |
| 79-02-01 | 02 | 2 | HEX-CONSUMER-01 | T-79-01 | Enhanced raise includes triage fields | DX | Induced failure; inspect raise output | ❌ W0 | ⬜ pending |
| 79-02-02 | 02 | 2 | HEX-CONSUMER-01 | — | `SCORIA_PRESERVE_HOST=1` skips cleanup | DX | `SCORIA_PRESERVE_HOST=1 MIX_ENV=test mix test --only host_proof` | ❌ W0 | ⬜ pending |
| 79-02-03 | 02 | 2 | HEX-CONSUMER-01 | — | Failure snapshot under workspace `tmp/` | DX | Induced failure → `tmp/scoria-host-proof-last-failure/MANIFEST.txt` | ❌ W0 | ⬜ pending |
| 79-03-01 | 03 | 3 | HEX-CONSUMER-01 | — | Adoption lane green with full overlay | lane | `MIX_ENV=test mix test.adoption` | ✅ | ✅ green |
| 79-03-02 | 03 | 3 | HEX-CONSUMER-01 | — | Closeout order unchanged | contract | `MIX_ENV=test mix test test/scoria/verification_lanes_test.exs` | ✅ | ✅ green |
| 79-03-03 | 03 | 3 | HEX-CONSUMER-01 | — | CI artifact on failure | CI | GHA upload after failed adoption | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Consumer test uses `run_full_proof!/1` with derived step assertion
- [x] `@moduletag :host_proof`
- [x] Enhanced `Runner` raise (D-39 fields + nested FAIL extract)
- [x] `SCORIA_PRESERVE_HOST` in Generator cleanup
- [x] Host map includes `working_root` / `unpack_root` for snapshot
- [x] Failure snapshot → `tmp/scoria-host-proof-last-failure/`
- [x] CI `upload-artifact` on failure
- [x] Closeout ceremony artifacts (79-VERIFICATION, ledger reconciliation)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CI release_preview → adoption reuse | HEX-CONSUMER-01 | Full CI job | `MIX_ENV=dev mix scoria.release_preview && SCORIA_HEX_UNPACK_ROOT=tmp/scoria-release-preview MIX_ENV=test mix test.adoption` |
| CI artifact upload on failure | HEX-CONSUMER-01 | GHA-only | Induce adoption failure in CI; confirm artifact `scoria-host-proof-last-failure` |
| Preserve host disk inspection | HEX-CONSUMER-01 | Operator DX | `SCORIA_PRESERVE_HOST=1 mix test --only host_proof`; verify `IO.warn` path |

---

## Failure Triage (flake note)

If CI consumer proof exceeds **120s on two consecutive runs**, bump `@moduletag timeout` to **240_000** (not 300/420), update this file, and note in `79-VERIFICATION.md`. Gallery 300s lane is not precedent (D-37).

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s (or documented 240s escalation)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** signed off 2026-05-29 (79-VERIFICATION.md passed)
