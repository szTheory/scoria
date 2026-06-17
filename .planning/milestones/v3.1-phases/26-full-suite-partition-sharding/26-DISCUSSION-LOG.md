# Phase 26: Full-suite partition sharding - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-16
**Phase:** 26-full-suite-partition-sharding
**Areas discussed:** Sharded-job structure, Per-shard DB isolation, Zero-coverage-loss proof, Matrix fan-in wiring
**Mode:** Advisor (`opinionated` → `minimal_decisive`), followed by a user-requested deeper parallel-subagent research pass per area (idiomatic Elixir/Phoenix/Ecto, cross-ecosystem lessons, footguns, maintainer-JTBD/DX, coherence).

---

## Sharded-job structure

| Option | Description | Selected |
|--------|-------------|----------|
| A. New dedicated `full-suite:` matrix job | `needs: build`, `fail-fast: false`, `matrix.partition: [1,2,3,4]`; runs only `mix test --WAE --partitions 4`; closeout chain stays in `test:` and runs once | ✓ |
| B. Matrix the whole `test:` job | Re-runs release_preview + phx_new install + 3 closeout lanes 4× | |

**User's choice:** A (locked all four).
**Notes:** Cross-ecosystem confirmation (Nimblehq prod example, Playwright/Jest shard patterns). DX: name `full-suite (k/total)`. `--partitions 4` fits GitHub's 20-job cap. Footgun locked: no `--partition N` flag — `MIX_TEST_PARTITION` env selects the leg. Move the WAE step out of `test:`.

---

## Per-shard DB isolation

| Option | Description | Selected |
|--------|-------------|----------|
| A. Drop `SCORIA_DB_NAME`, set `MIX_TEST_PARTITION` at job env | config/test.exs `||` falls through to `scoria_test{k}`; job env propagates to all mix tasks | ✓ |
| B. Keep `SCORIA_DB_NAME: scoria_test`, rely on per-runner container isolation | Defeats partition naming; silent coupling if topology changes | |

**User's choice:** A.
**Notes:** Absence of `SCORIA_DB_NAME` is load-bearing. config/test.exs re-evaluated per mix invocation, so DB-prep + test all hit `scoria_test{k}`. POSTGRES_DB inert; health-cmd → `pg_isready -U postgres`. DB-prep strings stay byte-identical (contract greps). Canonical `mix phx.new` pattern; cross-ecosystem footgun = trusting infra isolation alone (Rails/pytest).

---

## Zero-coverage-loss proof

| Option | Description | Selected |
|--------|-------------|----------|
| A. Trust partition math + structural contract guard | rem-based complete residue system → union==suite by construction; assert `--partitions 4`/`MIX_TEST_PARTITION`/`[1,2,3,4]`/`needs: build` | ✓ |
| B (added). `after_suite` zero-test guard in test_helper | Closes the exit-0-with-0-tests vacuous-pass hole, gated on `MIX_TEST_PARTITION` | ✓ |
| C. Sum per-shard "N tests" vs baseline count | Magic number, cry-wolf, parse-miss vacuous pass | |
| D. `mix test --dry-run` count | Flag does not exist in Elixir | |

**User's choice:** A + B.
**Notes:** Verified `filter_by_partition/3` source (Elixir 1.19.5). New finding: ExUnit exits 0 on a 0-test partition (`{:noop,_}`) → after_suite guard is the only backstop. ~151 files → [38,38,38,37]. Cautionary tales: Knapsack Pro fallback false-green, Jest empty-shard, CircleCI duplicate-on-missing-timing. Reject numeric reconciliation.

---

## Matrix fan-in wiring

| Option | Description | Selected |
|--------|-------------|----------|
| A. Add `full-suite` to `verify-summary.needs`; `fail-fast:false`; never `continue-on-error` | Matrix → one aggregated `needs.*.result`; name-agnostic loop gates it; keep `if: always()` | ✓ |
| B. Wrap matrix in an extra aggregator job | Redundant unless using continue-on-error (which we avoid) | |

**User's choice:** A.
**Notes:** 3-vote adversarial verification confirmed: matrix aggregates to one result; `continue-on-error:true` is the false-green footgun; `if: always()` is mandatory (CodeQL #712 war story). Phase 25 subset test stays green (matched by job name); ADD targeted `"full-suite" in verify-summary.needs` assertion for fail-loud teeth. Shard names never auto-required → SC#4 with zero branch-protection edits. rust-analyzer canonical pattern.

---

## Claude's Discretion

- Exact regex/file placement of new contract asserts (`ci_policy_contract_test.exs` vs a sibling file).
- `POSTGRES_DB` value in the `full-suite:` container (parity `scoria_test` vs partition-keyed — both inert).
- YAML position of `full-suite:` among sibling jobs (order not load-bearing post Phase 25 D-01).
- `after_suite` guard phrasing + stderr diagnostic message.

## Deferred Ideas

- Shard wall-clock balance tuning (perf, not coverage) — measure after first run.
- Coverage-% reporting / `--cover` merge across shards — separate concern, don't add `--cover` here.
- Phase 27: fixed-host-port Postgres flake, TEMP e2e diagnostic removal, retry-vs-fix policy.
- Phase 28: `mix ci` alias + velocity closeout.
- Reviewed-not-folded todos: `ci-policy-job-cache-key-mislabel.md` (WR-01, already resolved in Phase 25); `docker-dx-fleet-hardening.md` (off-domain, v3 Docker DX track).
