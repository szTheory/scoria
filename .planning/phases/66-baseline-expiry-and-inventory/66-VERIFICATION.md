---
phase: 66-baseline-expiry-and-inventory
status: passed
verified: 2026-05-27
---

# Phase 66 Verification Report

## Must-Haves Verified

| Requirement | Status | Evidence |
|-------------|--------|----------|
| WARN-03 baseline expiry enforcement | PASS | `Scoria.WarningBaseline`, `mix scoria.warning_baseline.check`, CI policy job |
| WARN-04 warning inventory | PASS | `Scoria.WarningInventory`, `mix scoria.warning_inventory`, operator docs |
| Accepted rows past expiry fail check | PASS | expired fixture test + mix task exit 1 |
| Blank Owner/Expires fail as invalid | PASS | invalid_blank_owner fixture test |
| Parser scans Accepted section only | PASS | resolves_section_trap fixture test |
| Deterministic --date tests | PASS | all fixture tests use explicit dates |
| CI policy job without Postgres | PASS | ci_policy_contract_test postgres isolation |
| Baseline check before compile WAE | PASS | ci_policy_contract_test ordering |
| test job needs: policy | PASS | ci.yml + contract test |
| Closeout chain preserved | PASS | verification_lanes_test + ci_policy_contract_test |
| Inventory capture mode (no WAE gate) | PASS | mix task runs compile+test without --warnings-as-errors |
| Cluster registry hybrid match | PASS | cluster_test.exs for 7 patterns |
| --write artifacts layout | PASS | task writes baseline JSON + WARNING-INVENTORY.md + gitignored tmp |
| Logger/SQL noise excluded | PASS | cluster_test exclusion test |

## Automated Checks

```
MIX_ENV=test mix test test/scoria/warning_baseline_test.exs test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/warning_inventory/cluster_test.exs
MIX_ENV=test mix scoria.warning_baseline.check
```

All passed.

## Human Verification

None required — all acceptance criteria are automated.

## Gaps

None.
