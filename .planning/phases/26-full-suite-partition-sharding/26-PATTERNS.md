# Phase 26: Full-suite partition sharding — Pattern Map

**Mapped:** 2026-06-16
**Files analyzed:** 4 (2 modified, 2 modified-in-place)
**Analogs found:** 4 / 4

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.github/workflows/ci-verify.yml` | CI workflow (Postgres job) | request-response (GHA job) | sibling `knowledge:` / `connector:` jobs in the same file (lines 217–274, 277–337) | exact |
| `test/scoria/ci_policy_contract_test.exs` | contract test | batch (YAML structural assertion) | existing `job_blocks/1` + `verify-summary fan-in` test in the same file (lines 266–299, 537–567) | exact |
| `test/scoria/verification_lanes_test.exs` | contract test | batch (YAML order assertion) | existing `ci lane ordering` test in the same file (lines 67–143) | exact |
| `test/test_helper.exs` | test bootstrap / guard | event-driven (ExUnit after_suite) | existing Layer 2 knowledge guard in the same file (lines 27–34) | exact |

---

## Pattern Assignments

---

### `.github/workflows/ci-verify.yml` — new `full-suite:` matrix job (D-01, D-02, D-04)

**Analog:** `knowledge:` job (lines 217–274) and `connector:` job (lines 277–337) in `.github/workflows/ci-verify.yml`

**Services + env preamble pattern** (analog: `knowledge:` lines 217–243):

```yaml
# knowledge: job — analog for full-suite: services + env block
knowledge:
  runs-on: ubuntu-latest
  needs: build

  services:
    postgres:
      image: pgvector/pgvector:pg16
      env:
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: postgres
        POSTGRES_DB: scoria_test
      ports:
        - 55432:5432
      options: >-
        --health-cmd "pg_isready -U postgres -d scoria_test"
        --health-interval 10s
        --health-timeout 5s
        --health-retries 10

  env:
    MIX_ENV: test
    SCORIA_DB_HOST: localhost
    SCORIA_DB_PORT: 55432
    SCORIA_DB_USERNAME: postgres
    SCORIA_DB_PASSWORD: postgres
    SCORIA_DB_NAME: scoria_test
```

**Differences for `full-suite:`:**
- Add `strategy: { fail-fast: false, matrix: { partition: [1, 2, 3, 4] } }` above `services:`
- Add `name: "full-suite (${{ matrix.partition }}/${{ strategy.job-total }})"` above `runs-on:`
- Change `--health-cmd` to `"pg_isready -U postgres"` (drop `-d scoria_test` — DB does not exist until `ecto.create` runs)
- Set `MIX_TEST_PARTITION: ${{ matrix.partition }}` at job-level `env:` (propagates to all steps including `ecto.create`)
- **Omit `SCORIA_DB_NAME` entirely** — its absence is load-bearing; the `||` in `config/test.exs` falls through to `scoria_test#{MIX_TEST_PARTITION}` only when `SCORIA_DB_NAME` is `nil`
- Omit `SCORIA_HEX_UNPACK_ROOT` (that is `test:` job specific)

**Setup-beam + artifact-download pattern** (analog: `knowledge:` steps, lines 244–263):

```yaml
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
```

**DB-prep block pattern** (analog: `knowledge:` lines 265–271; `connector:` lines 325–331; `test:` lines 158–164 — ALL three are byte-identical):

```yaml
      # DB-prep: keep in sync with sibling parallel jobs
      - name: Prepare database
        run: |
          mix ecto.create
          mix ecto.migrate --to 20260511000300
          mix eval 'Scoria.TestSupport.Migrations.migrate_knowledge!()'
          mix ecto.migrate
```

Copy this block verbatim (same marker comment, same literal strings). The contract tests grep for
`"mix ecto.migrate --to 20260511000300"` and `"Scoria.TestSupport.Migrations.migrate_knowledge!()"` in `ci_verify`; byte-identical keeps them green.

**Final step (new — differs from all siblings):**

```yaml
      - name: Run full suite (shard ${{ matrix.partition }}/4)
        run: mix test --warnings-as-errors --partitions 4
```

Note: NO `--partition N` flag exists. `MIX_TEST_PARTITION` env (set at job level) selects the leg.

**`verify-summary.needs` update** (analog: line 342 in `ci-verify.yml`):

Current (line 342):
```yaml
    needs: [policy, build, test, ratchet, knowledge, connector]
```

After Phase 26:
```yaml
    needs: [policy, build, test, ratchet, knowledge, connector, full-suite]
```

