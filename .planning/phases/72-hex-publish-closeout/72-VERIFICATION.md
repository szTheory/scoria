---
phase: 72-hex-publish-closeout
status: in_progress
updated: 2026-05-28
---

# Phase 72 — Verification Ledger

## Integration PR (gate-zero closeout)

| Field | Value |
|-------|-------|
| Date | 2026-05-28 |
| PR URL | https://github.com/szTheory/scoria/pull/1 |
| PR head SHA | `06a0cbdfc4d881e388c3cf6f0784f39ed57bc758` |
| Merge commit SHA | `197c92939a7fa250febd7f18f7c505c109a17370` |
| CI run URL | https://github.com/szTheory/scoria/actions/runs/26598641841 |
| policy job | success |
| test job | success |
| Merged to main | 2026-05-28T20:32:41Z |

Phase 71 gate-zero waiver (`gate-zero-71`) is closed by this attestation on the integration merge path (D-72-05).

## Publish commit CI

*(pending — record green `ci-verify` on merge commit `197c929` after main CI completes)*

| Field | Value |
|-------|-------|
| CI run URL | *(pending)* |
| policy job | *(pending)* |
| test job | *(pending)* |

## Publish evidence

*(filled after Release PR merge, tag `v0.1.0`, and `publish-hex` — plan 72-02)*

| Field | Value |
|-------|-------|
| Release PR URL | *(pending)* |
| Tag | `v0.1.0` |
| Publish workflow run URL | *(pending)* |
| hex.pm `0.1.0` | *(pending)* |

## Adopter flip gate

*(filled in plan 72-03 — requires `curl -fsS https://hex.pm/api/packages/scoria/releases/0.1.0`)*

## Post-flip smoke

*(filled after `post-publish-smoke.yml` — plan 72-03)*
