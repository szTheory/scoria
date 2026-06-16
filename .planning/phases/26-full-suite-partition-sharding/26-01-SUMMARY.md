---
phase: 26-full-suite-partition-sharding
plan: "01"
subsystem: ci
tags: [ci, sharding, partitions, contract-tests, docs]
dependency_graph:
  requires:
    - Phase 25 job_blocks/1 YAML parser (ci_policy_contract_test.exs)
    - Phase 23 build-test-env artifact (build job + download-artifact pattern)
    - Phase 24 derived-not-magic-number / fail-loud contract-test DNA
  provides:
    - full-suite: 4-way matrix job in ci-verify.yml (SHARD-01 / SC#1-SC#4)
    - per-shard DB isolation via MIX_TEST_PARTITION (scoria_test1..4)
    - after_suite zero-test partition guard (test_helper.exs)
    - structural coverage-proof contract (D-03) + fan-in pin (D-04) in ci_policy_contract_test.exs
  affects:
    - .github/workflows/ci-verify.yml topology (full-suite added to parallel wave)
    - docs/MAINTAINERS.md, docs/operator_verification.md, README.md (topology strings)
tech_stack:
  added: []
  patterns:
    - "GHA matrix strategy: fail-fast false, matrix.partition [1,2,3,4], MIX_TEST_PARTITION at job-level env"
    - "ExUnit.after_suite/1 zero-test guard gated on MIX_TEST_PARTITION (bare truthy)"
    - "Map.fetch!/2 + map_size/1 non-empty guard for anti-vacuous-pass contract tests"
key_files:
  created: []
  modified:
    - .github/workflows/ci-verify.yml
    - test/test_helper.exs
    - test/scoria/ci_policy_contract_test.exs
    - test/scoria/verification_lanes_test.exs
    - docs/MAINTAINERS.md
    - docs/operator_verification.md
    - README.md
decisions:
  - "SHARD-01: full-suite matrix job uses fail-fast false; never continue-on-error (false-green footgun)"
  - "DB isolation: SCORIA_DB_NAME absent from full-suite env (load-bearing absence); MIX_TEST_PARTITION at job-level propagates to ecto.create + ecto.migrate + mix test"
  - "Partition health-cmd: pg_isready -U postgres (no -d scoria_test — DB does not exist at health-check time)"
  - "Atomic commit: YAML move + contract-test fixes + docs must land together (policy lane runs contract tests with WAE)"
metrics:
  duration: "~8 minutes"
  completed: "2026-06-16T21:26:00Z"
  tasks_completed: 3
  files_modified: 7
---

# Phase 26 Plan 01: Full-Suite Partition Sharding Summary

**One-liner:** 4-way GHA matrix job `full-suite:` shards ExUnit WAE across `scoria_test1..4` partition DBs, zero-coverage-loss proven by rem-completeness math + structural contract + after_suite guard, wired into verify-summary fan-in.

## Tasks Completed

| Task | Name | Status | Key Changes |
|------|------|--------|-------------|
| 1 | Add full-suite: matrix job, move WAE step, wire fan-in, add after_suite guard | Done | ci-verify.yml: new full-suite: job (4-way matrix), WAE step removed from test:, verify-summary.needs updated; test_helper.exs: partition zero-test guard |
| 2 | Fix three breaking contract assertions + add D-03/D-04 structural coverage-proof | Done | ci_policy_contract_test.exs: B-1/B-2 fixed, D-03 test added, D-04 test added, U-1/U-2/U-3 updated; verification_lanes_test.exs: B-3 fixed, cross-workflow assert added |
| 3 | Update docs-as-contract topology lines and MAINTAINERS gate map | Done | MAINTAINERS.md: topology, table row, full-suite narrative, failure-diagnosis; operator_verification.md + README.md: topology strings |

## Verification

Lane-contract WAE command result: **GREEN** (48 tests, 0 failures)

```
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors \
  test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs
```

## CI Architecture After This Plan

```
policy → build → { test, ratchet, knowledge, connector, full-suite[×4] } → verify-summary
```

**full-suite: job key properties:**
- `needs: build` (restores `build-test-env` artifact — no cold compile)
- `strategy.fail-fast: false` + `matrix.partition: [1, 2, 3, 4]`
- `MIX_TEST_PARTITION: ${{ matrix.partition }}` at **job-level** env (propagates to all steps)
- `SCORIA_DB_NAME` **absent** (load-bearing: `config/test.exs` falls through to `scoria_test{k}`)
- DB-prep block byte-identical to siblings (`# DB-prep: keep in sync with sibling parallel jobs` marker)
- Final step: `mix test --warnings-as-errors --partitions 4`
- Postgres health-cmd: `pg_isready -U postgres` (no `-d scoria_test` — partition DB not yet created)

## Breaking Assertions Fixed

| ID | File | Fix |
|----|------|-----|
| B-1 | ci_policy_contract_test.exs:212-214 | Removed stale `index_of(test_body, "run: mix test --warnings-as-errors")`; added cross-job `Map.fetch!(job_blocks(ci_verify), "full-suite")` asserts |
| B-2 | ci_policy_contract_test.exs:229,231-232 | Renamed test; replaced two breaking asserts with `refute test_body =~ "run: mix test --warnings-as-errors"` + full-suite cross-job asserts |
| B-3 | verification_lanes_test.exs:100 | Removed stale WAE-in-test_body assert; added `assert ci_workflow =~ "mix test --warnings-as-errors --partitions 4"` |

## New Contract Tests

**D-03 — "full-suite job is a 4-way matrix with correct partition wiring and no DB name collision":**
- Non-empty `map_size(blocks) > 0` guard (anti-vacuous-pass)
- `Map.fetch!(blocks, "full-suite")` — raises on missing key
- SC#1 asserts: `needs: build`, `--partitions 4`, `MIX_TEST_PARTITION`, `matrix.partition`, `partition: [1, 2, 3, 4]`, `fail-fast: false`, refutes `continue-on-error`
- SC#2 asserts: refutes `SCORIA_DB_NAME`, asserts `MIX_TEST_PARTITION: ${{ matrix.partition }}`, `services:`
- Rem-completeness proof documented as contract comment (Layer 1)

**D-04 — "full-suite is explicitly wired into verify-summary fan-in (D-04 targeted pin)":**
- `Map.fetch!(blocks, "verify-summary")` + assert contains `"full-suite"`

**U-1/U-2/U-3 updates:**
- U-1: `full-suite` added to postgres-services assertion list
- U-2: `# full-suite:` added to intent-comment test
- U-3: `full-suite` added to gate-map topology test

## Zero-Coverage-Loss Proof (SC#3)

**Layer 1 (math):** `filter_by_partition/3` = `sort |> with_index |> filter rem(i, total) == partition - 1`. For total=4, partitions {1,2,3,4} cover rem values {0,1,2,3} — a complete residue system. Union of 4 shards = full suite BY CONSTRUCTION (Elixir 1.19.5).

**Layer 2 (contract):** D-03 test pins `--partitions 4` AND `partition: [1, 2, 3, 4]` as separate agreeing facts. A `--partitions 3` / `[1,2,3,4]` mismatch goes RED before merge.

**Layer 3 (runtime):** `after_suite` guard in `test_helper.exs` — gated on `System.get_env("MIX_TEST_PARTITION")`, `exit({:shutdown, 1})` when `total == 0`. Closes the ExUnit `{:noop,_}` exit-0-on-0-tests hole.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Unused variable in renamed B-2 test**
- **Found during:** Task 2 — running lane-contract WAE command
- **Issue:** After removing the `index_of(test_body, runtime_to_handoff)` assertion from the renamed B-2 test, the `runtime_to_handoff = VerificationLanes.ci_command(:runtime_to_handoff)` variable assignment triggered a `--warnings-as-errors` compile warning
- **Fix:** Removed the now-unused `runtime_to_handoff` assignment from the B-2 test body
- **Files modified:** `test/scoria/ci_policy_contract_test.exs`
- **Commit:** (part of atomic commit)

## Threat Flags

None. All new surface is CI-only (no auth/crypto/PII/runtime-input); threat mitigations T-26-01 through T-26-06 implemented as specified.

## Self-Check

- [x] `.github/workflows/ci-verify.yml` contains `full-suite:` job
- [x] `test/test_helper.exs` contains `MIX_TEST_PARTITION` guard
- [x] `test/scoria/ci_policy_contract_test.exs` contains `Map.fetch!(blocks, "full-suite")`
- [x] `test/scoria/verification_lanes_test.exs` contains `--partitions 4` cross-workflow assert
- [x] `docs/MAINTAINERS.md` contains `full-suite` and `MIX_TEST_PARTITION=k mix test --warnings-as-errors --partitions 4`
- [x] `docs/operator_verification.md` contains `full-suite`
- [x] `README.md` contains `full-suite`
- [x] Lane-contract WAE command: 48 tests, 0 failures
- [x] `mix ecto.migrate --to 20260511000300` appears exactly 4 times in ci-verify.yml
- [x] `continue-on-error` absent from ci-verify.yml
- [x] `verify-summary.needs` is inline list including `full-suite`; `if: always()` retained
- [x] `config/test.exs` unchanged (SC#1)

## Self-Check: PASSED
