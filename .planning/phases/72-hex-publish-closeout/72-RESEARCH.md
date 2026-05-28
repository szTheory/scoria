# Phase 72: Hex Publish Closeout — Research

**Researched:** 2026-05-28  
**Domain:** First public Hex publish (`0.1.0`), adopter-facing install flip, v2.7 milestone closeout  
**Confidence:** HIGH (Phase 71 infra landed; CONTEXT decisions locked)

## Summary

Phase 72 executes the first live Hex publish at semver `0.1.0` / git tag `v0.1.0`, closes Phase 71 gate-zero by requiring **green remote `ci-verify` on the publish commit**, enables stubbed `publish-hex` and `hex-publish` jobs, flips README + `package_surface_test` only after Hex API confirms `0.1.0`, removes one-time `release-as`, and writes v2.7 milestone audit artifacts.

**Primary recommendation:** Four-plan wave split (72-01 integration blockers → 72-02 publish → 72-03 adopter flip → 72-04 closeout). **Critical ordering:** README must not change until `curl` hex.pm release `0.1.0` returns 200 (D-72-11).

## Standard Stack

| Component | Choice | Why |
|-----------|--------|-----|
| Release automation | release-please-action@v4 + elixir type | Already configured; manifest `0.0.0` + `release-as: "0.1.0"` |
| CI bar | `ci-verify.yml` workflow_call | Scoria D-14 — full policy + Postgres closeout, not oarlock `mix test` only |
| Publish auth | `HEX_API_KEY` repo secret | szTheory standard; no Environment on first ship (D-72-32) |
| Recovery | `hex-publish.yml` workflow_dispatch | Only when tag exists and hex.pm version 404 |
| Verification ledger | `72-VERIFICATION.md` | URLs/SHAs never in operator guide (D-72-20) |

## Architecture Patterns

### `@version` module attribute (blocking)

```elixir
# mix.exs — required shape for publish workflows
@version "0.1.0"

def project do
  [
    version: @version,
    docs: docs(),  # source_ref: "v#{@version}"
    ...
  ]
end

defp docs do
  [source_ref: "v#{@version}", ...]
end
```

Current `version = "0.1.0"` + `docs(version)` breaks `grep '@version "'` in both publish workflows.

### Enable publish jobs (Phase 72 flip)

| Workflow | Job | Phase 71 | Phase 72 |
|----------|-----|----------|----------|
| `release-please.yml` | `publish-hex` | `if: false` | `if: release_created == 'true'` + uncomment dry-run/publish |
| `hex-publish.yml` | `publish` | `if: false` | `if: needs.verify.result == 'success'` + uncomment steps |

### Contract test co-flip (same PR as workflow enable)

`ci_policy_contract_test.exs` must flip:
- Phase 71: assert `if: false`, refute live `mix hex.publish --yes`
- Phase 72: assert enabled guards, dry-run + publish steps present
- Post-ship (72-03): manifest `0.1.0`, refute `release-as` pin

### Adopter flip gate

```
Release PR merge → tag v0.1.0 → publish-hex → hex.pm 0.1.0 exists
                                              ↓
                         THEN flip README + package_surface_test + badge
```

## Don't Hand-Roll

| Problem | Don't build | Use instead |
|---------|-------------|-------------|
| README flip before registry | "Docs first" | curl hex.pm API gate (D-72-11) |
| Tag-only publish | Manual tag without Release PR | Release Please reviewed merge |
| Laptop publish | Local `mix hex.publish` for 0.1.0 | CI publish job with ci-verify |
| Manifest pre-bump | Set manifest to 0.1.0 before publish | Keep `0.0.0` until Hex confirms (D-72-24) |
| `sync_release_summary` | Sigra-style job | Omit entirely (R-72-03) |

## Common Pitfalls

