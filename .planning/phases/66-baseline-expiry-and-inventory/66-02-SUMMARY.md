---
phase: 66-baseline-expiry-and-inventory
plan: 02
subsystem: infra
tags: [github-actions, ci, warnings, contract-tests]

requires:
  - phase: 66-01
    provides: mix scoria.warning_baseline.check
provides:
  - CI policy job split
  - ci_policy_contract_test.exs
affects: [phase-68, phase-69]

tech-stack:
  added: []
  patterns: [policy job before Postgres closeout]

key-files:
  created:
    - test/scoria/ci_policy_contract_test.exs
  modified:
    - .github/workflows/ci.yml
    - .planning/ROADMAP.md

key-decisions:
  - "Baseline check runs in Postgres-free policy job before compile WAE"
  - "Test job preserves closeout chain with needs: policy"

requirements-completed: [WARN-03]

duration: 10min
completed: 2026-05-27
---

# Phase 66 Plan 02 Summary

**WARN-03 wired into GitHub Actions via policy/test job split with contract-tested ordering.**

## Accomplishments
- Split ci.yml into policy and test jobs
- Moved compile WAE and lane-contract tests to policy job
- Added CI policy contract tests and fixed ROADMAP phase header format

## Task Commits
1. **Task 66-02-01** - `ab76b0c`
2. **Task 66-02-02** - `59ce425`

## Self-Check: PASSED
- ci.yml contains policy job with baseline check before compile WAE
- Contract tests pass with verification_lanes_test.exs
