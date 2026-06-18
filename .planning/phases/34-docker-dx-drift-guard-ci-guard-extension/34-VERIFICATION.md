---
phase: 34-docker-dx-drift-guard-ci-guard-extension
verified: 2026-06-18T20:47:49Z
status: passed
score: 8/8 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 34: Docker DX Drift Guard + CI Guard Extension Verification Report

**Phase Goal:** The canonical Docker dev-DX commands and URLs are pinned by a policy-lane contract test so verification-copy drift cannot recur silently, and `ci_policy_contract_test.exs` ephemeral-port scan is extended to cover `post-publish-smoke.yml`.
**Verified:** 2026-06-18T20:47:49Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `test/scoria/docker_dx_doc_contract_test.exs` exists in the policy lane, is file-read-only/no-start safe, and asserts `make up`, `make dev`, `4799`, `make nuke`, `direnv` or `1Password`, and `ANTHROPIC_API_KEY` in `docs/docker_dev_dx.md`. | VERIFIED | `test/scoria/docker_dx_doc_contract_test.exs:1-4` defines `Scoria.DockerDxDocContractTest`, `use ExUnit.Case, async: true`, and `@doc_path`; lines 25-39 assert the required positive tokens; line 99 reads only `File.read!(@doc_path)`. `ci-verify.yml:53-56` includes the test in the policy-lane `mix test --no-start --warnings-as-errors` command. |
| 2 | The same test mechanically rejects stale fixed `localhost:4000` / fixed loopback `4000` browser-start guidance while allowing qualified Docker-internal `4000` mechanics. | VERIFIED | `docker_dx_doc_contract_test.exs:53-61` asserts no stale hits in the real docs; lines 63-75 include negative stale examples; lines 77-96 include allowed Docker-internal and anti-footgun examples. Static scan `rg -n "localhost:4000\|127\\.0\\.0\\.1:4000" docs/docker_dev_dx.md` returned zero matches. |
| 3 | The doc contract also pins Phase 31 cache-table reader strings. | VERIFIED | `docker_dx_doc_contract_test.exs:41-51` asserts `mix deps.get`, `mix deps.compile`, and `app compile only`; those fragments are present in `docs/docker_dev_dx.md:240-242`. |
| 4 | `ci_policy_contract_test.exs` scans `.github/workflows/post-publish-smoke.yml` for the FLAKE-01 host-port ban and rejects host ports `>= 32768`. | VERIFIED | `ci_policy_contract_test.exs:8` defines `@post_publish_smoke`; line 214 reads it; lines 229-235 add file-prefixed post-publish postgres blocks; lines 247-249 exactly require `post-publish-smoke.yml:smoke`; lines 260-274 extract `HOST:CONTAINER` binds and assert `host_port < @ephemeral_range_min`. |
| 5 | `post-publish-smoke.yml` uses `5432:5432` and `SCORIA_DB_PORT: 5432`, with no remaining `55432` hits. | VERIFIED | `.github/workflows/post-publish-smoke.yml:51-62` shows `5432:5432` and `SCORIA_DB_PORT: 5432`. `rg -n "55432" .github/workflows/post-publish-smoke.yml` returned zero matches. |
| 6 | `ci_policy_contract_test.exs` no longer owns broad Docker DX doc-token assertions duplicated by the dedicated doc contract. | VERIFIED | `rg -n "@docker_dx_docs\|Docker DX guide documents the collision-resistant workflow\|http://localhost:4000/scoria" test/scoria/ci_policy_contract_test.exs` returned zero matches. The remaining related guard is the non-doc `.env.example` instance example at `ci_policy_contract_test.exs:814-819`; Dockerfile, Compose, Makefile, and secrets-structure policy guards remain in the file. |
| 7 | The existing `ci-verify.yml` policy lane runs the new doc contract without CI topology changes. | VERIFIED | `.github/workflows/ci-verify.yml:53-56` keeps the same policy step and `SCORIA_LANE_CONTRACT_ONLY: "true"` while adding `test/scoria/docker_dx_doc_contract_test.exs` to the explicit file list. The policy job has no services block; service blocks remain only in app-booting jobs (`ci-verify.yml:107`, `191`, `256`, `316`, `385`). `ci.yml:127-147` still exposes `ci-gate`. |
| 8 | Final Phase 34 verification passes the combined policy-lane command and both static drift checks. | VERIFIED | Ran `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/docker_dx_doc_contract_test.exs test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs`: 83 tests, 0 failures. `rg` static checks for `55432` and stale `localhost:4000` / fixed loopback `4000` returned zero matches. `git diff --check -- test/scoria/docker_dx_doc_contract_test.exs test/scoria/ci_policy_contract_test.exs .github/workflows/post-publish-smoke.yml .github/workflows/ci-verify.yml` passed. |

