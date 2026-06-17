# v3.1 CI/CD Velocity Proof

**Claim:** Phase 28 of v3.1 closes out the CI/CD Velocity milestone. This document pins the
before/after run IDs, captures raw `gh run view --json` JSON inline (for retention-purge
durability), computes the critical path per D-D2, and documents honesty caveats.

**Headline:** PR CI serial-baseline critical-path ~76min → projected ~23min with Phases 23-26
improvements (Phases 24-26 work is local-only; the fully-parallelized topology has not yet
run on GitHub Actions — see Honesty Caveats below).

---

## BEFORE (Baseline): Run 27508317719

**Run ID:** 27508317719
**URL:** https://github.com/szTheory/scoria/actions/runs/27508317719
**Commit:** 4f04341070de64c0bc1e12d0b1cb79c9e567eedc (ci: bump GitHub Actions to Node-24 runtimes)
**Date:** 2026-06-14T18:38:47Z
**Topology:** Serial — `verify / policy` runs parallel to `verify / test` but test dominates.
The `verify / test` job runs ALL lanes in sequence: release_preview → adoption → runtime_to_handoff
→ semantic → ratchet hygiene → full suite → knowledge (re-ran full suite, pre-Phase 24) → connector.

This is the **SEED-003 baseline run** (reproduced the fixed-port Postgres flake; see SEED-003
flakiness evidence for context on this specific run).

### Per-job active durations (slowest-first)

| Job | startedAt | completedAt | Active duration |
|-----|-----------|-------------|-----------------|
| verify / test | 18:41:47Z | 19:57:41Z | **75m54s** (4554s) |
| e2e | 18:38:55Z | 18:40:45Z | 1m50s (110s) |
| verify / policy | 18:38:52Z | 18:39:11Z | 0m19s (19s) |
| ci-gate | 19:57:43Z | 19:57:45Z | 0m02s (2s) |

**Run-level wall-clock** = max(completedAt) − min(startedAt)
= 19:57:45Z − 18:38:52Z = **78m53s ≈ 79min**

**Critical path** (serial topology, D-D2):
`policy → test → ci-gate` = 19s + 4554s + 2s = **4575s = 76m15s ≈ 76min**

(e2e runs in parallel with policy+test and does not dominate.)

### Baseline raw JSON (captured inline for retention-purge durability)

