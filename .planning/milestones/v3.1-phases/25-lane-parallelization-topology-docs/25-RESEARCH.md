# Phase 25: Lane Parallelization + Topology Docs - Research

**Researched:** 2026-06-15
**Domain:** GitHub Actions CI topology, Elixir contract-test refactoring, YAML fan-in, docs-as-contract
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01 — Topology-aware refactor, NOT byte-order preservation.**
- Add `job_blocks/1` helper to `ci_policy_contract_test.exs` parsing `jobs:` into a `%{job_name => job_body}` map.
- Keep `split_jobs/1` for policy/build-vs-test-side slice tests.
- KEEP intra-`test:` step-order assertions: `release_preview < adoption < runtime_to_handoff < semantic < full-suite`.
- REWRITE ~4 cross-job assertions into parallel-shape: `ratchet`, `knowledge`, `connector` are top-level jobs with `needs: build`, not steps inside `test:`.
- KEEP `refute ... in VerificationLanes.closeout_order()` for `:connector` and `:support_copilot_gallery`.
- Apply intra-vs-cross split to `verification_lanes_test.exs` "ci lane ordering" test too.

**D-02 — Derived fan-in-completeness test + name-agnostic aggregation.**
- `verify-summary` aggregation: `if: always()`, `needs: [policy, build, test, ratchet, knowledge, connector]`, bash loop over `${{ join(needs.*.result, ' ') }}` that exits 1 on any result `!= "success"` (skipped = fail).
- Derived contract test: parse `ci-verify.yml`, derive set of top-level jobs with `needs: build`, assert each is in `verify-summary.needs` (subset assertion with non-empty guard).

**D-03 — Inline duplication; no composite action.**
- DB-prep needed by: `test`, `knowledge`, `connector` jobs.
- `ratchet` carries NO `services:` and NO DB-prep (no Ecto dependency confirmed).
- Duplicate preamble inline; add `# DB-prep: keep in sync with sibling parallel jobs` marker comment.

**D-04 — Prose + structure + new contract assertions (Option C).**
- `docs/MAINTAINERS.md` `## CI gate map`: rename `**Test job closeout**` heading, add topology line `policy → build → { test, ratchet, knowledge, connector } → verify-summary`, add job→command table.
- Update `ci_policy_contract_test.exs` docs-topology test: change `=~ "Test job closeout"` to new heading, ADD asserts naming each parallel lane and `verify-summary`.
- Update `docs/operator_verification.md` and `README` CI-topology line in lockstep in same commit.

**WR-01 (folded) — Policy cache-key/MIX_ENV mislabel.**
- Policy job compiles under default `MIX_ENV=dev` but uses `-test-mix-` cache key.
- Recommended fix: set `MIX_ENV: test` on policy job.
- Cache-key contract assertions (`assert ci_verify =~ ~r/key:.*-test-mix-/` and `assert ci_entry =~ ~r/key:.*-dev-mix-/`, plus `refute ... runner.os }}-mix-` guards) must stay green.

### Claude's Discretion
- Exact regex for `job_blocks/1` and whether new assertions live in `ci_policy_contract_test.exs` or a sibling file.
- Exact YAML file ordering of parallel sibling jobs (no longer load-bearing after D-01).
- WR-01 fix mechanism: set `MIX_ENV: test` vs relabel key.
- Whether gallery tail is a step inside `connector:` vs a separate job (ROADMAP default: step inside `connector:`).

### Deferred Ideas (OUT OF SCOPE)
- Full-suite `--partitions 4` sharding (Phase 26).
- Fixed-host-port Postgres flake, TEMP e2e diagnostic removal, retry policy (Phase 27).
- `mix ci` alias + velocity closeout (Phase 28).
- `docker-dx-fleet-hardening.md` (unrelated to CI topology).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PAR-01 | Heavy `verify / test` lanes run as parallel `needs:`-jobs (closeout `test:` chain, ratchet hygiene, knowledge, connector + advisory gallery) rather than one serial job. | Current serial `test:` job structure mapped; all 5 target lanes identified from current YAML steps. |
| PAR-02 | Single stable fan-in `verify-summary` aggregates all parallel verify jobs; `CI / ci-gate` required-check name unchanged; skipped children never individually required. | Current `ci-gate` bash idiom confirmed as mirror for new fan-in; `needs: [verify, e2e]` structure confirmed unchanged. |
| PAR-03 | `Scoria.VerificationLanes` byte-order/closeout-order contract tests stay green — every canonical lane still executes in its pinned order. | All contract assertions catalogued; intra-job vs cross-job split identified precisely. |
| DX-02 | `docs/MAINTAINERS.md`, `docs/operator_verification.md`, and `README` describe new parallel CI topology; docs-as-contract test stays green. | All three docs read; current state of each captured; specific assertions that must change identified. |
</phase_requirements>

---

## Summary

Phase 25 splits the current serial `ci-verify.yml` `test:` job into four parallel sibling jobs (`test`, `ratchet`, `knowledge`, `connector`) each depending on `build`, gated by a new `verify-summary` fan-in job. The implementation is almost entirely mechanics: YAML restructuring, contract-test refactoring to parallel-shape assertions, and docs updated in lockstep.

The research confirms that all four locked decisions are implementable without ambiguity. The codebase state is fully characterized: the current YAML has exactly one `test:` job with 14 steps (release_preview through gallery), `split_jobs/1` splits at `"\n  test:"`, and there are exactly 4 assertions that become cross-job under the split. The `ratchet` job (`tmp_preflight_test.exs` + `MIX_ENV=test mix test --WAE`) is confirmed to use only `ExUnit.Case` (no `DataCase`/Ecto) — no Postgres service needed.

