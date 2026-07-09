---
id: SEED-003
status: archived
planted: 2026-06-14
archived_on: 2026-07-09
shipped_in: v3.1
planted_during: v3.0 Control Room
trigger_when: next milestone — when planning CI/CD, DX, or developer-velocity work
scope: medium
enriched: 2026-06-14 (flakiness evidence + actions-bump status)
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

## Resolution

Archived at v3.4 closeout after confirming the core CI/CD efficiency work shipped in v3.1 CI/CD
Velocity: build-once artifact reuse, parallel lane fan-out, knowledge lane narrowing, 4-way shard
matrix, flake cleanup, `mix ci`, and measured PR critical path reduction to 7m38s. Remaining
test-code determinism work is tracked separately as SEED-004 / deferred roadmap work.

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
   (annotations on every v2.17 run flagged this). ✅ **SHIPPED as standalone hotfix
   [PR #10](https://github.com/szTheory/scoria/pull/10) (2026-06-14)** — checkout v4→v6,
   cache v4→v5, setup-node v4→v6, upload-artifact v4→v7, github-script v7→v9,
   release-please-action v4→v5; `erlef/setup-beam@v1` left as-is (v1 tag already floats
   to node24 v1.24.0). This pain point is closed; the milestone need not revisit it.

## Flakiness Evidence Log (captured 2026-06-14)

Flake elimination is now an **explicit scope item** for this milestone (per maintainer:
"we definitely want to address flakiness during this GSD milestone"). We want
fast/deterministic/bulletproof gates — **no blanket auto-retries used as a cover for real
flakes**; retries are a temporary quarantine tool only, root-cause is the goal.

1. **Postgres fixed-host-port bind flake (PRIMARY, reproduced).** Run `27508317719`,
   PR #10, 2026-06-14: `verify / test` failed at the **"Initialize containers"** step
   (before any action runs) with:
   `failed to set up container networking: driver failed programming external
   connectivity ... failed to bind host port for 0.0.0.0:55432:172.18.0.2:5432/tcp:
   address already in use` → `Docker start fail with exit code 1`. `policy` + `e2e`
   passed; the pgvector image pulled fine. **Root cause:** the postgres `pgvector:pg16`
   service container uses a **fixed host-port mapping (`-p 55432:5432`)**, duplicated in
   `ci.yml` (e2e job) and `ci-verify.yml` (test job); fixed host ports are fragile on
   runners (leftover/recycled container or provisioning race). **Recovered** by a plain
   `gh run rerun --failed`. **Candidate fixes to evaluate:** drop the fixed host-port
   mapping and connect via the service network alias (`postgres:5432`, job-container
   pattern), make the bind resilient, or parameterize/randomize the host port. This code
   is touched anyway during Phase 1/3 — fix it there.
2. **"Transient gh blip" exit-1 on the main CI watch** (v2.17 close, run `27505520774`
   era): the `gh run watch` exited 1 although the run was green — flaky watch/tooling
   layer, not a real CI failure. Low priority; note for the determinism pass.
3. **`runtime_integration` / adoption-lane occasional flake** (noted prior session):
   passed clean on re-run; suspected timing/`Process.sleep`-adjacent. **Overlaps the
   deferred SEED-004 test-code determinism work** — root-cause there, not in workflow YAML.
4. **e2e temp-diagnostic tech-debt:** the `ci.yml` e2e job still carries a TEMP diagnostic
   step (prints DB run count + server rendering) left over from the skeleton-e2e
   root-cause debugging. Remove it during the milestone.

## Goal for Next Milestone

Profile each CI lane (where does the hour go?), parallelize/shard the `verify / test`
and `e2e` lanes, tighten caching, **eliminate the known flakes (fixed-host-port service
container, temp e2e diagnostic) and set a deliberate retry-vs-fix policy**, and cut total
wall-clock. Preserve the existing verification bar (Scoria.VerificationLanes SSOT +
ci_policy_contract_test). Node-24 actions modernization is already done (PR #10).

## Breadcrumbs

- CI entrypoint + lane topology: `.github/workflows/ci.yml` (verify + e2e + ci-gate),
  `.github/workflows/ci-verify.yml` (policy → test, reusable).
- Lane SSOT: `Scoria.VerificationLanes` + `test/scoria/ci_policy_contract_test.exs`.
- Maintainer narrative: `docs/operator_verification.md` (CI gate map).
- e2e dev-server boot + topup: `lib/mix/tasks/scoria.ui.e2e.ex`; seed alias
  `dev.setup` in `mix.exs` (`["scoria.dev.db", "run priv/repo/dev_seed.exs"]`).
- Fixed-host-port service container (flake #1): `services.postgres.ports` / `-p 55432:5432`
  in both `.github/workflows/ci.yml` (e2e job) and `.github/workflows/ci-verify.yml` (test job).
- Temp e2e diagnostic to remove (flake #4): the DB-run-count + server-render debug step in
  the `e2e` job of `.github/workflows/ci.yml`.
- Related deferred work: SEED-004 (test-code async/determinism — IntegrationCase async,
  per-module endpoints, `Process.sleep`→`eventually/2`) covers flake #3's deeper root cause.
- Full milestone plan: `~/.claude/plans/everything-s-settled-and-green-eventual-hinton.md`.

## Notes

Planted at v2.17 close (PR #9). Captured with full context from the PR #9 CI debugging
session — the slowness was felt acutely while waiting ~1h per run to validate a
one-line CSS fix. Enrich further with `/gsd:capture --seed --enrich SEED-003` if needed.