1. **Inline `version =` in mix.exs** — publish verify step fails even when semver correct (D-72-06).
2. **Merge Release PR before HEX_API_KEY + job enable** — tag without tarball (R-72-01).
3. **README Hex-primary before registry** — #1 integration-lib support failure (D-72-11).
4. **Remove `release-as` before Hex lists 0.1.0** — next Release PR wrong bump (D-72-18).
5. **Contract tests still assert `if: false`** after enabling jobs (D-72-22).
6. **Two uncommented `{:scoria, ...}` deps** — duplicate key in deps block (D-72-15).
7. **`### Bleeding edge` subsection** — elevates git to co-primary (R-72-07).

## Codebase Findings

| Finding | Location | Phase 72 action |
|---------|----------|-----------------|
| `version = "0.1.0"` not `@version` | `mix.exs:5` | Refactor in 72-01 |
| `publish-hex` / `publish` `if: false` | workflows | Enable in 72-01 |
| Publish steps commented | both workflows | Uncomment in 72-01 |
| Pre-publish README guard | `package_surface_test.exs:45-57` | Invert in 72-03 only |
| Manifest `0.0.0` | `.release-please-manifest.json` | Keep until publish; sync to `0.1.0` after |
| `release-as: "0.1.0"` | `release-please-config.json` | Remove post-flip in 72-03 |
| Hex name 404 attested | `71-VERIFICATION.md` | Optional re-check D-72-25 |
| Gate-zero waiver | Phase 71 | Non-waivable remote CI on publish commit (D-72-05) |

## szTheory Reference (oarlock)

- `@version` grep before publish — copy pattern from oarlock `release-please.yml`
- Secrets-only publish — no GitHub Environment on first ship
- Scoria difference: publish runs **full ci-verify**, not `mix test` only

## Validation Architecture

| Property | Value |
|----------|-------|
| Framework | ExUnit (Mix) |
| Quick run | `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs test/scoria/package_surface_test.exs` |
| CI parity | `MIX_ENV=test mix scoria.test.ci_trust` |
| Release preview | `MIX_ENV=dev mix scoria.release_preview` |
| Hex build smoke | `mix hex.build` |
| Estimated quick runtime | ~60–120s (contract tests) |

**Per-requirement verification:**

| REQ | Automated command | Manual |
|-----|-------------------|--------|
| HEX-01 | `ci_policy_contract_test.exs` (enabled publish + dry-run steps) | Release PR review 0.1.0; record CI URL in `72-VERIFICATION.md` |
| HEX-01 publish | — | `curl -fsS https://hex.pm/api/packages/scoria/releases/0.1.0`; publish workflow run URL |
| HEX-02 flip | `package_surface_test.exs` (Hex-primary assertions) | Smoke `mix deps.get` in clean project with `{:scoria, "~> 0.1", hex: :scoria}` |
| HEX-02 badge | `rg 'hexpm/v/scoria' README.md` | Visual badge on GitHub render |
| Closeout | — | `v2.7-MILESTONE-AUDIT.md`; REQUIREMENTS checkboxes |

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Publish without green ci-verify | Integration PR + attestation before Release PR merge (D-72-05) |
| Re-publish within ~1h window | Do not bump to 0.1.1 for retry (D-72-19); use recovery only if 404 |
| Manifest drift after recovery | Manual sync manifest to `0.1.0` (D-72-17) |
| Hex name squatted | Optional curl package 404 before publish (D-72-25) |

## Plan Structure (locked)

| Plan | Wave | Autonomous | Key deliverables |
|------|------|------------|------------------|
| 72-01 | 1 | false | @version, enable jobs, contract flip, integration PR CI attestation |
| 72-02 | 2 | false | Release PR → publish → 72-VERIFICATION.md |
| 72-03 | 3 | true* | README flip, operator appendix, release-as removal (*blocked on 72-02) |
| 72-04 | 4 | true | v2.7 audit + REQUIREMENTS |

*README.md excluded from 72-01 and 72-02 `files_modified` per D-72-37.*
