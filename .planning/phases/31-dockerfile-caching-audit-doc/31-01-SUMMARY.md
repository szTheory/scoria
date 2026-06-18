---
phase: 31-dockerfile-caching-audit-doc
plan: 01
subsystem: infra
tags: [docker, dockerfile, buildkit, layer-cache, mix, elixir]

# Dependency graph
requires: []
provides:
  - Dockerfile.dev boundary invariant comment (INVARIANT: volatile source) above COPY lib lib
  - docs/docker_dev_dx.md layer-invalidation table (4-row: CSS, HEEx/lib, config, mix.exs/mix.lock)
  - ci_policy_contract_test.exs COPY-order + boundary-marker contract test
  - One-time empirical proof: mix deps.get is CACHED on a CSS/HEEx-only source touch
affects: [phase-34-docker-dx-doc]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Layer-order invariant: volatile source COPYs must stay below deps.get + deps.compile in Dockerfile.dev"
    - "Policy-lane contract test pins COPY layer order statically — no Docker daemon required"
    - "Boundary invariant comment couples human-readable rationale to machine-readable marker"

key-files:
  created:
    - docs/docker_dev_dx.md (layer-invalidation section appended)
  modified:
    - Dockerfile.dev
    - docs/docker_dev_dx.md
    - test/scoria/ci_policy_contract_test.exs

key-decisions:
  - "D-01: Do NOT reorder Dockerfile.dev COPY/RUN lines — order is already correct; phase documents and guards it only"
  - "D-04: Empirical Docker proof is a one-time recorded snapshot in SUMMARY, not a standing make cache-audit harness or CI step"
  - "D-08: COPY-order test appended to existing ci_policy_contract_test.exs, not a new file"
  - "D-10: Boundary invariant comment uses INVARIANT: volatile source as load-bearing marker substring (not pre-existing header phrase)"
  - "D-11: Phase 34 hand-off recorded here; Phase 34 must NOT absorb a Dockerfile-order assertion unless D-08 is dropped"

patterns-established:
  - "Contract test marker pattern: @layer_invariant_marker attribute in ci_policy_contract_test.exs couples comment to test assertion"
  - "Empirical cache proof pattern: warm cache -> touch real file -> --progress=plain rebuild -> grep CACHED|deps.get"

requirements-completed: [CACHE-01]

# Metrics
duration: 45min
completed: 2026-06-18
status: complete
---

# Phase 31 Plan 01: Dockerfile Caching Audit + Doc Summary

**Empirical proof + three permanent guards that Dockerfile.dev layer order prevents mix deps.get/deps.compile re-execution on CSS/HEEx-only edits — boundary invariant comment, docs layer-invalidation table, and static policy-lane contract test.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-06-18T00:00:00Z
- **Completed:** 2026-06-18T00:00:00Z
- **Tasks:** 3 (2 auto + 1 human-verify checkpoint)
- **Files modified:** 3

## Accomplishments

- Added `# INVARIANT: volatile source` boundary comment above `COPY lib lib` in `Dockerfile.dev` (criterion 2) — couples human rationale to machine-readable marker
- Appended 4-row layer-invalidation table to `docs/docker_dev_dx.md` under "No rebuild on source/style edits" (criterion 3) — covers CSS (nothing), HEEx/lib (app compile only), config (deps.compile + mix compile), mix.exs/mix.lock (full dep rebuild)
- Appended COPY-order + boundary-marker contract test to `test/scoria/ci_policy_contract_test.exs` (criterion 4) — `index_of` substring-order assertions + `df =~ @layer_invariant_marker`; passes in policy lane (`mix test --no-start`) with 46 tests, 0 failures
- Recorded one-time empirical Docker cache proof (criterion 1) — `mix deps.get` appears only as `CACHED` on a CSS/HEEx mtime touch; full verbatim evidence below

## Task Commits

Each task was committed atomically:

