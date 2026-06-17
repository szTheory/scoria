# Phase 28: DX `mix ci` alias + velocity closeout - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-17
**Phase:** 28-dx-mix-ci-alias-velocity-closeout
**Areas discussed:** Form & run semantics, Optional lanes & env, Format/deps-lock + CI parity, Velocity proof artifact

Mode: advisor (`minimal_decisive`; `technical_background: true` → no plain-language
reframing). User requested deep parallel subagent research per area and a coherent
one-shot recommendation set; all four areas researched and all recommendations accepted.

---

## Form & run semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Mix.Task, run-all-aggregate | `scoria.ci` task driven off VerificationLanes; runs all steps, aggregates failures, `System.halt(1)` on any | ✓ |
| Mix.Task, fail-fast | Same task form but stops at first failing step | |
| mix.exs alias (plain list) | `ci: [...]` chain — simplest but can't aggregate; last-step-only exit code (elixir#4318) → false-green | |

**User's choice:** Mix.Task, run-all-aggregate, SSOT-driven (researched; accepted).
**Notes:** Alias form disqualified twice — exit-code swallowing footgun + SSOT drift vs byte-order contracts. Run-all mirrors CI's `verify-summary` fan-in.

---

## Optional lanes & env

| Option | Description | Selected |
|--------|-------------|----------|
| Require DB, exclude gallery | Full gating set; hard-fail w/ preflight + actionable microcopy if Postgres/pgvector missing; exclude advisory gallery | ✓ |
| Detect + skip with warning | Skip infra-dependent lanes with a warning — but exit 0 while real gate fails (false-confidence) | |
| Require DB, include gallery | Same as recommended but also run advisory gallery as non-failing tail | |

**User's choice:** Require DB + preflight hard-fail, exclude gallery (researched; accepted).
**Notes:** Added `--skip-optional` / `SCORIA_CI_SKIP_OPTIONAL=1` opt-out that prints skipped lanes, stamps `RESULT: PARTIAL`, and still exits non-zero. Silent-skip-with-exit-0 rejected as worse than no local mirror.

---

## Format/deps-lock + CI parity

| Option | Description | Selected |
|--------|-------------|----------|
| Superset locally, leave CI | `mix ci` includes format + deps-lock (per DX-01); CI untouched; document asymmetry | ✓ |
| Add to CI too (policy job) | Also add format + deps-lock to ci-verify.yml policy for exact symmetry | |

**User's choice:** Strict superset locally, do NOT touch CI this phase (researched; accepted).
**Notes:** Editing the contract-guarded workflow at milestone close is scope creep. Both deps commands chosen (`deps.unlock --check-unused` + `deps.get --check-locked`). CI symmetry deferred. `.formatter.exs` must exclude `examples/`.

---

## Velocity proof artifact

| Option | Description | Selected |
|--------|-------------|----------|
| Committed proof doc, pinned IDs | `28-VELOCITY-PROOF.md` + raw JSON + MILESTONES.md headline + VERIFICATION back-ref | ✓ |
| Phase VERIFICATION only | Timing captured only in 28-VERIFICATION.md | |

**User's choice:** Committed proof doc with pinned run IDs + raw JSON (researched; accepted).
**Notes:** Critical path = sum of stage maxima (per-job startedAt→completedAt, excl. queue); headline wall-clock = max(completedAt)−min(startedAt). Baseline = real historical serial run (SEED-003: `27508317719`/`27505520774`), capture JSON now before retention purge. Warm-cache + same-workload caveats stated in the doc.

## Claude's Discretion

None — all four areas were explicitly decided via researched recommendations.

## Deferred Ideas

- Add format + deps-lock checks to CI's `policy` job (true local↔CI symmetry) — follow-up phase.
- `mix ci --with-advisory` flag for the non-failing gallery tail.
- Median-of-N warm runs for the velocity proof if single-run variance is noisy.
