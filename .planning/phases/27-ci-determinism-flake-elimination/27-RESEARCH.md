# Phase 27: CI Determinism & Flake Elimination — Research

**Researched:** 2026-06-16
**Domain:** GitHub Actions CI — Postgres service-container port mechanics, YAML surgery, ExUnit contract-test extension
**Confidence:** HIGH — all findings verified directly against live codebase files

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**FLAKE-01 — Postgres connection strategy**
- D-01: Replace `ports: ['55432:5432']` with `ports: ['5432:5432']` and set `SCORIA_DB_PORT: 5432` in every CI Postgres job block. Apply to all 5 blocks: `e2e` (ci.yml) and `test`, `knowledge`, `connector`, `full-suite` matrix (ci-verify.yml).
- D-02 (root cause): `55432` falls inside the GitHub-runner ephemeral port range (32768–60999). `5432` is below it and immune.
- D-03 (rejected): Dynamic host port (`- 5432/tcp`) — `job.services.<id>.ports` is NOT available in job-level `env:`. Do not use.
- D-04 (rejected): Job-in-container + network alias. Too heavy. Do not use.
- D-05 (local unchanged): Local dev/test keep `SCORIA_DB_PORT=55432`. CI=5432 / local=55432 coexist. Config default fallback is already `"5432"`.

**FLAKE-02 — Remove TEMP diagnostic**
- D-06: Delete the `TEMP diagnose runs visibility` step from the `e2e` job in `ci.yml`. Clear-cut.

