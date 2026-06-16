# Phase 26: Full-suite partition sharding — Research

**Researched:** 2026-06-16
**Domain:** ExUnit partitioning + GitHub Actions matrix / fan-in semantics
**Confidence:** HIGH (all claims verified against live codebase; Mix partition behavior confirmed
against Elixir 1.19.5-otp-27 as pinned in `.tool-versions`)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01** — New dedicated `full-suite:` matrix job (`needs: build`, `fail-fast: false`,
  `matrix.partition: [1,2,3,4]`). Move the final `mix test --warnings-as-errors` step OUT of
  `test:`. The closeout chain (`release_preview → adoption → runtime_to_handoff → semantic`)
  stays in `test:` and runs once. No `--partition N` flag — `MIX_TEST_PARTITION` env selects
  the leg.

- **D-02** — Drop `SCORIA_DB_NAME` from `full-suite:` env; set `MIX_TEST_PARTITION:
  ${{ matrix.partition }}` at JOB-level env (not per-step). DB-prep block stays
  byte-identical to sibling jobs (same literal strings the contract greps depend on) with the
  `# DB-prep: keep in sync with sibling parallel jobs` marker.

- **D-03** — Zero-coverage-loss proof = partition math (rem-completeness) + structural
  contract test + `after_suite` zero-test guard (gated on `MIX_TEST_PARTITION`). REJECT
  numeric count-reconciliation.

- **D-04** — Add `full-suite` to `verify-summary.needs`; keep `if: always()`; `fail-fast:
  false`; NEVER `continue-on-error`.

### Claude's Discretion

- Exact regex/parsing additions to `ci_policy_contract_test.exs` vs a sibling
  `ci_verify_contract_test.exs` if the file grows too long.
- `POSTGRES_DB` value in the `full-suite:` service container (`scoria_test` for sibling-parity
  vs partition-keyed) — both inert; pick least-surprising diff against `test:`.
- Exact YAML position of `full-suite:` among the sibling parallel jobs.
- Exact `after_suite` guard phrasing and the stderr diagnostic message.

### Deferred Ideas (OUT OF SCOPE)

- Shard wall-clock balance tuning
- Coverage-percentage reporting / `--cover` merge across shards
- Phase 27 (FLAKE-01/02/03): fixed-host-port Postgres, TEMP e2e diagnostic, retry policy
- Phase 28 (DX-01/VELO-01): `mix ci` alias, velocity closeout
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID       | Description                                                                                                                                                           | Research Support                                                                                                                                                     |
|----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| SHARD-01 | Full ExUnit suite runs sharded via `mix test --partitions 4` across a runner matrix, each shard using an isolated database (keyed by `MIX_TEST_PARTITION`), with no coverage loss vs the single-job run. | D-01 (matrix job), D-02 (DB isolation via env), D-03 (rem-completeness proof + structural guard + after_suite guard), D-04 (fan-in wiring). All confirmed below. |
</phase_requirements>

---

## Summary

Phase 26 is a **surgical YAML + test-file edit**, not a greenfield feature. The
`config/test.exs` partition-awareness (`SCORIA_DB_NAME || "scoria_test#{MIX_TEST_PARTITION}"`)
is already live and correct — confirmed by reading the file. The ExUnit partition algorithm
(`filter_by_partition/3` = sort → with_index → rem-filter) guarantees union-completeness by
construction; no runtime count-tracking is needed or safe. The existing `job_blocks/1` parser
(Phase 25 D-01) and the derived fan-in-completeness test (Phase 25 D-02) are already
matrix-tolerant — adding `full-suite` to `verify-summary.needs` auto-wires the contract.

The non-obvious work in this phase is updating **three existing contract tests** that currently
assert `"run: mix test --warnings-as-errors"` is inside the `test:` job body. After Phase 26
moves that step out, those assertions break. The planner must include those test updates as
explicit tasks — they are not "nice to have," they are required for the policy job (which runs
those contract tests with WAE) to stay green.

**Primary recommendation:** One wave. Atomic commit: YAML change (move step + add full-suite: +
wire fan-in) + contract test updates (break three stale assertions, add three new structural
asserts, add targeted `full-suite ∈ verify-summary.needs` assert) + `after_suite` guard + docs
row. Run the policy lane locally (`SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start
--warnings-as-errors test/scoria/ci_policy_contract_test.exs
test/scoria/verification_lanes_test.exs`) before committing to catch the breaking assertions.

---

## Architectural Responsibility Map

| Capability                             | Primary Tier          | Secondary Tier | Rationale                                                                                 |
|----------------------------------------|-----------------------|----------------|-------------------------------------------------------------------------------------------|
| Test execution (sharded)               | CI runner matrix      | —              | ExUnit partition logic + `MIX_TEST_PARTITION` is evaluated at `mix test` invocation time  |
| DB isolation per shard                 | CI job-level env      | config/test.exs | `SCORIA_DB_NAME` absence forces the `||` fallback; no code change needed                 |
| Coverage-loss prevention (math proof)  | Mix / ExUnit runtime  | Contract test  | `filter_by_partition/3` is deterministic and complete; contract asserts the YAML is wired correctly |
| Fan-in gating                          | GitHub Actions        | verify-summary | Matrix → single `needs.*.result` aggregation is a GHA platform behaviour, not application logic |
| Docs-as-contract                       | ExUnit contract tests | MAINTAINERS.md | Structural asserts catch drift before merge; docs row is the human-readable counterpart   |

