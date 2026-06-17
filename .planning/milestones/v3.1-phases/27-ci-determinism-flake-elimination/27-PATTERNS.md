# Phase 27: CI Determinism & Flake Elimination — Pattern Map

**Mapped:** 2026-06-16
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.github/workflows/ci.yml` | config | request-response | `.github/workflows/ci-verify.yml` | exact |
| `.github/workflows/ci-verify.yml` | config | request-response | `.github/workflows/ci.yml` | exact |
| `test/scoria/ci_policy_contract_test.exs` | test | transform | `test/scoria/ci_policy_contract_test.exs` (existing tests in same file) | exact — extend in place |
| `docs/MAINTAINERS.md` | config | N/A | `docs/MAINTAINERS.md` (existing `## CI gate map` section) | exact — extend in place |

---

## Pattern Assignments

### `.github/workflows/ci.yml` (config — YAML surgery × 2)

**Changes:** (1) line 42: `- 55432:5432` → `- 5432:5432`; (2) line 52: `SCORIA_DB_PORT: 55432` → `SCORIA_DB_PORT: 5432`; (3) delete lines 115–126 (TEMP step).

**Current Postgres block shape** (ci.yml lines 34–56 — the before state):
```yaml
services:
  postgres:
    image: pgvector/pgvector:pg16
    env:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: scoria_dev
    ports:
      - 55432:5432          # line 42 — CHANGE TO: - 5432:5432
    options: >-
      --health-cmd "pg_isready -U postgres -d scoria_dev"
      --health-interval 10s
      --health-timeout 5s
      --health-retries 10

env:
  MIX_ENV: dev
  SCORIA_DB_HOST: localhost
  SCORIA_DB_PORT: 55432     # line 52 — CHANGE TO: SCORIA_DB_PORT: 5432
  SCORIA_DB_USERNAME: postgres
  SCORIA_DB_PASSWORD: postgres
  SCORIA_DB_NAME: scoria_dev
  PORT: 4000
```

**TEMP step to delete** (ci.yml lines 115–126 inclusive — comment block + step):
```yaml
      # TEMP DIAGNOSTIC (remove after skeleton e2e root-caused): separates
      # "DB has no runs" from "server can't see the seeded runs". Prints the
      # row count via a fresh mix process and what the running server renders.
      - name: TEMP diagnose runs visibility
        run: |
          echo "== DB run count (fresh mix process) =="
          mix run -e 'IO.puts("DBRUNS=" <> Integer.to_string(Scoria.Repo.aggregate(Scoria.Workflows.Run, :count, :id)))' 2>/dev/null | grep DBRUNS || echo "DBRUNS=ERR"
          echo "== server render of /workflows =="
          curl -s http://localhost:4000/scoria/workflows | grep -oE 'No runs yet|/workflows/[a-f0-9-]+' | sort | uniq -c | head
          echo "== env the server points at =="
          echo "SCORIA_DB_NAME=$SCORIA_DB_NAME SCORIA_DB_PORT=$SCORIA_DB_PORT"
```
The step at line 127 (`- name: Run dashboard e2e lane`) immediately follows and must remain.

**Header comment retarget (D-11, optional)** (ci.yml line 18):
```yaml
# Maintainer narrative: docs/operator_verification.md — CI gate map (maintainers).
```
Optionally change to: `# Maintainer narrative: docs/MAINTAINERS.md — CI gate map + flake policy.`

---

### `.github/workflows/ci-verify.yml` (config — YAML surgery × 4)

**Changes:** In each of 4 job blocks, change `ports: - 55432:5432` → `- 5432:5432` and `SCORIA_DB_PORT: 55432` → `SCORIA_DB_PORT: 5432`. Exact line pairs:

| Job | `ports:` line | `SCORIA_DB_PORT:` line |
|-----|--------------|----------------------|
| `test` | 115 | 125 |
| `knowledge` | 226 | 236 |
| `connector` | 286 | 296 |
| `full-suite` | 355 | 365 |