Keep as inline `[...]` syntax — the contract test regex `~r/needs:\s*\[([^\]]+)\]/` (line 285 of `ci_policy_contract_test.exs`) only matches this form. Do not convert to multi-line list.

**Step to REMOVE from `test:` job** (current line 184–185):

```yaml
      - name: Run tests
        run: mix test --warnings-as-errors
```

Remove this step. The `test:` job ends at the semantic lane step (line 182–183):
```yaml
      - name: Run semantic fast-path lane
        run: mix test.semantic_fast_path --warnings-as-errors
```

**Intent comment to add** (follow pattern at lines 102, 187, 216, 276, 339):

```yaml
  # full-suite: sharded full ExUnit suite (WAE) — 4-way matrix on shared build artifact
  full-suite:
```

**YAML position:** Place `full-suite:` after `connector:` (line 276) and before `verify-summary:` (line 339). The `connector_body` extraction in `verification_lanes_test.exs` line 127 bounds by `"\n  verify-summary:"`, so inserting between `connector:` and `verify-summary:` keeps it correct. Do NOT insert between `test:` and `ratchet:`.

---

### `test/scoria/ci_policy_contract_test.exs` — new structural coverage-proof asserts (D-03) and targeted fan-in assert (D-04)

**Analog:** `job_blocks/1` parser (lines 537–567), `verify-summary fan-in` test (lines 266–299), and `test job runs semantic lane after runtime_to_handoff` test (lines 203–221) in the same file.

**`job_blocks/1` parser** (lines 537–567 — reused as-is, no changes needed):

```elixir
  defp job_blocks(content) do
    # Match all top-level job names (2-space indent, word chars + hyphens, followed by colon)
    job_names =
      Regex.scan(~r/^  ([\w-]+):/m, content)
      |> Enum.map(&Enum.at(&1, 1))

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

          :nomatch ->
            ""
        end

      Map.put(acc, job, body)
    end)
  end
```

`Map.fetch!(blocks, "full-suite")` raises (not silent empty string) if `"full-suite"` key is absent — this is the anti-vacuous-pass mechanism.

**Non-empty guard pattern** (analog: lines 279–281 in the fan-in test):

```elixir
    assert MapSet.size(parallel_lanes) > 0,
           "expected at least one parallel verify lane with needs: build; regex may be broken"
```

Apply the same non-empty guard on `job_blocks/1` results when writing new D-03 asserts.

**Fan-in derived subset test** (lines 266–299 — the existing test; auto-catches `full-suite` once it has `needs: build`):

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
        [_, needs_str] ->
          needs_str |> String.split(",") |> Enum.map(&String.trim/1) |> MapSet.new()

        nil ->
          flunk("verify-summary job has no needs: [...] block")
      end

    # Subset assertion: every parallel lane is wired into verify-summary
    assert MapSet.subset?(parallel_lanes, verify_summary_needs),
           "unwired lanes: #{inspect(MapSet.difference(parallel_lanes, verify_summary_needs))}"
  end
```

No changes needed to this test — once `full-suite:` has `needs: build`, it is auto-derived into `parallel_lanes` and auto-checked against `verify_summary_needs`.

**Breaking test B-1** — "test job runs semantic lane after runtime_to_handoff" (lines 203–221):

Lines 212–214 will go RED after Phase 26 because `"run: mix test --warnings-as-errors"` is absent from `test_body`:

```elixir
    # Semantic precedes full-suite WAE inside test: job  ← REMOVE this comment + assertion
    assert index_of(test_body, @semantic_lane) <
             index_of(test_body, "run: mix test --warnings-as-errors")
```

Replace with a cross-job assertion targeting the `full-suite:` block:

```elixir
    # full-suite: matrix job carries WAE (moved out of test: job)
    full_suite_body = Map.fetch!(job_blocks(ci_verify), "full-suite")
    assert full_suite_body =~ "mix test --warnings-as-errors"
    assert full_suite_body =~ "--partitions 4"
```

**Breaking test B-2** — "test job runs full suite WAE after closeout lanes; knowledge is a parallel job" (lines 223–240):

Lines 229 and 231–232 will go RED:

```elixir
    assert test_body =~ "run: mix test --warnings-as-errors"           # BREAKS — remove
    assert index_of(test_body, runtime_to_handoff) <
             index_of(test_body, "run: mix test --warnings-as-errors") # BREAKS — remove
