---
phase: 28-dx-mix-ci-alias-velocity-closeout
plan: "02"
subsystem: planning/velocity-proof
tags: [velocity, ci, proof, milestones, documentation]
requirements-completed: [VELO-01]

dependency-graph:
  requires:
    - "27-01 (CI determinism — baseline run 27508317719 documented there)"
    - "26-01 (full-suite sharding — provides the parallel topology architecture)"
    - "25-01 (lane parallelization — provides verify-summary fan-in)"
    - "24-01 (knowledge lane fix — provides Phase 24 timing data)"
    - "23-01 (build-once job — after-run 27514007418 uses this)"
  provides:
    - "28-VELOCITY-PROOF.md: durable before/after timing proof with inline raw JSON"
    - "MILESTONES.md: v3.1 CI/CD Velocity durable headline block"
    - "28-VERIFICATION.md: phase verification with back-reference to proof"
  affects:
    - ".planning/MILESTONES.md (v3.1 block added)"

tech-stack:
  added: []
  patterns:
    - "gh CLI capture: gh run view <id> --json databaseId,headSha,createdAt,jobs,workflowName,url"
    - "D-D2 critical path: sum of stage maxima along dependency chain (active run time, not billable minutes)"
    - "Inline JSON capture for retention-purge durability"

key-files:
  created:
    - ".planning/phases/28-dx-mix-ci-alias-velocity-closeout/28-VELOCITY-PROOF.md"
    - ".planning/phases/28-dx-mix-ci-alias-velocity-closeout/28-VERIFICATION.md"
  modified:
    - ".planning/MILESTONES.md"

decisions:
  - "Used run 27514007418 as best available after-run (Phase 23 build-once); Phases 24-26 are local-only with no GitHub Actions run yet"
  - "Projected critical path ~23min from step timing + architecture; not fabricated (D-D3 compliance)"
  - "Honest caveats documented: warm-cache, same-workload, runner variance, Phases 24-26 pending push"
  - "Ratchet lane (19m7s) is the remaining bottleneck after Phase 24 knowledge fix and Phase 26 sharding"

metrics:
  duration: "~20 minutes"
  completed: "2026-06-17"
  tasks-completed: 2
  tasks-total: 2
  files-created: 2
  files-modified: 1
---

# Phase 28 Plan 02: Velocity Proof Summary

**One-liner:** Durable velocity proof with inline raw JSON from GitHub Actions runs (27508317719 baseline, 27514007418 after), D-D2 critical-path computation (~76min serial → ~23min projected), v3.1 MILESTONES.md headline, and honest caveats for local-only Phases 24-26.

## What Was Built

VELO-01 satisfied: the v3.1 CI/CD Velocity milestone's timing outcome is recorded as a durable,
honest artifact with:

1. **`28-VELOCITY-PROOF.md`** (new, 230 lines): Pinned before/after run IDs with raw
   `gh run view --json` JSON captured inline (retention-purge durable). Both the baseline
   run (27508317719, serial topology, ~76min critical path) and the best available after-run
   (27514007418, Phase 23 build-once, ~73min) have their full JSON captured. The projected
   critical path for the fully-parallelized Phases 23-26 topology is computed from real step
   timing (~23min, bottlenecked by the 19min ratchet hygiene lane). Honesty caveats document
   that Phases 24-26 are local-only and the live parallelized run is pending merge.

2. **`MILESTONES.md` v3.1 block** (new block above v3.0): Carries the durable headline with
   before/after run IDs, phases completed, timeline, and delivered summary. Survives milestone
   archive.

3. **`28-VERIFICATION.md`** (new): Records phase verification status and back-references
   `28-VELOCITY-PROOF.md` as the durable timing source.

## Critical Path Computation (D-D2)

**Before** (run 27508317719, serial topology):
- `policy (0m19s) → test (75m54s) → ci-gate (0m02s)` = **76m15s ≈ 76min**
- Wall-clock: 78m53s ≈ 79min

**After** (run 27514007418, Phase 23 build-once):
- `policy (2m59s) + build (0m19s) → test (69m23s) → ci-gate (0m02s)` = **72m43s ≈ 73min**
- Wall-clock: 72m48s ≈ 73min

**Projected** (Phases 23-26 fully parallelized, from step timing):
- `policy (2m59s) + build (0m19s) + max(test 6m30s, ratchet 19m07s, knowledge ~3m, full-suite/4 5m24s, connector 20s) + verify-summary (~30s)`
- Bottleneck: ratchet lane (19m07s)
- **Total: ~23min** (pending live GitHub Actions run)

## Deviations from Plan

**1. [Rule 1 - Honesty] After-run is Phase 23 only, not fully-parallelized**
- **Found during:** Task 1 — attempting to find a green run of the fully-parallelized pipeline
- **Issue:** Phases 24-26 (knowledge fix, lane parallelization, full-suite sharding) are
  implemented locally but have not been pushed to GitHub remote. The latest green CI run
  (27514007418) only reflects Phase 23 (build-once job).
- **Action:** Used 27514007418 as the after-run (best available), computed projected critical
  path from internal step timing, explicitly documented the gap vs. original ~12min target.
- **Impact:** Proof is honest — ~23min projected vs. ~12min target. The ratchet lane (19m7s)
  is the remaining bottleneck after parallelization.

**2. [Rule 1 - Honesty] Projected ~23min not ~12min as originally targeted**
- **Found during:** Task 1 critical path computation
- **Issue:** SEED-003 estimated two "fixable root causes" totaling ~45min. After Phase 24
  (knowledge fix, -22min) and Phase 26 (sharding, ~-16min from parallel lanes), the projected
  critical path is still ~23min because the ratchet lane dominates at ~19min.
- **Action:** Documented honestly in 28-VELOCITY-PROOF.md. The ~12min target may still be
  achievable if the ratchet subprocess also benefits from the Phase 23 build artifact when run
  as a parallel job (not yet measured).
- **Impact:** No fabricated numbers. The `must_haves` accept either the real after-run data
  OR an honest projection — the doc provides both.

## Self-Check

Artifacts exist:
- `28-VELOCITY-PROOF.md`: FOUND (commit 6c39ac8)
- `MILESTONES.md`: FOUND (commit 43b15a5)
- `28-VERIFICATION.md`: FOUND (commit 43b15a5)

Commits exist:
- 6c39ac8: docs(28-02): capture before/after run JSON and create velocity proof (VELO-01)
- 43b15a5: docs(28-02): add v3.1 headline to MILESTONES.md and create 28-VERIFICATION.md

Automated checks passed:
- `grep -E '27508317719|baseline run unavailable'` PASS
- `grep -E 'actions/runs/[0-9]+'` PASS
- `grep 'verify-summary'` PASS
- `grep -i 'warm-cache'` PASS
- `grep -E '"(jobs|databaseId)"'` PASS
- MILESTONE_OK (v3.1 above v3.0, 77m in MILESTONES, 28-VELOCITY-PROOF.md in VERIFICATION)

## Self-Check: PASSED
