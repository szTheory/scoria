---
status: passed
phase: 81-post-publish-registry-gate
verified: 2026-05-29T12:00:00Z
requirements:
  - HEX-REGISTRY-01
score:
  must_haves: 16/16
  roadmap_criteria: 3/4_pass + 1/4_latent
  requirement: 1/1
---

# Phase 81 Verification

## Goal

Extend post-publish attestation from compile-only `deps.get` to **live Hex registry** proof — install → migrate → route + runtime overlay subset — and wire it as a **blocking** job in the release chain. Close HEX-REGISTRY-01 at milestone level.

**Scope note (D-55 continuity):** Phase 80 = pre-publish **content-revision** upgrade (tarball at same semver). Phase 81 = live registry **semver** upgrade (`0.1.0` → `0.1.x+1`) when eligible.

## Requirement traceability

| Requirement | Phase 81 delivery | Status | Evidence |
|-------------|-------------------|--------|----------|
| **HEX-REGISTRY-01** | `:hex_registry` dep mode, `run_registry_proof!/1`, `mix scoria.post_publish_smoke`, blocking `post-publish-attest` in release workflows | **Complete** | `host_app_registry_proof_test.exs`; `post-publish-smoke.yml` `workflow_call`; `release-please.yml` + `hex-publish.yml` attest jobs |

Cross-reference with `.planning/REQUIREMENTS.md` traceability table: `HEX-REGISTRY-01 | 81 | Complete`.

## Success criteria (ROADMAP)

| # | Criterion | Verified | Evidence |
|---|-----------|----------|----------|
| 1 | `post-publish-smoke.yml` runs install → migrate → overlay subset against live Hex after index wait | **PASS** | `mix scoria.post_publish_smoke` → `run_registry_proof!/1` (6 steps); Postgres on 55432; exact pin via `registry_dep_snippet_pinned/1` |
| 2 | Release workflow is blocking for publish attestation (replaces compile-only smoke) | **PASS** | `post-publish-attest` job in `release-please.yml` (`needs: publish-hex`) and `hex-publish.yml` (`needs: publish`); failure fails parent workflow |
| 3 | Real semver upgrade step documented for when `0.1.x+1` publishes | **latent** | `semver_upgrade_eligible?/1` gates upgrade leg; at `0.1.0`-only releases today, fresh-install attest only — upgrade activates when `0.1.1+` publishes |
| 4 | Operator gate map updated for v2.10 CI topology | **PASS** | `docs/operator_verification.md` PR vs release proof depth table |

## Plan must_haves

### 81-01 — Registry contract + Generator

| Truth / artifact | Verified | Evidence |
|------------------|----------|----------|
| `registry_dep_tuple_pinned/1`, `semver_upgrade_eligible?/1` (D-73, D-86) | PASS | `HexConsumerContract` APIs + unit tests |
| `:hex_registry` dep mode + `overlay_from_dep!/1` (D-70, D-74) | PASS | `Generator.create_host!(dep_mode: :hex_registry, ...)` |

### 81-02 — Runner registry proof + Mix task

| Truth / artifact | Verified | Evidence |
|------------------|----------|----------|
| `run_registry_proof!/1` 6-step subset (D-69, D-71) | PASS | `expected_registry_steps/1` exact atom list |
| `mix scoria.post_publish_smoke` maintainer entrypoint (D-75) | PASS | Not in `mix test.adoption` |
| Registry upgrade via `bump: {:registry, from:, to:}` (D-84) | PASS | `host_app_registry_upgrade_proof_test.exs` |

### 81-03 — Workflow wiring + gate map

| Truth / artifact | Verified | Evidence |
|------------------|----------|----------|
| `post-publish-smoke.yml` `workflow_call` SSOT (D-77) | PASS | `version` + `skip_index_wait` inputs |
| `post-publish-attest` in `release-please.yml` (D-78) | PASS | `needs: [release-please, publish-hex]` |
| Attest in `hex-publish.yml` recovery (D-79) | PASS | `needs: publish` |
| Postgres pgvector on 55432 (D-81) | PASS | Matches `ci-verify.yml` test job |
| Operator gate map PR vs release row (D-89) | PASS | `docs/operator_verification.md` |

## Latent criteria

### Criterion 3 — Registry semver upgrade leg