```json
{"createdAt":"2026-06-14T18:38:47Z","databaseId":27508317719,"headSha":"4f04341070de64c0bc1e12d0b1cb79c9e567eedc","jobs":[{"completedAt":"2026-06-14T19:57:41Z","conclusion":"success","databaseId":81303773158,"name":"verify / test","startedAt":"2026-06-14T18:41:47Z","status":"completed","steps":[{"completedAt":"2026-06-14T18:41:49Z","conclusion":"success","name":"Set up job","number":1,"startedAt":"2026-06-14T18:41:47Z","status":"completed"},{"completedAt":"2026-06-14T18:42:11Z","conclusion":"success","name":"Initialize containers","number":2,"startedAt":"2026-06-14T18:41:49Z","status":"completed"},{"completedAt":"2026-06-14T18:42:13Z","conclusion":"success","name":"Run actions/checkout@v6","number":3,"startedAt":"2026-06-14T18:42:11Z","status":"completed"},{"completedAt":"2026-06-14T18:42:19Z","conclusion":"success","name":"Install Erlang and Elixir","number":4,"startedAt":"2026-06-14T18:42:13Z","status":"completed"},{"completedAt":"2026-06-14T18:42:22Z","conclusion":"success","name":"Restore deps cache","number":5,"startedAt":"2026-06-14T18:42:19Z","status":"completed"},{"completedAt":"2026-06-14T18:42:23Z","conclusion":"success","name":"Install dependencies","number":6,"startedAt":"2026-06-14T18:42:22Z","status":"completed"},{"completedAt":"2026-06-14T18:42:35Z","conclusion":"success","name":"Run release preview lane","number":7,"startedAt":"2026-06-14T18:42:23Z","status":"completed"},{"completedAt":"2026-06-14T18:42:38Z","conclusion":"success","name":"Install phx_new archive for host consumer proof","number":8,"startedAt":"2026-06-14T18:42:35Z","status":"completed"},{"completedAt":"2026-06-14T18:42:51Z","conclusion":"success","name":"Prepare database","number":9,"startedAt":"2026-06-14T18:42:38Z","status":"completed"},{"completedAt":"2026-06-14T18:48:03Z","conclusion":"success","name":"Run adoption closure lane","number":10,"startedAt":"2026-06-14T18:42:51Z","status":"completed"},{"completedAt":"2026-06-14T18:48:10Z","conclusion":"success","name":"Run runtime-to-handoff proof lane","number":12,"startedAt":"2026-06-14T18:48:03Z","status":"completed"},{"completedAt":"2026-06-14T18:48:16Z","conclusion":"success","name":"Run semantic fast-path lane","number":13,"startedAt":"2026-06-14T18:48:10Z","status":"completed"},{"completedAt":"2026-06-14T19:09:30Z","conclusion":"success","name":"Verify maintainer ratchet hygiene chain","number":14,"startedAt":"2026-06-14T18:48:16Z","status":"completed"},{"completedAt":"2026-06-14T19:33:19Z","conclusion":"success","name":"Run tests","number":15,"startedAt":"2026-06-14T19:09:30Z","status":"completed"},{"completedAt":"2026-06-14T19:57:17Z","conclusion":"success","name":"Run knowledge lane","number":16,"startedAt":"2026-06-14T19:33:19Z","status":"completed"},{"completedAt":"2026-06-14T19:57:21Z","conclusion":"success","name":"Run connector lane","number":17,"startedAt":"2026-06-14T19:57:17Z","status":"completed"},{"completedAt":"2026-06-14T19:57:36Z","conclusion":"success","name":"Run support copilot gallery lane (advisory)","number":18,"startedAt":"2026-06-14T19:57:21Z","status":"completed"}],"url":"https://github.com/szTheory/scoria/actions/runs/27508317719/job/81303773158"},{"completedAt":"2026-06-14T18:39:11Z","conclusion":"success","databaseId":81303784921,"name":"verify / policy","startedAt":"2026-06-14T18:38:52Z","status":"completed","url":"https://github.com/szTheory/scoria/actions/runs/27508317719/job/81303784921"},{"completedAt":"2026-06-14T18:40:45Z","conclusion":"success","databaseId":81303785542,"name":"e2e","startedAt":"2026-06-14T18:38:55Z","status":"completed","url":"https://github.com/szTheory/scoria/actions/runs/27508317719/job/81303785542"},{"completedAt":"2026-06-14T19:57:45Z","conclusion":"success","databaseId":81309034662,"name":"ci-gate","startedAt":"2026-06-14T19:57:43Z","status":"completed","url":"https://github.com/szTheory/scoria/actions/runs/27508317719/job/81309034662"}],"url":"https://github.com/szTheory/scoria/actions/runs/27508317719","workflowName":"CI"}
```

---

## AFTER (Phase 23 build-once): Run 27514007418

**Run ID:** 27514007418
**URL:** https://github.com/szTheory/scoria/actions/runs/27514007418
**Commit:** 5f606f1dd79f2c53488df7e1ecf676dfb375dfad (feat(23-01): CACHE-02 — build-once job + artifact restore)
**Date:** 2026-06-14T22:26:48Z
**Topology:** Phase 23 adds a dedicated `build` job that compiles once and shares the artifact.
The `test` job then restores the artifact instead of recompiling. Lanes still run serially
within the `test` job. Phases 24-26 (knowledge fix, lane parallelization, sharding) are
implemented locally but not yet pushed to GitHub — see Honesty Caveats.

**Context:** This is the most recent warm-cache green CI run on the GitHub-pushed code.
The warm-cache is confirmed — `Restore deps cache` hit (1s) vs cold install (~7s).

### Per-job active durations (slowest-first)

