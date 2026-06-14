# Phase 23: Cache correctness + build-once job - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-14
**Phase:** 23-cache-correctness-build-once-job
**Areas discussed:** Build-job placement, dev-env lanes, Cache-key + versions, Contract-test handling
**Mode:** advisor / minimal_decisive (recommended defaults presented; user confirmed all four areas)

---

## Build-job placement

| Option | Description | Selected |
|--------|-------------|----------|
| `build` in reusable `ci-verify.yml` | Single compile warms every consumer (PR verify, release-please verify, hex-publish recovery); sequence policy → build → test | ✓ |
| `build` in `ci.yml` entry only | Compile-once only for the PR/main entry; recovery/release paths unaffected | |

**User's choice:** `build` in `ci-verify.yml` (accepted recommendation).
**Notes:** Broadest reuse / one SSOT. Trade-off acknowledged: `e2e` lives in `ci.yml` and is MIX_ENV=dev, which the dev-env-lanes decision resolves.

---

## dev-env lanes

| Option | Description | Selected |
|--------|-------------|----------|
| test-only artifact; dev via cache | build uploads MIX_ENV=test only (CACHE-02 literal); e2e/release_preview keep dev compile warmed by env-scoped dev cache (CACHE-01 fix) | ✓ |
| build both dev + test artifacts | build compiles test AND dev, uploads both; dev lanes download dev artifact | |

**User's choice:** test-only artifact; dev via env-scoped cache.
**Notes:** Test-env `_build` is useless to a dev compile; dev compile is the cheaper half; second dev artifact would exceed CACHE-02 scope. This was the one genuine fork in the phase.

---

## Cache-key + versions

| Option | Description | Selected |
|--------|-------------|----------|
| `version-file: .tool-versions` + composite key | setup-beam reads `.tool-versions` (matches 3 other workflows); key = os+otp+elixir+MIX_ENV+mix.lock | ✓ |

**User's choice:** accepted recommendation (locked, not contested).
**Notes:** Kills hardcoded `27`/`1.19` drift vs `.tool-versions` (`27.3.2` / `1.19.5-otp-27`). restore-keys narrowed from the too-broad `${{ runner.os }}-mix-`.

---

## Contract-test handling

| Option | Description | Selected |
|--------|-------------|----------|
| policy → build(needs: policy) → test(needs: build) | Literal `needs: policy` substring preserved; split_jobs (splits at `\n  test:`) still works; build has no `services:` | ✓ |

**User's choice:** accepted recommendation.
**Notes:** No pinned command string moves out of byte-order (Success Criterion #4). Contract tests extended minimally to assert the build job + artifact + needs chain.

---

## Claude's Discretion

- Exact mechanism for reading `.tool-versions` into a cache-key step output (inline grep/cut, composite action, or setup-beam outputs).
- Artifact `name` / `retention-days` / `if-no-files-found` settings (consistent with existing repo usage).

## Deferred Ideas

- None within other phases' scope from this discussion.
- Reviewed-not-folded todo: "Docker dev-DX fleet hardening" (weak keyword match; unrelated to CI cache). The fixed CI Postgres port is owned by Phase 27.