**FLAKE-03 — Retry-vs-fix policy**
- D-07 (stance): Zero-retry default. Gating test lanes MUST NOT use `continue-on-error: true`, job-level retry, or any retry-action wrapper on `mix test`, the e2e lane, or any verify job.
- D-08 (carve-out): The existing `attempt` polling loops in `release-please.yml`, `hex-publish.yml`, and `*-automerge.yml` poll for CI completion / Hex index — they are control-flow waits, NOT test retries — and are explicitly out of scope.
- D-09 (allowed exception): Retry permitted ONLY on infra-transient steps (network/package install, browser/toolchain download). Distinct step name, inline justification, log `RETRY <step> attempt N/M: <reason>`, max 3 attempts, added under review.
- D-10 (fix, don't retry): A non-deterministic test must be root-caused-and-fixed or quarantined with a tracking issue.

**Policy doc home**
- D-11: Add `### Flake policy: retry vs fix` subsection to `docs/MAINTAINERS.md`, adjacent to `## CI gate map {#ci-gate-map-maintainers}`. NOT `docs/operator_verification.md` (adopter-facing). Optionally retarget the `ci.yml` header comment (line ~16/18) from `operator_verification.md` to `MAINTAINERS.md`.

**Recurrence proof**
- D-12 (durable guard): Extend `test/scoria/ci_policy_contract_test.exs` with a permanent assertion that no Postgres `ports:` block binds a host port in the ephemeral range (≥ 32768). Derive Postgres-job set from `body =~ "postgres:"`. Keep `>= 5` non-empty guard. Reuse `job_blocks/1` for both `ci.yml` and `ci-verify.yml`. String/regex-based only — no YAML parser.
- D-13 (empirical sweep): One-time ~10× `workflow_dispatch` sweep; paste run URLs into VERIFICATION doc. Non-permanent.
- D-14 (honest framing): Non-recurrence is structural (host port below ephemeral range), contract test is durable guarantee, sweep is corroboration only.

### Claude's Discretion

- Exact regex/parse form of the ephemeral-range assertion and how the carve-out for the release/merge polling loops is encoded in the contract test.
- Whether to add a contract assertion banning `continue-on-error`/retry-action `uses:` slugs on test workflows to enforce D-07 (recommended; low false-positive risk).
- Whether to retarget the `ci.yml` header comment (D-11) now or note it for Phase 28.

### Deferred Ideas (OUT OF SCOPE)

- `mix ci` local alias + before/after velocity timing — Phase 28 (DX-01, VELO-01).
- Retargeting/cleanup of the `ci.yml` header comment to MAINTAINERS.md may be folded into Phase 28 if not done here.
- Optional broader contract assertion banning retry-action `uses:` slugs — implement with D-07 enforcement if cheap; otherwise a follow-up.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FLAKE-01 | Postgres service container no longer fails on host-port bind conflicts — fixed `-p 55432:5432` replaced with non-conflicting strategy | D-01/D-02 locked; 5 edit sites confirmed (exact lines below) |
| FLAKE-02 | Leftover TEMP diagnostic step (DB run-count + server-render dump) removed from `e2e` job in `ci.yml` | Confirmed at ci.yml lines 115–126; step name "TEMP diagnose runs visibility" |
| FLAKE-03 | Retry-vs-fix policy documented and applied — no blanket auto-retries; any retry scoped to infra-transient step only, visible in logs | D-07/D-08 locked; no existing retry patterns on test steps confirmed |
</phase_requirements>

---

## Summary

Phase 27 is a small, high-confidence surgical phase: three bounded edits (YAML × 5 blocks, one YAML step deletion, one doc section) plus an ExUnit contract-test extension. All decisions are locked in CONTEXT.md. This research confirms the exact current state of every edit site, verifies CONTEXT's claims against the live codebase, and surfaces one undocumented implication the planner must know.

**Primary recommendation:** The planner can write a single plan. All 5 Postgres blocks are live and identical in shape. The TEMP step is live. No retry patterns exist on test steps today. The contract test's `job_blocks/1` helper and non-empty guard idiom are ready to extend. One material implication not fully called out in CONTEXT: `docs/MAINTAINERS.md` references `SCORIA_DB_PORT=55432` in **12 places** as the local-parity instruction — those references are intentionally local-only (D-05) and must NOT be updated, but the flake-policy subsection needs to note that CI will use port 5432 while local stays on 55432.

**CONTEXT.md claims verified:** All verified — no drift found. Approximate line numbers in CONTEXT are close but not exact; exact current numbers documented below.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Postgres service port binding | GitHub Actions runner OS / Docker | GitHub Actions YAML | Host port collides with ephemeral range at the OS network layer; fix is in YAML |
| CI job configuration | GitHub Actions YAML | — | Port, env vars, step list |
| Flake policy enforcement (durable) | ExUnit contract test (`ci_policy_contract_test.exs`) | MAINTAINERS.md | Contract test catches future regressions; docs capture human-readable policy |
| Flake policy enforcement (human) | `docs/MAINTAINERS.md` | — | D-11: maintainer-only doc, never adopter-facing |
| Local DB port | `lib/scoria/verification_lanes.ex` + `docs/MAINTAINERS.md` | config/dev.exs, config/test.exs | Intentionally fixed at 55432 locally; unchanged by this phase |

---

## Standard Stack

No new packages. This phase is YAML surgery + ExUnit test extension + Markdown docs. Zero new dependencies.

**No Package Legitimacy Audit required** — no external packages installed.

---

## Edit-Site Inventory (VERIFIED against live files)

This is the core deliverable. Every edit site confirmed by direct file inspection.

### ci.yml — e2e job Postgres block

**Current state (confirmed):**

```yaml
# ci.yml lines 34–52: e2e job services block
services:
  postgres:
    image: pgvector/pgvector:pg16
    env:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: scoria_dev
    ports:
      - 55432:5432          # LINE 42 — CHANGE TO: - 5432:5432
    options: >-
      --health-cmd "pg_isready -U postgres -d scoria_dev"
      --health-interval 10s
      --health-timeout 5s
      --health-retries 10

# ci.yml lines 49–56: e2e job env block
env:
  MIX_ENV: dev
  SCORIA_DB_HOST: localhost
  SCORIA_DB_PORT: 55432     # LINE 52 — CHANGE TO: SCORIA_DB_PORT: 5432
  ...
```

**CONTEXT claim "lines ~34–52":** [VERIFIED: ci.yml] Accurate — ports block is line 41–42, env is lines 49–56.

### ci.yml — TEMP diagnostic step

**Current state (confirmed):**

```yaml
# ci.yml lines 115–126: TEMP diagnostic step
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

**Step name:** `TEMP diagnose runs visibility` (lines 118–126, including comment block lines 115–117)
**CONTEXT claim "lines ~115–125":** [VERIFIED: ci.yml] Accurate — step comment starts line 115, step content through line 126.
**Delete scope:** Remove lines 115–126 inclusive (comment block + step).

### ci.yml — header comment

**Current state (line 16–19, confirmed):**

```yaml
# PR and release-please branch CI entrypoint — executable jobs live in ci-verify.yml.
# Parallel topology: policy → build → { test, ratchet, knowledge, connector } → verify-summary.
# Maintainer narrative: docs/operator_verification.md — CI gate map (maintainers).   # LINE 18
# Release-please branches and workflow_dispatch reuse the same verify bar as main.
# Lane order SSOT: Scoria.VerificationLanes + test/scoria/ci_policy_contract_test.exs.
```

**Line 18** points to `docs/operator_verification.md`. D-11 says optionally retarget to `MAINTAINERS.md` — this is Claude's Discretion.

### ci-verify.yml — 4 Postgres blocks

**Current state (all confirmed):**

| Job | ports: line | SCORIA_DB_PORT: line | Current value |
|-----|------------|---------------------|---------------|
| `test` | 115 | 125 | `55432:5432` / `55432` |
| `knowledge` | 226 | 236 | `55432:5432` / `55432` |
| `connector` | 286 | 296 | `55432:5432` / `55432` |
| `full-suite` | 355 | 365 | `55432:5432` / `55432` |

**CONTEXT claim "test (~107), knowledge (~218), connector (~278), full-suite (~347)":** [VERIFIED: ci-verify.yml] CONTEXT line numbers are slightly off — actual ports: lines are 115, 226, 286, 355. CONTEXT approximations understated by ~8–17 lines (likely due to content added in Phase 25/26). All 4 blocks structurally identical in shape.

**Full-suite note:** The `full-suite` job does NOT have `SCORIA_DB_NAME` in its env (load-bearing for shard isolation). When replacing `55432` → `5432`, do NOT add `SCORIA_DB_NAME`. The existing shape must be preserved exactly except for the two port values.

### ci-verify.yml — `full-suite` job also lacks `SCORIA_DB_NAME` in env block

Confirmed from live file: `full-suite` env block (lines 362–368) contains `MIX_ENV`, `SCORIA_DB_HOST`, `SCORIA_DB_PORT`, `SCORIA_DB_USERNAME`, `SCORIA_DB_PASSWORD`, `MIX_TEST_PARTITION` — intentionally NO `SCORIA_DB_NAME`. The port-only change must preserve this.

---

## Contract Test Extension (D-12) — Current State

### `job_blocks/1` helper — exact current signature

[VERIFIED: ci_policy_contract_test.exs line 586]

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

**Key property:** `job_blocks/1` is file-agnostic — it takes a content string, not a filename. D-12 says to reuse it for both `ci.yml` (for the `e2e` job block) and `ci-verify.yml` (for the 4 test-lane job blocks). [VERIFIED: ci_policy_contract_test.exs]

### Non-empty guard idiom — two existing forms

[VERIFIED: ci_policy_contract_test.exs]

**Form 1 — `map_size` (line 250):**
```elixir
assert map_size(blocks) > 0, "job_blocks/1 returned empty — regex may be broken"
```

**Form 2 — `MapSet.size` (line 327):**
```elixir
assert MapSet.size(parallel_lanes) > 0,
       "expected at least one parallel verify lane with needs: build; regex may be broken"
```

D-12 says keep `>= 5` non-empty guard for the new assertion (to ensure at least the known 5 Postgres jobs are found). Use `map_size(postgres_blocks) >= 5` form.

### Existing `postgres` service assertion

[VERIFIED: ci_policy_contract_test.exs lines 179–193]

The test `"postgres service is configured only for test, knowledge, and connector jobs"` already asserts which jobs have `services:` blocks. The D-12 new assertion is distinct — it checks the **port value** inside those blocks, not just their presence. The two tests are complementary; D-12 extends, does not replace, line 179.

### Current test file module-level attributes

[VERIFIED: ci_policy_contract_test.exs lines 6–16]

```elixir
@ci_verify ".github/workflows/ci-verify.yml"
@ci_entry ".github/workflows/ci.yml"
@maintainer_docs "docs/MAINTAINERS.md"
@operator_docs "docs/operator_verification.md"
```

Both workflow files already have module-level attributes. The new D-12 test can use `@ci_verify` and `@ci_entry` directly — no new attributes needed for file paths. May want a module attribute for the ephemeral range threshold (`@ephemeral_range_min 32768`) for readability.

### Suggested D-12 contract test structure

```elixir
test "no CI Postgres job binds a host port in the ephemeral range (>= 32768)" do
  ci_verify = File.read!(@ci_verify)
  ci_entry = File.read!(@ci_entry)

  # Derive all job blocks that reference postgres across both files
  postgres_blocks =
    (job_blocks(ci_verify) |> Enum.filter(fn {_, body} -> body =~ "postgres:" end)) ++
    (job_blocks(ci_entry) |> Enum.filter(fn {_, body} -> body =~ "postgres:" end))
    |> Map.new()

  # Non-empty guard: must find >= 5 (e2e + test, knowledge, connector, full-suite)
  assert map_size(postgres_blocks) >= 5,
         "expected >= 5 postgres jobs across ci.yml + ci-verify.yml; regex may be broken"

  # Assert no ports: block binds a host port >= 32768 (ephemeral range start on GitHub runners)
  for {job, body} <- postgres_blocks do
    # Extract all "- NNNN:5432" or "- NNNN/tcp" style port bindings from services: block
    port_bindings = Regex.scan(~r/- (\d+)(?::\d+|\/tcp)/, body)
    for [_full, host_port_str] <- port_bindings do
      host_port = String.to_integer(host_port_str)
      assert host_port < 32768,
             "Job #{job}: host port #{host_port} is in the ephemeral range (>= 32768) — " <>
             "use a port below 32768 to prevent kernel bind conflicts on GitHub runners"
    end
  end
end
```

**Note for planner:** The exact regex form is Claude's Discretion (D-12). The above is a concrete suggestion. The `job_blocks/1` call on `ci_entry` will return a map containing `e2e`, `ci-gate`, `verify` (the workflow_call stub) — filter by `body =~ "postgres:"` to isolate the `e2e` job correctly.

---

## MAINTAINERS.md — Flake Policy Subsection (D-11)

### Current anchor and surrounding structure

[VERIFIED: MAINTAINERS.md lines 1–88]

```
## CI gate map {#ci-gate-map-maintainers}   ← line 5
  [... gate map content through line 88 ...]
## Hex release & recovery                   ← line 90
```

**Insert location:** After the existing gate map content (around line 88) and before `## Hex release & recovery` (line 90). The new subsection is `### Flake policy: retry vs fix` inside the `## CI gate map` section.

### What the new subsection must contain (D-07 through D-10)

- Zero-retry default stance
- Banned patterns: `continue-on-error: true`, job-level `retry:`, retry-action `uses:` slugs on `mix test` / e2e / verify steps
- One allowed exception class: infra-transient steps (distinct name, inline justification, log format, max 3 attempts, added under review)
- Fix-don't-retry: root-cause-and-fix or quarantine with `@tag :flaky` + tracking issue; `--repeat-until-failure` is for reproducing, not for masking

### Port references already in MAINTAINERS.md — do NOT change

[VERIFIED: MAINTAINERS.md — 12 occurrences of `55432`]

Lines 24, 26, 27, 28, 30, 41, 45, 50, 54, 77, 87, 88 all reference `SCORIA_DB_PORT=55432` as local-parity instructions. These are correct per D-05 — local stays on 55432. Do NOT update these. The new flake-policy subsection should note that CI will use port 5432 going forward (while local stays 55432).

---

## Retry Pattern Audit — D-08 Carve-Out Verification

### Carve-out files — confirmed `attempt` polling loops

[VERIFIED: direct grep]

| File | Pattern | Nature |
|------|---------|--------|
| `release-please.yml` | `for (let attempt = 1; attempt <= 40; attempt++)` (line 138), `for (let attempt = 1; attempt <= 40; ...)` (line 152), `seq 1 36` (line 260) | Poll for CI completion / Hex index availability |
| `hex-publish.yml` | `for (let attempt = 1; attempt <= 20; attempt++)` (line 72), `seq 1 36` (line 180) | Poll for CI completion / Hex index availability |
| `release-pr-automerge.yml` | `for attempt in $(seq 1 12)` (line 158) | Poll for ci-gate status / branch-protection |

These are all control-flow waits (D-08 carve-out). None run `mix test` or any assertion step.

### `integration-pr-automerge.yml` — no `attempt` loops

[VERIFIED: direct grep] `integration-pr-automerge.yml` has no `attempt` or `seq` patterns. It uses a simple `github-script` checks call without a retry loop.

### CI test workflows — confirmed zero retry patterns

[VERIFIED: direct grep on ci.yml and ci-verify.yml]

Neither `ci.yml` nor `ci-verify.yml` contains `continue-on-error`, `nick-fields`, `Wandalen`, `wretry`, or any `retry:` on test steps. D-07 codifies the existing de-facto state.

---

## Local Port vs CI Port — Full Context (D-05)

### Places that hardcode `55432` as LOCAL-ONLY (do NOT change)

[VERIFIED: direct grep across lib/ and config/]

| File | Lines | Context |
|------|-------|---------|
| `lib/scoria/verification_lanes.ex` | 48 | Local `command:` for semantic_fast_path lane |
| `lib/mix/tasks/scoria.pgvector.bootstrap.ex` | 9, 46, 56, 171, 193 | `@default_port 55432` — local pgvector bootstrap |
| `docs/MAINTAINERS.md` | 24, 26, 27, 28, 30, 41, 45, 50, 54, 77, 87, 88 | Local-parity commands for maintainers |

### Config fallback already correct — no change needed

[VERIFIED: config/test.exs line 7, config/dev.exs line 7]

```elixir
port: String.to_integer(System.get_env("SCORIA_DB_PORT", "5432")),
```

Both configs default to `"5432"`. When CI sets `SCORIA_DB_PORT: 5432`, this reads `5432`. When local sets `SCORIA_DB_PORT=55432`, this reads `55432`. No config changes needed.

---

## Architecture Patterns

### Pattern: GitHub Actions service-container port mechanics

**How ports work:**
- `ports: ['HOST:CONTAINER']` publishes the container port to the host at HOST.
- `localhost:HOST` is how the job's steps reach the service.
- The kernel allocates the host port at Docker container start time.
- If HOST is in the ephemeral range (32768–60999 on Linux), the kernel may have already assigned that port to an outbound socket → `port already allocated` error.
- `5432` is below 32768 → never collides with the ephemeral range.

**Why dynamic port (`- 5432/tcp`) was rejected (D-03):**

`${{ job.services.postgres.ports['5432'] }}` is only available at the step `env:` or `run:` level, NOT at the job-level `env:` block. Since `SCORIA_DB_PORT` is set at job level and read by all steps via config, using a dynamic port would require injecting the port into every step individually or using a step to set `GITHUB_ENV`. This is higher surface, worse failure mode (silent empty string if the expression isn't available). [ASSUMED — based on GitHub Actions context availability table referenced in D-03; the fundamental limitation is known but not re-verified against live GitHub docs in this session.]

### Pattern: String/regex contract tests (no YAML parser)

[VERIFIED: ci_policy_contract_test.exs — established idiom throughout]

All existing assertions use `File.read!` + `=~` / `Regex.scan` / `:binary.match`. Rationale: preserves assertion on source text including comments and ordering. No YAML parser dependency (no `yaml_elixir` or similar in mix.exs). D-12 explicitly requires staying string/regex-based.

### Anti-Patterns to Avoid

- **Changing local port references:** The 55432 references in verification_lanes.ex, pgvector.bootstrap.ex, MAINTAINERS.md are intentional local-only values (D-05). Touch only the 5 CI YAML blocks.
- **Adding SCORIA_DB_NAME to full-suite env:** The full-suite job intentionally omits it so `config/test.exs` resolves `scoria_test1..4` via `MIX_TEST_PARTITION`. Preserve this.
- **Using a YAML parser in contract tests:** The existing idiom is string/regex. Adding a YAML dep creates an ecosystem footgun and contradicts D-12.
- **Touching `docs/operator_verification.md`:** That is adopter-facing (D-11). The flake policy goes in MAINTAINERS.md only.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Detect if port is in ephemeral range | Custom OS query | Static threshold `32768` in contract test | Linux ephemeral range is well-defined; test asserts the constraint is never violated |
| Retry flaky tests | Auto-retry runner | `@tag :flaky` + tracking issue | ExUnit has no idiomatic auto-retry (`--repeat-until-failure` is for reproducing, not fixing) |
| YAML parsing for contract tests | yaml_elixir dep | String/regex on `File.read!` | Existing idiom; no new dep; works for ordering/comment checks too |

---

## Common Pitfalls

### Pitfall 1: Changing the wrong port values

**What goes wrong:** Updating the CI YAML ports but not the job-level `SCORIA_DB_PORT:` env, or vice versa — the app connects to localhost:5432 but Docker published a different host port (or vice versa).
**How to avoid:** Both `ports:` and `SCORIA_DB_PORT:` must be updated together in each of the 5 job blocks. They are always co-located in the YAML (services block → then env block a few lines below).
**Warning signs:** `pg_isready` health check passes (container is up) but `mix ecto.create` fails with connection refused or timeout.

### Pitfall 2: Updating local-parity port references in MAINTAINERS.md

**What goes wrong:** "Find and replace all 55432 → 5432" catches the local-parity instructions in MAINTAINERS.md, breaking the local setup story and the existing contract test `"maintainer CI gate map documents topology..."` which asserts `SCORIA_DB_PORT=55432 mix test` etc.
**How to avoid:** Changes are CI YAML only. MAINTAINERS.md gets a NEW flake-policy subsection — no search/replace of existing port references.
**Warning signs:** `mix test test/scoria/ci_policy_contract_test.exs` fails on `"maintainer CI gate map documents topology, parity, ratchet, and failure diagnosis"` (line 488).

### Pitfall 3: D-12 contract test passes vacuously

**What goes wrong:** `job_blocks/1` regex fails silently → `postgres_blocks` is empty → the `for` loop body never executes → test passes but asserts nothing.
**How to avoid:** Non-empty guard: `assert map_size(postgres_blocks) >= 5`. The current 5-job count is the correct floor.
**Warning signs:** Removing a `ports:` block from a job doesn't trigger a test failure.

### Pitfall 4: Full-suite `SCORIA_DB_NAME` accidentally added

**What goes wrong:** Copying an env block from `test:` or `knowledge:` job into `full-suite:` during the port edit accidentally adds `SCORIA_DB_NAME: scoria_test` → all 4 shards hit the same DB → data collision.
**How to avoid:** The full-suite env block only has these 5 vars: `MIX_ENV`, `SCORIA_DB_HOST`, `SCORIA_DB_PORT`, `SCORIA_DB_USERNAME`, `SCORIA_DB_PASSWORD`, `MIX_TEST_PARTITION`. No `SCORIA_DB_NAME`.
**Warning signs:** The existing contract test `"full-suite job is a 4-way matrix with correct partition wiring and no DB name collision"` (line 245) asserts `refute full_suite_body =~ "SCORIA_DB_NAME"`.

### Pitfall 5: TEMP step deletion leaves a dangling health wait

**What goes wrong:** The TEMP step sits between "Boot dev dashboard" (lines 103–113) and "Run dashboard e2e lane" (line 128). Deleting it is straightforward — there are no YAML anchors or step references that depend on `TEMP diagnose runs visibility` by name.
**How to avoid:** Verify the remaining step order after deletion: checkout → beam → node → deps cache → install deps → playwright cache → install e2e tooling → dev db setup → assets → boot → run e2e → upload report. No gap.

---

## Validation Architecture

`workflow.nyquist_validation` is absent from `.planning/config.json` — treat as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled with Elixir) |
| Config file | `config/test.exs` |
| Quick run command | `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` |
| Full suite command | `mix test --warnings-as-errors` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FLAKE-01 | No CI Postgres job binds host port >= 32768 | contract | `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` | ✅ (new test added to existing file) |
| FLAKE-02 | TEMP diagnostic step absent from ci.yml | contract | `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` | ✅ (new test added to existing file) |
| FLAKE-03 | No `continue-on-error`/retry-action on test steps (optional per discretion) | contract | `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs` | ✅ (new test, Claude's Discretion) |
| SC-4 | All existing contract tests and verification lanes stay green | regression | `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` | ✅ (existing tests, must remain green) |

### Sampling Rate

- **Per task commit:** `mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs`
- **Per wave merge:** Same (this phase is likely a single plan/wave)
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

None — `test/scoria/ci_policy_contract_test.exs` already exists and the `job_blocks/1` helper is ready. The new D-12 assertions are added to the existing file. No new test files, no framework install, no conftest needed.

**Additional contract tests to add (durable guard for FLAKE-01 and FLAKE-02):**

1. `"no CI Postgres job binds a host port in the ephemeral range (>= 32768)"` — D-12, FLAKE-01
2. `"e2e job in ci.yml has no TEMP diagnostic step"` — FLAKE-02 durable guard (optional but recommended; low cost)
3. (Claude's Discretion) `"no test workflow step uses continue-on-error or retry-action"` — D-07 enforcement

---

## Environment Availability

Step 2.6: SKIPPED — this phase is YAML surgery + ExUnit test extension + Markdown docs. No external tools, services, CLIs, runtimes, or databases beyond what already runs in CI. No new dependencies on anything external.

---

## Open Questions

1. **Header comment retargeting (D-11 discretionary)**
   - What we know: Both `ci.yml` (line 18) and `ci-verify.yml` (line 11) say `Maintainer narrative: docs/operator_verification.md`. D-11 says optionally retarget to `MAINTAINERS.md`.
   - What's unclear: Whether this should be done in Phase 27 or deferred to Phase 28's DX/docs pass.
   - Recommendation: Do it in Phase 27 — it's a 2-line edit in 2 files, directly related to D-11, and locks the maintainer narrative destination to the correct doc while the flake-policy subsection is being written.

2. **D-07 enforcement contract assertion**
   - What we know: Claude's Discretion says "recommended; low false-positive risk". No existing retry patterns on test steps confirmed.
   - What's unclear: Whether to assert on `continue-on-error` only in ci.yml / ci-verify.yml, or also in the carve-out files.
   - Recommendation: Scope to ci.yml + ci-verify.yml only. The carve-out files should be excluded from the assertion (use `refute ci_verify =~ "continue-on-error"` and `refute ci_entry_test_section =~ "continue-on-error"` or similar). Do not assert on release-please.yml / automerge files — those are not test-running workflows.

3. **TEMP step contract test — add or just delete?**
   - What we know: D-06 is "clear-cut — no gray area." FLAKE-02 just says to remove it.
   - What's unclear: Whether a contract assertion `refute ci_entry =~ "TEMP diagnose"` should be added to prevent re-introduction.
   - Recommendation: Yes — add `refute ci_entry =~ "TEMP diagnose"` to the new contract test (or as a standalone one-liner assertion). Costs nothing, prevents regression.

---

## Sources

### Primary (HIGH confidence)

- `.github/workflows/ci.yml` — direct read; exact line numbers for all edit sites confirmed
- `.github/workflows/ci-verify.yml` — direct read; exact line numbers for all 4 Postgres blocks confirmed
- `test/scoria/ci_policy_contract_test.exs` — direct read; `job_blocks/1` exact implementation, non-empty guard idiom, existing `postgres` assertions confirmed
- `docs/MAINTAINERS.md` — direct read; all 12 `55432` references confirmed local-only; flake-policy insertion point confirmed
- `lib/scoria/verification_lanes.ex` — direct read; line 48 `SCORIA_DB_PORT=55432` local command confirmed
- `config/test.exs`, `config/dev.exs` — direct read; `"5432"` default fallback confirmed (line 7 in both)
- `lib/mix/tasks/scoria.pgvector.bootstrap.ex` — direct read; `@default_port 55432` local-only, not a CI concern
- `.planning/config.json` — direct read; `nyquist_validation` key absent → treat as enabled

### Secondary (MEDIUM confidence)

- CONTEXT.md — all claims verified against live files; line number approximations noted as slightly off but structurally correct

### Tertiary (LOW confidence — requires acknowledgment)

- D-03 claim that `job.services.<id>.ports` is unavailable in job-level `env:` — [ASSUMED] accepted from CONTEXT.md (backed by GitHub Actions context availability table referenced in CONTEXT). Not re-verified against live GitHub docs in this session. Decision is locked; this note is for the planner's awareness only.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `job.services.<id>.ports` is NOT available in job-level `env:` (basis for rejecting D-03 dynamic port) | Edit-Site Inventory | Low — D-03 is already a rejected alternative; the fix (D-01, static 5432) is the locked decision regardless |

---

## Metadata

**Confidence breakdown:**
- Edit sites (exact line numbers): HIGH — direct file read
- Contract test extension approach: HIGH — `job_blocks/1` internals confirmed
- MAINTAINERS.md insertion point: HIGH — direct file read
- D-08 carve-out verification: HIGH — direct grep confirmed all `attempt` loops are control-flow only
- D-03 rejection basis (GitHub Actions context table): MEDIUM — accepted from CONTEXT, not re-verified

**Research date:** 2026-06-16
**Valid until:** Stable — no external ecosystem churn; validity is tied to the files in this repo, not external package releases
