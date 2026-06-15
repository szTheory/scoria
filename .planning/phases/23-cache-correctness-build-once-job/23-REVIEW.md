---
phase: 23-cache-correctness-build-once-job
reviewed: 2026-06-14T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - .github/workflows/ci-verify.yml
  - .github/workflows/ci.yml
  - test/scoria/ci_policy_contract_test.exs
findings:
  critical: 0
  warning: 3
  info: 2
  total: 5
status: issues_found
---

# Phase 23: Code Review Report

**Reviewed:** 2026-06-14
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Phase 23 delivers CACHE-01 (env-scoped cache keys) and CACHE-02 (build-once artifact) across three files. The core build topology (policy → build → test), the tar mtime preservation mechanism, and the artifact upload/download chain are all sound. The 4 new contract assertions are structurally correct and green.

Three warnings require attention before this topology is relied upon by Phase 25 (parallelization) or Phase 26 (matrix sharding): a cache-key mislabeling on the policy job that causes it to write dev-compiled artifacts under a `test-mix` key; a stale topology comment in `ci.yml`; and a semantically misleading pre-existing contract test name that now passes for the wrong reason.

---

## Warnings

### WR-01: Policy job writes dev-compiled `_build` artifacts under a `test-mix-` cache key

**File:** `.github/workflows/ci-verify.yml:15-54` (policy job)

**Issue:** The `policy` job has no `MIX_ENV: test` set at job level. Its `mix compile --warnings-as-errors` step (line 49) therefore runs under `MIX_ENV=dev` (the Elixir default), writing compiled BEAM files to `_build/dev/`. However, the `actions/cache@v5` key on line 35 is `...-test-mix-${{ hashFiles('**/mix.lock') }}`. When the policy job saves the cache at post-step, `_build/dev` artifacts are stored under a key that claims to hold test-env output.

On a cold-cache workflow run (new `mix.lock` hash), the policy job runs first and saves this mislabeled entry. The build job then restores it. The build job's `mix compile --warnings-as-errors` runs correctly under `MIX_ENV=test` and produces the right `_build/test` output regardless — so the artifact is always correct. However:

1. **Future consumers (Phase 25/26 matrix jobs)** that restore the `test-mix` cache expecting purely test-compiled `_build` will find `_build/dev` content mixed in. If any such job inspects the cache for sanity or uses the cache path `_build` instead of the artifact, it may silently load dev artifacts.
2. **The compile WAE gate in policy is weaker than intended**: it validates warnings under `MIX_ENV=dev`, not `MIX_ENV=test`. Test-environment-only code (test helpers, ExUnit macros) is not covered by this check.

The pre-phase-23 policy job also lacked `MIX_ENV: test`, so the compile-gating weakness is pre-existing. However, phase 23 specifically changed the cache key label from the neutral `runner.os-mix-` to the semantically assertive `test-mix-`, making the mislabeling a new, explicitly introduced inconsistency.

**Fix:** Add `MIX_ENV: test` at the policy job level so the compile WAE step actually validates test-env code and the saved cache contains genuine `_build/test` artifacts:

```yaml
  policy:
    runs-on: ubuntu-latest
    env:
      MIX_ENV: test   # add this

    steps:
      ...
      - name: Compile with warnings as errors
        run: mix compile --warnings-as-errors  # now correctly compiles _build/test
```

If keeping `policy` in `MIX_ENV=dev` is intentional (e.g., it checks dev warnings specifically), rename its cache key to `-dev-mix-` to match what it actually writes, and set `MIX_ENV: test` only on the `build` and `test` jobs (which already have it).

---

### WR-02: `ci.yml` header comment is stale — still says "Two-job topology" after adding the `build` job

**File:** `.github/workflows/ci.yml:17`

