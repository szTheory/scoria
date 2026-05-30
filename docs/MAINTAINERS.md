# Scoria Maintainer Guide

This guide is for **maintainers** — CI topology, release operations, warning ratchet commands, and installer contract proofs. Adopters should start with [operator verification](operator_verification.md) and [adoption lanes](adoption_lanes.md).

## CI gate map {#ci-gate-map-maintainers}

GitHub Actions runs two jobs in order: **`policy`** (no Postgres) first, then **`test`** (`needs: policy`, pgvector Postgres on port 55432) for canonical closeout. Executable jobs live in `.github/workflows/ci-verify.yml` (reusable SSOT); `.github/workflows/ci.yml` is the PR entrypoint. Lane order is enforced by `Scoria.VerificationLanes` and `test/scoria/ci_policy_contract_test.exs`.

**Policy job (fail cheap, no database):**

1. `mix scoria.warning_baseline.check` — baseline expiry before compile
2. `mix scoria.warning_inventory.check_baseline` — committed inventory JSON must keep `clusters` empty
3. `mix compile --warnings-as-errors` — compile WAE
4. Lane-contract WAE: `mix test --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs`

**Test job closeout (Postgres on 55432):**

1. `MIX_ENV=dev mix scoria.release_preview` — release/docs lane (dev only)
2. `mix ecto.create` + `mix ecto.migrate`
3. `mix test.adoption` → `mix test.runtime_to_handoff` — behavioral closeout lanes
4. `mix test.semantic_fast_path --warnings-as-errors` — semantic lane WAE after closeout
5. Ratchet hygiene: `mix test --warnings-as-errors test/scoria/warning_inventory/tmp_preflight_test.exs`
6. `mix test --warnings-as-errors` — full-suite WAE
7. `mix test.knowledge --warnings-as-errors` — optional knowledge lane WAE
8. `mix scoria.test.support_copilot` — advisory support-copilot gallery lane (not closeout)

**Verification lanes in PR CI**

| Lane | Command | In PR CI? | Notes |
|------|---------|-----------|-------|
| Default runtime | mix test.adoption | Yes | Tarball full overlay + content-revision upgrade |
| Runtime-to-handoff | mix test.runtime_to_handoff | Yes | Closeout lane |
| Semantic fast-path | mix test.semantic_fast_path --warnings-as-errors | Yes | Not in closeout order |
| Optional knowledge | mix test.knowledge --warnings-as-errors | Yes | After full-suite WAE |
| Support copilot gallery | mix scoria.test.support_copilot | Yes | Advisory; not in closeout order |

**PR vs release proof depth**

| Path | Proof depth | Command / workflow | Blocking? |
|------|-------------|-------------------|-----------|
| **PR CI** | Tarball consumer full overlay + content-revision upgrade | `mix test.adoption` via `ci-verify.yml` | Yes — merge gate |
| **Release** | Live Hex registry + conditional semver upgrade | `mix scoria.post_publish_smoke` after `publish-hex` | Yes — release fails if attest fails |

- **Content-revision upgrade:** `scoria-0.1.0-unpack` fixture → HEAD tarball
- **Registry semver upgrade:** baseline exact previous → target just-published when `published_version > 0.1.0`

**Local parity:** set `SCORIA_DB_PORT=55432` for the test job database; use `MIX_ENV=dev` only for `mix scoria.release_preview`. Run `mix scoria.test.ci_trust` for maintainer trust bundle parity.

**Ratchet is maintainer-only:** `mix scoria.warning_ratchet.test` and `mix scoria.warning_ratchet.check` are debugger commands — not CI steps.

**When CI fails, run the matching maintainer command next:**

- Policy: `warning_baseline.check` failed → `mix scoria.warning_baseline.check` locally
- Policy: `warning_inventory.check_baseline` failed → refresh inventory in a dedicated PR
- Policy: compile WAE failed → `mix compile --warnings-as-errors`
- Policy: lane-contract WAE failed → `mix test --warnings-as-errors test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs`
- Test: adoption or runtime_to_handoff failed → `SCORIA_DB_PORT=55432 mix test.adoption` or `mix test.runtime_to_handoff`
- Test: full-suite WAE failed → `SCORIA_DB_PORT=55432 mix test --warnings-as-errors`

## Hex release & recovery {#hex-release--recovery-maintainers}

Maintainer-only release operations. Adopter install guidance stays in README and [CHANGELOG.md](../CHANGELOG.md).

### Version namespaces

- **Hex / git:** semver such as `0.1.0`, `v0.1.0`, `{:scoria, "~> 0.1"}` on [hex.pm](https://hex.pm/packages/scoria)
- **Planning:** internal `v2.x` milestone labels in the repository are delivery tranches — not a second install axis

### HEX_API_KEY

```bash
mix hex.user key generate scoria-ci --api
gh secret set HEX_API_KEY --repo szTheory/scoria
```

### Default path (Release Please)

1. Push conventional commits to `main` → release-please opens/updates a Release PR
2. Confirm CI is green on the `release-please--**` branch
3. Merge the Release PR → tag → `publish-hex` with `HEX_API_KEY`
4. Post-publish attest runs `mix scoria.post_publish_smoke`

### Manual recovery (`hex-publish.yml`)

When `publish-hex` failed but the git tag exists and the version is not on hex.pm:

```bash
gh workflow run hex-publish.yml \
  --ref v0.1.1 \
  -f tag=v0.1.1 \
  -f release_version=0.1.1
```

**Do not** re-publish a version already listed on hex.pm.

### Post-publish registry checks

```bash
curl -fsS https://hex.pm/api/packages/scoria/releases/0.1.1
mix scoria.post_publish_smoke
```

When `published_version > 0.1.0`, registry attest also runs the semver upgrade leg.

### Executable SSOT

| Workflow | Role |
|----------|------|
| `.github/workflows/ci-verify.yml` | Reusable policy → test verify bar |
| `.github/workflows/ci.yml` | PR / release-please triggers |
| `.github/workflows/release-please.yml` | Release PR + publish-hex + post-publish-attest |
| `.github/workflows/post-publish-smoke.yml` | Registry attest |
| `.github/workflows/hex-publish.yml` | Manual recovery |

## Installer contract proofs

```bash
mix scoria.test.install_contract
```

Not a PR CI step or adoption closeout lane command.

## UAT automation contract

Producer-path integration tests prove runtime→PubSub→LiveView without test `send/2`. Merge-blocking orchestrator wiring: `mix test.semantic_fast_path --warnings-as-errors`. Gallery advisory lane: `mix scoria.test.support_copilot`.
