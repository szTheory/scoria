# Reviewer Verification

Reviewer verification proves that Scoria is installed, scoped, inspectable, and ready for optional capability work. Start with the default runtime verification suite before adding semantic cache, knowledge, connector, or support-copilot gallery proof.

Start with the default runtime capability: run `$ mix test.adoption`, then use `$ mix test.runtime_to_handoff` only when you intentionally add bounded handoffs. This verification suite does not require semantic fast-path setup, knowledge/pgvector bootstrap, retrieval setup, or hosted onboarding setup.

Use this guide with [Getting Started](guides/getting-started.md), [Default Runtime](guides/capabilities/default-runtime.md), [Ownership Boundary](guides/ownership-boundary.md), [Troubleshooting](guides/troubleshooting.md), and the [Glossary](guides/reference/glossary.md).

Compatibility note: older copied links and 0.1.x text may say `docs/operator_verification.md` or operator verification. New public docs should say reviewer verification. Use `operator` only for explicit SRE/on-call job sense or historical compatibility notes.

## What core success means

You have proven the default runtime capability when all of these are true:

- `$ mix scoria.install` has wired the dashboard, copied core migrations, and set baseline runtime defaults.
- `$ mix ecto.migrate` has applied the host app's Scoria migrations.
- `$ mix test.adoption` passes for the host app.
- one real run starts through `Scoria.start_run/2`.
- that same run can be read back through `Scoria.get_run/1` or found through `Scoria.list_runs_for_session/1`.
- `/scoria/workflows/:run_id` shows the reviewer trace for that exact run.
- `/scoria` is mounted behind host-authenticated dashboard scope, not public tenant query params.

This verification suite does not require semantic fast-path setup, knowledge/pgvector bootstrap, retrieval setup, or hosted onboarding setup.

In current public vocabulary, that means the default runtime proof does not require semantic cache setup, optional knowledge base setup, connector setup, pgvector bootstrap, retrieval setup, or hosted onboarding.

## Dashboard auth and tenant scope proof

The host authenticates the reviewer and asserts tenant scope before Scoria renders tenant-owned dashboard evidence. The host app authenticates the reviewer and asserts dashboard tenant scope. Query params do not choose tenants for the dashboard. Scoria supplies the dashboard seam and records trusted scope; the host app owns authentication, authorization, tenant membership, role values, policy values, and business truth. Authorization remains delegated to the host; Scoria does not introduce a role model.

Mount the dashboard behind your Phoenix auth and membership checks; in short, mount the dashboard with host-authenticated scope:

```elixir
scope "/" do
  pipe_through [:browser, :require_authenticated_user]

  scoria_dashboard "/scoria",
    on_mount: [{MyAppWeb.UserAuth, :require_authenticated}],
    scope_resolver: MyAppWeb.ScoriaDashboardScope
end
```

Have the resolver return tenant data only after the host has authorized the reviewer for that tenant:

```elixir
defmodule MyAppWeb.ScoriaDashboardScope do
  @behaviour ScoriaWeb.DashboardScope.Resolver

  @impl true
  def resolve(_params, _session, socket) do
    account = socket.assigns.current_account
    user = socket.assigns.current_user

    {:ok,
     %{
       tenant_id: account.id,
       actor_id: user.id,
       display_tenant: account.name
     }}
  end
end
```

Verify the boundary:

1. Open `/scoria` while authenticated as a reviewer for a known tenant.
2. Confirm the dashboard renders only that tenant's runs, approvals, incidents, eval evidence, and prompt release evidence.
3. Open `/scoria?tenant=another-tenant` with the same authenticated session.
4. Confirm the tenant query hint does not change the asserted tenant scope; tenant query hint does not change the asserted dashboard scope.
5. Remove or reject the resolver scope and confirm Scoria fails closed with generic browser-facing copy: `This Scoria dashboard is not available for this session.`

The bare `scoria_dashboard "/scoria"` form still compiles for compatibility with generated/dev/example mounts. Prefer the explicit `on_mount:` plus `scope_resolver:` shape in authenticated host apps.

## Installer verification modes (upgrade-safe)

Use this workflow before and after host-app upgrades:

```bash
mix scoria.install --dry-run
mix scoria.install --check
mix scoria.install
```

`--dry-run` previews planned changes. `--check` never writes host files. `manual_review` entries never receive silent overwrites; remediate the printed issue and rerun the check before apply.

Automation should parse the final check-mode trailer:

```text
SCORIA_CHECK_RESULT status=<compliant|drift|manual_review|error> exit_code=<0|1|2>
```

## Check vs apply drift detection

| Stage | What fingerprints mean |
|-------|-------------------------|
| `--check` / `--dry-run` | Live host surfaces only. Classifications and exit codes come from current disk and package desired state. |
| Stored `.scoria/install/manifest.json` | Informational snapshot from the last successful apply. It does not drive check classification. |
| Apply preflight | Compares each plan entry fingerprint captured at plan build time to live disk before writes. |
| Post-apply | Manifest is rewritten as the last-applied snapshot. |

Do not edit `.scoria/install/manifest.json` by hand. If apply blocks for stale fingerprints, rerun `--dry-run` and `--check` without changing managed files between check and apply.

