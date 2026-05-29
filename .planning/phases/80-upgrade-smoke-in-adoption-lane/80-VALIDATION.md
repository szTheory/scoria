---
phase: 80
slug: upgrade-smoke-in-adoption-lane
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-29
---

# Phase 80 — Validation Strategy

> Per-phase validation contract for HEX-UPGRADE-01 upgrade smoke.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `config/test.exs` (existing) |
| **Quick run command** | `MIX_ENV=test mix test --only host_upgrade` |
| **Full suite command** | `MIX_ENV=test mix test.adoption` |
| **Estimated runtime** | ~100–116s (upgrade module warm); ~165–175s (full adoption lane) |

---

## Sampling Rate

- **After every task commit:** `MIX_ENV=test mix compile --warnings-as-errors`
- **After 80-01:** `MIX_ENV=test mix test test/scoria/hex_consumer_contract_test.exs`
- **After 80-03:** `MIX_ENV=test mix test --only host_upgrade` then `MIX_ENV=test mix test.adoption`
- **Before `/gsd-verify-work`:** Full adoption lane green
- **Max feedback latency:** 180 seconds (240_000 after D-37 escalation on upgrade module only)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 80-01-01 | 01 | 1 | HEX-UPGRADE-01 | unit | `mix test test/scoria/hex_consumer_contract_test.exs` | ⬜ pending |
| 80-01-02 | 01 | 1 | HEX-UPGRADE-01 | unit | fixture stamp + fingerprint guard test | ⬜ pending |
| 80-02-01 | 02 | 2 | HEX-UPGRADE-01 | compile | `mix compile --warnings-as-errors` | ⬜ pending |
| 80-03-01 | 03 | 3 | HEX-UPGRADE-01 | integration | `mix test --only host_upgrade` | ⬜ pending |
| 80-03-02 | 03 | 3 | HEX-UPGRADE-01 | lane | `mix test.adoption` | ⬜ pending |
| 80-03-03 | 03 | 3 | HEX-UPGRADE-01 | contract | `mix test test/mix/tasks/test.adoption_test.exs` | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers phase requirements. Wave 1 creates committed baseline fixture (not Wave 0 test stubs).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| D-37 timeout escalation | HEX-UPGRADE-01 | Requires two consecutive CI >120s | Record CI timing; bump module tag to 240_000 if triggered |
| SCORIA_PRESERVE_HOST debug | DX | Opt-in env | `SCORIA_PRESERVE_HOST=1 mix test --only host_upgrade` after induced failure |
| Migration ordering latent proof | ROADMAP #4 | No migration delta at 0.1.0→HEAD today | Document in 80-VERIFICATION.md; activates on first post-0.1.0 migration |

---

## Validation Sign-Off

- [ ] All tasks have automated verify
- [ ] Sampling continuity maintained
- [ ] Feedback latency < 180s (upgrade module)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
