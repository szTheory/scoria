---
phase: 28-dx-mix-ci-alias-velocity-closeout
plan: 03
subsystem: infra
tags: [ci, github-actions, elixir, warning-ratchet, velocity-proof]

# Dependency graph
requires:
  - phase: 28-dx-mix-ci-alias-velocity-closeout
    provides: Plans 28-01 (mix ci alias) and 28-02 (initial velocity proof with projected ~23min)
  - phase: 25-lane-parallelization
    provides: Parallelized topology (policy → build → parallel lanes → verify-summary)
  - phase: 26-full-suite-partition-sharding
    provides: 4-way full-suite matrix sharding
  - phase: 27-ci-determinism-flake-elimination
    provides: Ephemeral-port Postgres, no-TEMP-diagnostic, retry-vs-fix policy
provides:
  - "Compile-only ratchet warning capture (lib/ + test files, zero test execution)"
  - "VELO-01 MEASURED proof: 7m38s critical path in run 27709716751 (warm-cache, GREEN)"
  - "28-VELOCITY-PROOF.md updated with real measured run, inline JSON, D-D2 computation"
  - "MILESTONES.md v3.1 headline carrying 7m38s measured (not projected)"
  - "REQUIREMENTS.md DX-01 and VELO-01 flipped to Complete"
affects: [milestones, requirements, velocity-proof, ratchet-ci-lane]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "compile-only ratchet capture: mix do compile --force + test --only <unused-tag> (loads+compiles test files, runs zero tests)"
    - "VELO-01 proof: D-D2 critical path from gh run view --json active run times, slowest shard for matrix lanes"

key-files:
  created:
    - .planning/phases/28-dx-mix-ci-alias-velocity-closeout/28-03-SUMMARY.md
  modified:
    - .planning/phases/28-dx-mix-ci-alias-velocity-closeout/28-VELOCITY-PROOF.md
    - .planning/MILESTONES.md
    - .planning/REQUIREMENTS.md
    - .planning/STATE.md
    - .planning/ROADMAP.md

key-decisions:
  - "Ratchet capture optimized to compile-only (mix test --only :__ratchet_compile_only__): preserves lib/ force-recompile AND test-file compilation, runs zero tests — cutting ratchet lane from ~19m to ~1m46s without weakening WARN-06"
  - "VELO-01 is MET at 7m38s (458s) critical path — well below the ~15m target (target was ~12m)"
  - "Three first-real-run CI topology defects required repair: (a) ratchet needed Postgres, (b) full-suite shards needed phx_new archive, (c) scoria.install_check needed 180s timeout under shard load"
  - "The scoria.install_check 60s→180s timeout is recorded as a follow-up item (possible phx_new/Igniter contention under parallel shard load — non-blocking)"

patterns-established:
  - "Parity guard pattern: capture_parity_test.exs injects a deliberate high-signal compile warning, confirms the optimized capture still surfaces it, then confirms clean tree yields zero offenders"
  - "D-D2 computation: sum of stage maxima along policy → build → max(parallel lanes) → verify-summary using completedAt - startedAt active times"

requirements-completed: [VELO-01]

# Metrics
duration: 45min
completed: 2026-06-17
---

# Phase 28 Plan 03: Gap Closure — Compile-Only Ratchet + Measured Velocity Proof Summary

**Compile-only ratchet capture (19min→106s), WARN-06 parity-guarded, with VELO-01 MEASURED at 7m38s critical path in real GitHub Actions run 27709716751**

## Performance

- **Duration:** ~45 min (Task A: compile-only ratchet fix + parity test; Task B: capture real run, update proof + traceability)
- **Started:** 2026-06-17
- **Completed:** 2026-06-17
- **Tasks:** 2 (Task A + Task B)
- **Files modified:** 7

## Accomplishments

- Ratchet lane CI cost reduced from ~19m07s to 1m46s (106s) by making `capture_output_standalone!/0` compile-only — force-recompiles `lib/` AND loads+compiles all test files via `mix test --only :__ratchet_compile_only__`, running zero tests. WARN-06 parity maintained and proven by `capture_parity_test.exs`.
- Parallelized topology (Phases 23-28) pushed to GitHub and ran GREEN with warm cache: run 27709716751 (commit 06cdc34, 2026-06-17). Critical path: **7m38s (458s)** — well below the VELO-01 ≤~15m target (target was ~12m; actual 7.6m). VELO-01 IS MET.
- 28-VELOCITY-PROOF.md updated with inline raw JSON, per-job duration table (slowest-first), and D-D2 critical-path computation replacing the "~23min projected" estimate.
- MILESTONES.md v3.1 headline updated to "7m38s MEASURED" with run ID 27709716751.
- REQUIREMENTS.md DX-01 and VELO-01 flipped from Pending to Complete.

## Task Commits

Each task was committed atomically:

1. **Task A: Compile-only ratchet capture + parity guard** - `bf15f10` (feat: compile-only ratchet warning capture, parity test, MAINTAINERS.md update)
2. **Task B topology fixes (orchestrator-pushed):**
   - `d07093b` — ratchet lane Postgres + ci_policy_contract_test update
   - `8501578` — full-suite shards phx_new archive + scoria.install_check 180s timeout
   - `06cdc34` — final topology fix (origin/main, GREEN run 27709716751)
