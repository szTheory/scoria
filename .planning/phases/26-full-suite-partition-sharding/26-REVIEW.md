---
phase: 26-full-suite-partition-sharding
reviewed: 2026-06-16T00:00:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - .github/workflows/ci-verify.yml
  - test/test_helper.exs
  - test/scoria/ci_policy_contract_test.exs
  - test/scoria/verification_lanes_test.exs
  - docs/MAINTAINERS.md
  - docs/operator_verification.md
  - README.md
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 26: Code Review Report

**Reviewed:** 2026-06-16
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

This is a CI-contract phase (SHARD-01) that shards the full ExUnit suite across a 4-way GitHub Actions matrix (`full-suite:`), moves `mix test --warnings-as-errors` out of the `test:` job into the matrix, wires `full-suite` into the `verify-summary` fan-in, adds a `MIX_TEST_PARTITION` zero-test guard in `test_helper.exs`, fixes three breaking contract assertions, and updates topology docs.

I traced the core threat model (false-green / coverage-evasion) against the diff and against `config/test.exs` (the load-bearing DB-name fallback) and reached the following conclusions:

- **WAE step is not lost.** `mix test --warnings-as-errors --partitions 4` is present in the `full-suite:` job (line 400) and removed from `test:`. The union of partitions `{1,2,3,4}` over `--partitions 4` is a complete residue system, so coverage is preserved by construction. No BLOCKER.
- **Fan-in is wired correctly.** `verify-summary.needs` includes `full-suite` (line 405). GitHub Actions aggregates the 4 matrix legs into a single `needs.full-suite.result` that is `success` only if every leg succeeds; `join(needs.*.result, ' ')` plus the `!= "success"` loop fails the gate on any non-success (including `skipped`). `fail-fast: false` does not mask this — it only lets all shards finish. No `continue-on-error` present. No BLOCKER.
- **DB isolation is correct.** `config/test.exs` resolves `database: SCORIA_DB_NAME || "scoria_test#{MIX_TEST_PARTITION}"`. The `full-suite:` job omits `SCORIA_DB_NAME` and sets `MIX_TEST_PARTITION` at job level, so `ecto.create`/`ecto.migrate`/`eval`/`test` all resolve to `scoria_testk` per shard. Each matrix leg gets its own isolated Postgres service container, so no cross-shard collision. No BLOCKER.
- **Zero-test guard pattern is proven.** The new partition guard reuses the identical `exit({:shutdown, 1})` shape introduced for the knowledge lane in phase 24 (`dcbb535`), placed after `ExUnit.start/1`. Sound.

No Critical issues. Two Warnings and two Info items below.

## Warnings

### WR-01: Partition zero-test guard has no contract test — the primary threat mitigation is unpinned

**File:** `test/test_helper.exs:39-46` (mitigation); `test/scoria/ci_policy_contract_test.exs` (missing coverage)
**Issue:** The stated central threat for this phase is "a shard reporting success when 0 tests ran." The mitigation is the `MIX_TEST_PARTITION` `after_suite` guard in `test_helper.exs` that exits non-zero when `total == 0`. However, **no test pins this guard**. The contract suite added a `D-04` fan-in pin and an `SC#1–SC#3` matrix-wiring test, but nothing asserts the guard exists in `test_helper.exs`. If someone deletes or weakens the guard (e.g., during a future test-helper refactor), every contract test still passes and the false-green hole silently reopens — exactly the failure this phase exists to prevent. A grep confirms the only references to `MIX_TEST_PARTITION` outside `test_helper.exs` are the workflow-string assertions, none of which touch the guard body.
**Fix:** Add a contract assertion pinning the guard, e.g. in `ci_policy_contract_test.exs`:
```elixir
test "test_helper pins partition zero-test guard" do
  helper = File.read!("test/test_helper.exs")
  assert helper =~ ~s|System.get_env("MIX_TEST_PARTITION")|
  assert helper =~ "after_suite"
  assert helper =~ "total == 0"
  assert helper =~ "exit({:shutdown, 1})"
end
```
This keeps the mitigation in lockstep with the workflow change it protects.

### WR-02: full-suite Postgres health-cmd drifts from sibling jobs in a "keep in sync" block

**File:** `.github/workflows/ci-verify.yml:357`
**Issue:** The `test:`, `knowledge:`, and `connector:` jobs all use `--health-cmd "pg_isready -U postgres -d scoria_test"` (lines 117, 228, 288). The new `full-suite:` job uses `--health-cmd "pg_isready -U postgres"` (line 357) — the `-d scoria_test` database arg is dropped. This is benign for correctness (the service still seeds `POSTGRES_DB: scoria_test`, and each shard creates `scoria_testk` via `ecto.create`), but the DB-prep step carries the comment "keep in sync with sibling parallel jobs," and the service blocks are otherwise byte-identical across all four Postgres jobs. Silent drift in an explicitly-synced block invites future copy-paste errors and makes the health-check semantics inconsistent (the `full-suite` healthcheck no longer asserts the seed DB is queryable).
**Fix:** Align with siblings:
```yaml
        options: >-
          --health-cmd "pg_isready -U postgres -d scoria_test"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 10
```

## Info

### IN-01: Guard activates on any non-nil MIX_TEST_PARTITION, including empty string

**File:** `test/test_helper.exs:39`
**Issue:** `if System.get_env("MIX_TEST_PARTITION")` is truthy for **any** non-nil value, including `""`. The comment claims the guard "never fires in local or lane runs," which holds today because the only writer is `matrix.partition` (always `1`–`4`). But the same env var is interpolated into the DB name in `config/test.exs:10` as `"scoria_test#{MIX_TEST_PARTITION}"` — if `MIX_TEST_PARTITION=""` were ever exported (a plausible misconfiguration), the DB silently collapses to `scoria_test` (collision with non-sharded jobs) AND this guard would activate. The coupling is currently unreachable but undefended.
**Fix:** Make the predicate explicit about a meaningful partition value, e.g.:
```elixir
partition = System.get_env("MIX_TEST_PARTITION")
if partition not in [nil, ""] do
  ExUnit.after_suite(fn %{total: total} ->
    if total == 0 do
      IO.puts(:stderr, "[full-suite partition #{partition}] after_suite: 0 tests executed — possible partition misconfiguration")
      exit({:shutdown, 1})
    end
  end)
end
```

### IN-02: SC#3 "rem-completeness" test asserts only string literals, not the partition algorithm

**File:** `test/scoria/ci_policy_contract_test.exs:271-277`
**Issue:** The `SC#3` block carries a detailed comment proving that `--partitions 4` with `matrix.partition [1,2,3,4]` forms a complete residue system, but the executable assertions are just `full_suite_body =~ "--partitions 4"` and `=~ "partition: [1, 2, 3, 4]"` — the same two string checks already made in `SC#1`. The test's name and comment promise an algorithmic completeness proof; the assertions only verify two literals stayed in the YAML. This is acceptable as a drift-detection pin (a mismatched `--partitions 3` + `[1,2,3,4]` would be caught), but the comment over-claims what the test enforces. Either trim the comment to "drift pin" framing or add a real check that the `--partitions N` integer equals the matrix list length (parse both and compare) so the proof is executable rather than narrative.
**Fix:** Optional — parse and cross-check, e.g.:
```elixir
[_, n] = Regex.run(~r/--partitions (\d+)/, full_suite_body)
[_, list] = Regex.run(~r/partition: \[([^\]]+)\]/, full_suite_body)
count = list |> String.split(",") |> length()
assert String.to_integer(n) == count, "--partitions N must equal matrix.partition list length"
```

---

_Reviewed: 2026-06-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