**Representative block shape** (ci-verify.yml lines 107–128, `test` job — identical structure for all 4):
```yaml
    services:
      postgres:
        image: pgvector/pgvector:pg16
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: scoria_test
        ports:
          - 55432:5432          # CHANGE TO: - 5432:5432
        options: >-
          --health-cmd "pg_isready -U postgres -d scoria_test"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 10

    env:
      MIX_ENV: test
      SCORIA_DB_HOST: localhost
      SCORIA_DB_PORT: 55432     # CHANGE TO: SCORIA_DB_PORT: 5432
      SCORIA_DB_USERNAME: postgres
      SCORIA_DB_PASSWORD: postgres
      SCORIA_DB_NAME: scoria_test
```

**CRITICAL — `full-suite` job exception:** The `full-suite` env block (lines 362–368) does NOT contain `SCORIA_DB_NAME`. Do not copy `SCORIA_DB_NAME` from another job when editing it. Change only the two port values; preserve the existing shape exactly.

---

### `test/scoria/ci_policy_contract_test.exs` (test — EXTEND with new assertions)

This is the highest pattern-risk file. All new `test` blocks must match the file's existing conventions exactly. Patterns extracted below.

**Module-level attributes** (lines 6–16 — no new attributes needed for file paths):
```elixir
@ci_verify ".github/workflows/ci-verify.yml"
@ci_entry ".github/workflows/ci.yml"
@maintainer_docs "docs/MAINTAINERS.md"
@operator_docs "docs/operator_verification.md"
```
May add `@ephemeral_range_min 32_768` as a named constant for the port threshold (readability; Claude's Discretion).

**`job_blocks/1` helper** (lines 586–616 — file-agnostic, takes content string):
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
        :nomatch -> ""
      end

    Map.put(acc, job, body)
  end)
end
```
**Usage pattern for D-12:** Call `job_blocks(ci_verify)` and `job_blocks(ci_entry)` separately, then filter each by `body =~ "postgres:"` to derive the Postgres-job set. `job_blocks(ci_entry)` returns a map with keys `verify`, `e2e`, `ci-gate` — only `e2e` will match `body =~ "postgres:"`.

**Non-empty guard idiom — Form 1: `map_size` (line 250):**
```elixir
assert map_size(blocks) > 0, "job_blocks/1 returned empty — regex may be broken"
```

**Non-empty guard idiom — Form 2: `MapSet.size` (line 327):**
```elixir
assert MapSet.size(parallel_lanes) > 0,
       "expected at least one parallel verify lane with needs: build; regex may be broken"
```
D-12 requires `>= 5` for the new assertion (not just `> 0`). Use `map_size` form with `>= 5`:
```elixir
assert map_size(postgres_blocks) >= 5,
       "expected >= 5 postgres jobs across ci.yml + ci-verify.yml; regex may be broken"
```

**Existing per-job `services:` assertion as template** (lines 179–193 — the closest analog for the new ephemeral-port-ban assertion):
```elixir
test "postgres service is configured only for test, knowledge, and connector jobs" do
  ci_verify = File.read!(@ci_verify)
  blocks = job_blocks(ci_verify)

  # Jobs that must have Postgres services
  assert Map.fetch!(blocks, "test") =~ "services:"
  assert Map.fetch!(blocks, "knowledge") =~ "services:"
  assert Map.fetch!(blocks, "connector") =~ "services:"
  assert Map.fetch!(blocks, "full-suite") =~ "services:"

  # Jobs that must NOT have Postgres services
  refute Map.fetch!(blocks, "policy") =~ "services:"
  refute Map.fetch!(blocks, "build") =~ "services:"
  refute Map.fetch!(blocks, "ratchet") =~ "services:"
  refute Map.fetch!(blocks, "verify-summary") =~ "services:"
end
```
The D-12 test is distinct — it asserts the **host port value** inside the blocks, not just their presence. Mirror the structure: `File.read!(@ci_verify)` → `job_blocks(...)` → filter → guard → per-job assertion.

**Canonical `File.read!` + `=~` / `Regex` assertion pattern** (lines 18–27, simplest form):
```elixir
test "ci-verify.yml is reusable workflow_call SSOT" do
  ci_verify = File.read!(@ci_verify)

  assert ci_verify =~ "workflow_call"
  assert ci_verify =~ @baseline_check
  ...
end
```

**`Regex.scan` + per-match iteration pattern** (lines 332–345 — closest analog for extracting and iterating port values):
```elixir
needs_match = Regex.run(~r/needs:\s*\[([^\]]+)\]/, verify_summary_body)