1. **Task 1: Boundary invariant comment + docs layer-invalidation table** - `9bb2eaa` (feat)
2. **Task 2: COPY-order + marker contract test** - `de2168f` (test)
3. **Task 3: Empirical proof recorded in SUMMARY** - (this SUMMARY, committed separately)

## Files Created/Modified

- `Dockerfile.dev` - Added 4-line `# INVARIANT: volatile source` comment block directly above existing `# 3) Volatile source last` comment (L51–54); COPY/RUN order unchanged
- `docs/docker_dev_dx.md` - Appended `### Layer-cache invalidation (cold docker compose up --build only)` heading + framing paragraph + 4-row table after "Cold builds" bullet, before `## Adopting this in another repo`
- `test/scoria/ci_policy_contract_test.exs` - Added `@layer_invariant_marker "INVARIANT: volatile source"` attribute + new flat `test "Dockerfile.dev keeps cache-optimal COPY layer order (deps -> config -> source)"` block

## COPY Order Unchanged (D-01 Confirmation)

The COPY/RUN order in `Dockerfile.dev` was NOT changed. This phase documents and guards the existing order only:

```
L40:  COPY mix.exs mix.lock ./       # deps manifest — layer 1
L46:  COPY config config             # compile config — layer 2
L51:  # INVARIANT: volatile source (lib/dev/priv) MUST stay below deps.get + deps.compile.
L52:  # Reordering re-fetches/recompiles deps on every source edit. Layer order is deliberate
L53:  # — see docs/docker_dev_dx.md (layer-invalidation table). Guarded by
L54:  # test/scoria/ci_policy_contract_test.exs.
L55:  # 3) Volatile source last — editing these does NOT invalidate the layers above.
L56:  COPY lib lib                   # volatile source — layer 3
```

The existing `# 3) Volatile source last` comment at L55 was preserved (the docs table cites it as "step 3").

## Empirical Docker Cache Proof (Criterion 1)

**Procedure** (repo root, Docker 29.5.2 / Compose v5.1.3 / buildx v0.34.0, service `web`):

```
1. docker compose build web                                                      # warm cache
2. touch assets/css/06-utilities.css lib/scoria_web/components/layouts/root.html.heex
3. docker compose build --progress=plain web 2>&1 | tee /tmp/scoria-cacheproof.log
4. grep -nE 'CACHED|mix deps\.get' /tmp/scoria-cacheproof.log
```

**grep output (verbatim):**

```
15:#4 CACHED
32:#9 CACHED
35:#10 CACHED
38:#11 CACHED
41:#12 CACHED
44:#13 CACHED
46:#14 [stage-0  7/15] RUN --mount=type=cache,target=/root/.hex,sharing=locked     mix deps.get
47:#14 CACHED
50:#15 CACHED
53:#16 CACHED
56:#17 CACHED
59:#18 CACHED
62:#19 CACHED
65:#20 CACHED
68:#21 CACHED
71:#22 CACHED
```

**Step mapping:**

| BuildKit step | Dockerfile step | Result |
|---|---|---|
| `#14` | `RUN ... mix deps.get` | **CACHED** (line 47) — no download/fetch output follows |
| `#10` | `RUN ... mix deps.compile` | **CACHED** (line 35) — no recompile |
| `#12` | `COPY lib lib` | **CACHED** (line 41) |
| `#20` | `RUN mix compile` | **CACHED** (line 65) |

**VERDICT: PASS for criterion 1** — `mix deps.get` and `mix deps.compile` appear only as `CACHED` on a CSS/HEEx source touch; no dep refetch or recompile occurred.

### Honest Nuance (mtime vs. content hash)

ALL layers returned CACHED, including `COPY lib lib` and `mix compile`. The reason: `touch` updates only mtime, and BuildKit keys COPY layers on **file content hashes**, not mtime. So no layer was invalidated by the touch at all.

