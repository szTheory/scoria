---
phase: 82-docs-truth-milestone-closeout
plan: 01
subsystem: docs
tags: [hex-consumer, drift-guards, adopter-docs, ci-policy]

requires:
  - phase: 78-hex-consumer-contract-foundation
    provides: HexConsumerContract SSOT
  - phase: 79-tarball-consumer-overlay-proof
    provides: Tarball consumer proof vocabulary
  - phase: 81-post-publish-registry-gate
    provides: post_publish_smoke maintainer workflow
provides:
  - HexConsumerContract.adopter_doc_surfaces/0 for README + adoption_lanes
  - adoption_surface_test macro drift guards
  - ci_policy_contract_test v2.10 gate map topology pins
  - Honest DOCS-HEX-01 Partial ledger until 82-02
affects: [82-02, 82-03]

key-files:
  created: []
  modified:
    - lib/scoria/hex_consumer_contract.ex
    - lib/scoria/adopter_doc_contract.ex
    - README.md
    - docs/adoption_lanes.md
    - docs/operator_verification.md
    - test/scoria/adoption_surface_test.exs
    - test/scoria/ci_policy_contract_test.exs
    - .planning/REQUIREMENTS.md

requirements-completed: []

duration: 15min
completed: 2026-05-30
---

# Phase 82 Plan 01: DOCS-HEX-01 Drift Guards Summary

**Executable adopter/maintainer doc pins via `adopter_doc_surfaces/0`, prose alignment, and honest REQUIREMENTS ledger (Partial until 82-02).**

## Accomplishments

- Added `HexConsumerContract.adopter_doc_surfaces/0` scoped to README + adoption_lanes (D-96)
- Extended `AdopterDocContract.readme_maintainer_command_refutes/0` with `mix scoria.post_publish_smoke` (D-100)
- README Verification adopter-scoped; removed `SCORIA_HEX_UNPACK_ROOT` leakage (D-91)
- adoption_lanes tarball closeout note with operator guide link (D-92)
- operator_verification gate map upgrade sequence bullets (D-93, D-104)
- Macro drift tests in adoption_surface_test + gate map test in ci_policy_contract_test
- DOCS-HEX-01 unchecked/Partial in REQUIREMENTS.md (D-112)

## Self-Check: PASSED

Combined gate: 61 tests, 0 failures.

```bash
MIX_ENV=test mix test --warnings-as-errors \
  test/scoria/hex_consumer_contract_test.exs \
  test/scoria/adoption_surface_test.exs \
  test/scoria/ci_policy_contract_test.exs \
  test/scoria/support_journey_source_test.exs
```

## Deviations

None.
