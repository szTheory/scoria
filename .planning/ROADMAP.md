# Roadmap: Scoria

**Last updated:** 2026-06-14 (v3.1 CI/CD Velocity roadmap created — Phases 23–28)

## Milestones

- 📋 **v3.1 CI/CD Velocity** — Phases 23–28 (cut CI ~77m → ~12m, eliminate flakes, preserve the bar) — ACTIVE (SEED-003)
- ✅ **v3.0 Control Room** — Phases 11–17 (dashboard design-system / IA / motion / proof) — SHIPPED 2026-06-14 — [archive](milestones/v3.0-ROADMAP.md)
- ✅ **v2.17 Vesicle** — Phases 18–22 (brand system, interjected) — SHIPPED 2026-06-11 — [archive](milestones/v2.17-ROADMAP.md)
- ✅ **v2.16 ReqLLM Peer Bump** — Phases 08–10 + 10.1 (shipped 2026-05-30) — [archive](milestones/v2.16-ROADMAP.md)
- ✅ **v2.15 Connector Adoption Lane** — Phases 05–07 + 07.1 (shipped 2026-05-30) — [archive](milestones/v2.15-ROADMAP.md)
- ✅ **v2.14 Maintenance Release** — `0.1.1` prep (shipped 2026-05-30)
- ✅ **v2.13 Adopter Docs Truth** — MAINTAINERS split, Hex metadata (shipped 2026-05-30)
- ✅ **v2.12 Adoption Confidence & Reference Demo** — Phases 02–04 (shipped 2026-05-30)

## Phases

### 📋 v3.1 CI/CD Velocity (Phases 23–28) — ACTIVE

Infra/docs-only milestone realizing **SEED-003**. Cut PR CI wall-clock from ~77 min (today: one serial `verify / test` job ≈ 76m) to ~12 min and eliminate known flakes — **without weakening the verification bar**: every lane that gates merge today still gates merge, nothing demoted to nightly. Hard constraints held throughout: preserve `Scoria.VerificationLanes.closeout_order/0` and the byte-order lane contract (`ci_policy_contract_test`, `verification_lanes_test`) green at *every* phase; single fast PR+main gate; standard `ubuntu-latest` runners; the `CI / ci-gate` required-check name stays stable. Sequenced lowest-risk-highest-payoff first: cache/build-once foundation → the single biggest win (knowledge scope fix) → parallelization (with topology docs folded in) → sharding → flake elimination → DX alias + timing closeout.

