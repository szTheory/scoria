# Phase 71 — Pattern Map

**Phase:** 71 — Release Infrastructure  
**Generated:** 2026-05-28

## Files to Create/Modify

| File | Role | Closest analog | Pattern to copy |
|------|------|----------------|-----------------|
| `CHANGELOG.md` | Adopter/maintainer release SSOT | `~/projects/oarlock/CHANGELOG.md` (if exists) + bootstrap skill template | Keep a Changelog + planning-vs-semver preamble; no `### Summary` |
| `.tool-versions` | Local/CI Erlang pin | `ci.yml` erlef/setup-beam versions | `erlang 27.x` + `elixir 1.19.x` |
| `.github/workflows/ci-verify.yml` | Reusable verify SSOT | Current `ci.yml` jobs block | Move `policy` + `test` jobs unchanged |
| `.github/workflows/ci.yml` | PR/push triggers | `lattice_stripe/.github/workflows/ci.yml` triggers | `release-please--**` + `workflow_dispatch` |
| `release-please-config.json` | Release automation config | `~/projects/oarlock/release-please-config.json` | Add bootstrap-sha, release-as, bump flags |
| `.release-please-manifest.json` | Released version ledger | bootstrap skill | `{ ".": "0.0.0" }` |
| `.github/workflows/release-please.yml` | Release PR + publish chain | `~/projects/oarlock/.github/workflows/release-please.yml` | Replace publish steps with `uses: ci-verify`; stub publish |
| `.github/workflows/hex-publish.yml` | Manual recovery | `~/projects/oarlock/.github/workflows/hex-publish.yml` | `verify` job via ci-verify; publish steps for Phase 72 |
| `docs/operator_verification.md` | Maintainer runbook | Phase 70 CI gate map section | New `## Hex release & recovery` after gate map |
| `test/scoria/ci_policy_contract_test.exs` | Executable CI contract | Existing tests | Read `ci-verify.yml`; assert `ci.yml` `uses:` |

## Excerpt: ci.yml after extraction

```yaml
name: CI

on:
  push:
    branches:
      - main
      - 'release-please--**'
  pull_request:
    branches:
      - main
  workflow_dispatch:

permissions:
  contents: read

jobs:
  verify:
    uses: ./.github/workflows/ci-verify.yml
```

## Excerpt: release-please verify job

```yaml
  verify:
    needs: release-please
    if: ${{ needs.release-please.outputs.release_created == 'true' }}
    uses: ./.github/workflows/ci-verify.yml
```

## PATTERN MAPPING COMPLETE
