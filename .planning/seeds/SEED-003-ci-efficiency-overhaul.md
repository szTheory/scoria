---
id: SEED-003
status: dormant
planted: 2026-06-14
planted_during: v3.0 Control Room
trigger_when: next milestone — when planning CI/CD, DX, or developer-velocity work
scope: medium
---

# SEED-003: CI/CD efficiency overhaul — cut CI wall-clock

## Why This Matters

CI is **very slow** and it directly taxes every merge. The v2.17 PR #9 run took
**~1h+ end-to-end**; the `verify / test` lane alone has run **6–60 min** (adoption
closure + full test suite), and the `e2e` lane adds a fresh-DB dev-server cold boot
before Playwright even starts. Slow CI slows every iteration and discourages small,
frequent PRs. Examine this **right after v2.17 (PR #9) merges** and make it a focused
target for the next milestone with GSD.

## When to Surface

**Trigger:** next milestone planning, especially any CI/CD, DX, or developer-velocity
theme. Surface during `/gsd:new-milestone` scope discovery.

## Scope Estimate

**Medium** — a phase or two: profile lanes, parallelize/shard, tighten caching, bump
deprecated actions. Mostly `.github/workflows/` + test-lane config; low product risk,
high velocity payoff.

## Pain Points Observed (this session, v2.17 PR #9)

1. **`verify / test` is one long serial lane** (adoption closure lane + full ExUnit
   suite, 6–60 min). Prime candidate for **parallelization / test sharding** across
   matrix jobs.
2. **e2e dev-server cold boot is slow** — `mix dev.setup` + compile + `mix
   scoria.assets.build` + server boot all run *before* Playwright starts. Consider
   precompiled/cached build, prebuilt assets, or a warm image.
3. **Caching likely underused** — deps cache + Playwright browser cache; verify hit
   rates and key stability (saw cache hits but boot still slow).
4. **Deprecated Node 20 actions** — GitHub forces Node 24 by **2026-06-16**. Bump
   `actions/checkout`, `actions/cache`, `actions/setup-node`, `actions/upload-artifact`
   (annotations on every v2.17 run flagged this).

## Goal for Next Milestone

Profile each CI lane (where does the hour go?), parallelize/shard the `verify / test`
and `e2e` lanes, tighten caching, modernize actions, and cut total wall-clock. Preserve
the existing verification bar (Scoria.VerificationLanes SSOT + ci_policy_contract_test).

## Breadcrumbs

- CI entrypoint + lane topology: `.github/workflows/ci.yml` (verify + e2e + ci-gate),
  `.github/workflows/ci-verify.yml` (policy → test, reusable).
- Lane SSOT: `Scoria.VerificationLanes` + `test/scoria/ci_policy_contract_test.exs`.
- Maintainer narrative: `docs/operator_verification.md` (CI gate map).
- e2e dev-server boot + topup: `lib/mix/tasks/scoria.ui.e2e.ex`; seed alias
  `dev.setup` in `mix.exs` (`["scoria.dev.db", "run priv/repo/dev_seed.exs"]`).

## Notes

Planted at v2.17 close (PR #9). Captured with full context from the PR #9 CI debugging
session — the slowness was felt acutely while waiting ~1h per run to validate a
one-line CSS fix. Enrich further with `/gsd:capture --seed --enrich SEED-003` if needed.