Node-24 actions modernization is **already shipped** (PR #10, merged) and is intentionally NOT a phase here.

- [x] **Phase 23: Cache correctness + build-once job** — env-scoped cache keys; a `build` job compiles once and shares `_build/test` + `deps` as an artifact to all downstream jobs. — completed 2026-06-14
- [x] **Phase 24: Knowledge lane scope fix** — `--only knowledge` so the knowledge lane stops re-running the full suite (~−22m), same WAE bar, contract string unchanged. (completed 2026-06-15)
- [ ] **Phase 25: Lane parallelization + topology docs** — split heavy `verify / test` lanes into parallel `needs:` jobs with a fan-in `verify-summary`; preserve byte-order contract + `ci-gate` name; topology docs move in lockstep.
- [ ] **Phase 26: Full-suite partition sharding** — `mix test --partitions 4` across a runner matrix on the shared build artifact, isolated DB per shard, zero coverage loss.
- [ ] **Phase 27: CI determinism & flake elimination** — fix the fixed-host-port Postgres flake, remove the leftover TEMP e2e diagnostic, document a retry-vs-fix policy.
- [ ] **Phase 28: DX `mix ci` alias + velocity closeout** — one local command mirroring the gate; prove ≤~15m warm-cache critical path via before/after `gh run` timing.

<details>
<summary>✅ v3.0 Control Room (Phases 11–17) — SHIPPED 2026-06-14</summary>

UI/IA/DX milestone. No net-new backend capability families. Expose components → delete leaked classes → consolidate → orient → polish → prove. Sequenced for compounding reuse: primitives before screens, least-iterated screens before high-traffic, motion/responsive/theme last before the proof sweep.

- [x] Phase 11: Evaluation engine + seed depth (5/5 plans) — completed 2026-06-04
- [x] Phase 12: Design-system component layer (5/5 plans) — completed 2026-06-04
- [x] Phase 13: Orientation spine (IA) (8/8 plans) — completed 2026-06-12
- [x] Phase 14: Least-iterated screens polish (6/6 plans) — completed 2026-06-12
- [x] Phase 15: High-traffic screens + evidence adapters (5/5 plans) — completed 2026-06-13
- [x] Phase 16: Motion + responsive + theme parity (6/6 plans) — completed 2026-06-13
- [x] Phase 17: Consistency sweep + proof (3/3 plans) — completed 2026-06-13

Full details: `.planning/milestones/v3.0-ROADMAP.md`. Closed with `gaps_found` audit accepted — 10 verification-doc gaps recorded as Known Gaps in MILESTONES.md.

</details>

<details>
<summary>✅ v2.17 Vesicle (Phases 18–22) — SHIPPED 2026-06-11</summary>

- [x] Phase 18: Pressure-test audit + decision lock — gate #1 approved 2026-06-11 (tagline override "AI ops for Phoenix apps."; propagation: not-required) — completed 2026-06-11
- [x] Phase 19: Logo divergence + user choice — gate #2 (2 rounds): TV-1 "Span rail" mark + LK-B "Mark-as-o" fused lockup locked — completed 2026-06-11
- [x] Phase 20: Logo convergence — full variant set — 8 root variants, user confirmed "ship it" — completed 2026-06-11
- [x] Phase 21: Tokens + brand book + standalone HTML — tokens.json/css, brand-book.md 543 lines, 7 examples, index.html 55 KB — completed 2026-06-11
- [x] Phase 22: Integration + final quality gate — quality-gate.mjs 8/8 PASS, 458 KB, mix test 632 green, DS-06 untouched — completed 2026-06-11

Full details: `.planning/milestones/v2.17-ROADMAP.md`

</details>

<details>
<summary>✅ v2.16 ReqLLM Peer Bump (Phases 08–10 + 10.1) — SHIPPED 2026-05-30</summary>

- [x] Phase 08: Bump ReqLLM constraint and lockfile — completed 2026-05-30
- [x] Phase 09: Compatibility fixes and test verification — completed 2026-05-30
- [x] Phase 10: CI lane verification and closeout — completed 2026-05-30
- [x] Phase 10.1: VERIFICATION gap closeout (INSERTED) — 1/1 plan — completed 2026-05-30

Full details: `.planning/milestones/v2.16-ROADMAP.md`

</details>

<details>
<summary>✅ v2.15 Connector Adoption Lane (Phases 05–07 + 07.1) — SHIPPED 2026-05-30</summary>

- [x] Phase 05: Lane contract + Mix task — completed 2026-05-30
- [x] Phase 06: Integration proof + SupportJourney alignment — completed 2026-05-30
- [x] Phase 07: Docs, drift guards, CI wiring — completed 2026-05-30
- [x] Phase 07.1: VERIFICATION gap closeout (INSERTED) — 1/1 plan — completed 2026-05-30

Full details: `.planning/milestones/v2.15-ROADMAP.md`

</details>

## Phase Details

### Phase 23: Cache correctness + build-once job

**Goal**: CI compiles deps + app exactly once per run and every downstream job reuses that artifact, with cache keys that never collide across `MIX_ENV` or stale tool versions.
**Depends on**: Nothing (foundation for all downstream parallel/shard jobs)
**Requirements**: CACHE-01, CACHE-02
**Success Criteria** (what must be TRUE):

  1. CI cache keys are scoped by OS + OTP + Elixir + `MIX_ENV` + `mix.lock` hash (OTP/Elixir sourced from `.tool-versions`), so `MIX_ENV=dev` and `MIX_ENV=test` `_build` artifacts never share a key — verified by no spurious recompiles in job logs across dev/test steps.
  2. A dedicated `build` job runs `mix deps.get && mix compile --warnings-as-errors` (`MIX_ENV=test`) once and publishes `_build/test` + `deps` via `upload-artifact`.
  3. Every downstream job `needs: build` and restores that artifact instead of recompiling — confirmed by absence of a cold-compile step in downstream job logs.
  4. The lane contract tests (`ci_policy_contract_test`, `verification_lanes_test`) remain green — no command string moved out of pinned byte-order.

**Plans**: 1 plan
Plans:

- [x] 23-01-PLAN.md — env+version-scoped cache keys, build-once job (tar artifact), test-job restore, contract-test extensions

### Phase 24: Knowledge lane scope fix

**Goal**: The knowledge verification lane runs only its knowledge-tagged tests instead of re-running the entire suite, reclaiming ~22 min with zero coverage loss and an unchanged merge bar.
**Depends on**: Phase 23 (runs on the warm shared build artifact)
**Requirements**: KNOW-01
**Success Criteria** (what must be TRUE):

  1. The knowledge lane runs only the 6 knowledge-tagged files (e.g. via `--only knowledge`) — verified by log file/line count dropping from a full-suite re-run to the scoped set.
  2. The same warnings-as-errors bar holds and the literal `mix test.knowledge --warnings-as-errors` contract string is unchanged in `ci-verify.yml`.
  3. Knowledge coverage is preserved: every knowledge-tagged test that ran before still runs (no `:knowledge` test silently excluded).
  4. `ci_policy_contract_test` + `verification_lanes_test` stay green (the command-string contract is unaffected by the internal arg change).

**Plans**: 1 plan

Plans:

- [x] 24-01-PLAN.md — scope knowledge lane to --only knowledge inside the mix task, add the after_suite zero-test guard, and add the derived-file-set coverage contract test (D-01/D-02/D-03)

### Phase 25: Lane parallelization + topology docs

**Goal**: The heavy serial `verify / test` job fans out into parallel `needs:`-jobs gated by one stable fan-in check, the canonical lane order is preserved as YAML byte-order, and the docs that the contract tests assert describe the topology move in the same commit.
**Depends on**: Phase 23 (each parallel job restores the shared build artifact), Phase 24 (scoped knowledge job)
**Requirements**: PAR-01, PAR-02, PAR-03, DX-02
**Success Criteria** (what must be TRUE):

  1. The heavy lanes run as sibling parallel jobs — closeout `test:` chain (carries `services: postgres`), `ratchet:`, `knowledge:`, and `connector` + advisory `gallery` tail — each `needs: build`, instead of one serial job.
  2. A single `verify-summary` fan-in job (`needs:` all children, `if: always()`, asserts each child `result == 'success'`) is the only required check; individual parallel/skipped children are never independently required.
  3. The `CI / ci-gate` required-check name is unchanged (`ci.yml`'s `ci-gate` still `needs: [verify, e2e]`), so branch protection needs no edit.
  4. `Scoria.VerificationLanes` byte-order/closeout-order contract tests (`ci_policy_contract_test`, `verification_lanes_test`) stay green — every canonical lane command string remains in its pinned order with one `test:` job carrying Postgres and no `services:` before it.
  5. `docs/MAINTAINERS.md`, `docs/operator_verification.md`, and `README` describe the new parallel topology, and any "docs describe topology" contract test stays green (docs committed in lockstep with the YAML change).

**Plans**: 2 plans
Plans:
**Wave 1**

- [x] 25-01-PLAN.md — split ci-verify.yml into parallel {test, ratchet, knowledge, connector} + verify-summary fan-in; refactor both contract tests to parallel-shape + derived fan-in completeness; fold WR-01/WR-02/WR-03

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 25-02-PLAN.md — update MAINTAINERS.md / operator_verification.md / README to the parallel topology and the docs-topology contract asserts (lockstep)

**UI hint**: no

### Phase 26: Full-suite partition sharding

**Goal**: The full ExUnit suite runs split across a parallel runner matrix on the shared build artifact, collapsing the suite wall-clock while preserving exact coverage.
**Depends on**: Phase 23 (matrix jobs restore the build artifact), Phase 25 (slots into the parallel topology under the fan-in)
**Requirements**: SHARD-01
**Success Criteria** (what must be TRUE):

  1. The full suite runs as `mix test --warnings-as-errors --partitions 4` across a 4-way runner matrix, each exporting `MIX_TEST_PARTITION=${{ matrix.partition }}` (no `config/test.exs` change — it is already partition-aware).
  2. Each shard uses an isolated database keyed by `MIX_TEST_PARTITION`, so shards never collide on DB state.
  3. There is zero coverage loss versus the single-job run — the union of the 4 shards' executed tests equals the prior full-suite test count.
  4. Only the `verify-summary` fan-in is required; individual matrix shard names are never added as required checks.

**Plans**: TBD

### Phase 27: CI determinism & flake elimination

**Goal**: Known CI flakes are eliminated at the root and a deliberate retry-vs-fix policy prevents new flakes from being masked.
**Depends on**: Phase 25 (operates on the new parallel job topology)
**Requirements**: FLAKE-01, FLAKE-02, FLAKE-03
**Success Criteria** (what must be TRUE):

  1. The Postgres service no longer binds a fixed host port — the `-p 55432:5432` mapping in `ci.yml` + `ci-verify.yml` is replaced with a non-conflicting strategy (network alias / dynamic port / resilient bind); the failure reproduced on run `27508317719` does not recur across repeated runs.
  2. The leftover TEMP diagnostic step (DB run-count + server-render dump) is removed from the `e2e` job in `ci.yml`.
  3. A retry-vs-fix policy is documented and applied — no blanket auto-retries; any retry is scoped to a known-infra-transient step only and is visible in logs.
  4. Contract tests and the verification bar remain green/intact — no lane removed or demoted while fixing flakes.

**Plans**: TBD

### Phase 28: DX `mix ci` alias + velocity closeout

**Goal**: A contributor can reproduce the full merge gate locally with one command, and the milestone's headline velocity outcome is proven with real before/after timing.
**Depends on**: Phase 25, Phase 26, Phase 27 (the alias mirrors the final lane set; timing measured against the fully-parallelized pipeline)
**Requirements**: DX-01, VELO-01
**Success Criteria** (what must be TRUE):

  1. A single `mix ci` alias reproduces the merge gate locally (deps lock check, format check, compile WAE, the canonical lane set) and exits non-zero on any gate failure.
  2. On a warm-cache PR run, CI critical-path wall-clock is ≤ ~15 min (target ~12 min), down from the ~77 min baseline — verified via `gh run view <id> --json jobs` before/after timing.
  3. The knowledge job no longer re-runs the full suite (confirmed by log file/line count) and the `build` artifact is restored by every downstream shard (no cold recompiles) — the two largest reclaimed costs are demonstrably gone.
  4. Every gating lane still executes in CI (diffed from job logs, not just YAML) and `ci_policy_contract_test` + `verification_lanes_test` are green — the bar is preserved at milestone close.

**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 23. Cache correctness + build-once job | v3.1 | 1/1 | Complete    | 2026-06-15 |
| 24. Knowledge lane scope fix | v3.1 | 1/1 | Complete    | 2026-06-15 |
| 25. Lane parallelization + topology docs | v3.1 | 1/2 | In Progress|  |
| 26. Full-suite partition sharding | v3.1 | 0/0 | Not started | - |
| 27. CI determinism & flake elimination | v3.1 | 0/0 | Not started | - |
| 28. DX `mix ci` alias + velocity closeout | v3.1 | 0/0 | Not started | - |
| 11. Evaluation engine + seed depth | v3.0 | 5/5 | Complete | 2026-06-04 |
| 12. Design-system component layer | v3.0 | 5/5 | Complete | 2026-06-04 |
| 13. Orientation spine (IA) | v3.0 | 8/8 | Complete | 2026-06-12 |
| 14. Least-iterated screens polish | v3.0 | 6/6 | Complete | 2026-06-12 |
| 15. High-traffic screens + evidence adapters | v3.0 | 5/5 | Complete | 2026-06-13 |
| 16. Motion + responsive + theme parity | v3.0 | 6/6 | Complete | 2026-06-13 |
| 17. Consistency sweep + proof | v3.0 | 3/3 | Complete | 2026-06-13 |
| 18. Pressure-test audit + decision lock | v2.17 | 2/2 | Complete | 2026-06-11 |
| 19. Logo divergence + user choice | v2.17 | 3/3 | Complete | 2026-06-11 |
| 20. Logo convergence — full variant set | v2.17 | 2/2 | Complete | 2026-06-11 |
| 21. Tokens + brand book + standalone HTML | v2.17 | 3/3 | Complete | 2026-06-11 |
| 22. Integration + final quality gate | v2.17 | 2/2 | Complete | 2026-06-11 |
| 08 | v2.16 | — | Complete | 2026-05-30 |
| 09 | v2.16 | — | Complete | 2026-05-30 |
| 10 | v2.16 | — | Complete | 2026-05-30 |
| 10.1 | v2.16 | 1/1 | Complete | 2026-05-30 |

## Previous milestone archive

See `.planning/MILESTONES.md` for full closeout history.