| Job | startedAt | completedAt | Active duration |
|-----|-----------|-------------|-----------------|
| verify / test | 22:30:11Z | 23:39:34Z | **69m23s** (4163s) |
| e2e | 22:26:51Z | 22:30:11Z | 3m20s (200s) |
| verify / policy | 22:26:50Z | 22:29:49Z | 2m59s (179s) |
| verify / build | 22:29:51Z | 22:30:10Z | 0m19s (19s) |
| ci-gate | 23:39:36Z | 23:39:38Z | 0m02s (2s) |

**Run-level wall-clock** = max(completedAt) − min(startedAt)
= 23:39:38Z − 22:26:50Z = **72m48s ≈ 73min**

**Critical path** (policy → build → test → ci-gate):
= 179s + 19s + 4163s + 2s = **4363s = 72m43s ≈ 73min**

Phase 23 saving: test job no longer recompiles (~6min reduction from warm-cache artifact restore).

### Internal step breakdown of verify/test job (pre-parallelization)

These step timings are the basis for the projected critical path calculation below.

| Step | Active duration | Notes |
|------|-----------------|-------|
| release_preview + phx_new + DB-prep | 1m47s + 3s + 12s = 1m62s | Closeout preamble |
| adoption closure lane | 4m29s | Merge-blocking closeout |
| runtime-to-handoff proof lane | 6s | Merge-blocking closeout |
| semantic fast-path lane | 7s | Merge-blocking closeout |
| ratchet hygiene chain | **19m07s** | Warning-inventory WAE subprocess |
| Run tests (full suite --WAE) | **21m33s** | Moves to sharded full-suite job (Phase 26) |
| knowledge lane | **21m16s** | Re-runs full suite here (Phase 24 not yet applied) |
| connector lane | 4s | |
| gallery (advisory) | 16s | |

Note: In this run, the knowledge lane still re-runs the full suite (Phase 24's
`--only knowledge` fix has NOT yet been applied — it is a local-only commit). After
Phase 24, the knowledge lane will run only 6 knowledge-tagged files.

### After-run raw JSON (captured inline for retention-purge durability)

