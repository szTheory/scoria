---
phase: 23-cache-correctness-build-once-job
plan: 01
subsystem: infra
tags: [github-actions, ci-cd, cache, artifacts, mix-compile, elixir, exunit]

# Dependency graph
requires:
  - phase: none
    provides: "Foundation for all downstream parallel/shard jobs in v3.1"
provides:
  - "env+version-scoped cache keys (OS + OTP + Elixir + MIX_ENV + mix.lock hash) — dev/test keys never collide"
  - "build job: compiles once under MIX_ENV=test WAE and uploads tarred _build/test + deps artifact"
  - "test job: downloads + untars artifact, performs zero recompile"
  - "Contract-test coverage: 4 new assertions pinning the build topology and cache-key invariants"
affects:
  - "Phase 24 (knowledge scope fix runs on the warm shared artifact)"
  - "Phase 25 (parallelization builds on policy -> build -> test topology)"
  - "Phase 26 (matrix sharding restores the same build artifact)"
  - "Phase 28 (velocity closeout measures warm-cache timing introduced here)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "build-once artifact pattern: MIX_ENV=test compile WAE once → tar -czf preserving mtimes → upload-artifact@v7; downstream jobs download + tar -xzf, no recompile"
    - "env-scoped cache keys: ${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-{test|dev}-mix-${{ hashFiles('**/mix.lock') }}"
    - "setup-beam version-file: use version-file: .tool-versions + version-type: strict + id: beam so outputs feed cache key interpolation"

key-files:
  created: []
  modified:
    - ".github/workflows/ci-verify.yml"
    - ".github/workflows/ci.yml"
    - "test/scoria/ci_policy_contract_test.exs"

key-decisions:
  - "D-01: ci-verify.yml is the SSOT for compile-once; ci.yml e2e job uses its own dev-mix cache (not the test artifact) — scoped separately to preserve dev/_build isolation"
  - "D-02: tar (not raw upload-artifact path) is mandatory to preserve mtimes; without it mix sees every file as stale and triggers a full recompile downstream"
  - "D-03: build job has no services: block (Postgres stays test-only) so the split_jobs/1 policy-side slice can assert refute policy_section =~ 'services:'"
  - "D-04: artifact retention-days: 1 + if-no-files-found: error minimises exposure window and hard-fails if the pack step is skipped"

patterns-established:
  - "Pattern: Build topology split — policy -> build -> test in ci-verify.yml; build job key must precede the literal \\n  test: boundary for split_jobs/1 to place it policy-side"
  - "Pattern: Contract-test for job topology — use split_jobs/1 split at \\n  test: and assert/refute =~ against named sections; no new helper functions needed"
  - "Pattern: setup-beam id: beam — always add id: beam when using version-file so steps.beam.outputs.{otp,elixir}-version are addressable in cache key"

requirements-completed: [CACHE-01, CACHE-02]

