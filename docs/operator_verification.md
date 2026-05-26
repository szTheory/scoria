# Operator Verification

This guide is the default Phoenix verification lane for Scoria's public runtime surface. The goal is simple: prove the core install, runtime, and operator-evidence path before you touch the optional knowledge lane.

## What core success means

You have proven the default lane when all of these are true:

- `mix scoria.install` has wired the dashboard, copied core migrations, and set baseline runtime defaults
- `mix ecto.migrate` and `mix test.adoption` pass for the host app
- one real run starts through `Scoria.start_run/2`
- that same run can be read back through `Scoria.get_run/1` or found via `list_runs_for_session/1`
- `/scoria/workflows/:run_id` shows operator evidence for that exact run

You do not need pgvector, knowledge tables, retrieval, grounding, semantic-fast-path setup, or `mix test.knowledge` to prove the core lane.

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
- `mix test.semantic_fast_path` proves the bounded semantic troubleshooting lane
- `mix test.knowledge` proves the optional knowledge lane

## Maintainer closeout

For repository closeout, the canonical proof chain is exactly:

```bash
mix scoria.release_preview
mix test.adoption
```

Use `mix scoria.release_preview` as the canonical maintainer proof for docs-build and package-inventory truth before publish-facing changes merge.
If you are wiring the lane into CI, run it under `MIX_ENV=dev` instead of presenting the job-wide test env as the supported closeout contract.
Use `mix test.adoption` as the canonical default-lane verifier for the install, fresh-host install/migrate/route/runtime proof, docs, and migration-lane guards that make up the bounded acceptance harness.
Use `mix test.semantic_fast_path` only for the canonical `v2.1` semantic fast-path troubleshooting lane.
Use `mix test.knowledge` only when you are intentionally validating the optional knowledge lane.
Use `mix test` as broader repo-health context when you want to classify failures outside the canonical proof lane.
