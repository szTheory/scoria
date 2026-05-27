---
phase: 63-manifest-check-fingerprint-hardening
plan: 03
subsystem: install
tags: [docs, integration-tests, operator-guide]

requires:
  - phase: 63-02
    provides: Report manifest output and mix help
provides:
  - Operator Check vs apply drift detection subsection
  - Adoption doc pins and install check contract tests
affects: []

key-files:
  modified:
    - docs/operator_verification.md
    - docs/adoption_lanes.md
    - test/scoria/adoption_surface_test.exs
    - test/mix/tasks/scoria.install_check_test.exs

requirements-completed: [INST-07]

completed: 2026-05-27
---

# Phase 63 Plan 03 Summary

**Documented check vs apply fingerprint semantics for operators and locked them with integration tests.**

## Accomplishments

- Added `### Check vs apply drift detection` to operator verification guide
- Cross-linked from adoption lanes
- Tests prove tampered manifest and absent manifest do not change check tri-state

## Self-Check: PASSED

- 38 related tests green including install_check, adoption_surface, mode_equivalence
