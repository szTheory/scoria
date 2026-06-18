# Phase 31: Dockerfile caching audit + doc - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-18
**Phase:** 31-dockerfile-caching-audit-doc
**Areas discussed:** Empirical proof permanence, Layer-invalidation table accuracy, Layer-order regression guard

**Method:** User requested deep, subagent-backed research on all three gray areas with a one-shot coherent recommendation set. Three parallel `gsd-advisor-researcher` agents researched each decision against Docker BuildKit best practice, Elixir/Phoenix ecosystem lessons, and the project's Operator-First DX DNA (`prompts/sztheory-elixir-dna.md`). Recommendations were synthesized into one interlocking set: prove (A) → comment + table (B) → static test (C).

---

## Empirical proof permanence (success criterion 1)

| Option | Description | Selected |
|--------|-------------|----------|
| Documented command + recorded result | Run `docker compose build --progress=plain` once on CSS + HEEx edits, grep for absence of `mix deps.get`, record in SUMMARY, document the repeatable command. No new tooling. | ✓ |
| `make cache-audit` target | Commit a Make target running build + grep + pass/fail, re-runnable on demand (heavy: real docker build each run). | |
| Both | Target + recorded output. | |

**User's choice:** Research-driven. Researcher recommended option 1 refined.
**Notes:** A `make` target shelling a real `docker compose build` is heavy (minutes/run), brittle (BuildKit progress format + grep string), and a CI-flake footgun (per-runner cache makes build-cache assertions non-deterministic). Ecosystem consensus: the canonical guard for a dev image is the Dockerfile structure + honest docs, not a standing build-audit harness. The repeatable machine guard is the static COPY-order test (C), not a docker build. → D-04/D-05.

---

## Layer-invalidation table accuracy (success criterion 3)

| Option | Description | Selected |
|--------|-------------|----------|
| Accurate, all-layer table | Cover every real COPY boundary + note CSS invalidates no layer; exceeds the mandated 3 rows. | ✓ (hybrid) |
| Roadmap-literal 3 rows | Exactly the 3 mandated rows as worded, even though CSS rebuilds nothing. | |

**User's choice:** Research-driven. Researcher recommended the hybrid: a corrected, COPY-boundary-accurate table that still literally satisfies the 3 mandated rows, preceded by a bind-mount-vs-cold-build framing sentence, with the apt layer folded into prose (not a row).
**Notes:** The roadmap's mandated CSS/HEEx row is imprecise — `assets/` is never `COPY`'d, so a CSS edit invalidates zero image layers; only a HEEx/lib edit triggers app-only compile. Phases 29–30 DNA forbids shipping a knowingly-wrong artifact ("the current static list already drifted"; "honest about the cold-recompile cost"). The hybrid corrects the one falsehood while keeping the table scannable, 1:1 with the Dockerfile, and criterion-3-satisfying. Lands at the end of §"No rebuild on source/style edits". → D-06/D-07.

---

## Layer-order regression guard (the "cannot regress silently" goal)

| Option | Description | Selected |
|--------|-------------|----------|
| Leave to comment + Phase 34 | Ship only the invariant comment + table; rely on the comment now and Phase 34's doc-string test later. | |
| Add Dockerfile COPY-order test now | Tiny policy-lane test (no docker build, no DB) asserting Dockerfile.dev COPY order. | ✓ (hybrid) |

**User's choice:** Research-driven. Researcher recommended the hybrid: ship the order guard now, **folded into the existing `test/scoria/ci_policy_contract_test.exs`** (already in the policy lane, already `--no-start`, no DB) — zero new file, zero CI edit — with a marker assertion coupling the Dockerfile boundary comment to the test.
**Notes:** Verified Phase 34's stated criteria guard only `docs/docker_dev_dx.md` strings + the `post-publish-smoke.yml` port scan — Dockerfile layer order is in NO phase's scope, a real gap. Phase 34 also depends on Phase 33, so deferring would leave the gap open ~3 phases. The static test (structural precondition, every `mix test`) is complementary to the empirical proof (runtime behavior, once, local). Robust via relative `index_of!` substring-order assertions, not exact-line matches. Honors PROJECT.md: existing policy lane only, no CI topology change, `closeout_order/0` byte-stable. → D-08/D-09/D-10/D-11.

---

## Claude's Discretion

- Exact SUMMARY evidence-block wording, table cell prose (keeping load-bearing strings), invariant-comment phrasing, and the `index_of!` helper implementation.
- Whether to cross-link the Dockerfile header comment to the new table.
- Whether to also record the `up --build` proof in addition to `build --progress=plain`.

## Deferred Ideas

- `make cache-audit` target — rejected (heavy/brittle/CI-flake footgun); static test covers the repeatable guard.
- Standalone apt/system table row — folded into framing prose.
- Phase 34 asserting the table's strings — recorded as hand-off D-11.
- Reviewed-not-folded todos: `docker-dx-fleet-hardening` (FLEET-01, deferred milestone-wide); `ci-policy-job-cache-key-mislabel` (CI MIX_ENV cleanup, unrelated to image-layer caching).
</content>
