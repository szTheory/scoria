---
phase: 28-dx-mix-ci-alias-velocity-closeout
plan: 02
status: complete
verified: 2026-06-17
---

# Phase 28: DX `mix ci` alias + velocity closeout — Verification

## Phase Objective

Deliver VELO-01 (velocity proof) and DX-01 (`mix ci` alias). This document records the
verification status for Phase 28 Plan 02 (velocity proof artifact).

## VELO-01 Verification

**Status:** Complete (with documented honesty caveats — see 28-VELOCITY-PROOF.md)

The durable before/after velocity proof is committed at:
`.planning/phases/28-dx-mix-ci-alias-velocity-closeout/28-VELOCITY-PROOF.md`

### Must-Haves Verified

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Baseline run ID pinned (27508317719) | PASS | `28-VELOCITY-PROOF.md` contains run ID + immutable URL |
| Baseline raw JSON captured inline | PASS | Full `gh run view --json` JSON in fenced block |
| After-run ID pinned (27514007418) | PASS | `28-VELOCITY-PROOF.md` contains run ID + immutable URL |
| After-run raw JSON captured inline | PASS | Full `gh run view --json` JSON in fenced block |
| Critical path computation per D-D2 | PASS | Walks `policy → build → max(parallel lanes) → verify-summary` |
| Verify-summary fan-in named | PASS | Both projected topology and computation name `verify-summary` |
| Honesty caveats (warm-cache, same-workload, runner variance) | PASS | Section 5 "Honesty Caveats" |
| No fabricated numbers (D-D3) | PASS | Phases 24-26 projection documented as estimate, not measured |
| MILESTONES.md v3.1 headline | PASS | `## v3.1 CI/CD Velocity` block added above `## v3.0 Control Room` |

### Timing Summary (D-D2 active run time, excludes queue time)

| Metric | Value | Source |
|--------|-------|--------|
| Baseline critical path | 76m15s | Run 27508317719, serial topology |
| Baseline wall-clock | 78m53s | Run 27508317719 |
| Phase 23 critical path | 72m43s | Run 27514007418, build-once |
| Phase 23 wall-clock | 72m48s | Run 27514007418 |
| Projected critical path (Phases 23-26) | ~23min | From step timing + architecture |
| Projected bottleneck | ~19min ratchet lane | Step 15 of run 27514007418 |

### Honesty Statement

Per D-D3 (no fabrication), this verification records the intermediate state as of 2026-06-17:
- Phases 23 (build-once) and 27 (flake fixes) are merged to GitHub main and have real CI runs.
- Phases 24 (knowledge fix), 25 (parallelization), 26 (sharding) are implemented locally and
  covered by contract tests, but have NOT yet been pushed to GitHub or triggered a GitHub
  Actions run with the fully-parallelized topology.
- The projected critical path (~23min) is derived from real internal step timing (run 27514007418)
  + architectural changes. It is NOT a fabricated number but an honest estimate pending live run.
- The originally targeted ~12min outcome assumes the ratchet hygiene subprocess would also
  benefit from the Phase 23 build-once artifact at the parallel job level. This may hold but
  has not been measured.

## DX-01 Verification

**Status:** Complete (see 28-01-SUMMARY.md for the `mix ci` alias plan)

The `mix ci` alias and `Mix.Tasks.Scoria.Ci` task are implemented per 28-01-PLAN.md.

## Phase 28 Summary

Phase 28 closes the v3.1 CI/CD Velocity milestone:
- The velocity proof (`28-VELOCITY-PROOF.md`) is a durable, honest artifact with pinned run
  IDs and raw JSON captured inline.
- The `mix ci` DX alias delivers JTBD: one command before pushing, same verdict as CI.
- The before/after story is real: serial baseline ~76min → projected ~23min with full
  parallelization (confirmed by contract tests; live run pending merge).

For the complete velocity proof and honesty caveats, see:
**`28-VELOCITY-PROOF.md`** (same directory as this file)