**Issue:** Line 17 reads:
```
# Two-job topology: policy (fail cheap, no Postgres) → test (canonical closeout + full WAE).
```
Phase 23 introduced a third job (`build`) between `policy` and `test` in `ci-verify.yml`, making this a three-job topology. The `build` job is inside the reusable `ci-verify.yml` (not directly in `ci.yml`), but the comment describes the topology of what `ci.yml` calls, and that topology is now `policy → build → test`.

No contract test enforces this comment. The `ci.yml header comment block` test (line 310 in `ci_policy_contract_test.exs`) only checks for `>= 5` comment lines and the presence of `ci-verify`, `policy`, and `test` — it does not check for `build` or detect `Two-job`.

A maintainer reading `ci.yml` will be confused when the actual topology has three jobs but the header says two.

**Fix:**
```yaml
# Three-job topology (in ci-verify.yml): policy (fail cheap, no Postgres) → build (compile once, MIX_ENV=test) → test (canonical closeout + full WAE).
```

---

### WR-03: Existing contract test `"test job depends on policy and preserves closeout chain order"` now passes for a structurally wrong reason

**File:** `test/scoria/ci_policy_contract_test.exs:154-168`

**Issue:** The test name says "test job depends on policy" but after phase 23, the `test` job has `needs: build` — it no longer directly depends on `policy`. The assertion `assert ci_verify =~ "needs: policy"` (line 161) still passes because the `build` job has `needs: policy` elsewhere in the file. The assertion is a substring match on the whole file, not scoped to the test job.

The new contract test `"test job needs build, not policy directly"` (line 302) correctly captures the actual topology. But the old test with the misleading name remains and passes vacuously — a reader of the test suite will see "test job depends on policy" and think the `test` job directly needs `policy`, which is now false.

This is not a new problem introduced wholly by phase 23 (the assertion pre-dates this phase), but phase 23 deliberately changed the topology to make the test name false while adding a corrective new test. The stale name should have been updated as part of this change.

**Fix:** Update the test name to reflect that the whole workflow (not specifically the test job) preserves the `needs: policy` link transitively via the build job:

```elixir
test "ci-verify.yml preserves needs: policy link and closeout chain order" do
  # (body unchanged)
```

Or, scope the assertion to the policy-section only:

```elixir
  assert policy_section =~ "needs: policy"
```

This makes the assertion geography match the test name.

---

## Info

### IN-01: `TEMP DIAGNOSTIC` step in `ci.yml` e2e job (pre-existing, not introduced in phase 23)

**File:** `.github/workflows/ci.yml:115-126`

**Issue:** A step labeled "TEMP DIAGNOSTIC (remove after skeleton e2e root-caused)" has been in `ci.yml` since before phase 23. It runs diagnostic shell commands (`mix run`, `curl`, `grep`) on every CI run. Phase 23 did not add this step, but it is still present.

**Fix:** Remove once the e2e root cause is identified. No action required for this phase specifically.

---

### IN-02: No contract assertion enforces the `# build:` comment convention or the `build` job's `env: MIX_ENV: test`

**File:** `test/scoria/ci_policy_contract_test.exs:325-331`

**Issue:** The existing `"ci-verify.yml documents per-job intent comments for policy and test"` test asserts `# policy:` and `# test:` comments exist, but does not assert `# build:`. Similarly, no contract test asserts that the build job has `env: MIX_ENV: test`. As the topology grows (Phase 25/26), missing assertions make it easier to accidentally omit the `MIX_ENV: test` scoping or the comment convention from new jobs.

**Fix:** Extend the comment-convention test to include the build job:

```elixir
  assert policy_section =~ "# build:"
```

And add an assertion that the build job sets `MIX_ENV: test`:

```elixir
test "build job runs under MIX_ENV=test" do
  ci_verify = File.read!(@ci_verify)
  [policy_section, _test_section] = split_jobs(ci_verify)

  # build block must set MIX_ENV: test at job level
  build_section =
    policy_section
    |> String.split("\n  build:")
    |> Enum.at(1, "")

  assert build_section =~ "MIX_ENV: test"
end
```

---

_Reviewed: 2026-06-14_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