The WR-01 fix (policy job compiles under `MIX_ENV=dev` but uses `-test-mix-` key) should be resolved by adding `env: { MIX_ENV: test }` to the policy job, consistent with the existing cache-key contract assertion `assert ci_verify =~ ~r/key:.*-test-mix-/`. Two additional folded cleanups from 23-REVIEW.md (WR-02 stale header comment, WR-03 stale test name) are low-risk and can fold into this same pass.

**Primary recommendation:** Implement in this wave order: (1) YAML restructuring + WR-01 fix, (2) contract test refactor (D-01 + D-02), (3) docs update (D-04). Keep all changes in one commit since the contract tests and docs must be updated in lockstep.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Parallel job topology (fan-out) | CI/CD (GitHub Actions YAML) | — | Job-level `needs:` graph is a GitHub Actions concept; can only live in YAML |
| Fan-in aggregation | CI/CD (GitHub Actions YAML) | — | `verify-summary` job is a YAML-only construct |
| Lane command strings (SSOT) | Application code (`VerificationLanes`) | Contract tests | `lib/scoria/verification_lanes.ex` is the SSOT; YAML and tests derive from it |
| Contract assertions (topology + fan-in) | Test layer (`ci_policy_contract_test.exs`) | `verification_lanes_test.exs` | CI topology is asserted as ExUnit tests per repo DNA |
| DB-prep block | CI/CD (YAML, inline per job) | — | `services:` is job-level only in GitHub Actions; cannot be extracted to composite action |
| Docs topology description | Docs layer (`MAINTAINERS.md`, `operator_verification.md`, `README`) | Contract tests | Docs updated in lockstep; contract tests assert docs stay current |

---

## Standard Stack

No new packages are installed in this phase. The implementation is purely:
- GitHub Actions YAML restructuring
- Elixir ExUnit test refactoring
- Markdown documentation updates

All tooling is already present in the repo.

**Version reference (from `.tool-versions`):** [VERIFIED: .tool-versions]
- Erlang 27.3.2
- Elixir 1.19.5-otp-27

---

## Package Legitimacy Audit

> Not applicable — this phase installs no external packages.

---

## Architecture Patterns

### System Architecture Diagram

```
ci.yml (PR/main entrypoint)
  └── verify (uses: ci-verify.yml)
       └── [ci-verify.yml reusable workflow]
            ├── policy (no DB, WAE contract tests)
            ├── build (needs: policy → compile once → upload artifact)
            │     [build-test-env artifact published here]
            ├── test  (needs: build → download artifact → Postgres → closeout chain + full WAE)
            ├── ratchet (needs: build → download artifact → tmp_preflight WAE, NO DB)
            ├── knowledge (needs: build → download artifact → Postgres → mix test.knowledge WAE)
            ├── connector (needs: build → download artifact → Postgres → mix test.connector WAE
            │              → gallery tail step)
            └── verify-summary (needs: [policy, build, test, ratchet, knowledge, connector]
                                if: always()
                                bash loop: join(needs.*.result) → exit 1 on any != "success")
  └── e2e (separate, MIX_ENV=dev, Playwright)
  └── ci-gate (needs: [verify, e2e], if: always()) ← UNCHANGED, branch protection target
```

### Current ci-verify.yml Structure (BEFORE phase)

Three jobs in serial: `policy → build → test`

The current `test:` job has these steps in order (line numbers from actual file):

1. `actions/checkout@v6`
2. `erlef/setup-beam@v1` (version-file: .tool-versions, version-type: strict)
3. `actions/download-artifact@v7` (name: build-test-env)
4. `tar -xzf build-test-env.tar.gz`
5. `mix deps.get`
6. `MIX_ENV=dev mix scoria.release_preview` (release_preview lane)
7. `mix archive.install hex phx_new --force`
8. DB-prep: `mix ecto.create` + `mix ecto.migrate --to 20260511000300` + `mix eval 'Scoria.TestSupport.Migrations.migrate_knowledge!()'` + `mix ecto.migrate`
9. `mix test.adoption` (adoption lane)
10. Upload artifact (failure-only: scoria-host-proof-last-failure)
11. `mix test.runtime_to_handoff`
12. `mix test.semantic_fast_path --warnings-as-errors`
13. `MIX_ENV=test mix test --warnings-as-errors test/scoria/warning_inventory/tmp_preflight_test.exs` (ratchet)
14. `mix test --warnings-as-errors` (full suite)
15. `mix test.knowledge --warnings-as-errors`
16. `mix test.connector --warnings-as-errors`
17. `mix scoria.test.support_copilot` (gallery, advisory)

**Steps 13 (ratchet) and beyond become separate parallel jobs.**

### Current ci.yml Structure (BEFORE phase)

```yaml
jobs:
  verify:    # uses: ./.github/workflows/ci-verify.yml
  e2e:       # Playwright, MIX_ENV=dev, Postgres scoria_dev DB
  ci-gate:   # needs: [verify, e2e], if: always()
              # per-named-child bash: if VERIFY != "success" → exit 1; if E2E != "success" → exit 1
```

The `ci-gate` bash idiom uses named per-child checks:
```bash
if [[ "$VERIFY" != "success" ]]; then exit 1; fi
if [[ "$E2E" != "success" ]]; then exit 1; fi
```

The new `verify-summary` generalizes this to name-agnostic `join(needs.*.result)` loop.

### Target ci-verify.yml Structure (AFTER phase)

