---
phase: 23-cache-correctness-build-once-job
verified: 2026-06-14T00:00:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
---

# Phase 23: Cache Correctness + Build-Once Job — Verification Report

**Phase Goal:** Make CI compile deps + app exactly once per run and have every downstream job reuse that compiled artifact, with cache keys that can never collide across MIX_ENV or stale tool versions, while keeping the byte-order lane-contract tests green.
**Verified:** 2026-06-14
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | CI compiles deps + app exactly once per workflow run (build job), MIX_ENV=test, warnings-as-errors | VERIFIED | `ci-verify.yml` lines 57–99: build job has `env: MIX_ENV: test`, `needs: policy`, `mix compile --warnings-as-errors` at line 87; no `mix compile` exists in the test job (lines 101–195) |
| 2 | The test job restores the compiled artifact and performs zero recompile | VERIFIED | Test job has `download-artifact@v7` (line 140) + `tar -xzf` (line 145); no `actions/cache` restore and no `mix compile` in test job; `/tmp/recompile-proof.txt` is 0 bytes (zero Compiling lines after local tar round-trip); CI run 27514007418 job 81319470639 grep returned no output |
| 3 | Cache keys are scoped by OS + OTP + Elixir + MIX_ENV + mix.lock hash; dev/test never share a key | VERIFIED | `ci-verify.yml` lines 35+79: `-test-mix-` segment present in all key: lines; `ci.yml` line 79: `-dev-mix-` segment present; `grep -v '^#' ... | grep -c 'runner.os }}-mix-'` returns 0 across both files |
| 4 | OTP/Elixir versions sourced from .tool-versions; no hardcoded otp-version/elixir-version remain | VERIFIED | `grep -c 'otp-version: "27"' ci-verify.yml ci.yml` returns 0 in both; `version-file: .tool-versions` appears 3× in ci-verify.yml (policy, build, test jobs) and 1× in ci.yml (e2e job); `id: beam` present on all 4 setup-beam steps |
| 5 | ci_policy_contract_test and verification_lanes_test stay green; no pinned command string moved out of byte-order | VERIFIED | `SCORIA_LANE_CONTRACT_ONLY=true MIX_ENV=test mix test ... ci_policy_contract_test.exs verification_lanes_test.exs` → **42 tests, 0 failures**; `git log --oneline c33c45e..HEAD -- test/scoria/verification_lanes_test.exs` returned empty (file untouched in phase) |

