---
phase: 72-hex-publish-closeout
status: passed
updated: 2026-05-29
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

| Field | Value |
|-------|-------|
| Date | 2026-05-28 |
| Release merge SHA | `49f2d60018c4c79fbc09969116526c48454a8e84` |
| CI run URL | https://github.com/szTheory/scoria/actions/runs/26610277846 |
| policy job | success |
| test job | success |

## Publish evidence

| Field | Value |
|-------|-------|
| Date | 2026-05-29 |
| Release PR URL | https://github.com/szTheory/scoria/pull/2 |
| GitHub Release | https://github.com/szTheory/scoria/releases/tag/v0.1.0 |
| Tag | `v0.1.0` |
| Publish workflow run URL | https://github.com/szTheory/scoria/actions/runs/26610277846 |
| Publish job | `Publish to Hex.pm` — success |
| hex.pm `0.1.0` | https://hex.pm/api/packages/scoria/releases/0.1.0 — 200 OK |

## Adopter flip gate

| Check | Result | Date |
|-------|--------|------|
| `curl -fsS https://hex.pm/api/packages/scoria/releases/0.1.0` | 200 OK | 2026-05-29 |

## Post-flip smoke

| Check | Result | Date |
|-------|--------|------|
| Local `mix deps.get` + compile with `{:scoria, "~> 0.1", hex: :scoria}` | pending maintainer | 2026-05-29 |
| 24h follow-up registry + consumer smoke | pending | — |
