# Scoria Maintainer Guide

This guide is for **maintainers** — CI topology, release operations, warning ratchet commands, and installer contract proofs. Adopters should start with [operator verification](operator_verification.md) and [adoption lanes](adoption_lanes.md). For running the dashboard locally (and the multi-instance / no-port-conflict Docker setup), see [Docker dev DX](https://github.com/szTheory/scoria/blob/main/docs/docker_dev_dx.md) (dev-only; not shipped to Hex).

## CI gate map {#ci-gate-map-maintainers}

GitHub Actions runs parallel verify jobs: **`policy`** (no Postgres) → **`build`** → `{ test, ratchet, knowledge, connector, full-suite }` (each `needs: build`) → **`verify-summary`** fan-in. A **`ci-gate`** umbrella job in `ci.yml` fails if the verify workflow fails — branch protection and release automerge require **CI / ci-gate**. Executable jobs live in `.github/workflows/ci-verify.yml` (reusable SSOT); `.github/workflows/ci.yml` is the PR entrypoint. Lane order is enforced by `Scoria.VerificationLanes` and `test/scoria/ci_policy_contract_test.exs`.

**Policy job (fail cheap, no database):**

1. `mix scoria.warning_baseline.check` — baseline expiry before compile
2. `mix scoria.warning_inventory.check_baseline` — committed inventory JSON must keep `clusters` empty
3. `mix compile --warnings-as-errors` — compile WAE
4. Lane-contract WAE: `mix test --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs`

**Parallel verify jobs (each needs: build):**

Topology: `policy → build → { test, ratchet, knowledge, connector, full-suite[×4] } → verify-summary`

The `verify-summary` fan-in aggregates all parallel lane results; any non-success (including skipped) fails the workflow.

| Job | Local command |
|-----|---------------|
| `test` | `SCORIA_DB_PORT=55432 mix test --warnings-as-errors` |
| `ratchet` | `SCORIA_DB_PORT=55432 MIX_ENV=test mix test --warnings-as-errors test/scoria/warning_inventory/tmp_preflight_test.exs` |
| `knowledge` | `SCORIA_DB_PORT=55432 mix test.knowledge --warnings-as-errors` |
| `connector` | `SCORIA_DB_PORT=55432 mix test.connector --warnings-as-errors` |
| `full-suite (k/4)` | `SCORIA_DB_PORT=55432 MIX_TEST_PARTITION=k mix test --warnings-as-errors --partitions 4` |

**`test` job (Postgres on 55432):**

1. `MIX_ENV=dev mix scoria.release_preview` — release/docs lane (dev only)
2. `mix ecto.create` + `mix ecto.migrate`
3. `mix test.adoption` → `mix test.runtime_to_handoff` — behavioral closeout lanes
4. `mix test.semantic_fast_path --warnings-as-errors` — semantic lane WAE after closeout

**`ratchet` job (Postgres on 55432):**

- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test --warnings-as-errors test/scoria/warning_inventory/tmp_preflight_test.exs`
- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test --include ratchet_parity test/scoria/warning_inventory/capture_parity_test.exs` — WARN-06 parity guard

The ratchet capture is **compile-only**: `capture_output_standalone!/0` runs `mix do compile --force + test --only __ratchet_compile_only__`, which force-recompiles `lib/` and compiles all test files (emitting compiler warnings to stderr) but executes zero tests. The `--force` step is retained so any future gate extension that filters `lib/` paths is not silently weakened by a warm cache hit. The lane runs Postgres because `mix test` boots the Scoria application (Oban -> DB) so the capture runs faithfully (a DB-free `--no-start` run was verified to miss the injected warning). WARN-06 gate parity is guarded by `test/scoria/warning_inventory/capture_parity_test.exs`.

**`knowledge` job (Postgres on 55432):**

- `mix test.knowledge --warnings-as-errors` — optional knowledge lane WAE

**`connector` job (Postgres on 55432):**

- `mix test.connector --warnings-as-errors` — remote connector lane WAE
- `mix scoria.test.support_copilot` — advisory support-copilot gallery lane (tail step; not closeout)

**`full-suite` job (4-way matrix, Postgres on 55432):**

- `mix test --warnings-as-errors --partitions 4` — sharded full suite WAE
- Set `MIX_TEST_PARTITION=k` (no `SCORIA_DB_NAME`) — activates `scoria_testk` DB isolation
- Failed shard `full-suite (2/4)` → `SCORIA_DB_PORT=55432 MIX_TEST_PARTITION=2 mix test --warnings-as-errors --partitions 4`

**Verification lanes in PR CI**

| Lane | Command | In PR CI? | Notes |
|------|---------|-----------|-------|
| Default runtime | mix test.adoption | Yes | Tarball full overlay + content-revision upgrade |
| Runtime-to-handoff | mix test.runtime_to_handoff | Yes | Closeout lane |
| Semantic fast-path | mix test.semantic_fast_path --warnings-as-errors | Yes | Not in closeout order |
| Optional knowledge | mix test.knowledge --warnings-as-errors | Yes | Parallel with full-suite (both need: build) |
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

**Ratchet is maintainer-only:** `mix scoria.warning_ratchet.test` and `mix scoria.warning_ratchet.check` are debugger commands — not CI steps. The ratchet capture is compile-only (compiles `lib/` + test files, runs zero tests); WARN-06 gate parity is guarded by `test/scoria/warning_inventory/capture_parity_test.exs`.

**When CI fails, run the matching maintainer command next:**

- Policy: `warning_baseline.check` failed → `mix scoria.warning_baseline.check` locally
- Policy: `warning_inventory.check_baseline` failed → refresh inventory in a dedicated PR
- Policy: compile WAE failed → `mix compile --warnings-as-errors`
- Policy: lane-contract WAE failed → `mix test --warnings-as-errors test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs`
- Test: adoption or runtime_to_handoff failed → `SCORIA_DB_PORT=55432 mix test.adoption` or `mix test.runtime_to_handoff`
- Full-suite (k/4): WAE failed → `SCORIA_DB_PORT=55432 MIX_TEST_PARTITION=k mix test --warnings-as-errors --partitions 4`

### Local merge gate: mix ci {#local-merge-gate}

`mix ci` reproduces the full merge gate locally and exits non-zero on any failure.

**What it runs (in order):**

1. `mix deps.unlock --check-unused` — flags orphan entries left in `mix.lock`
2. `mix deps.get --check-locked` — asserts the lock is in sync with `mix.exs` (fails instead of silently rewriting)
3. `mix format --check-formatted` — format drift check (scoped via `.formatter.exs`; does not touch `examples/` vendored deps)
4. `mix compile --warnings-as-errors` — compile gate
5. pgvector preflight: `mix scoria.pgvector.bootstrap --check` — hard-fails with actionable `Next step:` block if pgvector is unreachable (never silently skips a merge-gating lane)
6. All merge-gating lanes from `Scoria.VerificationLanes.closeout_order()` + `:semantic_fast_path`, `:knowledge`, `:connector` (`:support_copilot_gallery` excluded — advisory, not merge-blocking)

Run-all-then-aggregate: every step runs before the verdict is printed; `System.halt(1)` if any step failed.

**No Docker / docs-only change?**

`mix ci --skip-optional` skips the preflight and the optional/Docker-dependent lanes (`:knowledge`, `:semantic_fast_path`, `:connector`), prints exactly which lanes were skipped, then stamps:

    RESULT: PARTIAL (knowledge, semantic_fast_path, connector skipped — NOT a merge-gate pass)

and exits non-zero unconditionally. It can never be mistaken for a clean gate.

**Deliberate local-vs-CI asymmetry (shift-left):**

`mix ci` runs `mix format --check-formatted`, `mix deps.unlock --check-unused`, and `mix deps.get --check-locked` **locally only** — CI's `policy` job does NOT run these checks today (D-C2/D-C3 from the phase 28 planning context). This is intentional: local is a strict superset of CI (more safety locally, never less). Adding these checks to the `policy` job is a documented deferred follow-up; until then the asymmetry is here as the canonical reference.

### Flake policy: retry vs fix {#flake-policy}

**Zero-retry default.** Gating test lanes MUST NOT use `continue-on-error: true`, job-level
`retry:`, or any retry-action wrapper (`nick-fields/retry`, `Wandalen/wretry.action`, etc.)
on steps running `mix test`, the e2e lane, or any verify job.

**Banned patterns on `ci.yml` and `ci-verify.yml` test steps:**
- `continue-on-error: true`
- Job-level `retry:` on test jobs
- `uses: nick-fields/retry@*` or `uses: Wandalen/wretry.action@*` wrapping assertion steps

**Carve-out (not test retries):** The existing `attempt` polling loops in
`release-please.yml`, `hex-publish.yml`, and `release-pr-automerge.yml` poll for CI
completion / Hex index availability / branch-protection status. These are control-flow
waits, not test retries, and are out of scope.

**One allowed exception class:** A retry is permitted only on a step doing a known
infra-transient operation (network/package install, browser/toolchain download). Such a
step must:
1. Have a distinct step name identifying it as a retry (e.g., `Install Playwright (retry: network-transient)`)
2. Include an inline comment justifying the retry
3. Log `RETRY <step> attempt N/M: <reason>` at runtime
4. Cap at max 3 attempts
5. Be added under review

**Fix, don't retry.** A non-deterministic test must be root-caused-and-fixed or
quarantined (`@tag :flaky`, excluded from the gate) with a tracking issue — never made
to pass by re-running. (`mix test --repeat-until-failure` is for *reproducing* flakes, not
masking them.)

**Durable enforcement:** `test/scoria/ci_policy_contract_test.exs` asserts that no Postgres
job in `ci.yml` or `ci-verify.yml` binds a host port in the Linux ephemeral range (≥ 32768).
The root cause of FLAKE-01 (run 27508317719) was `55432` falling in that range; CI now uses
`5432` (below the range). Local dev/test retain `SCORIA_DB_PORT=55432` — see local parity
commands above.

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

## Design-system component catalog

`ScoriaWeb.UI` is the single enforced token gateway for all dashboard UI components.
Every function component emits brand-book semantic classes (`assets/css/04-components.css`)
driven by design tokens; raw Tailwind palette classes (`bg-rose-200`, etc.) are blocked
in `lib/scoria_web/ui.ex` by `test/scoria_web/ds06_drift_guard_test.exs`.

CSS selectors should stay component-oriented: prefer block classes, BEM modifiers,
and inherited token variables over long structural selectors. A modifier-to-element
selector is acceptable when that relationship is the component contract
(`.scoria-table-shell--has-summary .scoria-table__viewport`), but avoid reaching
through unrelated components such as panel → table → filter controls. For shared
surface variants, add a `ScoriaWeb.UI` option such as `flush={true}` and let the
component emit the modifier class.

Tables use one canonical compact scan density. Do not add user-facing
compact/default/comfortable toggles; they add decision overhead without changing
the operator job. If a table needs a different rhythm, solve it as a distinct
component or documented surface variant instead of page-local row-density state.

Page headers own screen-level orientation. When a page has one primary scan
surface, keep the table/list panel headerless unless a visible section heading
introduces a distinct peer region or decision boundary. This avoids repeating
the page title as inner card chrome while preserving dense table containment.

### Components at a glance

| Component | Purpose |
|-----------|---------|
| `badge/1` | Status badge — tone + label, never color-alone |
| `button/1` | Primary / ghost / danger button (brand book §8.5) |
| `eyebrow/1` | Small uppercase category/status label |
| `panel/1` | Panel/card surface with optional eyebrow + title + actions header; `flush={true}` keeps table viewports edge-to-edge while preserving chrome gutters |
| `metric/1` | Metric card: label, big value, explicit delta (brand book §11.3) |
| `id/1` | Copyable monospace identifier — CopyId JS hook |
| `attention_card/1` | Status Home actionable-state card |
| `object_header/1` | Object-detail page header |
| `stub_page/1` | Placeholder page for unimplemented screens |
| `kbd/1` | Keyboard shortcut chip |
| `command_palette/1` | Client-side filtered command palette |
| `empty_state/1` | Empty-state placeholder with optional action |
| `modal/1` | Slot-based modal dialog (DS-02) |
| `drawer/1` | Slot-based drawer panel (DS-02) |
| `field/1` | Form field wrapper (DS-03) |
| `form_section/1` | Form section group (DS-03) |
| `skeleton/1` | Loading skeleton placeholder (DS-05) |
| `toast/1` | Transient toast notification (DS-05) |
| `notebook/1` | Tabbed evidence notebook (DS-04) |
| `raw_evidence/1` | Raw evidence details/pre block (DS-04) |
| `evidence_section/1` | Notebook-scoped evidence section |
| `evidence_rows/1` | Key-value evidence rows |
| `evidence_action_row/1` | Compact evidence action/link row |
| `evidence_empty/1` | Notebook-scoped evidence empty state |
| `table/1` | Sortable, paginated operator scan table with canonical compact density (DS-01) |
| `flash_group/1` | Flash notification group (DS-05) |
| `tone/1` | Utility: maps status string/atom → semantic tone atom |
| `status_label/1` | Utility: human-readable label for a status string |

This table is a glance index — not the SSOT. The full attribute and slot reference is generated from code.

### Full attribute/slot reference

```bash
MIX_ENV=dev mix docs
```

The rendered catalog lives in `doc/` (gitignored; standard Elixir ExDoc output).
Open `doc/ScoriaWeb.UI.html` for the full component reference including all `attr`
and `slot` declarations.

### Raw-palette drift protection

```bash
mix test test/scoria_web/ds06_drift_guard_test.exs
```

Three assertions guard `ui.ex` zero-tolerance and enforce the ratchet across all
`lib/scoria_web/` files. `test/support/ds06_baseline.txt` is empty — any raw palette
class introduction fails `mix test` automatically.

## Screenshot + Critique Harness (dev-only)

The screenshot and LLM-critique harness provides a mechanical proof loop for the v3.0 Control Room milestone. It captures every dashboard screen across its state matrix, runs an optional 9-dimension AI critique, and writes a ranked gap register. It is **dev-only**: excluded from the shipped Hex package and never run in merge-blocking CI (D-01).

### Prerequisites

1. **Node.js >= 18** — must be on `PATH` (the harness shells out via `System.cmd("node", ...)`).
   Verify: `node --version`

2. **Playwright + Chromium** — install globally before running any screenshot pass:

   ```bash
   npm install -g playwright && npx playwright install chromium
   ```

   Playwright is a documented maintainer prerequisite (D-02). It is **not** a `mix.exs` dependency — installing it does not affect `mix.lock` or `hex.audit`.

3. **ANTHROPIC_API_KEY** — required only for the `--critique` pass (the LLM vision call). The screenshot pass runs without it. Use the process-scoped 1Password pattern in the Docker dev DX Secrets section; do not put plaintext provider keys in `.env`, `.envrc`, shell history, logs, screenshots, or planning artifacts.

   ```bash
   op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- mix scoria.ui.shots --critique --url http://localhost:4799/scoria
   ```

### Seed-first workflow

Screens must render populated data before capture — run the idempotent dashboard seed first:

```bash
mix run priv/repo/dev_seed.exs
```

This is safe to re-run: it uses `Repo.get_by` + conditional insert guards so records are not duplicated. Seeded tenant is `acme-corp` (the `Scoria.SupportJourney` spine — D-07).

### Screenshot pass

Start the dashboard with `make dev`, seed populated data from another shell, then run the screenshot pass against the native host URL:

```bash
make dev
mix run priv/repo/dev_seed.exs
mix scoria.ui.shots --url http://localhost:4799/scoria
```

Captured PNGs land in `priv/shots/{date}/{screen}/{state}.png` (gitignored — only `gap_register.md` is committed). The state matrix per tenant-scoped screen is:

- `empty_dark_desktop`, `empty_dark_mobile`, `empty_light_desktop`, `empty_light_mobile`
- `populated_dark_desktop`, `populated_dark_mobile`, `populated_light_desktop`, `populated_light_mobile`
- Overlay states (screen-specific): `modal_dark_desktop`, `connector_drawer_dark_desktop`, etc.

**Optional flags:**

```bash
mix scoria.ui.shots --url http://localhost:4799/scoria   # custom dev server URL (default shown)
mix scoria.ui.shots --tenant-empty empty-tenant          # empty-state tenant slug (default shown)
mix scoria.ui.shots --tenant-seeded acme-corp            # seeded-state tenant slug (default shown)
mix scoria.ui.shots --release-id <uuid>                  # navigate directly to a specific prompt release
```

### Critique pass (--critique)

Run the critique pass as a separate gated step at phase-milestone boundaries (D-04). It calls the UI critique screen function via ReqLLM vision on the canonical populated / desktop / dark state for each screen (~9 vision calls), then writes per-screen findings JSON:

```bash
op run --env-file "${SCORIA_OP_ENV_FILE:-.env.op}" -- mix scoria.ui.shots --critique --url http://localhost:4799/scoria
```

Requires `ANTHROPIC_API_KEY`. Writes `priv/shots/{date}/{screen}/populated_dark_desktop.json` alongside the PNG. The gap register aggregation step (`priv/shots/gap_register.md`) runs in Plan 05's audit pass.

This step starts the Elixir application (to access ReqLLM and application config). The plain screenshot pass does **not** start the Elixir app — it only shells out to Node/Playwright.

### Empty-state limitation (4 non-tenant-scoped screens)

**Review Queue**, **Eval Workbench**, **Prompt Registry**, and **Workflow Index** do not support `?tenant=` query-param switching — they list all records globally and do not read `params["tenant"]` in `mount/3`. As a result, the harness captures **populated-only** for these four screens; their `tenantScoped` manifest flag is `false`.

Their empty state (all-empty DB) is a freshly-migrated-DB artifact, not a per-run harness capture. Document this when reviewing gap register findings — empty captures for these four screens require running the harness against a freshly-migrated database before applying the seed.

The five remaining tenant-scoped screens (Live Ops, Approvals, Workflows, Incidents, Connectors) support both empty and populated state captures via `?tenant=` navigation.

### Dev-only posture summary

- `priv/dev/shots.mjs` is **checked into git** (committed dev tooling, D-01) but **excluded from the shipped Hex package** via explicit `priv/` subdirectory inclusions in `mix.exs package.files`.
- `priv/shots/` screenshot captures are **gitignored** (PNG/JSON); only `gap_register.md` is committed.
- The `scoria.ui.shots` Mix task is **not registered in CI** (`cli.preferred_envs` does not list it) — it runs only when maintainers explicitly invoke it.

### Contact-sheet generation

After capturing two dated shot sets, generate the before/after contact sheet:

```bash
node priv/dev/contact_sheet.mjs \
  --before priv/shots/2026-06-04 \
  --after priv/shots/<final-date> \
  --out priv/shots/contact_sheet.html
```

The generated HTML is gitignored (`*.html` in `priv/shots/.gitignore`).
`priv/shots/contact_sheet_index.md` (committed) records the dir pair and per-screen delta notes.
For future milestone passes, substitute new baseline and final dirs — no code changes needed.