verify_summary_needs =
  case needs_match do
    [_, needs_str] ->
      needs_str |> String.split(",") |> Enum.map(&String.trim/1) |> MapSet.new()

    nil ->
      flunk("verify-summary job has no needs: [...] block")
  end
```

**New tests to add (D-12, FLAKE-01, FLAKE-02):**

1. **D-12 — ephemeral port ban** (primary, longest):
```elixir
test "no CI Postgres job binds a host port in the ephemeral range (>= 32768)" do
  ci_verify = File.read!(@ci_verify)
  ci_entry = File.read!(@ci_entry)

  # Derive all job blocks that reference postgres: across both workflow files.
  # job_blocks/1 is file-agnostic — call once per file, filter by body content.
  verify_postgres =
    job_blocks(ci_verify) |> Enum.filter(fn {_name, body} -> body =~ "postgres:" end)

  entry_postgres =
    job_blocks(ci_entry) |> Enum.filter(fn {_name, body} -> body =~ "postgres:" end)

  postgres_blocks = Map.new(verify_postgres ++ entry_postgres)

  # Non-empty guard: broken regex cannot vacuously pass.
  # Current count: e2e (ci.yml) + test, knowledge, connector, full-suite (ci-verify.yml) = 5.
  assert map_size(postgres_blocks) >= 5,
         "expected >= 5 postgres jobs across ci.yml + ci-verify.yml; regex may be broken"

  # Assert no ports: binding uses a host port in the ephemeral range (>= 32768).
  # GitHub runner ephemeral port range: 32768–60999 (Linux kernel default).
  # Port 55432 is in this range — the root cause of FLAKE-01 (run 27508317719).
  for {job, body} <- postgres_blocks do
    port_bindings = Regex.scan(~r/- (\d+)(?::\d+|\/tcp)/, body)

    for [_full, host_port_str] <- port_bindings do
      host_port = String.to_integer(host_port_str)

      assert host_port < 32_768,
             "Job #{job}: host port #{host_port} is in the ephemeral range (>= 32768) — " <>
               "use a port below 32768 to prevent kernel bind conflicts on GitHub runners"
    end
  end
end
```

2. **FLAKE-02 durable guard** (one-liner, recommended):
```elixir
test "e2e job in ci.yml has no TEMP diagnostic step" do
  ci_entry = File.read!(@ci_entry)
  refute ci_entry =~ "TEMP diagnose", "TEMP diagnostic step must be removed from ci.yml e2e job"
end
```

3. **D-07 enforcement** (Claude's Discretion — recommended, scope ci.yml + ci-verify.yml only):
```elixir
test "no test workflow step uses continue-on-error or a retry-action" do
  ci_verify = File.read!(@ci_verify)
  ci_entry = File.read!(@ci_entry)

  refute ci_verify =~ "continue-on-error",
         "ci-verify.yml must not use continue-on-error on any step (D-07 zero-retry policy)"

  refute ci_entry =~ "continue-on-error",
         "ci.yml must not use continue-on-error on any step (D-07 zero-retry policy)"

  # Retry-action wrappers banned on test workflows (not carve-out release/automerge workflows)
  refute ci_verify =~ "nick-fields/retry"
  refute ci_verify =~ "Wandalen/wretry"
  refute ci_entry =~ "nick-fields/retry"
  refute ci_entry =~ "Wandalen/wretry"
end
```
Note: `release-please.yml`, `hex-publish.yml`, `release-pr-automerge.yml` are explicitly out of scope for this assertion (D-08 carve-out). Do not assert on them.

**Insertion point:** New tests should be inserted after the existing `"postgres service is configured only for test, knowledge, and connector jobs"` test (line 179) — thematically adjacent to the Postgres service assertions.

---

### `docs/MAINTAINERS.md` (config — ADD flake-policy subsection)

**Insertion location:** After line 88 (`Full-suite (k/4): WAE failed → ...`) and before line 90 (`## Hex release & recovery {#hex-release--recovery-maintainers}`). The new subsection lives inside `## CI gate map` as a `### Flake policy: retry vs fix` heading.

