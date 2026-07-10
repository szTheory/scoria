# Maintainers

This guide is intentionally packaged for Scoria maintainers. It covers CI topology, release-preview proof, docs maintenance, release recovery, warning ratchet commands, installer contract proofs, and dev-only inspection surfaces. Adopter-first docs should start with [Getting Started](guides/getting-started.md), [Reviewer Verification](guides/reviewer-verification.md), and the [Glossary](guides/reference/glossary.md); do not move maintainer-only commands into README.

For the public ownership boundary behind maintainer verification, keep the README section [What Scoria owns vs what your app owns](README.md#what-scoria-owns-vs-what-your-app-owns) and [Ownership Boundary](guides/ownership-boundary.md) aligned.

## CI gate map

GitHub Actions runs parallel verify jobs:

```text
policy -> build -> { test, ratchet, knowledge, connector, full-suite[x4] } -> verify-summary
```

The `ci-gate` umbrella job in `.github/workflows/ci.yml` fails if the reusable verify workflow fails. Branch protection and release automation require `CI / ci-gate`. Executable jobs live in `.github/workflows/ci-verify.yml`; `.github/workflows/ci.yml` is the PR entrypoint.

Policy job:

1. `mix scoria.warning_baseline.check`
2. `mix scoria.warning_inventory.check_baseline`
3. `mix compile --warnings-as-errors`
4. `mix test --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs`

Test job:

1. `MIX_ENV=dev mix scoria.release_preview`
2. `mix ecto.create` and `mix ecto.migrate`
3. `mix test.adoption`
4. `mix test.runtime_to_handoff`
5. `mix test.semantic_fast_path --warnings-as-errors`

Parallel jobs:

| Job | Local command |
|-----|---------------|
| `ratchet` | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test --warnings-as-errors test/scoria/warning_inventory/tmp_preflight_test.exs` |
| `knowledge` | `SCORIA_DB_PORT=55432 mix test.knowledge --warnings-as-errors` |
| `connector` | `SCORIA_DB_PORT=55432 mix test.connector --warnings-as-errors` |
| `full-suite (k/4)` | `SCORIA_DB_PORT=55432 MIX_TEST_PARTITION=k mix test --warnings-as-errors --partitions 4` |

Use `SCORIA_DB_PORT=55432` for local parity. CI binds Postgres below the Linux ephemeral range; local dev/test retains 55432.

## Release preview and docs maintenance

Run release preview before publish-facing docs, package, or ExDoc changes merge:

```bash
mix scoria.release_preview
```

This command builds docs and checks an unpacked local Hex preview for required runtime files, migrations, README, canonical guides, compatibility stubs, and docs brand assets. In CI, run the same verification suite as:

```bash
MIX_ENV=dev mix scoria.release_preview
```

ExDoc is a dev-only dependency, so `MIX_ENV=dev` is the CI environment for release preview. Do not present `MIX_ENV=test mix scoria.release_preview` as the supported contract.

For direct docs inspection:

```bash
MIX_ENV=dev mix docs
```

Rendered docs live in `doc/`, which is gitignored. Inspect `doc/index.html`, grouped guide extras, grouped public modules, logo/favicon rendering, redirects, and generated Markdown output when changing ExDoc configuration.

Keep this packaging boundary:

- Canonical public docs live under `guides/`.
- Old `docs/*.md` paths are compatibility stubs where copied links may exist.
- Dev-only docs such as design-system, Docker dev DX, UAT automation, component lab, screenshot harness, and generated browser artifacts stay out of adopter HexDocs unless a plan explicitly packages them.
- `guides/maintainers.md`, `CHANGELOG.md`, and `LICENSE` belong in the Maintainers ExDoc group.

## Local merge gate

`mix ci` reproduces the merge gate locally and exits non-zero on any failure.

It runs deps-lock checks, formatting, compile warnings-as-errors, pgvector preflight, and all gating verification suites from `Scoria.VerificationSuites`, plus optional knowledge, semantic cache, and connector proof unless `--skip-optional` is used.

```bash
mix ci
```

`mix ci --skip-optional` is partial proof only. It prints skipped lanes and exits non-zero so it cannot be mistaken for a clean merge gate.

## Installer contract proofs

Deep installer planner behavior is maintainer-only:

```bash
mix scoria.test.install_contract
```

Adopters use the no-write installer modes documented in [Reviewer Verification](guides/reviewer-verification.md):

```bash
mix scoria.install --dry-run
mix scoria.install --check
```

`--check` never writes host files. The final trailer is:

```text
SCORIA_CHECK_RESULT status=<compliant|drift|manual_review|error> exit_code=<0|1|2>
```

Use installer contract proof when changing planner classification, manifest behavior, no-write modes, or generated file mutation logic.

## Hex release and recovery

Routine patch release flow:

1. Merge maintainer PRs to `main` using conventional commit prefixes.
2. Confirm `CI / ci-gate` is green on `main`.
3. Let Release Please open or update the patch Release PR.
4. Let release-branch CI pass.
5. Let Release PR Auto-Merge merge the Release PR and dispatch follow-up CI/Release Please.
6. Let Release Please tag and publish to Hex after tag SHA `ci-gate` succeeds.
7. Let post-publish registry attest run `mix scoria.post_publish_smoke`.
8. Verify `mix hex.info scoria` lists the new version.

Manual Hex publish recovery is only for cases where Release Please or Hex publish did not complete:

```bash
gh workflow run hex-publish.yml \
  --ref v0.1.3 \
  -f tag=v0.1.3 \
  -f release_version=0.1.3
```

Do not republish a version already listed on Hex.

## Warning baseline and inventory

Maintainers enforce accepted warning debt expiry and classified inventory outside adopter closeout proof:

```bash
mix scoria.warning_baseline.check
MIX_ENV=test mix scoria.warning_inventory --write --scope full
MIX_ENV=test mix scoria.warning_ratchet.check
MIX_ENV=test mix scoria.warning_ratchet.test --warnings-as-errors
```

The ratchet capture is compile-only and maintainer-focused. Behavioral verification suites remain:

- `mix test.adoption`
- `mix test.runtime_to_handoff`
- `mix test.semantic_fast_path`
- `mix test.knowledge`
- `mix test.connector`

## Phase 44 dashboard scope proof

Review Queue, Eval Workbench, Prompt Registry, and Workflow Index now mount through DashboardScope. Tenant-owned evidence on those screens is loaded from the host-asserted dashboard scope; prompt templates and eval specs remain catalog metadata only where the Phase 44 summaries document that boundary.

Do not use a tenant query string to drive screenshot or maintainer proof scope. The dashboard harness must mount through host session data or a host resolver, and a tenant query hint must not change the asserted scope. Empty-state captures for tenant-owned evidence require either a freshly migrated database before seed or a host scope whose tenant has no rows.

Focused proof:

```bash
MIX_ENV=test mix test test/scoria_web/router_test.exs test/scoria_web/dashboard_scope_test.exs test/scoria_web/dashboard_scope_source_guard_test.exs test/scoria/adoption_surface_test.exs test/scoria_web/live/dashboard_auth_home_connectors_incidents_test.exs test/scoria_web/live/dashboard_auth_approvals_test.exs test/scoria_web/live/dashboard_auth_workflows_test.exs test/scoria_web/live/dashboard_auth_quality_data_test.exs test/scoria_web/live/dashboard_auth_prompts_test.exs --warnings-as-errors
```

## Dev-only inspection surfaces

The Component Lab, design-system guide, Docker dev DX guide, UAT automation docs, screenshot harness, and contact-sheet generator are maintainer development tools. They are useful for local inspection but should not become adopter HexDocs surface area without an explicit plan.

Component Lab proof:

```bash
mix test test/scoria_web/dev_lab_boundary_test.exs
make dev
mix scoria.ui.e2e --base-url http://localhost:4799/scoria
```

Screenshot pass:

```bash
make dev
mix run priv/repo/dev_seed.exs
mix scoria.ui.shots --url http://localhost:4799/scoria
```

Optional critique pass requires a process-scoped provider key:

```bash
op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- mix scoria.ui.shots --critique --url http://localhost:4799/scoria
```

Do not store plaintext provider keys in `.env`, `.envrc`, shell history, logs, screenshots, or planning artifacts.