```yaml
jobs:
  policy:          # unchanged (+ WR-01: add MIX_ENV: test)
  build:           # unchanged (needs: policy)
  test:            # needs: build; services: postgres (55432:5432)
                   # steps: checkout → setup-beam → download-artifact → tar -xzf → deps.get
                   #        → release_preview → phx_new install → DB-prep
                   #        → adoption → runtime_to_handoff → semantic → full WAE
  ratchet:         # needs: build; NO services; NO DB-prep
                   # steps: checkout → setup-beam → download-artifact → tar -xzf → deps.get
                   #        → MIX_ENV=test mix test --WAE tmp_preflight_test.exs
  knowledge:       # needs: build; services: postgres (55432:5432); DB-prep
                   # steps: checkout → setup-beam → download-artifact → tar -xzf → deps.get
                   #        → DB-prep → mix test.knowledge --WAE
  connector:       # needs: build; services: postgres (55432:5432); DB-prep
                   # steps: checkout → setup-beam → download-artifact → tar -xzf → deps.get
                   #        → DB-prep → mix test.connector --WAE → mix scoria.test.support_copilot
  verify-summary:  # needs: [policy, build, test, ratchet, knowledge, connector]
                   # if: always()
                   # bash: join(needs.*.result) loop, exit 1 on any != "success"
```

### Per-job Preamble (inline, all non-policy jobs)

Per D-03, each job that needs the artifact duplicates verbatim:
```yaml
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
```

Marker comment to add after preamble for Postgres-needing jobs:
```yaml
# DB-prep: keep in sync with sibling parallel jobs
```

### DB-prep Block (Postgres-needing jobs: test, knowledge, connector)

```yaml
- name: Prepare database
  run: |
    mix ecto.create
    mix ecto.migrate --to 20260511000300
    mix eval 'Scoria.TestSupport.Migrations.migrate_knowledge!()'
    mix ecto.migrate
```

These literal strings are grepped by contract tests — they MUST remain verbatim in `ci-verify.yml`.

### verify-summary Fan-in Job

```yaml
verify-summary:
  runs-on: ubuntu-latest
  needs: [policy, build, test, ratchet, knowledge, connector]
  if: always()
  steps:
    - name: Assert all parallel verify lanes succeeded
      env:
        RESULTS: ${{ join(needs.*.result, ' ') }}
      run: |
        set -euo pipefail
        for result in $RESULTS; do
          if [[ "$result" != "success" ]]; then
            echo "verify-summary failed: a parallel lane result was $result"
            exit 1
          fi
        done
        echo "verify-summary passed: all parallel lanes succeeded."
```

This mirrors the `ci-gate` idiom but is name-agnostic — adding a lane to `needs:` auto-includes it in the result check.

### job_blocks/1 Parser (D-01)

New helper alongside existing `split_jobs/1` in `ci_policy_contract_test.exs`:

```elixir
defp job_blocks(content) do
  # Match all top-level job names (2-space indent, followed by colon + newline)
  job_names = Regex.scan(~r/^  (\w[\w-]*):/m, content) |> Enum.map(&Enum.at(&1, 1))

  Enum.reduce(Enum.zip(job_names, tl(job_names) ++ [nil]), %{}, fn {job, next_job}, acc ->
    start_marker = "\n  #{job}:"
    end_marker = if next_job, do: "\n  #{next_job}:", else: nil

    body =
      case :binary.match(content, start_marker) do
        {start, _} ->
          slice = String.slice(content, start, byte_size(content))
          if end_marker do
            case :binary.match(slice, end_marker) do
              {stop, _} -> String.slice(slice, 0, stop)
              :nomatch -> slice
            end
          else
            slice
          end
        :nomatch -> ""
      end

    Map.put(acc, job, body)
  end)
end
```

The planner has discretion on exact regex — this is a starting-point pattern. The important invariant: it must produce a `%{"test" => body, "ratchet" => body, ...}` map usable for parallel-shape assertions.

### Anti-Patterns to Avoid

- **Byte-order assertions for independent parallel jobs:** After the split, asserting `index_of(ratchet) < index_of(knowledge)` would be a byte-accident that cries-wolf RED on a safe parallel-job reorder.
- **Per-child named checks in verify-summary:** Do not replicate `ci-gate`'s `if [[ "$RATCHET" != "success" ]]` pattern in the new fan-in; use the name-agnostic join loop instead.
- **Composite action extraction for services:** GitHub Actions forbids `services:` in composite actions — any extraction leaves the riskiest block still duplicated.
- **Vacuous non-empty guard omission:** The fan-in completeness test (derives set of jobs with `needs: build`, asserts subset of `verify-summary.needs`) must include a non-empty guard so a broken regex cannot vacuously pass with an empty set.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fan-in result aggregation | Per-child named bash checks | `join(needs.*.result)` loop over space-separated results | Name-agnostic; adding a lane to `needs:` auto-includes it |
| YAML job-body parsing | Hand-written string search | Regex scan on `^  (\w[\w-]*):` (indent-2 top-level) | ~15-line helper that composes with existing `split_jobs/1` |
| Reusable preamble | Composite action | Inline duplication with sync comment | `services:` is job-level only; contract greps require literal strings in YAML |

---

## Runtime State Inventory

> Not applicable — this is a CI/devops restructuring phase, not a rename/refactor/migration.

---

## Current Contract-Test State (Precise Catalogue)

### `ci_policy_contract_test.exs` — Assertions by Category

**Assertions that use `split_jobs/1` and STAY valid after the split (keep unchanged):**

| Test | Why still valid |
|------|----------------|
| `"policy job runs warning baseline..."` (L140) | Uses `split_jobs/1`; `policy_section` still exists and is unchanged |
| `"postgres service is configured only for the test job"` (L170) | Asserts `refute policy_section =~ "services:"` and `assert test_section =~ "services:"` — still true; `test:` still carries Postgres |
| `"policy job does not run warning_ratchet.test"` (L265) | Policy section unchanged |
| `"build job exists in policy-side slice..."` (L283) | Build is in policy-side slice; unchanged |
| `"build job uploads artifact and test job downloads it"` (L294) | Both still true |
| `"test job needs build, not policy directly"` (L302) | `test:` still has `needs: build` |
| `"cache keys include MIX_ENV segment..."` (L273) | Still grep across full file |
| `"ci-verify.yml prepares knowledge migrations..."` (L84) | Literal DB-prep strings still in `ci-verify.yml` (now in `test:` and other parallel jobs) |

