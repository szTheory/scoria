# Phase 71: Release Infrastructure — Research

**Researched:** 2026-05-28  
**Domain:** szTheory Elixir Hex release automation (release-please + reusable CI verify)  
**Confidence:** HIGH for CI topology and bootstrap gotchas; MEDIUM for bootstrap-sha at execution time

## Summary

Phase 71 lands release **infrastructure** without publishing: hand-authored `CHANGELOG.md` for `0.1.0`, `.tool-versions` aligned to CI (OTP 27 / Elixir 1.19), release-please config with manifest `0.0.0` + one-time `release-as: "0.1.0"`, reusable `ci-verify.yml` extracted from today's two-job `ci.yml`, and release/hex workflows that call the same verify bar as PR CI. Oarlock is the workflow shape reference but its publish job runs `mix test` only — Scoria must keep policy + Postgres closeout (CONTEXT D-14).

**Primary recommendation:** Four-plan wave sequence — bootstrap docs/pins → extract CI → wire release-please + stubbed publish → maintainer runbook + gate-zero verification artifact.

## Standard Stack

| Component | Choice | Why |
|-----------|--------|-----|
| Release automation | googleapis/release-please-action@v4 | szTheory standard; elixir release-type |
| CI reuse | `workflow_call` in `ci-verify.yml` | Single SSOT for PR, release branch, tag verify |
| Version pin | `.tool-versions` + erlef/setup-beam in CI | Matches existing ci.yml OTP 27 / Elixir 1.19 |
| Recovery | `hex-publish.yml` workflow_dispatch | Manual path when automation fails (Phase 72 live) |
| Docs SSOT | `docs/operator_verification.md` | Phase 70 pattern — not README for maintainer depth |

## Architecture Patterns

### Reusable CI verify

```yaml
# .github/workflows/ci-verify.yml
on:
  workflow_call:
jobs:
  policy: ...
  test:
    needs: policy
    services:
      postgres: ...
```

```yaml
# .github/workflows/ci.yml
jobs:
  verify:
    uses: ./.github/workflows/ci-verify.yml
```

`test/scoria/ci_policy_contract_test.exs` must assert lane order in **`ci-verify.yml`** (or via `uses:` + file read) — not only monolithic `ci.yml`.

### Release Please (first ship)

| Setting | Value | Source |
|---------|-------|--------|
| Manifest `.` | `0.0.0` | Gotcha #4 — not `0.1.0` pre-publish |
| `release-as` | `"0.1.0"` | Gotcha #5 — remove in Phase 72 |
| `bootstrap-sha` | Full SHA of last commit before release-infra merge | release-please elixir bootstrap |
| `bump-minor-pre-major` | `false` | CONTEXT D-16 |
| No `sync_release_summary` | Omit job entirely | Gotcha #6 (sigra-only) |

### Publish job (Phase 71)

Land `publish-hex` job structure with `if: false` (or equivalent) so Phase 72 only flips the guard and sets `HEX_API_KEY` — no `mix hex.publish` to registry in Phase 71.

## Don't Hand-Roll

| Problem | Don't build | Use instead |
|---------|-------------|-------------|
| Version bumping | Custom semver scripts | release-please conventional commits |
| Duplicate CI YAML | Copy/paste policy+test into release workflow | `workflow_call` to `ci-verify.yml` |
| Release notes from planning | Auto-dump MILESTONES into CHANGELOG Added | Hand-write capability bullets; traceability table separate |
| Minimal publish test bar | `mix test` only on tag | Full policy + test jobs (Scoria D-14) |

## Common Pitfalls

1. **Manifest at 0.1.0** → Release PR targets 0.1.1+ — use `0.0.0` baseline.
2. **Missing workflow permissions** → Release PR never opens — document `gh api` settings (D-17).
3. **GITHUB_TOKEN on release branches** → CI may not run — extend `ci.yml` triggers to `release-please--**` + `workflow_dispatch` (D-12).
4. **`### Summary` under version headings** — breaks sigra-style release body scripts; Scoria must not add (D-06).
5. **Inventing v2.2 in traceability** — MILESTONES has v2.1, v2.3, v2.4, v2.5, v2.6 only (D-05).
6. **Blocking Phase 71 on origin/main green** — prefer integration PR attestation or bounded waiver (D-22–D-24).

## Codebase Findings

| Finding | Location | Implication |
|---------|----------|-------------|
| Two-job CI with Postgres 55432 | `.github/workflows/ci.yml` | Extract verbatim to `ci-verify.yml` |
| Executable order SSOT | `Scoria.VerificationLanes`, `ci_policy_contract_test.exs` | Extend contracts for reusable workflow |
| `mix.exs` version `0.1.0`, no CHANGELOG in package files | `mix.exs` `package/0` | Add `CHANGELOG.md` to files list; optional `name: "scoria"` |
| No `.tool-versions` | repo root | Create OTP 27 / Elixir 1.19 |
| Hex name available | `GET hex.pm/api/packages/scoria` → 404 | Record in `71-VERIFICATION.md` |
| Operator CI gate map exists | `docs/operator_verification.md` | Insert Hex section **after** gate map (D-26) |

## szTheory Reference Diffs (Scoria vs oarlock)

| Area | oarlock | Scoria Phase 71 |
|------|---------|-----------------|
| Publish verify | `mix test` only | `ci-verify.yml` (policy + full closeout) |
| OTP pin | `.tool-versions` strict | OTP 27 / Elixir 1.19 (not sigra 28) |
| Manifest | May show shipped version | `0.0.0` until first Hex publish |
| release-please publish | Live hex publish | Stubbed/disabled in Phase 71 |

## Validation Architecture

| Property | Value |
|----------|-------|
| Framework | ExUnit (Mix) |
| Quick run | `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs` |
| CI parity | `MIX_ENV=test mix scoria.test.ci_trust` |
| Release preview | `MIX_ENV=dev mix scoria.release_preview` |
| Estimated quick runtime | ~60–120s (policy contract tests) |

**Per-requirement verification:**

| REQ | Automated command | Manual |
|-----|-------------------|--------|
| HEX-01 (prep) | `mix test test/scoria/ci_policy_contract_test.exs` (ci-verify + workflow uses) | Confirm Release PR targets 0.1.0 on GitHub (do not merge) |
| HEX-02 (prep) | Optional: `mix test test/scoria/changelog_contract_test.exs` if added | Read CHANGELOG preamble + Added bullets |
| Gate-zero | — | Record CI run URL in `71-VERIFICATION.md` or waiver |

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Contract tests still read only `ci.yml` jobs | Update `split_jobs` / helpers to target `ci-verify.yml` |
| Accidental Hex publish | `publish-hex` job `if: false` until Phase 72 |
| bootstrap-sha drift | Executor sets SHA at commit time before first release-please run |
| Release PR CI flake | Document `RELEASE_PLEASE_TOKEN`; optional bootstrap job deferred |

## RESEARCH COMPLETE
