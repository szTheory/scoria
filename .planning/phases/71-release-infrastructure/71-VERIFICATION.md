---
phase: 71-release-infrastructure
status: partial
updated: 2026-05-28
---

# Phase 71 Verification Ledger

## Hex name availability (D-21)

| Check | Result | Date |
|-------|--------|------|
| `curl -s -o /dev/null -w "%{http_code}" https://hex.pm/api/packages/scoria` | **404** (name available) | 2026-05-28 |
| `mix.exs` package name | `scoria` | 2026-05-28 |

## release-please bootstrap SHA

`release-please-config.json` → `bootstrap-sha`: `7a28797e1d72a90853125ba170b8a264ba9d3585`

(last commit before release-please config landed)

## Gate-zero remote CI attestation (D-22–D-24)

**Status:** bounded waiver (local `main` is 216+ commits ahead of `origin/main`; attestation deferred to integration PR / Phase 72 publish commit)

| Field | Value |
|-------|-------|
| `waiver_id` | `gate-zero-71` |
| `deferred_to` | Phase 72 publish commit |
| Local evidence | `MIX_ENV=test mix scoria.test.ci_trust` — exit 0 on 2026-05-28 (policy contracts, verification_lanes, ratchet hygiene, full inventory) |
| Audit reference | `.planning/milestones/v2.6-MILESTONE-AUDIT.md` — CI closeout contract satisfied at v2.6 closeout |
| Attestation scope | Pre-push tree uses `ci-verify.yml` SSOT; remote green URL pending integration PR |

**Preferred path (human follow-up):** Open integration PR with phase 71 tree → record green `CI` workflow run URL, commit SHA, `policy` + `test` job success here → remove waiver block.

## Phase 71 Release PR check (D-19)

- [ ] After release infra merges to `main`, confirm Release Please PR targets **`0.1.0`**
- [ ] Do **not** merge Release PR in Phase 71

## Workflow permissions (D-17)

- [ ] Run `gh api` workflow permissions command (documented in operator guide) before first Release Please run

## Local verification (automated)

| Command | Status |
|---------|--------|
| `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs test/scoria/changelog_contract_test.exs` | pass |
| `MIX_ENV=test mix scoria.test.ci_trust` | pass (2026-05-28) |