# Metrics
duration: multi-session (Tasks 1+2 prior executor; SC#3 checkpoint resolved by user; Task 3/SUMMARY this session)
completed: 2026-06-14
---

# Phase 23 Plan 01: Cache Correctness + Build-Once Job Summary

**MIX_ENV-scoped cache keys (OS+OTP+Elixir+MIX_ENV+mix.lock hash) replace bare runner.os-mix- keys, and a dedicated build job compiles once under MIX_ENV=test WAE and ships the tarred _build/test + deps artifact to all downstream jobs — proven zero recompile locally and in CI run 27514007418.**

## Performance

- **Duration:** Multi-session (prior executor: Tasks 1+2; this session: SC#3 proof + SUMMARY)
- **Started:** 2026-06-14
- **Completed:** 2026-06-14
- **Tasks:** 3 (including checkpoint verification Task 3)
- **Files modified:** 3 (.github/workflows/ci-verify.yml, .github/workflows/ci.yml, test/scoria/ci_policy_contract_test.exs)

## Accomplishments

- CACHE-01: All setup-beam steps switched to version-file: .tool-versions + version-type: strict + id: beam; all cache keys carry the MIX_ENV segment (test-mix- / dev-mix-); no bare runner.os-mix- key remains in either workflow file.
- CACHE-02 (SC#2): New build job inserted between policy and test in ci-verify.yml (needs: policy, MIX_ENV=test, no services:); compiles deps + app WAE once; packs with tar -czf build-test-env.tar.gz _build/test deps and uploads via upload-artifact@v7 (retention-days: 1, if-no-files-found: error). Test job changed to needs: build, restores via download-artifact@v7 + tar -xzf, removes the Restore deps cache step.
- SC#3 (make-or-break): Zero downstream recompile proven by both the local mtime simulation and CI log grep (see SC#3 Proofs section below).
- SC#4: 42 contract tests pass; no VerificationLanes command string moved; verification_lanes_test.exs is byte-identical to pre-phase state.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED (CACHE-01 test)** — `c33c45e` (test)
2. **Task 1 GREEN (CACHE-01 impl)** — `51c12fe` (feat)
3. **Task 2 RED (CACHE-02 tests)** — `534f586` (test)
4. **Task 2 GREEN (CACHE-02 impl)** — `5f606f1` (feat)
5. **Task 3 (SC#3 checkpoint — no code modified)** — resolved by user; proof captured in this SUMMARY
6. **Plan metadata** — this commit (docs)

## Files Created/Modified

- `.github/workflows/ci-verify.yml` — topology changed to policy -> build -> test; build job added; test job rewritten (needs: build, artifact restore path, no cache restore step); all setup-beam steps switched to version-file form + id: beam; all cache keys env-scoped
- `.github/workflows/ci.yml` — e2e job setup-beam switched to version-file form + id: beam; e2e cache key updated to dev-mix- scoped key
- `test/scoria/ci_policy_contract_test.exs` — 4 new test functions: "cache keys include MIX_ENV segment to prevent dev/test collision", "build job exists in policy-side slice, needs policy, and has no services block", "build job uploads artifact and test job downloads it", "test job needs build, not policy directly"; also: lazy-quantifier fix to lane_contract_step regex (deviation — see below)

## Final Job Topology

`ci-verify.yml` reusable workflow:

```
policy  (no services, no build dep)
  |
  v
build   (needs: policy, MIX_ENV=test, ubuntu-latest, no services:)
        steps: checkout → setup-beam (version-file, id: beam) → cache (test-mix key)
               → mix deps.get → mix compile --warnings-as-errors
               → tar -czf build-test-env.tar.gz _build/test deps
               → upload-artifact@v7 (name: build-test-env, retention-days: 1, if-no-files-found: error)
  |
  v
test    (needs: build, MIX_ENV=test, ubuntu-latest, services: postgres)
        steps: checkout → setup-beam (version-file, id: beam)
               → download-artifact@v7 (name: build-test-env) → tar -xzf build-test-env.tar.gz
               → mix deps.get (no-op safety net) → [lanes, including MIX_ENV=dev scoria.release_preview]
```

`ci.yml` e2e job: setup-beam uses version-file + id: beam; cache key is dev-mix- scoped.

## SC#3 Proofs — Zero Downstream Recompile

Both proofs are required per plan acceptance criteria. Both PASS.

### Proof 1 — Local mtime simulation: PASS

**Procedure (run from repo root):**
```
MIX_ENV=test mix deps.get && mix compile (--warnings-as-errors)
tar -czf /tmp/build-test-env.tar.gz _build/test deps
rm -rf _build/test deps
tar -xzf /tmp/build-test-env.tar.gz
MIX_ENV=test mix compile --warnings-as-errors 2>&1 | tee /tmp/recompile-proof.txt
grep -i Compiling /tmp/recompile-proof.txt
```

**Result:** `/tmp/recompile-proof.txt` contained 0 lines. `grep -i Compiling /tmp/recompile-proof.txt` produced no match.

**Conclusion: PASS — zero recompile after tar round-trip restores mtimes correctly.**

### Proof 2 — CI log proof: PASS

**CI run id:** 27514007418 (workflow "CI", reusable ci-verify.yml; topology: policy -> build -> test)

**Job conclusions:**
- verify/policy: success
- verify/build: success
- verify/test: success (job id 81319470639)
- e2e: success
- ci-gate: success

**Grep command (plan-specified):**
```
gh run view 27514007418 --log --job 81319470639 | grep -A5 "Unpack compiled artifact" | grep -i Compiling
```

**Result:** NO output — the grep found no Compiling lines in the test job after the unpack step.

**Attribution detail:** All 59 `Compiling N files` lines appearing in the test job are confined to the `MIX_ENV=dev mix scoria.release_preview` lane. This is expected by design: the artifact is `_build/test + deps` only; the dev release_preview keeps its own dev compile. Zero `Compiling` lines appear in any MIX_ENV=test lane after the artifact restore. SC#3 holds.

**Conclusion: PASS — test job restores artifact and performs zero test recompile in CI.**

## Decisions Made

- Tar (not raw upload-artifact path glob) is mandatory to preserve `_build/` mtimes. Without tar, GitHub Actions upload strips mtimes and Mix sees every .beam as stale, triggering a full recompile downstream. This is the mtime landmine documented in 23-RESEARCH.md.
- The `build` job has no `services:` block. Postgres stays test-only. This keeps `refute policy_section =~ "services:"` green in the contract tests.
- `retention-days: 1` on the artifact minimises the post-run exposure window for the compiled BEAM (T-23-01 mitigation).
- `if-no-files-found: error` on upload-artifact hard-fails CI if the pack step silently produces nothing.
- The `build:` key must byte-position before `\n  test:` in ci-verify.yml so `split_jobs/1` places the build job in the policy-side slice and the test assertions target the correct section.
- No `mix compile` step remains in the test job path (replaced entirely by the artifact restore path).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Lazy-quantifier fix to lane_contract_step regex in ci_policy_contract_test.exs**
- **Found during:** Task 2 (CACHE-02 contract assertion implementation)
- **Issue:** The `lane_contract_step/2` test helper used the regex `(?:\s+.+\n)+` (greedy quantifier). Once the build job body followed the lane-contract step in the policy_section, the greedy `+` over-matched and captured content from the build job, causing false-positive failures on contract assertions that should have cleanly bounded their step match.
- **Fix:** Changed quantifier to `(?:\s+.+\n)+?` (lazy). The lazy form matches the minimal number of continuation lines, stopping at the first step boundary. No production code changed; only the test helper regex was updated.
- **Files modified:** `test/scoria/ci_policy_contract_test.exs`
- **Verification:** 42 contract tests pass with 0 failures after fix; the failing assertions in Task 2 RED became GREEN with the impl commit.
- **Committed in:** `5f606f1` (feat(23-01): CACHE-02 — build-once job + artifact restore + 3 contract assertions)

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug — regex over-match in test helper)
**Impact on plan:** The fix was necessary for test correctness; it tightened an existing regex to match its intended scope. No scope creep; no production code changed.

## SC#4 Confirmation — No VerificationLanes Byte-Order String Moved

`git diff test/scoria/verification_lanes_test.exs` is empty — the file is byte-identical to its pre-phase state.

No `VerificationLanes` command string was moved, renamed, or modified in any file (`lib/` or `test/`). The `verification_lanes_test.exs` and `ci_policy_contract_test.exs` byte-order lane contract remains fully intact.

Final confirmation: `SCORIA_LANE_CONTRACT_ONLY=true MIX_ENV=test mix test --no-start --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs` → **42 tests, 0 failures** (verified in this session).

## Success Criteria → Evidence Mapping

| Criterion | Status | Evidence |
|-----------|--------|----------|
| CACHE-01: cache keys scoped OS+OTP+Elixir+MIX_ENV+mix.lock; dev/test never share a key; no bare runner.os-mix- key | PASS | `grep -v '^#' ci-verify.yml ci.yml \| grep -c 'runner.os }}-mix-'` → 0; both files contain -test-mix- / -dev-mix- in key: lines; setup-beam uses version-file + id: beam in all jobs |
| CACHE-02 (SC#2): build job runs mix deps.get && mix compile WAE (MIX_ENV=test) once, publishes tarred artifact | PASS | ci-verify.yml build: block contains needs: policy, mix compile --warnings-as-errors, tar -czf build-test-env.tar.gz _build/test deps, upload-artifact@v7; contract assertion "build job exists in policy-side slice..." green |
| SC#3: test job restores artifact + zero recompile — proven by local sim AND CI log grep | PASS | Proof 1: /tmp/recompile-proof.txt = 0 lines; Proof 2: CI run 27514007418, job 81319470639 — grep -A5 "Unpack compiled artifact" \| grep -i Compiling → no output |
| SC#4: contract tests green; no command string moved out of byte-order; build job lands policy-side, no services: | PASS | 42 tests, 0 failures; git diff verification_lanes_test.exs empty; build: precedes \n  test: in ci-verify.yml; refute policy_section =~ "services:" passes |

## Issues Encountered

None beyond the auto-fixed lazy-quantifier deviation documented above.

## User Setup Required

None — no external service configuration required. All changes are GitHub Actions YAML and ExUnit test files.

## Known Stubs

None — no placeholder data, stub values, or TODO markers introduced in this plan.

## Next Phase Readiness

- Phase 24 (knowledge lane scope fix) can begin immediately. It depends on Phase 23's build artifact being available in ci-verify.yml, which is now shipped.
- The `build` job in ci-verify.yml is the SSOT compile step for all downstream consumers (PR verify, release-please verify, hex-publish recovery).
- No blockers or concerns.

## Self-Check

- [x] `.planning/phases/23-cache-correctness-build-once-job/23-01-SUMMARY.md` — this file, written via Write tool
- [x] Commit `c33c45e` exists (`git log` verified)
- [x] Commit `51c12fe` exists (`git log` verified)
- [x] Commit `534f586` exists (`git log` verified)
- [x] Commit `5f606f1` exists (`git log` verified)
- [x] Contract suite: 42 tests, 0 failures (re-run in this session)

## Self-Check: PASSED

---
*Phase: 23-cache-correctness-build-once-job*
*Completed: 2026-06-14*
