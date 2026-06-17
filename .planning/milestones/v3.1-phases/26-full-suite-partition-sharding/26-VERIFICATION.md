---
phase: 26-full-suite-partition-sharding
verified: 2026-06-16T22:00:00Z
status: human_needed
score: 5/5
overrides_applied: 0
gaps: []
human_verification:
  - test: "Run a real 4-shard CI matrix on GitHub Actions (post-merge or manual trigger)"
    expected: "Four green full-suite (k/4) jobs appear under verify-summary; all shards report > 0 tests; verify-summary aggregates to success; no shard gets SCORIA_DB_NAME collision"
    why_human: "The sharded matrix run requires 4 runners + Postgres service containers; it only executes in GitHub Actions CI, not locally. The YAML contract and structural tests are green locally but the live parallel run cannot be confirmed without CI access."
---

# Phase 26: Full-Suite Partition Sharding — Verification Report

**Phase Goal:** The full ExUnit suite runs split across a parallel runner matrix (4-way `mix test --warnings-as-errors --partitions 4`) on the shared build artifact, collapsing the suite wall-clock while preserving EXACT coverage — with per-shard DB isolation keyed by MIX_TEST_PARTITION, a single verify-summary fan-in, and zero coverage loss.
**Verified:** 2026-06-16T22:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Authoritative Local Check Result

The lane-contract command (the exact policy-job command in CI) was run and passed:

```
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors \
  test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs
```