**Score:** 8/8 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `test/scoria/docker_dx_doc_contract_test.exs` | Dedicated DOCS-03 contract | VERIFIED | 171 lines; substantive ExUnit tests for positive tokens, cache strings, stale URL rejection, allowed qualifiers, and anti-footgun copy. |
| `test/scoria/ci_policy_contract_test.exs` | Extended FLAKE-01 scanner | VERIFIED | Reads `@post_publish_smoke`, prefixes `post-publish-smoke.yml:smoke`, asserts exact inclusion, and enforces `< 32768` host ports. |
| `.github/workflows/post-publish-smoke.yml` | Low fixed Postgres bind | VERIFIED | Uses `5432:5432` and `SCORIA_DB_PORT: 5432`; zero `55432` matches. |
| `.github/workflows/ci-verify.yml` | Existing policy lane includes doc contract | VERIFIED | Policy-lane run line includes `test/scoria/docker_dx_doc_contract_test.exs` with `--no-start --warnings-as-errors`. |
| `docs/docker_dev_dx.md` | Source document guarded by contract | VERIFIED | Contains required Docker/native commands, URL, secrets nouns, and cache strings; stale fixed `4000` browser-start scan is clean. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `test/scoria/docker_dx_doc_contract_test.exs` | `docs/docker_dev_dx.md` | `File.read!(@doc_path)` | WIRED | `@doc_path` is `docs/docker_dev_dx.md`; line 99 reads it; test command passes against current docs. |
| `test/scoria/ci_policy_contract_test.exs` | `.github/workflows/post-publish-smoke.yml` | `File.read!(@post_publish_smoke)` in FLAKE-01 test | WIRED | Lines 8 and 214 wire the workflow into the scanner; exact key assertion prevents count-only false positives. |
| `.github/workflows/ci-verify.yml` | `test/scoria/docker_dx_doc_contract_test.exs` | Explicit policy-lane `mix test --no-start --warnings-as-errors` file list | WIRED | Line 56 includes the new test in the existing policy job. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `docker_dx_doc_contract_test.exs` | `docs` | `File.read!("docs/docker_dev_dx.md")` | Yes | FLOWING |
| `ci_policy_contract_test.exs` | `post_publish` / `postgres_blocks` | `File.read!(".github/workflows/post-publish-smoke.yml")` plus `job_blocks/1` | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Policy lane runs the new doc contract and extended CI policy contract under `--no-start` | `SCORIA_LANE_CONTRACT_ONLY=true mix test --no-start --warnings-as-errors test/scoria/docker_dx_doc_contract_test.exs test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs` | 83 tests, 0 failures | PASS |
| Post-publish smoke has no old ephemeral-range bind | `rg -n "55432" .github/workflows/post-publish-smoke.yml` | zero matches | PASS |
| Docker DX docs have no stale fixed `4000` browser-start hits | `rg -n "localhost:4000\|127\\.0\\.0\\.1:4000" docs/docker_dev_dx.md` | zero matches | PASS |
| Phase source files have no whitespace errors | `git diff --check -- test/scoria/docker_dx_doc_contract_test.exs test/scoria/ci_policy_contract_test.exs .github/workflows/post-publish-smoke.yml .github/workflows/ci-verify.yml` | exit 0 | PASS |

### Probe Execution

No phase-declared probes or conventional `scripts/*/tests/probe-*.sh` probes were found for Phase 34. Probe execution skipped as not applicable.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DOCS-03 | 34-01, 34-02, 34-03 | Policy-lane `docker_dx_doc_contract_test.exs` asserts canonical commands/URLs in `docs/docker_dev_dx.md` and absence of stale `localhost:4000` dev-start guidance. | SATISFIED | New doc contract exists, is policy-lane wired, passes under `mix test --no-start`, asserts required positive tokens, rejects stale fixed `4000` examples, and static stale scan is clean. |

No additional Phase 34 requirements are orphaned in `.planning/REQUIREMENTS.md`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | - | No `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, placeholder, empty implementation, or console-only implementation markers found in Phase 34 plans/source targets. | - | - |

### Human Verification Required

None.

### Gaps Summary

No gaps found. The roadmap success criteria and plan-specific must-haves are implemented, wired, and exercised by the policy-lane command plus static drift checks. Phase 35 release publishing and live registry smoke remain out of scope and are explicitly covered by the later roadmap phase.

---

_Verified: 2026-06-18T20:47:49Z_
_Verifier: the agent (gsd-verifier)_
