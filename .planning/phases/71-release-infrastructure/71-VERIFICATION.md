---
phase: 71-release-infrastructure
status: passed
updated: 2026-05-28
score: 5/5
gate_zero_approved: 2026-05-28
---

# Phase 71 Goal Verification

## Must-haves

| Criterion | Status | Evidence |
|-----------|--------|----------|
| CHANGELOG with preamble and [0.1.0] | pass | `CHANGELOG.md`, `changelog_contract_test.exs` |
| release-please + ci-verify on release | pass | `release-please.yml`, `release-please-config.json` |
| hex-publish recovery documented | pass | `hex-publish.yml`, operator guide Hex section |
| Hex name 404 + .tool-versions | pass | curl 404; `.tool-versions` OTP 27 / Elixir 1.19 |
| Gate-zero attestation or waiver | pass (waiver approved) | `waiver_id: gate-zero-71`; human approved 2026-05-28 |

## Automated checks

- `mix test` contract files: pass (23 tests)
- `mix scoria.test.ci_trust`: pass (2026-05-28)
- No live `mix hex.publish` in workflows (publish jobs `if: false`)

## Human verification

1. Open integration PR and record green `CI` workflow URL in this file (replaces gate-zero waiver).
2. After merge to `main`, confirm Release Please PR targets `0.1.0` (do not merge until Phase 72).
3. Run GitHub workflow permissions `gh api` command before first Release Please run.

## Hex name availability (D-21)

| Check | Result | Date |
|-------|--------|------|
| `curl` hex.pm/packages/scoria | **404** | 2026-05-28 |
| `mix.exs` package name | `scoria` | 2026-05-28 |

## release-please bootstrap SHA

`7a28797e1d72a90853125ba170b8a264ba9d3585`

## Gate-zero waiver

| Field | Value |
|-------|-------|
| `waiver_id` | `gate-zero-71` |
| `status` | **approved** (2026-05-28) |
| `deferred_to` | Phase 72 publish commit (remote CI URL required at publish) |
| Local evidence | `mix scoria.test.ci_trust` exit 0 (2026-05-28) |
| Audit reference | `.planning/milestones/v2.6-MILESTONE-AUDIT.md` |

Remote CI URL on integration PR remains recommended before Phase 72 but does not block Phase 71 closeout.