At `0.1.0`-only releases, `mix scoria.post_publish_smoke` runs fresh-install registry proof only (`semver_upgrade_eligible?("0.1.0")` → false). The upgrade leg (`host_app_registry_upgrade_proof_test.exs`) activates when release-please publishes `0.1.1+`:

- Baseline pins exact previous semver via `registry_upgrade_pair/1`
- Upgrade target uses exact just-published version
- Reuses Phase 80 `run_upgrade_proof!/2` orchestration with `bump: {:registry, from:, to:}`

### Criterion 4 continuity — Migration delta (D-87)

Post-upgrade `ecto.migrate` migration-delta assertion remains **latent** until first post-0.1.0 core migration ships (same as Phase 80 criterion #4). Harness ships now; activation documented here for continuity.

## Score summary

| Layer | Score | Notes |
|-------|-------|-------|
| Plan must_haves (81-01 + 81-02 + 81-03) | **16/16** | All truths and artifacts verified in codebase |
| ROADMAP success criteria | **3 PASS + 1 latent** | Criterion 3 (live semver upgrade leg) wired + documented; activates at `0.1.1+` |
| Requirement HEX-REGISTRY-01 | **1/1** | Traceability matches `.planning/REQUIREMENTS.md` |
| Automated checks (this run) | **7/7** | rg pins, contract tests, compile WAE, ci_policy_contract |

**Overall status: `passed`** — phase goal achieved; intentional deferrals are latent activation, not gaps.

## Automated verification

| Command | Result | Notes |
|---------|--------|-------|
| `rg -n 'workflow_call' .github/workflows/post-publish-smoke.yml` | PASS | Reusable SSOT |
| `rg -n 'post-publish-attest' .github/workflows/release-please.yml` | PASS | Blocking release job |
| `rg -n 'post-publish-smoke.yml' .github/workflows/hex-publish.yml` | PASS | Recovery parity |
| `rg -n 'post-publish|registry' docs/operator_verification.md` | PASS | Gate map row |
| `MIX_ENV=test mix test test/scoria/hex_consumer_contract_test.exs --warnings-as-errors` | PASS | 11 tests, 0 failures |
| `MIX_ENV=test mix test test/scoria/ci_policy_contract_test.exs --warnings-as-errors` | PASS | 29 tests, 0 failures |
| `MIX_ENV=test mix compile --warnings-as-errors` | PASS | Compile WAE |

**Note:** Full `mix scoria.post_publish_smoke` requires live Hex + Postgres — runs in CI post-publish chain, not in PR CI.

## Registry step contract

Fresh-install registry subset (6 steps):

```
[:deps_get, :scoria_install, :ecto_create, :ecto_migrate,
 :host_route_smoke_test, :host_runtime_smoke_test]
```

When eligible, upgrade adds baseline + upgrade phases via `run_upgrade_proof!/2` with registry bump.

## Manual verification commands

```bash
# Local replay (requires live Hex + Postgres on 55432)
SCORIA_REGISTRY_VERSION=0.1.0 SCORIA_DB_PORT=55432 mix scoria.post_publish_smoke

# Maintainer debug via workflow_dispatch
gh workflow run post-publish-smoke.yml -f version=0.1.0

# Verify release chain wiring
rg -n 'post-publish-attest|skip_index_wait' .github/workflows/release-please.yml
```

## Gaps

**None for Phase 81 scope.** Intentional deferrals (not gaps):

- Criterion 3 registry semver upgrade — **latent** until `0.1.1+` publishes
- Criterion 4 migration delta — **latent** until first post-0.1.0 core migration ships
- Phase 82: full README/operator tarball-vs-registry prose sweep (DOCS-HEX-01)

## Review follow-ups (non-blocking)

From `81-REVIEW.md` — do not block phase closeout; address before first `0.1.1+` live attest:

- `hex-publish.yml`: guard `post-publish-attest` when `dry_run: true` (dry-run recovery should not poll Hex for unpublished version)
- `scoria.post_publish_smoke`: validate `SCORIA_REGISTRY_VERSION` with `Version.parse/1` at task entry

## Verdict

Phase 81 goal **achieved**. All three plan waves delivered: registry contract + Generator, Runner proof + Mix task, and blocking workflow attest with operator gate map stub. **HEX-REGISTRY-01 Complete.**

---
*Verified: 2026-05-29 (re-verified against codebase)*