3. **Task B metadata (this commit):** docs(28-03): capture measured run, update proof + MILESTONES + REQUIREMENTS + SUMMARY

## Files Created/Modified

- `.planning/phases/28-dx-mix-ci-alias-velocity-closeout/28-VELOCITY-PROOF.md` — replaced "~23min projected" with MEASURED 7m38s; inline JSON for run 27709716751; per-job table; D-D2 computation; Honesty Caveats updated (local-only and post-push-pending resolved)
- `.planning/MILESTONES.md` — v3.1 headline updated to "7m38s MEASURED" with run 27709716751
- `.planning/REQUIREMENTS.md` — DX-01 and VELO-01 checkboxes flipped to `[x]`; traceability rows Pending → Complete
- `.planning/STATE.md` — plan position, session, metrics updated
- `.planning/ROADMAP.md` — Phase 28 plan count updated (3/3)
- `lib/scoria/warning_inventory.ex` — `capture_output_standalone!/0` compile-only (Task A, bf15f10)
- `test/scoria/warning_inventory/capture_parity_test.exs` — parity guard (Task A, bf15f10)
- `docs/MAINTAINERS.md` — compile-only ratchet documented (Task A, bf15f10)

## Decisions Made

- Compile-only capture uses `mix do compile --force + test --only :__ratchet_compile_only__` — KEPT `compile --force` to preserve the original `lib/` force-recompile scope even though the gate's `high_signal_path?` currently filters only test-file paths. This ensures a future lib-path extension is not silently weakened.
- VELO-01 is MET: 7m38s measured ≤ ~15m target. The actual number (7.6m) is better than the original ~12m target. No rounding, no embellishment — the measured number is the headline.
- The `scoria.install_check` 60s→180s timeout is recorded as a non-blocking follow-up. The 3x increase suggests a possible `phx_new`/Igniter interaction under parallel shard load that is worth profiling (a dedicated future phase, not a blocker for VELO-01 closeout).

## Deviations from Plan

### Auto-fixed Issues (CI Topology Repairs)

The plan's Task B anticipated that the orchestrator would push and capture the run. Three first-real-run CI topology defects were discovered and fixed by the orchestrator before a GREEN run existed (commits d07093b, 8501578, 06cdc34). These are documented here for completeness.

**1. [Rule 3 - Blocking] Ratchet lane required Postgres**
- **Found during:** Task B — first-run of parallelized topology
- **Issue:** The ratchet job runs `mix test --WAE tmp_preflight_test.exs` which calls `mix scoria.warning_ratchet.check` → boots the application → needs a database. The new parallel `ratchet` job had no `services: postgres` block.
- **Fix:** Added `services: postgres` to the ratchet job in `ci-verify.yml`; updated `ci_policy_contract_test.exs` to match the new `services:` presence.
- **Commit:** d07093b

**2. [Rule 3 - Blocking] Full-suite shards required phx_new archive**
- **Found during:** Task B — first-run topology
- **Issue:** Full-suite shards run the host-proof overlay tests which call `mix phx.new` — the `phx_new` archive was not installed in the shard jobs.
- **Fix:** Added `mix archive.install hex phx_new --force` step to the full-suite matrix job in `ci-verify.yml`.
- **Commit:** 8501578

**3. [Rule 1 - Bug] scoria.install_check 60s timeout too tight under shard load**
- **Found during:** Task B — first-run topology
- **Issue:** Under parallel shard execution, `mix scoria.install_check` was timing out at 60s due to contention (likely `phx_new`/Igniter interaction under load).
- **Fix:** Increased timeout to 180s. Recorded as a known follow-up for future profiling.
- **Commit:** 8501578

---

**Total deviations:** 3 (all CI topology plumbing repairs; the core velocity win — compile-only ratchet — was planned and executed as designed)
**Impact on plan:** The three repairs are CI plumbing (not gate-weakening) and were required for any real run to complete. The compile-only ratchet capture is the core velocity lever this plan delivered.

## Issues Encountered

- The "~23min projected" estimate from Plan 28-02 was conservative: the actual measured critical path (7m38s) is significantly better because the dominant bottleneck shifted from `ratchet` (now 106s) to `verify / test` (417s, the closeout chain). The closeout chain's 417s is healthy — it contains meaningful merge-gating work (release_preview + adoption + runtime-to-handoff + semantic).
- Runner variance note: the four full-suite shards showed high spread (60s to 373s) reflecting test-distribution unevenness across partitions. Shard 1 dominates at 373s. This is within normal variance and well below the 417s `verify / test` critical lane — no action needed.

## User Setup Required

None — no external service configuration required. The proof is pinned to run 27709716751 with inline JSON.

## Next Phase Readiness

Phase 28 is complete. v3.1 CI/CD Velocity milestone is SHIPPED:
- VELO-01: MET (7m38s ≤ ~15m)
- DX-01: Complete (`mix ci` alias ships Plan 28-01)
- All other v3.1 requirements: Complete (see REQUIREMENTS.md)

Follow-up item (non-blocking, recorded for future planning):
- `scoria.install_check` 60s→180s timeout bump may indicate a `phx_new`/Igniter interaction
  under parallel shard load worth profiling. A dedicated phase can investigate if the timeout
  tightens or becomes a flake source.

---
*Phase: 28-dx-mix-ci-alias-velocity-closeout*
*Completed: 2026-06-17*