```

Rename test to `"test job ends with semantic lane; full-suite is a parallel matrix job"`. Replace broken assertions with:

```elixir
    refute test_body =~ "run: mix test --warnings-as-errors"   # full-suite step moved out
    full_suite_body = Map.fetch!(blocks, "full-suite")
    assert full_suite_body =~ "mix test --warnings-as-errors"
    assert full_suite_body =~ "--partitions 4"
    assert full_suite_body =~ "needs: build"
```

The `refute` line gives the assertion teeth in the opposite direction (fails if the WAE step is accidentally left in `test:`).

**New D-03 structural coverage-proof asserts** (new test, add after line 240):

```elixir
  test "full-suite job is a 4-way matrix with correct partition wiring and no DB name collision" do
    ci_verify = File.read!(@ci_verify)
    blocks = job_blocks(ci_verify)

    # Non-empty guard: broken job_blocks/1 regex can't vacuously pass
    assert map_size(blocks) > 0, "job_blocks/1 returned empty — regex may be broken"

    full_suite_body = Map.fetch!(blocks, "full-suite")

    # SC#1 — sharded invocation
    assert full_suite_body =~ "needs: build"
    assert full_suite_body =~ "mix test --warnings-as-errors"
    assert full_suite_body =~ "--partitions 4"
    assert full_suite_body =~ "MIX_TEST_PARTITION"
    assert full_suite_body =~ "${{ matrix.partition }}"
    assert full_suite_body =~ "partition: [1, 2, 3, 4]"
    assert full_suite_body =~ "fail-fast: false"
    refute full_suite_body =~ "continue-on-error"

    # SC#2 — DB isolation: absence of SCORIA_DB_NAME is load-bearing
    # config/test.exs: database: System.get_env("SCORIA_DB_NAME") || "scoria_test#{MIX_TEST_PARTITION}"
    # When SCORIA_DB_NAME is nil, the || resolves scoria_test1..4 per shard.
    refute full_suite_body =~ "SCORIA_DB_NAME"
    assert full_suite_body =~ "MIX_TEST_PARTITION: ${{ matrix.partition }}"
    assert full_suite_body =~ "services:"

    # SC#3 — Rem-completeness proof (filter_by_partition/3, Elixir 1.19.5):
    #   sorted_files |> Enum.with_index() |> Enum.filter(fn {_, i} -> rem(i, total) == partition - 1 end)
    #   For total=4, partitions {1,2,3,4} cover rem values {0,1,2,3} — a complete residue system.
    #   Union of 4 shards = full suite BY CONSTRUCTION. These two assertions keep --partitions N
    #   and matrix.partition list in sync; a mismatch (e.g., --partitions 3 + [1,2,3,4]) is caught.
    assert full_suite_body =~ "--partitions 4"
    assert full_suite_body =~ "partition: [1, 2, 3, 4]"
  end
```

**New D-04 targeted `full-suite in verify-summary.needs` assert** (add to or alongside the existing fan-in test at line 266, or as a standalone test):

```elixir
  test "full-suite is explicitly wired into verify-summary fan-in (D-04 targeted pin)" do
    ci_verify = File.read!(@ci_verify)
    blocks = job_blocks(ci_verify)

    verify_summary_body = Map.fetch!(blocks, "verify-summary")
    assert verify_summary_body =~ "full-suite",
           "full-suite must be in verify-summary.needs — wiring it prevents a false-green fan-in"
  end
```

**Non-breaking update U-1** — "postgres service is configured only for test, knowledge, and connector jobs" (line 179). Add after the three positive asserts:

```elixir
    assert Map.fetch!(blocks, "full-suite") =~ "services:"
```

**Non-breaking update U-2** — "ci-verify.yml documents per-job intent comments" (line 410). Add to existing test:

```elixir
    assert ci_verify =~ "# full-suite:"
```

**Non-breaking update U-3** — "maintainer CI gate map documents topology, parity, ratchet, and failure diagnosis" (line 440). Add inside existing test:

```elixir
    assert gate_map =~ "full-suite"
```

---

### `test/scoria/verification_lanes_test.exs` — fix breaking assertion B-3

**Analog:** Existing `"ci lane ordering follows the canonical closeout chain"` test (lines 67–143), specifically line 100.

**Breaking assertion B-3** (line 100):

```elixir
    assert index_of(test_body, semantic) < index_of(test_body, "run: mix test --warnings-as-errors")
