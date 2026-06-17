---
phase: 27-ci-determinism-flake-elimination
reviewed: 2026-06-16T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - .github/workflows/ci.yml
  - .github/workflows/ci-verify.yml
  - docs/MAINTAINERS.md
  - test/scoria/ci_policy_contract_test.exs
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 27: Code Review Report

**Reviewed:** 2026-06-16
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

The core flake-elimination edits are correct. All five Postgres host-port bindings
(`test`, `knowledge`, `connector`, `full-suite` in `ci-verify.yml`; `e2e` in `ci.yml`)
were changed `55432:5432` → `5432:5432`, moving the host port out of the Linux ephemeral
range. The leftover `TEMP diagnose runs visibility` step was removed from the e2e job. The
YAML job structure remains intact: I parsed all job blocks programmatically and confirmed
the topology (`policy → build → { test, ratchet, knowledge, connector, full-suite } →
verify-summary`) is unbroken, the `full-suite` matrix job still omits `SCORIA_DB_NAME`
(load-bearing for `scoria_test{1..4}` shard isolation, verified against
`config/test.exs:8-10`), and the new contract test file passes all 45 tests.

The findings below are not in the happy-path edits themselves but in the **durability of
the new guard** (WR-01) and **documentation consistency** (WR-02, IN-01..IN-03). WR-01 is
the most important: the new port-range guard has a regex blind spot that lets the exact
flake class it protects against slip through under a common YAML spelling.

## Warnings

### WR-01: Port-range guard regex misses GitHub's short-form (host-only) port binding — vacuous-pass risk

**File:** `test/scoria/ci_policy_contract_test.exs:220`

**Issue:** The new guard extracts host ports with:

```elixir
port_bindings = Regex.scan(~r/- (\d+)(?::\d+|\/tcp)/, body)
```

This only matches list items that carry a `:container` or `/tcp` suffix (e.g.
`- 5432:5432` or `- 5432/tcp`). GitHub Actions service `ports:` also accepts the **short
form** where only the host port is given and the container port is inferred:

```yaml
ports:
  - 55432
```

That spelling produces **zero matches**, so the inner `assert host_port < 32768` loop
never runs and the guard passes vacuously — for the precise misconfiguration
(`55432`) this test exists to prevent. The `map_size(postgres_blocks) >= 5` non-empty
guard does not help here: it proves jobs *exist*, not that their ports were *scanned*.
Verified empirically:

```
Regex.scan(~r/- (\d+)(?::\d+|\/tcp)/, "ports:\n  - 55432\n")  #=> []
```

A future maintainer reintroducing the flake via the short form would get a green guard.

**Fix:** Make the container/tcp suffix optional and anchor the match to a `ports:`-context
list item, then assert a non-empty extraction per postgres block so a broken regex fails
loudly instead of silently:

```elixir
port_bindings = Regex.scan(~r/^\s*-\s*(\d+)(?::\d+|\/tcp)?\s*$/m, body)

assert port_bindings != [],
       "Job #{job}: postgres service has no parseable host-port binding — " <>
         "regex may be stale or job uses an unhandled ports: spelling"

for [_full, host_port_str] <- port_bindings do
  host_port = String.to_integer(host_port_str)
  assert host_port < @ephemeral_range_min, ...
end
```

(Anchoring to a leading-dash list item also avoids accidentally matching unrelated
numeric YAML values such as `retention-days:` or `--health-retries`.)

### WR-02: `ci.yml` header topology comment omits `full-suite` — drifts from actual job graph

**File:** `.github/workflows/ci.yml:17`

**Issue:** The workflow-header narrative comment reads:

```
# Parallel topology: policy → build → { test, ratchet, knowledge, connector } → verify-summary.
```

but `full-suite` is a real parallel verify lane (it lives in `ci-verify.yml`, which `ci.yml`
delegates to via `uses:`). The sibling file `ci-verify.yml:9` correctly lists
`{ test, ratchet, knowledge, connector, full-suite }`, and `MAINTAINERS.md:18` does too, so
this is an isolated stale comment. Since the phase explicitly re-touched these header
comments (the diff updated the adjacent `Maintainer narrative:` line), the topology line
should have been corrected in lockstep. The contract test
`"ci.yml has workflow header comment block before jobs"` only counts comment lines and
checks for `policy`/`test` substrings, so it does not catch this drift.

**Fix:** Update the comment to match the real topology:

```
# Parallel topology: policy → build → { test, ratchet, knowledge, connector, full-suite } → verify-summary.
```

## Info

### IN-01: `MAINTAINERS.md` CI-gate-map prose topology (line 7) also omits `full-suite`

**File:** `docs/MAINTAINERS.md:7`

**Issue:** The opening sentence of the CI gate map describes
`{ test, ratchet, knowledge, connector }` while the canonical topology line at
`MAINTAINERS.md:18` includes `full-suite[×4]`. Same drift as WR-02 but in the
maintainer-facing prose. It is downgraded to Info because the authoritative topology
line and table in the same doc are correct, so a reader gets the right picture overall.

**Fix:** Add `full-suite` to the line-7 brace list to match line 18 and `ci-verify.yml:405`.

### IN-02: New `Durable enforcement` paragraph asserts a stronger guarantee than the test delivers

**File:** `docs/MAINTAINERS.md:120-124`

**Issue:** The doc states the contract test "asserts that no Postgres job ... binds a host
port in the Linux ephemeral range (≥ 32768)." Given WR-01, the assertion only holds for
the `host:container` / `/tcp` spellings actually in use today; a short-form `- 55432`
binding would escape it. Once WR-01 is fixed this sentence becomes accurate; until then it
over-promises. Listing here so the doc and the guard are reconciled together.

**Fix:** Resolve WR-01 (preferred). The prose can then stand as written.

### IN-03: `job_blocks/1` treats non-job 2-space keys (`workflow_call`, `contents`, `push`, etc.) as pseudo-jobs

**File:** `test/scoria/ci_policy_contract_test.exs:644-674`

**Issue:** The job-name regex `~r/^  ([\w-]+):/m` matches any 2-space-indented key, so on
`ci-verify.yml` it yields `workflow_call`, `contents`, ... alongside real jobs, and on
`ci.yml` it yields `push`, `pull_request`, `workflow_dispatch`, `contents`, .... The new
port-range and continue-on-error tests survive this only because those pseudo-blocks
happen not to contain `"postgres:"` / `"continue-on-error"`. This is a latent fragility,
not a current bug — but it means the `map_size(...) >= 5` non-empty guard is counting from
a set polluted by non-jobs, weakening its diagnostic value. (It is pre-existing helper
code, not introduced by this phase; noted because the new tests now depend on it.)

**Fix:** Constrain extraction to the `jobs:` mapping, e.g. slice from the `\njobs:\n`
marker before scanning, or filter out the known top-level keys (`on`, `permissions`,
`workflow_call`, `push`, `pull_request`, `workflow_dispatch`, `contents`) so only true
job names enter the block map.

---

_Reviewed: 2026-06-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