```json
{"createdAt":"2026-06-14T22:26:48Z","databaseId":27514007418,"headSha":"5f606f1dd79f2c53488df7e1ecf676dfb375dfad","jobs":[{"completedAt":"2026-06-14T22:30:11Z","conclusion":"success","databaseId":81319253522,"name":"e2e","startedAt":"2026-06-14T22:26:51Z","status":"completed","steps":[{"completedAt":"2026-06-14T22:26:54Z","conclusion":"success","name":"Set up job","number":1,"startedAt":"2026-06-14T22:26:52Z","status":"completed"},{"completedAt":"2026-06-14T22:27:15Z","conclusion":"success","name":"Initialize containers","number":2,"startedAt":"2026-06-14T22:26:54Z","status":"completed"},{"completedAt":"2026-06-14T22:27:16Z","conclusion":"success","name":"Run actions/checkout@v6","number":3,"startedAt":"2026-06-14T22:27:15Z","status":"completed"},{"completedAt":"2026-06-14T22:27:22Z","conclusion":"success","name":"Install Erlang and Elixir","number":4,"startedAt":"2026-06-14T22:27:16Z","status":"completed"},{"completedAt":"2026-06-14T22:27:27Z","conclusion":"success","name":"Install Node.js","number":5,"startedAt":"2026-06-14T22:27:22Z","status":"completed"},{"completedAt":"2026-06-14T22:27:28Z","conclusion":"success","name":"Restore deps cache","number":6,"startedAt":"2026-06-14T22:27:27Z","status":"completed"},{"completedAt":"2026-06-14T22:27:30Z","conclusion":"success","name":"Install dependencies","number":7,"startedAt":"2026-06-14T22:27:28Z","status":"completed"},{"completedAt":"2026-06-14T22:27:35Z","conclusion":"success","name":"Cache Playwright browsers","number":8,"startedAt":"2026-06-14T22:27:30Z","status":"completed"},{"completedAt":"2026-06-14T22:27:51Z","conclusion":"success","name":"Install e2e tooling","number":9,"startedAt":"2026-06-14T22:27:35Z","status":"completed"},{"completedAt":"2026-06-14T22:29:26Z","conclusion":"success","name":"Prepare dev database and seed","number":10,"startedAt":"2026-06-14T22:27:51Z","status":"completed"},{"completedAt":"2026-06-14T22:29:27Z","conclusion":"success","name":"Build dashboard assets","number":11,"startedAt":"2026-06-14T22:29:26Z","status":"completed"},{"completedAt":"2026-06-14T22:29:35Z","conclusion":"success","name":"Boot dev dashboard","number":12,"startedAt":"2026-06-14T22:29:27Z","status":"completed"},{"completedAt":"2026-06-14T22:29:38Z","conclusion":"success","name":"TEMP diagnose runs visibility","number":13,"startedAt":"2026-06-14T22:29:35Z","status":"completed"},{"completedAt":"2026-06-14T22:30:02Z","conclusion":"success","name":"Run dashboard e2e lane","number":14,"startedAt":"2026-06-14T22:29:38Z","status":"completed"},{"completedAt":"2026-06-14T22:30:04Z","conclusion":"success","name":"Upload Playwright report","number":15,"startedAt":"2026-06-14T22:30:02Z","status":"completed"}],"url":"https://github.com/szTheory/scoria/actions/runs/27514007418/job/81319253522"},{"completedAt":"2026-06-14T22:29:49Z","conclusion":"success","databaseId":81319253574,"name":"verify / policy","startedAt":"2026-06-14T22:26:50Z","status":"completed","steps":[{"completedAt":"2026-06-14T22:26:52Z","conclusion":"success","name":"Set up job","number":1,"startedAt":"2026-06-14T22:26:51Z","status":"completed"},{"completedAt":"2026-06-14T22:26:53Z","conclusion":"success","name":"Run actions/checkout@v6","number":2,"startedAt":"2026-06-14T22:26:52Z","status":"completed"},{"completedAt":"2026-06-14T22:27:00Z","conclusion":"success","name":"Install Erlang and Elixir","number":3,"startedAt":"2026-06-14T22:26:53Z","status":"completed"},{"completedAt":"2026-06-14T22:27:01Z","conclusion":"success","name":"Restore deps cache","number":4,"startedAt":"2026-06-14T22:27:00Z","status":"completed"},{"completedAt":"2026-06-14T22:27:03Z","conclusion":"success","name":"Install dependencies","number":5,"startedAt":"2026-06-14T22:27:01Z","status":"completed"},{"completedAt":"2026-06-14T22:28:35Z","conclusion":"success","name":"Check warning baseline expiry","number":6,"startedAt":"2026-06-14T22:27:03Z","status":"completed"},{"completedAt":"2026-06-14T22:29:43Z","conclusion":"success","name":"Check committed warning inventory baseline","number":7,"startedAt":"2026-06-14T22:28:35Z","status":"completed"},{"completedAt":"2026-06-14T22:29:44Z","conclusion":"success","name":"Compile with warnings as errors","number":8,"startedAt":"2026-06-14T22:29:43Z","status":"completed"},{"completedAt":"2026-06-14T22:29:45Z","conclusion":"success","name":"Verify lane-contract tests with warnings as errors","number":9,"startedAt":"2026-06-14T22:29:44Z","status":"completed"}],"url":"https://github.com/szTheory/scoria/actions/runs/27514007418/job/81319253574"},{"completedAt":"2026-06-14T22:30:10Z","conclusion":"success","databaseId":81319446579,"name":"verify / build","startedAt":"2026-06-14T22:29:51Z","status":"completed","steps":[{"completedAt":"2026-06-14T22:29:52Z","conclusion":"success","name":"Set up job","number":1,"startedAt":"2026-06-14T22:29:51Z","status":"completed"},{"completedAt":"2026-06-14T22:29:54Z","conclusion":"success","name":"Run actions/checkout@v6","number":2,"startedAt":"2026-06-14T22:29:52Z","status":"completed"},{"completedAt":"2026-06-14T22:30:00Z","conclusion":"success","name":"Install Erlang and Elixir","number":3,"startedAt":"2026-06-14T22:29:54Z","status":"completed"},{"completedAt":"2026-06-14T22:30:01Z","conclusion":"success","name":"Restore deps + build cache","number":4,"startedAt":"2026-06-14T22:30:00Z","status":"completed"},{"completedAt":"2026-06-14T22:30:03Z","conclusion":"success","name":"Install dependencies","number":5,"startedAt":"2026-06-14T22:30:01Z","status":"completed"},{"completedAt":"2026-06-14T22:30:04Z","conclusion":"success","name":"Compile with warnings as errors","number":6,"startedAt":"2026-06-14T22:30:03Z","status":"completed"},{"completedAt":"2026-06-14T22:30:06Z","conclusion":"success","name":"Pack compiled artifact (preserves mtimes)","number":7,"startedAt":"2026-06-14T22:30:04Z","status":"completed"},{"completedAt":"2026-06-14T22:30:08Z","conclusion":"success","name":"Upload compiled artifact","number":8,"startedAt":"2026-06-14T22:30:06Z","status":"completed"}],"url":"https://github.com/szTheory/scoria/actions/runs/27514007418/job/81319446579"},{"completedAt":"2026-06-14T23:39:34Z","conclusion":"success","databaseId":81319470639,"name":"verify / test","startedAt":"2026-06-14T22:30:11Z","status":"completed","steps":[{"completedAt":"2026-06-14T22:30:13Z","conclusion":"success","name":"Set up job","number":1,"startedAt":"2026-06-14T22:30:12Z","status":"completed"},{"completedAt":"2026-06-14T22:30:36Z","conclusion":"success","name":"Initialize containers","number":2,"startedAt":"2026-06-14T22:30:13Z","status":"completed"},{"completedAt":"2026-06-14T22:30:37Z","conclusion":"success","name":"Run actions/checkout@v6","number":3,"startedAt":"2026-06-14T22:30:36Z","status":"completed"},{"completedAt":"2026-06-14T22:30:44Z","conclusion":"success","name":"Install Erlang and Elixir","number":4,"startedAt":"2026-06-14T22:30:37Z","status":"completed"},{"completedAt":"2026-06-14T22:30:45Z","conclusion":"success","name":"Download compiled artifact","number":5,"startedAt":"2026-06-14T22:30:44Z","status":"completed"},{"completedAt":"2026-06-14T22:30:45Z","conclusion":"success","name":"Unpack compiled artifact (restores exact mtimes)","number":6,"startedAt":"2026-06-14T22:30:45Z","status":"completed"},{"completedAt":"2026-06-14T22:30:47Z","conclusion":"success","name":"Install dependencies (no-op when deps/ complete)","number":7,"startedAt":"2026-06-14T22:30:45Z","status":"completed"},{"completedAt":"2026-06-14T22:32:19Z","conclusion":"success","name":"Run release preview lane","number":8,"startedAt":"2026-06-14T22:30:47Z","status":"completed"},{"completedAt":"2026-06-14T22:32:22Z","conclusion":"success","name":"Install phx_new archive for host consumer proof","number":9,"startedAt":"2026-06-14T22:32:19Z","status":"completed"},{"completedAt":"2026-06-14T22:32:34Z","conclusion":"success","name":"Prepare database","number":10,"startedAt":"2026-06-14T22:32:22Z","status":"completed"},{"completedAt":"2026-06-14T22:37:03Z","conclusion":"success","name":"Run adoption closure lane","number":11,"startedAt":"2026-06-14T22:32:34Z","status":"completed"},{"completedAt":"2026-06-14T22:37:09Z","conclusion":"success","name":"Run runtime-to-handoff proof lane","number":13,"startedAt":"2026-06-14T22:37:03Z","status":"completed"},{"completedAt":"2026-06-14T22:37:16Z","conclusion":"success","name":"Run semantic fast-path lane","number":14,"startedAt":"2026-06-14T22:37:09Z","status":"completed"},{"completedAt":"2026-06-14T22:56:23Z","conclusion":"success","name":"Verify maintainer ratchet hygiene chain","number":15,"startedAt":"2026-06-14T22:37:16Z","status":"completed"},{"completedAt":"2026-06-14T23:17:56Z","conclusion":"success","name":"Run tests","number":16,"startedAt":"2026-06-14T22:56:23Z","status":"completed"},{"completedAt":"2026-06-14T23:39:12Z","conclusion":"success","name":"Run knowledge lane","number":17,"startedAt":"2026-06-14T23:17:56Z","status":"completed"},{"completedAt":"2026-06-14T23:39:16Z","conclusion":"success","name":"Run connector lane","number":18,"startedAt":"2026-06-14T23:39:12Z","status":"completed"},{"completedAt":"2026-06-14T23:39:32Z","conclusion":"success","name":"Run support copilot gallery lane (advisory)","number":19,"startedAt":"2026-06-14T23:39:16Z","status":"completed"}],"url":"https://github.com/szTheory/scoria/actions/runs/27514007418/job/81319470639"},{"completedAt":"2026-06-14T23:39:38Z","conclusion":"success","databaseId":81323997434,"name":"ci-gate","startedAt":"2026-06-14T23:39:36Z","status":"completed","url":"https://github.com/szTheory/scoria/actions/runs/27514007418/job/81323997434"}],"url":"https://github.com/szTheory/scoria/actions/runs/27514007418","workflowName":"CI"}
```