This **over-satisfies** criterion 1 — deps were definitively not refetched. The "app compile only" path described in the docs table (HEEx/`lib/` row) describes a real **content edit** that invalidates `COPY lib lib` → re-runs `mix compile` while deps stay CACHED because they sit above the volatile-source COPYs in the deliberate layer order. That path was not exercised by an mtime-only touch and is not required for criterion 1.

Note on `--progress` flag placement: the correct global flag form is `docker compose --progress plain build web`; the `docker compose build --progress=plain web` form still produces plain output captured to the log (compose forwards the flag to BuildKit).

## Success Criteria — How Each Was Met

| # | Criterion | How Met |
|---|---|---|
| 1 | CSS/HEEx touch → `mix deps.get` only as CACHED | Empirical proof above: `#14 CACHED` with no download output |
| 2 | `Dockerfile.dev` invariant comment with `INVARIANT: volatile source` marker | `feat(31-01)` commit `9bb2eaa` — grep-verified present above `COPY lib lib` |
| 3 | `docs/docker_dev_dx.md` layer-invalidation table | `feat(31-01)` commit `9bb2eaa` — table covers CSS (nothing), HEEx (app compile only), config, mix.exs/mix.lock |
| 4 | Static COPY-order + marker test in policy lane | `test(31-01)` commit `de2168f` — 46 tests, 0 failures with `mix test --no-start` |

## Phase 34 Hand-Off Note (D-11, RECORD-ONLY)

**Do NOT build Phase 34's test here.** The following is recorded for Phase 34's planning context:

1. **Doc-string contract test:** Phase 34's `docker_dx_doc_contract_test.exs` should assert that the table's load-bearing strings (`mix deps.get`, `mix deps.compile`, `app compile only`) survive in `docs/docker_dev_dx.md` and are not accidentally deleted or renamed in future edits.

2. **Dockerfile layer-order assertion contingency:** Dockerfile layer-order was absent from every phase's stated success criteria until D-08 closed it via the policy-lane contract test in `ci_policy_contract_test.exs`. If D-08 were ever dropped (the COPY-order test removed from `ci_policy_contract_test.exs`), Phase 34 must absorb an equivalent Dockerfile-order assertion to prevent silent regression of the `mix.exs/mix.lock` → `config` → `lib` invariant.

## Decisions Made

- **D-01**: COPY/RUN order was already correct — phase documents and guards only; no reordering.
- **D-04**: Empirical proof is a one-time SUMMARY snapshot; no `make cache-audit` target, no CI harness (non-deterministic in CI, daemon-free policy lane).
- **D-08**: COPY-order test appended to existing `ci_policy_contract_test.exs` (not a new file) to stay within the established policy-lane pattern.
- **D-10**: Boundary marker `INVARIANT: volatile source` is distinct from the pre-existing `"Layer order is deliberate"` header phrase at L7 — using the pre-existing phrase would make the assertion pass vacuously before the boundary comment was added.
- **D-11**: Phase 34 hand-off is record-only; Phase 34's doc-string contract test is not built here.

## Deviations from Plan

None — plan executed exactly as written. The two auto tasks and the human-verify checkpoint all completed as specified. The mtime/content-hash nuance in the empirical proof was anticipated by the plan's "honest nuance" guidance.

## Issues Encountered

None. `mix test --no-start test/scoria/ci_policy_contract_test.exs` passed green on first run after Task 2.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- CACHE-01 requirement satisfied: CSS/HEEx-only edits provably do not trigger dep refetch, with three permanent guards preventing silent regression.
- Phase 34 can proceed with the `docker_dx_doc_contract_test.exs` doc-string contract test using the load-bearing strings documented in the hand-off note above.
- `docs/docker_dev_dx.md` layer-invalidation table and `Dockerfile.dev` boundary comment are stable; future phases touching `Dockerfile.dev` must preserve the `COPY mix.exs mix.lock` → `COPY config` → `COPY lib` order (enforced by `ci_policy_contract_test.exs`).

---
*Phase: 31-dockerfile-caching-audit-doc*
*Completed: 2026-06-18*
