# Phase 26: Full-suite partition sharding - Context

**Gathered:** 2026-06-16
**Status:** Ready for planning

<domain>
## Phase Boundary

The single full-suite step `mix test --warnings-as-errors` (today the last step of the
serial `test:` job in `.github/workflows/ci-verify.yml`, line ~185) fans out into a
**4-way `--partitions 4` runner matrix** on the shared `build-test-env` artifact, each
shard on its own runner with an **isolated partition-keyed database**, slotting under the
existing single `verify-summary` fan-in — collapsing full-suite wall-clock with **zero
coverage loss**.

**Topology after this phase (Phase 25 left it matrix-tolerant):**

```
policy → build → { test, ratchet, knowledge, connector, full-suite[×4 matrix] } → verify-summary
```

- The closeout chain (`release_preview → adoption → runtime_to_handoff → semantic_fast_path`)
  **stays in `test:` and runs exactly once**. Only the final `mix test --WAE` step **moves out**
  into the new sharded `full-suite:` job.
- Each sibling already `needs: build` and restores the compile-once artifact.

**Locked by ROADMAP success criteria (do not relitigate):**
1. Full suite runs as `mix test --warnings-as-errors --partitions 4` across a 4-way runner
   matrix, each exporting `MIX_TEST_PARTITION=${{ matrix.partition }}`. **No `config/test.exs`
   change** — it is already partition-aware (`database: System.get_env("SCORIA_DB_NAME") ||
   "scoria_test#{System.get_env("MIX_TEST_PARTITION")}"`).
2. Each shard uses an isolated database keyed by `MIX_TEST_PARTITION` → `scoria_test1..4`,
   so shards never collide on DB state.
3. Zero coverage loss vs the single-job run — the union of the 4 shards' executed tests
   equals the prior full-suite test count.
4. Only the `verify-summary` fan-in is required; individual matrix shard names are **never**
   added as required checks (branch protection still requires only `CI / ci-gate`).

**In scope:** the new `full-suite:` matrix job (inline preamble + DB-prep + sharded run);
moving the `mix test --WAE` step out of `test:`; wiring `full-suite` into
`verify-summary.needs`; the structural coverage-proof contract test (reusing Phase 25's
`job_blocks/1`); the `after_suite` zero-test guard in `test/test_helper.exs`; updating the
`docs/MAINTAINERS.md` job→local-command table (Phase 25 D-04) with the `full-suite (k/4)` row.

**Out of scope (later phases):** the fixed-host-port Postgres flake `-p 55432:5432`, the TEMP
e2e diagnostic removal, and the retry-vs-fix policy (Phase 27 — FLAKE-01/02/03); shard wall-clock
*balance* tuning (a perf concern, not coverage — partition-by-file can skew; revisit only if a
shard is consistently ~2× others); coverage-percentage reporting / `--cover` merge (a separate
concern with its own artifact-merge cost — do NOT add `--cover` to sharded jobs here); the
`mix ci` local alias + velocity closeout (Phase 28 — DX-01/VELO-01).

</domain>

<decisions>
## Implementation Decisions

All four areas were researched via advisor mode (`opinionated` → `minimal_decisive` tier), then
a SECOND deep parallel-subagent pass at the user's request (idiomatic Elixir/Phoenix/Ecto,
cross-ecosystem lessons, footguns, maintainer-JTBD/DX, coherence). UI/UX lens discarded (CI/devops
phase); the "user" is the **maintainer/contributor** (JTBD: fast green gate, map a failed
*shard* → the exact local command, never a false-green). The four decisions interlock — see the
**Coherence** note in `<specifics>`. They carry Phase 24/25 DNA (derived-not-magic-number,
fail-loud, contracts that proxy the real property, docs-as-contract) into the sharding layer.

### Sharded-job structure (SHARD-01, SC#1)

