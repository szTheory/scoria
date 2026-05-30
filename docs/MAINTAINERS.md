# Scoria Maintainer Guide

This guide is for **maintainers** — CI topology, release operations, warning ratchet commands, and installer contract proofs. Adopters should start with [operator verification](operator_verification.md) and [adoption lanes](adoption_lanes.md).

## CI gate map {#ci-gate-map-maintainers}

GitHub Actions runs two jobs in order: **`policy`** (no Postgres) first, then **`test`** (`needs: policy`, pgvector Postgres on port 55432) for canonical closeout. A **`ci-gate`** umbrella job fails if either lane fails — branch protection and release automerge require **CI / ci-gate**. Executable jobs live in `.github/workflows/ci-verify.yml` (reusable SSOT); `.github/workflows/ci.yml` is the PR entrypoint. Lane order is enforced by `Scoria.VerificationLanes` and `test/scoria/ci_policy_contract_test.exs`.

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
8. `mix test.connector --warnings-as-errors` — remote connector lane WAE after knowledge
9. `mix scoria.test.support_copilot` — advisory support-copilot gallery lane (not closeout)

**Verification lanes in PR CI**

| Lane | Command | In PR CI? | Notes |
|------|---------|-----------|-------|
| Default runtime | mix test.adoption | Yes | Tarball full overlay + content-revision upgrade |
| Runtime-to-handoff | mix test.runtime_to_handoff | Yes | Closeout lane |
| Semantic fast-path | mix test.semantic_fast_path --warnings-as-errors | Yes | Not in closeout order |
| Optional knowledge | mix test.knowledge --warnings-as-errors | Yes | After full-suite WAE |
| Remote connector | mix test.connector --warnings-as-errors | Yes | After knowledge WAE; not in closeout order |
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

### Required secrets

**`HEX_API_KEY`** — Hex publish from CI:

```bash
mix hex.user key generate scoria-ci --api
gh secret set HEX_API_KEY --repo szTheory/scoria
```

**`RELEASE_PLEASE_TOKEN`** — fine-grained PAT with Contents + Pull requests write. Required for routine hands-off releases: native `pull_request` CI on Release Please bot pushes and reliable GitHub release creation. Without it, release-branch CI may not refresh when the Release PR is stale.

```bash
gh secret set RELEASE_PLEASE_TOKEN --repo szTheory/scoria
```

### Normal patch release (fully automated)

1. Merge maintainer PRs to `main` using conventional commit prefixes (`fix:`, `docs:`, `chore:` for patch-eligible work).
2. Confirm GitHub Actions **CI / ci-gate** is green on `main`.
3. **Release Please** workflow opens or updates a patch Release PR.
4. **Bootstrap CI on Release PR** dispatches `ci.yml` only when a Release PR is open but was **not** just updated (`prs_created` false). Fresh Release Please updates run **pull_request** CI via `RELEASE_PLEASE_TOKEN` — no duplicate dispatch.
5. When **ci-gate** succeeds on the release branch, **Release PR Auto-Merge** merges the Release PR, dispatches **CI** on `main`, then **Release Please** (`GITHUB_TOKEN` merges do not emit push events).
6. **Release Please** tags the merge, waits for **ci-gate** on the tag SHA, then publishes to Hex automatically.
7. **Post-publish registry attest** runs `mix scoria.post_publish_smoke` (includes semver upgrade leg when `published_version > 0.1.0`).
8. Verify `mix hex.info scoria` lists the new version.

Routine patch releases require **no manual merge** of the Release PR.

### What to expect in Actions

| Workflow | When it runs | Skipped is normal when |
|----------|--------------|------------------------|
| **Release Please** | Every push to `main` or after automerge dispatch | Tag/Hex jobs skip until a Release PR merges (`release_created` is false). |
| **Release PR Auto-Merge** | After **CI** completes on `release-please--**` | CI on `main` finishes — only release-branch CI triggers merge. |
| **Bootstrap CI on Release PR** | After **Release Please** on `main` | Open Release PR exists but was not just updated (`prs_created` false). |
| **Release PR Auto-Merge** | `workflow_dispatch` | Manual retry when automation stalled after green ci-gate. |

A **skipped** Release PR Auto-Merge run after a maintainer push to `main` is expected, not a failed release.

### Avoiding duplicate CI on Release PRs

With `RELEASE_PLEASE_TOKEN`, Release Please PR updates trigger native `pull_request` CI. The bootstrap job **does not** `workflow_dispatch` CI when `prs_created` is true — duplicate runs would cancel each other and leave a stale failed `ci-gate` on the PR.

**Automerge** merges with `GITHUB_TOKEN`, which does **not** emit `push` events. **Release PR Auto-Merge** dispatches **CI** on `main`, then **Release Please**, so `gate-ci-green` can verify `ci-gate` before Hex publish.

### Manual recovery (`hex-publish.yml`)

Use only when Release Please or Hex publish did not complete:

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
| `.github/workflows/ci.yml` | PR / release-please triggers + ci-gate umbrella |
| `.github/workflows/release-please.yml` | Release PR + bootstrap CI + publish-hex + post-publish-attest |
| `.github/workflows/release-pr-automerge.yml` | Auto-merge release PR after ci-gate |
| `.github/workflows/post-publish-smoke.yml` | Registry attest |
| `.github/workflows/hex-publish.yml` | Manual recovery |

## Installer contract proofs

```bash
mix scoria.test.install_contract
```

Not a PR CI step or adoption closeout lane command.

## UAT automation contract

Producer-path integration tests prove runtime→PubSub→LiveView without test `send/2`. Merge-blocking orchestrator wiring: `mix test.semantic_fast_path --warnings-as-errors`. Gallery advisory lane: `mix scoria.test.support_copilot`.
