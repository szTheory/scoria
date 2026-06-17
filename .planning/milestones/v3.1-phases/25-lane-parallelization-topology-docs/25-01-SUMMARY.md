---
phase: 25-lane-parallelization-topology-docs
plan: "01"
subsystem: ci-cd
tags: [ci, parallelization, contract-tests, yaml, github-actions]
dependency_graph:
  requires: []
  provides: [parallel-ci-topology, verify-summary-fan-in, contract-tests-parallel-shape]
  affects: [.github/workflows/ci-verify.yml, .github/workflows/ci.yml, test/scoria/ci_policy_contract_test.exs, test/scoria/verification_lanes_test.exs, docs/MAINTAINERS.md]
tech_stack:
  added: []
  patterns: [parallel-github-actions-jobs, name-agnostic-join-fan-in, job-body-map-parser]
key_files:
  created: []
  modified:
    - .github/workflows/ci-verify.yml
    - .github/workflows/ci.yml
    - test/scoria/ci_policy_contract_test.exs
    - test/scoria/verification_lanes_test.exs
    - docs/MAINTAINERS.md
decisions:
  - "gallery tail step (mix scoria.test.support_copilot) stays inside connector: as a sequential step, not a separate top-level job (D-04 discretion + Pitfall 3)"
  - "job_blocks/1 uses ~r/^  ([\w-]+):/m regex to parse top-level jobs; slices body by finding next job marker or EOF"
  - "test: remains the first non-policy/build job in YAML byte-order, preserving split_jobs/1 semantics"
  - "WR-01 fix: add env: MIX_ENV: test to policy: job; do NOT change the cache key string"
metrics:
  duration: "6 minutes"
  completed_date: "2026-06-15"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 5
---

# Phase 25 Plan 01: Lane Parallelization + Topology Docs Summary

**One-liner:** Parallel GitHub Actions topology with four sibling jobs (`test`, `ratchet`, `knowledge`, `connector`) each `needs: build`, gated by a name-agnostic `verify-summary` fan-in that treats skipped as failure — contract test suite refactored from byte-order to parallel-shape assertions with derived fan-in completeness guard.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Restructure ci-verify.yml into parallel sibling jobs + verify-summary fan-in; fold WR-01/WR-02 | 84103dc | .github/workflows/ci-verify.yml, .github/workflows/ci.yml |
| 2 | Refactor ci_policy_contract_test.exs to parallel-shape + derived fan-in completeness; fold WR-03 | 5cb9613 | test/scoria/ci_policy_contract_test.exs, docs/MAINTAINERS.md |
| 3 | Split verification_lanes_test.exs "ci lane ordering" into intra-vs-cross asserts | f418f64 | test/scoria/verification_lanes_test.exs |

## What Was Built

### Task 1: ci-verify.yml restructure

Rewrote the serial three-job topology (`policy → build → test`) into seven jobs:
- `policy`: unchanged except WR-01 addition of `env: MIX_ENV: test`
- `build`: unchanged (compiles once, uploads artifact)
- `test`: trimmed to closeout chain + semantic + full-suite WAE; DB-prep marker added
- `ratchet`: new parallel job, `needs: build`, NO `services:`, NO DB-prep; single step: `MIX_ENV=test mix test --WAE tmp_preflight_test.exs`
- `knowledge`: new parallel job, `needs: build`, Postgres services + DB-prep, `mix test.knowledge --WAE`
- `connector`: new parallel job, `needs: build`, Postgres services + DB-prep, `mix test.connector --WAE` + gallery tail step
- `verify-summary`: `if: always()`, `needs: [policy, build, test, ratchet, knowledge, connector]`, name-agnostic `join(needs.*.result)` bash loop that exits 1 on any result != "success"

WR-01 folded: `env: MIX_ENV: test` added to `policy:` job so compile matches the `-test-mix-` cache key.
WR-02 folded: `ci.yml` header comment updated from "Two-job topology" to "Parallel topology".

### Task 2: ci_policy_contract_test.exs refactor

Added `job_blocks/1` private helper alongside `split_jobs/1`. Kept `split_jobs/1` unchanged.

