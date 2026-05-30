---
phase: 07
slug: docs-drift-guards-ci-wiring
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-30
retroactive: true
---

# Phase 07 — Validation Strategy

> Retroactive Nyquist validation for v2.15 docs truth, drift guards, and PR CI WAE wiring (no prior GSD execute-phase artifacts).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19 / Mix) |
| **Config file** | `mix.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/support_journey_source_test.exs test/scoria/ci_policy_contract_test.exs:216 test/scoria/ci_policy_contract_test.exs:252 --warnings-as-errors` |
| **Full suite command** | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/support_journey_source_test.exs test/scoria/ci_policy_contract_test.exs --warnings-as-errors` |
| **Policy lane command** | `MIX_ENV=test mix test.policy --warnings-as-errors` |
| **Estimated runtime** | ~1 second (phase slice) |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **Before phase sign-off:** Full suite command green
- **CI path:** `mix test.connector --warnings-as-errors` after knowledge WAE; policy contract tests in policy job

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-retro-01 | — | 1 | CONN-DOCS-01 | — | `adoption_lanes.md` + `connector_adoption.md` name `mix test.connector` | unit | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/support_journey_source_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 07-retro-02 | — | 1 | CONN-DOCS-02 | — | SupportJourney SSOT pins connector command + boundary wording | unit | `MIX_ENV=test mix test test/scoria/support_journey_source_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 07-retro-03 | — | 1 | CONN-DOCS-02 | — | `adoption_lanes.md` pins connector lane + embedded-boundary link | unit | `MIX_ENV=test mix test test/scoria/adoption_surface_test.exs:102 --warnings-as-errors` | ✅ | ✅ green |
| 07-retro-04 | — | 1 | CONN-CI-01 | — | CI runs connector WAE after knowledge, before gallery | unit | `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs:216 --warnings-as-errors` | ✅ | ✅ green |
| 07-retro-05 | — | 1 | CONN-CI-01 | — | `MAINTAINERS.md` gate map includes connector lane row | unit | `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs:252 --warnings-as-errors` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. One drift guard assertion added for `adoption_lanes.md` embedded-boundary link (audit tech-debt closure).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `support_journey_source_test` in policy lane-contract WAE bundle | CONN-DOCS-02 | Test runs in full WAE/gallery lane, not policy fail-cheap bundle — connector doc pins fail later in CI | Optional: add to policy job bundle for fail-cheap; current coverage is green in connector + adoption lanes |

---

## Validation Sign-Off

- [x] All phase requirements have automated verification
- [x] Sampling continuity: phase slice runs in <2s
- [x] No watch-mode flags
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-30 (retroactive validate-phase)

---

## Validation Audit 2026-05-30

| Metric | Count |
|--------|-------|
| Gaps found | 1 (adoption_lanes boundary link unpinned) |
| Resolved | 1 |
| Escalated | 1 (policy WAE bundle placement — manual-only) |

**Evidence run:**

```
MIX_ENV=test mix test test/scoria/adoption_surface_test.exs test/scoria/support_journey_source_test.exs test/scoria/ci_policy_contract_test.exs --warnings-as-errors
# 53 tests, 0 failures
```
