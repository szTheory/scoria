---
phase: 57-warning-and-ci-trust
plan: 01
subsystem: warnings
tags: [warning-policy, release-preview, baseline]
requirements-completed: [WARN-01, WARN-02]
duration: 15min
completed: 2026-05-27
---

# Phase 57 Plan 01 Summary

Closed release-preview warning debt and established scoped warning-baseline ownership.

## Accomplishments

- Ensured `mix scoria.release_preview` enforces docs warnings as errors and passes cleanly.
- Added explicit warning-baseline ledger with owner and expiry fields for accepted non-canonical debt.
- Fixed docs/type warning contributors by aligning source docs/type exports with publish docs checks.

## Evidence

- `MIX_ENV=dev mix scoria.release_preview` (pass)
- `MIX_ENV=test mix compile --warnings-as-errors` (pass)

## Files

- `lib/mix/tasks/scoria.release_preview.ex`
- `lib/scoria/knowledge/source.ex`
- `.planning/WARNING-BASELINE.md`
