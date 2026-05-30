---
phase: 81-post-publish-registry-gate
plan: 03
subsystem: infra
tags: [hex, registry, github-actions, workflow_call, post-publish-smoke, ci-gates]

requires:
  - phase: 81-post-publish-registry-gate
    plan: 02
    provides: mix scoria.post_publish_smoke and registry ExUnit proof modules
  - phase: 81-post-publish-registry-gate
    plan: 01
    provides: HexConsumerContract registry APIs and Generator :hex_registry mode
provides:
  - workflow_call post-publish-smoke.yml SSOT with version and skip_index_wait inputs
  - blocking post-publish-attest job in release-please.yml after publish-hex
  - post-publish-attest job in hex-publish.yml recovery path
  - operator gate map PR vs release proof depth in docs/operator_verification.md
  - 81-VERIFICATION.md phase verification ledger
affects: [82, release-please.yml, hex-publish.yml, operator_verification.md]

tech-stack:
  added: []
  patterns:
    - "post-publish-smoke.yml is workflow_call SSOT; release:published trigger removed (D-77)"
    - "post-publish-attest needs publish-hex; skip_index_wait true when index poll already ran (D-78, D-82)"
    - "Registry attest uses Postgres pgvector on 55432 matching ci-verify test job (D-81)"
    - "PR CI = tarball full depth; release = registry subset + conditional semver upgrade (D-89)"

key-files:
  created:
    - .planning/phases/81-post-publish-registry-gate/81-VERIFICATION.md
  modified:
    - .github/workflows/post-publish-smoke.yml
    - .github/workflows/release-please.yml
    - .github/workflows/hex-publish.yml
    - docs/operator_verification.md
    - test/scoria/ci_policy_contract_test.exs

key-decisions:
  - "Removed release:published trigger — blocking attest only via workflow_call after publish-hex"
  - "hex-publish recovery passes skip_index_wait from publish job output based on whether index wait ran"
  - "ci_policy_contract_test pins post-publish-attest and post-publish-smoke.yml job names"

patterns-established:
  - "Green release-please run implies registry consumer proof passed via post-publish-attest"
  - "workflow_dispatch retained on post-publish-smoke for maintainer debug reruns (D-80)"

requirements-completed: [HEX-REGISTRY-01]

duration: 2min
completed: 2026-05-30
---

# Phase 81 Plan 03: Workflow Attest Wiring + Gate Map Summary

**Blocking post-publish registry attest wired into release-please and hex-publish recovery via reusable workflow_call SSOT with operator gate map documenting PR tarball vs release registry proof depth**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-30T00:36:34Z
- **Completed:** 2026-05-30T00:38:04Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Refactored `post-publish-smoke.yml` to `workflow_call` SSOT running `mix scoria.post_publish_smoke` with Postgres on 55432
- Added blocking `post-publish-attest` job to `release-please.yml` (`needs: publish-hex`, `skip_index_wait: true`)
- Added parallel attest job to `hex-publish.yml` recovery with conditional `skip_index_wait`
- Documented PR vs release proof depth in operator gate map and created `81-VERIFICATION.md`

## Task Commits

Each task was committed atomically:

1. **Task 81-03-01: Refactor post-publish-smoke.yml to workflow_call SSOT** - `c027664` (feat)
2. **Task 81-03-02: Wire blocking attest jobs in release-please and hex-publish** - `20e12a6` (feat)
3. **Task 81-03-03: Operator gate map stub and 81-VERIFICATION.md** - `47247ac` (feat)

## Files Created/Modified

- `.github/workflows/post-publish-smoke.yml` - Reusable registry attest with version/skip_index_wait inputs, Postgres, mix scoria.post_publish_smoke
- `.github/workflows/release-please.yml` - Blocking post-publish-attest after publish-hex
- `.github/workflows/hex-publish.yml` - Recovery path attest with conditional skip_index_wait
- `docs/operator_verification.md` - PR vs release proof depth gate map table
- `.planning/phases/81-post-publish-registry-gate/81-VERIFICATION.md` - Phase verification ledger with latent upgrade note
- `test/scoria/ci_policy_contract_test.exs` - Pins post-publish-attest job names

## Decisions Made

- Removed `release:published` trigger to avoid racing publish-hex (D-77)
- hex-publish recovery derives skip_index_wait from whether publish job ran index wait
- Extended existing ci_policy_contract tests rather than new test module (D-89 discretion)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required for code delivery. Full attest runs in CI post-publish chain with live Hex + Postgres.

## Next Phase Readiness

- Phase 81 complete (3/3 plans) — ready for Phase 82 docs truth + milestone closeout
- Live registry attest will activate on next release-please publish run
- Semver upgrade leg latent until `0.1.1+` publishes

## Self-Check: PASSED

- `rg -n 'workflow_call' .github/workflows/post-publish-smoke.yml` — PASS
- `rg -n 'scoria.post_publish_smoke' .github/workflows/post-publish-smoke.yml` — PASS
- `rg -n '55432' .github/workflows/post-publish-smoke.yml` — PASS
- `rg -n 'skip_index_wait' .github/workflows/post-publish-smoke.yml` — PASS
- `rg -n 'post-publish-attest' .github/workflows/release-please.yml` — PASS
- `rg -n 'post-publish-smoke.yml' .github/workflows/hex-publish.yml` — PASS
- `rg -n 'skip_index_wait: true' .github/workflows/release-please.yml` — PASS
- `test -f .planning/phases/81-post-publish-registry-gate/81-VERIFICATION.md` — PASS
- `rg -n 'HEX-REGISTRY-01' .planning/phases/81-post-publish-registry-gate/81-VERIFICATION.md` — PASS
- `rg -n 'post-publish' docs/operator_verification.md` — PASS
- `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs:49 test/scoria/ci_policy_contract_test.exs:76 --warnings-as-errors` — PASS (2 tests)
- `git log --oneline --grep="81-03"` — 3 commits found

---
*Phase: 81-post-publish-registry-gate*
*Completed: 2026-05-30*