**Assertions that become BROKEN after the split (must rewrite to parallel-shape):**

1. `"test job runs semantic lane after runtime_to_handoff and before ratchet hygiene"` (L187)
   - Currently: `index_of(test_section, @semantic_lane) < index_of(test_section, "MIX_ENV=test mix test...tmp_preflight_test.exs")`
   - After split: ratchet is a separate top-level job; `index_of` in `test_section` won't find the ratchet command.
   - Rewrite: keep the intra-`test:` assertion (`runtime_to_handoff < semantic < full-suite`); replace the ratchet ordering with a parallel-shape assertion (ratchet is in `job_blocks("ratchet")`, has `needs: build`, is NOT in `test_section`).

2. `"test job runs full suite WAE after closeout lanes and before knowledge WAE lane"` (L202)
   - Currently: `index_of(test_section, "run: mix test --WAE") < index_of(test_section, "mix test.knowledge --WAE")`
   - After split: knowledge is a separate top-level job; the second half of this assertion breaks.
   - Rewrite: keep `runtime_to_handoff < full-suite` intra-`test:` assertion; replace the knowledge ordering with parallel-shape (knowledge is in `job_blocks("knowledge")`, has `needs: build`).

3. `"test job runs connector lane after knowledge WAE and before gallery lane"` (L216)
   - Currently: `index_of(test_section, knowledge_cmd) < index_of(test_section, connector_cmd) < index_of(test_section, gallery_cmd)`
   - After split: knowledge, connector, and gallery are all outside `test_section`.
   - Rewrite: connector and gallery are in `job_blocks("connector")` as sequential steps (gallery is a tail step); assert `index_of(connector_body, connector_cmd) < index_of(connector_body, gallery_cmd)`. The `refute :connector in VerificationLanes.closeout_order()` KEEPS unchanged.

4. `"test job runs support copilot gallery lane after knowledge WAE..."` (L229)
   - Currently: `index_of(test_section, knowledge_cmd) < index_of(test_section, gallery_cmd)`
   - After split: gallery moves inside `connector` job.
   - Rewrite: assert gallery step is inside `job_blocks("connector")`; assert comes after connector cmd within that body. The `refute :support_copilot_gallery in VerificationLanes.closeout_order()` KEEPS unchanged.

**Assertion to update (docs topology assertion):**

- `"maintainer CI gate map documents topology, parity, ratchet, and failure diagnosis"` (L351)
  - Currently: `assert gate_map =~ "Test job closeout"`
  - After phase: change to new heading (e.g., `"Parallel verify jobs"`); ADD asserts for `"ratchet"`, `"knowledge"`, `"connector"`, `"verify-summary"` appearing in gate_map.

**New assertions to add:**

- Fan-in completeness derived test (D-02): parse `ci-verify.yml` for top-level jobs with `needs: build`, assert each is in `verify-summary.needs`, non-empty guard.

**Assertions that need PHRASING update (not logic change):**

- `"test job depends on policy and preserves closeout chain order"` (L154) — currently asserts `needs: policy` but the `test` job now has `needs: build`. The assertion `ci_verify =~ "needs: policy"` is still true (policy and build both appear), but the test name is now misleading (WR-03). Rename the test to `"test job depends on build and preserves closeout chain order"` and update the `needs: policy` assertion to `needs: build` for the `test` job check.

**Comment to update (WR-02):**

- `ci.yml` line 17: `# Two-job topology: policy (fail cheap, no Postgres) → test (canonical closeout + full WAE).` — update to reflect the new multi-job structure after the parallel split.
- `ci-verify.yml` header comment (line 9): `# Reusable CI SSOT: policy (fail cheap, no Postgres) → build (compile once) → test (canonical closeout + full WAE).` — update to reflect the full topology.

### `verification_lanes_test.exs` — Assertions by Category

**Assertions that STAY valid unchanged:**

| Test | Why |
|------|-----|
| `"lane contract defines command, env, prerequisites, and exclusions..."` (L6) | Pure `VerificationLanes` module test; no YAML |
| `"closeout chain stays pinned to release-preview, adoption, runtime-to-handoff"` (L30) | Pure module test |
| `"default and runtime-to-handoff lanes share the same optional setup exclusions"` (L46) | Pure module test |
| `"connector lane stays advisory outside closeout order"` (L55) | Pure module test; `refute :connector in closeout_order()` still true |
| `"support copilot gallery lane stays advisory outside closeout order"` (L61) | Pure module test |

**Assertion that becomes BROKEN after the split:**

- `"ci lane ordering follows the canonical closeout chain"` (L67)
  - Currently: asserts byte-order for `release_preview < adoption < runtime_to_handoff < semantic < full-suite` AND `knowledge < connector < gallery` — all in one file scan.
  - After split: the last three (`knowledge < connector < gallery`) are cross-job byte-positions; asserting them would be byte-accidents.
  - Rewrite: KEEP the intra-`test:` step order (`release_preview < adoption < runtime_to_handoff < semantic < full-suite`) by scoping to the `test:` job body (via `job_blocks("test")`). REPLACE the `knowledge < connector < gallery` ordering with parallel-shape assertions: knowledge is in a separate job body, connector is in a separate job body, gallery is a step in connector's body after the connector command.

---

## WR-01: Policy Cache-Key / MIX_ENV Mislabel — Precise Facts