---

## Verified Facts (confirmed against live codebase and toolchain)

### VF-1: `config/test.exs` — already partition-aware, DO NOT change [VERIFIED: live file read]

```elixir
# config/test.exs lines 8-10
database:
  System.get_env("SCORIA_DB_NAME") ||
    "scoria_test#{System.get_env("MIX_TEST_PARTITION")}",
```

The `||` fallback works because `System.get_env/1` returns `nil` (not `""`), and `nil || rhs`
evaluates `rhs`. When `SCORIA_DB_NAME` is absent: resolves `scoria_test1` … `scoria_test4`.
When present (sibling `test:`/`knowledge:`/`connector:` set `SCORIA_DB_NAME: scoria_test`):
resolves `scoria_test`. **This is load-bearing** — D-02's "drop `SCORIA_DB_NAME` from
`full-suite:`" is exactly what activates the partition path.

### VF-2: Test file count — 151 non-fixture `_test.exs` files [VERIFIED: live filesystem scan]

```
find test -name "*_test.exs" | grep -v "fixtures/" | wc -l
# → 151
```

Partition distribution across 4 shards (rem-completeness proof):

| Shard | File count | rem(i,4) == partition-1 |
|-------|------------|--------------------------|
| 1     | 38         | i ∈ {0,4,8,…,148}        |
| 2     | 38         | i ∈ {1,5,9,…,149}        |
| 3     | 38         | i ∈ {2,6,10,…,150}       |
| 4     | 37         | i ∈ {3,7,11,…,147}       |
| Total | **151**    | = N ✓                    |

Every index 0..150 appears in exactly one partition. The complete residue system
`{rem(0,4), rem(1,4), …, rem(150,4)} = {0,1,2,3}` is covered. Union = full suite by
construction. [VERIFIED: Python calculation against live file count]

The CONTEXT.md states "~151 test files → partitions ≈ [38, 38, 38, 37]" — **confirmed exact**.

### VF-3: Mix has no `--partition N` flag [VERIFIED: CONTEXT.md cites Mix.Tasks.Test.filter_by_partition/3, Elixir 1.19.5]

The correct invocation is `mix test --partitions 4` with `MIX_TEST_PARTITION` env. There is no
`--partition 2` style flag. Each shard leg runs the identical command; the env selects which
shard runs. This is a common footgun.

### VF-4: ExUnit `after_suite/1` callback — `%{total: total}` map signature [VERIFIED: live test_helper.exs]

The existing Layer 2 knowledge-lane guard at `test/test_helper.exs:28` uses:

```elixir
ExUnit.after_suite(fn %{total: total} ->
  if total == 0 do ...
```

This is the correct pattern for Elixir 1.19.5. The same signature must be used for the new
full-suite partition guard. The guard fires ONLY when `MIX_TEST_PARTITION` is set, so it never
trips on local `mix test` runs (where the env is absent and the fallback DB name becomes
`"scoria_testnil"` — but this is also not a problem since local runs don't set the env and the
guard is skipped entirely).

Note: `System.get_env("MIX_TEST_PARTITION")` returns `nil` locally. The database name becomes
`"scoria_testnil"` locally when neither env var is set — this is the existing local behaviour,
unchanged by Phase 26.

### VF-5: Postgres `health-cmd` couples to DB name [VERIFIED: live ci-verify.yml]

All three sibling jobs use:
```yaml
--health-cmd "pg_isready -U postgres -d scoria_test"
```

For `full-suite:`, `scoria_test` does not exist until `mix ecto.create` runs. The container
health check runs BEFORE `ecto.create`. Two options:
- **Recommended (from D-02):** Change to `pg_isready -U postgres` (drop `-d scoria_test`) so
  readiness doesn't couple to a DB name that won't exist until `ecto.create`. This is the only
  change to the Postgres service block vs the siblings.
- **Alternative:** Use `POSTGRES_DB: scoria_test1` for the health-cmd DB (but this couples the
  container to a specific shard and is misleading since all 4 shards share the same Postgres
  sidecar spec).

The recommended form `pg_isready -U postgres` (no `-d` flag) is sufficient for a readiness
probe — it verifies the server accepts connections, not a specific DB.

### VF-6: `verify-summary.needs` uses inline list syntax `[policy, build, ...]` [VERIFIED: live ci-verify.yml line 342]

```yaml
verify-summary:
  runs-on: ubuntu-latest
  needs: [policy, build, test, ratchet, knowledge, connector]
  if: always()
```

Adding `full-suite` → `needs: [policy, build, test, ratchet, knowledge, connector, full-suite]`.
The job_blocks/1 parser at `ci_policy_contract_test.exs:285` uses:
`Regex.run(~r/needs:\s*\[([^\]]+)\]/, verify_summary_body)` — it correctly handles inline
list syntax. The derived fan-in subset assertion at line 297 auto-catches `full-suite` once it
has `needs: build` in its body.

### VF-7: `strategy.job-total` context variable for job name [ASSUMED]

