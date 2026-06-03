---
phase: 06
slug: integration-proof-supportjourney-alignment
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-30
retroactive: true
---

# Phase 06 — Validation Strategy

> Retroactive Nyquist validation for v2.15 integration proof (SupportJourney → connector register → fleet → drawer).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19 / Mix) |
| **Config file** | `mix.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/connectors/adoption_lane_test.exs --warnings-as-errors` |
| **Full suite command** | `MIX_ENV=test mix test test/scoria/connectors/adoption_lane_test.exs test/scoria/connectors/schema_test.exs test/scoria/connectors/invocation_test.exs test/mix/tasks/test.connector_test.exs --warnings-as-errors` |
| **Lane task command** | `MIX_ENV=test mix test.connector --warnings-as-errors` |
| **Estimated runtime** | ~1 second (adoption_lane only) |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **Before phase sign-off:** Full suite command green
- **CI path:** `mix test.connector --warnings-as-errors` (includes adoption_lane_test)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 06-retro-01 | — | 1 | CONN-LANE-03 | — | SupportJourney fixtures drive connector register | integration | `MIX_ENV=test mix test test/scoria/connectors/adoption_lane_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 06-retro-02 | — | 1 | CONN-LANE-03 | — | Fleet list surfaces connector_key + connector_label | integration | `MIX_ENV=test mix test test/scoria/connectors/adoption_lane_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 06-retro-03 | — | 1 | CONN-LANE-03 | — | Operator drawer evidence (health, status) | integration | `MIX_ENV=test mix test test/scoria/connectors/adoption_lane_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 06-retro-04 | — | 1 | CONN-LANE-03 | — | Proof runs under bounded connector lane task | unit | `MIX_ENV=test mix test test/mix/tasks/test.connector_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test stubs required.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All phase requirements have automated verification
- [x] Sampling continuity: adoption_lane_test runs in <2s
- [x] No watch-mode flags
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-30 (retroactive validate-phase)

---

## Validation Audit 2026-05-30

| Metric | Count |
|--------|-------|
| Gaps found | 0 (process artifacts only) |
| Resolved | 0 |
| Escalated | 0 |

**Evidence run:**

```
MIX_ENV=test mix test test/scoria/connectors/adoption_lane_test.exs --warnings-as-errors
# 1 test, 0 failures
```