```

After Phase 26, `"run: mix test --warnings-as-errors"` is absent from `test_body` (bounded by `"\n  test:"` → `"\n  ratchet:"`). `index_of/2` calls `flunk/1` when needle is not found. Result: RED.

**Fix:** Remove line 100. The last legitimate intra-`test:` order assertion becomes the one at line 99:

```elixir
    assert index_of(test_body, runtime_to_handoff) < index_of(test_body, semantic)
```

Optionally add a cross-job assertion at the bottom of the test (after the connector block, line 143):

```elixir
    # full-suite: matrix job carries the WAE step (moved out of test: job)
    assert ci_workflow =~ "mix test --warnings-as-errors --partitions 4"
```

The `test_body` extraction (lines 75–87) stays unchanged — it correctly bounds by `"\n  ratchet:"`, which is unaffected by adding `full-suite:` after `connector:`.

The `connector_body` extraction (lines 127–138) correctly bounds by `"\n  verify-summary:"`. Placing `full-suite:` between `connector:` and `verify-summary:` does NOT affect this boundary — the slice ends at `"\n  verify-summary:"` regardless.

---

### `test/test_helper.exs` — new `after_suite` zero-test partition guard (D-03 Layer 3)

**Analog:** Existing Layer 2 knowledge guard (lines 27–34):

```elixir
# Layer 2 zero-test guard: fires only when SCORIA_TEST_INCLUDE_KNOWLEDGE=true
# (i.e., only during mix test.knowledge runs). Default mix test never trips this.
# Must be placed AFTER ExUnit.start/1 — after_suite reads from app env initialized by start.
if System.get_env("SCORIA_TEST_INCLUDE_KNOWLEDGE") == "true" do
  ExUnit.after_suite(fn %{total: total} ->
    if total == 0 do
      IO.puts(:stderr, "[knowledge lane] after_suite: 0 tests executed — possible tag loss")
      exit({:shutdown, 1})
    end
  end)
end
```

**New guard to add** (place immediately after line 34, still after `ExUnit.start/1`):

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

Key pattern differences from the knowledge analog:
- Gate condition: `System.get_env("MIX_TEST_PARTITION")` (truthy when set, `nil` locally — so `if nil` is falsy, guard is skipped)
- Knowledge guard uses `== "true"` string comparison; partition guard uses bare truthy check (the value is a partition number string `"1"`.."4"`, not a boolean string)
- Diagnostic message includes `System.get_env("MIX_TEST_PARTITION")` for shard identification
- The `%{total: total}` map destructuring is identical to the analog — this is the correct ExUnit 1.19.5 `after_suite/1` callback signature

---

### `docs/MAINTAINERS.md` — CI gate map updates (D-01, D-02 docs row)

**Analog:** Existing topology line (line 18) and job→command table (lines 22–27):

Current topology line (line 18):
```
Topology: `policy → build → { test, ratchet, knowledge, connector } → verify-summary`
```

Update to:
```
Topology: `policy → build → { test, ratchet, knowledge, connector, full-suite[×4] } → verify-summary`
```

Current job→command table (lines 22–27):
```markdown
| Job | Local command |
|-----|---------------|
| `test` | `SCORIA_DB_PORT=55432 mix test --warnings-as-errors` |
| `ratchet` | `MIX_ENV=test mix test --warnings-as-errors test/scoria/warning_inventory/tmp_preflight_test.exs` |
| `knowledge` | `SCORIA_DB_PORT=55432 mix test.knowledge --warnings-as-errors` |
| `connector` | `SCORIA_DB_PORT=55432 mix test.connector --warnings-as-errors` |
```

Add row (the `SCORIA_DB_PORT=55432` is present; `SCORIA_DB_NAME` is **absent** — that is load-bearing):
```markdown
| `full-suite (k/4)` | `SCORIA_DB_PORT=55432 MIX_TEST_PARTITION=k mix test --warnings-as-errors --partitions 4` |
```

Add `full-suite` narrative section (analog: existing `knowledge` / `connector` job sections lines 41–48):

```markdown
**`full-suite` job (4-way matrix, Postgres on 55432):**

- `mix test --warnings-as-errors --partitions 4` — sharded full suite WAE
- Set `MIX_TEST_PARTITION=k` (no `SCORIA_DB_NAME`) — activates `scoria_testk` DB isolation
- Failed shard `full-suite (2/4)` → `SCORIA_DB_PORT=55432 MIX_TEST_PARTITION=2 mix test --warnings-as-errors --partitions 4`
```

Update the `test:` job section (current lines 29–35) to reflect step 5 is now moved:

```markdown
**`test` job (Postgres on 55432):**

1. `MIX_ENV=dev mix scoria.release_preview` — release/docs lane (dev only)
2. `mix ecto.create` + `mix ecto.migrate`
3. `mix test.adoption` → `mix test.runtime_to_handoff` — behavioral closeout lanes
4. `mix test.semantic_fast_path --warnings-as-errors` — semantic lane WAE after closeout
```

(Remove step 5 `mix test --warnings-as-errors` — it has moved to `full-suite:`.)

Update the failure diagnosis section (current line 82):
```
- Test: full-suite WAE failed → `SCORIA_DB_PORT=55432 mix test --warnings-as-errors`
```
Becomes:
```
- Full-suite (k/4): WAE failed → `SCORIA_DB_PORT=55432 MIX_TEST_PARTITION=k mix test --warnings-as-errors --partitions 4`
```

---

## Shared Patterns

### Non-empty guard on `job_blocks/1`

**Source:** `test/scoria/ci_policy_contract_test.exs` line 279–281
**Apply to:** All new D-03 asserts that call `job_blocks/1`

```elixir
assert map_size(blocks) > 0, "job_blocks/1 returned empty — regex may be broken"
```

Or the existing form from the fan-in test:
```elixir
assert MapSet.size(parallel_lanes) > 0,
       "expected at least one parallel verify lane with needs: build; regex may be broken"
```

### `Map.fetch!/2` for anti-vacuous-pass

**Source:** `test/scoria/ci_policy_contract_test.exs` line 284, 303, etc.
**Apply to:** All new assertions targeting the `"full-suite"` key

Use `Map.fetch!(blocks, "full-suite")` — raises `KeyError` if `"full-suite"` is absent from the parsed YAML, rather than silently returning an empty string.

### Inline `needs:` list syntax

**Source:** `.github/workflows/ci-verify.yml` line 342
**Apply to:** The `verify-summary.needs` update

```yaml
needs: [policy, build, test, ratchet, knowledge, connector, full-suite]
```

Contract test regex `~r/needs:\s*\[([^\]]+)\]/` (line 285) requires this inline form. Multi-line YAML list syntax is not matched.

### `# DB-prep: keep in sync with sibling parallel jobs` marker

**Source:** `.github/workflows/ci-verify.yml` lines 158, 265, 325
**Apply to:** The DB-prep block in the new `full-suite:` job

Copy verbatim — the comment is a cross-job synchronization signal and the literal strings are what existing contract tests grep for.

### `ExUnit.after_suite/1` callback signature

**Source:** `test/test_helper.exs` line 28
**Apply to:** New partition zero-test guard in `test/test_helper.exs`

```elixir
ExUnit.after_suite(fn %{total: total} ->
```

This is the correct Elixir 1.19.5 pattern. Placement must be AFTER `ExUnit.start/1` (line 22).

---

## No Analog Found

None. All four artifacts have direct, exact analogs in the existing codebase.

---

## Breaking Assertion Summary (planner must include as explicit tasks)

| ID | File | Lines | Needle that disappears | Fix |
|----|------|--------|------------------------|-----|
| B-1 | `ci_policy_contract_test.exs` | 212–214 | `"run: mix test --warnings-as-errors"` in `test_body` | Remove 2 lines; add cross-job assertion on `full-suite` block |
| B-2 | `ci_policy_contract_test.exs` | 229, 231–232 | `"run: mix test --warnings-as-errors"` in `test_body` | Rename test; replace 2 assertions with `refute` + `full-suite` cross-job asserts |
| B-3 | `verification_lanes_test.exs` | 100 | `"run: mix test --warnings-as-errors"` in `test_body` | Remove line 100; optionally add cross-workflow assert |

All three use `index_of/2` (which calls `flunk/1` on `:nomatch`) or `=~` on `test_body`. After the WAE step is removed from `test:`, all three produce RED in the policy lane's WAE contract run.

**Local pre-commit command** (from RESEARCH.md — run before committing the YAML change):

```bash
SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors \
  test/scoria/ci_policy_contract_test.exs \
  test/scoria/verification_lanes_test.exs
```

---

## Metadata

**Analog search scope:** `.github/workflows/`, `test/scoria/`, `test/test_helper.exs`, `docs/`
**Files read:** `ci-verify.yml` (357 lines), `ci_policy_contract_test.exs` (588 lines), `verification_lanes_test.exs` (151 lines), `test_helper.exs` (34 lines), `docs/MAINTAINERS.md` (first 90 lines)
**Pattern extraction date:** 2026-06-16