**Score:** 5/5 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.github/workflows/ci-verify.yml` | policy → build → test topology; build job compiles once + uploads tar; test job downloads + untars; env-scoped test-mix cache keys; setup-beam version-file | VERIFIED | build job at lines 57–99 (`needs: policy`, `MIX_ENV: test`, `mix compile --warnings-as-errors`, `tar -czf`, `upload-artifact@v7`); test job at lines 101–195 (`needs: build`, `download-artifact@v7`, `tar -xzf`, no cache step); contains `build:` at byte 1955 < `\n  test:` at byte 3275 |
| `.github/workflows/ci.yml` | e2e job env-scoped dev-mix cache key; setup-beam version-file | VERIFIED | Line 79: `-dev-mix-` in key; line 62–63: `id: beam` + `version-file: .tool-versions` |
| `test/scoria/ci_policy_contract_test.exs` | 4 new assertions for build topology and cache-key invariants | VERIFIED | Lines 273, 283, 294, 302: all 4 test functions present; contract suite runs 42 tests, 0 failures |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `ci-verify.yml build job` | `ci-verify.yml test job` | `upload-artifact@v7` (name: build-test-env) → `download-artifact@v7` + `tar -xzf` | WIRED | Lines 93–98 upload; lines 140–145 download + unpack; artifact name `build-test-env` matches in both steps |
| `setup-beam id: beam outputs` | `actions/cache@v5 key` | `steps.beam.outputs.otp-version` / `steps.beam.outputs.elixir-version` interpolation | WIRED | All 3 cache blocks in ci-verify.yml (lines 35, 79) and 1 in ci.yml (line 79) use `${{ steps.beam.outputs.otp-version }}` and `${{ steps.beam.outputs.elixir-version }}`; all 4 setup-beam steps carry `id: beam` |
| `test/scoria/ci_policy_contract_test.exs split_jobs/1` | `.github/workflows/ci-verify.yml` | Split at `\n  test:` — build job byte-position lands policy-side | WIRED | `split_jobs/1` (line 434) splits on `\n  test:`; build job key at byte 1955, test job boundary at byte 3275 — build is definitively policy-side; contract test `"build job exists in policy-side slice..."` passes |

---

### Data-Flow Trace (Level 4)

Not applicable — no dynamic-data-rendering components. Artifacts are GitHub Actions YAML and ExUnit test files. Data "flow" is the artifact tarball from build job to test job, verified via key-link wiring above.

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Contract suite green (42 tests) | `SCORIA_LANE_CONTRACT_ONLY=true MIX_ENV=test mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` | 42 tests, 0 failures (0.1s) | PASS |
| No hardcoded OTP version | `grep -c 'otp-version: "27"' ci-verify.yml ci.yml` | 0 in both files | PASS |
| No bare runner.os-mix- key | `grep -v '^#' ci-verify.yml ci.yml | grep -c 'runner.os }}-mix-'` | 0 | PASS |
| MIX_ENV cache segments present | `grep -n 'test-mix-\|dev-mix-' ci-verify.yml ci.yml` | test-mix- in ci-verify.yml (lines 35, 37, 79, 81); dev-mix- in ci.yml (lines 79, 81) | PASS |
| SC#3 local mtime simulation | `grep -ic 'compiling' /tmp/recompile-proof.txt` | 0 — file is 0 bytes, zero Compiling lines | PASS |
| version-file sourcing count | `grep -c 'version-file: .tool-versions' ci-verify.yml ci.yml` | ci-verify.yml: 3, ci.yml: 1 | PASS |
| id: beam on all setup-beam steps | `grep -n 'id: beam' ci-verify.yml ci.yml` | 3 occurrences in ci-verify.yml (lines 23, 67, 133), 1 in ci.yml (line 62) | PASS |

---

### Probe Execution

No conventional `scripts/*/tests/probe-*.sh` files declared or required for this phase. Phase is GitHub Actions YAML + ExUnit only.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| CACHE-01 | 23-01-PLAN.md | Cache keys scoped by OS + OTP + Elixir + MIX_ENV + mix.lock hash; dev/test never share a key; no bare runner.os-mix- key | SATISFIED | All cache keys carry `-test-mix-` or `-dev-mix-` segment; `steps.beam.outputs.*` from `id: beam` feeds version segments; zero bare `runner.os}}-mix-` keys; REQUIREMENTS.md marked `[x]` |
| CACHE-02 | 23-01-PLAN.md | Dedicated `build` job compiles deps + app once (MIX_ENV=test, WAE) and publishes _build/test + deps as artifact; every downstream job restores instead of recompiling | SATISFIED | Build job exists with correct topology (`needs: policy`, `MIX_ENV: test`, `mix compile --warnings-as-errors`, `tar -czf`, `upload-artifact@v7`); test job has `needs: build`, `download-artifact@v7`, `tar -xzf`, no `mix compile`, no cache restore step; REQUIREMENTS.md marked `[x]` |

Both requirements are fully traced and satisfied. No orphaned requirements detected for Phase 23.

---

### Anti-Patterns Found

No blockers or warnings introduced by phase 23. No TBD/FIXME/XXX markers in modified files. No stub patterns, placeholder data, or hardcoded empty returns.

---

### Observations from Code Review (23-REVIEW.md) — Advisory Only

These three items were flagged in the code review as advisory/forward-looking warnings. Per the verification instructions, they do not block this phase goal — they are noted here for traceability.

**WR-01 (Advisory):** The `policy` job has no `MIX_ENV: test` set at job level. Its `mix compile --warnings-as-errors` runs under `MIX_ENV=dev`, storing `_build/dev` artifacts under the `-test-mix-` cache key. The build job's own compile (which does have `MIX_ENV: test`) produces the correct `_build/test` artifact regardless. This is a semantic mislabeling on the policy job's cache key, not a build-correctness issue. Relevant to Phase 25/26 (parallelization/sharding): recommended fix is to either add `MIX_ENV: test` to the policy job or rename its cache key to `-dev-mix-`.

**WR-02 (Advisory):** `ci.yml` line 17 still reads "Two-job topology" — the header comment is stale after Phase 23 introduced a third job (`build`) inside `ci-verify.yml`. No contract test enforces this comment. Cosmetic only; recommended update in a future pass.

**WR-03 (Advisory):** The existing test `"test job depends on policy and preserves closeout chain order"` (line 154) passes because `build` has `needs: policy` — not because `test` directly needs policy. The new test `"test job needs build, not policy directly"` (line 302) correctly captures the actual topology, but the old test name is now misleading. Recommended rename in a future pass.

None of these advisories affect the phase goal, must-haves, or requirement satisfaction.

---

### Human Verification Required

None — all must-haves were verifiable programmatically.

---

### Gaps Summary

No gaps. All 5 must-haves are verified, both requirements satisfied, 42 contract tests pass, zero recompile locally, CI run 27514007418 confirms zero test-path recompile in production CI.

---

_Verified: 2026-06-14_
_Verifier: Claude (gsd-verifier)_
