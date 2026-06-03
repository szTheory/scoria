---
phase: 05
slug: lane-contract-mix-task
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-30
retroactive: true
---

# Phase 05 — Validation Strategy

> Retroactive Nyquist validation for v2.15 lane contract + `mix test.connector` (no prior GSD execute-phase artifacts).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19 / Mix) |
| **Config file** | `mix.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/scoria/verification_lanes_test.exs:55 test/mix/tasks/test.connector_test.exs --warnings-as-errors` |
| **Full suite command** | `MIX_ENV=test mix test test/scoria/connectors/adoption_lane_test.exs test/scoria/connectors/schema_test.exs test/scoria/connectors/invocation_test.exs test/mix/tasks/test.connector_test.exs --warnings-as-errors` |
| **Lane task command** | `MIX_ENV=test mix test.connector --warnings-as-errors` |
| **Estimated runtime** | ~2 seconds (bounded subset) |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **Before phase sign-off:** Full suite command green
- **CI path:** `mix test.connector --warnings-as-errors` after adoption + knowledge WAE

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-retro-01 | — | 1 | CONN-LANE-01 | — | `:connector` advisory; not in closeout; command + prerequisites | unit | `MIX_ENV=test mix test test/scoria/verification_lanes_test.exs:55` | ✅ | ✅ green |
| 05-retro-02 | — | 1 | CONN-LANE-02 | — | Bounded four-file subset; task discoverable | unit | `MIX_ENV=test mix test test/mix/tasks/test.connector_test.exs` | ✅ | ✅ green |
| 05-retro-03 | — | 1 | CONN-LANE-02 | — | Bounded connector tests execute green | integration | `MIX_ENV=test mix test test/scoria/connectors/adoption_lane_test.exs test/scoria/connectors/schema_test.exs test/scoria/connectors/invocation_test.exs test/mix/tasks/test.connector_test.exs --warnings-as-errors` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test stubs required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Full `mix test.connector` on dirty local DB | CONN-LANE-02 | `migrate_core!()` in task can fail when core schema partially migrated locally; CI runs full ecto migrate first | Run `mix ecto.reset` or full migrate, then `mix test.connector --warnings-as-errors` |

---

## Validation Sign-Off

- [x] All phase requirements have automated verification (contract + bounded subset)
- [x] Sampling continuity: contract tests are fast (<2s)
- [x] No watch-mode flags
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-30 (retroactive validate-phase)

---

## Validation Audit 2026-05-30

| Metric | Count |
|--------|-------|
| Gaps found | 0 (process artifacts only) |
| Resolved | 0 |
| Escalated | 1 (local lane task migrate — manual-only) |

**Evidence run:**

```
MIX_ENV=test mix test test/scoria/verification_lanes_test.exs:55 test/mix/tasks/test.connector_test.exs --warnings-as-errors
# 2 tests, 0 failures

MIX_ENV=test mix test test/scoria/connectors/adoption_lane_test.exs test/scoria/connectors/schema_test.exs test/scoria/connectors/invocation_test.exs test/mix/tasks/test.connector_test.exs --warnings-as-errors
# green
```