**Current state (confirmed from file):**
- Policy job (line 14–54 in `ci-verify.yml`): has NO `env: MIX_ENV:` at job level
- Policy job's cache key (line 35): `...-test-mix-${{ hashFiles('**/mix.lock') }}`
- Policy job's `mix compile --warnings-as-errors` step (line 48): runs under `MIX_ENV=dev` (Elixir default)
- Build job (line 57–98): has `env: MIX_ENV: test`; also uses `-test-mix-` cache key

**Recommended fix:** Add `env: { MIX_ENV: test }` to the policy job (between `runs-on: ubuntu-latest` and `steps:`).

**Cache-key contract assertions that must stay green:**
- `assert ci_verify =~ ~r/key:.*-test-mix-/` (line 277) — still passes: both policy AND build use `-test-mix-` key
- `assert ci_entry =~ ~r/key:.*-dev-mix-/` (line 278) — unchanged; `ci.yml` e2e job uses `-dev-mix-`
- `refute ci_verify =~ ~r/key: \$\{\{ runner\.os \}\}-mix-/` (line 279) — unchanged
- `refute ci_entry =~ ~r/key: \$\{\{ runner\.os \}\}-mix-/` (line 280) — unchanged

**Additional assertion to add (pins the WR-01 fix):**
```elixir
# In the policy job assertions block:
assert policy_section =~ "MIX_ENV: test"
```
This pins the invariant that policy now compiles under test env.

---

## Ratchet Job: DB Dependency Confirmed Absent

**Verified:** `test/scoria/warning_inventory/tmp_preflight_test.exs` uses `use ExUnit.Case, async: false` — NOT `DataCase` or any Ecto case. [VERIFIED: source file read]

**Verified:** `lib/mix/tasks/scoria.warning_ratchet.test.ex` and `lib/mix/tasks/scoria.warning_ratchet.check.ex` have zero references to `Ecto`, `Repo`, `postgres`, or `database`. They shell out to `System.cmd("mix", ["scoria.warning_ratchet.check"], ...)` and run `Mix.Task.run("test", ...)` on high-signal WAE paths — pure compile-time analysis. [VERIFIED: source files read]

**Conclusion:** The `ratchet:` parallel job carries:
- Standard preamble (checkout, setup-beam, download-artifact, tar -xzf, deps.get)
- NO `services: postgres`
- NO DB-prep block
- Single step: `MIX_ENV=test mix test --warnings-as-errors test/scoria/warning_inventory/tmp_preflight_test.exs`

This keeps the "one `test:` job carrying Postgres / no `services:` before it" contract clean, and the `"postgres service is configured only for the test job"` test assertion must be updated to name the full set of Postgres-carrying jobs (`test`, `knowledge`, `connector`) not just `test`.

---

## Docs: Current State vs Required Changes

### `docs/MAINTAINERS.md` `## CI gate map` section

**Current state (L6–61):**
- Header sentence describes "two jobs in order: policy (no Postgres) first, then test"
- `**Test job closeout (Postgres on 55432):**` heading lists all 9 steps as a serial numbered list (including ratchet, knowledge, connector, gallery as steps 5–9)
- "Verification lanes in PR CI" table lists all lanes
- Local parity section, ratchet-is-maintainer-only section, "when CI fails" command table

**Required changes (D-04):**
1. Rename `**Test job closeout (Postgres on 55432):**` to an accurate parallel-jobs heading (e.g., `**Parallel verify jobs (each needs: build):**`)
2. Add topology line: `policy → build → { test, ratchet, knowledge, connector } → verify-summary`
3. Add job→command table (the highest-value maintainer artifact for debugging which job failed):

   | Job | Local command |
   |-----|---------------|
   | `test` | `SCORIA_DB_PORT=55432 mix test --warnings-as-errors` |
   | `ratchet` | `MIX_ENV=test mix test --warnings-as-errors test/scoria/warning_inventory/tmp_preflight_test.exs` |
   | `knowledge` | `SCORIA_DB_PORT=55432 mix test.knowledge --warnings-as-errors` |
   | `connector` | `SCORIA_DB_PORT=55432 mix test.connector --warnings-as-errors` |

4. Keep all existing verified content (hex release section, ratchet commands, failure diagnosis table).

**Contract assertions that change (in `ci_policy_contract_test.exs`):**
- `"maintainer CI gate map documents topology, parity, ratchet, and failure diagnosis"` (L351):
  - Change: `assert gate_map =~ "Test job closeout"` → `assert gate_map =~ "Parallel verify jobs"` (or whatever new heading is chosen)
  - Add: `assert gate_map =~ "ratchet"`, `assert gate_map =~ "knowledge"`, `assert gate_map =~ "connector"`, `assert gate_map =~ "verify-summary"`

**Contract assertions that stay unchanged:**
- `"CI-03 documents CI gate map for maintainers"` (L252) — `assert maintainer_docs =~ "CI gate map"` etc. all still true
- `"maintainer gate map pins v2.10 PR vs release proof depth"` (L333) — the `**PR vs release proof depth**` section is unchanged
- `"MAINTAINERS.md documents fully automated release train"` (L75) — `## Hex release & recovery` section unchanged

### `docs/operator_verification.md`

**Current state:** No CI topology section visible in the first 120 lines (adopter-focused guide). The `operator_verification.md` contains the lane troubleshooting sections (semantic fast-path, etc.). There is a reference to CI gate map in MAINTAINERS.md narrative.

**Required changes (D-04):** Update the CI gate map narrative (if any) to reflect the parallel topology. The file does not have a prominent "CI gate map" section in the visible portion — search for any mention of "two-job" or "serial" topology language and update.

**Grep result:** `grep "CI topology\|parallel\|ci-gate\|verify-summary" docs/operator_verification.md` returned zero results — this file has no topology description in the current state. The DX-02 requirement says to update it; add a brief CI topology note (e.g., in a "CI" subsection) describing the parallel structure.

### `README.md`

