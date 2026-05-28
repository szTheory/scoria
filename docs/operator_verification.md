# Operator Verification

This guide is the default Phoenix verification lane for Scoria's public runtime surface. The goal is simple: prove the core install, runtime, and operator-evidence path before you touch the optional knowledge lane.
Maintainer closeout starts with mix scoria.release_preview before the bounded test lanes.
Start with the default runtime lane. It proves identity-aware durable runs, approvals, and operator evidence with mix test.adoption. Use mix test.runtime_to_handoff as the bounded escalation proof lane when the same durable run needs narrow same-run delegation, host-controlled projected context, and operator-visible delegated lineage.
Start here with `mix scoria.install`, `mix ecto.migrate`, and `mix test.adoption`; add this only when the default lane is stable in your host app.

## What core success means

You have proven the default lane when all of these are true:

- `mix scoria.install` has wired the dashboard, copied core migrations, and set baseline runtime defaults
- `mix ecto.migrate` and `mix test.adoption` pass for the host app
- one real run starts through `Scoria.start_run/2`
- that same run can be read back through `Scoria.get_run/1` or found via `list_runs_for_session/1`
- `/scoria/workflows/:run_id` shows operator evidence for that exact run

This lane does not require semantic fast-path setup, knowledge/pgvector bootstrap, retrieval setup, or hosted onboarding setup.

## Installer verification modes (upgrade-safe)

Use this workflow before and after host-app upgrades:

1. `mix scoria.install --dry-run` to preview planned changes without writes.
2. `mix scoria.install --check` to verify current state without writes.
3. Remediate any `manual_review` entries using the printed remediation steps.
4. `mix scoria.install` to apply planner-classified changes.

`--check` never writes host files. `manual_review` entries never receive silent overwrites.

Automation should parse the final check-mode trailer:

`SCORIA_CHECK_RESULT status=<compliant|drift|manual_review|error> exit_code=<0|1|2>`

### Check vs apply drift detection

| Stage | What fingerprints mean |
|-------|-------------------------|
| `--check` / `--dry-run` | Live host surfaces only. Classifications and exit codes come from current disk and package desired state. |
| Stored `.scoria/install/manifest.json` | Informational snapshot from the last successful apply. It does not drive check classification. |
| Apply preflight | Compares each plan entry fingerprint captured at plan build time to live disk before writes. |
| Post-apply | Manifest is rewritten as the last-applied snapshot. |

Do not edit `.scoria/install/manifest.json` by hand. If apply blocks for stale fingerprints, re-run `--dry-run` and `--check` without changing managed files between check and apply.

An absent manifest file is informational only. A compliant host can still exit `0` from `--check` when ownership markers and migrations are already converged.

## Step 1: Install preflight

Run the installer and the boring baseline commands first:

```bash
mix scoria.install
mix ecto.migrate
mix test.adoption
```

What this proves:

- the dashboard routes mount at `/scoria`
- the Scoria-owned core tables are available through copied host-app migrations
- baseline runtime defaults are present
- the app passes the bounded default-lane adoption verifier

Use `mix test.adoption` as the canonical default-lane verifier when you want one bounded proof that covers installer truth, the fresh-host install/migrate/route/runtime smoke, and the repo-local adoption guards without waiting for the whole suite. Maintainers can still use `mix test` as broader repo-health context.
The bounded verifier carries the slow generated-host proof under a local proof-only timeout; support guidance should not widen that into a suite-wide timeout change or a `mix test.adoption --trace` contract.

## Semantic fast-path troubleshooting lane

When you are validating the `v2.1` semantic fast path specifically, use the bounded semantic lane instead of the broad suite:

```bash
SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path
```

This is the canonical `v2.1` troubleshooting lane. It proves:

- tenant partitioning and semantic lookup behavior
- explicit fallback visibility for `bypass`, `miss`, `reject`, and `hit`
- operator evidence projection on `/scoria` and `/scoria/workflows/:run_id`
- lifecycle truth for `active`, `stale`, `invalidated`, and `writeback_rejected`
- retrieval-backed source fingerprint checks used by the semantic lane

Use the semantic nouns exactly as rendered by the product:

- `hit` means Scoria reused a durable semantic entry
- `bypass` means Scoria intentionally skipped the fast path and ran the normal runtime path
- `miss` means the fast path evaluated cleanly but found no reusable entry, so the normal runtime path executed
- `reject` means Scoria found a candidate entry but refused it because compatibility or freshness no longer held
- `active`, `stale`, `invalidated`, and `writeback_rejected` are lifecycle states for the durable semantic entry itself

## Step 2: Prove one real runtime flow

From your Phoenix app, start one real run through the public facade:

```elixir
identity =
  Scoria.identity(%{
    actor_id: current_user.id,
    tenant_id: current_account.id,
    session_id: get_session(conn, :assistant_session_id)
  })

{:ok, started} =
  Scoria.start_run(identity,
    root_role_id: "executor",
    initial_step: %{sequence: 1, kind: "approval", role_id: "executor", status: "queued"},
    handlers: %{"approval" => {MyApp.RuntimeHandlers, :wait_for_approval}}
  )
```

Persist `started.run_id`. That `run_id` is the exact handle for readback, resume, and operator evidence.

## Step 3: Read back the same run

Use the returned `run_id` to verify that the runtime surface can report the exact execution you just created:

```elixir
{:ok, summary} = Scoria.get_run(started.run_id)
same_session_runs = Scoria.list_runs_for_session(identity.session_id)
```

Expected core proof:

- `summary.run_id == started.run_id`
- `summary.session_id == identity.session_id`
- the run is visible in `list_runs_for_session/1`

If the run pauses for approval, keep that same `run_id`. Approval resume is always exact-run resume.

## Step 4: Open operator evidence

Open the operator pages for the installed dashboard:

```text
/scoria
/scoria/workflows/:run_id
```

The second page should show the same durable run you started from the host app. This is operator evidence for the run, not the system of record for your domain model.

## Step 5: Resume an approval-paused run

If your verification run pauses for approval, resume it by exact `run_id`:

```elixir
{:ok, resumed} =
  Scoria.resume_run(started.run_id,
    handlers: %{"approval" => {MyApp.RuntimeHandlers, :succeed}}
  )
```

The resumed run keeps the same `run_id`. A later turn in the same conversation should reuse the same `session_id` but create a fresh `run_id`.

## Optional knowledge lane

Only after the default lane is proven should you expand into the knowledge-backed path:

```bash
mix scoria.pgvector.bootstrap
mix test.knowledge
```

That lane is explicitly optional. It verifies pgvector-backed retrieval and grounding behavior after the core runtime and operator surface already work.

## Maintainer release-preview lane

When you are validating Scoria's publish-facing package and docs surface, use the bounded release-preview lane:

```bash
mix scoria.release_preview
```

This is the canonical maintainer proof for release packaging. It runs `mix docs` and checks an unpacked local Hex preview for the required runtime files, migrations, README, and adopter guides.
CI should run this lane in `MIX_ENV=dev` because ExDoc stays a dev-only tool, but the maintainer-facing command contract remains plain `mix scoria.release_preview`.

Keep it distinct from the other named lanes:

- `mix test.adoption` proves the canonical default runtime adoption boundary
- `mix test.runtime_to_handoff` proves bounded runtime-to-handoff escalation through `Scoria.get_run_detail/1` and `delegated_handoffs`
- `mix test.semantic_fast_path` proves the bounded semantic troubleshooting lane
- `mix test.knowledge` proves the optional knowledge lane

## Maintainer closeout

For repository closeout, the canonical proof chain is exactly:

```bash
mix scoria.release_preview
mix test.adoption
mix test.runtime_to_handoff
```

Use `mix scoria.release_preview` as the canonical maintainer proof for docs-build and package-inventory truth before publish-facing changes merge.
If you are wiring the lane into CI, run it under `MIX_ENV=dev` instead of presenting the job-wide test env as the supported closeout contract.
Use `mix test.adoption` as the canonical default-lane verifier for the install, fresh-host install/migrate/route/runtime proof, docs, and migration-lane guards that make up the bounded acceptance harness.
Use `mix test.runtime_to_handoff` as the canonical bounded escalation proof lane for runtime-to-handoff behavior and delegated evidence readback.
Use `mix test.semantic_fast_path` only for the canonical `v2.1` semantic fast-path troubleshooting lane.
Use `mix test.knowledge` only when you are intentionally validating the optional knowledge lane.
Use `mix test` as broader repo-health context when you want to classify failures outside the canonical proof lane.

## Warning baseline and inventory

Maintainers enforce accepted warning debt expiry and capture classified inventory outside the adopter closeout lanes.

- `mix scoria.warning_baseline.check` — fails when accepted rows in `.planning/WARNING-BASELINE.md` are expired or invalid
- `mix scoria.warning_inventory` — capture-mode inventory of compiler warnings (no WAE)
- `mix scoria.warning_inventory --write --scope full` — writes cluster-count JSON and human summary for Phase 67 ratchet ordering

### WARN-05 canonical compile and lane-contract surfaces

Maintainers verify compile WAE and canonical lane-contract tests remain warning-clean before cluster-fix work:

```bash
MIX_ENV=test mix compile --warnings-as-errors
MIX_ENV=test mix test --warnings-as-errors test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs
```

These are the canonical WARN-05 maintainer proof commands (p0 compile + p1 lane-contract WAE).

### WARN-06 high-signal ratchet

Maintainers verify high-signal warning-as-errors scope before Phase 68 CI wiring:

```bash
mix scoria.warning_baseline.check
rm -rf test/tmp/*
MIX_ENV=test mix scoria.warning_inventory --write --scope full
MIX_ENV=test mix scoria.warning_ratchet.check
MIX_ENV=test mix scoria.warning_ratchet.test --warnings-as-errors
```

`mix scoria.warning_ratchet.check` now enforces empty `test/tmp/` before capture and automatically removes transient entries under `test/tmp/` after capture, so a follow-on `mix scoria.warning_inventory` run does not require manual cleanup between those two commands.

Preflight: still run `rm -rf test/tmp/*` before inventory `--write` when you skip `warning_ratchet.check` (for example a manual inventory-only refresh) so host-proof fixture pollution does not skew cluster counts.

### WARN-07 CI warning gates (full suite)

CI preserves behavioral lane commands unchanged:

- `mix test.adoption` — default runtime lane (behavior)
- `mix test.runtime_to_handoff` — escalation lane (behavior)

CI enforces compiler warnings across the full default test suite after closeout lanes:

```bash
mix test --warnings-as-errors
```

The high-signal ratchet bridge (`mix scoria.warning_ratchet.test --warnings-as-errors`) remains available for maintainer pre-flip debugging and WARN-06 scope checks; it is no longer a separate CI step after Phase 68-03 closeout.

Ratchet paths include `Mix.Tasks.Scoria.Test.Adoption.adoption_test_files/0` plus `test/scoria/**/*_test.exs` and `test/scoria_web/live/**/*_test.exs` (`Scoria.WarningRatchet.high_signal_wae_paths/0`).

Maintainer adopter-parity debug command:

```bash
MIX_ENV=test mix test.adoption --warnings-as-errors
```

Local full-suite closeout uses pgvector Postgres on port 55432 (`SCORIA_DB_PORT=55432`).

### CI gate map (maintainers)

GitHub Actions runs two jobs in order: **`policy`** (no Postgres) first, then **`test`** (`needs: policy`, pgvector Postgres on port 55432) for canonical closeout. Executable order lives in `.github/workflows/ci.yml`, `Scoria.VerificationLanes`, and `test/scoria/ci_policy_contract_test.exs` — this section explains topology and local parity only.

**Policy job (fail cheap, no database):**

1. `mix scoria.warning_baseline.check` — baseline expiry before compile
2. `mix compile --warnings-as-errors` — compile WAE
3. Lane-contract WAE: `mix test --warnings-as-errors test/scoria/ci_policy_contract_test.exs test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs`

**Test job closeout (Postgres on 55432):**

1. `MIX_ENV=dev mix scoria.release_preview` — release/docs lane (dev only)
2. `mix ecto.create` + `mix ecto.migrate`
3. `mix test.adoption` → `mix test.runtime_to_handoff` — behavioral closeout lanes
4. `mix test --warnings-as-errors` — full-suite WAE after closeout lanes
5. `mix test.knowledge` — optional knowledge lane (behavior, not WAE)

**Local parity:** set `SCORIA_DB_PORT=55432` for the test job database; use `MIX_ENV=dev` only for `mix scoria.release_preview`. Run `mix scoria.test.ci_trust` for the full Phase 69 maintainer trust bundle (policy contracts + ratchet hygiene integration); add `--fast` for policy-parity only (~30s).

**Ratchet is maintainer-only:** `mix scoria.warning_ratchet.test` and `mix scoria.warning_ratchet.check` are WARN-06 debugger commands — they are **not** CI steps after Phase 68.

**When CI fails, run the matching maintainer command next:**

- Policy: `warning_baseline.check` failed → inspect `.planning/WARNING-BASELINE.md` expiry rows, then `mix scoria.warning_baseline.check` locally
- Policy: compile WAE failed → `mix compile --warnings-as-errors` and fix compiler warnings
- Policy: lane-contract WAE failed → `MIX_ENV=test mix test --warnings-as-errors test/scoria/verification_lanes_test.exs test/scoria/adoption_surface_test.exs`
- Test: adoption or runtime_to_handoff failed → reproduce with `SCORIA_DB_PORT=55432 mix test.adoption` or `mix test.runtime_to_handoff`
- Test: full-suite WAE failed → `SCORIA_DB_PORT=55432 MIX_ENV=test mix test --warnings-as-errors` after closeout lanes pass