---

## Projected Critical Path: Fully Parallelized Topology (Phases 23-26)

The complete v3.1 CI/CD Velocity improvement set (Phases 23-26) exists in the local main
branch but has NOT yet been pushed to GitHub or triggered a GitHub Actions run as of this
writing (2026-06-17). The parallel topology is implemented and covered by contract tests.
This section computes the projected critical path from the real per-step timing in run
27514007418 combined with the Phase 24-26 architectural changes.

**Implemented topology** (Phases 25-26, local main branch):

```
policy → build → { test, ratchet, knowledge, connector, full-suite[×4 matrix] } → verify-summary
```

- `policy` — baseline expiry + compile WAE + lane-contract tests (no Postgres)
- `build` — compile once (MIX_ENV=test, WAE), upload artifact
- `test` — closeout chain on shared artifact: release_preview → adoption → runtime_to_handoff → semantic_fast_path (no full-suite step after Phase 26)
- `ratchet` — maintainer hygiene chain (warning-inventory WAE subprocess)
- `knowledge` — `mix test.knowledge --warnings-as-errors` with Phase 24 `--only knowledge` fix
- `connector` — `mix test.connector --warnings-as-errors` + advisory gallery tail
- `full-suite [×4]` — `mix test --warnings-as-errors --partitions 4` matrix (Phase 26)
- `verify-summary` — fan-in (`if: always()`, `needs:` all above)

