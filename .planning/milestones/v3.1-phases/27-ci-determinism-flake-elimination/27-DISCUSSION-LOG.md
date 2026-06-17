# Phase 27: CI determinism & flake elimination - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-16
**Phase:** 27-ci-determinism-flake-elimination
**Areas discussed:** DB connection strategy, Retry-vs-fix policy stance, Policy doc location, Recurrence proof

**Mode:** Advisor (`minimal_decisive` tier, opinionated profile). All four areas
researched via parallel `gsd-advisor-researcher` subagents at user request (idiomatic
Elixir/Phoenix/Ecto CI practice, ecosystem examples, footguns, DX). UI/brand lens
discarded — DevOps phase.

---

## DB connection strategy (FLAKE-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Dynamic host-port (`- 5432/tcp` + `job.services...ports`) | Initial Claude rec; eliminates contention but context unavailable in job-level env → silent empty-port failure, per-step env across 5 blocks | |
| Fixed `5432:5432` + `SCORIA_DB_PORT: 5432` | Default port below ephemeral range; dominant Elixir idiom; least surprise | ✓ |
| Job-in-container + network alias (`postgres:5432`) | Heaviest; containerizes setup-beam/Node/Playwright | |

**User's choice:** Fixed `5432:5432` (locked after research reversed the initial dynamic-port rec).
**Notes:** Root cause established — `55432` ∈ GHA ephemeral range `32768–60999`; kernel
can transiently grab it before Docker publishes → "port already allocated" (run
`27508317719`). `5432` is below the range → immune. Dynamic-port rejected on the
GitHub context-availability footgun (job.services not in job-level `env:`). Local dev/test
stay at `55432` (CI sets env explicitly).

---

## Retry-vs-fix policy stance (FLAKE-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Zero-retry default + release/merge polling carve-out | Ban continue-on-error/retry wrappers on test lanes; one named infra-transient exception class | ✓ |
| Narrow named whitelist now | Pre-authorize apt/Playwright-download retries | |

**User's choice:** Zero-retry default.
**Notes:** Codifies current de-facto state (no test retries exist). Backed by
Fowler/industry consensus; ExUnit has no idiomatic auto-retry. Existing `attempt` loops
in release/hex/automerge are completion-polling, explicitly carved out as non-test.

---

## Policy doc location

| Option | Description | Selected |
|--------|-------------|----------|
| `docs/operator_verification.md` section | Initial Claude rec; but doc is adopter-facing | |
| `docs/MAINTAINERS.md` (under CI gate map anchor) | Canonical maintainer/CI home; `{#ci-gate-map-maintainers}` anchor | ✓ |
| New `docs/ci_flake_policy.md` | Orphaned or shipped-noise | |
| `CONTRIBUTING.md` / `.github/` | No CONTRIBUTING.md exists; splits CI narrative | |

**User's choice:** `docs/MAINTAINERS.md` (locked after research reversed the initial pick).
**Notes:** operator_verification.md is adopter-facing ("default verification lane for
your host app"); MAINTAINERS.md is explicitly maintainer-only and already owns the CI
gate map. Optionally retarget the `ci.yml` header comment to MAINTAINERS.md.

---

## Recurrence proof (Success Criterion 1)

| Option | Description | Selected |
|--------|-------------|----------|
| Contract-test guard + one-time ~10× workflow_dispatch sweep | Durable guard (a) + empirical corroboration (b) | ✓ |
| Contract test only | Proves pattern, not runtime non-recurrence | |
| Re-run sweep only | No durable guard; evidence rots | |
| Temporary repeat-N matrix, then removed | Forgotten cleanup; recurring CI cost | |

**User's choice:** Both — guard + sweep.
**Notes:** Guard asserts no Postgres host-port bind in ephemeral range (≥32768),
root-cause-faithful; derive job set from `body =~ "postgres:"` + `>= 5` guard; reuse
`job_blocks/1`; no yaml parser. Honest VERIFICATION framing: non-recurrence is
structural; rule-of-three means ~10 runs is weak probabilistic evidence but the fix
isn't probabilistic. FLAKE-02 (TEMP removal) is clear-cut — handled without discussion.

---

## Claude's Discretion

- Exact regex/parse form of the ephemeral-range assertion + carve-out encoding in the contract test.
- Whether to also ban `continue-on-error`/retry-action `uses:` slugs on test workflows (recommended).
- Whether to retarget the `ci.yml` header comment now or in Phase 28.

## Deferred Ideas

- `mix ci` local alias + before/after velocity timing → Phase 28 (DX-01, VELO-01).
- `ci.yml` header-comment retarget cleanup may fold into Phase 28's doc pass.
- Broader retry-action-ban contract assertion as a possible follow-up.
