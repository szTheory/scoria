---
phase: 27-ci-determinism-flake-elimination
plan: "01"
subsystem: ci
tags: [ci, flake-elimination, postgres, contract-test, maintainers]
dependency_graph:
  requires: []
  provides:
    - Postgres host port 5432 in all 5 CI Postgres job blocks (FLAKE-01 fix)
    - TEMP diagnostic step removed from e2e job (FLAKE-02 fix)
    - Retry-vs-fix policy documented in MAINTAINERS.md (FLAKE-03)
    - 3 durable contract guards in ci_policy_contract_test.exs (D-12, FLAKE-02, D-07)
  affects:
    - .github/workflows/ci.yml
    - .github/workflows/ci-verify.yml
    - docs/MAINTAINERS.md
    - test/scoria/ci_policy_contract_test.exs
tech_stack:
  added: []
  patterns:
    - GitHub Actions service container fixed host port below ephemeral range
    - ExUnit contract tests via File.read! + Regex (no YAML parser)
    - Zero-retry CI policy with documented infra-transient exception class
key_files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - .github/workflows/ci-verify.yml
    - docs/MAINTAINERS.md
    - test/scoria/ci_policy_contract_test.exs
decisions:
  - "D-01: Replace 55432:5432 with 5432:5432 in all 5 CI Postgres job blocks; port 55432 is in Linux ephemeral range 32768-60999, port 5432 is immune"
  - "D-06: Delete TEMP diagnose runs visibility step from ci.yml e2e job — clear-cut, no gray area"
  - "D-11: Add flake policy subsection to MAINTAINERS.md as ### under ## CI gate map; retarget header comments from operator_verification.md to MAINTAINERS.md"
  - "D-12: Add ephemeral-port ban contract test (>= 5 non-empty guard, host_port < 32768 per binding) — root-cause-faithful"
  - "D-07: Add no-retry-on-test-workflows contract assertion (continue-on-error + nick-fields/retry + Wandalen/wretry); D-08 carve-out files excluded"
metrics:
  duration: "5 minutes"
  completed_date: "2026-06-17"
  tasks_completed: 3
  files_modified: 4
---

# Phase 27 Plan 01: CI Determinism & Flake Elimination Summary

Structural fix for two known CI flakes (FLAKE-01 Postgres host-port ephemeral range collision, FLAKE-02 leftover TEMP diagnostic step) plus a documented zero-retry policy with three durable contract guards in `ci_policy_contract_test.exs`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | FLAKE-01+02: fix Postgres host port + delete TEMP step | 5277e90 | ci.yml, ci-verify.yml |
| 2 | FLAKE-03: retry-vs-fix policy in MAINTAINERS.md | cf7f88d | docs/MAINTAINERS.md |
| 3 | Durable contract guards (TDD) | 4b884c8 | test/scoria/ci_policy_contract_test.exs |

## What Was Done

### Task 1 — FLAKE-01 + FLAKE-02

**FLAKE-01:** Changed `- 55432:5432` to `- 5432:5432` in all 5 Postgres job blocks across both workflow files. Port 55432 falls in the Linux kernel ephemeral port range (32768–60999); port 5432 does not. Also updated all 5 `SCORIA_DB_PORT: 55432` env entries to `SCORIA_DB_PORT: 5432`. Local `SCORIA_DB_PORT=55432` references in MAINTAINERS.md, verification_lanes.ex, and pgvector.bootstrap.ex were intentionally left unchanged (D-05; CI=5432, local=55432 coexist cleanly via config env fallback).

**FLAKE-02:** Deleted the `TEMP diagnose runs visibility` step (12 lines: 3-line comment block + the step body) from the `e2e` job in `ci.yml`. The step was a leftover skeleton diagnostic that dumped DB row counts and server renders into CI logs.

**D-11 (discretionary):** Retargeted the header comment in both workflow files from `docs/operator_verification.md` to `docs/MAINTAINERS.md` since the flake policy now lives there.

**full-suite integrity:** The `full-suite` env block still has NO `SCORIA_DB_NAME` (intentional for per-shard DB isolation via `MIX_TEST_PARTITION`).

### Task 2 — FLAKE-03 Flake Policy

Inserted a new `### Flake policy: retry vs fix {#flake-policy}` subsection into `docs/MAINTAINERS.md` between the last `## CI gate map` bullet (line 88) and `## Hex release & recovery` (line 90 before insertion). The subsection covers:

- Zero-retry default (D-07)
- Banned patterns: `continue-on-error: true`, job-level `retry:`, `nick-fields/retry`, `Wandalen/wretry.action`
- Carve-out: `release-please.yml`, `hex-publish.yml`, `release-pr-automerge.yml` polling loops are control-flow waits, not test retries (D-08)
- One allowed exception class for infra-transient steps with 5 conditions (D-09)
- Fix-don't-retry: `@tag :flaky` + tracking issue, `--repeat-until-failure` for reproducing not masking (D-10)
- Durable enforcement note citing FLAKE-01 root cause (run 27508317719), CI now on 5432, local stays 55432

### Task 3 — Contract Guards (TDD)

Extended `test/scoria/ci_policy_contract_test.exs` from 42 to 45 tests by adding 3 new test blocks immediately after the existing `"postgres service is configured only for test, knowledge, and connector jobs"` test.

Also added `@ephemeral_range_min 32_768` module attribute for readability.

**New tests:**
1. `"no CI Postgres job binds a host port in the ephemeral range (>= 32768)"` — reads both workflow files, calls `job_blocks/1` on each, filters by `body =~ "postgres:"`, asserts `map_size >= 5` (non-empty guard per D-12/Pitfall 3), then for every `- NNNN:5432` / `- NNNN/tcp` binding asserts `host_port < 32_768`
2. `"e2e job in ci.yml has no TEMP diagnostic step"` — `refute ci_entry =~ "TEMP diagnose"`
3. `"no test workflow step uses continue-on-error or a retry-action"` — refutes `continue-on-error`, `nick-fields/retry`, `Wandalen/wretry` in both `@ci_verify` and `@ci_entry` only (D-08 carve-out files not asserted)

The existing `job_blocks/1` helper was reused (not redefined). No YAML parser added.

## Verification Results

```
mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs
48 tests, 0 failures
```

- ci_policy_contract_test.exs: 45 tests (was 42)
- verification_lanes_test.exs: 3 tests
- All pre-existing 42 tests still pass (no existing assertion edited)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — this plan makes no runtime UI changes and introduces no stub values.

## Threat Flags

No new security-relevant surface introduced. The Postgres port change is host-side CI service binding only on ephemeral, trusted, single-tenant GitHub runners. The contract test reads local files only. STRIDE register: T-27-01 and T-27-02 mitigations implemented (D-12 + D-07 contract guards). T-27-04 mitigated (TEMP step deleted).

## Self-Check: PASSED

- FOUND: `.planning/phases/27-ci-determinism-flake-elimination/27-01-SUMMARY.md`
- FOUND: commit 5277e90 (Task 1 — workflow port fixes)
- FOUND: commit cf7f88d (Task 2 — MAINTAINERS.md flake policy)
- FOUND: commit 4b884c8 (Task 3 — contract guard tests)
- All 4 key files created/modified exist at expected paths
- Test suite: 48 tests, 0 failures, warnings-as-errors clean
