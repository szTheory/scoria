# Phase 25: Lane parallelization + topology docs - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-15
**Phase:** 25-lane-parallelization-topology-docs
**Mode:** advisor (`minimal_decisive` tier — one decisive locked recommendation per area)
**Areas discussed:** Contract-test adaptation, Anti-false-green fan-in, Per-job setup sharing, Docs topology depth (DX-02)

---

## Contract-test adaptation (D-01)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Byte-order preservation | Lay sibling jobs in canonical file order so existing `index_of` byte-order assertions pass with near-zero test changes; "stays green" satisfied literally | |
| B — Topology-aware refactor | Add `job_blocks/1` job-map parser; KEEP intra-`test:`-job step-order asserts (real, sequential, shared DB); REWRITE cross-job byte-order asserts into parallel-shape asserts (each top-level job `needs: build`) | ✓ |

**User's choice:** Deep-dive selected; recommendation B locked.
**Notes:** "Stays green" (SC#4) read as *suite green AND order pinned where order is real*, not byte-accident preservation. Option A would cry-wolf RED on safe parallel-job reorders (tech debt, against DNA). ~4 assertions become cross-job byte-accidents and get rewritten; closeout-chain + semantic + full-suite intra-step order kept. Reuses one new `job_blocks/1` parser shared with D-02.

---

## Anti-false-green fan-in (D-02)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Hand-maintained + reviewed | Write `verify-summary` needs[] + per-child checks by hand; rely on code review | |
| B — Derived contract test + per-child bash | Derived test catches needs[] omission, but per-child named bash still drifts | |
| C — Derived test + name-agnostic aggregation | Derived fan-in-completeness test + `join(needs.*.result)` loop (skipped=fail) that auto-covers new lanes | ✓ |

**User's choice:** Deep-dive selected; recommendation C locked.
**Notes:** GitHub semantics confirmed — an unwired *failing* lane still fails the reusable-workflow result → `ci-gate`; genuine residual risk is a *skipped* lane, so `skipped = fail`. Name-agnostic aggregation means a lane added to `needs:` is auto-checked (no per-child bash edit — the very manual-vigilance gap being closed). Derived test asserts every `needs: build` job ∈ `verify-summary.needs` (subset + non-empty guard), mirroring Phase 24 D-03.

---

## Per-job setup sharing (D-03)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Inline duplication | Copy preamble + DB-prep into each Postgres-needing job; zero new abstraction; contract greps keep working | ✓ |
| B — Composite action(s) | Extract setup/DB-prep into `.github/actions/`; DRY but breaks literal-string greps + `services:` can't live in a composite | |
| C — Hybrid | Composite preamble only, DB-prep inline | |

**User's choice:** Deep-dive selected; recommendation A locked.
**Notes:** Decisive blockers against extraction: `services:` is job-level only (composite half-measure); contract tests grep `ci-verify.yml` for literal DB-prep strings (relocating breaks them); repo has zero composite actions (new-pattern cost unjustified for ~3 jobs). DB-prep needed by test/knowledge/connector; `ratchet` (tmp_preflight WAE) flagged for planner to verify Ecto-need — if none, no `services:`/DB-prep.

---

## Docs topology depth — DX-02 (D-04)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Prose-only | Update gate-map paragraphs, keep existing assertions passing | |
| B — Prose + structure | Add topology diagram + job→command table | |
| C — Prose + structure + new contract assertion | Also assert docs NAME each parallel lane + `verify-summary` (docs-as-contract) | ✓ |

**User's choice:** Deep-dive selected; recommendation C locked.
**Notes:** Phase is literally named "…topology docs" and repo already enforces docs-as-contract, so extra assertions are on-DNA, not over-engineering. Job→local-command table is the highest-value maintainer artifact post-parallelization. Rename the now-false `**Test job closeout**` heading; update the topology contract test to the new heading + lane-naming asserts. `operator_verification.md` + README updated in lockstep.

---

## Folded Todo

| Todo | Decision | Notes |
|------|----------|-------|
| WR-01 — `ci-policy-job-cache-key-mislabel.md` | **Fold in opportunistically** | Policy job compiles under default `MIX_ENV=dev` but caches under `-test-mix-`. Fix while YAML is open: recommended set `MIX_ENV: test` on policy (matches key, warms build cache); alt relabel to `-dev-mix-`. Must keep cache-key contract asserts green. |
| `docker-dx-fleet-hardening.md` | Reviewed, **not folded** | Weak match (0.4, keyword "phase"); unrelated Docker DX track. |

## Claude's Discretion
- `job_blocks/1` regex; whether new asserts live in `ci_policy_contract_test.exs` or a sibling file if it grows.
- Exact YAML file ordering of parallel sibling jobs (no longer load-bearing once D-01 asserts shape, not byte-order); `verify-summary` step phrasing.
- WR-01 fix mechanism (set `MIX_ENV: test` vs relabel), subject to the cache-key contract.
- Whether the `connector` gallery tail is a step inside `connector:` vs a tiny separate job (default: step; it is advisory).

## Deferred Ideas
- Full-suite `--partitions 4` sharding → Phase 26 (slots under this fan-in).
- Fixed-host-port Postgres flake / TEMP e2e diagnostic / retry policy → Phase 27.
- `mix ci` alias + velocity closeout → Phase 28.