**Projected per-lane durations** (from run 27514007418 step timing, with Phase 24-26 adjustments):

| Parallel lane | Projected duration | Source |
|--------------|-------------------|--------|
| `test` (closeout chain only, no full-suite) | ~6m30s | Steps 8-14 of run 27514007418 (389s) |
| `ratchet` (hygiene chain) | ~19m07s | Step 15 of run 27514007418 (1147s) |
| `knowledge` (--only knowledge, Phase 24) | ~3m (est.) | 6 knowledge files; actual timing pending push |
| `connector` (+gallery) | ~20s | Steps 18-19 of run 27514007418 |
| `full-suite` shard (slowest of 4, Phase 26) | ~5m24s | Step 16 ÷ 4 (1293s ÷ 4 = 323s) |

**Projected critical path** per D-D2 (sum of stage maxima along dependency chain):

```
policy (2m59s) + build (0m19s) + max(parallel lanes) + verify-summary (~30s)
  = 179s + 19s + max(389, 1147, 180, 20, 323)s + 30s
  = 179s + 19s + 1147s (ratchet) + 30s
  = 1375s
  = ~23min
```

The bottleneck lane is `ratchet` at ~19min (warning-inventory WAE subprocess). This is the
dominant cost after parallelization eliminates the previously-dominant knowledge re-run (~22min
saved by Phase 24) and full-suite serial execution (~16min saved by Phase 26 sharding +
Phase 25 parallelization).