**Current state (lines 279–284):**
```markdown
## For maintainers

- [Maintainer guide](docs/MAINTAINERS.md) — CI topology, release operations, warning ratchet
- [Operator verification](docs/operator_verification.md) — adopter verification ladder (also used as docs extra)

For broader repo-health context outside the canonical lane proofs, run `mix test` locally or see the maintainer guide.
```

**Line 281** reads: `[Maintainer guide](docs/MAINTAINERS.md) — CI topology, release operations, warning ratchet`

**Line 290** (from grep): `CI topology, release operations, warning ratchet commands, and installer contract proofs live in [docs/MAINTAINERS.md](MAINTAINERS.md#ci-gate-map-maintainers).`

**Required changes (DX-02):** Update the CI-topology line to mention the parallel structure (e.g., "parallel CI topology with `verify-summary` fan-in"). The `README` contract assertion `"README links maintainers to maintainer guide near status section"` (L364) asserts `assert readme =~ "CI topology"` — this passes as long as the phrase "CI topology" remains somewhere in that section.

---

## Common Pitfalls

### Pitfall 1: Breaking the `split_jobs/1`-based tests with the wrong YAML layout

**What goes wrong:** Moving `test:` job below the new parallel jobs in YAML byte-order so that `split_jobs/1` (which splits at `"\n  test:"`) produces a `policy_section` that excludes `build:`.
**Why it happens:** YAML job order is semantically free (only `needs:` graph matters), but `split_jobs/1` splits on the literal `"\n  test:"` position.
**How to avoid:** Keep `test:` as the first non-policy/build job in YAML byte-order, so `split_jobs/1` continues to work correctly for the policy-side slice tests that use it. The new parallel jobs (`ratchet`, `knowledge`, `connector`, `verify-summary`) go AFTER `test:` in the YAML.
**Warning signs:** `split_jobs/1`-based tests fail with `"expected policy and test jobs in ci-verify.yml"`.

### Pitfall 2: Vacuous fan-in completeness test

**What goes wrong:** The derived fan-in-completeness test (parse jobs with `needs: build`, assert subset of `verify-summary.needs`) uses a broken regex and matches zero jobs — the empty-set passes the subset assertion vacuously.
**Why it happens:** A regex that doesn't match indent-2 `needs: build` annotations returns `[]`; `MapSet.subset?(MapSet.new([]), anything)` is always true.
**How to avoid:** Add a non-empty guard: `assert Enum.count(parallel_lanes) > 0, "expected at least one job with needs: build"` before the subset assertion.
**Warning signs:** The test passes even when `verify-summary.needs` is empty or wrong.

### Pitfall 3: Gallery tail step as a separate job breaks `verify-summary` needs count

**What goes wrong:** If gallery becomes a 7th top-level job (not a step inside `connector`), the derived fan-in-completeness test derives it as a `needs: build` job and requires it to be in `verify-summary.needs`. But gallery is advisory and the CONTEXT.md says it is a step inside `connector`, not a job.
**Why it happens:** ROADMAP ambiguity — "tail" can be interpreted as a job.
**How to avoid:** Per D-04 discretion, gallery is a step inside `connector:`, not a separate job. The `connector:` job body includes both `mix test.connector --WAE` and `mix scoria.test.support_copilot` as sequential steps.
**Warning signs:** Fan-in completeness test unexpectedly includes gallery in the derived set.

### Pitfall 4: Postgres `services:` on `ratchet` job breaks the services contract test

**What goes wrong:** Adding `services: postgres` to the `ratchet:` job to "be safe" breaks the assertion `"postgres service is configured only for the test job"`.
**Why it happens:** Ratchet was previously a step inside the Postgres-carrying `test:` job; naively moving it as a job may carry the services block along.
**How to avoid:** Ratchet confirmed to have zero Ecto/DB dependencies. The `ratchet:` job must have NO `services:` block. The existing contract test that checks `refute policy_section =~ "services:"` may need to broaden its assertion — verify whether `ratchet:` body ends up in `policy_section` or `test_section` after the split (it ends up in neither; it's a new top-level job, so `split_jobs/1`-based tests won't see it). The "postgres service is configured only for the test job" test needs to be updated to reflect that Postgres now lives in `test`, `knowledge`, and `connector` jobs.

### Pitfall 5: `SCORIA_LANE_CONTRACT_ONLY` step runs with broken contract assertions

**What goes wrong:** The policy job runs `mix test --no-start --WAE ci_policy_contract_test.exs verification_lanes_test.exs adoption_surface_test.exs` with `SCORIA_LANE_CONTRACT_ONLY=true`. If the contract test assertions are updated but the YAML topology is not committed yet (e.g., in a split commit), the policy job fails because the assertions don't match the YAML.
**Why it happens:** The contract tests, YAML, and docs form a three-way lockstep.
**How to avoid:** Per D-04, all three (YAML, contract tests, docs) must be committed in the same commit. The wave plan should make the single-commit constraint explicit.

### Pitfall 6: WR-01 fix breaks alternate cache-key assertion path

**What goes wrong:** Adding `MIX_ENV: test` to the policy job might trigger a new test-env compile in the policy job that produces a `-test-mix-` artifact — but the policy job still has `restore-keys: ...-test-mix-` which already warms from the same key that `build` will write. This is actually correct behavior, but could cause confusion about why policy now compiles faster than expected.
**Why it happens:** The cache-restore for policy will now hit the `build` job's artifact if policy runs after a previous warm build on the same branch.
**How to avoid:** No action needed — this is the intended behavior. The cache contract assertions (`assert ci_verify =~ ~r/key:.*-test-mix-/`) still pass.

---

## Code Examples

Verified patterns from actual codebase files:

### Current `split_jobs/1` helper (keep unchanged)