Result: **48 tests, 0 failures**

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `full-suite:` runs `mix test --warnings-as-errors --partitions 4` across `matrix.partition: [1,2,3,4]`, each leg exporting MIX_TEST_PARTITION from matrix.partition; config/test.exs unchanged | VERIFIED | ci-verify.yml line 337: `full-suite:` job exists. Line 345: `partition: [1, 2, 3, 4]`. Line 368: `MIX_TEST_PARTITION: ${{ matrix.partition }}` at job level. Line 400: `run: mix test --warnings-as-errors --partitions 4`. config/test.exs: `git diff HEAD -- config/test.exs` returns empty (byte-identical). |
| 2 | Each shard's DB is `scoria_test{k}` (SCORIA_DB_NAME absent from full-suite env); shards never collide | VERIFIED | ci-verify.yml full-suite env block (lines 362-369): no `SCORIA_DB_NAME` key present. `MIX_TEST_PARTITION` at job level propagates to all steps. config/test.exs line 9-10: `System.get_env("SCORIA_DB_NAME") \|\| "scoria_test#{System.get_env("MIX_TEST_PARTITION")}"` — absence of SCORIA_DB_NAME activates the partition DB path by construction. |
| 3 | Zero coverage loss — proven by rem-completeness math (Layer 1), pinned by structural contract (`--partitions 4` + `[1,2,3,4]` sync, Layer 2), backstopped by `after_suite` zero-test guard (Layer 3) | VERIFIED | Layer 1: rem-completeness proof comment in ci_policy_contract_test.exs lines 271-274. Layer 2: D-03 test (lines 245-278) asserts both `--partitions 4` and `partition: [1, 2, 3, 4]` as separate agreeing facts with non-empty guard. Layer 3: test_helper.exs lines 39-45: `if System.get_env("MIX_TEST_PARTITION")` guard with `ExUnit.after_suite` + `exit({:shutdown, 1})` when `total == 0`. |
| 4 | Only `verify-summary` required; `full-suite ∈ verify-summary.needs`; no per-shard check added; `if: always()` + `fail-fast: false` retained; `continue-on-error` absent | VERIFIED | ci-verify.yml line 405: `needs: [policy, build, test, ratchet, knowledge, connector, full-suite]` (inline list). Line 406: `if: always()`. Line 343: `fail-fast: false`. Grep for `continue-on-error` returns empty. D-04 test (ci_policy_contract_test.exs lines 280-287) pins `verify_summary_body =~ "full-suite"`. |
| 5 | `mix test --warnings-as-errors` step gone from `test:` job; three breaking contract assertions fixed; lane-contract WAE command green; topology docs name full-suite in lockstep | VERIFIED | ci-verify.yml `test:` job (lines 102-183): last lane step is `mix test.semantic_fast_path --warnings-as-errors` (line 182); no bare `mix test --warnings-as-errors` step. Grep for `run: mix test --warnings-as-errors$` returns empty. B-1/B-2 (ci_policy_contract_test.exs): no `index_of(test_body, "run: mix test --warnings-as-errors")` assertions remain. B-3 (verification_lanes_test.exs line 144): cross-workflow assert `ci_workflow =~ "mix test --warnings-as-errors --partitions 4"` replaces stale assert. Lane-contract WAE: 48 tests, 0 failures. Docs: MAINTAINERS.md line 18 topology includes `full-suite[×4]`; operator_verification.md line 292 includes `full-suite[×4]`; README.md line 281 includes `full-suite[×4]`. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.github/workflows/ci-verify.yml` | full-suite: 4-way matrix job; test: job with WAE step removed; verify-summary.needs including full-suite | VERIFIED | full-suite: job at line 337 with all required structure; test: job ends at semantic_fast_path; verify-summary.needs inline list at line 405 includes full-suite |
| `test/test_helper.exs` | after_suite zero-test partition guard gated on MIX_TEST_PARTITION | VERIFIED | Lines 39-45: guard present, gated on `System.get_env("MIX_TEST_PARTITION")`, `exit({:shutdown, 1})` when `total == 0`, placed after ExUnit.start/1 |
| `test/scoria/ci_policy_contract_test.exs` | B-1/B-2 fixes + D-03 structural coverage-proof asserts + D-04 fan-in pin + U-1/U-2/U-3 updates | VERIFIED | D-03 test at line 245; D-04 test at line 280; U-1 at line 187; U-2 at line 466; U-3 at line 497; no stale WAE-in-test_body asserts remain |
| `test/scoria/verification_lanes_test.exs` | B-3 fix (remove stale WAE-in-test_body assert; add cross-workflow --partitions 4 assert) | VERIFIED | Line 144: `assert ci_workflow =~ "mix test --warnings-as-errors --partitions 4"`; no stale `index_of(test_body, "run: mix test --warnings-as-errors")` |
| `docs/MAINTAINERS.md` | full-suite (k/4) gate-map row + topology line + narrative + failure-diagnosis row | VERIFIED | Topology line 18; `full-suite (k/4)` job table row at line 28; full-suite narrative section at lines 50-54; failure-diagnosis at line 88 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| ci-verify.yml full-suite: env | config/test.exs database fallback | Absence of SCORIA_DB_NAME + MIX_TEST_PARTITION job-level env | WIRED | `MIX_TEST_PARTITION: ${{ matrix.partition }}` at line 368; no SCORIA_DB_NAME in full-suite env block; config/test.exs lines 9-10 resolve `scoria_testk` when SCORIA_DB_NAME is nil |
| ci-verify.yml verify-summary.needs | full-suite job result aggregation | Inline needs list | WIRED | `needs: [policy, build, test, ratchet, knowledge, connector, full-suite]` at line 405; inline form matches the regex `~r/needs:\s*\[([^\]]+)\]/` in the contract test |
| ci_policy_contract_test.exs | ci-verify.yml full-suite: block | job_blocks/1 + Map.fetch!(blocks, "full-suite") | WIRED | `Map.fetch!(blocks, "full-suite")` appears at lines 187, 214, 232, 252, 284 — raises on missing key (anti-vacuous-pass) |

### Data-Flow Trace (Level 4)

Not applicable — this phase produces CI YAML, contract tests, and docs; no dynamic data rendering artifacts.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Lane-contract WAE command green (authoritative local check) | `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` | 48 tests, 0 failures | PASS |
| full-suite: job exists in ci-verify.yml | `grep -q 'full-suite:' .github/workflows/ci-verify.yml` | Match found (line 337) | PASS |
| mix ecto.migrate --to 20260511000300 appears exactly 4 times | `grep -c 'mix ecto.migrate --to 20260511000300' .github/workflows/ci-verify.yml` | 4 | PASS |
| continue-on-error absent from ci-verify.yml | `grep -n 'continue-on-error' .github/workflows/ci-verify.yml` | No output | PASS |
| verify-summary.needs inline list includes full-suite | `grep -n 'needs: \[policy.*full-suite\]' .github/workflows/ci-verify.yml` | Line 405 matches | PASS |
| Bare WAE step absent from test: job | `grep -n 'run: mix test --warnings-as-errors$' .github/workflows/ci-verify.yml` | No output | PASS |
| config/test.exs unchanged | `git diff HEAD -- config/test.exs` | Empty (no diff) | PASS |

### Probe Execution

No probe scripts declared or conventionally located for this phase. Phase 26 is a CI-contract phase (YAML + test-file + docs); the authoritative check is the lane-contract command above.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| SHARD-01 | 26-01-PLAN.md | The full ExUnit suite runs sharded via `mix test --partitions 4` across a runner matrix, each shard using an isolated database (already keyed by `MIX_TEST_PARTITION` in `config/test.exs`), with no coverage loss versus the single-job run. | SATISFIED | full-suite: job in ci-verify.yml satisfies all three sub-requirements: partitioned run (`--partitions 4`), isolated DB per shard (SCORIA_DB_NAME absent, MIX_TEST_PARTITION at job level), zero coverage loss (Layer 1 math + Layer 2 structural contract + Layer 3 after_suite guard). REQUIREMENTS.md marks SHARD-01 as `[x]` Complete at Phase 26 (line 84). |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | — | — | — | No TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER markers found in any modified file. No stub returns, empty handlers, or hardcoded empty data. |

### Warnings from Code Review (26-REVIEW.md)

Two warnings were raised in the code review (no blockers):

**WR-01 (Warning):** The partition zero-test guard in `test_helper.exs` has no contract test pinning it. If deleted or weakened, the D-03/D-04 contract tests still pass but the false-green hole reopens silently. Suggested fix: add a `test "test_helper pins partition zero-test guard"` assertion in `ci_policy_contract_test.exs`. This is not a blocker for SHARD-01 but weakens the defense-in-depth posture.

**WR-02 (Warning):** The `full-suite:` Postgres health-cmd (`pg_isready -U postgres`) omits `-d scoria_test` present in the three sibling jobs. Functionally benign (the partition DB is created by `ecto.create`, not the health check), but creates silent drift in an explicitly-synced block. The PLAN explicitly specifies this form (VF-5) as intentional — the partition DB does not exist at health-check time.

**IN-02 (Info):** SC#3 rem-completeness test only pins two string literals (`--partitions 4`, `partition: [1, 2, 3, 4]`) — effective as drift detection but the comment over-claims an algorithmic completeness proof. Optional enhancement: parse and cross-check the integer against list length.

None of these are blockers. WR-02 is an intentional design decision per the PLAN.

### Human Verification Required

#### 1. Live 4-Shard CI Matrix Run

**Test:** Trigger a PR or manual CI run on GitHub Actions after merging this phase. Observe the Actions run for `ci-verify.yml`.
**Expected:** Four green `full-suite (k/4)` jobs appear (1/4, 2/4, 3/4, 4/4), each showing > 0 tests run. `verify-summary` aggregates to success. No shard encounters a DB collision (each uses `scoria_testk`). The overall wall-clock of the parallel set is roughly 1/4 of the previous single-job run time.
**Why human:** The sharded matrix run requires 4 parallel GitHub Actions runners with Postgres service containers. This can only execute in GitHub Actions CI — not reproducible locally. The YAML contract, structural contract tests, and after_suite guard are all verified green locally, but the live parallel execution is post-merge/manual only.

### Gaps Summary

No gaps. All 5 must-have truths are VERIFIED. SHARD-01 requirement is SATISFIED. The authoritative lane-contract command passes (48 tests, 0 failures). All key artifacts exist and are substantively wired. The only remaining item is a human verification of the live 4-shard GHA matrix run, which is by design post-merge.

---

_Verified: 2026-06-16T22:00:00Z_
_Verifier: Claude (gsd-verifier)_
