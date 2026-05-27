---
phase: 66-baseline-expiry-and-inventory
plan: 01
subsystem: testing
tags: [elixir, mix, warnings, baseline, ci]

requires: []
provides:
  - Scoria.WarningBaseline parser API
  - mix scoria.warning_baseline.check maintainer task
affects: [66-02, 66-03, phase-67-ratchet]

tech-stack:
  added: []
  patterns: [markdown policy + code enforcement SSOT]

key-files:
  created:
    - lib/scoria/warning_baseline.ex
    - lib/mix/tasks/scoria.warning_baseline.check.ex
    - test/scoria/warning_baseline_test.exs
    - test/fixtures/warning_baseline/
  modified: []

key-decisions:
  - "Accepted debt parsed only from ## Accepted Warning Debt section"
  - "Expiry valid through end of UTC expiry day"

patterns-established:
  - "WarningBaseline.load/1 with injectable :date for deterministic tests"

requirements-completed: [WARN-03]

duration: 15min
completed: 2026-05-27
---

# Phase 66 Plan 01 Summary

**Executable WARN-03 baseline expiry enforcement via Scoria.WarningBaseline and mix scoria.warning_baseline.check.**

## Accomplishments
- Implemented parser with accepted/invalid/expired row APIs
- Added Mix task with remediation UX and --file/--date flags
- Fixture-backed ExUnit coverage for valid, expired, invalid, and resolved-section traps

## Task Commits
1. **Task 66-01-01** - `1ffb840`
2. **Task 66-01-02** - `d879857`

## Self-Check: PASSED
- Key files exist on disk
- `MIX_ENV=test mix test test/scoria/warning_baseline_test.exs` passes
- Production baseline check passes for current date
