---
phase: 81
slug: post-publish-registry-gate
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-29
---

# Phase 81 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/hex_consumer_contract_test.exs --warnings-as-errors` |
| **Full suite command** | `SCORIA_REGISTRY_VERSION=0.1.0 mix scoria.post_publish_smoke` |
| **Estimated runtime** | ~90–180s per registry proof module (Postgres + phx.new) |

---

## Sampling Rate

- **After every task commit:** Run quick contract/unit command above
- **After plan 81-02:** Run `SCORIA_REGISTRY_VERSION=0.1.0 mix scoria.post_publish_smoke` when Hex 0.1.0 is indexed (maintainer machine or CI)
- **After plan 81-03:** Validate workflow YAML references and optional `ci_policy_contract_test` extension
- **Before `/gsd-verify-work`:** Post-publish workflow dry-run or documented manual attest checklist in `81-VERIFICATION.md`
- **Max feedback latency:** ~180s (module timeout)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 81-01-01 | 01 | 1 | HEX-REGISTRY-01 | T-81-01 | Pinned registry tuple, no `~> 0.1` in attest path | unit | `mix test test/scoria/hex_consumer_contract_test.exs` | ✅ | ⬜ pending |
| 81-01-02 | 01 | 1 | HEX-REGISTRY-01 | T-81-02 | Overlays sourced from deps tree not checkout | compile | `MIX_ENV=test mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 81-02-01 | 02 | 2 | HEX-REGISTRY-01 | T-81-03 | Exact 6-step registry proof order | integration | `mix test --only registry_proof` | ❌ W0 | ⬜ pending |
| 81-02-02 | 02 | 2 | HEX-REGISTRY-01 | T-81-04 | Upgrade uses registry bump not path | integration | `mix test --only registry_upgrade` | ❌ W0 | ⬜ pending |
| 81-02-03 | 02 | 2 | HEX-REGISTRY-01 | — | Mix task invokes proof modules | task | `mix help scoria.post_publish_smoke` | ❌ W0 | ⬜ pending |
| 81-03-01 | 03 | 3 | HEX-REGISTRY-01 | T-81-05 | Attest job needs publish-hex | workflow | Review `release-please.yml` job graph | ✅ | ⬜ pending |
| 81-03-02 | 03 | 3 | HEX-REGISTRY-01 | — | Gate map documents PR vs release | doc | `rg post-publish docs/operator_verification.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers phase requirements (HostAppProof harness, Postgres CI service, HexConsumerContract). Wave 0 adds new test modules and Mix task only — no new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| First live release attest on Hex | HEX-REGISTRY-01 #2 | Requires secrets + published version | Run release-please on test tag or `workflow_dispatch` with version |
| Semver upgrade leg | HEX-REGISTRY-01 #3 | Needs `0.1.1+` on Hex | Document latent at `0.1.0`; verify when second patch publishes |
| Registry index lag | HEX-REGISTRY-01 | External Hex CDN | Use `skip_index_wait: true` when chained after publish-hex |

---

## Phase Verification Checklist

- [ ] `mix scoria.post_publish_smoke` runs install → migrate → route+runtime overlays against pinned `hex: :scoria`
- [ ] `release-please.yml` fails when attest fails
- [ ] `hex-publish.yml` recovery includes same attest
- [ ] Operator gate map row added
- [ ] `81-VERIFICATION.md` documents latent upgrade at 0.1.0-only releases