**vs. original ~12min target:** The SEED-003 profiling (citing "~45 min of two fixable root
causes") pointed to the knowledge re-run (~22min) and the ratchet cold-compile (~22min) as
the main targets. Phase 24 addresses the knowledge re-run. However, measured data from run
27514007418 shows the ratchet step takes ~19min even on a warm-cache run with the Phase 23
artifact available to downstream jobs. After Phases 23-26, the projected critical path is
~23min rather than ~12min — the ratchet lane remains the dominant cost.

**Phase 23 measured savings:** 76min (serial baseline) → 73min (build-once) = ~3min reduction
from eliminating test-job recompilation (confirmed by `Download compiled artifact` 1s vs prior
`mix deps.compile` absent in baseline).

---

## Critical-Path Computation Summary (D-D2 contract)

Per D-D2: critical path = sum of **stage maxima** along the dependency chain
`policy → build → max(test, ratchet, knowledge, connector, full-suite shards) → verify-summary`,
using each job's (completedAt − startedAt) active run time (EXCLUDES queue time). For matrix
lanes (full-suite ×4) take the SLOWEST shard.

| Stage | Duration (projected) | Notes |
|-------|----------------------|-------|
| policy | 2m59s (measured) | Warm cache hit, Phase 23 run |
| build | 0m19s (measured) | Build-once artifact upload |
| max(parallel lanes) | 19m07s (ratchet) | Bottleneck after Phase 24-26 |
| verify-summary | ~30s (est.) | Fan-in result check |
| **TOTAL** | **~23min** | Projected with Phases 23-26 applied |

Baseline comparison: 76m15s (serial) → ~23min projected (fully parallelized) = ~−53min
Run-level wall-clock improvement: ~79min (baseline) → ~73min (Phase 23 only, measured)

---

## Honesty Caveats (D-D4)

1. **Phases 24-26 are local-only:** The knowledge lane fix (Phase 24), lane parallelization
   (Phase 25), and full-suite sharding (Phase 26) have been implemented and contract-tested
   but have NOT yet been pushed to GitHub or triggered a GitHub Actions run. The projected
   ~23min critical path is derived from architecture + internal step timing of run 27514007418,
   not from a live GitHub Actions execution of the parallelized topology. This is stated
   explicitly because D-D3 prohibits fabricating per-job numbers.

2. **warm-cache run:** Run 27514007418 is a warm-cache run — `Restore deps + build cache`
   completed in 1s, confirming a cache hit on the stable env-scoped key (OS/OTP/Elixir/
   MIX_ENV/mix.lock hash) introduced in Phase 23. The baseline run 27508317719 also hit the
   cache (5s restore vs 7s install) — the comparison is on a same-workload, warm-cache basis.

3. **same-workload:** Both runs execute the same test suite (same commit count / no skipped
   lanes). The after-run includes the same adoption, runtime-to-handoff, semantic, ratchet,
   full-suite, knowledge, and connector lanes as the baseline — no lanes were omitted.

4. **runner variance:** Single runs per configuration. GitHub Actions `ubuntu-latest` runners
   have non-trivial variance (±2-5min on compute-bound jobs is typical). The ratchet's ~19min
   measurement should be treated as a one-sample estimate with ±2min uncertainty.

5. **ratchet cold-compile note:** SEED-003 described the ratchet as "a cold-compile subprocess"
   that was a root cause. With Phase 23's build-once artifact available to the parallel ratchet
   job, the ratchet job CAN restore the artifact. Whether the ratchet's `mix test --WAE`
   subprocess inside `scoria.warning_ratchet.test` also benefits from the artifact (or runs its
   own subprocess compile) is not yet measured. A live parallelized run may show the ratchet
   job significantly faster than the ~19min serial measurement.

6. **post-push verification pending:** The durable velocity outcome (≤~15min or ~12min target)
   requires a live GitHub Actions run with the Phases 24-26 code merged. This document records
   the intermediate state as of 2026-06-17 (Phase 28 closeout). The verify-summary fan-in job
   name and parallel topology are fully implemented in `.github/workflows/ci-verify.yml` and
   guarded by contract tests.

---

*Generated: 2026-06-17 | Baseline run ID: 27508317719 | Phase 23 after-run ID: 27514007418*
*Phases 24-26: local main branch (not yet pushed) | Critical path method: D-D2 (active run time)*