Deep installer contract proofs are maintainer-only:

```bash
mix scoria.test.install_contract
```

Do not put this command in README or first-run adopter docs. Use it when maintaining installer planner behavior, not when proving normal host adoption.

## Install and default runtime proof

Run the installer and baseline proof first:

```bash
mix scoria.install
mix ecto.migrate
mix test.adoption
```

What this proves:

- dashboard routes mount at `/scoria`.
- Scoria-owned core tables are available through copied host-app migrations.
- baseline runtime defaults are present.
- the host app can start and inspect one default runtime run.
- adopter docs and migration guards match the packaged surface.

`$ mix test.adoption` is the canonical default runtime verification suite. It includes the fresh-host install/migrate/route/runtime smoke, the generated-host package proof, and adoption docs/migration guards. The bounded verifier carries the slow generated-host proof under a local proof-only timeout; support guidance should not widen that into a suite-wide timeout change or a `$ mix test.adoption --trace` contract.

## Prove one real runtime flow

Start one real run from your Phoenix app:

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

Persist `started.run_id`. That `run_id` is the exact handle for readback, resume, and reviewer trace inspection.

## Read back and open the reviewer trace

Use the returned `run_id` to verify that the runtime surface reports the exact execution you just created:

```elixir
{:ok, summary} = Scoria.get_run(started.run_id)
same_session_runs = Scoria.list_runs_for_session(identity.session_id)
```

Expected proof:

- `summary.run_id == started.run_id`.
- `summary.session_id == identity.session_id`.
- the run is visible in `list_runs_for_session/1`.
- `/scoria/workflows/:run_id` shows the same durable run.

Use `session_id` to group related host turns. Use `run_id` to inspect or resume one exact Scoria execution.

## Resume an approval-paused run

If the verification run pauses for approval, resume it by exact `run_id`:

```elixir
{:ok, resumed} =
  Scoria.resume_run(started.run_id,
    handlers: %{"approval" => {MyApp.RuntimeHandlers, :succeed}}
  )
```

The resumed run keeps the same `run_id`. A later turn in the same conversation should reuse the same `session_id` and create a fresh `run_id`.

## Optional capability proof

Add optional capabilities only after the default runtime is boring:

| Capability | Command | Use when |
|------------|---------|----------|
| Bounded handoffs | `$ mix test.runtime_to_handoff` | same-run delegated work needs `scoped_context` and reviewer-visible lineage |
| Semantic cache | `SCORIA_DB_PORT=55432 SCORIA_DB_PASSWORD=postgres MIX_ENV=test mix test.semantic_fast_path` | safe read-only reuse needs tenant partitioning and compatibility proof |
| Optional knowledge base | `$ mix scoria.pgvector.bootstrap` then `$ mix test.knowledge` | retrieval, citations, and grounding are part of the product |
| Remote connectors | `$ mix test.connector` | durable MCP connector records and reviewer fleet trace details matter |
| Support-copilot gallery | `$ mix scoria.test.support_copilot` | maintainers want the advisory repository-local gallery proof |

The support-copilot gallery is advisory. Merge-blocking adoption proof remains `$ mix test.adoption`.

Semantic cache proof uses the product's reviewer-facing outcome vocabulary:

- `hit` means Scoria reused a durable semantic entry.
- `bypass` means Scoria intentionally skipped reuse and ran the normal runtime path.
- `miss` means no reusable entry existed, so the normal runtime path executed.
- `reject` means a candidate entry existed, but compatibility or freshness no longer held.
- `active`, `stale`, `invalidated`, and `writeback_rejected` are durable lifecycle states for the semantic entry itself.

## Release-preview package proof

Maintainers validate publish-facing docs and package inventory with:

```bash
mix scoria.release_preview
```

This verification suite runs docs generation with warnings-as-errors and checks an unpacked local Hex preview for required runtime files, migrations, README, canonical guides, compatibility stubs, and docs brand assets. CI should run this verification suite in `MIX_ENV=dev` because ExDoc stays a dev-only tool, but keep the maintainer-facing command contract plain: `$ mix scoria.release_preview`. Use `MIX_ENV=dev mix docs --warnings-as-errors` only as a diagnostic shortcut for raw docs warnings, not as a separate CI policy step.

Keep release preview distinct from behavioral proof:

- `$ mix scoria.release_preview` proves docs-build and package-inventory truth.
- `$ mix test.adoption` proves the default runtime adoption boundary.
- `$ mix test.runtime_to_handoff` proves bounded same-run escalation and delegated trace readback.
- `$ mix test.semantic_fast_path` proves the canonical semantic cache troubleshooting verification suite.
- `$ mix test.knowledge` proves optional knowledge base behavior.

## Maintainer closeout chain

For repository closeout, the canonical proof chain is exactly:

```bash
mix scoria.release_preview
mix test.adoption
mix test.runtime_to_handoff
```

Use the broader `$ mix test` or `$ mix ci` commands as broader repo-health context when classifying failures outside the canonical verification suites. Maintainer-only CI topology, release automation, warning ratchet, and dev-only component-lab commands live in [Maintainers](guides/maintainers.md).