```elixir
# Source: test/scoria/ci_policy_contract_test.exs L434
defp split_jobs(content) do
  case :binary.match(content, "\n  test:") do
    {index, _length} ->
      [String.slice(content, 0, index), String.slice(content, index, byte_size(content))]
    :nomatch ->
      flunk("expected policy and test jobs in ci-verify.yml")
  end
end
```

This still works after the split: `test:` remains the first non-policy/build job in YAML byte-order.

### Current `ci-gate` bash idiom (model for `verify-summary`)

```yaml
# Source: .github/workflows/ci.yml L149
- name: Verify required CI lanes
  env:
    VERIFY: ${{ needs.verify.result }}
    E2E: ${{ needs.e2e.result }}
  run: |
    set -euo pipefail
    if [[ "$VERIFY" != "success" ]]; then
      echo "ci-gate failed: verify workflow result was $VERIFY"
      exit 1
    fi
    if [[ "$E2E" != "success" ]]; then
      echo "ci-gate failed: e2e lane result was $E2E"
      exit 1
    fi
    echo "ci-gate passed: all required lanes succeeded."
```

The new `verify-summary` replaces the per-child named pattern with a name-agnostic loop.

### Current `VerificationLanes` ci_command values (verbatim — planner reference)

```elixir
# Source: lib/scoria/verification_lanes.ex
:release_preview  → ci_command: "MIX_ENV=dev mix scoria.release_preview"
:adoption         → ci_command: "mix test.adoption"
:runtime_to_handoff → ci_command: "mix test.runtime_to_handoff"
:semantic_fast_path → ci_command: "mix test.semantic_fast_path"  # (no --WAE suffix in SSOT, WAE added in step)
:knowledge        → ci_command: "mix test.knowledge"             # (no --WAE suffix in SSOT, WAE added in step)
:connector        → ci_command: "mix test.connector --warnings-as-errors"
:support_copilot_gallery → ci_command: "mix scoria.test.support_copilot"
```

### Parallel-shape assertion pattern (D-01 example)

```elixir
# For ratchet (formerly: index_of in test_section):
defp assert_parallel_job_with_needs_build(job_blocks, job_name) do
  job_body = Map.fetch!(job_blocks, job_name)
  assert job_body =~ "needs: build", "expected #{job_name} job to have needs: build"
  refute job_body =~ "needs: policy", "#{job_name} should not depend on policy directly"
end

# Example usage:
test "ratchet is a parallel job with needs: build, no Postgres service" do
  ci_verify = File.read!(@ci_verify)
  blocks = job_blocks(ci_verify)

  assert_parallel_job_with_needs_build(blocks, "ratchet")
  refute Map.fetch!(blocks, "ratchet") =~ "services:"
  assert Map.fetch!(blocks, "ratchet") =~ "tmp_preflight_test.exs"
end
```

### Fan-in completeness test skeleton (D-02)

```elixir
test "verify-summary fan-in wires every parallel verify lane (derived)" do
  ci_verify = File.read!(@ci_verify)
  blocks = job_blocks(ci_verify)

  # Derive: all top-level jobs (excluding policy, build, verify-summary) that have needs: build
  parallel_lanes =
    blocks
    |> Enum.filter(fn {name, body} ->
      name not in ["policy", "build", "verify-summary"] and body =~ "needs: build"
    end)
    |> Enum.map(fn {name, _} -> name end)
    |> MapSet.new()

  # Non-empty guard: a broken regex cannot vacuously pass
  assert MapSet.size(parallel_lanes) > 0,
         "expected at least one parallel verify lane with needs: build; regex may be broken"

  # Parse verify-summary.needs
  verify_summary_body = Map.fetch!(blocks, "verify-summary")
  needs_match = Regex.run(~r/needs:\s*\[([^\]]+)\]/, verify_summary_body)
  verify_summary_needs =
    case needs_match do
      [_, needs_str] -> needs_str |> String.split(",") |> Enum.map(&String.trim/1) |> MapSet.new()
      nil -> flunk("verify-summary job has no needs: [...] block")
    end

  # Subset assertion: every parallel lane is wired
  assert MapSet.subset?(parallel_lanes, verify_summary_needs),
         "unwired lanes: #{inspect(MapSet.difference(parallel_lanes, verify_summary_needs))}"
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single serial `test:` job with all lanes as steps | Parallel sibling jobs (`test`, `ratchet`, `knowledge`, `connector`) each `needs: build` | Phase 25 | Critical-path reduced; one slow lane no longer blocks others |
| Byte-order assertions for all lanes | Intra-job step-order (real) vs parallel-shape (cross-job) | Phase 25 | Eliminates cry-wolf RED on safe job reorders |
| Individual ci-gate children (`needs: [verify, e2e]`) | `verify-summary` fan-in aggregates parallel lanes; `ci-gate` consumes `verify` result unchanged | Phase 25 | Branch protection untouched; adding a lane auto-includes it in fan-in |

**Deprecated/outdated after this phase:**

- `# Two-job topology:` comment in `ci.yml` header (WR-02): update to reflect three-job topology (policy/build/parallel lanes + e2e + ci-gate).
- `"test job depends on policy and preserves closeout chain order"` test name (WR-03): rename to `"test job depends on build and preserves closeout chain order"`.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Gallery tail is a step inside `connector:` job, not a separate top-level job | Architecture Patterns | If gallery is a separate job, it must be added to `verify-summary.needs`; fan-in completeness test derives it; minor YAML rework |
| A2 | The planner may choose to put `ratchet/knowledge/connector/verify-summary` jobs AFTER `test:` in YAML byte-order to preserve `split_jobs/1` semantics | Architecture Patterns | If any new job is inserted BEFORE `test:`, `split_jobs/1` still works (splits at first `"\n  test:"`), but the policy-side slice now includes the new job. Keep `test:` as the immediate successor of `build:` |

