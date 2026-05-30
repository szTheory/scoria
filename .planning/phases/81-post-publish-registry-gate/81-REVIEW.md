---
status: issues
phase: 81-post-publish-registry-gate
reviewed: 2026-05-29
---

# Phase 81 Code Review

Review of post-publish registry gate source: exact-pinned Hex consumer contract, `:hex_registry` host proof generator/runner, maintainer Mix task, and CI workflow wiring.

## Summary

Core release attest path is well structured — exact pins are isolated from adopter `~> 0.1` policy, overlays copy from `deps/scoria` after `deps.get`, Postgres matches `ci-verify.yml`, and `post-publish-attest` correctly chains after `publish-hex` with deduplicated index polling. Two workflow/validation gaps are worth fixing before the first `0.1.1+` upgrade leg runs live.

## Findings

| Severity | Area | File | Finding |
|----------|------|------|---------|
| warning | Workflow dependency graph | `.github/workflows/hex-publish.yml` | `post-publish-attest` runs whenever `publish` succeeds, including `dry_run: true`. Dry-run recovery never publishes or waits for Hex index, so attest will poll for an unpublished version and fail — misleading for operators using dry-run as a publish preview. Add `if: github.event.inputs.dry_run != 'true'` (or equivalent) on `post-publish-attest`. |
| warning | Exact version pin safety | `lib/mix/tasks/scoria.post_publish_smoke.ex` | `SCORIA_REGISTRY_VERSION` is required but not validated with `Version.parse/1`. A malformed value (e.g. `~> 0.1`, empty after trim, pre-release edge cases) produces a bad exact pin and fails late at `deps.get` with opaque resolver errors. Validate at task entry and raise a clear Mix error. |
| info | Exact version pin safety | `lib/scoria/hex_consumer_contract.ex` | `registry_dep_snippet_pinned/1` interpolates `version` into mix.exs without escaping. Safe in CI (workflow-controlled), but a maintainer typo with embedded `"` would corrupt generated host `mix.exs`. Consider `Version.parse/1` guard or `inspect/1` for defense in depth. |
| info | Semver upgrade baseline | `lib/scoria/hex_consumer_contract.ex` | `registry_upgrade_from_version/1` only decrements patch; at `0.2.0` the baseline becomes `0.1.0` (not `0.1.x` latest). Acceptable for current `0.1.x` scope but will need extension before minor/major release attest. |
| info | CI contract coverage | `test/scoria/ci_policy_contract_test.exs` | `release-please.yml` post-publish-attest is pinned; `hex-publish.yml` only asserts `post-publish-smoke.yml` reference, not the `post-publish-attest` job name or dry-run guard. Extend when fixing dry-run attest. |

## Focus-area verification

### Exact version pin safety

- **Pass:** `registry_dep_tuple_pinned/1` / `registry_dep_snippet_pinned/1` use exact semver strings with `hex: :scoria` — no `~>` on attest path (D-73).
- **Pass:** Adopter helpers (`hex_dep_tuple/0`, `hex_dep_snippet/0`) unchanged at `~> 0.1`.
- **Pass:** `Generator.patch_mix_exs!/1` and `bump_registry_dep!/2` both emit pinned snippets; upgrade regex targets pinned shape only.
- **Pass:** Fresh-install and upgrade ExUnit modules assert pinned dep line in host `mix.exs`.
- **Gap:** No semver validation at Mix task boundary (see warning above).

### Overlay-from-deps correctness

- **Pass:** `:hex_registry` hosts start with `overlay_tests: []`; checkout overlay copy is skipped at create time (D-70).
- **Pass:** `maybe_overlay_from_dep!/1` runs immediately after `deps.get` in registry fresh-install, upgrade baseline, and upgrade bump legs.
- **Pass:** `overlay_from_dep!/1` copies only `host_route_smoke_test.exs` and `host_runtime_smoke_test.exs` from `deps/scoria/priv/host_app_proof/overlay/test` — registry subset per D-69.
- **Pass:** Hex package includes `"priv"` in `mix.exs` `:package` files, so overlays ship in published tarball.
- **Pass:** Post-bump upgrade leg re-runs `overlay_from_dep!/1` so overlay content matches the bumped dep version.

### Workflow dependency graph

- **Pass:** `post-publish-smoke.yml` is `workflow_call` SSOT; `release:published` trigger removed (D-77).
- **Pass:** `release-please.yml`: `post-publish-attest` `needs: [release-please, publish-hex]`, gated on `release_created`, passes `skip_index_wait: true` after publish-side index poll (D-78, D-82).
- **Pass:** `hex-publish.yml`: `post-publish-attest` `needs: publish`; `skip_index_wait` derived from publish job output — `true` when publish + index wait ran, `false` when idempotent skip or dry-run (index poll delegated to attest).
- **Pass:** Attest failure fails parent workflow (blocking gate criterion #2).
- **Pass:** `workflow_dispatch` retained on `post-publish-smoke.yml` for maintainer reruns (D-80).
- **Gap:** Dry-run recovery still schedules attest (see warning above).

### Postgres service config

- **Pass:** `post-publish-smoke.yml` matches `ci-verify.yml` test job:
  - Image: `pgvector/pgvector:pg16`
  - Credentials: `postgres` / `postgres`
  - DB: `scoria_test`
  - Port mapping: `55432:5432`
  - Health check: `pg_isready -U postgres -d scoria_test` (10s interval, 5s timeout, 10 retries)
- **Pass:** Job env sets `SCORIA_DB_HOST=localhost`, `SCORIA_DB_PORT=55432`, username/password aligned with service.
- **Pass:** `Generator.patch_test_config!/1` and `Runner.host_env/0` propagate `SCORIA_DB_*` into generated host Mix invocations.

## Verified patterns

- Registry proof is 6 fixed steps: `deps_get` → overlay-from-dep → `scoria.install` → `ecto.create` → `ecto.migrate` → route + runtime smokes.
- Registry upgrade reuses Phase 80 orchestration with `bump: {:registry, from:, to:}` and registry-specific overlay subset in `expected_upgrade_steps/1`.
- Failure MANIFEST and triage include `dep_mode: hex_registry` and `registry_version` for replay (`:registry_proof` / `:registry_upgrade` tags).
- `mix scoria.post_publish_smoke` is isolated from adoption lane; conditionally includes upgrade test via `semver_upgrade_eligible?/1`.

## Recommended follow-ups

1. Guard `post-publish-attest` in `hex-publish.yml` against `dry_run: true`.
2. Add `Version.parse/1` validation in `registry_version!/0` (Mix task) and optionally in `registry_dep_tuple_pinned/1`.
3. Extend `ci_policy_contract_test` to pin `hex-publish.yml` `post-publish-attest` job once dry-run guard lands.