Rewrote 4 cross-job assertions from byte-order to parallel-shape using `job_blocks`:
1. "test job runs semantic lane..." — scoped intra-`test:` ordering; ratchet asserted as parallel job with `needs: build`
2. "test job runs full suite WAE..." — kept intra-`test:` ordering; knowledge asserted as parallel job
3. "connector lane is a parallel job..." — connector body asserted to have `needs: build` and `connector_cmd < gallery_cmd`
4. "gallery lane runs inside connector job..." — gallery asserted in connector body after connector command

Added derived fan-in-completeness test (D-02) with non-empty guard (`MapSet.size > 0`) + `MapSet.subset?` assertion.

Added WR-01 pin: `assert policy_section =~ "MIX_ENV: test"`.

WR-03 folded: renamed "test job depends on policy..." to "test job depends on build...".

Updated "postgres service is configured only for the test job" to use `job_blocks`: asserts `test`/`knowledge`/`connector` have `services:`, asserts `policy`/`build`/`ratchet`/`verify-summary` do not.

Updated "maintainer CI gate map documents topology..." to assert "Parallel verify jobs" (renamed from "Test job closeout") plus "ratchet", "knowledge", "connector", "verify-summary".

Added intent comment assertions for `# ratchet:`, `# knowledge:`, `# connector:`, `# verify-summary:`.

Updated `docs/MAINTAINERS.md`: renamed "Test job closeout" to "Parallel verify jobs", added topology line, added job→command table, expanded per-job docs for ratchet/knowledge/connector.

All 38 tests in `ci_policy_contract_test.exs` pass.

### Task 3: verification_lanes_test.exs intra-vs-cross split

Updated "ci lane ordering follows the canonical closeout chain" to:
- Scope intra-`test:` step order (`release_preview < adoption < runtime_to_handoff < semantic < full-suite`) to the `test:` job body (inline slice at `"\n  test:"` → `"\n  ratchet:"`)
- Replace cross-job `knowledge < connector < gallery` byte-order assertions with parallel-shape: extract `knowledge:` body (slice to `"\n  connector:"`), extract `connector:` body (slice to `"\n  verify-summary:"`), assert each has `needs: build`, assert `connector_cmd < gallery_cmd` within connector body

Both contract files green together: 44 tests, 0 failures.

## Verification Results

- `ruby -ryaml` topology check: 7 jobs present, ratchet has no services, verify-summary has `if: always()` — **PASSED**
- `YAML.load_file` parse: **PASSED** (no YAML errors)
- `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs`: **44 tests, 0 failures**

## Requirements Satisfied

- **PAR-01**: `test`/`ratchet`/`knowledge`/`connector` are sibling jobs each `needs: build`; `connector` carries gallery tail step
- **PAR-02**: `verify-summary` (`if: always()`, name-agnostic `skipped=fail`) aggregates all lanes; `ci-gate`/branch-protection name unchanged
- **PAR-03**: Intra-`test:` step order pinned; cross-job lanes asserted by parallel-shape, not byte-accident
- **WR-01**: `MIX_ENV: test` added to policy job; contract test pins it
- **WR-02**: `ci.yml` header comment updated to reflect parallel topology
- **WR-03**: Stale test name renamed to "test job depends on build and preserves closeout chain order"

## Deviations from Plan

None — plan executed exactly as written. All locked decisions (D-01, D-02, D-03, D-04) implemented as specified.

## Known Stubs

None. No stub patterns introduced.

## Threat Flags

No new network endpoints, auth paths, file access patterns, or schema changes introduced. This plan modifies only GitHub Actions YAML, Elixir test files, and Markdown documentation.

## Self-Check: PASSED

- `.github/workflows/ci-verify.yml`: FOUND
- `test/scoria/ci_policy_contract_test.exs`: FOUND
- `test/scoria/verification_lanes_test.exs`: FOUND
- `docs/MAINTAINERS.md`: FOUND
- Commit 84103dc: FOUND (Task 1)
- Commit 5cb9613: FOUND (Task 2)
- Commit f418f64: FOUND (Task 3)