---

## Open Questions

1. **`"postgres service is configured only for the test job"` test (L170) — how to handle?**
   - What we know: After the split, Postgres services exist in `test`, `knowledge`, and `connector` jobs. The current assertion `assert test_section =~ "services:"` and `refute policy_section =~ "services:"` uses `split_jobs/1` — `test_section` will now include everything from `"\n  test:"` to end-of-file, which includes the new parallel jobs. The assertion `assert test_section =~ "services:"` will still pass (knowledge and connector have services). The `refute policy_section =~ "services:"` also still passes.
   - What's unclear: Is the test still semantically correct? It originally meant "only the `test:` job, not policy". Now it's true but imprecise — `ratchet` is also in `test_section` but has no services.
   - Recommendation: Update the test to use `job_blocks` to be explicit: assert `test`, `knowledge`, `connector` blocks have `services:`, assert `policy`, `build`, `ratchet`, `verify-summary` blocks do not.

2. **`operator_verification.md` topology content — how much to add?**
   - What we know: The file currently has zero CI topology mentions.
   - What's unclear: How much prose is appropriate for an adopter-facing doc?
   - Recommendation: Add a minimal CI note (1–2 sentences + topology line) — enough to satisfy DX-02 and the contract assertion without over-documenting CI internals in an adopter guide.

---

## Environment Availability

> This phase modifies only YAML, Elixir source, and Markdown files. No external dependencies required at execution time. GitHub Actions environment is the execution target — not local.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Erlang | Local test run | ✓ | 27.3.2 (.tool-versions) | — |
| Elixir | Local test run | ✓ | 1.19.5-otp-27 (.tool-versions) | — |
| PostgreSQL | Local contract test run (contract tests read files, no DB needed) | N/A | N/A | Contract tests are file-parsing only; DB not needed for CI contract tests |

---

## Validation Architecture

> `workflow.nyquist_validation` key is absent from `.planning/config.json` — treated as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) |
| Config file | `test/test_helper.exs` |
| Quick run command | `MIX_ENV=test mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` |
| Full suite command | `mix test --warnings-as-errors` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PAR-01 | Parallel jobs each have `needs: build`, correct commands | contract | `mix test --no-start test/scoria/ci_policy_contract_test.exs` | ✅ (rewrite existing) |
| PAR-02 | `verify-summary` aggregates all parallel lanes; derived completeness | contract | `mix test --no-start test/scoria/ci_policy_contract_test.exs` | ✅ (new test in existing file) |
| PAR-03 | Lane order still pinned (intra-job step order preserved) | contract | `mix test --no-start test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` | ✅ (rewrite existing) |
| DX-02 | Docs name each parallel lane and `verify-summary` | contract | `mix test --no-start test/scoria/ci_policy_contract_test.exs` | ✅ (update existing docs-topology test) |

### Sampling Rate

- **Per task commit:** `MIX_ENV=test mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs`
- **Per wave merge:** `mix test --warnings-as-errors` (full suite)
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

None — existing test infrastructure covers all phase requirements. The contract test files exist and the test_helper.exs `SCORIA_LANE_CONTRACT_ONLY` path already handles the no-DB constraint for the policy job's lane-contract step.

---

## Security Domain

> This phase modifies only CI topology YAML, ExUnit contract tests, and documentation. No authentication, session, input validation, or cryptography surfaces are touched. ASVS categories V2/V3/V4/V5/V6 are not applicable.

---

## Sources

### Primary (HIGH confidence)

All findings are derived from direct file reads of authoritative sources in this repository. No external docs or web searches were required for this CI/devops phase — the CONTEXT.md encodes all architectural decisions from prior research rounds, and the code files are the canonical reference.

- `.github/workflows/ci-verify.yml` — complete file read; all job names, step commands, services config, artifact names, cache keys confirmed
- `.github/workflows/ci.yml` — complete file read; `ci-gate` bash idiom, `needs: [verify, e2e]` structure confirmed
- `test/scoria/ci_policy_contract_test.exs` — complete file read; all 30+ tests catalogued; 4 breaking assertions identified
- `test/scoria/verification_lanes_test.exs` — complete file read; 6 tests catalogued; 1 breaking assertion identified
- `lib/scoria/verification_lanes.ex` — complete file read; all 7 lane records with ci_command values confirmed
- `test/scoria/warning_inventory/tmp_preflight_test.exs` — complete file read; confirmed `use ExUnit.Case, async: false` (no DB)
- `lib/mix/tasks/scoria.warning_ratchet.test.ex` — complete file read; confirmed no Ecto/DB references
- `lib/mix/tasks/scoria.warning_ratchet.check.ex` — complete file read; confirmed no Ecto/DB references
- `docs/MAINTAINERS.md` — complete file read; current `## CI gate map` content catalogued
- `docs/operator_verification.md` — first 120 lines read; zero CI topology mentions confirmed
- `README.md` — relevant lines read; current "For maintainers" / CI topology line confirmed
- `.planning/todos/pending/ci-policy-job-cache-key-mislabel.md` — complete file read; WR-01 facts confirmed
- `test/test_helper.exs` — key lines read; `SCORIA_LANE_CONTRACT_ONLY` handling confirmed
- `.tool-versions` — Erlang 27.3.2, Elixir 1.19.5-otp-27

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all tooling confirmed present
- Architecture: HIGH — derived directly from source files, no inference required
- Contract test analysis: HIGH — all assertions read from actual source; breaking vs. safe categorized precisely
- Ratchet DB dependency: HIGH — confirmed absent from both task source and test source
- Pitfalls: HIGH — derived from the contract test invariants and GitHub Actions semantics already encoded in CONTEXT.md

**Research date:** 2026-06-15
**Valid until:** This phase is a one-time structural change; research is valid until execution.