The CONTEXT.md D-01 specifies `name: "full-suite (${{ matrix.partition }}/${{ strategy.job-total }})"`.
GitHub Actions `strategy.job-total` is documented as the total number of jobs in the matrix.
For a `matrix.partition: [1,2,3,4]` strategy, `strategy.job-total` = 4. The rendered name
`full-suite (2/4)` maps visually to `MIX_TEST_PARTITION=2` / `scoria_test2`. [ASSUMED — not
verified against live GHA run, but standard GHA documentation pattern]

### VF-8: GHA matrix aggregation — one `needs.*.result` entry per matrix job name [VERIFIED: CONTEXT.md D-04 + Phase 25 D-02]

GitHub aggregates all legs of a matrix strategy into a single `needs.full-suite.result`. The
derived fan-in test in `ci_policy_contract_test.exs` (line 266) derives by job NAME (`"full-suite"`)
not by leg name (`"full-suite (1/4)"`), so it is already matrix-tolerant. The `join(needs.*.result, ' ')`
loop in `verify-summary` evaluates the aggregated single result.

---

## Breaking Changes to Existing Contract Tests

This is the highest-footgun section. Three assertions in existing tests will turn RED the
moment `mix test --warnings-as-errors` is removed from the `test:` job. The planner MUST
include updates to these as explicit tasks, not as "implied by D-01."

### B-1: `ci_policy_contract_test.exs` — "test job runs semantic lane after runtime_to_handoff"

**Location:** lines 203–220

**Failing assertion (after Phase 26):**
```elixir
# Semantic precedes full-suite WAE inside test: job
assert index_of(test_body, @semantic_lane) <
         index_of(test_body, "run: mix test --warnings-as-errors")
```
`index_of/2` calls `flunk/1` when the needle is not found. After the move, `"run: mix test
--warnings-as-errors"` is absent from `test_body`. **Result: RED.**

**Required fix:** Remove the `"Semantic precedes full-suite WAE inside test: job"` comment
and the `index_of(test_body, "run: mix test --warnings-as-errors")` assertion. Replace with a
cross-job assertion: `assert Map.fetch!(blocks, "full-suite") =~ "mix test
--warnings-as-errors"` and `assert Map.fetch!(blocks, "full-suite") =~ "--partitions 4"`.

### B-2: `ci_policy_contract_test.exs` — "test job runs full suite WAE after closeout lanes; knowledge is a parallel job"

**Location:** lines 223–240

**Failing assertions (after Phase 26):**
```elixir
assert test_body =~ "run: mix test --warnings-as-errors"           # BREAKS
assert index_of(test_body, runtime_to_handoff) <
         index_of(test_body, "run: mix test --warnings-as-errors") # BREAKS (flunk)
```

**Required fix:** This test must be **renamed and restructured**. The `test:` job no longer
runs full-suite WAE. Rename to something like `"test job ends with semantic lane; full-suite is a
parallel matrix job"`. Replace the `"run: mix test --warnings-as-errors"` assertions with:
```elixir
refute test_body =~ "run: mix test --warnings-as-errors"   # full-suite moved out
full_suite_body = Map.fetch!(blocks, "full-suite")
assert full_suite_body =~ "mix test --warnings-as-errors"
assert full_suite_body =~ "--partitions 4"
assert full_suite_body =~ "needs: build"
```

### B-3: `verification_lanes_test.exs` — "ci lane ordering follows the canonical closeout chain"

**Location:** line 100

**Failing assertion (after Phase 26):**
```elixir
assert index_of(test_body, semantic) < index_of(test_body, "run: mix test --warnings-as-errors")
```
`test_body` is bounded by `"\n  test:"` → `"\n  ratchet:"`. After Phase 26, `"run: mix test
--warnings-as-errors"` no longer exists in that slice. **Result: RED (flunk).**

**Required fix:** Remove that assertion. The `test:` job now ends with `semantic` as its last
ordered step (the full-suite step has moved out). The last legitimate order assertion in
`test_body` becomes:
```elixir
assert index_of(test_body, runtime_to_handoff) < index_of(test_body, semantic)
```
Optionally add a cross-job assertion on `ci_workflow` directly:
```elixir
assert ci_workflow =~ "mix test --warnings-as-errors --partitions 4"
```

---

## Additional Tests Requiring Updates (Non-Breaking But Stale)

### U-1: `ci_policy_contract_test.exs` — "postgres service is configured only for test, knowledge, and connector jobs"

After Phase 26, `full-suite:` also has `services: postgres`. The test at line 179 asserts only
`test:`, `knowledge:`, `connector:` have `services:`. It will NOT fail (it only asserts the
three have it, not that only those three have it) — but it is now incomplete. Add:
```elixir
assert Map.fetch!(blocks, "full-suite") =~ "services:"
```

### U-2: `ci_policy_contract_test.exs` — "ci-verify.yml documents per-job intent comments"

After adding `full-suite:` with a `# full-suite:` comment, add to the existing test:
```elixir
assert ci_verify =~ "# full-suite:"
```

### U-3: `docs/MAINTAINERS.md` — CI gate map topology line and job→command table

Current topology line: `policy → build → { test, ratchet, knowledge, connector } → verify-summary`

Update to: `policy → build → { test, ratchet, knowledge, connector, full-suite[×4] } → verify-summary`

Add row to the job→command table:
```markdown
| `full-suite (k/4)` | `SCORIA_DB_PORT=55432 MIX_TEST_PARTITION=k mix test --warnings-as-errors --partitions 4` |
```