- **D-01 — New dedicated `full-suite:` matrix job; closeout stays in `test:`.**
  - Add `full-suite:` with `needs: build`, `strategy.fail-fast: false`, `strategy.matrix.partition:
    [1, 2, 3, 4]`. It runs ONLY the sharded full suite: `mix test --warnings-as-errors --partitions 4`.
  - **Move** the final `mix test --warnings-as-errors` step OUT of the `test:` job. The `test:`
    closeout chain (`release_preview → adoption → runtime_to_handoff → semantic_fast_path`) is
    untouched and runs **once**. Rejected: matrixing the whole `test:` job (would re-run the
    phx_new archive install + release_preview + 3 closeout test lanes 4× for zero coverage gain).
  - **Footgun locked:** there is **no `--partition N` flag**. Each leg runs `mix test --partitions 4`
    and `MIX_TEST_PARTITION` (env) selects which partition this leg is. Confirmed against Mix source
    (`Mix.Tasks.Test.filter_by_partition/3`, Elixir 1.19.5).
  - **`--partitions 4`** is right: it fills GitHub's parallelism (the parallel wave is ~11 jobs,
    well under the 20-concurrent cap), and matches the `scoria_test1..4` DB naming (D-03). Changing
    the count would also require revising the matrix + DB + contract assertions — out of scope.
  - **Job NAME for DX:** `name: "full-suite (${{ matrix.partition }}/${{ strategy.job-total }})"`
    → renders `full-suite (2/4)` in the UI; the digit maps 1:1 to `MIX_TEST_PARTITION=2` /
    `scoria_test2` (principle of least surprise — the name *is* the repro key).

### Per-shard DB isolation (SHARD-01, SC#2)

- **D-02 — Drop `SCORIA_DB_NAME`; set `MIX_TEST_PARTITION` at JOB-level env.**
  - The `full-suite:` job MUST NOT set `SCORIA_DB_NAME`. Its **absence is load-bearing**: the `||`
    in `config/test.exs` falls through to `scoria_test#{MIX_TEST_PARTITION}` only when
    `SCORIA_DB_NAME` is unset. (The sibling `test:`/`knowledge:`/`connector:` jobs keep
    `SCORIA_DB_NAME: scoria_test` precisely because they are NOT partitioned — leave them as-is.)
  - Set `MIX_TEST_PARTITION: ${{ matrix.partition }}` at **job-level `env:`** (not per-step). GHA
    propagates job env to every step's process, and `config/test.exs` is re-evaluated per mix task
    invocation (not compile-baked) — so `mix ecto.create`, `mix ecto.migrate --to …`, the
    `mix eval 'Scoria.TestSupport.Migrations.migrate_knowledge!()'`, and `mix test` ALL resolve the
    same `scoria_test{k}`. No per-step env repetition (a known split-brain footgun).
  - Keep the other `SCORIA_DB_*` env (host/port/username/password) — needed to connect to the
    sidecar. The container's `POSTGRES_DB` is **inert** (`mix ecto.create` creates `scoria_test{k}`
    itself); recommend setting the service health-cmd to `pg_isready -U postgres` (drop `-d
    scoria_test`) so readiness doesn't couple to a DB name that won't exist until `ecto.create`.
    Whether `POSTGRES_DB` stays `scoria_test` (parity) or is partition-keyed is **planner discretion**
    — both are inert and correct.
  - **DB-prep block stays byte-identical** to the sibling jobs (same `mix ecto.migrate --to
    20260511000300` + `migrate_knowledge!()` literal strings the Phase 24/25 contract greps depend
    on) with the `# DB-prep: keep in sync with sibling parallel jobs` marker. SC#1's "no
    config/test.exs change" holds — only YAML env changes.

### Zero-coverage-loss proof (SHARD-01, SC#3)

