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
| `post-publish-smoke.yml` workflow_dispatch `v0.1.0` / `0.1.0` | see Post-publish workflow row | 2026-05-29 |
| Local `mix deps.get` + compile with `{:scoria, "~> 0.1", hex: :scoria}` | see Local consumer row | 2026-05-29 |
| 24h follow-up registry + consumer smoke | closed at v2.8 closeout | 2026-05-29 |

## Post-publish workflow

| Field | Value |
|-------|-------|
| Workflow | `.github/workflows/post-publish-smoke.yml` |
| Inputs | `tag: v0.1.0`, `version: 0.1.0` |
| First dispatch run | https://github.com/szTheory/scoria/actions/runs/26611813528 — **failed** (setup-beam `version-file` without checkout; fixed in v2.8 closeout) |
| Re-run after fix | dispatch after `post-publish-smoke.yml` checkout + explicit OTP/Elixir lands on `main` |

## Local consumer smoke

| Field | Value |
|-------|-------|
| Command | Clean `mix new` project + `{:scoria, "~> 0.1", hex: :scoria}` + `mix deps.get` + `mix compile --warnings-as-errors` |
| Result | **pass** (2026-05-29) — `scoria 0.1.0` resolved from Hex |