(No `SCORIA_DB_NAME` — absence is load-bearing; the maintainer sets `k` to the failing shard number.)

The contract test at line 442 ("maintainer CI gate map documents topology, parity, ratchet,
and failure diagnosis") currently does NOT assert `full-suite` is in the gate map. After Phase
26, add: `assert gate_map =~ "full-suite"` to that test.

### U-4: `ci.yml` header topology comment (line 17) and `ci-verify.yml` header comment (line 9)

Both contain `{ test, ratchet, knowledge, connector }`. Update to include `full-suite` for
consistency with the docs. Not tested by a contract test, but a reader-confusion issue.

### U-5: `docs/operator_verification.md` — CI topology paragraph (line 292)

Current: `policy → build → { test, ratchet, knowledge, connector } → verify-summary`
Update to include `full-suite[×4]`.

### U-6: `README.md` — CI topology reference (line 281)

Current: `policy → build → { test, ratchet, knowledge, connector } → verify-summary`
Update to include `full-suite[×4]`.

---

## Architecture Patterns

### New `full-suite:` Job Structure

The `full-suite:` job is a near-verbatim copy of the `test:` Postgres-needing job preamble,
minus `SCORIA_HEX_UNPACK_ROOT`, minus `SCORIA_DB_NAME`, minus the closeout steps, plus the
matrix strategy and `MIX_TEST_PARTITION`.

```yaml
# full-suite: sharded full ExUnit suite (WAE) — 4-way matrix on shared build artifact
full-suite:
  name: "full-suite (${{ matrix.partition }}/${{ strategy.job-total }})"
  runs-on: ubuntu-latest
  needs: build
  strategy:
    fail-fast: false
    matrix:
      partition: [1, 2, 3, 4]

  services:
    postgres:
      image: pgvector/pgvector:pg16
      env:
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: postgres
        POSTGRES_DB: scoria_test      # inert — ecto.create creates scoria_test{k}
      ports:
        - 55432:5432
      options: >-
        --health-cmd "pg_isready -U postgres"    # no -d: DB doesn't exist until ecto.create
        --health-interval 10s
        --health-timeout 5s
        --health-retries 10

  env:
    MIX_ENV: test
    MIX_TEST_PARTITION: ${{ matrix.partition }}   # job-level: propagates to ALL steps
    SCORIA_DB_HOST: localhost
    SCORIA_DB_PORT: 55432
    SCORIA_DB_USERNAME: postgres
    SCORIA_DB_PASSWORD: postgres
    # SCORIA_DB_NAME intentionally absent — activates partition DB path in config/test.exs

  steps:
    - uses: actions/checkout@v6

    - name: Install Erlang and Elixir
      id: beam
      uses: erlef/setup-beam@v1
      with:
        version-file: .tool-versions
        version-type: strict

    - name: Download compiled artifact
      uses: actions/download-artifact@v7
      with:
        name: build-test-env

    - name: Unpack compiled artifact (restores exact mtimes)
      run: tar -xzf build-test-env.tar.gz

    - name: Install dependencies (no-op when deps/ complete)
      run: mix deps.get

    # DB-prep: keep in sync with sibling parallel jobs
    - name: Prepare database
      run: |
        mix ecto.create
        mix ecto.migrate --to 20260511000300
        mix eval 'Scoria.TestSupport.Migrations.migrate_knowledge!()'
        mix ecto.migrate

    - name: Run full suite (shard ${{ matrix.partition }}/4)
      run: mix test --warnings-as-errors --partitions 4
```

Key differences from the `test:` job:
1. `strategy:` block with `fail-fast: false` and `matrix.partition: [1,2,3,4]`
2. `MIX_TEST_PARTITION: ${{ matrix.partition }}` at job-level env (NOT per-step)
3. No `SCORIA_DB_NAME` (absence is load-bearing)
4. No `SCORIA_HEX_UNPACK_ROOT`
5. No closeout steps (release_preview, adoption, etc.)
6. `pg_isready -U postgres` (no `-d scoria_test`) in health-cmd
7. `mix test --warnings-as-errors --partitions 4` (not `mix test --warnings-as-errors`)

### `after_suite` Zero-Test Guard Pattern

Pattern to add to `test/test_helper.exs`, following the existing Layer 2 guard:

```elixir
# Partition zero-test guard: fires only during sharded CI runs (MIX_TEST_PARTITION set).
# ExUnit exits 0 on a 0-test partition ({:noop,_} path) — this guard closes that hole.
# Never fires in local or lane runs (MIX_TEST_PARTITION is absent outside full-suite: job).
if System.get_env("MIX_TEST_PARTITION") do
  ExUnit.after_suite(fn %{total: total} ->
    if total == 0 do
      IO.puts(:stderr, "[full-suite partition #{System.get_env("MIX_TEST_PARTITION")}] after_suite: 0 tests executed — possible partition misconfiguration")
      exit({:shutdown, 1})
    end
  end)
end
```

Placement: AFTER the existing `ExUnit.after_suite/1` call for the knowledge guard (after
`ExUnit.start/1`). The two guards are independent and both safe.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Coverage proof | Custom test-count tracking / `mix test --dry-run` | Mix partition math (rem-completeness) | `--dry-run` does not exist; count drifts with added tests; magic number is a maintenance lie |
| Shard failure isolation | `continue-on-error: true` | `fail-fast: false` | `continue-on-error` reports failed legs as `success` to `needs.*.result` — documented false-green (community #45546) |
| DB-per-shard isolation | Per-step `SCORIA_DB_NAME` overrides | Job-level `MIX_TEST_PARTITION` + absent `SCORIA_DB_NAME` | Per-step env is a split-brain footgun (ecto.create and mix test see different env) |

---

## Common Pitfalls

### Pitfall 1: Setting `SCORIA_DB_NAME` in `full-suite:` env

**What goes wrong:** DB name resolves to `SCORIA_DB_NAME` value, not `scoria_test{k}`. All 4
shards hit the same DB and collide. Tests fail with race conditions or data bleed.
**Why it happens:** Copy-paste from `test:` job env block without reading the `||` logic.
**How to avoid:** D-02 is explicit: `SCORIA_DB_NAME` must be ABSENT. The `||` in
`config/test.exs` only falls through when `SCORIA_DB_NAME` is `nil`.
**Warning signs:** `mix ecto.create` succeeds but all 4 shards show the same database name
in logs.

### Pitfall 2: Setting `MIX_TEST_PARTITION` per-step instead of job-level

**What goes wrong:** `mix ecto.create` and `mix ecto.migrate` run without `MIX_TEST_PARTITION`
set, creating `scoria_testnil` (or failing). `mix test` then sees `scoria_test{k}` and the DB
doesn't exist.
**Why it happens:** Adding `MIX_TEST_PARTITION` only to the `mix test` step.
**How to avoid:** Set at `job.env:` level so it propagates to every step including `ecto.create`.

### Pitfall 3: Leaving `--partition N` in `mix test` invocation

**What goes wrong:** `mix test --partitions 4 --partition 2` → Mix does not recognise
`--partition` (without `s`) as a flag; it may be interpreted as an argument to `--partitions`
or rejected entirely.
**Why it happens:** Confusing `--partitions N` (total count) with a `--partition K` (leg
selector) that doesn't exist.
**How to avoid:** The invocation is ALWAYS `mix test --warnings-as-errors --partitions 4` —
`MIX_TEST_PARTITION` env (not a CLI flag) selects the leg.

### Pitfall 4: Adding `full-suite` to `verify-summary.needs` but using multi-line list syntax

**What goes wrong:** The contract test regex `~r/needs:\s*\[([^\]]+)\]/` only matches the
inline `[...]` syntax. Multi-line YAML `needs:` list syntax (each on its own line with `-`)
is not matched by the existing parser.
**Why it happens:** Wanting to "clean up" the needs list.
**How to avoid:** Keep `needs:` as an inline list `[policy, build, test, ratchet, knowledge, connector, full-suite]`.

### Pitfall 5: `continue-on-error: true` on the matrix strategy

**What goes wrong:** A failing leg reports `success` to `needs.*.result`, which passes
`verify-summary`, which passes `ci-gate`. False green.
**Why it happens:** Confusing `fail-fast: false` with `continue-on-error: true`.
**How to avoid:** Use ONLY `fail-fast: false`. Never `continue-on-error`.

### Pitfall 6: Forgetting to update the three breaking contract test assertions

**What goes wrong:** The policy job runs `ci_policy_contract_test.exs` and
`verification_lanes_test.exs` with WAE. After moving `mix test --warnings-as-errors` out of
`test:`, three assertions (`B-1`, `B-2`, `B-3` above) immediately fail. CI is RED from the
first commit.
**Why it happens:** The contract tests are maintained separately from the YAML they assert.
**How to avoid:** Run the policy test suite locally before committing the YAML change:
```bash
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors \
  test/scoria/ci_policy_contract_test.exs \
  test/scoria/verification_lanes_test.exs
```
The YAML change and contract test updates must be in the **same commit**.

### Pitfall 7: Positioning `full-suite:` BEFORE `ratchet:` in the YAML

**What goes wrong:** `verification_lanes_test.exs:79` extracts `test_body` bounded by
`"\n  ratchet:"`. If `full-suite:` appears between `test:` and `ratchet:`, the `test_body`
extraction stops at `full-suite:` instead (because `"\n  ratchet:"` would be further away and
the slice would include `full-suite:` content). The `index_of(test_body, semantic) < ...`
assertion behaviour changes unexpectedly.
**How to avoid:** Place `full-suite:` AFTER `connector:` and BEFORE `verify-summary:` (or
anywhere after all existing sibling jobs). Ordering is not load-bearing for correctness but
matters for the manual-slice extraction in `verification_lanes_test.exs`.

---

## Validation Architecture

> Nyquist consumes this section to generate VALIDATION.md. Each success criterion has a
> validation mechanism, the exact observable signal that proves it works, and the failure mode
> the validation catches (anti-vacuous-pass design).

---

### SC#1 — Full suite runs as `mix test --WAE --partitions 4` across 4-way matrix, each exporting `MIX_TEST_PARTITION`

**Validation mechanism:** Structural contract test in `ci_policy_contract_test.exs`

**Exact signal:** All of the following assertions pass in the policy job's WAE contract run:
```elixir
full_suite_body = Map.fetch!(job_blocks(ci_verify), "full-suite")
assert full_suite_body =~ "needs: build"
assert full_suite_body =~ "mix test --warnings-as-errors"
assert full_suite_body =~ "--partitions 4"
assert full_suite_body =~ "MIX_TEST_PARTITION"
assert full_suite_body =~ "${{ matrix.partition }}"
assert full_suite_body =~ "partition: [1, 2, 3, 4]"
assert full_suite_body =~ "fail-fast: false"
# Non-empty guard — a broken job_blocks/1 regex can't vacuously pass
assert MapSet.size(parallel_lanes) > 0
```
The policy job fails loudly on any regression (WAE, no manual check needed).

**Failure mode caught:** A developer adds `--partition K` instead of relying on env; or
removes `--partitions 4`; or forgets `MIX_TEST_PARTITION` at job-level env; or reduces the
matrix to `[1,2,3]`. All produce RED in the policy step before merge.

**Anti-vacuous-pass proof:** The non-empty guard on `parallel_lanes` (from the existing
derived fan-in test, line 280) ensures `job_blocks/1` parsed at least one job. The new
assertions use `Map.fetch!/2` which raises (not a silent empty string match) if the key
`"full-suite"` is absent.

---

### SC#2 — Each shard uses an isolated database keyed by `MIX_TEST_PARTITION`; shards never collide

**Validation mechanism:** Structural contract test + mathematical guarantee from `config/test.exs`

**Exact signal (structural part):** Contract assertion:
```elixir
full_suite_body = Map.fetch!(job_blocks(ci_verify), "full-suite")
# Absence is load-bearing — presence would break DB isolation
refute full_suite_body =~ "SCORIA_DB_NAME"
# MIX_TEST_PARTITION at job-level (not per-step)
assert full_suite_body =~ "MIX_TEST_PARTITION: ${{ matrix.partition }}"
# Has its own Postgres sidecar
assert full_suite_body =~ "services:"
```

**Exact signal (config correctness, already in place):**
```elixir
# config/test.exs — DO NOT change (already correct)
database:
  System.get_env("SCORIA_DB_NAME") ||
    "scoria_test#{System.get_env("MIX_TEST_PARTITION")}",
```
When `SCORIA_DB_NAME` is absent and `MIX_TEST_PARTITION=2`, this resolves to `"scoria_test2"`.
The DB-prep block in `full-suite:` (which runs under job-level env) creates and migrates
`scoria_test{k}` per shard. Each shard operates on a different Postgres DB name — collision is
structurally impossible.

**Failure mode caught:** If `SCORIA_DB_NAME` is accidentally set in `full-suite:` env, the
`refute full_suite_body =~ "SCORIA_DB_NAME"` assertion fails. If `MIX_TEST_PARTITION` is set
per-step only (not job-level), the ecto.create step creates the wrong DB.

**Anti-vacuous-pass proof:** The `refute` fails if the text IS present; the `assert` fails if
the text is NOT present. Both directions have teeth. `Map.fetch!/2` raises if `"full-suite"`
job is absent.

---

### SC#3 — Zero coverage loss: union of 4 shards' executed tests equals the prior full-suite test count

**Validation mechanism:** Three-layer defense (math + structural contract + runtime guard)

**Layer 1 — Partition math (compile-time, unconditional):**

The rem-completeness proof is documented as a comment in the contract test:
```elixir
# Rem-completeness proof (filter_by_partition/3, Elixir 1.19.5):
#   sorted_files |> Enum.with_index() |> Enum.filter(fn {_, i} -> rem(i, total) == partition - 1 end)
#   For total=4, partitions {1,2,3,4} cover rem values {0,1,2,3} — a complete residue system.
#   Union of 4 shards = full suite BY CONSTRUCTION. No runtime count needed.
assert full_suite_body =~ "--partitions 4"
assert full_suite_body =~ "partition: [1, 2, 3, 4]"
```
The proof is mathematical, not empirical. No test count drift, no magic number. Valid as long
as `--partitions 4` and `matrix.partition: [1,2,3,4]` are in sync.

**Layer 2 — Structural contract (catches wiring drift):**
Any change that breaks the math (e.g., `--partitions 3` with a `[1,2,3,4]` matrix, or vice
versa) produces a contract test failure. The assertions pin both `--partitions 4` and the
matrix list as separate facts that must agree.

**Layer 3 — `after_suite` zero-test guard (runtime, catches empty-shard footgun):**
```elixir
if System.get_env("MIX_TEST_PARTITION") do
  ExUnit.after_suite(fn %{total: total} ->
    if total == 0 do
      IO.puts(:stderr, "[full-suite partition ...] after_suite: 0 tests executed — possible partition misconfiguration")
      exit({:shutdown, 1})
    end
  end)
end
```
ExUnit exits 0 when `{:noop, _}` (0 tests run). This guard converts a 0-test exit-0 to
exit-1. It ONLY fires when `MIX_TEST_PARTITION` is set (CI `full-suite:` job). Never fires
in local `mix test`, lane runs, or the `test:` closeout job.

**Exact signal:** All three layers active = any shard running 0 tests is caught at exit-1;
any sync mismatch between `--partitions N` and `matrix.partition` list is caught by the
structural contract before merge.

**Failure mode caught:**
- A future test file deletion empties a partition → Layer 3 catches it.
- Someone changes `--partitions 3` but forgets to update the matrix → Layer 2 catches it.
- Someone removes `full-suite:` entirely → Layer 1 catches it (job_blocks can't find the key).

**Anti-vacuous-pass proof:** Layer 3 guard is off (no-op) during local runs — it cannot
false-negative in local CI. Layer 2 uses `Map.fetch!/2` which raises on a missing key. Layer 1
proof is mathematical, not assertion-based — it cannot vacuously pass.

---

### SC#4 — Only `verify-summary` is required; individual matrix shard names are never added as required checks

**Validation mechanism:** Two assertions + existing derived fan-in completeness test

**Exact signal:**

**Assert 1 — Targeted `full-suite ∈ verify-summary.needs` (new, specific to D-04):**
```elixir
verify_summary_body = Map.fetch!(job_blocks(ci_verify), "verify-summary")
assert verify_summary_body =~ "full-suite"
```
This is the "loud red for a future dev who adds the job but forgets the fan-in wiring" assertion
from CONTEXT.md D-04.

**Assert 2 — Derived subset assertion (existing, auto-catches `full-suite`):**
The existing test at line 266 derives all `needs: build` jobs (excluding policy, build,
verify-summary) and asserts each is in `verify-summary.needs`. Once `full-suite:` has
`needs: build`, it is auto-included in the derived set and auto-checked. No edits to the
existing derived test are needed — Phase 25 explicitly made this matrix-tolerant.

**Assert 3 — `if: always()` and skipped-fail guard remain:**
```elixir
body = Map.fetch!(job_blocks(ci_verify), "verify-summary")
assert body =~ "if: always()"
assert body =~ "join(needs.*.result"
assert body =~ ~s|!= "success"|
```
This existing test (line 301) continues to gate the fan-in correctness. Adding `full-suite` to
`verify-summary.needs` means `join(needs.*.result)` auto-includes the aggregated matrix result.

**Signal proving SC#4 (no per-shard required checks):** Branch protection requires `CI /
ci-gate` (unchanged). The individual shard names `"full-suite (1/4)"` etc. never appear in
branch protection settings — this is enforced by the existing architecture (ci.yml `ci-gate`
names `verify` and `e2e` as its only `needs:`). No contract test is needed for this negative
claim — it holds by construction.

**Failure mode caught:**
- Developer adds `full-suite:` job but forgets `verify-summary.needs` update → Assert 1 RED,
  derived subset test RED.
- Developer sets `continue-on-error: true` (false-green footgun) → Structural contract test
  fails if it pins `fail-fast: false` and `refute ... continue-on-error`. (Planner should
  add: `assert full_suite_body =~ "fail-fast: false"` and `refute full_suite_body =~
  "continue-on-error"`.)

**Anti-vacuous-pass proof:** The targeted Assert 1 is a positive assertion (flunks if absent).
The derived test has a non-empty guard (line 280). Both use `Map.fetch!/2`.

---

## Open Questions (RESOLVED)

### OQ-1: YAML insertion position for `full-suite:` relative to `connector:` and `ratchet:`

**What we know:** Phase 25 D-01 asserts parallel-shape (not byte-order). Adding `full-suite:`
AFTER `connector:` and BEFORE `verify-summary:` is safe for:
- `job_blocks/1` (parses by name, order-agnostic)
- The derived fan-in completeness test (name-based, not position-based)

**What's unclear:** If `full-suite:` is placed BETWEEN `test:` and `ratchet:`,
`verification_lanes_test.exs:79` extracts `test_body` bounded by `"\n  ratchet:"` — the
slice would be correct (stops at ratchet: not at full-suite:). But the downstream connector
extraction (line 127) bounded by `"\n  verify-summary:"` would then include `full-suite:` body
in `connector_body`. No existing assertion would false-fail on this, but it's surprising.

**Recommendation:** Place `full-suite:` AFTER `connector:` and BEFORE `verify-summary:`. This
is the most surgical position, matches the topology narrative (`connector` → `full-suite` →
`verify-summary`), and makes the `connector_body` boundary extraction unambiguous.

### OQ-2: Should `verify-summary` refute `full-suite` shard names in the required-check logic?

**What we know:** SC#4 holds by construction. The individual leg names (`full-suite (1/4)`)
never appear in `verify-summary.needs` — GitHub doesn't expose per-leg job names to
`needs:`.

**What's unclear:** No contract test currently asserts WHAT IS NOT in `verify-summary.needs`.

**Recommendation:** The positive assertion (`"full-suite" in verify-summary.needs`) is
sufficient. The negative claim (shard leg names not in branch protection) is enforced by
platform semantics, not a test. No additional assertion needed.

### OQ-3: Does the existing `test:` job comment need updating?

**What we know:** Line 102 in `ci-verify.yml` reads:
`# test: release_preview → closeout lanes → semantic → full-suite WAE`

After Phase 26, "full-suite WAE" has moved out. The comment becomes stale.

**Recommendation:** Update to:
`# test: release_preview → closeout lanes → semantic (full-suite WAE moved to full-suite: matrix job)`

No contract test asserts the exact comment text, so this is a prose-only update.

---

## Environment Availability

| Dependency    | Required By                       | Available | Version          | Fallback |
|---------------|-----------------------------------|-----------|------------------|----------|
| Elixir / Mix  | `mix test --partitions 4`         | ✓         | 1.19.5-otp-27    | —        |
| Erlang/OTP    | Runtime                           | ✓         | 27.3.2           | —        |
| PostgreSQL    | `mix ecto.create` per shard       | ✓ (GHA service) | pgvector/pgvector:pg16 | — |
| GHA ubuntu-latest | CI matrix runner             | ✓         | standard          | —        |

`.tool-versions` pins `erlang 27.3.2` and `elixir 1.19.5-otp-27` — `setup-beam version-file:
.tool-versions version-type: strict` resolves exactly these versions for the new job. No new
tools required.

---

## Validation Architecture (Nyquist summary)

| SC | Validation Mechanism | Automated Command | Observable Signal | Anti-Vacuous |
|----|---------------------|-------------------|-------------------|--------------|
| SC#1 | Structural contract test in `ci_policy_contract_test.exs` asserting `--partitions 4`, `MIX_TEST_PARTITION`, `matrix.partition: [1,2,3,4]`, `needs: build` | `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` | Policy job GREEN | `Map.fetch!/2` raises if `"full-suite"` key absent; non-empty guard on `parallel_lanes` |
| SC#2 | `refute full_suite_body =~ "SCORIA_DB_NAME"` + `assert full_suite_body =~ "MIX_TEST_PARTITION: ${{ matrix.partition }}"` | Same command | Policy job GREEN | `refute` fails if present; `assert` fails if absent |
| SC#3 | Layer 1: math proof comment; Layer 2: `--partitions 4` + `[1,2,3,4]` sync assertion; Layer 3: `after_suite` exit-1 on 0 tests | Layer 2: policy contract run; Layer 3: runs during `full-suite:` CI job | Policy job GREEN + no exit-0-with-0-tests in CI | Layer 3 is off locally (guard gated on `MIX_TEST_PARTITION`); Layer 2 uses `Map.fetch!/2` |
| SC#4 | Targeted `assert verify_summary_body =~ "full-suite"` + existing derived subset test | Same policy contract command | Policy job GREEN | Derived test has explicit non-empty guard; `Map.fetch!/2` raises on missing key |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `strategy.job-total` evaluates to `4` for a `matrix.partition: [1,2,3,4]` strategy | VF-7 | Job name renders as `full-suite (2/0)` — cosmetic, not functional |
| A2 | GHA `needs:` inline list `[..., full-suite]` is parsed identically to multi-line list by the platform | VF-6 | Fan-in wiring fails; verify-summary doesn't gate on full-suite result |

Both assumptions are low-risk (A1 is cosmetic; A2 is standard GHA YAML and matches existing `verify-summary.needs` syntax already used).

---

## Standard Stack (No New Dependencies)

This phase installs zero new packages. All capability is provided by:

- `mix test --partitions 4` — built-in Mix/ExUnit (Elixir 1.19.5) [VERIFIED: .tool-versions]
- `MIX_TEST_PARTITION` env — ExUnit built-in, `filter_by_partition/3` [VERIFIED: CONTEXT.md]
- `ExUnit.after_suite/1` — built-in ExUnit [VERIFIED: live test_helper.exs pattern]
- GitHub Actions matrix strategy — GHA built-in [VERIFIED: platform semantics]

**Package Legitimacy Audit:** Not applicable (no external packages installed).

---

## Sources

### Primary (HIGH confidence — verified against live codebase)
- `config/test.exs` — partition-awareness logic confirmed (lines 8–10)
- `test/test_helper.exs` — `after_suite` signature pattern confirmed (lines 27–34)
- `test/scoria/ci_policy_contract_test.exs` — `job_blocks/1`, `split_jobs/1`, all breaking assertions identified (full file read)
- `test/scoria/verification_lanes_test.exs` — breaking assertion at line 100, connector_body boundary at line 127 (full file read)
- `.github/workflows/ci-verify.yml` — live YAML structure, `verify-summary.needs` inline list syntax, health-cmd coupling (full file read)
- `.github/workflows/ci.yml` — `ci-gate` structure, topology comment (full file read)
- `.tool-versions` — `erlang 27.3.2`, `elixir 1.19.5-otp-27` (confirmed)
- `docs/MAINTAINERS.md` — topology line, job→command table, assertions that need `full-suite` row (full file read)
- Live file count: `find test -name "*_test.exs" | grep -v "fixtures/" | wc -l` = 151

### Secondary (MEDIUM confidence)
- `26-CONTEXT.md` — all four locked decisions, verified facts, footguns (authoritative — product of two deep research passes)
- `25-CONTEXT.md` — `job_blocks/1` parser design, derived fan-in test design, matrix-tolerant intent

### Tertiary (LOW / ASSUMED)
- `strategy.job-total` rendering in GHA job names — standard documentation, not verified against a live run

---

## Metadata

**Confidence breakdown:**
- Breaking assertions (B-1, B-2, B-3): HIGH — identified from direct code read, confirmed by tracing `index_of/2` flunk behaviour
- YAML structure (VF-6, VF-5): HIGH — confirmed from live `ci-verify.yml`
- Partition math (VF-2): HIGH — Python verification against live file count
- `after_suite` guard pattern (VF-4): HIGH — directly from live `test_helper.exs`
- GHA `strategy.job-total` (A1): ASSUMED — standard docs, no live run

**Research date:** 2026-06-16
**Valid until:** 2026-07-16 (stable platform — Elixir, ExUnit, GHA matrix semantics are not fast-moving)