- **D-03 — Trust partition math + structural contract guard + `after_suite` zero-test guard.**
  - **Math (verified):** `filter_by_partition/3` is `Enum.sort(files) |> Enum.with_index() |>
    Enum.filter(fn {_, i} -> rem(i, total) == partition - 1 end)`. The sorted file list indexed
    `0..N-1` maps each file to exactly partition `rem(i, total)`; `{0..total-1}` is a complete
    residue system → **union of the 4 shards == full suite BY CONSTRUCTION** (mathematical, not a
    runtime count). Sort is deterministic by design (the source comment cites cross-OS duplicate
    avoidance). ~151 test files → partitions ≈ [38, 38, 38, 37].
  - **Structural contract test** (new, in `ci_policy_contract_test.exs`, reusing Phase 25
    `job_blocks/1`): assert the `full-suite:` block contains `--partitions 4`, wires
    `MIX_TEST_PARTITION` from `matrix.partition`, declares `partition: [1, 2, 3, 4]`, and has
    `needs: build`. Include the non-empty `job_blocks` guard (a broken parser can't vacuously pass).
    Document the rem-completeness proof as a comment next to the assertions (docs-as-contract).
  - **`after_suite` zero-test guard** (new, in `test/test_helper.exs`): ExUnit exits **0** when a
    partition runs **0 tests** (`{:noop,_}` path — verified vacuous-pass hole). Add, **gated on
    `System.get_env("MIX_TEST_PARTITION")`**, an `ExUnit.after_suite(fn %{total: total} -> ... end)`
    that `exit({:shutdown, 1})` when `total == 0`. Only active during partitioned CI runs (never
    local/lane runs); derived from ExUnit's own summary (no magic number); never fires in normal
    operation but is insurance against a future empty shard.
  - **REJECTED — numeric count-reconciliation** (sum per-shard "N tests" vs a baseline): `mix test
    --dry-run` does not exist; the "N tests" line drifts as tests are added (cry-wolf magic number,
    DNA violation); a parse miss vacuously passes; runtime test counts shift with tag filters.
    Cross-ecosystem cautionary tales: Knapsack Pro fallback-mode false-green, Jest empty-shard
    (#13027), CircleCI duplicate-on-missing-timing.
  - A leg that crashes (compile/DB-prep/test non-zero exit) or is skipped is already caught by the
    existing `verify-summary` (`skipped/failure = fail`). The `after_suite` guard closes the ONLY
    residual hole (exit-0-with-0-tests).

### Matrix fan-in / required-check wiring (SHARD-01, SC#4)

- **D-04 — Add `full-suite` to `verify-summary.needs`; `fail-fast:false`; never `continue-on-error`.**
  - GitHub aggregates a matrix strategy into ONE `needs.<job>.result` (= `failure` if any leg fails;
    `cancelled`/`skipped` propagate). Add `full-suite` to `verify-summary.needs: [policy, build,
    test, ratchet, knowledge, connector, full-suite]`; the existing name-agnostic
    `join(needs.*.result)` loop (skipped = fail) gates it automatically — no per-child edit.
  - **Keep `if: always()` on `verify-summary`** (non-negotiable — a fan-in without it gets *skipped*
    when an upstream is cancelled and branch protection reads skipped as success; this is the
    CodeQL #712 false-green war story).
  - **`fail-fast: false`** on the matrix so all 4 shards run to completion → the maintainer sees ALL
    failing shards in one run (and can re-run a single flaky leg). **NEVER `continue-on-error: true`**
    — confirmed footgun (community #45546): it reports failed legs as `success` to `needs.*.result`,
    a false-green. `fail-fast: false` is the correct substitute.
  - **Phase 25 derived subset test stays green** (it derives jobs with `needs: build` and asserts
    each ∈ `verify-summary.needs`; the matrix job qualifies and is matched by job NAME, not leg name
    — matrix-tolerant by design). **ADD one targeted assertion** `assert "full-suite" in
    verify_summary_needs(...)` so a future dev who adds the job but forgets the fan-in wiring gets a
    loud red (fail-loud teeth specific to the matrix job).
  - Shard check names (`full-suite (1/4)` …) never auto-become required — branch protection requires
    only `CI / ci-gate`; SC#4 satisfied with **zero** branch-protection edits. Canonical pattern,
    matches rust-analyzer's `cancel-if-matrix-failed` fan-in.

### Claude's Discretion
- Exact regex/parsing additions to `ci_policy_contract_test.exs` vs a sibling
  `ci_verify_contract_test.exs` if the file grows too long — follow existing repo conventions.
- `POSTGRES_DB` value in the `full-suite:` service container (`scoria_test` for sibling-parity vs
  partition-keyed) — both inert; pick the least-surprising diff against `test:`.
- Exact YAML position of the `full-suite:` job among the sibling parallel jobs (order is not
  load-bearing — Phase 25 D-01 asserts parallel-shape, not byte-order).
- Exact `after_suite` guard phrasing and the stderr diagnostic message.

### Folded Todos
- None folded into this phase. (WR-01 — the policy cache-key/MIX_ENV mislabel — was already folded
  into and resolved by Phase 25; see Reviewed Todos below.)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope / requirements
- `.planning/ROADMAP.md` §"Phase 26: Full-suite partition sharding" — goal + 4 success criteria.
- `.planning/REQUIREMENTS.md` — **SHARD-01** (the single requirement this phase satisfies; mapping
  table at line ~84). FLAKE-01/02/03 (Phase 27) and DX-01/VELO-01 (Phase 28) are explicitly NOT this phase.
- `.planning/PROJECT.md` §"Current Milestone: v3.1 CI/CD Velocity" — hard constraint: never weaken
  the verification bar (nothing demoted to nightly); single fast PR+main gate.
- `prompts/sztheory-elixir-dna.md` — engineering DNA the decisions align with (operator-first DX,
  automation over manual, robust CI/CD, idiomatic Elixir, least surprise, don't over-engineer).

### Prior-phase context this phase builds on
- `.planning/phases/25-lane-parallelization-topology-docs/25-CONTEXT.md` — the parallel topology +
  name-agnostic `verify-summary` fan-in (D-02), the `job_blocks/1` YAML parser + derived
  fan-in-completeness subset test (D-01/D-02), inline DB-prep / no-composite-action (D-03), the
  docs job→command table (D-04). Phase 25 explicitly left the fan-in "matrix-tolerant" for THIS phase.
- `.planning/phases/23-cache-correctness-build-once-job/23-CONTEXT.md` — the `build` job +
  `build-test-env` artifact every parallel job restores (no cold compile); env-scoped cache keys.
- `.planning/phases/24-knowledge-lane-scope-fix/24-CONTEXT.md` — the derived-not-magic-number /
  fail-loud contract-test DNA that D-03's structural guard mirrors (non-empty guard so a broken
  regex can't vacuously pass).

### CI files this phase modifies
- `.github/workflows/ci-verify.yml` — reusable `workflow_call` SSOT. The `test:` job (lines ~102–185)
  loses its final `mix test --WAE` step; the new `full-suite:` matrix job is added; `verify-summary`
  (lines ~340–356) gains `full-suite` in `needs:`. Holds the literal DB-prep strings the contract
  greps depend on (keep inline + byte-identical).
- `.github/workflows/ci.yml` — PR/main entry: `verify` (uses `ci-verify.yml`), `e2e`, `ci-gate`
  (`needs: [verify, e2e]`). `ci-gate` name + branch protection are **untouched**.
- `config/test.exs` (lines 8–10) — already partition-aware; **DO NOT change** (SC#1). It is why
  dropping `SCORIA_DB_NAME` + setting `MIX_TEST_PARTITION` is sufficient.
- `.tool-versions` — `erlang 27.3.2`, `elixir 1.19.5-otp-27` (the `version-file:` source; the
  Elixir version whose `filter_by_partition/3` the proof relies on).

### Test/contract files this phase adds to
- `test/scoria/ci_policy_contract_test.exs` — home of `job_blocks/1` + Phase 25's derived fan-in
  test; add the D-03 structural coverage-proof asserts and the D-04 targeted `full-suite ∈
  verify-summary.needs` assertion here (or a sibling `ci_verify_contract_test.exs` per convention).
- `test/scoria/verification_lanes_test.exs` — pins lane set; check whether the new `full-suite` lane
  needs representation here for parity with Phase 25's lane assertions.
- `test/test_helper.exs` — home of the new `after_suite` zero-test guard (gated on `MIX_TEST_PARTITION`).

### Docs to update in lockstep
- `docs/MAINTAINERS.md` §"## CI gate map" — add the `full-suite (k/4)` row to the job→local-command
  table (Phase 25 D-04), e.g. `SCORIA_DB_PORT=55432 MIX_TEST_PARTITION=k mix test
  --warnings-as-errors --partitions 4` (no `SCORIA_DB_NAME`). Update the topology line to include
  `full-suite`. If `ci_policy_contract_test.exs` asserts the gate map names each lane, add `full-suite`.
- `docs/operator_verification.md` and `README.md` — CI topology line updated in the same commit if
  they enumerate the lanes (docs-as-contract).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`job_blocks/1`** (`ci_policy_contract_test.exs`, Phase 25) — parses `jobs:` into `%{name =>
  body}`; reused by both the D-03 structural proof asserts and the D-04 fan-in assertion.
- **`verify-summary` name-agnostic fan-in** (`ci-verify.yml`, Phase 25 D-02) — `join(needs.*.result)`
  loop, skipped=fail; auto-gates the matrix job once `full-suite` is in `needs:` (no bash edit).
- **`build` job + `build-test-env` artifact** (Phase 23) — the `full-suite:` job restores it via
  `download-artifact` + `tar -xzf` instead of cold-compiling.
- **Sibling Postgres-job preamble + inline DB-prep** (`test:`/`knowledge:`/`connector:`) — copy
  verbatim into `full-suite:` (setup-beam `version-file:.tool-versions` + artifact download + DB-prep
  block), differing only by the matrix + dropped `SCORIA_DB_NAME` + added `MIX_TEST_PARTITION`.
- **Phase 24 derived file-set contract pattern** (non-empty guard, derived-not-hardcoded) — the
  template D-03's structural proof follows.

### Established Patterns
- **Contract-as-ExUnit-test** — CI invariants (topology, lane order, docs content) asserted in
  `ci_policy_contract_test.exs` / `verification_lanes_test.exs`. New invariants (`--partitions 4`
  present, `MIX_TEST_PARTITION` wired, fan-in completeness) follow the same pattern.
- **Per-job `services: postgres`** — job-level only (no composite action); carried by each
  Postgres-needing job. `full-suite:` carries its own.
- **`config/test.exs` partition-awareness** — `database: SCORIA_DB_NAME || "scoria_test#{MIX_TEST_PARTITION}"`
  is the canonical `mix phx.new` pattern; the same convention appears in
  `test/support/scoria/host_app_proof/generator.ex` (`"#{app_name}_test#{MIX_TEST_PARTITION}"`).

### Integration Points
- `ci.yml` `verify:` job result reflects `verify-summary` (which now includes `full-suite`);
  `ci-gate` consumes `needs.verify.result` unchanged.
- The `test:` job and the `full-suite:` job share the same Postgres image/version and DB-prep
  sequence — keep them in sync (the marker comment + grep).

</code_context>

<specifics>
## Specific Ideas

- User ran advisor mode (`opinionated` → `minimal_decisive`) then requested a SECOND, deeper
  parallel-subagent research pass per area: idiomatic Elixir/Plug/Ecto/Phoenix practice,
  cross-ecosystem lessons (Rails parallel_tests, pytest-xdist, Jest --shard, CircleCI/Knapsack Pro,
  rust-analyzer, CodeQL), footguns, maintainer-JTBD/DX, and coherence — "one-shot a perfect,
  coherent set so I don't have to think." UI/UX lens explicitly discardable (CI/devops phase).
- **Coherence note (why the four lock together):** D-01 and D-03/D-04 share Phase 25's `job_blocks/1`
  parser. D-02 keeps the DB-prep literals byte-identical so existing contract greps + the D-03 proof
  asserts keep resolving. D-03's math guarantee + structural guard + `after_suite` guard make the
  "zero coverage loss" claim provable without a magic-number. D-04's fan-in derivation was
  pre-made matrix-tolerant by Phase 25. The set goes RED only on real drift (missing `--partitions 4`,
  an unwired fan-in, an empty shard), never on a safe reorder.
- **Verified facts the planner can rely on:** (1) Mix has no `--partition N` flag — `MIX_TEST_PARTITION`
  env selects the leg. (2) `filter_by_partition/3` = sort|>with_index|>rem → total coverage by
  construction (Elixir 1.19.5). (3) ExUnit exits 0 on a 0-test partition (`{:noop,_}`) → the
  `after_suite` guard is the only backstop for that hole. (4) GitHub aggregates a matrix into one
  `needs.*.result`; `continue-on-error: true` would false-green it; `fail-fast: false` is the right knob.
- **Maintainer JTBD framing:** a failed shard `full-suite (2/4)` must map obviously to
  `MIX_TEST_PARTITION=2 mix test --partitions 4` locally → drives the job name (D-01) and the
  job→command doc-table row.

</specifics>

<deferred>
## Deferred Ideas

- **Shard wall-clock BALANCE** — partition-by-file can skew if one file dominates; this is a perf
  concern, not coverage. Measure after the first sharded run; only split a hot file or adjust the
  count if a shard is consistently ~2× the others. Not in scope for SHARD-01.
- **Coverage-percentage reporting / `--cover` merge across shards** — has its own artifact
  upload/download/merge cost (Jest-shard cautionary tale); a separate concern. Do NOT add `--cover`
  to the sharded jobs in this phase.
- **Phase 27 (FLAKE-01/02/03)** — fixed-host-port Postgres `-p 55432:5432`, TEMP e2e diagnostic
  removal, retry-vs-fix policy. Untouched here (parallel runners don't worsen the host-port flake).
- **Phase 28 (DX-01/VELO-01)** — `mix ci` local alias + velocity closeout; before/after timing
  measured against the fully-parallelized pipeline this phase completes.

### Reviewed Todos (not folded)
- **`ci-policy-job-cache-key-mislabel.md`** (WR-01) — matched (score 0.6) but **already folded into
  and resolved by Phase 25** (set `MIX_ENV: test` on the `policy` job). Not re-opened here.
- **`docker-dx-fleet-hardening.md`** — matched weakly (score 0.4, keyword "phase" only); belongs to
  the v3 Docker DX track, unrelated to CI sharding. Not in scope.

</deferred>

---

*Phase: 26-full-suite-partition-sharding*
*Context gathered: 2026-06-16*
