# Requirements: Scoria — v3.1 CI/CD Velocity

**Defined:** 2026-06-14
**Core Value:** Phoenix teams can add AI runtime governance to an existing app with confidence — which depends on a CI pipeline that is fast, deterministic, and trustworthy enough that maintainers and contributors actually run it.

**Milestone goal:** Cut PR CI wall-clock from ~77 min to ~12 min and eliminate known flakes, **without weakening the verification bar** — every lane that gates merge today still gates merge; nothing is demoted to a nightly tier.

## v1 Requirements

Requirements for this milestone. Each maps to exactly one roadmap phase.

### Caching (CACHE)

- [x] **CACHE-01**: CI cache keys are scoped by OS + OTP + Elixir + `MIX_ENV` + `mix.lock` hash so dev (`MIX_ENV=dev`) and test (`MIX_ENV=test`) `_build` artifacts never collide or cause spurious recompiles.
- [x] **CACHE-02**: A dedicated `build` job compiles deps + app once (`MIX_ENV=test`, warnings-as-errors) and publishes `_build/test` + `deps` as an artifact that every downstream job restores instead of recompiling.

### Knowledge Lane (KNOW)

- [x] **KNOW-01**: The knowledge verification lane runs only knowledge-tagged tests (e.g. `--only knowledge`), not the full suite, while preserving the same warnings-as-errors bar and the `mix test.knowledge --warnings-as-errors` contract string.

### Lane Parallelization (PAR)

- [ ] **PAR-01**: The heavy `verify / test` lanes run as parallel `needs:`-jobs (closeout `test:` chain, ratchet hygiene, knowledge, connector + advisory gallery) rather than one serial job.
- [ ] **PAR-02**: A single stable fan-in job (`verify-summary`) aggregates all parallel verify jobs and is what `ci-gate` depends on; the `CI / ci-gate` required-check name is unchanged so branch protection needs no edit, and skipped/parallel children are never individually required.
- [ ] **PAR-03**: The `Scoria.VerificationLanes` byte-order/closeout-order contract tests (`ci_policy_contract_test`, `verification_lanes_test`) stay green — every canonical lane still executes in its pinned order.

### Suite Sharding (SHARD)

- [x] **SHARD-01**: The full ExUnit suite runs sharded via `mix test --partitions 4` across a runner matrix, each shard using an isolated database (already keyed by `MIX_TEST_PARTITION` in `config/test.exs`), with no coverage loss versus the single-job run.

### Determinism & Flake Elimination (FLAKE)

- [x] **FLAKE-01**: The Postgres service container no longer fails on host-port bind conflicts — the fixed `-p 55432:5432` mapping (in `ci.yml` + `ci-verify.yml`) is replaced with a non-conflicting connection strategy (network alias / dynamic port / resilient bind). Reproduced on run `27508317719`.
- [x] **FLAKE-02**: The leftover TEMP diagnostic step (DB run-count + server-render dump) is removed from the `e2e` job in `ci.yml`.
- [x] **FLAKE-03**: A deliberate retry-vs-fix policy is documented and applied — no blanket auto-retries that mask real flakes; retries (if any) are scoped to known-infra-transient steps only and surfaced in logs.

### Developer Experience (DX)

- [x] **DX-01**: A single `mix ci` alias reproduces the merge gate locally (deps lock check, format check, compile WAE, the canonical lane set) so a contributor can run the same checks CI runs.
- [ ] **DX-02**: `docs/MAINTAINERS.md`, `docs/operator_verification.md`, and `README` describe the new parallel CI topology, and any contract test asserting "docs describe topology" stays green.

### Outcome (VELO)

- [x] **VELO-01**: On a warm-cache PR run, CI critical-path wall-clock is ≤ ~15 min (target ~12 min), down from the ~77 min baseline — verified via `gh run view --json jobs` timing before/after. MEASURED: 7m38s (458s) critical path in run 27709716751 (commit 06cdc34, 2026-06-17). MET.

## v2 Requirements

Deferred to future milestones. Tracked but not in this roadmap.

### Test-Code Determinism (SEED-004)

- **ASYNC-01**: Convert forced-serial `IntegrationCase` files to `async: true` (de-globalize the per-test `Reconciler`).
- **ASYNC-02**: De-globalize per-module Phoenix test endpoints so those LiveView tests can run async.
- **ASYNC-03**: Replace ~14 `Process.sleep` sites with the existing `eventually/2` polling helper; raise partition count past 4 once the serial floor drops.

### Docker DX (todo)

- **DOCKER-01**: `docker-dx-fleet-hardening` — adjacent dev-harness hardening (already captured as a pending todo).

## Out of Scope

| Feature | Reason |
|---------|--------|
| Test-code async/`Process.sleep` refactor | Higher product risk; touches 9+ test files. Deferred to SEED-004 (v2 above). This milestone is infra/docs only. |
| Nightly / scheduled CI tier | After parallelization everything fits in ~12 min; a single fast PR+main gate is kept. Nothing demoted — preserves the bar and avoids a second pipeline to maintain. |
| Larger / self-hosted runners | `mix test --partitions` over standard `ubuntu-latest` gives the parallelism without runner-cost or ops complexity. |
| Node-24 actions modernization | Already shipped as hotfix PR #10 (merged) ahead of the 2026-06-16 deadline. |
| Adding Dialyzer / new static-analysis tools to CI | Not currently in the project; adding them is scope expansion, not velocity work. |
| Reordering or widening `VerificationLanes.closeout_order/0` | The bar must not change; parallelization preserves order, it does not re-sequence it. |

## Traceability

Phase numbering continues the live epoch (v2.12=02–04 … v3.0=11–17, v2.17=18–22). v3.1 starts at **Phase 23**; verified no collision with any archived phase directory under `.planning/milestones/*-phases/` (archived numbers are 01–22 and 52–82; 23–28 sit in the unused gap).

| Requirement | Phase | Status |
|-------------|-------|--------|
| CACHE-01 | Phase 23 | Complete |
| CACHE-02 | Phase 23 | Complete |
| KNOW-01 | Phase 24 | Complete |
| PAR-01 | Phase 25 | Pending |
| PAR-02 | Phase 25 | Pending |
| PAR-03 | Phase 25 | Pending |
| DX-02 | Phase 25 | Pending |
| SHARD-01 | Phase 26 | Complete |
| FLAKE-01 | Phase 27 | Complete |
| FLAKE-02 | Phase 27 | Complete |
| FLAKE-03 | Phase 27 | Complete |
| DX-01 | Phase 28 | Complete |
| VELO-01 | Phase 28 | Complete |

**Coverage:**
- v1 requirements: 13 total
- Mapped to phases: 13 ✓
- Unmapped: 0 ✓

Per-phase requirement counts: Phase 23 (2), Phase 24 (1), Phase 25 (4), Phase 26 (1), Phase 27 (3), Phase 28 (2) = 13.

---
*Requirements defined: 2026-06-14*
*Last updated: 2026-06-17 — DX-01 and VELO-01 flipped to Complete; measured 7m38s critical path in run 27709716751 (Plan 28-03)*