**Existing `## CI gate map` section structure** (lines 5–88 — anchor is at line 5):
```markdown
## CI gate map {#ci-gate-map-maintainers}

[... gate map content ...]

**When CI fails, run the matching maintainer command next:**

- Policy: `warning_baseline.check` failed → ...
- Full-suite (k/4): WAE failed → `SCORIA_DB_PORT=55432 MIX_TEST_PARTITION=k mix test ...`
```

**Do NOT touch any of the 12 `55432` references** (lines 24, 26, 27, 28, 30, 41, 45, 50, 54, 77, 87, 88). They are intentional local-parity instructions per D-05.

**New subsection content to insert** (after line 88, before line 90):
```markdown

### Flake policy: retry vs fix {#flake-policy}

**Zero-retry default.** Gating test lanes MUST NOT use `continue-on-error: true`, job-level
`retry:`, or any retry-action wrapper (`nick-fields/retry`, `Wandalen/wretry.action`, etc.)
on steps running `mix test`, the e2e lane, or any verify job.

**Banned patterns on `ci.yml` and `ci-verify.yml` test steps:**
- `continue-on-error: true`
- Job-level `retry:` on test jobs
- `uses: nick-fields/retry@*` or `uses: Wandalen/wretry.action@*` wrapping assertion steps

**Carve-out (not test retries):** The existing `attempt` polling loops in
`release-please.yml`, `hex-publish.yml`, and `release-pr-automerge.yml` poll for CI
completion / Hex index availability / branch-protection status. These are control-flow
waits, not test retries, and are out of scope.

**One allowed exception class:** A retry is permitted only on a step doing a known
infra-transient operation (network/package install, browser/toolchain download). Such a
step must:
1. Have a distinct step name identifying it as a retry (e.g., `Install Playwright (retry: network-transient)`)
2. Include an inline comment justifying the retry
3. Log `RETRY <step> attempt N/M: <reason>` at runtime
4. Cap at max 3 attempts
5. Be added under review

**Fix, don't retry.** A non-deterministic test must be root-caused-and-fixed or
quarantined (`@tag :flaky`, excluded from the gate) with a tracking issue — never made
to pass by re-running. (`mix test --repeat-until-failure` is for *reproducing* flakes, not
masking them.)

**Durable enforcement:** `test/scoria/ci_policy_contract_test.exs` asserts that no Postgres
job in `ci.yml` or `ci-verify.yml` binds a host port in the Linux ephemeral range (≥ 32768).
The root cause of FLAKE-01 (run 27508317719) was `55432` falling in that range; CI now uses
`5432` (below the range). Local dev/test retain `SCORIA_DB_PORT=55432` — see local parity
commands above.
```

---

## Shared Patterns

### `File.read!` + `=~` / `Regex` string assertion (no YAML parser)

**Source:** `test/scoria/ci_policy_contract_test.exs` — established throughout the file
**Apply to:** All new `test` blocks in `ci_policy_contract_test.exs`

The entire contract test file uses `File.read!` + string operators (`=~`, `refute ... =~`, `Regex.scan`, `:binary.match`). No YAML parser. This is load-bearing for D-12: adding a YAML parser dep would contradict the file's convention and introduce an unnecessary dependency.

### Non-empty guard before a `for` or assertion loop

**Source:** `test/scoria/ci_policy_contract_test.exs` lines 250 and 327
**Apply to:** D-12 `postgres_blocks` assertion before the `for` loop

Always assert `map_size(collection) > 0` (or `>= N` for a known minimum count) before iterating, so a broken slice regex fails loud rather than vacuously passing an empty loop.

### `job_blocks/1` call pattern

**Source:** `test/scoria/ci_policy_contract_test.exs` lines 163–164
**Apply to:** D-12 test

Standard call idiom:
```elixir
blocks = job_blocks(ci_verify)
test_body = Map.fetch!(blocks, "test")
```
For D-12, call it twice (once per file) and filter both results by `body =~ "postgres:"` before merging.

---

## No Analog Found

None. All 4 target files have exact analogs in the codebase.

---

## Metadata

**Analog search scope:** `test/scoria/`, `.github/workflows/`, `docs/`
**Files scanned:** 4 source files read directly (ci_policy_contract_test.exs, ci.yml, ci-verify.yml, MAINTAINERS.md)
**Pattern extraction date:** 2026-06-16
